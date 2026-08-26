-- Phase 3 employee invitation repair and onboarding contract.
-- This migration is intentionally additive and must be applied explicitly by the owner.
-- It does not send email/SMS. delivery_channel records an intent only.

alter table if exists public.invites
  add column if not exists delivery_channel text not null default 'manual',
  add column if not exists normalized_phone text;

update public.invites
   set normalized_phone = nullif(regexp_replace(coalesce(recipient_phone, ''), '[^0-9+]', '', 'g'), '')
 where normalized_phone is null and recipient_phone is not null;

create index if not exists invites_tenant_contact_status_idx
  on public.invites (tenant_id, lower(recipient_email), normalized_phone, status, created_at desc);

create or replace function public.create_invitation_with_delivery(
  p_role_id uuid,
  p_recipient_email text default null,
  p_recipient_phone text default null,
  p_display_name text default null,
  p_delivery_channel text default 'manual',
  p_expires_hours integer default 24
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
  v_channel text := lower(coalesce(nullif(btrim(p_delivery_channel), ''), 'manual'));
  v_id uuid;
begin
  if v_channel not in ('manual', 'email', 'sms') then
    raise exception 'Invalid delivery channel';
  end if;
  if v_channel = 'email' and nullif(btrim(p_recipient_email), '') is null then
    raise exception 'Email delivery requires an email recipient';
  end if;
  if v_channel = 'sms' and nullif(btrim(p_recipient_phone), '') is null then
    raise exception 'SMS delivery requires a phone recipient';
  end if;

  v_result := public.create_invitation(
    p_role_id,
    p_recipient_email,
    p_recipient_phone,
    p_display_name,
    p_expires_hours
  );
  v_id := (v_result ->> 'id')::uuid;
  update public.invites
     set delivery_channel = v_channel,
         normalized_phone = nullif(regexp_replace(coalesce(recipient_phone, ''), '[^0-9+]', '', 'g'), '')
   where id = v_id;
  return v_result || jsonb_build_object('delivery_channel', v_channel);
end;
$$;

create or replace function public.create_invitations_bulk_recipients(
  p_role_id uuid,
  p_recipients jsonb,
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
  v_key uuid := coalesce(p_idempotency_key, gen_random_uuid());
  v_batch_id uuid;
  v_existing jsonb;
  v_recipient jsonb;
  v_result jsonb;
  v_results jsonb := '[]'::jsonb;
  v_email text;
  v_phone text;
  v_name text;
  v_channel text;
  v_count integer := jsonb_array_length(coalesce(p_recipients, '[]'::jsonb));
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_recipients) <> 'array' or v_count < 1 or v_count > 100 then
    raise exception 'Bulk invitations are limited to 1 to 100 recipients per batch';
  end if;
  if p_expires_hours is null or p_expires_hours not between 1 and 168 then
    raise exception 'Invitation expiry must be between 1 and 168 hours';
  end if;

  select sm.tenant_id into v_tenant
    from public.staff_members sm
   where sm.user_id = v_user and sm.status = 'active'
   order by sm.created_at limit 1;
  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then
    raise exception 'Staff management permission required';
  end if;
  if not exists (
    select 1 from public.roles r
     where r.id = p_role_id and r.tenant_id = v_tenant and not r.is_system_admin
  ) then
    raise exception 'Role does not belong to the current tenant';
  end if;

  select id, result_json into v_batch_id, v_existing
    from public.invitation_batches
   where tenant_id = v_tenant and idempotency_key = v_key;
  if found then return v_existing || jsonb_build_object('batch_id', v_batch_id); end if;

  insert into public.invitation_batches (tenant_id, created_by, role_id, requested_count, idempotency_key)
  values (v_tenant, v_user, p_role_id, v_count, v_key)
  returning id into v_batch_id;

  for v_recipient in select value from jsonb_array_elements(p_recipients) loop
    v_email := nullif(lower(btrim(v_recipient ->> 'email')), '');
    v_phone := nullif(btrim(v_recipient ->> 'phone'), '');
    v_name := nullif(btrim(v_recipient ->> 'display_name'), '');
    v_channel := lower(coalesce(nullif(btrim(v_recipient ->> 'delivery_channel'), ''), 'manual'));
    begin
      if v_email is null and v_phone is null then raise exception 'An email or phone recipient is required'; end if;
      v_result := public.create_invitation_with_delivery(
        p_role_id, v_email, v_phone, v_name, v_channel, p_expires_hours
      );
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'email', v_email,
        'phone', v_phone,
        'display_name', v_name,
        'delivery_channel', v_channel,
        'success', true,
        'id', v_result -> 'id',
        'code', v_result -> 'code',
        'expires_at', v_result -> 'expires_at'
      ));
    exception when others then
      v_results := v_results || jsonb_build_array(jsonb_build_object(
        'email', v_email,
        'phone', v_phone,
        'display_name', v_name,
        'delivery_channel', v_channel,
        'success', false,
        'error', 'Unable to create invitation for this recipient'
      ));
    end;
  end loop;

  v_result := jsonb_build_object('batch_id', v_batch_id, 'requested', v_count, 'results', v_results);
  update public.invitation_batches set result_json = v_result where id = v_batch_id;
  insert into public.audit_logs (tenant_id, user_id, action, target_table, record_id, new_data)
  values (v_tenant, v_user, 'INSERT', 'invitation_batches', v_batch_id, v_result);
  return v_result;
