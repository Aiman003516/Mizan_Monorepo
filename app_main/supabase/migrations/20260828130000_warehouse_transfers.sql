-- Mizan migration
-- id: 20260828130000_warehouse_transfers.sql
-- owner: inventory-and-pos
-- prerequisites: 20260828100000_inventory_reservations.sql
-- changes: atomic warehouse transfer evidence and stock movement
-- security: authenticated tenant scope, inventory permissions, idempotency, RLS, and audit
-- verification: supabase/tests/20260828130000_warehouse_transfers.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create table if not exists public.warehouse_transfers (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references public.tenants(id) on delete cascade,
  transfer_number text not null, source_warehouse_id text not null, destination_warehouse_id text not null,
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  status text not null default 'posted' check (status in ('posted','void')), reason text,
  idempotency_key text not null, created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc',now()), unique (tenant_id,id), unique (tenant_id,transfer_number), unique (tenant_id,idempotency_key),
  check (source_warehouse_id <> destination_warehouse_id)
);
create table if not exists public.warehouse_transfer_lines (
  id uuid primary key default gen_random_uuid(), tenant_id uuid not null references public.tenants(id) on delete cascade,
  transfer_id uuid not null references public.warehouse_transfers(id) on delete cascade, product_id text not null,
  quantity numeric(18,6) not null check (quantity > 0), unit_cost_minor bigint not null check (unit_cost_minor >= 0),
  unique (tenant_id,id), foreign key (tenant_id,transfer_id) references public.warehouse_transfers(tenant_id,id) on delete cascade
);
create index if not exists warehouse_transfers_status_idx on public.warehouse_transfers(tenant_id,status,created_at desc,id);
create index if not exists warehouse_transfer_lines_transfer_idx on public.warehouse_transfer_lines(tenant_id,transfer_id,id);

create or replace function public.post_warehouse_transfer(p_transfer_number text,p_source_warehouse_id text,p_destination_warehouse_id text,p_currency_code text,p_idempotency_key text,p_lines jsonb,p_reason text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_tenant uuid:=public.current_tenant_id(); v_id uuid; v_line jsonb; v_source public.inventory_balances; v_dest public.inventory_balances; v_qty numeric; v_count int:=0; v_product text; v_currency text:=upper(btrim(p_currency_code)); v_key text:=btrim(p_idempotency_key); v_src text:=btrim(p_source_warehouse_id); v_dst text:=btrim(p_destination_warehouse_id); v_existing public.warehouse_transfers;
begin
 if auth.uid() is null or v_tenant is null then raise exception 'Authenticated tenant membership required'; end if;
 if not public.has_tenant_permission(v_tenant,array['adjustInventory','manageProducts','manageSettings']) then raise exception 'Warehouse transfer permission required'; end if;
 if p_transfer_number is null or length(btrim(p_transfer_number)) not between 1 and 80 or v_src is null or v_dst is null or v_src=v_dst or v_currency !~ '^[A-Z]{3,5}$' or v_key is null or length(v_key) not between 8 and 240 or jsonb_typeof(p_lines)<>'array' or jsonb_array_length(p_lines)=0 then raise exception 'Warehouse transfer data is invalid'; end if;
 select * into v_existing from public.warehouse_transfers where tenant_id=v_tenant and idempotency_key=v_key; if found then return to_jsonb(v_existing)||jsonb_build_object('idempotent',true); end if;
 insert into public.warehouse_transfers(tenant_id,transfer_number,source_warehouse_id,destination_warehouse_id,currency_code,idempotency_key,reason,created_by) values(v_tenant,btrim(p_transfer_number),v_src,v_dst,v_currency,v_key,nullif(btrim(p_reason),''),auth.uid()) returning id into v_id;
 for v_line in select value from jsonb_array_elements(p_lines) loop
  v_count:=v_count+1; v_product:=btrim(v_line->>'product_id'); v_qty:=(v_line->>'quantity')::numeric;
  if v_product is null or length(v_product)=0 or v_qty is null or v_qty<=0 then raise exception 'Warehouse transfer line is invalid'; end if;
  select * into v_source from public.inventory_balances where tenant_id=v_tenant and warehouse_id=v_src and product_id=v_product and currency_code=v_currency for update;
  if not found or v_source.quantity_on_hand<v_qty then raise exception 'Insufficient source inventory'; end if;
  insert into public.warehouse_transfer_lines(tenant_id,transfer_id,product_id,quantity,unit_cost_minor) values(v_tenant,v_id,v_product,v_qty,v_source.average_cost_minor);
  update public.inventory_balances set quantity_on_hand=quantity_on_hand-v_qty where id=v_source.id;
  select * into v_dest from public.inventory_balances where tenant_id=v_tenant and warehouse_id=v_dst and product_id=v_product and currency_code=v_currency for update;
  if found then update public.inventory_balances set quantity_on_hand=quantity_on_hand+v_qty, average_cost_minor=v_source.average_cost_minor where id=v_dest.id;
  else insert into public.inventory_balances(tenant_id,warehouse_id,product_id,quantity_on_hand,average_cost_minor,currency_code) values(v_tenant,v_dst,v_product,v_qty,v_source.average_cost_minor,v_currency); end if;
 end loop;
 if v_count=0 then raise exception 'Warehouse transfer lines are required'; end if;
 return jsonb_build_object('transfer_id',v_id,'transfer_number',p_transfer_number,'status','posted','line_count',v_count);
end;$$;

drop trigger if exists warehouse_transfers_audit on public.warehouse_transfers; create trigger warehouse_transfers_audit after insert or update or delete on public.warehouse_transfers for each row execute function public.audit_row_change();
drop trigger if exists warehouse_transfer_lines_audit on public.warehouse_transfer_lines; create trigger warehouse_transfer_lines_audit after insert or update or delete on public.warehouse_transfer_lines for each row execute function public.audit_row_change();
alter table public.warehouse_transfers enable row level security; alter table public.warehouse_transfer_lines enable row level security;
revoke all on table public.warehouse_transfers,public.warehouse_transfer_lines from anon,authenticated; grant select on public.warehouse_transfers,public.warehouse_transfer_lines to authenticated;
drop policy if exists warehouse_transfers_select on public.warehouse_transfers; create policy warehouse_transfers_select on public.warehouse_transfers for select to authenticated using(tenant_id=public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists warehouse_transfer_lines_select on public.warehouse_transfer_lines; create policy warehouse_transfer_lines_select on public.warehouse_transfer_lines for select to authenticated using(tenant_id=public.current_tenant_id() and public.is_tenant_member(tenant_id));
revoke all on function public.post_warehouse_transfer(text,text,text,text,text,jsonb,text) from public,anon,authenticated; grant execute on function public.post_warehouse_transfer(text,text,text,text,text,jsonb,text) to authenticated;
