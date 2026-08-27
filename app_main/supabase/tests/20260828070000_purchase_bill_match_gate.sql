-- Mizan purchase-bill match gate regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(6);

select has_function('public', 'assert_purchase_bill_match', array['uuid'], 'purchase-bill match gate RPC exists');
select ok(
  pg_get_functiondef('public.assert_purchase_bill_match(uuid)'::regprocedure)
    like '%public.purchase_bill_three_way_match%',
  'match gate consumes the canonical three-way match evidence'
);
select ok(
  pg_get_functiondef('public.assert_purchase_bill_match(uuid)'::regprocedure)
    like '%Purchase bill is blocked by three-way matching%',
  'match gate rejects blocked bills'
);
select ok(
  pg_get_functiondef('public.assert_purchase_bill_match(uuid)'::regprocedure)
    like '%eligible_for_posting_gate%',
  'match gate returns an explicit posting eligibility state'
);
select ok(
  pg_get_functiondef('public.assert_purchase_bill_match(uuid)'::regprocedure)
    like '%current_tenant_id()%',
  'match gate derives tenant scope from the authenticated session'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name = 'assert_purchase_bill_match'
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute the bill match gate'
);

select * from finish();
rollback;
