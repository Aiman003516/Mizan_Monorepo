-- Mizan Owner Control Center Phase 1
-- This migration is additive and must be reviewed/applied through the normal
-- Supabase deployment process. It does not grant anonymous access and does not
-- allow settings to bypass accounting or tenant authorization.

create table if not exists public.tenant_settings (
  tenant_id uuid primary key references public.tenants(id) on delete cascade,
  schema_version text not null check (schema_version = 'mizan.owner-settings/v1'),
  revision bigint not null default 0 check (revision >= 0),
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists tenant_settings_updated_idx
  on public.tenant_settings (updated_at desc, tenant_id);

create table if not exists public.approval_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete restrict,
  request_type text not null check (request_type in (
    'expense', 'invoice', 'bill', 'journal', 'balance_adjustment',
    'refund', 'discount', 'period_reopen'
  )),
  target_id uuid,
  payload jsonb not null default '{}'::jsonb check (jsonb_typeof(payload) = 'object'),
  amount_minor bigint not null default 0 check (amount_minor >= 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  reason text not null check (length(btrim(reason)) between 1 and 1000),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  decided_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  decided_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  check ((status = 'pending' and decided_at is null and decided_by is null)
      or (status <> 'pending' and decided_at is not null and decided_by is not null))
);

create index if not exists approval_requests_tenant_status_idx
  on public.approval_requests (tenant_id, status, created_at desc, id);
create index if not exists approval_requests_requester_idx
  on public.approval_requests (tenant_id, requester_id, created_at desc, id);

alter table public.tenant_settings enable row level security;
alter table public.approval_requests enable row level security;
revoke all on table public.tenant_settings from anon, authenticated;
revoke all on table public.approval_requests from anon, authenticated;
grant select, insert, update on public.tenant_settings to authenticated;
grant select, insert, update on public.approval_requests to authenticated;

create or replace function public.prevent_owner_settings_schema_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and new.schema_version is distinct from old.schema_version then
    raise exception 'Owner settings schema version cannot be changed';
  end if;
  if new.revision < old.revision then
    raise exception 'Owner settings revision cannot move backwards';
  end if;
  return new;
end;
$$;

drop trigger if exists tenant_settings_immutable_schema on public.tenant_settings;
create trigger tenant_settings_immutable_schema
before update on public.tenant_settings
for each row execute function public.prevent_owner_settings_schema_change();

drop trigger if exists tenant_settings_updated_at on public.tenant_settings;
create trigger tenant_settings_updated_at
before update on public.tenant_settings
for each row execute function public.set_updated_at();

drop trigger if exists approval_requests_updated_at on public.approval_requests;
create trigger approval_requests_updated_at
before update on public.approval_requests
for each row execute function public.set_updated_at();

create or replace function public.audit_owner_control_center_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.audit_logs (
      tenant_id, user_id, action, target_table, record_id, old_data, new_data
    ) values (
      new.tenant_id,
      (select auth.uid()),
      'INSERT',
      tg_table_name,
      new.tenant_id,
      null,
      jsonb_build_object('revision', new.revision, 'sections', (
        select coalesce(jsonb_agg(section_name order by section_name), '[]'::jsonb)
        from jsonb_object_keys(new.settings) as section_name
      ))
    );
    return new;
  elsif tg_op = 'DELETE' then
    insert into public.audit_logs (
      tenant_id, user_id, action, target_table, record_id, old_data, new_data
    ) values (
      old.tenant_id,
      (select auth.uid()),
      'DELETE',
      tg_table_name,
      old.tenant_id,
      jsonb_build_object('revision', old.revision),
      null
    );
    return old;
  else
    insert into public.audit_logs (
      tenant_id, user_id, action, target_table, record_id, old_data, new_data
    ) values (
      new.tenant_id,
      (select auth.uid()),
      'UPDATE',
      tg_table_name,
      new.tenant_id,
      jsonb_build_object('revision', old.revision),
      jsonb_build_object('revision', new.revision, 'sections', (
        select coalesce(jsonb_agg(section_name order by section_name), '[]'::jsonb)
        from jsonb_object_keys(new.settings) as section_name
      ))
    );
    return new;
  end if;
end;
$$;

drop trigger if exists tenant_settings_audit on public.tenant_settings;
create trigger tenant_settings_audit
after insert or update or delete on public.tenant_settings
for each row execute function public.audit_owner_control_center_change();

create or replace function public.audit_approval_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    insert into public.audit_logs (
      tenant_id, user_id, action, target_table, record_id, old_data, new_data
    ) values (
      new.tenant_id,
      coalesce(new.decided_by, (select auth.uid())),
      'UPDATE',
      'approval_requests',
      new.id,
      jsonb_build_object('status', old.status, 'request_type', old.request_type),
      jsonb_build_object('status', new.status, 'request_type', new.request_type)
    );
  end if;
  return new;
end;
$$;

drop trigger if exists approval_requests_decision_audit on public.approval_requests;
create trigger approval_requests_decision_audit
after update on public.approval_requests
for each row execute function public.audit_approval_decision();

create policy tenant_settings_select on public.tenant_settings
for select to authenticated
using (public.is_tenant_member(tenant_id));

create policy tenant_settings_insert on public.tenant_settings
for insert to authenticated
with check (
  public.has_tenant_permission(tenant_id, array['manageSettings'])
  and updated_by = (select auth.uid())
);

create policy tenant_settings_update on public.tenant_settings
for update to authenticated
using (public.has_tenant_permission(tenant_id, array['manageSettings']))
with check (
  public.has_tenant_permission(tenant_id, array['manageSettings'])
  and updated_by = (select auth.uid())
);

create policy approval_requests_select on public.approval_requests
for select to authenticated
using (
  requester_id = (select auth.uid())
  or public.has_tenant_permission(tenant_id, array['manageSettings'])
);

create policy approval_requests_insert on public.approval_requests
for insert to authenticated
with check (
  requester_id = (select auth.uid())
  and public.is_tenant_member(tenant_id)
  and status = 'pending'
);

create policy approval_requests_update on public.approval_requests
for update to authenticated
using (public.has_tenant_permission(tenant_id, array['manageSettings']))
with check (
  public.has_tenant_permission(tenant_id, array['manageSettings'])
  and decided_by = (select auth.uid())
);
