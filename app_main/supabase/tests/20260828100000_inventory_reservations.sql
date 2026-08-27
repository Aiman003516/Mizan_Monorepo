-- Mizan inventory reservation regression checks.
-- Execute in disposable/staging Supabase after the inventory bridge migration.

begin;
select plan(8);
select has_table('public', 'inventory_reservations', 'inventory reservations table exists');
select has_index('public', 'inventory_reservations_available_idx', 'available reservation lookup index exists');
select has_function('public', 'reserve_inventory', array['text','text','numeric','text','text','uuid','timestamp with time zone','text'], 'reserve RPC exists');
select has_function('public', 'release_inventory_reservation', array['uuid'], 'release RPC exists');
select ok(pg_get_functiondef('public.reserve_inventory(text,text,numeric,text,text,uuid,timestamptz,text)'::regprocedure) like '%for update%', 'reserve locks the authoritative balance');
select ok(pg_get_functiondef('public.reserve_inventory(text,text,numeric,text,text,uuid,timestamptz,text)'::regprocedure) like '%Insufficient available inventory%', 'reserve rejects oversubscription');
select ok(pg_get_functiondef('public.reserve_inventory(text,text,numeric,text,text,uuid,timestamptz,text)'::regprocedure) like '%idempotency_key%', 'reserve supports retry-safe idempotency');
select ok(not exists (select 1 from information_schema.role_routine_grants where routine_schema='public' and routine_name in ('reserve_inventory','release_inventory_reservation') and grantee in ('anon','public') and privilege_type='EXECUTE'), 'anonymous/public roles cannot execute reservation commands');
select * from finish();
rollback;
