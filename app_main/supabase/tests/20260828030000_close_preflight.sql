-- Mizan month-end close preflight regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(10);

select has_function(
  'public',
  'accounting_close_preflight',
  array['uuid'],
  'close preflight RPC exists'
);
select function_privs_are(
  'public',
  'accounting_close_preflight',
  array['uuid'],
  'authenticated',
  array['EXECUTE'],
  'authenticated clients can run close preflight'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%public.current_tenant_id()%',
  'close preflight derives tenant scope from the authenticated context'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%draft_journals%',
  'close preflight checks draft journals'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%unposted_settlements%',
  'close preflight checks unposted settlements'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%pending_approvals%',
  'close preflight checks pending approvals'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%open_document_anomalies%',
  'close preflight checks document anomalies'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%active_leading_book%',
  'close preflight checks the active leading book'
);
select ok(
  pg_get_functiondef('public.accounting_close_preflight(uuid)'::regprocedure)
    like '%blocking%',
  'close preflight exposes blocking status'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name = 'accounting_close_preflight'
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute close preflight'
);

select * from finish();
rollback;
