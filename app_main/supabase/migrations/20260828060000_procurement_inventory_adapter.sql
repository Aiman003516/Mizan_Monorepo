-- Mizan migration
-- id: 20260828060000_procurement_inventory_adapter.sql
-- owner: procurement-and-inventory
-- prerequisites: 20260828050000_procurement_foundation.sql
-- changes: procurement receipt/return to inventory journal-draft adapters and immutable links
-- security: tenant/branch scope, permissions, RLS, grants, idempotency, and audit triggers
-- verification: supabase/tests/20260828060000_procurement_inventory_adapter.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

-- The adapter is explicit: procurement evidence is posted first, then each stock line
-- creates the existing inventory accounting draft. Journal posting remains the point
-- at which inventory_balances changes through the existing inventory trigger.
create table if not exists public.procurement_inventory_receipt_links (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid,
  purchase_receipt_id uuid not null references public.purchase_receipts(id) on delete restrict,
  purchase_receipt_line_id uuid not null references public.purchase_receipt_lines(id) on delete restrict,
  inventory_receipt_id uuid not null references public.inventory_receipts(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, purchase_receipt_line_id),
  unique (tenant_id, inventory_receipt_id),
  unique (tenant_id, id),
  foreign key (tenant_id, branch_id) references public.tenant_branches(tenant_id, id) on delete restrict,
  foreign key (tenant_id, purchase_receipt_id) references public.purchase_receipts(tenant_id, id) on delete restrict,
  foreign key (tenant_id, purchase_receipt_line_id) references public.purchase_receipt_lines(tenant_id, id) on delete restrict,
  foreign key (tenant_id, inventory_receipt_id) references public.inventory_receipts(tenant_id, id) on delete restrict
);

