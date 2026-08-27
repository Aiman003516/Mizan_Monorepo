-- Mizan migration
-- id: 20260828050000_procurement_foundation.sql
-- owner: procurement-and-accounting
-- prerequisites: 20260828040000_settlement_idempotency.sql
-- changes: purchase requisitions, purchase orders, receipt/return evidence, and three-way matching
-- security: tenant/branch scope, procurement permissions, approval gates, RLS, and audit triggers
-- verification: supabase/tests/20260828050000_procurement_foundation.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

-- Extend the governed approval vocabulary before procurement commands use it.
alter table public.approval_requests
  drop constraint if exists approval_requests_request_type_check;
alter table public.approval_requests
  add constraint approval_requests_request_type_check check (request_type in (
    'expense', 'invoice', 'bill', 'journal', 'balance_adjustment',
    'refund', 'discount', 'period_reopen', 'purchase_requisition', 'purchase_order'
  ));

create or replace function public.approval_decision_permission(
  p_tenant_id uuid,
  p_request_type text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_tenant_owner(p_tenant_id)
    or public.has_tenant_permission(p_tenant_id, array['approveRequests', 'manageSettings'])
    or case p_request_type
      when 'journal' then public.has_tenant_permission(p_tenant_id, array['manageAccounting', 'postJournalEntries'])
      when 'invoice' then public.has_tenant_permission(p_tenant_id, array['manageInvoices', 'manageSettings'])
      when 'bill' then public.has_tenant_permission(p_tenant_id, array['manageBills', 'manageSettings'])
      when 'balance_adjustment' then public.has_tenant_permission(p_tenant_id, array['manageAccounting', 'manageSettings'])
      when 'purchase_requisition' then public.has_tenant_permission(p_tenant_id, array['approveProcurement', 'manageProcurement'])
      when 'purchase_order' then public.has_tenant_permission(p_tenant_id, array['approveProcurement', 'manageProcurement'])
      else false
    end;
$$;

create or replace function public.create_approval_request(
  p_tenant_id uuid,
  p_request_type text,
  p_target_id uuid default null,
  p_payload jsonb default '{}'::jsonb,
  p_amount_minor bigint default 0,
  p_currency_code text default 'YER',
  p_reason text default '',
  p_branch_id uuid default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_request public.approval_requests;
begin
  if v_user_id is null or not public.is_tenant_member(p_tenant_id) then
    raise exception 'Authenticated tenant membership required';
  end if;
  if not public.approval_branch_access(p_tenant_id, p_branch_id) then
    raise exception 'Branch access required';
  end if;
  if p_request_type not in (
    'expense', 'invoice', 'bill', 'journal', 'balance_adjustment',
    'refund', 'discount', 'period_reopen', 'purchase_requisition', 'purchase_order'
  ) then
    raise exception 'Approval request type is invalid';
  end if;
  if p_amount_minor is null or p_amount_minor < 0 then
    raise exception 'Approval amount must be non-negative';
  end if;
  if p_currency_code is null or p_currency_code <> upper(btrim(p_currency_code))
     or length(btrim(p_currency_code)) not between 3 and 5 then
    raise exception 'Approval currency code is invalid';
  end if;
  if p_reason is null or length(btrim(p_reason)) not between 1 and 1000 then
    raise exception 'Approval reason is required';
  end if;
  if p_idempotency_key is not null and length(btrim(p_idempotency_key)) not between 8 and 200 then
    raise exception 'Approval idempotency key is invalid';
  end if;

  if p_idempotency_key is not null then
    select * into v_request
    from public.approval_requests
    where tenant_id = p_tenant_id
      and requester_id = v_user_id
      and idempotency_key = btrim(p_idempotency_key)
    limit 1;
    if found then
      return to_jsonb(v_request);
    end if;
  end if;

  insert into public.approval_requests (
    tenant_id, requester_id, request_type, target_id, payload,
    amount_minor, currency_code, reason, branch_id, idempotency_key
  ) values (
    p_tenant_id, v_user_id, p_request_type, p_target_id, coalesce(p_payload, '{}'::jsonb),
    p_amount_minor, upper(btrim(p_currency_code)), btrim(p_reason), p_branch_id,
    nullif(btrim(p_idempotency_key), '')
  ) returning * into v_request;

  insert into public.approval_request_events (
    tenant_id, approval_request_id, actor_id, from_status, to_status, decision_reason
  ) values (p_tenant_id, v_request.id, v_user_id, null, 'pending', v_request.reason);

  return to_jsonb(v_request);
end;
$$;

create table if not exists public.purchase_requisitions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid,
  requester_id uuid not null references auth.users(id) on delete restrict,
  requisition_number text not null check (length(btrim(requisition_number)) between 1 and 80),
  status text not null default 'draft' check (status in ('draft', 'pending_approval', 'approved', 'rejected', 'cancelled', 'converted')),
  needed_by date,
  purpose text not null check (length(btrim(purpose)) between 1 and 1000),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  total_minor bigint not null default 0 check (total_minor >= 0),
  approval_request_id uuid references public.approval_requests(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, requisition_number),
  unique (tenant_id, id),
  foreign key (tenant_id, branch_id) references public.tenant_branches(tenant_id, id) on delete restrict
);

create table if not exists public.purchase_requisition_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  requisition_id uuid not null references public.purchase_requisitions(id) on delete cascade,
  line_number integer not null check (line_number > 0),
  product_id text,
  description text not null check (length(btrim(description)) between 1 and 500),
  quantity numeric(18,6) not null check (quantity > 0),
  estimated_unit_price_minor bigint not null default 0 check (estimated_unit_price_minor >= 0),
  line_total_minor bigint not null default 0 check (line_total_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  unique (requisition_id, line_number),
  unique (tenant_id, id),
  foreign key (tenant_id, requisition_id) references public.purchase_requisitions(tenant_id, id) on delete cascade
);

create table if not exists public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid,
  vendor_id uuid not null references public.vendors(id) on delete restrict,
  requisition_id uuid references public.purchase_requisitions(id) on delete restrict,
  order_number text not null check (length(btrim(order_number)) between 1 and 80),
  status text not null default 'draft' check (status in ('draft', 'pending_approval', 'approved', 'partially_received', 'received', 'closed', 'rejected', 'cancelled')),
  order_date date not null,
  expected_date date,
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  subtotal_minor bigint not null default 0 check (subtotal_minor >= 0),
  tax_minor bigint not null default 0 check (tax_minor >= 0),
  total_minor bigint not null default 0 check (total_minor = subtotal_minor + tax_minor),
  approval_request_id uuid references public.approval_requests(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, order_number),
  unique (tenant_id, id),
  check (expected_date is null or expected_date >= order_date),
  foreign key (tenant_id, branch_id) references public.tenant_branches(tenant_id, id) on delete restrict,
  foreign key (tenant_id, requisition_id) references public.purchase_requisitions(tenant_id, id) on delete restrict
);

