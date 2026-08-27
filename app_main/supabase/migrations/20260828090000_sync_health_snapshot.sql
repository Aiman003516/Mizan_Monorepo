-- Mizan migration
-- id: 20260828090000_sync_health_snapshot.sql
-- owner: sync-and-governance
-- prerequisites: 20260827270000_transactional_outbox_events.sql
-- changes: tenant-scoped aggregate sync-health snapshot RPC
-- security: session-derived tenant scope, authenticated execution, and no payload exposure
-- verification: supabase/tests/20260828090000_sync_health_snapshot.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create or replace function public.get_sync_health_snapshot()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_pending integer;
  v_processing integer;
  v_failed integer;
  v_succeeded integer;
  v_open_conflicts integer;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  select
    count(*) filter (where status = 'pending'),
    count(*) filter (where status = 'processing'),
    count(*) filter (where status = 'failed'),
    count(*) filter (where status = 'succeeded')
  into v_pending, v_processing, v_failed, v_succeeded
  from public.erp_event_outbox
  where tenant_id = v_tenant_id;
  select count(*) into v_open_conflicts
  from public.sync_conflicts
  where tenant_id = v_tenant_id and status = 'open';
  return jsonb_build_object(
    'server_pending_count', coalesce(v_pending, 0),
    'server_processing_count', coalesce(v_processing, 0),
    'server_failed_count', coalesce(v_failed, 0),
    'server_succeeded_count', coalesce(v_succeeded, 0),
    'open_conflict_count', coalesce(v_open_conflicts, 0),
    'observed_at', timezone('utc', now())
  );
end;
$$;

revoke all on function public.get_sync_health_snapshot() from public, anon, authenticated;
grant execute on function public.get_sync_health_snapshot() to authenticated;
