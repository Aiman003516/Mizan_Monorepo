begin;
select plan(6);
select has_function('public','submit_crm_quote_for_approval',array['uuid','text'],'quote approval RPC exists');
select has_function('public','list_crm_interactions',array['text','uuid'],'interaction history RPC exists');
select ok(pg_get_functiondef('public.submit_crm_quote_for_approval(uuid,text)'::regprocedure) like '%create_approval_request%','quote approval creates governed approval request');
select ok(pg_get_functiondef('public.sync_crm_quote_approval_state()'::regprocedure) like '%accepted%','approval decisions synchronize quote status');
select ok(pg_get_functiondef('public.list_crm_interactions(text,uuid)'::regprocedure) like '%current_tenant_id()%','interaction history derives tenant scope');
select ok(not exists(select 1 from information_schema.role_routine_grants where routine_schema='public' and routine_name in('submit_crm_quote_for_approval','list_crm_interactions') and grantee in('anon','public') and privilege_type='EXECUTE'),'anonymous/public roles cannot execute CRM commands');
select * from finish(); rollback;