create table if not exists public.purchase_order_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  purchase_order_id uuid not null references public.purchase_orders(id) on delete cascade,
  line_number integer not null check (line_number > 0),
  product_id text,
  description text not null check (length(btrim(description)) between 1 and 500),
  ordered_quantity numeric(18,6) not null check (ordered_quantity > 0),
  unit_price_minor bigint not null check (unit_price_minor >= 0),
  tax_minor bigint not null default 0 check (tax_minor >= 0),
  line_total_minor bigint not null check (line_total_minor = round(ordered_quantity * unit_price_minor) + tax_minor),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  unique (purchase_order_id, line_number),
  unique (tenant_id, id),
  foreign key (tenant_id, purchase_order_id) references public.purchase_orders(tenant_id, id) on delete cascade
);

create table if not exists public.purchase_receipts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  purchase_order_id uuid not null references public.purchase_orders(id) on delete restrict,
  warehouse_id text not null default 'default' check (length(btrim(warehouse_id)) between 1 and 80),
  receipt_number text not null check (length(btrim(receipt_number)) between 1 and 80),
  receipt_date date not null,
  status text not null default 'draft' check (status in ('draft', 'posted', 'void')),
  received_by uuid references auth.users(id) on delete set null,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, receipt_number),
  unique (tenant_id, id),
  foreign key (tenant_id, purchase_order_id) references public.purchase_orders(tenant_id, id) on delete restrict
);

create table if not exists public.purchase_receipt_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  receipt_id uuid not null references public.purchase_receipts(id) on delete cascade,
  purchase_order_line_id uuid not null references public.purchase_order_lines(id) on delete restrict,
  quantity numeric(18,6) not null check (quantity > 0),
  unit_cost_minor bigint not null check (unit_cost_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  unique (tenant_id, id),
  foreign key (tenant_id, receipt_id) references public.purchase_receipts(tenant_id, id) on delete cascade,
  foreign key (tenant_id, purchase_order_line_id) references public.purchase_order_lines(tenant_id, id) on delete restrict
);

create table if not exists public.purchase_returns (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  purchase_order_id uuid not null references public.purchase_orders(id) on delete restrict,
  receipt_id uuid references public.purchase_receipts(id) on delete restrict,
  return_number text not null check (length(btrim(return_number)) between 1 and 80),
  return_date date not null,
  status text not null default 'draft' check (status in ('draft', 'posted', 'void')),
  reason text not null check (length(btrim(reason)) between 1 and 1000),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, return_number),
  unique (tenant_id, id),
  foreign key (tenant_id, purchase_order_id) references public.purchase_orders(tenant_id, id) on delete restrict,
  foreign key (tenant_id, receipt_id) references public.purchase_receipts(tenant_id, id) on delete restrict
);

create table if not exists public.purchase_return_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  return_id uuid not null references public.purchase_returns(id) on delete cascade,
  purchase_order_line_id uuid not null references public.purchase_order_lines(id) on delete restrict,
  quantity numeric(18,6) not null check (quantity > 0),
  unit_cost_minor bigint not null check (unit_cost_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  unique (tenant_id, id),
  foreign key (tenant_id, return_id) references public.purchase_returns(tenant_id, id) on delete cascade,
  foreign key (tenant_id, purchase_order_line_id) references public.purchase_order_lines(tenant_id, id) on delete restrict
);

alter table public.bills add column if not exists purchase_order_id uuid references public.purchase_orders(id) on delete restrict;
alter table public.bill_items add column if not exists purchase_order_line_id uuid references public.purchase_order_lines(id) on delete restrict;

create unique index if not exists vendors_tenant_id_unique_idx on public.vendors (tenant_id, id);
create unique index if not exists approval_requests_tenant_id_unique_idx on public.approval_requests (tenant_id, id);
create unique index if not exists bills_tenant_id_unique_idx on public.bills (tenant_id, id);
create unique index if not exists bill_items_tenant_id_unique_idx on public.bill_items (tenant_id, id);

alter table public.purchase_orders
  add constraint purchase_orders_vendor_tenant_fk
  foreign key (tenant_id, vendor_id) references public.vendors(tenant_id, id) on delete restrict;
