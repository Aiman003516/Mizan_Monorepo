-- Mizan inventory/POS bridge.
-- Products remain represented by tenant-scoped synced product IDs until a
-- dedicated product master is introduced. Financial and stock mutations are
-- performed only when an authorized journal draft is posted.

-- Preserve the legacy client signature while routing all new callers through
-- the extended book/FX/worktag contract introduced by the repair migration.
create or replace function public.create_journal_draft(
  p_entry_number text,
  p_entry_date date,
  p_description text,
  p_currency_code text,
  p_exchange_rate numeric,
  p_lines jsonb
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
begin
  return public.create_journal_draft(
    p_entry_number, p_entry_date, p_description, p_currency_code,
    p_exchange_rate, p_lines, null, null, null, null
  );
end;
$$;
revoke all on function public.create_journal_draft(text, date, text, text, numeric, jsonb) from public, anon, authenticated;
grant execute on function public.create_journal_draft(text, date, text, text, numeric, jsonb) to authenticated;

create table if not exists public.inventory_balances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  warehouse_id text not null default 'default' check (length(btrim(warehouse_id)) between 1 and 80),
  product_id text not null check (length(btrim(product_id)) between 1 and 160),
  quantity_on_hand numeric(18,6) not null default 0 check (quantity_on_hand >= 0),
  average_cost_minor bigint not null default 0 check (average_cost_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, warehouse_id, product_id),
  unique (tenant_id, id)
);

create table if not exists public.inventory_receipts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  warehouse_id text not null default 'default',
  product_id text not null,
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

create table if not exists public.pos_sales (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  sale_number text not null,
  warehouse_id text not null default 'default',
  sale_date date not null,
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  total_minor bigint not null check (total_minor >= 0),
  cogs_minor bigint not null default 0 check (cogs_minor >= 0),
  payment_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  revenue_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  inventory_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  cogs_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  status text not null default 'draft_created' check (status in ('draft_created', 'posted', 'void')),
  journal_entry_id uuid references public.journal_entries(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  posted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, sale_number),
  unique (tenant_id, id)
);

create table if not exists public.pos_sale_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  sale_id uuid not null references public.pos_sales(id) on delete cascade,
  line_number integer not null check (line_number > 0),
  product_id text not null,
  quantity numeric(18,6) not null check (quantity > 0),
  unit_price_minor bigint not null check (unit_price_minor >= 0),
  unit_cost_minor bigint not null check (unit_cost_minor >= 0),
  line_total_minor bigint not null check (line_total_minor >= 0),
  warehouse_id text not null default 'default',
  unique (sale_id, line_number),
  unique (tenant_id, id)
);

create index if not exists inventory_balances_lookup_idx
  on public.inventory_balances (tenant_id, warehouse_id, product_id);
create index if not exists inventory_receipts_status_idx
  on public.inventory_receipts (tenant_id, status, warehouse_id, product_id);
create index if not exists pos_sales_status_date_idx
  on public.pos_sales (tenant_id, status, sale_date desc, id);
create index if not exists pos_sale_lines_sale_idx
  on public.pos_sale_lines (tenant_id, sale_id, line_number);