end;
$$;

-- Replace the validation contract with an optional recipient-email binding check.
drop function if exists public.validate_invitation(text, text);
create function public.validate_invitation(
  p_token text default null,
  p_code text default null,
  p_recipient_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.invites;
  v_role_name text;
  v_tenant_name text;
  v_hash text;
begin
  if nullif(btrim(p_token), '') is not null then
    v_hash := encode(digest(btrim(p_token), 'sha256'), 'hex');
    select * into v_invite from public.invites i
     where i.token_hash = v_hash and i.status in ('pending','sent') and i.expires_at > timezone('utc', now());
  elsif p_code ~ '^[0-9]{6}$' then
    select * into v_invite from public.invites i
     where i.code = btrim(p_code) and i.status in ('pending','sent') and i.expires_at > timezone('utc', now());
  end if;
  if not found then return null; end if;
  if nullif(lower(btrim(p_recipient_email)), '') is not null
     and v_invite.recipient_email is not null
     and lower(v_invite.recipient_email) <> lower(btrim(p_recipient_email)) then
    raise exception 'This invitation is assigned to a different email address';
  end if;
  select r.name into v_role_name from public.roles r where r.id = v_invite.role_id and r.tenant_id = v_invite.tenant_id;
  select t.name into v_tenant_name from public.tenants t where t.id = v_invite.tenant_id;
  return jsonb_build_object(
    'id', v_invite.id,
    'tenant_id', v_invite.tenant_id,
    'tenant_name', v_tenant_name,
    'role_id', v_invite.role_id,
    'role_name', v_role_name,
    'display_name', v_invite.display_name,
    'recipient_email', v_invite.recipient_email,
    'recipient_phone', v_invite.recipient_phone,
    'expires_at', v_invite.expires_at
  );
end;
$$;

create or replace function public.list_invitations()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant uuid;
  v_rows jsonb;
begin
  select sm.tenant_id into v_tenant from public.staff_members sm
   where sm.user_id = auth.uid() and sm.status = 'active' order by sm.created_at limit 1;
  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then
    raise exception 'Staff management permission required';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id,
    'display_name', i.display_name,
    'recipient_email', i.recipient_email,
    'recipient_phone', i.recipient_phone,
    'role_id', i.role_id,
    'role_name', r.name,
    'status', case when i.status in ('pending','sent') and i.expires_at <= timezone('utc', now()) then 'expired' else i.status end,
    'delivery_channel', coalesce(i.delivery_channel, 'manual'),
    'expires_at', i.expires_at,
    'created_at', i.created_at,
    'resend_count', i.resend_count
  ) order by i.created_at desc), '[]'::jsonb)
    into v_rows
    from public.invites i join public.roles r on r.id = i.role_id and r.tenant_id = i.tenant_id
   where i.tenant_id = v_tenant;
  return v_rows;
end;
$$;