create table if not exists public.inventory_returns (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  warehouse_id text not null default 'default' check (length(btrim(warehouse_id)) between 1 and 80),
  product_id text not null check (length(btrim(product_id)) between 1 and 160),
  quantity numeric(18,6) not null check (quantity > 0),
  unit_cost_minor bigint not null check (unit_cost_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  status text not null default 'draft_created' check (status in ('draft_created', 'posted', 'void')),
  journal_entry_id uuid references public.journal_entries(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  posted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id)
);

create table if not exists public.procurement_inventory_return_links (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid,
  purchase_return_id uuid not null references public.purchase_returns(id) on delete restrict,
  purchase_return_line_id uuid not null references public.purchase_return_lines(id) on delete restrict,
  inventory_return_id uuid not null references public.inventory_returns(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, purchase_return_line_id),
  unique (tenant_id, inventory_return_id),
  unique (tenant_id, id),
  foreign key (tenant_id, branch_id) references public.tenant_branches(tenant_id, id) on delete restrict,
  foreign key (tenant_id, purchase_return_id) references public.purchase_returns(tenant_id, id) on delete restrict,
  foreign key (tenant_id, purchase_return_line_id) references public.purchase_return_lines(tenant_id, id) on delete restrict,
  foreign key (tenant_id, inventory_return_id) references public.inventory_returns(tenant_id, id) on delete restrict
);

create index if not exists procurement_inventory_receipt_links_lookup_idx
  on public.procurement_inventory_receipt_links (tenant_id, purchase_receipt_id, branch_id, created_at desc);
create index if not exists procurement_inventory_return_links_lookup_idx
  on public.procurement_inventory_return_links (tenant_id, purchase_return_id, branch_id, created_at desc);
create index if not exists inventory_returns_status_idx
  on public.inventory_returns (tenant_id, status, warehouse_id, product_id, created_at desc);

-- Small immutable SQL helper avoids duplicating PO currency lookup in the adapter.
create or replace function public.v_receipt_currency(p_purchase_order_id uuid, p_tenant_id uuid)
returns text language sql stable security definer set search_path = public
as $$ select currency_code from public.purchase_orders where id = p_purchase_order_id and tenant_id = p_tenant_id $$;

create or replace function public.create_inventory_return_draft(
  p_product_id text,
  p_warehouse_id text,
  p_quantity numeric,
  p_unit_cost_minor bigint,
  p_currency_code text,
  p_inventory_account_id uuid,
  p_payable_account_id uuid,
  p_entry_number text,
  p_return_date date default current_date
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_return_id uuid;
  v_entry_id uuid;
  v_draft jsonb;
  v_currency text := upper(btrim(p_currency_code));
  v_total bigint;
  v_inventory_type text;
  v_payable_type text;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['adjustInventory','manageAccounting','manageSettings']) then raise exception 'Inventory return permission required'; end if;
  if p_product_id is null or length(btrim(p_product_id)) = 0 or p_quantity is null or p_quantity <= 0
     or p_unit_cost_minor is null or p_unit_cost_minor < 0 or v_currency !~ '^[A-Z]{3,5}$'
     or p_entry_number is null or length(btrim(p_entry_number)) not between 1 and 80 then
    raise exception 'Inventory return data is invalid';
  end if;
  if not exists (
    select 1 from public.synced_products p
    where p.tenant_id = v_tenant_id and p.id = btrim(p_product_id) and not p.is_deleted
  ) then raise exception 'Product does not belong to the tenant'; end if;
  select account_type into v_inventory_type from public.chart_of_accounts where id = p_inventory_account_id and tenant_id = v_tenant_id and is_active;
  select account_type into v_payable_type from public.chart_of_accounts where id = p_payable_account_id and tenant_id = v_tenant_id and is_active;
  if v_inventory_type is distinct from 'asset' or v_payable_type is distinct from 'liability' then raise exception 'Inventory return accounts are invalid'; end if;
  v_total := round(p_quantity * p_unit_cost_minor)::bigint;
  insert into public.inventory_returns (tenant_id, warehouse_id, product_id, quantity, unit_cost_minor, currency_code, created_by)
  values (v_tenant_id, coalesce(nullif(btrim(p_warehouse_id), ''), 'default'), btrim(p_product_id), p_quantity, p_unit_cost_minor, v_currency, auth.uid())
  returning id into v_return_id;
  v_draft := public.create_journal_draft(
    p_entry_number, p_return_date, 'Inventory return ' || btrim(p_product_id), v_currency, 1,
    jsonb_build_array(
      jsonb_build_object('account_id', p_payable_account_id, 'debit_minor', v_total, 'credit_minor', 0, 'currency_code', v_currency, 'line_number', 1),
      jsonb_build_object('account_id', p_inventory_account_id, 'debit_minor', 0, 'credit_minor', v_total, 'currency_code', v_currency, 'line_number', 2)
    )
  );
  v_entry_id := (v_draft->>'id')::uuid;
  update public.journal_entries set source_type = 'inventory_return', source_id = v_return_id where id = v_entry_id and tenant_id = v_tenant_id;
  update public.inventory_returns set journal_entry_id = v_entry_id where id = v_return_id and tenant_id = v_tenant_id;
  return v_draft || jsonb_build_object('inventory_return_id', v_return_id, 'total_minor', v_total);
end;
$$;

create or replace function public.sync_inventory_after_post()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  v_receipt public.inventory_receipts;
  v_return public.inventory_returns;
  v_sale public.pos_sales;
  v_line record;
  v_balance public.inventory_balances;
  v_new_qty numeric;
  v_new_cost bigint;
begin
  if new.status <> 'posted' or new.source_id is null then return new; end if;
  if new.source_type = 'inventory_receipt' then
    select * into v_receipt from public.inventory_receipts where id = new.source_id and tenant_id = new.tenant_id and journal_entry_id = new.id for update;
    if found and v_receipt.status = 'draft_created' then
      select * into v_balance from public.inventory_balances where tenant_id = new.tenant_id and warehouse_id = v_receipt.warehouse_id and product_id = v_receipt.product_id and currency_code = v_receipt.currency_code for update;
      if not found then
        insert into public.inventory_balances (tenant_id, warehouse_id, product_id, quantity_on_hand, average_cost_minor, currency_code)
        values (new.tenant_id, v_receipt.warehouse_id, v_receipt.product_id, v_receipt.quantity, v_receipt.unit_cost_minor, v_receipt.currency_code);
      else
        v_new_qty := v_balance.quantity_on_hand + v_receipt.quantity;
        v_new_cost := case when v_new_qty = 0 then 0 else round(((v_balance.quantity_on_hand * v_balance.average_cost_minor) + (v_receipt.quantity * v_receipt.unit_cost_minor)) / v_new_qty)::bigint end;
        update public.inventory_balances set quantity_on_hand = v_new_qty, average_cost_minor = v_new_cost where id = v_balance.id;
      end if;
      update public.inventory_receipts set status = 'posted', posted_at = timezone('utc', now()) where id = v_receipt.id;
    end if;
  elsif new.source_type = 'inventory_return' then
    select * into v_return from public.inventory_returns where id = new.source_id and tenant_id = new.tenant_id and journal_entry_id = new.id for update;
    if found and v_return.status = 'draft_created' then
      update public.inventory_balances
      set quantity_on_hand = quantity_on_hand - v_return.quantity
      where tenant_id = new.tenant_id and warehouse_id = v_return.warehouse_id and product_id = v_return.product_id and currency_code = v_return.currency_code and quantity_on_hand >= v_return.quantity;
      if not found then raise exception 'Inventory changed before return posting'; end if;
      update public.inventory_returns set status = 'posted', posted_at = timezone('utc', now()) where id = v_return.id;
    end if;
  elsif new.source_type = 'pos_sale' then
    select * into v_sale from public.pos_sales where id = new.source_id and tenant_id = new.tenant_id and journal_entry_id = new.id for update;
    if found and v_sale.status = 'draft_created' then
      for v_line in select * from public.pos_sale_lines where sale_id = v_sale.id and tenant_id = new.tenant_id order by line_number loop
        update public.inventory_balances
        set quantity_on_hand = quantity_on_hand - v_line.quantity
        where tenant_id = new.tenant_id and warehouse_id = v_line.warehouse_id and product_id = v_line.product_id and currency_code = v_sale.currency_code and quantity_on_hand >= v_line.quantity;
        if not found then raise exception 'Inventory changed before POS sale posting'; end if;
      end loop;
      update public.pos_sales set status = 'posted', posted_at = timezone('utc', now()) where id = v_sale.id;
    end if;
  end if;
  return new;
end;
$$;

do $$
begin
  execute 'drop trigger if exists inventory_returns_updated_at on public.inventory_returns';
  execute 'create trigger inventory_returns_updated_at before update on public.inventory_returns for each row execute function public.set_updated_at()';
  execute 'drop trigger if exists inventory_returns_audit on public.inventory_returns';
  execute 'create trigger inventory_returns_audit after insert or update or delete on public.inventory_returns for each row execute function public.audit_row_change()';
  execute 'alter table public.inventory_returns enable row level security';
  execute 'revoke all on table public.inventory_returns from anon, authenticated';
end $$;

create policy inventory_returns_select on public.inventory_returns for select to authenticated using (public.is_tenant_member(tenant_id));

create or replace function public.post_purchase_receipt_to_inventory(
  p_purchase_receipt_id uuid,
  p_inventory_account_id uuid,
  p_payable_account_id uuid,
  p_entry_number_prefix text
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_receipt public.purchase_receipts;
  v_po public.purchase_orders;
  v_line record;
  v_draft jsonb;
  v_inventory_receipt_id uuid;
  v_existing_count integer;
  v_line_count integer;
  v_line_number integer := 0;
  v_branch_id uuid;
  v_prefix text := btrim(p_entry_number_prefix);
  v_results jsonb := '[]'::jsonb;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['adjustInventory','manageAccounting','manageSettings','manageProcurement']) then raise exception 'Procurement inventory permission required'; end if;
  if p_inventory_account_id is null or p_payable_account_id is null or v_prefix is null or length(v_prefix) not between 1 and 55 then raise exception 'Inventory adapter data is invalid'; end if;
  select * into v_receipt from public.purchase_receipts where id = p_purchase_receipt_id and tenant_id = v_tenant_id for update;
  if not found or v_receipt.status <> 'posted' then raise exception 'A posted purchase receipt is required'; end if;
  select * into v_po from public.purchase_orders where id = v_receipt.purchase_order_id and tenant_id = v_tenant_id for share;
  if not found then raise exception 'Purchase order was not found'; end if;
  v_branch_id := v_po.branch_id;
  if not public.approval_branch_access(v_tenant_id, v_branch_id) then raise exception 'Branch access required'; end if;
  select count(*) into v_line_count from public.purchase_receipt_lines where receipt_id = v_receipt.id and tenant_id = v_tenant_id;
  select count(*) into v_existing_count from public.procurement_inventory_receipt_links where purchase_receipt_id = v_receipt.id and tenant_id = v_tenant_id;
  if v_line_count = 0 then raise exception 'Purchase receipt has no lines'; end if;
  if v_existing_count = v_line_count then
    return jsonb_build_object('purchase_receipt_id', v_receipt.id, 'status', 'already_linked', 'links', coalesce((select jsonb_agg(to_jsonb(l) order by l.created_at) from public.procurement_inventory_receipt_links l where l.purchase_receipt_id = v_receipt.id and l.tenant_id = v_tenant_id), '[]'::jsonb));
  elsif v_existing_count <> 0 then
    raise exception 'Purchase receipt adapter state is incomplete';
  end if;
  for v_line in
    select prl.*, pol.product_id, pol.unit_price_minor, pol.currency_code as po_currency
    from public.purchase_receipt_lines prl
    join public.purchase_order_lines pol on pol.id = prl.purchase_order_line_id and pol.tenant_id = v_tenant_id
    where prl.receipt_id = v_receipt.id and prl.tenant_id = v_tenant_id
    order by prl.id
  loop
    v_line_number := v_line_number + 1;
    if v_line.product_id is null or length(btrim(v_line.product_id)) = 0 then raise exception 'All receipt lines must have a product for inventory posting'; end if;
    if v_line.currency_code is distinct from v_receipt_currency(v_receipt.purchase_order_id, v_tenant_id) then raise exception 'Receipt currency is inconsistent'; end if;
    v_draft := public.create_inventory_receipt_draft(v_line.product_id, v_receipt.warehouse_id, v_line.quantity, v_line.unit_cost_minor, v_line.po_currency, p_inventory_account_id, p_payable_account_id, v_prefix || '-' || substr(v_receipt.id::text, 1, 8) || '-' || v_line_number::text, v_receipt.receipt_date);
    v_inventory_receipt_id := (v_draft->>'receipt_id')::uuid;
    insert into public.procurement_inventory_receipt_links (tenant_id, branch_id, purchase_receipt_id, purchase_receipt_line_id, inventory_receipt_id, created_by)
    values (v_tenant_id, v_branch_id, v_receipt.id, v_line.id, v_inventory_receipt_id, auth.uid());
    v_results := v_results || jsonb_build_array(jsonb_build_object('purchase_receipt_line_id', v_line.id, 'inventory_receipt_id', v_inventory_receipt_id, 'status', 'draft_created'));
  end loop;
  return jsonb_build_object('purchase_receipt_id', v_receipt.id, 'status', 'linked', 'links', v_results);
end;
$$;

create or replace function public.post_purchase_return_to_inventory(
  p_purchase_return_id uuid,
  p_inventory_account_id uuid,
  p_payable_account_id uuid,
  p_entry_number_prefix text
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_return public.purchase_returns;
  v_po public.purchase_orders;
  v_line record;
  v_draft jsonb;
  v_inventory_return_id uuid;
  v_existing_count integer;
  v_line_count integer;
  v_line_number integer := 0;
  v_branch_id uuid;
  v_prefix text := btrim(p_entry_number_prefix);
  v_results jsonb := '[]'::jsonb;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['adjustInventory','manageAccounting','manageSettings','manageProcurement']) then raise exception 'Procurement inventory permission required'; end if;
  if p_inventory_account_id is null or p_payable_account_id is null or v_prefix is null or length(v_prefix) not between 1 and 55 then raise exception 'Inventory adapter data is invalid'; end if;
  select * into v_return from public.purchase_returns where id = p_purchase_return_id and tenant_id = v_tenant_id for update;
  if not found or v_return.status <> 'posted' then raise exception 'A posted purchase return is required'; end if;
  select * into v_po from public.purchase_orders where id = v_return.purchase_order_id and tenant_id = v_tenant_id for share;
  if not found then raise exception 'Purchase order was not found'; end if;
  v_branch_id := v_po.branch_id;
  if not public.approval_branch_access(v_tenant_id, v_branch_id) then raise exception 'Branch access required'; end if;
  select count(*) into v_line_count from public.purchase_return_lines where return_id = v_return.id and tenant_id = v_tenant_id;
  select count(*) into v_existing_count from public.procurement_inventory_return_links where purchase_return_id = v_return.id and tenant_id = v_tenant_id;
  if v_line_count = 0 then raise exception 'Purchase return has no lines'; end if;
  if v_existing_count = v_line_count then
    return jsonb_build_object('purchase_return_id', v_return.id, 'status', 'already_linked', 'links', coalesce((select jsonb_agg(to_jsonb(l) order by l.created_at) from public.procurement_inventory_return_links l where l.purchase_return_id = v_return.id and l.tenant_id = v_tenant_id), '[]'::jsonb));
  elsif v_existing_count <> 0 then
    raise exception 'Purchase return adapter state is incomplete';
  end if;
  for v_line in
    select prl.*, pol.product_id, pol.unit_price_minor, pol.currency_code as po_currency
    from public.purchase_return_lines prl
    join public.purchase_order_lines pol on pol.id = prl.purchase_order_line_id and pol.tenant_id = v_tenant_id
    where prl.return_id = v_return.id and prl.tenant_id = v_tenant_id
    order by prl.id
  loop
    v_line_number := v_line_number + 1;
    if v_line.product_id is null or length(btrim(v_line.product_id)) = 0 then raise exception 'All return lines must have a product for inventory posting'; end if;
    v_draft := public.create_inventory_return_draft(v_line.product_id, (select warehouse_id from public.purchase_receipts where id = v_return.receipt_id and tenant_id = v_tenant_id), v_line.quantity, v_line.unit_cost_minor, v_line.po_currency, p_inventory_account_id, p_payable_account_id, v_prefix || '-' || substr(v_return.id::text, 1, 8) || '-' || v_line_number::text, v_return.return_date);
    v_inventory_return_id := (v_draft->>'inventory_return_id')::uuid;
    insert into public.procurement_inventory_return_links (tenant_id, branch_id, purchase_return_id, purchase_return_line_id, inventory_return_id, created_by)
    values (v_tenant_id, v_branch_id, v_return.id, v_line.id, v_inventory_return_id, auth.uid());
    v_results := v_results || jsonb_build_array(jsonb_build_object('purchase_return_line_id', v_line.id, 'inventory_return_id', v_inventory_return_id, 'status', 'draft_created'));
  end loop;
  return jsonb_build_object('purchase_return_id', v_return.id, 'status', 'linked', 'links', v_results);
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['procurement_inventory_receipt_links','procurement_inventory_return_links'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon, authenticated', t);
    execute format('grant select on table public.%I to authenticated', t);
    execute format('drop trigger if exists %I_audit on public.%I', t, t);
    execute format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
  end loop;
end $$;

create policy procurement_inventory_receipt_links_select on public.procurement_inventory_receipt_links for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
create policy procurement_inventory_return_links_select on public.procurement_inventory_return_links for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));

revoke all on function public.v_receipt_currency(uuid, uuid) from public, anon, authenticated;
revoke all on function public.create_inventory_return_draft(text, text, numeric, bigint, text, uuid, uuid, text, date) from public, anon, authenticated;
revoke all on function public.post_purchase_receipt_to_inventory(uuid, uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.post_purchase_return_to_inventory(uuid, uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.create_inventory_return_draft(text, text, numeric, bigint, text, uuid, uuid, text, date) to authenticated;
grant execute on function public.post_purchase_receipt_to_inventory(uuid, uuid, uuid, text) to authenticated;
grant execute on function public.post_purchase_return_to_inventory(uuid, uuid, uuid, text) to authenticated;
