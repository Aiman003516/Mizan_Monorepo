-- Phase 4 AI action expansion schema/security tests.
-- Run after the Phase 4 migration in a disposable Supabase database.
-- No users, tenants, or business records are created here.

select plan(23);

select has_table('public', 'ai_action_requests', 'AI action request table exists');
select has_function('public', 'update_customer_for_tenant', array['uuid','uuid','timestamptz','jsonb'], 'customer update RPC exists');
select has_function('public', 'update_vendor_for_tenant', array['uuid','uuid','timestamptz','jsonb'], 'vendor update RPC exists');
select has_function('public', 'update_invoice_for_tenant', array['uuid','uuid','timestamptz','jsonb'], 'invoice update RPC exists');
select has_function('public', 'update_bill_for_tenant', array['uuid','uuid','timestamptz','jsonb'], 'bill update RPC exists');
select has_function('public', 'post_balance_adjustment_for_tenant', array['uuid','text','uuid','bigint','text','text','text','text','text','timestamptz','uuid'], 'balance adjustment RPC exists');
select has_function('public', 'post_journal_entry_for_tenant', array['uuid','text','date','text','jsonb','uuid'], 'journal posting RPC exists');
select has_function('public', 'archive_customer_for_tenant', array['uuid','uuid','timestamptz'], 'customer archive RPC exists');
select has_function('public', 'archive_vendor_for_tenant', array['uuid','uuid','timestamptz'], 'vendor archive RPC exists');
select has_function('public', 'void_invoice_for_tenant', array['uuid','uuid','timestamptz'], 'invoice void RPC exists');
select has_function('public', 'void_bill_for_tenant', array['uuid','uuid','timestamptz'], 'bill void RPC exists');

select is((select prosecdef from pg_proc where oid='public.execute_ai_action(uuid,uuid)'::regprocedure), true, 'AI execution wrapper is SECURITY DEFINER');
select ok((select proconfig @> array['search_path=public'] from pg_proc where oid='public.execute_ai_action(uuid,uuid)'::regprocedure), 'AI execution wrapper fixes search_path');
select is(has_function_privilege('anon','public.execute_ai_action(uuid,uuid)','EXECUTE'), false, 'anonymous execution remains blocked');
select is(has_function_privilege('authenticated','public.execute_ai_action(uuid,uuid)','EXECUTE'), true, 'authenticated execution remains available');
select is(has_function_privilege('anon','public.post_journal_entry_for_tenant(uuid,text,date,text,jsonb,uuid)','EXECUTE'), false, 'anonymous journal posting is blocked');
select is(has_function_privilege('authenticated','public.post_journal_entry_for_tenant(uuid,text,date,text,jsonb,uuid)','EXECUTE'), false, 'journal posting is only reachable through AI confirmation');

select ok((select pg_get_functiondef('public.post_journal_entry_for_tenant(uuid,text,date,text,jsonb,uuid)'::regprocedure) like '%v_total <> 0%'), 'journal RPC enforces debit-credit balance');
select ok((select pg_get_functiondef('public.post_balance_adjustment_for_tenant(uuid,text,uuid,bigint,text,text,text,text,text,timestamptz,uuid)'::regprocedure) like '%base currency%'), 'balance adjustment enforces tenant base currency');
select ok((select pg_get_functiondef('public.update_customer_for_tenant(uuid,uuid,timestamptz,jsonb)'::regprocedure) like '%changed since the preview%'), 'customer update enforces optimistic concurrency');
select ok((select pg_get_functiondef('public.update_invoice_for_tenant(uuid,uuid,timestamptz,jsonb)'::regprocedure) like '%Only draft invoices can be edited%'), 'invoice update restricts editable status');
select ok((select pg_get_functiondef('public.void_invoice_for_tenant(uuid,uuid,timestamptz)'::regprocedure) like '%amount_paid <> 0%'), 'invoice void rejects paid documents');
select ok(not exists (select 1 from pg_proc where proname in ('delete_customer_for_tenant','delete_vendor_for_tenant','delete_invoice_for_tenant','delete_bill_for_tenant')), 'hard-delete AI RPCs do not exist');

select * from finish();
rollback;
