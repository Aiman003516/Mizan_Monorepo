-- Mizan settlement idempotency regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(9);

select has_column('public', 'ar_ap_settlements', 'idempotency_key', 'settlements store idempotency keys');
select has_index('public', 'ar_ap_settlements_idempotency_idx', 'settlement idempotency keys are unique per tenant');
select has_function(
  'public',
  'create_settlement_draft_idempotent',
  array['text', 'text', 'uuid', 'uuid', 'bigint', 'text', 'date', 'text', 'text', 'uuid', 'uuid', 'text'],
  'idempotent settlement RPC exists'
);
select function_privs_are(
  'public',
  'create_settlement_draft_idempotent',
  array['text', 'text', 'uuid', 'uuid', 'bigint', 'text', 'date', 'text', 'text', 'uuid', 'uuid', 'text'],
  'authenticated',
  array['EXECUTE'],
  'authenticated clients can create retry-safe settlement drafts'
);
select ok(
  pg_get_functiondef('public.create_settlement_draft_idempotent(text,text,uuid,uuid,bigint,text,date,text,text,uuid,uuid,text)'::regprocedure)
    like '%pg_advisory_xact_lock%',
  'settlement retries serialize on the tenant and idempotency key'
);
select ok(
  pg_get_functiondef('public.create_settlement_draft_idempotent(text,text,uuid,uuid,bigint,text,date,text,text,uuid,uuid,text)'::regprocedure)
    like '%idempotency_key%',
  'settlement retries look up the existing key'
);
select ok(
  pg_get_functiondef('public.create_settlement_draft_idempotent(text,text,uuid,uuid,bigint,text,date,text,text,uuid,uuid,text)'::regprocedure)
    like '%create_settlement_draft(%',
  'new settlement drafts delegate to the canonical settlement command'
);
select ok(
  pg_get_functiondef('public.create_settlement_draft_idempotent(text,text,uuid,uuid,bigint,text,date,text,text,uuid,uuid,text)'::regprocedure)
    like '%public.current_tenant_id()%',
  'settlement idempotency is tenant scoped'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name = 'create_settlement_draft_idempotent'
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute idempotent settlement creation'
);

select * from finish();
rollback;
