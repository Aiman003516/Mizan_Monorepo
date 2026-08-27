-- Mizan party-statement regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(10);

select has_function(
  'public',
  'party_statement',
  array['text', 'uuid', 'date', 'date'],
  'party statement RPC exists'
);
select function_privs_are(
  'public',
  'party_statement',
  array['text', 'uuid', 'date', 'date'],
  'authenticated',
  array['EXECUTE'],
  'authenticated clients can read party statements'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%public.current_tenant_id()%',
  'statement query derives tenant scope from the authenticated context'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%i.tenant_id = public.current_tenant_id()%',
  'invoice activity is tenant scoped'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%b.tenant_id = public.current_tenant_id()%',
  'bill activity is tenant scoped'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%s.status = ''posted''%',
  'only posted settlements enter statements'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%a.status = ''posted''%',
  'only posted balance adjustments enter statements'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%running_balance_minor%',
  'statement output contains a running balance'
);
select ok(
  pg_get_functiondef('public.party_statement(text,uuid,date,date)'::regprocedure)
    like '%where p_from is not null and e.entry_date < p_from%',
  'statement output computes an opening balance before the requested period'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name = 'party_statement'
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute party statements'
);

select * from finish();
rollback;
