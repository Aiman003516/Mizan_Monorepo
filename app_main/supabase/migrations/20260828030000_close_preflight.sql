-- Mizan migration
-- id: 20260828030000_close_preflight.sql
-- owner: accounting-governance
-- prerequisites: 20260828020000_party_statements.sql
-- changes: tenant-scoped month-end close preflight read contract
-- security: authenticated tenant membership and server-derived period scope
-- verification: supabase/tests/20260828030000_close_preflight.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create or replace function public.accounting_close_preflight(p_period_id uuid)
returns table(
  check_code text,
  severity text,
  blocking boolean,
  issue_count bigint,
  message text
)
language sql
stable
security definer
set search_path = public
as $$
  with period as (
    select p.id, p.tenant_id, p.starts_on, p.ends_on, p.status
    from public.accounting_periods p
    where p.id = p_period_id
      and p.tenant_id = public.current_tenant_id()
  ),
  checks as (
    select
      'period_status'::text as check_code,
      case when p.status = 'open' then 'info' else 'high' end as severity,
      (p.status <> 'open') as blocking,
      case when p.status = 'open' then 0::bigint else 1::bigint end as issue_count,
      case when p.status = 'open' then 'The accounting period is open.' else 'The accounting period is not open.' end as message
    from period p

    union all

    select
      'pending_approvals',
      'high',
      count(*) > 0,
      count(*)::bigint,
      'Approval requests remain pending for this tenant.'
    from public.approval_requests ar
    join period p on p.tenant_id = ar.tenant_id
    where ar.tenant_id = public.current_tenant_id()
      and ar.status = 'pending'

    union all

    select
      'draft_journals',
      'high',
      count(*) > 0,
      count(*)::bigint,
      'Draft journal entries remain inside the accounting period.'
    from public.journal_entries je
    join period p on p.tenant_id = je.tenant_id
    where je.tenant_id = public.current_tenant_id()
      and je.entry_date between p.starts_on and p.ends_on
      and je.status = 'draft'

    union all

    select
      'unposted_settlements',
      'high',
      count(*) > 0,
      count(*)::bigint,
      'Settlement drafts remain unposted inside the accounting period.'
    from public.ar_ap_settlements s
    join period p on p.tenant_id = s.tenant_id
    where s.tenant_id = public.current_tenant_id()
      and s.settlement_date between p.starts_on and p.ends_on
      and s.status = 'draft_created'

    union all

    select
      'open_document_anomalies',
      'medium',
      count(*) > 0,
      count(*)::bigint,
      'Document anomalies require review before close.'
    from public.document_anomalies da
    where da.tenant_id = public.current_tenant_id()
      and da.status = 'open'

    union all

    select
      'active_leading_book',
      'high',
      count(*) = 0,
      case when count(*) = 0 then 1::bigint else 0::bigint end,
      case when count(*) = 0 then 'No active leading accounting book is configured.' else 'An active leading accounting book is configured.' end
    from public.accounting_books b
    where b.tenant_id = public.current_tenant_id()
      and b.book_type = 'leading'
      and b.status = 'active'
  )
  select check_code, severity, blocking, issue_count, message
  from checks
  order by blocking desc, severity desc, check_code;
$$;

revoke all on function public.accounting_close_preflight(uuid) from public, anon;
grant execute on function public.accounting_close_preflight(uuid) to authenticated;
