-- Manual customer/supplier balance adjustments.
-- Every successful adjustment creates one posted, balanced journal entry and one
-- adjustment-register row in the same transaction. Direct table writes remain
-- blocked; clients use post_manual_balance_adjustment().

create table if not exists public.balance_adjustments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  party_type text not null check (party_type in ('customer', 'vendor')),
  party_id uuid not null,
  amount_minor bigint not null check (amount_minor > 0),
  direction text not null check (direction in ('increase', 'decrease')),
  currency_code text not null check (currency_code = upper(currency_code) and currency_code ~ '^[A-Z]{3,5}$'),
  reason text not null check (length(btrim(reason)) between 3 and 500),
  reference text check (reference is null or length(btrim(reference)) between 1 and 120),
  effective_date date not null,
  debit_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  credit_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  journal_entry_id uuid not null references public.journal_entries(id) on delete restrict,
  status text not null default 'posted' check (status in ('posted', 'reversed')),
  idempotency_key text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id),
  unique (tenant_id, idempotency_key),
  check (debit_account_id <> credit_account_id)
);

create index if not exists balance_adjustments_party_date_idx
  on public.balance_adjustments (tenant_id, party_type, party_id, effective_date desc, id desc);
create index if not exists balance_adjustments_journal_idx
  on public.balance_adjustments (tenant_id, journal_entry_id);

alter table public.balance_adjustments enable row level security;
revoke all on table public.balance_adjustments from anon, authenticated;
drop policy if exists balance_adjustments_select on public.balance_adjustments;
create policy balance_adjustments_select on public.balance_adjustments
for select to authenticated
using (public.is_tenant_member(tenant_id));
grant select on public.balance_adjustments to authenticated;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (
       SELECT 1 FROM pg_publication_tables
       WHERE pubname = 'supabase_realtime'
         AND schemaname = 'public'
         AND tablename = 'balance_adjustments'
     ) THEN
    EXECUTE 'alter publication supabase_realtime add table public.balance_adjustments';
  END IF;
END $$;

drop trigger if exists balance_adjustments_updated_at on public.balance_adjustments;
create trigger balance_adjustments_updated_at
before update on public.balance_adjustments
for each row execute function public.set_updated_at();
drop trigger if exists balance_adjustments_audit on public.balance_adjustments;
create trigger balance_adjustments_audit
after insert or update or delete on public.balance_adjustments
for each row execute function public.audit_row_change();

