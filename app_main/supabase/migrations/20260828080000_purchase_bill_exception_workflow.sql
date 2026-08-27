-- Mizan migration
-- id: 20260828080000_purchase_bill_exception_workflow.sql
-- owner: procurement-and-accounting
-- prerequisites: 20260828070000_purchase_bill_match_gate.sql
-- changes: purchase-bill match exception requests and approval synchronization
-- security: tenant/branch scope, maker-checker approval, RLS, restricted grants, and audit
-- verification: supabase/tests/20260828080000_purchase_bill_exception_workflow.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create table if not exists public.purchase_bill_match_exceptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  branch_id uuid,
  bill_id uuid not null references public.bills(id) on delete restrict,
  approval_request_id uuid references public.approval_requests(id) on delete restrict,
  reason text not null check (length(btrim(reason)) between 1 and 1000),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  requested_by uuid not null references auth.users(id) on delete restrict,
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id),
  foreign key (tenant_id, branch_id) references public.tenant_branches(tenant_id, id) on delete restrict,
  foreign key (tenant_id, bill_id) references public.bills(tenant_id, id) on delete restrict,
  foreign key (tenant_id, approval_request_id) references public.approval_requests(tenant_id, id) on delete restrict
);

create unique index if not exists purchase_bill_match_exceptions_one_pending_idx
  on public.purchase_bill_match_exceptions (tenant_id, bill_id)
  where status = 'pending';
create index if not exists purchase_bill_match_exceptions_bill_idx
  on public.purchase_bill_match_exceptions (tenant_id, bill_id, status, created_at desc);

