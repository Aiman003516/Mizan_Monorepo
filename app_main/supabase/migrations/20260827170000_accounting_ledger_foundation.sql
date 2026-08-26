-- Mizan accounting ledger foundation.
-- Additive only: periods, tax codes, chart of accounts, journal entries/lines,
-- balanced posting, tenant RLS, and audit hooks. Do not apply without review.

create table if not exists public.accounting_periods (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 120),
  starts_on date not null,
  ends_on date not null,
  status text not null default 'open' check (status in ('open', 'locked', 'closed')),
  closed_by uuid references auth.users(id) on delete set null,
  closed_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, name),
  check (ends_on >= starts_on),
  check ((status = 'closed' and closed_at is not null) or status <> 'closed')
);

create index if not exists accounting_periods_lookup_idx
  on public.accounting_periods (tenant_id, starts_on, ends_on, status);

create table if not exists public.tax_codes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  code text not null check (code = upper(btrim(code)) and length(btrim(code)) between 1 and 40),
  name text not null check (length(btrim(name)) between 1 and 160),
  rate_percent numeric(7,4) not null check (rate_percent >= 0 and rate_percent <= 100),
  is_inclusive boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, code)
);

create index if not exists tax_codes_active_idx
  on public.tax_codes (tenant_id, is_active, lower(name), id);

create table if not exists public.chart_of_accounts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  code text not null check (code = upper(btrim(code)) and length(btrim(code)) between 1 and 40),
  name text not null check (length(btrim(name)) between 1 and 160),
  account_type text not null check (account_type in ('asset', 'liability', 'equity', 'revenue', 'expense', 'cost_of_sales')),
  parent_id uuid references public.chart_of_accounts(id) on delete restrict,
  normal_balance text not null check (normal_balance in ('debit', 'credit')),
  currency_code text not null default 'USD' check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  is_control_account boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, code),
  unique (tenant_id, id)
);

create index if not exists chart_of_accounts_tree_idx
  on public.chart_of_accounts (tenant_id, parent_id, is_active, code);

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  entry_number text not null check (length(btrim(entry_number)) between 1 and 80),
  entry_date date not null,
  description text not null check (length(btrim(description)) between 1 and 500),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  exchange_rate numeric(24,12) not null default 1 check (exchange_rate > 0),
  status text not null default 'draft' check (status in ('draft', 'posted', 'reversed')),
  source_type text,
  source_id uuid,
  reversal_of_id uuid references public.journal_entries(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  posted_by uuid references auth.users(id) on delete set null,
  posted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, entry_number),
  check ((status = 'posted' and posted_at is not null and posted_by is not null) or status <> 'posted')
);

create index if not exists journal_entries_period_idx
  on public.journal_entries (tenant_id, entry_date, status, id);
create index if not exists journal_entries_source_idx
  on public.journal_entries (tenant_id, source_type, source_id);