alter table public.purchase_requisitions
  add constraint purchase_requisitions_approval_tenant_fk
  foreign key (tenant_id, approval_request_id) references public.approval_requests(tenant_id, id) on delete restrict;
alter table public.purchase_orders
  add constraint purchase_orders_approval_tenant_fk
  foreign key (tenant_id, approval_request_id) references public.approval_requests(tenant_id, id) on delete restrict;
alter table public.bills
  add constraint bills_purchase_order_tenant_fk
  foreign key (tenant_id, purchase_order_id) references public.purchase_orders(tenant_id, id) on delete restrict;
alter table public.bill_items
  add constraint bill_items_purchase_order_line_tenant_fk
  foreign key (tenant_id, purchase_order_line_id) references public.purchase_order_lines(tenant_id, id) on delete restrict;

create index if not exists purchase_requisitions_tenant_status_idx
 on public.purchase_requisitions (tenant_id, status, created_at desc, id);
create index if not exists purchase_orders_tenant_status_idx on public.purchase_orders (tenant_id, status, order_date desc, id);
create index if not exists purchase_orders_vendor_idx on public.purchase_orders (tenant_id, vendor_id, status, order_date desc, id);
create index if not exists purchase_order_lines_order_idx on public.purchase_order_lines (tenant_id, purchase_order_id, line_number);
create index if not exists purchase_receipts_order_status_idx on public.purchase_receipts (tenant_id, purchase_order_id, status, receipt_date, id);
create index if not exists purchase_receipt_lines_po_line_idx on public.purchase_receipt_lines (tenant_id, purchase_order_line_id, receipt_id);
create index if not exists purchase_returns_po_status_idx on public.purchase_returns (tenant_id, purchase_order_id, status, return_date, id);
create index if not exists purchase_return_lines_po_line_idx on public.purchase_return_lines (tenant_id, purchase_order_line_id, return_id);
create index if not exists bills_purchase_order_idx on public.bills (tenant_id, purchase_order_id, id);
create index if not exists bill_items_purchase_order_line_idx on public.bill_items (tenant_id, purchase_order_line_id, id);

