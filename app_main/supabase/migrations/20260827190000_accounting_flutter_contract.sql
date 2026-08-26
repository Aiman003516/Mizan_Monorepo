-- Mizan Flutter accounting contract.
-- Additive RPCs for draft creation and period closing. Final posting remains
-- behind post_journal_entry and direct journal table writes stay restricted.

create or replace function public.create_journal_draft(
  p_entry_number text,
  p_entry_date date,
  p_description text,
  p_currency_code text,
  p_exchange_rate numeric,
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
  v_entry_id uuid;
  v_period_status text;
  v_line jsonb;
  v_count integer := 0;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageAccounting','manageSettings']) then raise exception 'Accounting permission required'; end if;
  if p_entry_number is null or length(btrim(p_entry_number)) not between 1 and 80 then raise exception 'Journal entry number is invalid'; end if;
  if p_description is null or length(btrim(p_description)) not between 1 and 500 then raise exception 'Journal description is invalid'; end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or length(p_currency_code) not between 3 and 5 then raise exception 'Journal currency is invalid'; end if;
  if p_exchange_rate is null or p_exchange_rate <= 0 then raise exception 'Exchange rate is invalid'; end if;
  if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) < 2 then raise exception 'Journal entry must contain at least two lines'; end if;
  select status into v_period_status from public.accounting_periods
  where tenant_id = v_tenant_id and p_entry_date between starts_on and ends_on
  order by starts_on desc limit 1;
  if v_period_status in ('locked', 'closed') then raise exception 'The accounting period is locked'; end if;
  insert into public.journal_entries (tenant_id, entry_number, entry_date, description, currency_code, exchange_rate, status, created_by)
  values (v_tenant_id, btrim(p_entry_number), p_entry_date, btrim(p_description), p_currency_code, p_exchange_rate, 'draft', v_user_id)
  returning id into v_entry_id;
  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_count := v_count + 1;
    insert into public.journal_lines (
      tenant_id, journal_entry_id, account_id, line_number, description,
      debit_minor, credit_minor, currency_code, foreign_debit_minor,
      foreign_credit_minor, tax_code_id
    ) values (
      v_tenant_id,
      v_entry_id,
      (v_line->>'account_id')::uuid,
      coalesce(nullif(v_line->>'line_number', '')::integer, v_count),
      nullif(btrim(v_line->>'description'), ''),
      coalesce(nullif(v_line->>'debit_minor', '')::bigint, 0),
      coalesce(nullif(v_line->>'credit_minor', '')::bigint, 0),
      coalesce(nullif(v_line->>'currency_code', ''), p_currency_code),
      coalesce(nullif(v_line->>'foreign_debit_minor', '')::bigint, 0),
      coalesce(nullif(v_line->>'foreign_credit_minor', '')::bigint, 0),
      nullif(v_line->>'tax_code_id', '')::uuid
    );
  end loop;
  return jsonb_build_object('id', v_entry_id, 'status', 'draft', 'entry_number', p_entry_number, 'line_count', v_count);
exception when others then
  if v_entry_id is not null then delete from public.journal_entries where id = v_entry_id; end if;
  raise;
end;
$$;

create or replace function public.profit_and_loss(p_starts_on date, p_ends_on date)
returns table(account_id uuid, account_code text, account_name text, account_type text, balance_minor bigint)
language sql
stable
security definer
set search_path = public
as $$
  select coa.id, coa.code, coa.name, coa.account_type,
         case when coa.account_type = 'revenue'
              then (coalesce(sum(jl.credit_minor), 0) - coalesce(sum(jl.debit_minor), 0))::bigint
              else (coalesce(sum(jl.debit_minor), 0) - coalesce(sum(jl.credit_minor), 0))::bigint
         end
  from public.chart_of_accounts coa
  left join public.journal_entries je on je.tenant_id = coa.tenant_id and je.status = 'posted' and je.entry_date between p_starts_on and p_ends_on
  left join public.journal_lines jl on jl.journal_entry_id = je.id and jl.account_id = coa.id and jl.tenant_id = coa.tenant_id
  where coa.tenant_id = public.current_tenant_id() and coa.account_type in ('revenue', 'expense') and coa.is_active
  group by coa.id, coa.code, coa.name, coa.account_type
  order by coa.code;
$$;

create or replace function public.balance_sheet(p_as_of date)
returns table(account_id uuid, account_code text, account_name text, account_type text, balance_minor bigint)
language sql
stable
security definer
set search_path = public
as $$
  select coa.id, coa.code, coa.name, coa.account_type,
         case when coa.account_type = 'asset'
              then (coalesce(sum(jl.debit_minor), 0) - coalesce(sum(jl.credit_minor), 0))::bigint
              else (coalesce(sum(jl.credit_minor), 0) - coalesce(sum(jl.debit_minor), 0))::bigint
         end
  from public.chart_of_accounts coa
  left join public.journal_entries je on je.tenant_id = coa.tenant_id and je.status = 'posted' and je.entry_date <= p_as_of
  left join public.journal_lines jl on jl.journal_entry_id = je.id and jl.account_id = coa.id and jl.tenant_id = coa.tenant_id
  where coa.tenant_id = public.current_tenant_id() and coa.account_type in ('asset', 'liability', 'equity') and coa.is_active
  group by coa.id, coa.code, coa.name, coa.account_type
  order by coa.code;
$$;

create or replace function public.close_accounting_period(p_period_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := (select auth.uid());
  v_period public.accounting_periods;
  v_unbalanced integer;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageAccounting','manageSettings']) then raise exception 'Accounting permission required'; end if;
  select * into v_period from public.accounting_periods where id = p_period_id and tenant_id = v_tenant_id for update;
  if not found then raise exception 'Accounting period was not found'; end if;
  if v_period.status = 'closed' then return jsonb_build_object('id', v_period.id, 'status', 'closed'); end if;
  select count(*) into v_unbalanced
  from (
    select je.id from public.journal_entries je
    left join public.journal_lines jl on jl.journal_entry_id = je.id and jl.tenant_id = je.tenant_id
    where je.tenant_id = v_tenant_id and je.status = 'posted' and je.entry_date between v_period.starts_on and v_period.ends_on
    group by je.id
    having coalesce(sum(jl.debit_minor), 0) <> coalesce(sum(jl.credit_minor), 0)
  ) invalid_entries;
  if v_unbalanced > 0 then raise exception 'The period contains unbalanced posted journal entries'; end if;
  update public.accounting_periods set status = 'closed', closed_by = v_user_id, closed_at = timezone('utc', now()) where id = v_period.id;
  return jsonb_build_object('id', v_period.id, 'status', 'closed', 'closed_at', timezone('utc', now()));
end;
$$;

revoke all on function public.create_journal_draft(text,date,text,text,numeric,jsonb) from public, anon, authenticated;
revoke all on function public.profit_and_loss(date,date) from public, anon, authenticated;
revoke all on function public.balance_sheet(date) from public, anon, authenticated;
revoke all on function public.close_accounting_period(uuid) from public, anon, authenticated;
grant execute on function public.create_journal_draft(text,date,text,text,numeric,jsonb) to authenticated;
grant execute on function public.profit_and_loss(date,date) to authenticated;
grant execute on function public.balance_sheet(date) to authenticated;
grant execute on function public.close_accounting_period(uuid) to authenticated;