create table if not exists public.journal_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  journal_entry_id uuid not null references public.journal_entries(id) on delete cascade,
  account_id uuid not null references public.chart_of_accounts(id) on delete restrict,
  line_number integer not null check (line_number > 0),
  description text,
  debit_minor bigint not null default 0 check (debit_minor >= 0),
  credit_minor bigint not null default 0 check (credit_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  foreign_debit_minor bigint not null default 0 check (foreign_debit_minor >= 0),
  foreign_credit_minor bigint not null default 0 check (foreign_credit_minor >= 0),
  tax_code_id uuid references public.tax_codes(id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (journal_entry_id, line_number),
  check ((debit_minor > 0 and credit_minor = 0) or (credit_minor > 0 and debit_minor = 0)),
  check ((foreign_debit_minor > 0 and foreign_credit_minor = 0) or (foreign_debit_minor = 0 and foreign_credit_minor >= 0))
);

create index if not exists journal_lines_entry_idx
  on public.journal_lines (tenant_id, journal_entry_id, line_number);
create index if not exists journal_lines_account_idx
  on public.journal_lines (tenant_id, account_id, journal_entry_id);

create or replace function public.prevent_posted_journal_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = 'posted' then
    raise exception 'Posted journal entries are immutable; create a reversal instead';
  end if;
  return new;
end;
$$;

create or replace function public.prevent_non_draft_journal_line_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entry public.journal_entries;
  v_account_tenant uuid;
  v_account_currency text;
begin
  select * into v_entry from public.journal_entries where id = coalesce(new.journal_entry_id, old.journal_entry_id);
  if not found or v_entry.tenant_id <> coalesce(new.tenant_id, old.tenant_id) then raise exception 'Journal entry tenant is invalid'; end if;
  if v_entry.status <> 'draft' then raise exception 'Journal lines are immutable after posting'; end if;
  select tenant_id into v_account_tenant from public.chart_of_accounts where id = coalesce(new.account_id, old.account_id);
  if v_account_tenant is null or v_account_tenant <> v_entry.tenant_id then raise exception 'Journal line account tenant is invalid'; end if;
  if tg_op <> 'DELETE' and new.currency_code <> v_entry.currency_code then raise exception 'Journal line currency must match the journal entry'; end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists journal_entries_immutable on public.journal_entries;
create trigger journal_entries_immutable before update or delete on public.journal_entries
for each row execute function public.prevent_posted_journal_mutation();
drop trigger if exists journal_lines_draft_only on public.journal_lines;
create trigger journal_lines_draft_only before insert or update or delete on public.journal_lines
for each row execute function public.prevent_non_draft_journal_line_mutation();

create or replace function public.post_journal_entry(p_journal_entry_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := (select auth.uid());
  v_entry public.journal_entries;
  v_debits bigint;
  v_credits bigint;
  v_line_count integer;
  v_period_status text;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageAccounting','postJournals','manageSettings']) then raise exception 'Accounting posting permission required'; end if;
  select * into v_entry from public.journal_entries where id = p_journal_entry_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Journal entry was not found'; end if;
  if v_entry.status <> 'draft' then raise exception 'Only draft journal entries can be posted'; end if;
  select status into v_period_status from public.accounting_periods
  where tenant_id = v_tenant_id and v_entry.entry_date between starts_on and ends_on
  order by starts_on desc limit 1;
  if v_period_status = 'locked' or v_period_status = 'closed' then raise exception 'The accounting period is locked'; end if;
  select coalesce(sum(debit_minor), 0), coalesce(sum(credit_minor), 0), count(*) into v_debits, v_credits, v_line_count
  from public.journal_lines where journal_entry_id = v_entry.id and tenant_id = v_tenant_id;
  if v_line_count < 2 or v_debits <= 0 or v_debits <> v_credits then raise exception 'Journal entry must contain at least two balanced lines'; end if;
  if exists (select 1 from public.journal_lines jl where jl.journal_entry_id = v_entry.id and (jl.tenant_id <> v_tenant_id or not exists (select 1 from public.chart_of_accounts coa where coa.id = jl.account_id and coa.tenant_id = v_tenant_id and coa.is_active))) then raise exception 'Journal line account is invalid'; end if;
  update public.journal_entries set status = 'posted', posted_by = v_user_id, posted_at = timezone('utc', now()) where id = v_entry.id;
  return jsonb_build_object('id', v_entry.id, 'status', 'posted', 'debit_minor', v_debits, 'credit_minor', v_credits);
end;
$$;

create or replace function public.trial_balance(p_starts_on date, p_ends_on date)
returns table(account_id uuid, account_code text, account_name text, account_type text, debit_minor bigint, credit_minor bigint, balance_minor bigint)
language sql
stable
security definer
set search_path = public
as $$
  select coa.id, coa.code, coa.name, coa.account_type,
         coalesce(sum(jl.debit_minor), 0)::bigint,
         coalesce(sum(jl.credit_minor), 0)::bigint,
         (coalesce(sum(jl.debit_minor), 0) - coalesce(sum(jl.credit_minor), 0))::bigint
  from public.chart_of_accounts coa
  left join public.journal_entries je on je.tenant_id = coa.tenant_id and je.status = 'posted' and je.entry_date between p_starts_on and p_ends_on
  left join public.journal_lines jl on jl.account_id = coa.id and jl.journal_entry_id = je.id and jl.tenant_id = coa.tenant_id
  where coa.tenant_id = public.current_tenant_id() and coa.is_active
  group by coa.id, coa.code, coa.name, coa.account_type
  order by coa.code;
$$;

-- Timestamp and audit hooks for accounting tables.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['accounting_periods','tax_codes','chart_of_accounts','journal_entries','journal_lines'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
  END LOOP;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['accounting_periods','tax_codes','chart_of_accounts','journal_entries','journal_lines'] LOOP
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy accounting_periods_select on public.accounting_periods for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy accounting_periods_write on public.accounting_periods for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']));
create policy tax_codes_select on public.tax_codes for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy tax_codes_write on public.tax_codes for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']));
create policy chart_of_accounts_select on public.chart_of_accounts for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy chart_of_accounts_write on public.chart_of_accounts for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']));
create policy journal_entries_select on public.journal_entries for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy journal_entries_write on public.journal_entries for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']));
create policy journal_lines_select on public.journal_lines for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy journal_lines_write on public.journal_lines for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']) and exists (select 1 from public.journal_entries je where je.id = journal_entry_id and je.tenant_id = tenant_id));

grant select, insert, update, delete on public.accounting_periods, public.tax_codes, public.chart_of_accounts to authenticated;
grant select on public.journal_entries, public.journal_lines to authenticated;
revoke insert, update, delete on public.journal_entries, public.journal_lines from authenticated;
revoke all on function public.prevent_posted_journal_mutation() from public, anon, authenticated;
revoke all on function public.prevent_non_draft_journal_line_mutation() from public, anon, authenticated;
revoke all on function public.post_journal_entry(uuid) from public, anon, authenticated;
revoke all on function public.trial_balance(date,date) from public, anon, authenticated;
grant execute on function public.post_journal_entry(uuid) to authenticated;
grant execute on function public.trial_balance(date,date) to authenticated;