create or replace function public.resend_invitation(
  p_invitation_id uuid,
  p_expires_hours integer default 24
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_tenant uuid;
  v_invite public.invites;
  v_code text;
  v_token text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_expires_hours is null or p_expires_hours not between 1 and 168 then raise exception 'Invitation expiry must be between 1 and 168 hours'; end if;
  select * into v_invite from public.invites where id = p_invitation_id for update;
  if not found then raise exception 'Invitation not found'; end if;
  v_tenant := v_invite.tenant_id;
  if not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then raise exception 'Staff management permission required'; end if;
  loop
    v_code := lpad((floor(random() * 900000) + 100000)::bigint::text, 6, '0');
    exit when not exists (select 1 from public.invites where code = v_code and id <> v_invite.id);
  end loop;
  v_token := encode(gen_random_bytes(32), 'hex');
  update public.invites set
    code = v_code,
    code_hash = encode(digest(v_code, 'sha256'), 'hex'),
    token_hash = encode(digest(v_token, 'sha256'), 'hex'),
    expires_at = timezone('utc', now()) + make_interval(hours => p_expires_hours),
    status = 'sent',
    is_used = false,
    used_by = null,
    used_at = null,
    revoked_at = null,
    revoked_by = null,
    last_sent_at = timezone('utc', now()),
    resend_count = coalesce(resend_count, 0) + 1
   where id = v_invite.id;
  insert into public.audit_logs (tenant_id, user_id, action, target_table, record_id, new_data)
  values (v_tenant, v_user, 'UPDATE', 'invites', v_invite.id,
          jsonb_build_object('event', 'resend', 'delivery_channel', coalesce(v_invite.delivery_channel, 'manual')));
  return jsonb_build_object('id', v_invite.id, 'code', v_code, 'token', v_token, 'expires_at', timezone('utc', now()) + make_interval(hours => p_expires_hours));
end;
$$;

create or replace function public.redeem_invitation(
  p_token text default null,
  p_code text default null,
  p_display_name text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_invite public.invites;
  v_email text;
  v_phone text;
  v_hash text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if nullif(btrim(p_token), '') is not null then
    v_hash := encode(digest(btrim(p_token), 'sha256'), 'hex');
    select * into v_invite from public.invites where token_hash = v_hash and status in ('pending','sent') and expires_at > timezone('utc', now()) for update;
  elsif p_code ~ '^[0-9]{6}$' then
    select * into v_invite from public.invites where code = btrim(p_code) and status in ('pending','sent') and expires_at > timezone('utc', now()) for update;
  end if;
  if not found then raise exception 'Invitation is invalid or expired'; end if;
  select lower(email), nullif(phone, '') into v_email, v_phone from auth.users where id = v_user;
  if v_invite.recipient_email is not null and (v_email is null or v_email <> lower(v_invite.recipient_email)) then
    raise exception 'This invitation is assigned to a different email address';
  end if;
  if v_invite.recipient_email is null and v_invite.recipient_phone is not null and (v_phone is null or regexp_replace(v_phone, '[^0-9+]', '', 'g') <> regexp_replace(v_invite.recipient_phone, '[^0-9+]', '', 'g')) then
    raise exception 'This invitation is assigned to a different phone number';
  end if;
  if exists (select 1 from public.staff_members where user_id = v_user and tenant_id <> v_invite.tenant_id and status = 'active') then
    raise exception 'The user already belongs to another active business';
  end if;
  insert into public.user_profiles (id, tenant_id, email, display_name)
  values (v_user, v_invite.tenant_id, v_email, coalesce(nullif(btrim(p_display_name), ''), v_invite.display_name, v_email, v_phone))
  on conflict (id) do update set tenant_id = excluded.tenant_id, email = coalesce(excluded.email, user_profiles.email), display_name = coalesce(excluded.display_name, user_profiles.display_name);
  insert into public.staff_members (tenant_id, user_id, role_id, status)
  values (v_invite.tenant_id, v_user, v_invite.role_id, 'active')
  on conflict (tenant_id, user_id) do update set role_id = excluded.role_id, status = 'active', updated_at = timezone('utc', now());
  update public.invites set status = 'accepted', is_used = true, used_by = v_user, used_at = timezone('utc', now()), accepted_at = timezone('utc', now()) where id = v_invite.id;
  insert into public.audit_logs (tenant_id, user_id, action, target_table, record_id, new_data)
  values (v_invite.tenant_id, v_user, 'UPDATE', 'invites', v_invite.id, jsonb_build_object('event', 'accepted'));
  return jsonb_build_object('tenant_id', v_invite.tenant_id, 'role_id', v_invite.role_id, 'invitation_id', v_invite.id);
end;
$$;

revoke all on function public.create_invitation_with_delivery(uuid,text,text,text,text,integer) from public, anon, authenticated;
revoke all on function public.create_invitations_bulk_recipients(uuid,jsonb,integer,uuid) from public, anon, authenticated;
revoke all on function public.validate_invitation(text,text,text) from public, anon, authenticated;
revoke all on function public.list_invitations() from public, anon, authenticated;
revoke all on function public.resend_invitation(uuid,integer) from public, anon, authenticated;
grant execute on function public.create_invitation_with_delivery(uuid,text,text,text,text,integer) to authenticated;
grant execute on function public.create_invitations_bulk_recipients(uuid,jsonb,integer,uuid) to authenticated;
grant execute on function public.validate_invitation(text,text,text) to anon, authenticated;
grant execute on function public.list_invitations() to authenticated;
grant execute on function public.resend_invitation(uuid,integer) to authenticated;
grant execute on function public.redeem_invitation(text,text,text) to authenticated;
