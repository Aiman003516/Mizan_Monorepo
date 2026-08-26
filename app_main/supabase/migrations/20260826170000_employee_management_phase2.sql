-- Phase 2 employee management.
-- Apply after 20260826150000_employee_invitation_phase1.sql.
-- This migration is intentionally separate so installations that already applied
-- Phase 1 still receive bulk invitation and scalable staff-management support.

create table if not exists public.invitation_batches (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  role_id uuid not null references public.roles(id) on delete restrict,
  requested_count integer not null check (requested_count between 1 and 100),
  result_json jsonb not null default '{}'::jsonb,
  idempotency_key uuid not null,
  created_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, idempotency_key)
);

create index if not exists invitation_batches_tenant_created_idx
  on public.invitation_batches (tenant_id, created_at desc);

alter table public.invitation_batches enable row level security;
drop policy if exists invitation_batches_tenant_read on public.invitation_batches;
create policy invitation_batches_tenant_read
  on public.invitation_batches for select to authenticated
  using (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));

create or replace function public.set_staff_status(
  p_user_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid;
begin
  if p_status not in ('active', 'suspended', 'removed') then
    raise exception 'Invalid staff status';
  end if;
  select sm.tenant_id
    into v_tenant_id
    from public.staff_members sm
   where sm.user_id = auth.uid() and sm.status = 'active'
   limit 1;
  if v_tenant_id is null or not public.has_tenant_permission(
    v_tenant_id, array['manageStaff','manageSettings']
  ) then
    raise exception 'Staff management permission required';
  end if;
  if exists (
    select 1
      from public.staff_members sm
      join public.roles r on r.tenant_id = sm.tenant_id and r.id = sm.role_id
     where sm.tenant_id = v_tenant_id and sm.user_id = p_user_id
       and r.is_system_admin
  ) then
    raise exception 'The owner cannot be suspended or removed';
  end if;
  update public.staff_members
     set status = p_status, updated_at = timezone('utc', now())
   where tenant_id = v_tenant_id and user_id = p_user_id;
  insert into public.audit_logs (
    tenant_id, user_id, action, target_table, record_id, new_data
  ) values (
    v_tenant_id, auth.uid(), 'UPDATE', 'staff_members', p_user_id,
    jsonb_build_object('status', p_status)
  );
end;
$$;

revoke all on function public.set_staff_status(uuid,text) from public, anon, authenticated;
grant execute on function public.set_staff_status(uuid,text) to authenticated;

-- Replace the non-idempotent Phase 1 batch signature with the Phase 2 contract.
drop function if exists public.create_invitations_bulk(uuid, text[], integer);

create or replace function public.create_invitations_bulk(
  p_role_id uuid,
  p_recipient_emails text[],
  p_expires_hours integer default 24,
  p_idempotency_key uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_tenant uuid;
  v_email text;
  v_result jsonb;
  v_results jsonb := '[]'::jsonb;
  v_batch_id uuid;
  v_key uuid := coalesce(p_idempotency_key, gen_random_uuid());
  v_count integer := coalesce(array_length(p_recipient_emails, 1), 0);
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if v_count = 0 or v_count > 100 then
    raise exception 'Bulk invitations are limited to 1 to 100 recipients per batch';
  end if;
  if p_expires_hours is null or p_expires_hours not between 1 and 168 then
    raise exception 'Invitation expiry must be between 1 and 168 hours';
  end if;

  select sm.tenant_id into v_tenant
    from public.staff_members sm
   where sm.user_id = v_user and sm.status = 'active'
   order by sm.created_at
   limit 1;
  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then
    raise exception 'Staff management permission required';
  end if;
  if not exists (
    select 1 from public.roles r
     where r.id = p_role_id and r.tenant_id = v_tenant and not r.is_system_admin
  ) then
    raise exception 'Role does not belong to the current tenant';
  end if;

  select id, result_json into v_batch_id, v_result
    from public.invitation_batches
   where tenant_id = v_tenant and idempotency_key = v_key;
  if found then
    return v_result || jsonb_build_object('batch_id', v_batch_id);
  end if;

  insert into public.invitation_batches (
    tenant_id, created_by, role_id, requested_count, idempotency_key
  ) values (
    v_tenant, v_user, p_role_id, v_count, v_key
  ) returning id into v_batch_id;

  foreach v_email in array p_recipient_emails loop
    begin
      v_result := public.create_invitation(
        p_role_id, v_email, null, null, p_expires_hours
      );
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'email', lower(btrim(v_email)),
        'success', true,
        'code', v_result -> 'code',
        'expires_at', v_result -> 'expires_at'
      ));
    exception when others then
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'email', lower(btrim(v_email)),
        'success', false,
        'error', 'Unable to create invitation'
      ));
    end;
  end loop;

  v_result := jsonb_build_object(
    'batch_id', v_batch_id,
    'requested', v_count,
    'results', v_results
  );
  update public.invitation_batches
     set result_json = v_result
   where id = v_batch_id;
  insert into public.audit_logs (
    tenant_id, user_id, action, target_table, record_id, new_data
  ) values (
    v_tenant, v_user, 'INSERT', 'invitation_batches', v_batch_id, v_result
  );
  return v_result;
end;
$$;

revoke all on function public.create_invitations_bulk(uuid,text[],integer,uuid)
  from public, anon, authenticated;
grant execute on function public.create_invitations_bulk(uuid,text[],integer,uuid)
  to authenticated;