create or replace function public.post_manual_balance_adjustment(
  p_party_type text,
  p_party_id uuid,
  p_amount_minor bigint,
  p_direction text,
  p_currency_code text,
  p_reason text,
  p_reference text default null,
  p_effective_date date default current_date,
  p_debit_account_id uuid default null,
  p_credit_account_id uuid default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_base_currency text;
  v_period_status text;
  v_party_balance bigint;
  v_new_balance bigint;
  v_delta bigint;
  v_debit_account uuid;
  v_credit_account uuid;
  v_journal_id uuid;
  v_adjustment_id uuid;
  v_entry_number text;
  v_existing jsonb;
begin
  if v_user_id is null or v_tenant_id is null then
    raise exception 'Authenticated tenant membership required';
  end if;
  if p_party_type not in ('customer', 'vendor') then
    raise exception 'Adjustment party type is invalid';
  end if;
  if p_party_type = 'customer'
     and not public.has_tenant_permission(v_tenant_id, array['manageCustomers','manageAccounting']) then
    raise exception 'Customer balance adjustment permission required';
  end if;
  if p_party_type = 'vendor'
     and not public.has_tenant_permission(v_tenant_id, array['manageVendors','manageAccounting']) then
    raise exception 'Supplier balance adjustment permission required';
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 then
    raise exception 'Adjustment amount must be greater than zero';
  end if;
  if p_direction not in ('increase', 'decrease') then
    raise exception 'Adjustment direction is invalid';
  end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code)
     or p_currency_code !~ '^[A-Z]{3,5}$' then
    raise exception 'Adjustment currency is invalid';
  end if;
  select currency_code into v_base_currency from public.tenants where id = v_tenant_id;
  if p_currency_code <> v_base_currency then
    raise exception 'Manual balance adjustments must use the tenant base currency';
  end if;
  if p_reason is null or length(btrim(p_reason)) not between 3 and 500 then
    raise exception 'A reason between 3 and 500 characters is required';
  end if;
  if p_reference is not null and length(btrim(p_reference)) not between 1 and 120 then
    raise exception 'Adjustment reference is invalid';
  end if;
  if p_effective_date is null then
    raise exception 'Adjustment date is required';
  end if;
  select status into v_period_status
  from public.accounting_periods
  where tenant_id = v_tenant_id
    and p_effective_date between starts_on and ends_on
  order by starts_on desc limit 1;
  if v_period_status in ('locked', 'closed') then
    raise exception 'The accounting period is locked';
  end if;

  if p_idempotency_key is not null then
    select jsonb_build_object(
      'adjustment_id', ba.id,
      'party_type', ba.party_type,
      'party_id', ba.party_id,
      'amount_minor', ba.amount_minor,
      'direction', ba.direction,
      'currency_code', ba.currency_code,
      'reason', ba.reason,
      'reference', ba.reference,
      'effective_date', ba.effective_date,
      'status', ba.status,
      'journal_entry_id', ba.journal_entry_id,
      'new_balance', case when ba.party_type = 'customer' then c.balance else v.balance end,
      'debit_account_id', ba.debit_account_id,
      'credit_account_id', ba.credit_account_id
    ) into v_existing
    from public.balance_adjustments ba
    left join public.customers c on ba.party_type = 'customer' and c.id = ba.party_id and c.tenant_id = ba.tenant_id
    left join public.vendors v on ba.party_type = 'vendor' and v.id = ba.party_id and v.tenant_id = ba.tenant_id
    where ba.tenant_id = v_tenant_id and ba.idempotency_key = btrim(p_idempotency_key);
    if v_existing is not null then return v_existing; end if;
  end if;

  if p_party_type = 'customer' then
    select balance into v_party_balance
    from public.customers
    where id = p_party_id and tenant_id = v_tenant_id and not is_deleted
    for update;
  else
    select balance into v_party_balance
    from public.vendors
    where id = p_party_id and tenant_id = v_tenant_id and not is_deleted
    for update;
  end if;
  if v_party_balance is null then raise exception 'Contact does not belong to the active tenant'; end if;
  v_delta := case when p_direction = 'increase' then p_amount_minor else -p_amount_minor end;
  v_new_balance := v_party_balance + v_delta;
  if v_new_balance < 0 then raise exception 'A contact balance cannot become negative'; end if;

  if p_party_type = 'customer' then
    if p_direction = 'increase' then
      select id into v_debit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_debit_account_id or (p_debit_account_id is null and lower(name) like '%receivable%'))
      order by (id = p_debit_account_id) desc, code limit 1;
      select id into v_credit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_credit_account_id or (p_credit_account_id is null and account_type = 'revenue'))
      order by (id = p_credit_account_id) desc, code limit 1;
    else
      select id into v_debit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_debit_account_id or (p_debit_account_id is null and lower(name) like '%cash%'))
      order by (id = p_debit_account_id) desc, code limit 1;
      select id into v_credit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_credit_account_id or (p_credit_account_id is null and lower(name) like '%receivable%'))
      order by (id = p_credit_account_id) desc, code limit 1;
    end if;
  else
    if p_direction = 'increase' then
      select id into v_debit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_debit_account_id or (p_debit_account_id is null and account_type in ('expense','cost_of_sales')))
      order by (id = p_debit_account_id) desc, code limit 1;
      select id into v_credit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_credit_account_id or (p_credit_account_id is null and lower(name) like '%payable%'))
      order by (id = p_credit_account_id) desc, code limit 1;
    else
      select id into v_debit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_debit_account_id or (p_debit_account_id is null and lower(name) like '%payable%'))
      order by (id = p_debit_account_id) desc, code limit 1;
      select id into v_credit_account from public.chart_of_accounts
      where tenant_id = v_tenant_id and is_active and (id = p_credit_account_id or (p_credit_account_id is null and lower(name) like '%cash%'))
      order by (id = p_credit_account_id) desc, code limit 1;
    end if;
  end if;
  if v_debit_account is null or v_credit_account is null or v_debit_account = v_credit_account then
    raise exception 'Valid debit and credit accounts are required for this adjustment';
  end if;
  if exists (select 1 from public.chart_of_accounts where id = v_debit_account and (tenant_id <> v_tenant_id or not is_active or currency_code <> v_base_currency))
     or exists (select 1 from public.chart_of_accounts where id = v_credit_account and (tenant_id <> v_tenant_id or not is_active or currency_code <> v_base_currency)) then
    raise exception 'Adjustment accounts must be active, tenant-owned, and use the base currency';
  end if;

  v_adjustment_id := gen_random_uuid();
  v_entry_number := 'ADJ-' || to_char(p_effective_date, 'YYYYMMDD') || '-' || replace(left(v_adjustment_id::text, 12), '-', '');
  insert into public.journal_entries (
    id, tenant_id, entry_number, entry_date, description, currency_code,
    exchange_rate, status, source_type, source_id, book_id, base_currency_code,
    created_by, posted_by, posted_at
  )
  select gen_random_uuid(), v_tenant_id, v_entry_number, p_effective_date,
    btrim(p_reason), v_base_currency, 1, 'posted', 'manual_balance_adjustment',
    v_adjustment_id, b.id, v_base_currency, v_user_id, v_user_id, timezone('utc', now())
  from public.accounting_books b
  where b.tenant_id = v_tenant_id and b.book_type = 'leading' and b.status = 'active'
  order by b.code limit 1
  returning id into v_journal_id;
  if v_journal_id is null then raise exception 'An active leading accounting book is required'; end if;

  insert into public.journal_lines (
    tenant_id, journal_entry_id, account_id, line_number, description,
    debit_minor, credit_minor, currency_code, foreign_debit_minor, foreign_credit_minor
  ) values
    (v_tenant_id, v_journal_id, v_debit_account, 1, btrim(p_reason), p_amount_minor, 0, v_base_currency, p_amount_minor, 0),
    (v_tenant_id, v_journal_id, v_credit_account, 2, btrim(p_reason), 0, p_amount_minor, v_base_currency, 0, p_amount_minor);

  insert into public.balance_adjustments (
    id, tenant_id, party_type, party_id, amount_minor, direction, currency_code,
    reason, reference, effective_date, debit_account_id, credit_account_id,
    journal_entry_id, status, idempotency_key, created_by
  ) values (
    v_adjustment_id, v_tenant_id, p_party_type, p_party_id, p_amount_minor,
    p_direction, v_base_currency, btrim(p_reason), nullif(btrim(p_reference), ''),
    p_effective_date, v_debit_account, v_credit_account, v_journal_id, 'posted',
    nullif(btrim(p_idempotency_key), ''), v_user_id
  );

  if p_party_type = 'customer' then
    update public.customers set balance = v_new_balance, updated_at = timezone('utc', now())
    where id = p_party_id and tenant_id = v_tenant_id;
  else
    update public.vendors set balance = v_new_balance, updated_at = timezone('utc', now())
    where id = p_party_id and tenant_id = v_tenant_id;
  end if;

  return jsonb_build_object(
    'adjustment_id', v_adjustment_id,
    'party_type', p_party_type,
    'party_id', p_party_id,
    'amount_minor', p_amount_minor,
    'direction', p_direction,
    'currency_code', v_base_currency,
    'reason', btrim(p_reason),
    'reference', nullif(btrim(p_reference), ''),
    'effective_date', p_effective_date,
    'status', 'posted',
    'journal_entry_id', v_journal_id,
    'new_balance', v_new_balance,
    'debit_account_id', v_debit_account,
    'credit_account_id', v_credit_account
  );
end;
$$;

revoke all on function public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text) from public, anon;
grant execute on function public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text) to authenticated;
