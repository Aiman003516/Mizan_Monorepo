-- Mizan migration
-- id: 20260828140000_accounting_source_drilldown.sql
-- owner: accounting-and-reporting
-- prerequisites: 20260827170000_accounting_ledger_foundation.sql
-- changes: read-only source-to-journal drill-down RPC
-- security: authenticated tenant scope, report permission, posted facts only, and no mutation grants
-- verification: supabase/tests/20260828140000_accounting_source_drilldown.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create or replace function public.accounting_source_drilldown(p_source_type text, p_source_id uuid)
returns table(journal_entry_id uuid, entry_number text, entry_date date, description text, currency_code text, journal_status text, line_id uuid, line_number integer, account_id uuid, account_code text, account_name text, debit_minor bigint, credit_minor bigint, line_description text)
language sql stable security definer set search_path=public as $$
 select je.id,je.entry_number,je.entry_date,je.description,je.currency_code,je.status,jl.id,jl.line_number,jl.account_id,coa.code,coa.name,jl.debit_minor,jl.credit_minor,jl.description
 from public.journal_entries je
 join public.journal_lines jl on jl.journal_entry_id=je.id and jl.tenant_id=je.tenant_id
 join public.chart_of_accounts coa on coa.id=jl.account_id and coa.tenant_id=je.tenant_id
 where je.tenant_id=public.current_tenant_id() and public.is_tenant_member(je.tenant_id)
   and public.has_tenant_permission(je.tenant_id,array['viewFinancialReports','manageAccounting','manageSettings'])
   and je.status='posted' and je.source_type=btrim(p_source_type) and je.source_id=p_source_id
 order by je.entry_date,je.entry_number,jl.line_number;
$$;
revoke all on function public.accounting_source_drilldown(text,uuid) from public,anon,authenticated;
grant execute on function public.accounting_source_drilldown(text,uuid) to authenticated;
