-- Mizan migration
-- id: 20260828000000_approval_enforcement_phase3.sql
-- owner: governance-and-security
-- prerequisites: 20260827293000_manual_balance_adjustment_workflow.sql
-- changes: branch-aware approval contracts, immutable decision events, and decision RPCs
-- security: server-enforced tenant/branch membership, anti-self-approval, RLS, and function grants
-- verification: supabase/tests/20260828000000_approval_enforcement_phase3.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

-- The phase-1 table remains compatible. These columns are additive and nullable so
-- existing approval records can be reviewed and migrated without data rewriting.
alter table public.approval_requests
  add column if not exists branch_id uuid,
  add column if not exists idempotency_key text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.approval_requests'::regclass
      and conname = 'approval_requests_branch_tenant_fk'
  ) then
    alter table public.approval_requests
      add constraint approval_requests_branch_tenant_fk
      foreign key (tenant_id, branch_id)
      references public.tenant_branches (tenant_id, id)
      on delete restrict;
  end if;
end;
$$;

create unique index if not exists approval_requests_idempotency_idx
  on public.approval_requests (tenant_id, requester_id, idempotency_key)
  where idempotency_key is not null;
create index if not exists approval_requests_branch_status_idx
  on public.approval_requests (tenant_id, branch_id, status, created_at desc, id);

