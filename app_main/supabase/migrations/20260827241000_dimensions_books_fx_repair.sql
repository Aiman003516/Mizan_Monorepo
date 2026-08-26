-- Additive repair for the dimensional accounting foundation.
-- This does not rewrite 20260827210000; it replaces its generic trigger with
-- table-aware validation and adds a backward-compatible extended draft RPC.

create or replace function public.prevent_cross_tenant_accounting_book()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_worktag_key text;
  v_dimension_type text;
  v_dimension_code text;
begin
  if tg_table_name = 'journal_entries' then
    if new.book_id is not null and not exists (
      select 1 from public.accounting_books b
      where b.id = new.book_id and b.tenant_id = new.tenant_id and b.status = 'active'
    ) then
      raise exception 'Accounting book does not belong to the active tenant';
    end if;
    if new.base_currency_code is not null
       and (new.base_currency_code <> upper(new.base_currency_code)
         or new.base_currency_code !~ '^[A-Z]{3,5}$') then
      raise exception 'Base currency code is invalid';
    end if;
    if new.exchange_rate_source is not null
       and length(btrim(new.exchange_rate_source)) not between 1 and 120 then
      raise exception 'Exchange-rate source is invalid';
    end if;
    if new.exchange_rate_source is not null and new.exchange_rate_effective_on is null then
      raise exception 'Exchange-rate effective date is required when a source is supplied';
    end if;
  elsif tg_table_name = 'journal_lines' then
    if new.worktags is not null and jsonb_typeof(new.worktags) <> 'object' then
      raise exception 'Worktags must be a JSON object';
    end if;
    if new.worktags is not null then
      for v_worktag_key in select jsonb_object_keys(new.worktags) loop
        if v_worktag_key not in ('branch', 'cost_center', 'project', 'campaign', 'region', 'fund') then
          raise exception 'Unsupported worktag key: %', v_worktag_key;
        end if;
        v_dimension_type := v_worktag_key;
        v_dimension_code := nullif(btrim(new.worktags->>v_worktag_key), '');
        if v_dimension_code is null or not exists (
          select 1 from public.accounting_dimensions d
          where d.tenant_id = new.tenant_id
            and d.dimension_type = v_dimension_type
            and d.code = upper(v_dimension_code)
            and d.is_active
        ) then
          raise exception 'Worktag does not belong to the active tenant dimension: %', v_worktag_key;
        end if;
      end loop;
    end if;
  end if;
  return new;
end;
$$;

-- Repair the historical generic function’s invalid field references by keeping
-- separate table-specific trigger attachment while retaining its public name.
drop trigger if exists journal_entry_book_dimensions_guard on public.journal_entries;
create trigger journal_entry_book_dimensions_guard
before insert or update on public.journal_entries
for each row execute function public.prevent_cross_tenant_accounting_book();

drop trigger if exists journal_line_worktags_guard on public.journal_lines;
create trigger journal_line_worktags_guard
before insert or update on public.journal_lines
for each row execute function public.prevent_cross_tenant_accounting_book();

-- Every tenant receives one stable leading book. Legacy journal rows are
-- backfilled only when an unambiguous active leading book exists.
insert into public.accounting_books (tenant_id, code, name, book_type, status)
select t.id, 'MAIN', 'Main book', 'leading', 'active'
from public.tenants t
where not exists (
  select 1 from public.accounting_books b
  where b.tenant_id = t.id and b.book_type = 'leading' and b.status = 'active'
);

update public.journal_entries je
set book_id = b.id
from public.accounting_books b
where je.book_id is null
  and b.tenant_id = je.tenant_id
  and b.book_type = 'leading'
  and b.status = 'active';

