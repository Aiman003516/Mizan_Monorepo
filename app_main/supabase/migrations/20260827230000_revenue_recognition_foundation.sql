-- Mizan controlled revenue-recognition foundation.
-- Schedule generation is deterministic and creates drafts only; posting remains
-- behind the existing accounting permission and journal-posting RPC.

create table if not exists public.revenue_contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete restrict,
  contract_number text not null check (length(btrim(contract_number)) between 1 and 80),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  total_minor bigint not null check (total_minor >= 0),
  starts_on date not null,
  ends_on date not null,
  deferred_revenue_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  revenue_account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  status text not null default 'draft' check (status in ('draft', 'active', 'completed', 'cancelled')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, contract_number),
  check (ends_on >= starts_on),
  unique (tenant_id, id)
);

create table if not exists public.revenue_schedule_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  contract_id uuid not null references public.revenue_contracts(id) on delete cascade,
  line_number integer not null check (line_number > 0),
  recognition_on date not null,
  amount_minor bigint not null check (amount_minor >= 0),
  status text not null default 'planned'
    check (status in ('planned', 'draft_created', 'recognized', 'cancelled')),
  journal_entry_id uuid references public.journal_entries(id) on delete restrict,
  recognized_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (contract_id, line_number),
  unique (tenant_id, id),
  check ((status = 'recognized' and journal_entry_id is not null and recognized_at is not null) or status <> 'recognized')
);

create index if not exists revenue_contracts_tenant_status_idx
  on public.revenue_contracts (tenant_id, status, starts_on, ends_on, id);
create index if not exists revenue_schedule_due_idx
  on public.revenue_schedule_lines (tenant_id, status, recognition_on, id);
create index if not exists revenue_schedule_contract_idx
  on public.revenue_schedule_lines (tenant_id, contract_id, line_number);

