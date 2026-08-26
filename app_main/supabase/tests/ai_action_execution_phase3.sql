-- Structural/integration checks for AI action execution Phase 3.
-- Run after the cloud source-of-truth, AI Phase 1, AI Phase 2, and Phase 3 migrations.
-- Runtime mutation tests must use authenticated tenant fixtures in a disposable project;
-- this file deliberately creates no users, tenants, invitations, or business records.

select plan(12);

select has_table('public', 'ai_action_requests', 'AI action request table exists');
select has_column('public', 'ai_action_requests', 'confirmation_token', 'confirmation token exists');
select has_column('public', 'ai_action_requests', 'execution_result', 'execution result exists');
select is(
  (select attnotnull from pg_attribute
    where attrelid = 'public.ai_action_requests'::regclass
      and attname = 'confirmation_token' and not attisdropped),
  true,
  'confirmation token is mandatory'
);
select is(
  (select relrowsecurity from pg_class where oid = 'public.ai_action_requests'::regclass),
  true,
  'AI action requests keep RLS enabled'
);
select has_function(
  'public', 'execute_ai_action', array['uuid', 'uuid'],
  'execution function has request id and confirmation token arguments'
);
select is(
  (select prosecdef from pg_proc
    where oid = 'public.execute_ai_action(uuid,uuid)'::regprocedure),
  true,
  'execution function is SECURITY DEFINER'
);
select ok(
  exists (
    select 1 from pg_proc
    where oid = 'public.execute_ai_action(uuid,uuid)'::regprocedure
      and proconfig @> array['search_path=public']
  ),
  'execution function fixes its search_path'
);
select is(
  has_table_privilege('anon', 'public.ai_action_requests', 'SELECT'),
  false,
  'anonymous clients cannot read action requests'
);
select is(
  has_table_privilege('authenticated', 'public.ai_action_requests', 'SELECT'),
  false,
  'authenticated clients cannot read action requests directly'
);
select is(
  has_function_privilege('anon', 'public.execute_ai_action(uuid,uuid)', 'EXECUTE'),
  false,
  'anonymous clients cannot execute AI actions'
);
select is(
  has_function_privilege('authenticated', 'public.execute_ai_action(uuid,uuid)', 'EXECUTE'),
  true,
  'authenticated clients may call the guarded execution function'
);

select * from finish();
rollback;
