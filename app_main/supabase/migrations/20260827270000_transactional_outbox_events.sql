-- Mizan transactional event outbox and sync-conflict foundation.
-- Business RPCs should enqueue an event in the same transaction as the
-- authoritative mutation. Delivery workers are retryable and idempotent.

create table if not exists public.erp_event_outbox (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  event_name text not null check (length(btrim(event_name)) between 1 and 160),
  aggregate_type text not null check (length(btrim(aggregate_type)) between 1 and 100),
  aggregate_id uuid,
  event_version integer not null default 1 check (event_version > 0),
  idempotency_key text not null check (length(btrim(idempotency_key)) between 8 and 240),
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'processing', 'succeeded', 'failed', 'cancelled')),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  last_error text,
  next_attempt_at timestamptz not null default timezone('utc', now()),
  locked_by text,
  locked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, idempotency_key),
  unique (tenant_id, id)
);

create table if not exists public.sync_conflicts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  client_mutation_id text not null,
  entity_type text not null,
  entity_id uuid,
  local_payload jsonb not null default '{}'::jsonb,
  server_payload jsonb not null default '{}'::jsonb,
  conflict_fields jsonb not null default '[]'::jsonb,
  status text not null default 'open' check (status in ('open', 'resolved', 'dismissed')),
  resolution_note text,
  created_at timestamptz not null default timezone('utc', now()),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete set null,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, client_mutation_id, entity_type)
);

create index if not exists erp_event_outbox_ready_idx
  on public.erp_event_outbox (tenant_id, status, next_attempt_at, created_at, id);
create index if not exists erp_event_outbox_aggregate_idx
  on public.erp_event_outbox (tenant_id, aggregate_type, aggregate_id, created_at desc);
create index if not exists sync_conflicts_status_idx
  on public.sync_conflicts (tenant_id, status, created_at desc, id);