create or replace function public.create_inventory_receipt_draft(
  p_product_id text,
  p_warehouse_id text,
  p_quantity numeric,
  p_unit_cost_minor bigint,
  p_currency_code text,
  p_inventory_account_id uuid,
  p_payable_account_id uuid,
  p_entry_number text,
  p_receipt_date date default current_date
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_receipt_id uuid;
  v_entry_id uuid;
  v_draft jsonb;
  v_currency text := upper(btrim(p_currency_code));
  v_total bigint;
  v_inventory_type text;
  v_payable_type text;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['adjustInventory','manageAccounting','manageSettings']) then raise exception 'Inventory receipt permission required'; end if;
  if p_product_id is null or length(btrim(p_product_id)) = 0 or p_quantity is null or p_quantity <= 0
     or p_unit_cost_minor is null or p_unit_cost_minor < 0 or v_currency !~ '^[A-Z]{3,5}$'
     or p_entry_number is null or length(btrim(p_entry_number)) not between 1 and 80 then
    raise exception 'Inventory receipt data is invalid';
  end if;
  if not exists (
    select 1 from public.synced_products p
    where p.tenant_id = v_tenant_id and p.id = btrim(p_product_id) and not p.is_deleted
  ) then raise exception 'Product does not belong to the tenant'; end if;
  select account_type into v_inventory_type from public.chart_of_accounts where id = p_inventory_account_id and tenant_id = v_tenant_id and is_active;
  select account_type into v_payable_type from public.chart_of_accounts where id = p_payable_account_id and tenant_id = v_tenant_id and is_active;
  if v_inventory_type is distinct from 'asset' or v_payable_type is distinct from 'liability' then raise exception 'Inventory receipt accounts are invalid'; end if;
  v_total := round(p_quantity * p_unit_cost_minor)::bigint;
  insert into public.inventory_receipts (tenant_id, warehouse_id, product_id, quantity, unit_cost_minor, currency_code, created_by)
  values (v_tenant_id, coalesce(nullif(btrim(p_warehouse_id), ''), 'default'), btrim(p_product_id), p_quantity, p_unit_cost_minor, v_currency, auth.uid())
  returning id into v_receipt_id;
  v_draft := public.create_journal_draft(
    p_entry_number, p_receipt_date, 'Inventory receipt ' || btrim(p_product_id), v_currency, 1,
    jsonb_build_array(
      jsonb_build_object('account_id', p_inventory_account_id, 'debit_minor', v_total, 'credit_minor', 0, 'currency_code', v_currency, 'line_number', 1),
      jsonb_build_object('account_id', p_payable_account_id, 'debit_minor', 0, 'credit_minor', v_total, 'currency_code', v_currency, 'line_number', 2)
    )
  );
  v_entry_id := (v_draft->>'id')::uuid;
  update public.journal_entries set source_type = 'inventory_receipt', source_id = v_receipt_id where id = v_entry_id and tenant_id = v_tenant_id;
  update public.inventory_receipts set journal_entry_id = v_entry_id where id = v_receipt_id and tenant_id = v_tenant_id;
  return v_draft || jsonb_build_object('receipt_id', v_receipt_id, 'total_minor', v_total);
end;
$$;

