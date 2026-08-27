-- Mizan migration
-- id: 20260828010000_approval_balance_adjustment_gate.sql
-- owner: governance-and-ar
-- prerequisites: 20260828000000_approval_enforcement_phase3.sql
-- changes: approval execution ledger and approval-aware balance-adjustment RPC
-- security: exact request matching, tenant scope, one-time consumption, and authenticated grants
-- verification: supabase/tests/20260828010000_approval_balance_adjustment_gate.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

alter table public.approval_requests
  add column if not exists consumed_at timestamptz,
  add column if not exists consumed_by uuid references auth.users(id) on delete set null;

create table if not exists public.approval_request_executions (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  approval_request_id uuid not null references public.approval_requests(id) on delete restrict,
  actor_id uuid not null references auth.users(id) on delete restrict,
  operation text not null check (length(btrim(operation)) between 1 and 120),
  result jsonb not null default '{}'::jsonb check (jsonb_typeof(result) = 'object'),
  created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists approval_request_one_execution_idx
  on public.approval_request_executions (approval_request_id);
create index if not exists approval_request_executions_tenant_idx
  on public.approval_request_executions (tenant_id, created_at desc, id);

create or replace function public.prevent_approval_execution_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception 'Approval execution records are append-only';
end;
$$;

drop trigger if exists approval_request_executions_immutable on public.approval_request_executions;
create trigger approval_request_executions_immutable
before update or delete on public.approval_request_executions
for each row execute function public.prevent_approval_execution_mutation();

create or replace function public.post_manual_balance_adjustment_with_approval(
  p_approval_request_id uuid,
  p_party_type text,
  p_party_id uuid,
  p_amount_minor bigint,
  p_direction text,
  p_currency_code text,
  p_reason text,
  p_reference text default null,
  p_effective_date date default current_date,
  p_debit_account_id uuid default null,
  p_credit_account_id uuid default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_request public.approval_requests;
  v_result jsonb;
begin
  if v_user_id is null or v_tenant_id is null then
    raise exception 'Authenticated tenant membership required';
  end if;
  if p_approval_request_id is null then
    raise exception 'An approved balance-adjustment request is required';
  end if;

  select * into v_request
  from public.approval_requests
  where id = p_approval_request_id
  for update;
  if not found or v_request.tenant_id <> v_tenant_id then
    raise exception 'Approval request was not found in the active tenant';
  end if;
  if v_request.request_type <> 'balance_adjustment' then
    raise exception 'Approval request type does not match the balance adjustment';
  end if;
  if v_request.status <> 'approved' then
    raise exception 'An approved request is required before posting';
  end if;
  if v_request.consumed_at is not null then
    raise exception 'Approval request has already been consumed';
  end if;
  if v_request.target_id is distinct from p_party_id
     or v_request.amount_minor <> p_amount_minor
     or v_request.currency_code <> p_currency_code
     or v_request.reason <> btrim(p_reason) then
    raise exception 'Balance adjustment does not match the approved request';
  end if;

  update public.approval_requests
  set consumed_at = timezone('utc', now()), consumed_by = v_user_id
  where id = p_approval_request_id and consumed_at is null;
  if not found then
    raise exception 'Approval request was consumed concurrently';
  end if;

  v_result := public.post_manual_balance_adjustment(
    p_party_type,
    p_party_id,
    p_amount_minor,
    p_direction,
    p_currency_code,
    p_reason,
    p_reference,
    p_effective_date,
    p_debit_account_id,
    p_credit_account_id,
    p_idempotency_key
  );

  insert into public.approval_request_executions (
    tenant_id, approval_request_id, actor_id, operation, result
  ) values (
    v_tenant_id, p_approval_request_id, v_user_id,
    'post_manual_balance_adjustment', coalesce(v_result, '{}'::jsonb)
  );

  return coalesce(v_result, '{}'::jsonb) || jsonb_build_object(
    'approval_request_id', p_approval_request_id,
    'approval_consumed_at', timezone('utc', now())
  );
end;
$$;

alter table public.approval_request_executions enable row level security;
revoke all on table public.approval_request_executions from anon, authenticated;
grant select on public.approval_request_executions to authenticated;

drop policy if exists approval_request_executions_select on public.approval_request_executions;
create policy approval_request_executions_select on public.approval_request_executions
for select to authenticated
using (
  public.is_tenant_member(tenant_id)
  and exists (
    select 1 from public.approval_requests ar
    where ar.id = approval_request_id
      and (
        ar.requester_id = (select auth.uid())
        or public.approval_decision_permission(ar.tenant_id, ar.request_type)
      )
  )
);

revoke all on function public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.post_manual_balance_adjustment_with_approval(uuid,text,uuid,bigint,text,text,text,text,date,uuid,uuid,text) to authenticated;
