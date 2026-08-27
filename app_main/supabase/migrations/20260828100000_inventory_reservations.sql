-- Mizan migration
-- id: 20260828100000_inventory_reservations.sql
-- owner: inventory-and-pos
-- prerequisites: 20260827250000_inventory_pos_accounting_bridge.sql
-- changes: tenant-scoped inventory reservations with idempotent reserve/release commands
-- security: authenticated tenant scope, permission checks, RLS, audit, and no direct writes
-- verification: supabase/tests/20260828100000_inventory_reservations.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create table if not exists public.inventory_reservations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  warehouse_id text not null default 'default' check (length(btrim(warehouse_id)) between 1 and 80),
  product_id text not null check (length(btrim(product_id)) between 1 and 160),
  quantity numeric(18,6) not null check (quantity > 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  reference_type text not null check (length(btrim(reference_type)) between 1 and 80),
  reference_id uuid,
  idempotency_key text not null check (length(btrim(idempotency_key)) between 8 and 240),
  status text not null default 'active' check (status in ('active', 'released', 'fulfilled', 'expired')),
  expires_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  released_by uuid references auth.users(id) on delete set null,
  released_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id),
  unique (tenant_id, idempotency_key)
);

create index if not exists inventory_reservations_available_idx
  on public.inventory_reservations (tenant_id, warehouse_id, product_id, currency_code, status, expires_at);

create or replace function public.reserve_inventory(
  p_warehouse_id text,
  p_product_id text,
  p_quantity numeric,
  p_currency_code text,
  p_reference_type text,
  p_reference_id uuid,
  p_expires_at timestamptz,
  p_idempotency_key text
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_warehouse text := coalesce(nullif(btrim(p_warehouse_id), ''), 'default');
  v_product text := btrim(p_product_id);
  v_currency text := upper(btrim(p_currency_code));
  v_reference text := btrim(p_reference_type);
  v_key text := btrim(p_idempotency_key);
  v_balance public.inventory_balances;
  v_reserved numeric;
  v_reservation public.inventory_reservations;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['performSale','manageProducts','manageSettings']) then raise exception 'Inventory reservation permission required'; end if;
  if v_product is null or length(v_product) not between 1 and 160 or p_quantity is null or p_quantity <= 0
     or v_currency !~ '^[A-Z]{3,5}$' or v_reference is null or length(v_reference) not between 1 and 80
     or v_key is null or length(v_key) not between 8 and 240 then
    raise exception 'Inventory reservation data is invalid';
  end if;
  if p_expires_at is not null and p_expires_at <= timezone('utc', now()) then raise exception 'Reservation expiry must be in the future'; end if;
  select * into v_reservation from public.inventory_reservations where tenant_id = v_tenant_id and idempotency_key = v_key;
  if found then return to_jsonb(v_reservation); end if;
  select * into v_balance from public.inventory_balances
  where tenant_id = v_tenant_id and warehouse_id = v_warehouse and product_id = v_product and currency_code = v_currency
  for update;
  if not found then raise exception 'Inventory balance was not found'; end if;
  select coalesce(sum(quantity), 0) into v_reserved
  from public.inventory_reservations
  where tenant_id = v_tenant_id and warehouse_id = v_warehouse and product_id = v_product and currency_code = v_currency
    and status = 'active' and (expires_at is null or expires_at > timezone('utc', now()));
  if v_balance.quantity_on_hand - v_reserved < p_quantity then raise exception 'Insufficient available inventory'; end if;
  insert into public.inventory_reservations (tenant_id, warehouse_id, product_id, quantity, currency_code, reference_type, reference_id, idempotency_key, expires_at, created_by)
  values (v_tenant_id, v_warehouse, v_product, p_quantity, v_currency, v_reference, p_reference_id, v_key, p_expires_at, v_user_id)
  returning * into v_reservation;
  return to_jsonb(v_reservation);
end;
$$;

create or replace function public.release_inventory_reservation(p_reservation_id uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_reservation public.inventory_reservations;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['performSale','manageProducts','manageSettings']) then raise exception 'Inventory reservation permission required'; end if;
  select * into v_reservation from public.inventory_reservations where id = p_reservation_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Inventory reservation was not found'; end if;
  if v_reservation.status = 'released' then return to_jsonb(v_reservation); end if;
  if v_reservation.status <> 'active' then raise exception 'Only active reservations can be released'; end if;
  update public.inventory_reservations set status = 'released', released_by = auth.uid(), released_at = timezone('utc', now())
  where id = v_reservation.id and tenant_id = v_tenant_id returning * into v_reservation;
  return to_jsonb(v_reservation);
end;
$$;

drop trigger if exists inventory_reservations_updated_at on public.inventory_reservations;
create trigger inventory_reservations_updated_at before update on public.inventory_reservations for each row execute function public.set_updated_at();
drop trigger if exists inventory_reservations_audit on public.inventory_reservations;
create trigger inventory_reservations_audit after insert or update or delete on public.inventory_reservations for each row execute function public.audit_row_change();
alter table public.inventory_reservations enable row level security;
revoke all on table public.inventory_reservations from anon, authenticated;
grant select on table public.inventory_reservations to authenticated;
drop policy if exists inventory_reservations_select on public.inventory_reservations;
create policy inventory_reservations_select on public.inventory_reservations for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
revoke all on function public.reserve_inventory(text, text, numeric, text, text, uuid, timestamptz, text) from public, anon, authenticated;
revoke all on function public.release_inventory_reservation(uuid) from public, anon, authenticated;
grant execute on function public.reserve_inventory(text, text, numeric, text, text, uuid, timestamptz, text) to authenticated;
grant execute on function public.release_inventory_reservation(uuid) to authenticated;
