-- Mizan schema health and data-quality preflight.
-- This migration adds only a read-only diagnostic RPC. It does not rewrite
-- business data and must be verified in a staging project before production.

create or replace function public.run_schema_health_check()
returns table(
  check_code text,
  severity text,
  passed boolean,
  observed_count bigint,
  details text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
  v_table text;
  v_count bigint;
  v_required_tables text[] := array[
    'tenants',
    'user_profiles',
    'roles',
    'staff_members',
    'invites',
    'currencies',
    'customers',
    'vendors',
    'invoices',
    'bills',
    'accounting_periods',
    'tax_codes',
    'chart_of_accounts',
    'journal_entries',
    'journal_lines'
  ];
  v_tenant_tables text[] := array[
    'roles',
    'staff_members',
    'invites',
    'currencies',
    'customers',
    'vendors',
    'invoices',
    'bills',
    'accounting_periods',
    'tax_codes',
    'chart_of_accounts',
    'journal_entries',
    'journal_lines'
  ];
begin
  if auth.uid() is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication is required for schema health checks';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception using
      errcode = '42501',
      message = 'An active tenant is required for schema health checks';
  end if;

  check_code := 'tenant_context';
  severity := 'critical';
  passed := true;
  observed_count := 1;
  details := 'Active tenant context is available.';
  return next;

  foreach v_table in array v_required_tables loop
    check_code := 'required_table.' || v_table;
    severity := 'critical';
    passed := to_regclass('public.' || v_table) is not null;
    observed_count := case when passed then 1 else 0 end;
    details := case
      when passed then 'Required table exists.'
      else 'Required table is missing; dependent features cannot be considered live.'
    end;
    return next;
  end loop;

  foreach v_table in array v_tenant_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format(
        'select count(*) from pg_class c
         where c.oid = $1::regclass and c.relrowsecurity',
        v_table
      ) into v_count using 'public.' || v_table;
      check_code := 'rls_enabled.' || v_table;
      severity := 'critical';
      passed := v_count = 1;
      observed_count := v_count;
      details := case
        when passed then 'Row-Level Security is enabled.'
        else 'Tenant-scoped table does not have Row-Level Security enabled.'
      end;
      return next;
    end if;
  end loop;

  foreach v_table in array v_tenant_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format(
        'select count(*) from public.%I x
         where x.tenant_id = $1
           and not exists (select 1 from public.tenants t where t.id = x.tenant_id)',
        v_table
      ) into v_count using v_tenant_id;
      check_code := 'orphan_tenant_reference.' || v_table;
      severity := 'critical';
      passed := v_count = 0;
      observed_count := v_count;
      details := case
        when passed then 'No orphan tenant references were found.'
        else 'Rows reference a tenant that does not exist.'
      end;
      return next;
    end if;
  end loop;

  if to_regclass('public.journal_entries') is not null
     and to_regclass('public.journal_lines') is not null then
    execute $query$
      select count(*) from (
        select je.id
        from public.journal_entries je
        join public.journal_lines jl
          on jl.journal_entry_id = je.id
         and jl.tenant_id = je.tenant_id
        where je.tenant_id = $1
          and je.status = 'posted'
        group by je.id
        having coalesce(sum(jl.debit_minor), 0)
            <> coalesce(sum(jl.credit_minor), 0)
      ) unbalanced
    $query$ into v_count using v_tenant_id;
    check_code := 'posted_journal_balance';
    severity := 'critical';
    passed := v_count = 0;
    observed_count := v_count;
    details := case
      when passed then 'All posted journal entries are balanced.'
      else 'Posted journal entries are not balanced and require reconciliation before migration.'
    end;
    return next;
  end if;

  if to_regclass('public.currencies') is not null then
    execute $query$
      select count(*) from public.currencies
      where tenant_id = $1
        and (code <> upper(code) or length(code) not between 3 and 5)
    $query$ into v_count using v_tenant_id;
    check_code := 'currency_code_format';
    severity := 'high';
    passed := v_count = 0;
    observed_count := v_count;
    details := case
      when passed then 'Tenant currency codes use the canonical uppercase format.'
      else 'Currency rows contain malformed codes.'
    end;
    return next;
  end if;

  foreach v_table in array v_tenant_tables loop
    if to_regclass('public.' || v_table) is not null then
      execute format(
        'select count(*) from pg_indexes
         where schemaname = ''public''
           and tablename = %L
           and indexdef ilike ''%%(tenant_id%%''',
        v_table
      ) into v_count;
      check_code := 'tenant_leading_index.' || v_table;
      severity := 'high';
      passed := v_count > 0;
      observed_count := v_count;
      details := case
        when passed then 'At least one tenant-leading index exists.'
        else 'No tenant-leading index was detected; review query plans before scale-up.'
      end;
      return next;
    end if;
  end loop;

  check_code := 'preflight_complete';
  severity := 'info';
  passed := true;
  observed_count := 1;
  details := 'Schema health checks completed for the active tenant.';
  return next;
end;
$$;

revoke all on function public.run_schema_health_check() from public, anon;
grant execute on function public.run_schema_health_check() to authenticated;