create or replace function public.create_purchase_requisition(
  p_requisition_number text,
  p_branch_id uuid,
  p_needed_by date,
  p_purpose text,
  p_currency_code text,
  p_lines jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := (select auth.uid());
  v_req_id uuid;
  v_line jsonb;
  v_line_number integer := 0;
  v_quantity numeric;
  v_unit_price bigint;
  v_line_total bigint;
  v_total bigint := 0;
  v_currency text := upper(btrim(p_currency_code));
  v_purpose text := btrim(p_purpose);
begin
  if v_user_id is null or v_tenant_id is null or not public.is_tenant_member(v_tenant_id) then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageProcurement', 'manageSettings']) then raise exception 'Procurement permission required'; end if;
  if not public.approval_branch_access(v_tenant_id, p_branch_id) then raise exception 'Branch access required'; end if;
  if p_requisition_number is null or length(btrim(p_requisition_number)) not between 1 and 80 then raise exception 'Requisition number is invalid'; end if;
  if v_purpose is null or length(v_purpose) not between 1 and 1000 then raise exception 'Requisition purpose is required'; end if;
  if v_currency !~ '^[A-Z]{3,5}$' or p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then raise exception 'Requisition data is invalid'; end if;

  insert into public.purchase_requisitions (tenant_id, branch_id, requester_id, requisition_number, needed_by, purpose, currency_code, created_by)
  values (v_tenant_id, p_branch_id, v_user_id, btrim(p_requisition_number), p_needed_by, v_purpose, v_currency, v_user_id)
  returning id into v_req_id;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_line_number := v_line_number + 1;
    v_quantity := (v_line->>'quantity')::numeric;
    v_unit_price := (v_line->>'estimated_unit_price_minor')::bigint;
    if v_quantity is null or v_quantity <= 0 or v_unit_price is null or v_unit_price < 0 then raise exception 'Requisition line quantity or price is invalid'; end if;
    if v_line->>'description' is null or length(btrim(v_line->>'description')) not between 1 and 500 then raise exception 'Requisition line description is required'; end if;
    v_line_total := round(v_quantity * v_unit_price)::bigint;
    v_total := v_total + v_line_total;
    insert into public.purchase_requisition_lines (tenant_id, requisition_id, line_number, product_id, description, quantity, estimated_unit_price_minor, line_total_minor, currency_code)
    values (v_tenant_id, v_req_id, v_line_number, nullif(btrim(v_line->>'product_id'), ''), btrim(v_line->>'description'), v_quantity, v_unit_price, v_line_total, v_currency);
  end loop;

  update public.purchase_requisitions set total_minor = v_total where id = v_req_id and tenant_id = v_tenant_id;
  return jsonb_build_object('requisition_id', v_req_id, 'requisition_number', btrim(p_requisition_number), 'status', 'draft', 'total_minor', v_total, 'currency_code', v_currency);
end;
$$;

create or replace function public.submit_purchase_requisition_for_approval(
  p_requisition_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_req public.purchase_requisitions;
  v_approval jsonb;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'Purchase requisition approval');
  v_key text;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  select * into v_req from public.purchase_requisitions where id = p_requisition_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Purchase requisition was not found'; end if;
  if v_req.status <> 'draft' then raise exception 'Only draft requisitions can be submitted'; end if;
  v_key := 'purchase-requisition:' || v_req.id::text;
  v_approval := public.create_approval_request(
    v_tenant_id,
    'purchase_requisition',
    v_req.id,
    jsonb_build_object('requisition_id', v_req.id, 'requisition_number', v_req.requisition_number, 'total_minor', v_req.total_minor, 'currency_code', v_req.currency_code),
    v_req.total_minor,
    v_req.currency_code,
    v_reason,
    v_req.branch_id,
    v_key
  );
  update public.purchase_requisitions set status = 'pending_approval', approval_request_id = (v_approval->>'id')::uuid where id = v_req.id and tenant_id = v_tenant_id;
  return v_approval || jsonb_build_object('requisition_id', v_req.id);
end;
$$;

create or replace function public.create_purchase_order_draft(
  p_order_number text,
  p_vendor_id uuid,
  p_requisition_id uuid,
  p_branch_id uuid,
  p_order_date date,
  p_expected_date date,
  p_currency_code text,
  p_lines jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := (select auth.uid());
  v_po_id uuid;
  v_req public.purchase_requisitions;
  v_line jsonb;
  v_line_number integer := 0;
  v_quantity numeric;
  v_unit_price bigint;
  v_tax bigint;
  v_line_total bigint;
  v_subtotal bigint := 0;
  v_tax_total bigint := 0;
  v_currency text := upper(btrim(p_currency_code));
begin
  if v_user_id is null or v_tenant_id is null or not public.is_tenant_member(v_tenant_id) then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageProcurement', 'manageSettings']) then raise exception 'Procurement permission required'; end if;
  if not public.approval_branch_access(v_tenant_id, p_branch_id) then raise exception 'Branch access required'; end if;
  if p_order_number is null or length(btrim(p_order_number)) not between 1 and 80 then raise exception 'Purchase order number is invalid'; end if;
  if not exists (select 1 from public.vendors v where v.id = p_vendor_id and v.tenant_id = v_tenant_id and not v.is_deleted) then raise exception 'Vendor does not belong to the tenant'; end if;
  if p_order_date is null or (p_expected_date is not null and p_expected_date < p_order_date) then raise exception 'Purchase order dates are invalid'; end if;
  if v_currency !~ '^[A-Z]{3,5}$' or p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then raise exception 'Purchase order data is invalid'; end if;
  if p_requisition_id is not null then
    select * into v_req from public.purchase_requisitions where id = p_requisition_id and tenant_id = v_tenant_id for share;
    if not found or v_req.status <> 'approved' then raise exception 'An approved requisition is required'; end if;
  end if;

  insert into public.purchase_orders (tenant_id, branch_id, vendor_id, requisition_id, order_number, order_date, expected_date, currency_code, created_by)
  values (v_tenant_id, p_branch_id, p_vendor_id, p_requisition_id, btrim(p_order_number), p_order_date, p_expected_date, v_currency, v_user_id)
  returning id into v_po_id;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_line_number := v_line_number + 1;
    v_quantity := (v_line->>'ordered_quantity')::numeric;
    v_unit_price := (v_line->>'unit_price_minor')::bigint;
    v_tax := coalesce((v_line->>'tax_minor')::bigint, 0);
    if v_quantity is null or v_quantity <= 0 or v_unit_price is null or v_unit_price < 0 or v_tax < 0 then raise exception 'Purchase order line quantity or price is invalid'; end if;
    if v_line->>'description' is null or length(btrim(v_line->>'description')) not between 1 and 500 then raise exception 'Purchase order line description is required'; end if;
    v_line_total := round(v_quantity * v_unit_price)::bigint + v_tax;
    v_subtotal := v_subtotal + round(v_quantity * v_unit_price)::bigint;
    v_tax_total := v_tax_total + v_tax;
    insert into public.purchase_order_lines (tenant_id, purchase_order_id, line_number, product_id, description, ordered_quantity, unit_price_minor, tax_minor, line_total_minor, currency_code)
    values (v_tenant_id, v_po_id, v_line_number, nullif(btrim(v_line->>'product_id'), ''), btrim(v_line->>'description'), v_quantity, v_unit_price, v_tax, v_line_total, v_currency);
  end loop;

  update public.purchase_orders set subtotal_minor = v_subtotal, tax_minor = v_tax_total, total_minor = v_subtotal + v_tax_total where id = v_po_id and tenant_id = v_tenant_id;
  return jsonb_build_object('purchase_order_id', v_po_id, 'order_number', btrim(p_order_number), 'status', 'draft', 'subtotal_minor', v_subtotal, 'tax_minor', v_tax_total, 'total_minor', v_subtotal + v_tax_total, 'currency_code', v_currency);
end;
$$;

create or replace function public.submit_purchase_order_for_approval(
  p_purchase_order_id uuid,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_po public.purchase_orders;
  v_approval jsonb;
  v_reason text := coalesce(nullif(btrim(p_reason), ''), 'Purchase order approval');
  v_key text;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  select * into v_po from public.purchase_orders where id = p_purchase_order_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Purchase order was not found'; end if;
  if v_po.status <> 'draft' then raise exception 'Only draft purchase orders can be submitted'; end if;
  v_key := 'purchase-order:' || v_po.id::text;
  v_approval := public.create_approval_request(
    v_tenant_id,
    'purchase_order',
    v_po.id,
    jsonb_build_object('purchase_order_id', v_po.id, 'order_number', v_po.order_number, 'vendor_id', v_po.vendor_id, 'total_minor', v_po.total_minor, 'currency_code', v_po.currency_code),
    v_po.total_minor,
    v_po.currency_code,
    v_reason,
    v_po.branch_id,
    v_key
  );
  update public.purchase_orders set status = 'pending_approval', approval_request_id = (v_approval->>'id')::uuid where id = v_po.id and tenant_id = v_tenant_id;
  return v_approval || jsonb_build_object('purchase_order_id', v_po.id);
end;
$$;

create or replace function public.sync_procurement_approval_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'approved' and new.request_type = 'purchase_requisition' then
    update public.purchase_requisitions set status = 'approved' where id = new.target_id and tenant_id = new.tenant_id and status = 'pending_approval';
  elsif new.status = 'rejected' and new.request_type = 'purchase_requisition' then
    update public.purchase_requisitions set status = 'rejected' where id = new.target_id and tenant_id = new.tenant_id and status = 'pending_approval';
  elsif new.status = 'approved' and new.request_type = 'purchase_order' then
    update public.purchase_orders set status = 'approved' where id = new.target_id and tenant_id = new.tenant_id and status = 'pending_approval';
  elsif new.status = 'rejected' and new.request_type = 'purchase_order' then
    update public.purchase_orders set status = 'rejected' where id = new.target_id and tenant_id = new.tenant_id and status = 'pending_approval';
  end if;
  return new;
end;
$$;

drop trigger if exists approval_requests_procurement_state on public.approval_requests;
create trigger approval_requests_procurement_state
after update of status on public.approval_requests
for each row execute function public.sync_procurement_approval_state();

create or replace function public.create_purchase_receipt_draft(
  p_purchase_order_id uuid,
  p_receipt_number text,
  p_warehouse_id text,
  p_receipt_date date,
  p_lines jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_po public.purchase_orders;
  v_receipt_id uuid;
  v_line jsonb;
  v_po_line public.purchase_order_lines;
  v_quantity numeric;
  v_received numeric;
  v_returned numeric;
  v_line_count integer := 0;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['receiveInventory', 'manageProcurement', 'adjustInventory']) then raise exception 'Receiving permission required'; end if;
  select * into v_po from public.purchase_orders where id = p_purchase_order_id and tenant_id = v_tenant_id for share;
  if not found or v_po.status not in ('approved', 'partially_received') then raise exception 'Purchase order is not ready for receiving'; end if;
  if p_receipt_number is null or length(btrim(p_receipt_number)) not between 1 and 80 or p_receipt_date is null or p_receipt_date < v_po.order_date then raise exception 'Receipt data is invalid'; end if;
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then raise exception 'Receipt lines are required'; end if;

  insert into public.purchase_receipts (tenant_id, purchase_order_id, warehouse_id, receipt_number, receipt_date, received_by)
  values (v_tenant_id, v_po.id, coalesce(nullif(btrim(p_warehouse_id), ''), 'default'), btrim(p_receipt_number), p_receipt_date, auth.uid())
  returning id into v_receipt_id;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_line_count := v_line_count + 1;
    select * into v_po_line from public.purchase_order_lines where id = (v_line->>'purchase_order_line_id')::uuid and purchase_order_id = v_po.id and tenant_id = v_tenant_id;
    if not found then raise exception 'Receipt line is not linked to this purchase order'; end if;
    v_quantity := (v_line->>'quantity')::numeric;
    if v_quantity is null or v_quantity <= 0 then raise exception 'Receipt quantity must be positive'; end if;
    select coalesce(sum(prl.quantity), 0) into v_received from public.purchase_receipt_lines prl join public.purchase_receipts pr on pr.id = prl.receipt_id where prl.purchase_order_line_id = v_po_line.id and prl.tenant_id = v_tenant_id and pr.status = 'posted';
    select coalesce(sum(prtl.quantity), 0) into v_returned from public.purchase_return_lines prtl join public.purchase_returns prt on prt.id = prtl.return_id where prtl.purchase_order_line_id = v_po_line.id and prtl.tenant_id = v_tenant_id and prt.status = 'posted';
    if v_received - v_returned + v_quantity > v_po_line.ordered_quantity then raise exception 'Receipt exceeds the ordered quantity'; end if;
    insert into public.purchase_receipt_lines (tenant_id, receipt_id, purchase_order_line_id, quantity, unit_cost_minor, currency_code)
    values (v_tenant_id, v_receipt_id, v_po_line.id, v_quantity, coalesce((v_line->>'unit_cost_minor')::bigint, v_po_line.unit_price_minor), v_po.currency_code);
  end loop;
  if v_line_count = 0 then raise exception 'Receipt lines are required'; end if;
  return jsonb_build_object('receipt_id', v_receipt_id, 'purchase_order_id', v_po.id, 'status', 'draft');
end;
$$;

create or replace function public.post_purchase_receipt(p_receipt_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_receipt public.purchase_receipts;
  v_purchase_order public.purchase_orders;
  v_total_lines bigint;
  v_receipt_quantity numeric;
  v_received numeric;
  v_returned numeric;
  v_net_received numeric;
  v_ordered numeric;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['receiveInventory', 'manageProcurement', 'adjustInventory']) then raise exception 'Receiving permission required'; end if;
  select * into v_receipt from public.purchase_receipts where id = p_receipt_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Purchase receipt was not found'; end if;
  select * into v_purchase_order from public.purchase_orders where id = v_receipt.purchase_order_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Purchase order was not found'; end if;
  select count(*) into v_total_lines from public.purchase_receipt_lines where receipt_id = v_receipt.id and tenant_id = v_tenant_id;
  if v_receipt.status = 'posted' then
    return jsonb_build_object('receipt_id', v_receipt.id, 'purchase_order_id', v_receipt.purchase_order_id, 'status', 'posted', 'line_count', v_total_lines);
  end if;
  if v_receipt.status <> 'draft' then raise exception 'Only draft receipts can be posted'; end if;
  if v_purchase_order.status not in ('approved', 'partially_received') then raise exception 'Purchase order is not ready for receiving'; end if;
  if v_total_lines = 0 then raise exception 'Receipt has no lines'; end if;
  select coalesce(sum(prl.quantity), 0) into v_receipt_quantity
  from public.purchase_receipt_lines prl
  where prl.receipt_id = v_receipt.id and prl.tenant_id = v_tenant_id;
  select coalesce(sum(prl.quantity), 0) into v_received
  from public.purchase_receipt_lines prl
  join public.purchase_receipts pr on pr.id = prl.receipt_id
  where prl.tenant_id = v_tenant_id
    and pr.purchase_order_id = v_receipt.purchase_order_id
    and pr.status = 'posted';
  select coalesce(sum(prtl.quantity), 0) into v_returned
  from public.purchase_return_lines prtl
  join public.purchase_returns prt on prt.id = prtl.return_id
  where prtl.tenant_id = v_tenant_id
    and prt.purchase_order_id = v_receipt.purchase_order_id
    and prt.status = 'posted';
  select coalesce(sum(pol.ordered_quantity), 0) into v_ordered
  from public.purchase_order_lines pol
  where pol.tenant_id = v_tenant_id and pol.purchase_order_id = v_receipt.purchase_order_id;
  if v_received - v_returned + v_receipt_quantity > v_ordered then raise exception 'Receipt exceeds the ordered quantity'; end if;
  update public.purchase_receipts set status = 'posted' where id = v_receipt.id and tenant_id = v_tenant_id;
  v_net_received := v_received - v_returned + v_receipt_quantity;
  update public.purchase_orders
  set status = case when v_net_received >= v_ordered then 'received' else 'partially_received' end
  where id = v_receipt.purchase_order_id and tenant_id = v_tenant_id and status in ('approved', 'partially_received');
  return jsonb_build_object('receipt_id', v_receipt.id, 'purchase_order_id', v_receipt.purchase_order_id, 'status', 'posted', 'line_count', v_total_lines);
end;
$$;

create or replace function public.create_purchase_return_draft(
  p_purchase_order_id uuid,
  p_receipt_id uuid,
  p_return_number text,
  p_return_date date,
  p_reason text,
  p_lines jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_return_id uuid;
  v_line jsonb;
  v_po_line public.purchase_order_lines;
  v_quantity numeric;
  v_received numeric;
  v_returned numeric;
  v_po public.purchase_orders;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['receiveInventory', 'manageProcurement', 'adjustInventory']) then raise exception 'Return permission required'; end if;
  select * into v_po from public.purchase_orders where id = p_purchase_order_id and tenant_id = v_tenant_id for share;
  if not found or v_po.status not in ('approved', 'partially_received', 'received') then raise exception 'Purchase order is not ready for return'; end if;
  if p_receipt_id is not null and not exists (select 1 from public.purchase_receipts where id = p_receipt_id and purchase_order_id = v_po.id and tenant_id = v_tenant_id and status = 'posted') then raise exception 'Return receipt is invalid'; end if;
  if p_return_number is null or length(btrim(p_return_number)) not between 1 and 80 or p_reason is null or length(btrim(p_reason)) not between 1 and 1000 or p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then raise exception 'Return data is invalid'; end if;

  insert into public.purchase_returns (tenant_id, purchase_order_id, receipt_id, return_number, return_date, reason, created_by)
  values (v_tenant_id, v_po.id, p_receipt_id, btrim(p_return_number), p_return_date, btrim(p_reason), auth.uid())
  returning id into v_return_id;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    select * into v_po_line from public.purchase_order_lines where id = (v_line->>'purchase_order_line_id')::uuid and purchase_order_id = v_po.id and tenant_id = v_tenant_id;
    if not found then raise exception 'Return line is not linked to this purchase order'; end if;
    v_quantity := (v_line->>'quantity')::numeric;
    if v_quantity is null or v_quantity <= 0 then raise exception 'Return quantity must be positive'; end if;
    select coalesce(sum(prl.quantity), 0) into v_received from public.purchase_receipt_lines prl join public.purchase_receipts pr on pr.id = prl.receipt_id where prl.purchase_order_line_id = v_po_line.id and prl.tenant_id = v_tenant_id and pr.status = 'posted';
    select coalesce(sum(prtl.quantity), 0) into v_returned from public.purchase_return_lines prtl join public.purchase_returns prt on prt.id = prtl.return_id where prtl.purchase_order_line_id = v_po_line.id and prtl.tenant_id = v_tenant_id and prt.status = 'posted';
    if v_returned + v_quantity > v_received then raise exception 'Return exceeds the received quantity'; end if;
    insert into public.purchase_return_lines (tenant_id, return_id, purchase_order_line_id, quantity, unit_cost_minor, currency_code)
    values (v_tenant_id, v_return_id, v_po_line.id, v_quantity, coalesce((v_line->>'unit_cost_minor')::bigint, v_po_line.unit_price_minor), v_po.currency_code);
  end loop;
  return jsonb_build_object('return_id', v_return_id, 'purchase_order_id', v_po.id, 'status', 'draft');
end;
$$;

create or replace function public.post_purchase_return(p_return_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_return public.purchase_returns;
  v_purchase_order public.purchase_orders;
  v_lines bigint;
  v_return_quantity numeric;
  v_received numeric;
  v_returned numeric;
  v_net_received numeric;
  v_ordered numeric;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['receiveInventory', 'manageProcurement', 'adjustInventory']) then raise exception 'Return permission required'; end if;
  select * into v_return from public.purchase_returns where id = p_return_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Purchase return was not found'; end if;
  select * into v_purchase_order from public.purchase_orders where id = v_return.purchase_order_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Purchase order was not found'; end if;
  select count(*) into v_lines from public.purchase_return_lines where return_id = v_return.id and tenant_id = v_tenant_id;
  if v_return.status = 'posted' then
    return jsonb_build_object('return_id', v_return.id, 'purchase_order_id', v_return.purchase_order_id, 'status', 'posted', 'line_count', v_lines);
  end if;
  if v_return.status <> 'draft' then raise exception 'Only draft returns can be posted'; end if;
  if v_purchase_order.status not in ('approved', 'partially_received', 'received') then raise exception 'Purchase order is not ready for return'; end if;
  if v_lines = 0 then raise exception 'Return has no lines'; end if;
  select coalesce(sum(prtl.quantity), 0) into v_return_quantity
  from public.purchase_return_lines prtl
  where prtl.return_id = v_return.id and prtl.tenant_id = v_tenant_id;
  select coalesce(sum(prl.quantity), 0) into v_received
  from public.purchase_receipt_lines prl
  join public.purchase_receipts pr on pr.id = prl.receipt_id
  where prl.tenant_id = v_tenant_id
    and pr.purchase_order_id = v_return.purchase_order_id
    and pr.status = 'posted';
  select coalesce(sum(prtl.quantity), 0) into v_returned
  from public.purchase_return_lines prtl
  join public.purchase_returns prt on prt.id = prtl.return_id
  where prtl.tenant_id = v_tenant_id
    and prt.purchase_order_id = v_return.purchase_order_id
    and prt.status = 'posted';
  if v_returned + v_return_quantity > v_received then raise exception 'Return exceeds the received quantity'; end if;
  select coalesce(sum(pol.ordered_quantity), 0) into v_ordered
  from public.purchase_order_lines pol
  where pol.tenant_id = v_tenant_id and pol.purchase_order_id = v_return.purchase_order_id;
  update public.purchase_returns set status = 'posted' where id = v_return.id and tenant_id = v_tenant_id;
  v_net_received := v_received - v_returned - v_return_quantity;
  update public.purchase_orders
  set status = case when v_net_received >= v_ordered then 'received' else 'partially_received' end
  where id = v_return.purchase_order_id and tenant_id = v_tenant_id and status in ('approved', 'partially_received', 'received');
  return jsonb_build_object('return_id', v_return.id, 'purchase_order_id', v_return.purchase_order_id, 'status', 'posted', 'line_count', v_lines);
end;
$$;

create or replace function public.purchase_bill_three_way_match(p_bill_id uuid)
returns table(
  bill_line_id uuid,
  purchase_order_id uuid,
  purchase_order_line_id uuid,
  ordered_quantity numeric,
  received_quantity numeric,
  returned_quantity numeric,
  available_quantity numeric,
  billed_quantity numeric,
  ordered_unit_price_minor bigint,
  billed_unit_price_minor bigint,
  price_variance_minor bigint,
  currency_code text,
  match_status text,
  blocking_reason text
)
language sql
stable
security definer
set search_path = public
as $$
  with bill_context as (
    select b.id, b.tenant_id, b.vendor_id, b.purchase_order_id, b.currency_code
    from public.bills b
    where b.id = p_bill_id
      and b.tenant_id = public.current_tenant_id()
      and b.status <> 'void'
  ),
  received as (
    select prl.purchase_order_line_id, sum(prl.quantity) as quantity
    from public.purchase_receipt_lines prl
    join public.purchase_receipts pr on pr.id = prl.receipt_id and pr.status = 'posted' and pr.tenant_id = prl.tenant_id
    join bill_context bc on bc.tenant_id = pr.tenant_id
    group by prl.purchase_order_line_id
  ),
  returned as (
    select prl.purchase_order_line_id, sum(prl.quantity) as quantity
    from public.purchase_return_lines prl
    join public.purchase_returns pr on pr.id = prl.return_id and pr.status = 'posted' and pr.tenant_id = prl.tenant_id
    join bill_context bc on bc.tenant_id = pr.tenant_id
    group by prl.purchase_order_line_id
  ),
  billed as (
    select bi2.purchase_order_line_id, sum(bi2.quantity) as quantity
    from public.bill_items bi2
    join public.bills b2 on b2.id = bi2.bill_id and b2.tenant_id = bi2.tenant_id and b2.status <> 'void'
    join bill_context bc on bc.purchase_order_id = b2.purchase_order_id and bc.tenant_id = b2.tenant_id
    group by bi2.purchase_order_line_id
  )
  select
    bi.id,
    bc.purchase_order_id,
    bi.purchase_order_line_id,
    pol.ordered_quantity,
    coalesce(r.quantity, 0)::numeric,
    coalesce(rt.quantity, 0)::numeric,
    (coalesce(r.quantity, 0) - coalesce(rt.quantity, 0))::numeric,
    coalesce(bl.quantity, 0)::numeric,
    pol.unit_price_minor,
    bi.unit_price,
    case when pol.unit_price_minor is null then null else abs(bi.unit_price - pol.unit_price_minor) end,
    bc.currency_code,
    case
      when bc.purchase_order_id is null or bi.purchase_order_line_id is null then 'blocked'
      when pol.id is null then 'blocked'
      when pol.purchase_order_id is distinct from bc.purchase_order_id then 'blocked'
      when po.vendor_id is distinct from bc.vendor_id then 'blocked'
      when pol.currency_code is distinct from bc.currency_code then 'blocked'
      when coalesce(r.quantity, 0) - coalesce(rt.quantity, 0) > pol.ordered_quantity then 'blocked'
      when coalesce(bl.quantity, 0) > pol.ordered_quantity then 'blocked'
      when coalesce(bl.quantity, 0) > (coalesce(r.quantity, 0) - coalesce(rt.quantity, 0)) then 'blocked'
      when abs(bi.unit_price - pol.unit_price_minor) > 0 then 'blocked'
      else 'matched'
    end,
    case
      when bc.purchase_order_id is null or bi.purchase_order_line_id is null then 'Purchase order linkage is required.'
      when pol.id is null then 'Purchase order line was not found.'
      when pol.purchase_order_id is distinct from bc.purchase_order_id then 'Purchase order line is linked to a different purchase order.'
      when po.vendor_id is distinct from bc.vendor_id then 'Vendor does not match the purchase order.'
      when pol.currency_code is distinct from bc.currency_code then 'Currency does not match the purchase order.'
      when coalesce(r.quantity, 0) - coalesce(rt.quantity, 0) > pol.ordered_quantity then 'Received quantity exceeds ordered quantity.'
      when coalesce(bl.quantity, 0) > pol.ordered_quantity then 'Cumulative billed quantity exceeds ordered quantity.'
      when coalesce(bl.quantity, 0) > (coalesce(r.quantity, 0) - coalesce(rt.quantity, 0)) then 'Cumulative billed quantity exceeds received quantity after returns.'
      when abs(bi.unit_price - pol.unit_price_minor) > 0 then 'Billed unit price does not match the purchase order.'
      else null
    end
  from public.bill_items bi
  join bill_context bc on bc.id = bi.bill_id
  left join public.purchase_order_lines pol on pol.id = bi.purchase_order_line_id and pol.tenant_id = bc.tenant_id
  left join public.purchase_orders po on po.id = bc.purchase_order_id and po.tenant_id = bc.tenant_id
  left join received r on r.purchase_order_line_id = bi.purchase_order_line_id
  left join returned rt on rt.purchase_order_line_id = bi.purchase_order_line_id
  left join billed bl on bl.purchase_order_line_id = bi.purchase_order_line_id
  order by bi.id;
$$;

-- Approval decisions update procurement state through the trigger above; direct writes
-- to procurement workflow tables remain unavailable to clients.
do $$
declare t text;
begin
  foreach t in array array['purchase_requisitions','purchase_requisition_lines','purchase_orders','purchase_order_lines','purchase_receipts','purchase_receipt_lines','purchase_returns','purchase_return_lines'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon, authenticated', t);
    execute format('grant select on table public.%I to authenticated', t);
    execute format('drop trigger if exists %I_updated_at on public.%I', t, t);
    if t in ('purchase_requisitions','purchase_orders','purchase_receipts','purchase_returns') then
      execute format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    end if;
    execute format('drop trigger if exists %I_audit on public.%I', t, t);
    execute format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
  end loop;
end;
$$;

drop policy if exists purchase_requisitions_select on public.purchase_requisitions;
create policy purchase_requisitions_select on public.purchase_requisitions for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_requisition_lines_select on public.purchase_requisition_lines;
create policy purchase_requisition_lines_select on public.purchase_requisition_lines for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_orders_select on public.purchase_orders;
create policy purchase_orders_select on public.purchase_orders for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_order_lines_select on public.purchase_order_lines;
create policy purchase_order_lines_select on public.purchase_order_lines for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_receipts_select on public.purchase_receipts;
create policy purchase_receipts_select on public.purchase_receipts for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_receipt_lines_select on public.purchase_receipt_lines;
create policy purchase_receipt_lines_select on public.purchase_receipt_lines for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_returns_select on public.purchase_returns;
create policy purchase_returns_select on public.purchase_returns for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));
drop policy if exists purchase_return_lines_select on public.purchase_return_lines;
create policy purchase_return_lines_select on public.purchase_return_lines for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));