create or replace function public.create_journal_draft(
  p_entry_number text,
  p_entry_date date,
  p_description text,
  p_currency_code text,
  p_exchange_rate numeric,
  p_lines jsonb,
  p_book_id uuid,
  p_base_currency_code text,
  p_exchange_rate_source text,
  p_exchange_rate_effective_on date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_entry_id uuid;
  v_period_status text;
  v_line jsonb;
  v_worktags jsonb;
  v_worktag_key text;
  v_count integer := 0;
  v_book_id uuid := p_book_id;
  v_base_currency text := nullif(upper(btrim(p_base_currency_code)), '');
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageAccounting','manageSettings']) then raise exception 'Accounting permission required'; end if;
  if p_entry_number is null or length(btrim(p_entry_number)) not between 1 and 80 then raise exception 'Journal entry number is invalid'; end if;
  if p_description is null or length(btrim(p_description)) not between 1 and 500 then raise exception 'Journal description is invalid'; end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or p_currency_code !~ '^[A-Z]{3,5}$' then raise exception 'Journal currency is invalid'; end if;
  if p_exchange_rate is null or p_exchange_rate <= 0 then raise exception 'Exchange rate is invalid'; end if;
  if v_base_currency is not null and v_base_currency !~ '^[A-Z]{3,5}$' then raise exception 'Base currency code is invalid'; end if;
  if p_exchange_rate_source is not null and length(btrim(p_exchange_rate_source)) not between 1 and 120 then raise exception 'Exchange-rate source is invalid'; end if;
  if p_exchange_rate_source is not null and p_exchange_rate_effective_on is null then raise exception 'Exchange-rate effective date is required when a source is supplied'; end if;
  if v_book_id is null then
    select b.id into v_book_id
    from public.accounting_books b
    where b.tenant_id = v_tenant_id and b.book_type = 'leading' and b.status = 'active'
    order by b.code
    limit 1;
  end if;
  if v_book_id is null or not exists (
    select 1 from public.accounting_books b where b.id = v_book_id and b.tenant_id = v_tenant_id and b.status = 'active'
  ) then raise exception 'Accounting book does not belong to the active tenant'; end if;
  if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) < 2 then raise exception 'Journal entry must contain at least two lines'; end if;
  select status into v_period_status from public.accounting_periods
  where tenant_id = v_tenant_id and p_entry_date between starts_on and ends_on
  order by starts_on desc limit 1;
  if v_period_status in ('locked', 'closed') then raise exception 'The accounting period is locked'; end if;

  insert into public.journal_entries (
    tenant_id, entry_number, entry_date, description, currency_code, exchange_rate,
    book_id, base_currency_code, exchange_rate_source, exchange_rate_effective_on,
    status, created_by
  ) values (
    v_tenant_id, btrim(p_entry_number), p_entry_date, btrim(p_description), p_currency_code, p_exchange_rate,
    v_book_id, v_base_currency, nullif(btrim(p_exchange_rate_source), ''), p_exchange_rate_effective_on,
    'draft', v_user_id
  ) returning id into v_entry_id;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_count := v_count + 1;
    v_worktags := coalesce(v_line->'worktags', '{}'::jsonb);
    if jsonb_typeof(v_worktags) <> 'object' then raise exception 'Worktags must be a JSON object'; end if;
    for v_worktag_key in select jsonb_object_keys(v_worktags) loop
      if v_worktag_key not in ('branch', 'cost_center', 'project', 'campaign', 'region', 'fund') then
        raise exception 'Unsupported worktag key: %', v_worktag_key;
      end if;
      if not exists (
        select 1 from public.accounting_dimensions d
        where d.tenant_id = v_tenant_id
          and d.dimension_type = v_worktag_key
          and d.code = upper(nullif(btrim(v_worktags->>v_worktag_key), ''))
          and d.is_active
      ) then raise exception 'Worktag does not belong to the active tenant dimension: %', v_worktag_key; end if;
    end loop;
    insert into public.journal_lines (
      tenant_id, journal_entry_id, account_id, line_number, description,
      debit_minor, credit_minor, currency_code, foreign_debit_minor,
      foreign_credit_minor, tax_code_id, worktags
    ) values (
      v_tenant_id, v_entry_id, (v_line->>'account_id')::uuid,
      coalesce(nullif(v_line->>'line_number', '')::integer, v_count),
      nullif(btrim(v_line->>'description'), ''),
      coalesce(nullif(v_line->>'debit_minor', '')::bigint, 0),
      coalesce(nullif(v_line->>'credit_minor', '')::bigint, 0),
      coalesce(nullif(v_line->>'currency_code', ''), p_currency_code),
      coalesce(nullif(v_line->>'foreign_debit_minor', '')::bigint, 0),
      coalesce(nullif(v_line->>'foreign_credit_minor', '')::bigint, 0),
      nullif(v_line->>'tax_code_id', '')::uuid, v_worktags
    );
  end loop;
  return jsonb_build_object('id', v_entry_id, 'status', 'draft', 'entry_number', p_entry_number, 'line_count', v_count, 'book_id', v_book_id);
exception when others then
  if v_entry_id is not null then delete from public.journal_entries where id = v_entry_id; end if;
  raise;
end;
$$;

revoke all on function public.create_journal_draft(text, date, text, text, numeric, jsonb, uuid, text, text, date) from public, anon, authenticated;
grant execute on function public.create_journal_draft(text, date, text, text, numeric, jsonb, uuid, text, text, date) to authenticated;
revoke all on function public.prevent_cross_tenant_accounting_book() from public, anon, authenticated;