create or replace function public.enqueue_erp_event(
  p_event_name text,
  p_aggregate_type text,
  p_aggregate_id uuid,
  p_event_version integer,
  p_idempotency_key text,
  p_payload jsonb
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_event_name is null or length(btrim(p_event_name)) not between 1 and 160
     or p_aggregate_type is null or length(btrim(p_aggregate_type)) not between 1 and 100
     or p_event_version is null or p_event_version <= 0
     or p_idempotency_key is null or length(btrim(p_idempotency_key)) not between 8 and 240 then
    raise exception 'ERP event envelope is invalid';
  end if;
  insert into public.erp_event_outbox (tenant_id, event_name, aggregate_type, aggregate_id, event_version, idempotency_key, payload)
  values (v_tenant_id, btrim(p_event_name), btrim(p_aggregate_type), p_aggregate_id, p_event_version, btrim(p_idempotency_key), coalesce(p_payload, '{}'::jsonb))
  on conflict (tenant_id, idempotency_key) do update set updated_at = timezone('utc', now())
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.claim_erp_events(
  p_worker_id text,
  p_limit integer default 50
)
returns table(id uuid, tenant_id uuid, event_name text, aggregate_type text, aggregate_id uuid, event_version integer, idempotency_key text, payload jsonb, attempt_count integer)
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null or public.current_tenant_id() is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_worker_id is null or length(btrim(p_worker_id)) not between 8 and 120 or p_limit is null or p_limit not between 1 and 200 then raise exception 'Worker claim data is invalid'; end if;
  return query
  with ready as (
    select e.id from public.erp_event_outbox e
    where e.tenant_id = public.current_tenant_id()
      and e.status in ('pending', 'failed')
      and e.next_attempt_at <= timezone('utc', now())
    order by e.created_at, e.id
    for update skip locked
    limit p_limit
  )
  update public.erp_event_outbox e
  set status = 'processing', locked_by = btrim(p_worker_id), locked_at = timezone('utc', now()), attempt_count = e.attempt_count + 1
  from ready
  where e.id = ready.id
  returning e.id, e.tenant_id, e.event_name, e.aggregate_type, e.aggregate_id, e.event_version, e.idempotency_key, e.payload, e.attempt_count;
end;
$$;

create or replace function public.complete_erp_event(
  p_event_id uuid,
  p_worker_id text,
  p_status text,
  p_error text default null,
  p_retry_seconds integer default 300
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_record public.erp_event_outbox;
  v_status text := case when p_status = 'succeeded' then 'succeeded' when p_status = 'cancelled' then 'cancelled' else 'failed' end;
begin
  if auth.uid() is null or public.current_tenant_id() is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_worker_id is null or length(btrim(p_worker_id)) < 8 or p_event_id is null then raise exception 'Event completion data is invalid'; end if;
  if v_status = 'failed' and (p_retry_seconds is null or p_retry_seconds not between 10 and 86400) then raise exception 'Retry interval is invalid'; end if;
  update public.erp_event_outbox
  set status = v_status,
      last_error = case when v_status = 'failed' then nullif(btrim(p_error), '') else null end,
      next_attempt_at = case when v_status = 'failed' then timezone('utc', now()) + make_interval(secs => p_retry_seconds) else next_attempt_at end,
      locked_by = null,
      locked_at = null
  where id = p_event_id and tenant_id = public.current_tenant_id() and status = 'processing' and locked_by = btrim(p_worker_id)
  returning * into v_record;
  if not found then raise exception 'Event claim was not found or is owned by another worker'; end if;
  return jsonb_build_object('id', v_record.id, 'status', v_record.status, 'attempt_count', v_record.attempt_count);
end;
$$;

create or replace function public.record_sync_conflict(
  p_client_mutation_id text,
  p_entity_type text,
  p_entity_id uuid,
  p_local_payload jsonb,
  p_server_payload jsonb,
  p_conflict_fields jsonb
)
returns uuid language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_client_mutation_id is null or length(btrim(p_client_mutation_id)) not between 8 and 200 or p_entity_type is null or length(btrim(p_entity_type)) = 0 then raise exception 'Sync conflict data is invalid'; end if;
  insert into public.sync_conflicts (tenant_id, client_mutation_id, entity_type, entity_id, local_payload, server_payload, conflict_fields)
  values (v_tenant_id, btrim(p_client_mutation_id), btrim(p_entity_type), p_entity_id, coalesce(p_local_payload, '{}'::jsonb), coalesce(p_server_payload, '{}'::jsonb), coalesce(p_conflict_fields, '[]'::jsonb))
  on conflict (tenant_id, client_mutation_id, entity_type) do update set local_payload = excluded.local_payload, server_payload = excluded.server_payload, conflict_fields = excluded.conflict_fields, status = 'open', resolved_at = null, resolved_by = null, updated_at = timezone('utc', now())
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.resolve_sync_conflict(
  p_conflict_id uuid,
  p_status text,
  p_resolution_note text
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null or public.current_tenant_id() is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_status not in ('resolved', 'dismissed') or p_resolution_note is null or length(btrim(p_resolution_note)) not between 1 and 500 then raise exception 'Conflict resolution is invalid'; end if;
  update public.sync_conflicts
  set status = p_status, resolution_note = btrim(p_resolution_note), resolved_at = timezone('utc', now()), resolved_by = auth.uid()
  where id = p_conflict_id and tenant_id = public.current_tenant_id() and status = 'open'
  returning id into v_id;
  if not found then raise exception 'Open sync conflict was not found'; end if;
  return jsonb_build_object('id', v_id, 'status', p_status);
end;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['erp_event_outbox','sync_conflicts'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy erp_event_outbox_select on public.erp_event_outbox for select to authenticated using (public.is_tenant_member(tenant_id));
create policy sync_conflicts_select on public.sync_conflicts for select to authenticated using (public.is_tenant_member(tenant_id));

revoke all on function public.enqueue_erp_event(text, text, uuid, integer, text, jsonb) from public, anon;
revoke all on function public.claim_erp_events(text, integer) from public, anon;
revoke all on function public.complete_erp_event(uuid, text, text, text, integer) from public, anon;
revoke all on function public.record_sync_conflict(text, text, uuid, jsonb, jsonb, jsonb) from public, anon;
revoke all on function public.resolve_sync_conflict(uuid, text, text) from public, anon;
grant execute on function public.enqueue_erp_event(text, text, uuid, integer, text, jsonb) to authenticated;
grant execute on function public.claim_erp_events(text, integer) to authenticated;
grant execute on function public.complete_erp_event(uuid, text, text, text, integer) to authenticated;
grant execute on function public.record_sync_conflict(text, text, uuid, jsonb, jsonb, jsonb) to authenticated;
grant execute on function public.resolve_sync_conflict(uuid, text, text) to authenticated;
