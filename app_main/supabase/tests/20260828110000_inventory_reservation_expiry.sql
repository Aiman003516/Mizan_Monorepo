begin;
select plan(3);
select has_function('public', 'expire_inventory_reservations', array[]::text[], 'manual expiry RPC exists');
select ok(pg_get_functiondef('public.expire_inventory_reservations()'::regprocedure) like '%status = ''expired''%', 'expiry marks only stale active reservations');
select ok(not exists (select 1 from information_schema.role_routine_grants where routine_schema='public' and routine_name='expire_inventory_reservations' and grantee in ('anon','public') and privilege_type='EXECUTE'), 'anonymous/public roles cannot execute expiry');
select * from finish();
rollback;
