-- Mizan platform foundation hardening.
-- Additive only: branches, durable server idempotency, sync mutation tracking,
-- tenant helpers, RLS, and audit hooks. Do not apply without a reviewed backup.

create extension if not exists pgcrypto;

create table if not exists public.tenant_branches (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  code text not null check (code = upper(btrim(code)) and length(btrim(code)) between 1 and 40),
  name text not null check (length(btrim(name)) between 1 and 160),
  address text,
  phone text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, code),
  unique (tenant_id, id)
);

create index if not exists tenant_branches_tenant_active_idx
  on public.tenant_branches (tenant_id, is_active, lower(name), id);

create table if not exists public.staff_branch_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  staff_member_id uuid not null references public.staff_members(id) on delete cascade,
  branch_id uuid not null references public.tenant_branches(id) on delete cascade,
  is_primary boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, staff_member_id, branch_id)
);

create unique index if not exists staff_branch_one_primary_idx
  on public.staff_branch_assignments (tenant_id, staff_member_id)
  where is_primary;
create index if not exists staff_branch_assignments_branch_idx
  on public.staff_branch_assignments (tenant_id, branch_id, staff_member_id);

create table if not exists public.mutation_idempotency_keys (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  scope text not null check (length(btrim(scope)) between 1 and 120),
  idempotency_key text not null check (length(btrim(idempotency_key)) between 8 and 200),
  request_hash text,
  response jsonb,
  status text not null default 'reserved' check (status in ('reserved', 'completed', 'failed')),
  created_at timestamptz not null default timezone('utc', now()),
  completed_at timestamptz,
  expires_at timestamptz not null default timezone('utc', now()) + interval '24 hours',
  unique (tenant_id, scope, idempotency_key)
);

create index if not exists mutation_idempotency_expiry_idx
  on public.mutation_idempotency_keys (expires_at, status);

create table if not exists public.sync_mutations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  client_mutation_id text not null check (length(btrim(client_mutation_id)) between 8 and 200),
  entity_type text not null check (length(btrim(entity_type)) between 1 and 100),
  entity_id uuid,
  operation text not null check (operation in ('insert', 'update', 'delete', 'command')),
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'processing', 'succeeded', 'failed', 'cancelled')),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  last_error text,
  next_attempt_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, client_mutation_id)
);

create index if not exists sync_mutations_ready_idx
  on public.sync_mutations (tenant_id, status, next_attempt_at, created_at);
create index if not exists sync_mutations_entity_idx
  on public.sync_mutations (tenant_id, entity_type, entity_id, created_at desc);

create or replace function public.current_tenant_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select up.tenant_id from public.user_profiles up where up.id = (select auth.uid())),
    (select sm.tenant_id from public.staff_members sm where sm.user_id = (select auth.uid()) and sm.status = 'active' order by sm.created_at limit 1)
  );
$$;

create or replace function public.is_tenant_owner(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.tenants t
    where t.id = p_tenant_id and t.owner_uid = (select auth.uid())
  );
$$;