revoke all on function public.create_purchase_requisition(text, uuid, date, text, text, jsonb) from public, anon, authenticated;
revoke all on function public.submit_purchase_requisition_for_approval(uuid, text) from public, anon, authenticated;
revoke all on function public.create_purchase_order_draft(text, uuid, uuid, uuid, date, date, text, jsonb) from public, anon, authenticated;
revoke all on function public.submit_purchase_order_for_approval(uuid, text) from public, anon, authenticated;
revoke all on function public.create_purchase_receipt_draft(uuid, text, text, date, jsonb) from public, anon, authenticated;
revoke all on function public.post_purchase_receipt(uuid) from public, anon, authenticated;
revoke all on function public.create_purchase_return_draft(uuid, uuid, text, date, text, jsonb) from public, anon, authenticated;
revoke all on function public.post_purchase_return(uuid) from public, anon, authenticated;
revoke all on function public.purchase_bill_three_way_match(uuid) from public, anon, authenticated;
grant execute on function public.create_purchase_requisition(text, uuid, date, text, text, jsonb) to authenticated;
grant execute on function public.submit_purchase_requisition_for_approval(uuid, text) to authenticated;
grant execute on function public.create_purchase_order_draft(text, uuid, uuid, uuid, date, date, text, jsonb) to authenticated;
grant execute on function public.submit_purchase_order_for_approval(uuid, text) to authenticated;
grant execute on function public.create_purchase_receipt_draft(uuid, text, text, date, jsonb) to authenticated;
grant execute on function public.post_purchase_receipt(uuid) to authenticated;
grant execute on function public.create_purchase_return_draft(uuid, uuid, text, date, text, jsonb) to authenticated;
grant execute on function public.post_purchase_return(uuid) to authenticated;
grant execute on function public.purchase_bill_three_way_match(uuid) to authenticated;
