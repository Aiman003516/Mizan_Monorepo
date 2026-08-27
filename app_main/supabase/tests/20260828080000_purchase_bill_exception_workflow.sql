-- Mizan purchase-bill exception workflow regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(9);

select has_table('public', 'purchase_bill_match_exceptions', 'purchase bill exception table exists');
select has_index('public', 'purchase_bill_match_exceptions_bill_idx', 'purchase bill exception lookup index exists');
select has_function('public', 'request_purchase_bill_match_exception', array['uuid', 'text', 'text'], 'exception request RPC exists');
select has_function('public', 'assert_purchase_bill_posting_eligibility', array['uuid'], 'exception-aware posting eligibility RPC exists');
select has_function('public', 'sync_purchase_bill_exception_state', array[]::text[], 'approval synchronization trigger function exists');
select ok(
  pg_get_functiondef('public.request_purchase_bill_match_exception(uuid,text,text)'::regprocedure)
    like '%public.create_approval_request%',
  'exception request creates a governed bill approval request'
);
select ok(
  pg_get_functiondef('public.assert_purchase_bill_posting_eligibility(uuid)'::regprocedure)
    like '%approved_exception%',
  'posting eligibility recognizes only an approved exception'
);
select ok(
  pg_get_functiondef('public.sync_purchase_bill_exception_state()'::regprocedure)
    like '%decided_by%',
  'approval decisions synchronize the exception decision actor'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name in ('request_purchase_bill_match_exception', 'assert_purchase_bill_posting_eligibility')
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute exception workflow commands'
);

select * from finish();
rollback;
