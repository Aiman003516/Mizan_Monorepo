-- Mizan sync-health snapshot regression checks.
-- Execute in a disposable/staging database after the transactional outbox migration.

begin;
select plan(5);

select has_function('public', 'get_sync_health_snapshot', array[]::text[], 'sync-health snapshot RPC exists');
select ok(
  pg_get_functiondef('public.get_sync_health_snapshot()'::regprocedure)
    like '%current_tenant_id()%',
  'sync-health snapshot derives tenant scope from the authenticated session'
);
select ok(
  pg_get_functiondef('public.get_sync_health_snapshot()'::regprocedure)
    like '%server_failed_count%',
  'sync-health snapshot exposes aggregate failure state'
);
select ok(
  pg_get_functiondef('public.get_sync_health_snapshot()'::regprocedure)
    not like '%payload%',
  'sync-health snapshot does not expose event payloads'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name = 'get_sync_health_snapshot'
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute sync-health snapshot'
);

select * from finish();
rollback;
