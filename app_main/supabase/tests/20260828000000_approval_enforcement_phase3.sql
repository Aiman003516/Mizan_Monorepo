-- Mizan approval enforcement regression checks.
-- Execute in a disposable/staging database with pgTAP and the canonical
-- migrations applied. This file is not production deployment SQL.

begin;
select plan(18);

select has_table('public', 'approval_requests', 'approval_requests exists');
select has_column('public', 'approval_requests', 'branch_id', 'approval requests carry branch scope');
select has_column('public', 'approval_requests', 'idempotency_key', 'approval requests carry idempotency');
select has_table('public', 'approval_request_events', 'approval decision events exist');
select has_column('public', 'approval_request_events', 'actor_id', 'approval events identify the actor');
select has_index('public', 'approval_requests_idempotency_idx', 'approval requests have idempotency uniqueness');
select has_index('public', 'approval_requests_branch_status_idx', 'approval requests have branch/status lookup');

select has_function('public', 'approval_branch_access', array['uuid', 'uuid'], 'branch access helper exists');
select has_function('public', 'approval_decision_permission', array['uuid', 'text'], 'decision permission helper exists');
select has_function('public', 'create_approval_request', array['uuid', 'text', 'uuid', 'jsonb', 'bigint', 'text', 'text', 'uuid', 'text'], 'request RPC exists');
select has_function('public', 'decide_approval_request', array['uuid', 'text', 'text'], 'decision RPC exists');

select has_trigger('public', 'approval_requests', 'approval_requests_immutable_facts', 'approval facts are immutable');
select has_trigger('public', 'approval_request_events', 'approval_request_events_immutable', 'approval events are append-only');
select policies_are('public', 'approval_requests', ARRAY['approval_requests_select'], 'approval requests expose only the select policy');
select policies_are('public', 'approval_request_events', ARRAY['approval_request_events_select'], 'approval events expose only the select policy');

select function_privs_are('public', 'create_approval_request', ARRAY['uuid', 'text', 'uuid', 'jsonb', 'bigint', 'text', 'text', 'uuid', 'text'], 'authenticated', ARRAY['EXECUTE'], 'authenticated users can request approval through RPC');
select function_privs_are('public', 'decide_approval_request', ARRAY['uuid', 'text', 'text'], 'authenticated', ARRAY['EXECUTE'], 'authenticated users can decide through RPC');

select ok(
  not exists (
    select 1
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name = 'approval_requests'
      and grantee = 'authenticated'
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
  ),
  'authenticated users have no direct approval mutation grants'
);
select ok(
  not exists (
    select 1
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name = 'approval_request_events'
      and grantee = 'authenticated'
      and privilege_type in ('INSERT', 'UPDATE', 'DELETE')
  ),
  'authenticated users cannot mutate approval events directly'
);

select * from finish();
rollback;