create table if not exists public.approval_request_events (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  approval_request_id uuid not null references public.approval_requests(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete restrict,
  from_status text,
  to_status text not null check (to_status in ('pending', 'approved', 'rejected')),
  decision_reason text,
  created_at timestamptz not null default timezone('utc', now()),
  check (from_status is null or from_status in ('pending', 'approved', 'rejected')),
  check (to_status = 'pending' or decision_reason is not null)
);

create index if not exists approval_request_events_request_idx
  on public.approval_request_events (tenant_id, approval_request_id, created_at, id);

create or replace function public.approval_branch_access(
  p_tenant_id uuid,
  p_branch_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_tenant_owner(p_tenant_id)
    or (
      p_branch_id is null
      and public.is_tenant_member(p_tenant_id)
    )
    or exists (
      select 1
      from public.staff_branch_assignments sba
      join public.staff_members sm
        on sm.id = sba.staff_member_id
       and sm.tenant_id = sba.tenant_id
      where sba.tenant_id = p_tenant_id
        and sba.branch_id = p_branch_id
        and sm.user_id = (select auth.uid())
        and sm.status = 'active'
    );
$$;

create or replace function public.approval_decision_permission(
  p_tenant_id uuid,
  p_request_type text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_tenant_owner(p_tenant_id)
    or public.has_tenant_permission(p_tenant_id, array['approveRequests', 'manageSettings'])
    or case p_request_type
      when 'journal' then public.has_tenant_permission(p_tenant_id, array['manageAccounting', 'postJournalEntries'])
      when 'invoice' then public.has_tenant_permission(p_tenant_id, array['manageInvoices', 'manageSettings'])
      when 'bill' then public.has_tenant_permission(p_tenant_id, array['manageBills', 'manageSettings'])
      when 'balance_adjustment' then public.has_tenant_permission(p_tenant_id, array['manageAccounting', 'manageSettings'])
      else false
    end;
$$;

create or replace function public.prevent_approval_request_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.tenant_id is distinct from old.tenant_id
     or new.requester_id is distinct from old.requester_id
     or new.request_type is distinct from old.request_type
     or new.target_id is distinct from old.target_id
     or new.payload is distinct from old.payload
     or new.amount_minor is distinct from old.amount_minor
     or new.currency_code is distinct from old.currency_code
     or new.reason is distinct from old.reason
     or new.branch_id is distinct from old.branch_id
     or new.idempotency_key is distinct from old.idempotency_key then
    raise exception 'Approval request facts are immutable';
  end if;
  if old.status <> 'pending' then
    raise exception 'Approval request has already been decided';
  end if;
  if new.status not in ('pending', 'approved', 'rejected') then
    raise exception 'Approval status is invalid';
  end if;
  if new.status = 'pending' and (new.decided_by is not null or new.decided_at is not null) then
    raise exception 'Pending approval cannot have a decision actor or timestamp';
  end if;
  if new.status <> 'pending' and (new.decided_by is null or new.decided_at is null) then
    raise exception 'A decided approval requires actor and timestamp';
  end if;
  return new;
end;
$$;

drop trigger if exists approval_requests_immutable_facts on public.approval_requests;
create trigger approval_requests_immutable_facts
before update on public.approval_requests
for each row execute function public.prevent_approval_request_mutation();

create or replace function public.prevent_approval_event_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception 'Approval decision events are append-only';
end;
$$;

drop trigger if exists approval_request_events_immutable on public.approval_request_events;
create trigger approval_request_events_immutable
before update or delete on public.approval_request_events
for each row execute function public.prevent_approval_event_mutation();

create or replace function public.create_approval_request(
  p_tenant_id uuid,
  p_request_type text,
  p_target_id uuid default null,
  p_payload jsonb default '{}'::jsonb,
  p_amount_minor bigint default 0,
  p_currency_code text default 'YER',
  p_reason text default '',
  p_branch_id uuid default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_request public.approval_requests;
begin
  if v_user_id is null or not public.is_tenant_member(p_tenant_id) then
    raise exception 'Authenticated tenant membership required';
  end if;
  if not public.approval_branch_access(p_tenant_id, p_branch_id) then
    raise exception 'Branch access required';
  end if;
  if p_request_type not in ('expense', 'invoice', 'bill', 'journal', 'balance_adjustment', 'refund', 'discount', 'period_reopen') then
    raise exception 'Approval request type is invalid';
  end if;
  if p_amount_minor is null or p_amount_minor < 0 then
    raise exception 'Approval amount must be non-negative';
  end if;
  if p_currency_code is null or p_currency_code <> upper(btrim(p_currency_code))
     or length(btrim(p_currency_code)) not between 3 and 5 then
    raise exception 'Approval currency code is invalid';
  end if;
  if p_reason is null or length(btrim(p_reason)) not between 1 and 1000 then
    raise exception 'Approval reason is required';
  end if;
  if p_idempotency_key is not null and length(btrim(p_idempotency_key)) not between 8 and 200 then
    raise exception 'Approval idempotency key is invalid';
  end if;

  if p_idempotency_key is not null then
    select * into v_request
    from public.approval_requests
    where tenant_id = p_tenant_id
      and requester_id = v_user_id
      and idempotency_key = btrim(p_idempotency_key)
    limit 1;
    if found then
      return to_jsonb(v_request);
    end if;
  end if;

  insert into public.approval_requests (
    tenant_id, requester_id, request_type, target_id, payload,
    amount_minor, currency_code, reason, branch_id, idempotency_key
  ) values (
    p_tenant_id, v_user_id, p_request_type, p_target_id, coalesce(p_payload, '{}'::jsonb),
    p_amount_minor, upper(btrim(p_currency_code)), btrim(p_reason), p_branch_id,
    nullif(btrim(p_idempotency_key), '')
  ) returning * into v_request;

  insert into public.approval_request_events (
    tenant_id, approval_request_id, actor_id, from_status, to_status, decision_reason
  ) values (p_tenant_id, v_request.id, v_user_id, null, 'pending', v_request.reason);

  return to_jsonb(v_request);
end;
$$;

create or replace function public.decide_approval_request(
  p_request_id uuid,
  p_decision text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_request public.approval_requests;
  v_updated public.approval_requests;
  v_reason text := nullif(btrim(p_reason), '');
begin
  if v_user_id is null then
    raise exception 'Authenticated user required';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception 'Approval decision is invalid';
  end if;
  if p_decision = 'rejected' and v_reason is null then
    raise exception 'A rejection reason is required';
  end if;

  select * into v_request
  from public.approval_requests
  where id = p_request_id
  for update;
  if not found then
    raise exception 'Approval request was not found';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'Approval request has already been decided';
  end if;
  if v_request.requester_id = v_user_id then
    raise exception 'The requester cannot approve or reject their own request';
  end if;
  if not public.approval_branch_access(v_request.tenant_id, v_request.branch_id) then
    raise exception 'Branch access required';
  end if;
  if not public.approval_decision_permission(v_request.tenant_id, v_request.request_type) then
    raise exception 'Approval permission required';
  end if;

  update public.approval_requests
  set status = p_decision,
      decided_by = v_user_id,
      decided_at = timezone('utc', now())
  where id = p_request_id
    and status = 'pending'
  returning * into v_updated;
  if not found then
    raise exception 'Approval request changed before decision';
  end if;

  insert into public.approval_request_events (
    tenant_id, approval_request_id, actor_id, from_status, to_status, decision_reason
  ) values (
    v_updated.tenant_id, v_updated.id, v_user_id, 'pending', p_decision,
    coalesce(v_reason, v_updated.reason)
  );

  return to_jsonb(v_updated);
end;
$$;

-- Direct writes are intentionally removed. All mutations must pass through the
-- authenticated RPCs above, while SELECT remains available through RLS.
revoke insert, update, delete on public.approval_requests from authenticated;
grant select on public.approval_requests to authenticated;
alter table public.approval_request_events enable row level security;
revoke all on public.approval_request_events from anon, authenticated;
grant select on public.approval_request_events to authenticated;

drop policy if exists approval_requests_select on public.approval_requests;
create policy approval_requests_select on public.approval_requests
for select to authenticated
using (
  public.approval_branch_access(tenant_id, branch_id)
  and (requester_id = (select auth.uid())
    or public.approval_decision_permission(tenant_id, request_type))
);

drop policy if exists approval_requests_insert on public.approval_requests;
drop policy if exists approval_requests_update on public.approval_requests;

drop policy if exists approval_request_events_select on public.approval_request_events;
create policy approval_request_events_select on public.approval_request_events
for select to authenticated
using (
  exists (
    select 1
    from public.approval_requests ar
    where ar.id = approval_request_id
      and ar.tenant_id = approval_request_events.tenant_id
      and public.approval_branch_access(ar.tenant_id, ar.branch_id)
      and (
        ar.requester_id = (select auth.uid())
        or public.approval_decision_permission(ar.tenant_id, ar.request_type)
      )
  )
);

revoke all on function public.approval_branch_access(uuid, uuid) from public, anon, authenticated;
revoke all on function public.approval_decision_permission(uuid, text) from public, anon, authenticated;
revoke all on function public.create_approval_request(uuid, text, uuid, jsonb, bigint, text, text, uuid, text) from public, anon, authenticated;
revoke all on function public.decide_approval_request(uuid, text, text) from public, anon, authenticated;
grant execute on function public.approval_branch_access(uuid, uuid) to authenticated;
grant execute on function public.approval_decision_permission(uuid, text) to authenticated;
grant execute on function public.create_approval_request(uuid, text, uuid, jsonb, bigint, text, text, uuid, text) to authenticated;
grant execute on function public.decide_approval_request(uuid, text, text) to authenticated;