create or replace function public.request_purchase_bill_match_exception(
  p_bill_id uuid,
  p_reason text,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_bill public.bills;
  v_branch_id uuid;
  v_exception public.purchase_bill_match_exceptions;
  v_approval jsonb;
  v_reason text := btrim(p_reason);
  v_key text := nullif(btrim(p_idempotency_key), '');
  v_blocked_count integer;
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageBills','manageProcurement','manageSettings']) then raise exception 'Purchase bill exception permission required'; end if;
  if v_reason is null or length(v_reason) not between 1 and 1000 then raise exception 'Exception reason is required'; end if;
  select * into v_bill from public.bills where id = p_bill_id and tenant_id = v_tenant_id for share;
  if not found or v_bill.status = 'void' then raise exception 'Purchase bill was not found'; end if;
  select po.branch_id into v_branch_id
  from public.purchase_orders po
  where po.id = v_bill.purchase_order_id and po.tenant_id = v_tenant_id;
  if v_bill.purchase_order_id is not null and not public.approval_branch_access(v_tenant_id, v_branch_id) then raise exception 'Branch access required'; end if;
  select count(*) filter (where match_status = 'blocked') into v_blocked_count
  from public.purchase_bill_three_way_match(p_bill_id);
  if coalesce(v_blocked_count, 0) = 0 then raise exception 'A match exception is not required'; end if;
  if v_key is not null then
    select * into v_exception from public.purchase_bill_match_exceptions
    where tenant_id = v_tenant_id and bill_id = p_bill_id and requested_by = v_user_id
      and reason = v_reason and status = 'pending'
    limit 1;
    if found then return to_jsonb(v_exception); end if;
  end if;
  if exists (select 1 from public.purchase_bill_match_exceptions where tenant_id = v_tenant_id and bill_id = p_bill_id and status = 'pending') then
    raise exception 'A purchase bill exception is already pending';
  end if;
  v_approval := public.create_approval_request(
    v_tenant_id,
    'bill',
    p_bill_id,
    jsonb_build_object('bill_id', p_bill_id, 'exception_reason', v_reason, 'match_blocked_count', v_blocked_count),
    v_bill.total_amount,
    v_bill.currency_code,
    v_reason,
    v_branch_id,
    coalesce(v_key, 'purchase-bill-exception:' || p_bill_id::text)
  );
  insert into public.purchase_bill_match_exceptions (tenant_id, branch_id, bill_id, approval_request_id, reason, requested_by)
  values (v_tenant_id, v_branch_id, p_bill_id, (v_approval->>'id')::uuid, v_reason, v_user_id)
  returning * into v_exception;
  return to_jsonb(v_exception) || jsonb_build_object('approval_request', v_approval);
end;
$$;

create or replace function public.sync_purchase_bill_exception_state()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  if new.request_type = 'bill' and new.target_id is not null then
    update public.purchase_bill_match_exceptions
    set status = case when new.status = 'approved' then 'approved' when new.status = 'rejected' then 'rejected' else status end,
        decided_by = case when new.status in ('approved', 'rejected') then new.decided_by else decided_by end,
        decided_at = case when new.status in ('approved', 'rejected') then timezone('utc', now()) else decided_at end
    where approval_request_id = new.id and tenant_id = new.tenant_id and status = 'pending';
  end if;
  return new;
end;
$$;

drop trigger if exists approval_requests_purchase_bill_exception_state on public.approval_requests;
create trigger approval_requests_purchase_bill_exception_state
after update of status on public.approval_requests
for each row execute function public.sync_purchase_bill_exception_state();

create or replace function public.assert_purchase_bill_posting_eligibility(p_bill_id uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_bill public.bills;
  v_branch_id uuid;
  v_total_lines integer;
  v_blocked_lines integer;
  v_exception public.purchase_bill_match_exceptions;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageBills','manageAccounting','manageSettings']) then raise exception 'Purchase bill approval permission required'; end if;
  select * into v_bill from public.bills where id = p_bill_id and tenant_id = v_tenant_id;
  if not found or v_bill.status = 'void' then raise exception 'Purchase bill was not found'; end if;
  if v_bill.purchase_order_id is not null then
    select branch_id into v_branch_id from public.purchase_orders where id = v_bill.purchase_order_id and tenant_id = v_tenant_id;
    if not public.approval_branch_access(v_tenant_id, v_branch_id) then raise exception 'Branch access required'; end if;
  end if;
  select count(*), count(*) filter (where match_status = 'blocked') into v_total_lines, v_blocked_lines
  from public.purchase_bill_three_way_match(p_bill_id);
  if v_total_lines = 0 then raise exception 'Purchase bill has no matchable lines'; end if;
  if v_blocked_lines = 0 then
    return jsonb_build_object('bill_id', p_bill_id, 'status', 'matched', 'line_count', v_total_lines, 'blocked_line_count', 0);
  end if;
  select * into v_exception from public.purchase_bill_match_exceptions
  where tenant_id = v_tenant_id and bill_id = p_bill_id and status = 'approved'
  order by decided_at desc nulls last, created_at desc limit 1;
  if not found then raise exception 'Purchase bill is blocked and has no approved exception'; end if;
  return jsonb_build_object('bill_id', p_bill_id, 'status', 'approved_exception', 'line_count', v_total_lines, 'blocked_line_count', v_blocked_lines, 'exception_id', v_exception.id, 'exception_reason', v_exception.reason);
end;
$$;

drop trigger if exists purchase_bill_match_exceptions_updated_at on public.purchase_bill_match_exceptions;
create trigger purchase_bill_match_exceptions_updated_at before update on public.purchase_bill_match_exceptions for each row execute function public.set_updated_at();
drop trigger if exists purchase_bill_match_exceptions_audit on public.purchase_bill_match_exceptions;
create trigger purchase_bill_match_exceptions_audit after insert or update or delete on public.purchase_bill_match_exceptions for each row execute function public.audit_row_change();
alter table public.purchase_bill_match_exceptions enable row level security;
revoke all on table public.purchase_bill_match_exceptions from anon, authenticated;
grant select on table public.purchase_bill_match_exceptions to authenticated;
drop policy if exists purchase_bill_match_exceptions_select on public.purchase_bill_match_exceptions;
create policy purchase_bill_match_exceptions_select on public.purchase_bill_match_exceptions for select to authenticated using (tenant_id = public.current_tenant_id() and public.is_tenant_member(tenant_id));

revoke all on function public.request_purchase_bill_match_exception(uuid, text, text) from public, anon, authenticated;
revoke all on function public.assert_purchase_bill_posting_eligibility(uuid) from public, anon, authenticated;
grant execute on function public.request_purchase_bill_match_exception(uuid, text, text) to authenticated;
grant execute on function public.assert_purchase_bill_posting_eligibility(uuid) to authenticated;