create or replace function public.create_revenue_contract(
  p_contract_number text,
  p_customer_id uuid,
  p_currency_code text,
  p_total_minor bigint,
  p_starts_on date,
  p_ends_on date,
  p_deferred_revenue_account_id uuid,
  p_revenue_account_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_contract_id uuid;
  v_period_count integer;
  v_base_amount bigint;
  v_remainder bigint;
  v_index integer := 0;
  v_date date;
  v_amount bigint;
  v_currency text := upper(btrim(p_currency_code));
begin
  if v_user_id is null or v_tenant_id is null then
    raise exception using errcode = '42501', message = 'Authenticated tenant membership required';
  end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageAccounting','manageSales','manageSettings']) then
    raise exception using errcode = '42501', message = 'Revenue contract permission required';
  end if;
  if p_contract_number is null or length(btrim(p_contract_number)) not between 1 and 80 then
    raise exception using errcode = '22023', message = 'Revenue contract number is invalid';
  end if;
  if v_currency !~ '^[A-Z]{3,5}$' or p_total_minor is null or p_total_minor < 0 then
    raise exception using errcode = '22023', message = 'Revenue contract amount or currency is invalid';
  end if;
  if p_ends_on < p_starts_on then
    raise exception using errcode = '22023', message = 'Revenue contract dates are invalid';
  end if;
  if p_deferred_revenue_account_id is null or p_revenue_account_id is null
     or p_deferred_revenue_account_id = p_revenue_account_id
     or (select count(*) from public.chart_of_accounts a
         where a.id in (p_deferred_revenue_account_id, p_revenue_account_id)
           and a.tenant_id = v_tenant_id and a.is_active) <> 2 then
    raise exception using errcode = '42501', message = 'Revenue accounts must be distinct active accounts belonging to the tenant';
  end if;
  if exists (
    select 1 from public.chart_of_accounts a
    where a.id = p_deferred_revenue_account_id and a.account_type <> 'liability'
  ) then
    raise exception using errcode = '22023', message = 'Deferred revenue account must be a liability account';
  end if;
  if exists (
    select 1 from public.chart_of_accounts a
    where a.id = p_revenue_account_id and a.account_type <> 'revenue'
  ) then
    raise exception using errcode = '22023', message = 'Revenue account must be a revenue account';
  end if;
  if p_customer_id is not null and not exists (
    select 1 from public.customers c where c.id = p_customer_id and c.tenant_id = v_tenant_id and not c.is_deleted
  ) then
    raise exception using errcode = '42501', message = 'Customer does not belong to the tenant';
  end if;

  insert into public.revenue_contracts (
    tenant_id, customer_id, contract_number, currency_code, total_minor,
    starts_on, ends_on, deferred_revenue_account_id, revenue_account_id,
    status, created_by
  ) values (
    v_tenant_id, p_customer_id, btrim(p_contract_number), v_currency, p_total_minor,
    p_starts_on, p_ends_on, p_deferred_revenue_account_id, p_revenue_account_id,
    'active', v_user_id
  ) returning id into v_contract_id;

  select count(*)::integer into v_period_count
  from generate_series(
    date_trunc('month', p_starts_on)::date,
    date_trunc('month', p_ends_on)::date,
    interval '1 month'
  );
  v_period_count := greatest(v_period_count, 1);
  v_base_amount := p_total_minor / v_period_count;
  v_remainder := p_total_minor % v_period_count;

  for v_date in
    select generate_series(
      date_trunc('month', p_starts_on)::date,
      date_trunc('month', p_ends_on)::date,
      interval '1 month'
    )::date
  loop
    v_index := v_index + 1;
    v_amount := v_base_amount + case when v_index <= v_remainder then 1 else 0 end;
    insert into public.revenue_schedule_lines (
      tenant_id, contract_id, line_number, recognition_on, amount_minor
    ) values (
      v_tenant_id, v_contract_id, v_index, greatest(v_date, p_starts_on), v_amount
    );
  end loop;

  return jsonb_build_object(
    'id', v_contract_id,
    'contract_number', p_contract_number,
    'status', 'active',
    'schedule_line_count', v_period_count,
    'total_minor', p_total_minor,
    'currency_code', v_currency
  );
end;
$$;

create or replace function public.list_revenue_schedule(
  p_status text default null,
  p_as_of date default null
)
returns table(
  id uuid,
  contract_id uuid,
  contract_number text,
  recognition_on date,
  amount_minor bigint,
  currency_code text,
  status text,
  journal_entry_id uuid
)
language sql
stable
security definer
set search_path = public
as $$
  select s.id, s.contract_id, c.contract_number, s.recognition_on,
         s.amount_minor, c.currency_code, s.status, s.journal_entry_id
  from public.revenue_schedule_lines s
  join public.revenue_contracts c on c.id = s.contract_id and c.tenant_id = s.tenant_id
  where s.tenant_id = public.current_tenant_id()
    and (p_status is null or s.status = p_status)
    and (p_as_of is null or s.recognition_on <= p_as_of)
  order by s.recognition_on, c.contract_number, s.line_number;
$$;

create or replace function public.create_revenue_recognition_draft(
  p_schedule_line_id uuid,
  p_entry_number text,
  p_entry_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_line public.revenue_schedule_lines;
  v_contract public.revenue_contracts;
  v_draft jsonb;
  v_entry_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then
    raise exception using errcode = '42501', message = 'Authenticated tenant membership required';
  end if;
  select * into v_line from public.revenue_schedule_lines
  where id = p_schedule_line_id and tenant_id = v_tenant_id for update;
  if not found then raise exception using errcode = '22023', message = 'Revenue schedule line was not found'; end if;
  if v_line.status <> 'planned' then raise exception using errcode = '22023', message = 'Revenue schedule line is not available'; end if;
  select * into v_contract from public.revenue_contracts where id = v_line.contract_id and tenant_id = v_tenant_id;
  if not found then raise exception using errcode = '22023', message = 'Revenue contract was not found'; end if;

  v_draft := public.create_journal_draft(
    p_entry_number,
    p_entry_date,
    'Revenue recognition ' || v_contract.contract_number || ' #' || v_line.line_number,
    v_contract.currency_code,
    1,
    jsonb_build_array(
      jsonb_build_object(
        'account_id', v_contract.deferred_revenue_account_id,
        'debit_minor', v_line.amount_minor,
        'credit_minor', 0,
        'currency_code', v_contract.currency_code,
        'line_number', 1
      ),
      jsonb_build_object(
        'account_id', v_contract.revenue_account_id,
        'debit_minor', 0,
        'credit_minor', v_line.amount_minor,
        'currency_code', v_contract.currency_code,
        'line_number', 2
      )
    )
  );
  v_entry_id := (v_draft->>'id')::uuid;
  update public.journal_entries
  set source_type = 'revenue_recognition', source_id = v_line.id
  where id = v_entry_id and tenant_id = v_tenant_id;
  update public.revenue_schedule_lines
  set status = 'draft_created', journal_entry_id = v_entry_id
  where id = v_line.id;
  return v_draft || jsonb_build_object('schedule_line_id', v_line.id);
end;
$$;

create or replace function public.sync_revenue_schedule_after_post()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'posted' and new.source_type = 'revenue_recognition' and new.source_id is not null then
    update public.revenue_schedule_lines
    set status = 'recognized', recognized_at = timezone('utc', now())
    where id = new.source_id
      and tenant_id = new.tenant_id
      and journal_entry_id = new.id
      and status = 'draft_created';
  end if;
  return new;
end;
$$;

drop trigger if exists revenue_schedule_posted_sync on public.journal_entries;
create trigger revenue_schedule_posted_sync
after update of status on public.journal_entries
for each row execute function public.sync_revenue_schedule_after_post();

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['revenue_contracts','revenue_schedule_lines'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy revenue_contracts_select on public.revenue_contracts for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy revenue_schedule_select on public.revenue_schedule_lines for select to authenticated
using (public.is_tenant_member(tenant_id));

revoke all on function public.create_revenue_contract(text, uuid, text, bigint, date, date, uuid, uuid) from public, anon;
revoke all on function public.list_revenue_schedule(text, date) from public, anon;
revoke all on function public.create_revenue_recognition_draft(uuid, text, date) from public, anon;
grant execute on function public.create_revenue_contract(text, uuid, text, bigint, date, date, uuid, uuid) to authenticated;
grant execute on function public.list_revenue_schedule(text, date) to authenticated;
grant execute on function public.create_revenue_recognition_draft(uuid, text, date) to authenticated;
