begin;
select plan(5);
select has_function('public','accounting_source_drilldown',array['text','uuid'],'accounting source drill-down RPC exists');
select ok(pg_get_functiondef('public.accounting_source_drilldown(text,uuid)'::regprocedure) like '%status=''posted''%','drill-down exposes posted journal facts only');
select ok(pg_get_functiondef('public.accounting_source_drilldown(text,uuid)'::regprocedure) like '%current_tenant_id()%','drill-down derives tenant scope from session');
select ok(pg_get_functiondef('public.accounting_source_drilldown(text,uuid)'::regprocedure) like '%viewFinancialReports%','drill-down enforces report permission');
select ok(not exists(select 1 from information_schema.role_routine_grants where routine_schema='public' and routine_name='accounting_source_drilldown' and grantee in('anon','public') and privilege_type='EXECUTE'),'anonymous/public roles cannot execute drill-down');
select * from finish(); rollback;