create or replace function public.create_pos_sale_draft(
  p_sale_number text,
  p_warehouse_id text,
  p_sale_date date,
  p_currency_code text,
  p_payment_account_id uuid,
  p_revenue_account_id uuid,
  p_inventory_account_id uuid,
  p_cogs_account_id uuid,
  p_lines jsonb
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_sale_id uuid;
  v_entry_id uuid;
  v_draft jsonb;
  v_line jsonb;
  v_count integer := 0;
  v_total bigint := 0;
  v_cogs bigint := 0;
  v_quantity numeric;
  v_unit_price bigint;
  v_line_total bigint;
  v_unit_cost bigint;
  v_available numeric;
  v_currency text := upper(btrim(p_currency_code));
  v_payment_type text;
  v_revenue_type text;
  v_inventory_type text;
  v_cogs_type text;
  v_warehouse text := coalesce(nullif(btrim(p_warehouse_id), ''), 'default');
  v_accounts uuid[] := array[p_payment_account_id, p_revenue_account_id, p_inventory_account_id, p_cogs_account_id];
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['performSale','manageAccounting','manageSettings']) then raise exception 'POS sale permission required'; end if;
  if p_sale_number is null or length(btrim(p_sale_number)) not between 1 and 80
     or v_currency !~ '^[A-Z]{3,5}$' or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then
    raise exception 'POS sale data is invalid';
  end if;
  if (select count(*) from public.chart_of_accounts where id = any(v_accounts) and tenant_id = v_tenant_id and is_active) <> 4 then raise exception 'POS accounts must belong to the active tenant'; end if;
  select account_type into v_payment_type from public.chart_of_accounts where id = p_payment_account_id;
  select account_type into v_revenue_type from public.chart_of_accounts where id = p_revenue_account_id;
  select account_type into v_inventory_type from public.chart_of_accounts where id = p_inventory_account_id;
  select account_type into v_cogs_type from public.chart_of_accounts where id = p_cogs_account_id;
  if v_payment_type is distinct from 'asset' or v_revenue_type is distinct from 'revenue'
     or v_inventory_type is distinct from 'asset' or v_cogs_type is distinct from 'expense' then raise exception 'POS account types are invalid'; end if;

  insert into public.pos_sales (
    tenant_id, sale_number, warehouse_id, sale_date, currency_code, total_minor,
    payment_account_id, revenue_account_id, inventory_account_id, cogs_account_id, created_by
  ) values (v_tenant_id, btrim(p_sale_number), v_warehouse, p_sale_date, v_currency, 0,
            p_payment_account_id, p_revenue_account_id, p_inventory_account_id, p_cogs_account_id, auth.uid())
  returning id into v_sale_id;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_count := v_count + 1;
    if v_line->>'product_id' is null or length(btrim(v_line->>'product_id')) = 0 then raise exception 'POS product is required'; end if;
    if not exists (
      select 1 from public.synced_products p
      where p.tenant_id = v_tenant_id and p.id = btrim(v_line->>'product_id') and not p.is_deleted
    ) then raise exception 'Product does not belong to the tenant'; end if;
    v_quantity := nullif(v_line->>'quantity', '')::numeric;
    v_unit_price := nullif(v_line->>'unit_price_minor', '')::bigint;
    if v_quantity is null or v_quantity <= 0 or v_unit_price is null or v_unit_price < 0 then raise exception 'POS line quantity or price is invalid'; end if;
    select b.quantity_on_hand, b.average_cost_minor into v_available, v_unit_cost
    from public.inventory_balances b
    where b.tenant_id = v_tenant_id and b.warehouse_id = v_warehouse and b.product_id = btrim(v_line->>'product_id') and b.currency_code = v_currency
    for update;
    if not found or v_available < v_quantity then raise exception 'Insufficient inventory for product %', v_line->>'product_id'; end if;
    v_line_total := round(v_quantity * v_unit_price)::bigint;
    v_total := v_total + v_line_total;
    v_cogs := v_cogs + round(v_quantity * v_unit_cost)::bigint;
    insert into public.pos_sale_lines (tenant_id, sale_id, line_number, product_id, quantity, unit_price_minor, unit_cost_minor, line_total_minor, warehouse_id)
    values (v_tenant_id, v_sale_id, v_count, btrim(v_line->>'product_id'), v_quantity, v_unit_price, v_unit_cost, v_line_total, v_warehouse);
  end loop;

  update public.pos_sales set total_minor = v_total, cogs_minor = v_cogs where id = v_sale_id;
  v_draft := public.create_journal_draft(
    btrim(p_sale_number), p_sale_date, 'POS sale ' || btrim(p_sale_number), v_currency, 1,
    jsonb_build_array(
      jsonb_build_object('account_id', p_payment_account_id, 'debit_minor', v_total, 'credit_minor', 0, 'currency_code', v_currency, 'line_number', 1),
      jsonb_build_object('account_id', p_revenue_account_id, 'debit_minor', 0, 'credit_minor', v_total, 'currency_code', v_currency, 'line_number', 2)
    ) || case when v_cogs > 0 then jsonb_build_array(
      jsonb_build_object('account_id', p_cogs_account_id, 'debit_minor', v_cogs, 'credit_minor', 0, 'currency_code', v_currency, 'line_number', 3),
      jsonb_build_object('account_id', p_inventory_account_id, 'debit_minor', 0, 'credit_minor', v_cogs, 'currency_code', v_currency, 'line_number', 4)
    ) else '[]'::jsonb end
  );
  v_entry_id := (v_draft->>'id')::uuid;
  update public.journal_entries set source_type = 'pos_sale', source_id = v_sale_id where id = v_entry_id and tenant_id = v_tenant_id;
  update public.pos_sales set journal_entry_id = v_entry_id where id = v_sale_id and tenant_id = v_tenant_id;
  return v_draft || jsonb_build_object('sale_id', v_sale_id, 'total_minor', v_total, 'cogs_minor', v_cogs);
exception when others then
  if v_sale_id is not null then delete from public.pos_sales where id = v_sale_id; end if;
  raise;
end;
$$;

create or replace function public.sync_inventory_after_post()
returns trigger language plpgsql security definer set search_path = public
as $$
declare
  v_receipt public.inventory_receipts;
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

drop trigger if exists inventory_posted_sync on public.journal_entries;
create trigger inventory_posted_sync after update of status on public.journal_entries
for each row execute function public.sync_inventory_after_post();

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['inventory_balances','inventory_receipts','pos_sales','pos_sale_lines'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    IF t <> 'pos_sale_lines' THEN EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t); END IF;
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy inventory_balances_select on public.inventory_balances for select to authenticated using (public.is_tenant_member(tenant_id));
create policy inventory_receipts_select on public.inventory_receipts for select to authenticated using (public.is_tenant_member(tenant_id));
create policy pos_sales_select on public.pos_sales for select to authenticated using (public.is_tenant_member(tenant_id));
create policy pos_sale_lines_select on public.pos_sale_lines for select to authenticated using (public.is_tenant_member(tenant_id));

revoke all on function public.create_inventory_receipt_draft(text, text, numeric, bigint, text, uuid, uuid, text, date) from public, anon;
revoke all on function public.create_pos_sale_draft(text, text, date, text, uuid, uuid, uuid, uuid, jsonb) from public, anon;
grant execute on function public.create_inventory_receipt_draft(text, text, numeric, bigint, text, uuid, uuid, text, date) to authenticated;
grant execute on function public.create_pos_sale_draft(text, text, date, text, uuid, uuid, uuid, uuid, jsonb) to authenticated;
