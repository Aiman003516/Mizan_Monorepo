-- Mizan approval-aware balance-adjustment regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(12);

select has_table('public', 'approval_request_executions', 'approval executions exist');
select has_column('public', 'approval_requests', 'consumed_at', 'approval requests record consumption time');
select has_column('public', 'approval_requests', 'consumed_by', 'approval requests record consuming actor');
select has_index('public', 'approval_request_one_execution_idx', 'one execution is allowed per request');
select has_trigger('public', 'approval_request_executions', 'approval_request_executions_immutable', 'execution records are append-only');
select has_function(
  'public',
  'post_manual_balance_adjustment_with_approval',
  array['uuid', 'text', 'uuid', 'bigint', 'text', 'text', 'text', 'text', 'date', 'uuid', 'uuid', 'text'],
  'approval-aware posting RPC exists'
);
select function_privs_are(
  'public',
  'post_manual_balance_adjustment_with_approval',
  array['uuid', 'text', 'uuid', 'bigint', 'text', 'text', 'text', 'text', 'date', 'uuid', 'uuid', 'text'],
  'authenticated',
  array['EXECUTE'],
  'authenticated clients can use the approval-aware posting RPC'
);
select ok(
  pg_get_functiondef(
    'public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure
  ) like '%v_request.status <> ''approved''%',
  'posting requires an approved request'
);
select ok(
  pg_get_functiondef(
    'public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure
  ) like '%v_request.consumed_at is not null%',
  'posting rejects a consumed request'
);
select ok(
  pg_get_functiondef(
    'public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure
  ) like '%v_request.target_id is distinct from p_party_id%',
  'posting matches the approved target'
);
select ok(
  pg_get_functiondef(
    'public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure
  ) like '%approval_request_executions%',
  'posting records execution history'
);
select ok(
  not exists (
    select 1
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name = 'approval_request_executions'
      and grantee = 'authenticated'
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
  ),
  'authenticated clients cannot mutate execution history directly'
);
select ok(
  pg_get_functiondef(
    'public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure
  ) like '%post_manual_balance_adjustment(%',
  'approved execution delegates to the canonical double-entry posting RPC'
);

select * from finish();
rollback;