create or replace function public.reserve_mutation(
  p_scope text,
  p_idempotency_key text,
  p_request_hash text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := (select auth.uid());
  v_existing public.mutation_idempotency_keys;
  v_id bigint;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_scope is null or length(btrim(p_scope)) not between 1 and 120 then raise exception 'Mutation scope is invalid'; end if;
  if p_idempotency_key is null or length(btrim(p_idempotency_key)) not between 8 and 200 then raise exception 'Idempotency key is invalid'; end if;
  select * into v_existing from public.mutation_idempotency_keys
  where tenant_id = v_tenant_id and scope = btrim(p_scope) and idempotency_key = btrim(p_idempotency_key)
  for update;
  if found then
    if v_existing.request_hash is distinct from p_request_hash then raise exception 'Idempotency key was reused with a different request'; end if;
    return jsonb_build_object('reserved', false, 'status', v_existing.status, 'response', v_existing.response);
  end if;
  insert into public.mutation_idempotency_keys (tenant_id, user_id, scope, idempotency_key, request_hash)
  values (v_tenant_id, v_user_id, btrim(p_scope), btrim(p_idempotency_key), p_request_hash)
  returning id into v_id;
  return jsonb_build_object('reserved', true, 'status', 'reserved', 'id', v_id);
end;
$$;

create or replace function public.complete_mutation(
  p_scope text,
  p_idempotency_key text,
  p_status text,
  p_response jsonb default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_record public.mutation_idempotency_keys;
begin
  if v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_status not in ('completed', 'failed') then raise exception 'Mutation status is invalid'; end if;
  update public.mutation_idempotency_keys
  set status = p_status, response = p_response, completed_at = timezone('utc', now())
  where tenant_id = v_tenant_id and scope = btrim(p_scope) and idempotency_key = btrim(p_idempotency_key)
  returning * into v_record;
  if not found then raise exception 'Mutation reservation was not found'; end if;
  return jsonb_build_object('status', v_record.status, 'response', v_record.response);
end;
$$;

create or replace function public.enqueue_sync_mutation(
  p_client_mutation_id text,
  p_entity_type text,
  p_entity_id uuid,
  p_operation text,
  p_payload jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := (select auth.uid());
  v_id uuid;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if p_client_mutation_id is null or length(btrim(p_client_mutation_id)) not between 8 and 200 then raise exception 'Client mutation id is invalid'; end if;
  if p_operation not in ('insert', 'update', 'delete', 'command') then raise exception 'Sync operation is invalid'; end if;
  insert into public.sync_mutations (tenant_id, user_id, client_mutation_id, entity_type, entity_id, operation, payload)
  values (v_tenant_id, v_user_id, btrim(p_client_mutation_id), btrim(p_entity_type), p_entity_id, p_operation, coalesce(p_payload, '{}'::jsonb))
  on conflict (tenant_id, client_mutation_id) do update set updated_at = timezone('utc', now())
  returning id into v_id;
  return v_id;
end;
$$;

-- Timestamp and audit hooks for the new tenant-scoped tables.
drop trigger if exists tenant_branches_updated_at on public.tenant_branches;
create trigger tenant_branches_updated_at before update on public.tenant_branches
for each row execute function public.set_updated_at();
drop trigger if exists tenant_branches_audit on public.tenant_branches;
create trigger tenant_branches_audit after insert or update or delete on public.tenant_branches
for each row execute function public.audit_row_change();
drop trigger if exists staff_branch_assignments_updated_at on public.staff_branch_assignments;
create trigger staff_branch_assignments_updated_at before update on public.staff_branch_assignments
for each row execute function public.set_updated_at();
drop trigger if exists staff_branch_assignments_audit on public.staff_branch_assignments;
create trigger staff_branch_assignments_audit after insert or update or delete on public.staff_branch_assignments
for each row execute function public.audit_row_change();
drop trigger if exists sync_mutations_updated_at on public.sync_mutations;
create trigger sync_mutations_updated_at before update on public.sync_mutations
for each row execute function public.set_updated_at();

alter table public.tenant_branches enable row level security;
alter table public.staff_branch_assignments enable row level security;
alter table public.mutation_idempotency_keys enable row level security;
alter table public.sync_mutations enable row level security;
revoke all on table public.tenant_branches, public.staff_branch_assignments, public.mutation_idempotency_keys, public.sync_mutations from anon, authenticated;

drop policy if exists tenant_branches_select on public.tenant_branches;
create policy tenant_branches_select on public.tenant_branches for select to authenticated
using (public.is_tenant_member(tenant_id));
drop policy if exists tenant_branches_write on public.tenant_branches;
create policy tenant_branches_write on public.tenant_branches for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageBranches','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageBranches','manageSettings']));

drop policy if exists staff_branch_assignments_select on public.staff_branch_assignments;
create policy staff_branch_assignments_select on public.staff_branch_assignments for select to authenticated
using (public.is_tenant_member(tenant_id));
drop policy if exists staff_branch_assignments_write on public.staff_branch_assignments;
create policy staff_branch_assignments_write on public.staff_branch_assignments for all to authenticated
using (
  public.has_tenant_permission(tenant_id, array['manageBranches','manageStaff','manageSettings'])
  and exists (select 1 from public.staff_members sm where sm.id = staff_member_id and sm.tenant_id = tenant_id)
  and exists (select 1 from public.tenant_branches b where b.id = branch_id and b.tenant_id = tenant_id)
)
with check (
  public.has_tenant_permission(tenant_id, array['manageBranches','manageStaff','manageSettings'])
  and exists (select 1 from public.staff_members sm where sm.id = staff_member_id and sm.tenant_id = tenant_id)
  and exists (select 1 from public.tenant_branches b where b.id = branch_id and b.tenant_id = tenant_id)
);

grant select, insert, update, delete on public.tenant_branches to authenticated;
grant select, insert, update, delete on public.staff_branch_assignments to authenticated;

revoke all on function public.current_tenant_id() from public, anon, authenticated;
revoke all on function public.is_tenant_owner(uuid) from public, anon, authenticated;
revoke all on function public.reserve_mutation(text,text,text) from public, anon, authenticated;
revoke all on function public.complete_mutation(text,text,text,jsonb) from public, anon, authenticated;
revoke all on function public.enqueue_sync_mutation(text,text,uuid,text,jsonb) from public, anon, authenticated;
grant execute on function public.current_tenant_id() to authenticated;
grant execute on function public.is_tenant_owner(uuid) to authenticated;
grant execute on function public.reserve_mutation(text,text,text) to authenticated;
grant execute on function public.complete_mutation(text,text,text,jsonb) to authenticated;
grant execute on function public.enqueue_sync_mutation(text,text,uuid,text,jsonb) to authenticated;

-- The mutation and sync tables intentionally have no direct client table grants.
-- Future business RPCs must reserve/complete mutations inside their own transaction.
