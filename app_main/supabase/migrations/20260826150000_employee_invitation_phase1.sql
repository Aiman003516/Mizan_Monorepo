-- Phase 1 employee invitations.
-- The legacy invites table/RPC remains available for compatibility. New clients
-- should use the invitation RPCs below after this migration is applied.

alter table if exists public.invites
  add column if not exists recipient_email text,
  add column if not exists recipient_phone text,
  add column if not exists display_name text,
  add column if not exists status text not null default 'pending',
  add column if not exists token_hash text,
  add column if not exists code_hash text,
  add column if not exists revoked_at timestamptz,
  add column if not exists revoked_by uuid references auth.users(id) on delete set null,
  add column if not exists accepted_at timestamptz,
  add column if not exists resend_count integer not null default 0,
  add column if not exists last_sent_at timestamptz;

update public.invites
set status = case
  when is_used then 'accepted'
  when expires_at <= timezone('utc', now()) then 'expired'
  else 'pending'
end
where status is null or status = 'pending';

create index if not exists invites_tenant_status_created_idx
  on public.invites (tenant_id, status, created_at desc, id);
create index if not exists invites_tenant_recipient_email_idx
  on public.invites (tenant_id, lower(recipient_email), created_at desc)
  where recipient_email is not null;
create index if not exists invites_token_hash_idx
  on public.invites (token_hash)
  where token_hash is not null;

create or replace function public.sync_invitation_status()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.is_used then
    new.status := 'accepted';
    new.accepted_at := coalesce(new.accepted_at, new.used_at, timezone('utc', now()));
  elsif new.status = 'accepted' then
    new.status := case
      when new.expires_at <= timezone('utc', now()) then 'expired'
      else 'pending'
    end;
  end if;
  return new;
end;
$$;

drop trigger if exists invites_sync_status on public.invites;
create trigger invites_sync_status
before insert or update on public.invites
for each row execute function public.sync_invitation_status();

create unique index if not exists invites_one_pending_email_idx
  on public.invites (tenant_id, lower(recipient_email))
  where status in ('pending', 'sent') and recipient_email is not null;

create or replace function public.create_invitation(
  p_role_id uuid,
  p_recipient_email text default null,
  p_recipient_phone text default null,
  p_display_name text default null,
  p_expires_hours integer default 24
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_invite public.invites;
  v_code text;
  v_token text;
  v_email text := nullif(lower(btrim(p_recipient_email)), '');
  v_phone text := nullif(btrim(p_recipient_phone), '');
  v_name text := nullif(btrim(p_display_name), '');
  v_expires timestamptz;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_expires_hours is null or p_expires_hours not between 1 and 168 then
    raise exception 'Invitation expiry must be between 1 and 168 hours';
  end if;
  if v_email is null and v_phone is null then
    raise exception 'An email or phone recipient is required';
  end if;
  if v_email is not null and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Recipient email is invalid';
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
  if v_email is not null and exists (
    select 1 from public.staff_members sm
    join public.user_profiles up on up.id = sm.user_id
    where sm.tenant_id = v_tenant and sm.status in ('active','suspended')
      and lower(up.email) = v_email
  ) then
    raise exception 'A staff member with this email already exists';
  end if;

  v_expires := timezone('utc', now()) + make_interval(hours => p_expires_hours);
  loop
    v_code := lpad((floor(random() * 900000) + 100000)::bigint::text, 6, '0');
    exit when not exists (
      select 1 from public.invites i
      where i.code = v_code
    );
  end loop;
  v_token := encode(gen_random_bytes(32), 'hex');

  insert into public.invites (
    tenant_id, role_id, code, created_by, expires_at,
    recipient_email, recipient_phone, display_name, status,
    token_hash, code_hash, last_sent_at
  ) values (
    v_tenant, p_role_id, v_code, v_user, v_expires,
    v_email, v_phone, v_name, 'sent',
    encode(digest(v_token, 'sha256'), 'hex'),
    encode(digest(v_code, 'sha256'), 'hex'),
    timezone('utc', now())
  ) returning * into v_invite;

  return jsonb_build_object(
    'id', v_invite.id,
    'code', v_code,
    'token', v_token,
    'tenant_id', v_tenant,
    'role_id', p_role_id,
    'recipient_email', v_email,
    'expires_at', v_expires
  );
end;
$$;

create or replace function public.validate_invitation(p_token text default null, p_code text default null)
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
    where i.token_hash = v_hash and i.status in ('pending','sent')
      and i.expires_at > timezone('utc', now());
  elsif p_code ~ '^[0-9]{6}$' then
    select * into v_invite from public.invites i
    where i.code = p_code and i.status in ('pending','sent')
      and i.expires_at > timezone('utc', now());
  end if;

  if not found then return null; end if;
  select r.name into v_role_name from public.roles r
    where r.id = v_invite.role_id and r.tenant_id = v_invite.tenant_id;
  select t.name into v_tenant_name from public.tenants t where t.id = v_invite.tenant_id;

  return jsonb_build_object(
    'id', v_invite.id,
    'tenant_id', v_invite.tenant_id,
    'tenant_name', v_tenant_name,
    'role_id', v_invite.role_id,
    'role_name', v_role_name,
    'display_name', v_invite.display_name,
    'expires_at', v_invite.expires_at
  );
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
  v_user uuid := (select auth.uid());
  v_email text;
  v_invite public.invites;
  v_profile public.user_profiles;
  v_hash text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if nullif(btrim(p_token), '') is not null then
    v_hash := encode(digest(btrim(p_token), 'sha256'), 'hex');
    select * into v_invite from public.invites i
      where i.token_hash = v_hash and i.status in ('pending','sent')
        and i.expires_at > timezone('utc', now()) for update;
  elsif p_code ~ '^[0-9]{6}$' then
    select * into v_invite from public.invites i
      where i.code = p_code and i.status in ('pending','sent')
        and i.expires_at > timezone('utc', now()) for update;
  end if;
  if not found then raise exception 'Invitation is invalid or expired'; end if;

  select lower(email) into v_email from auth.users where id = v_user;
  if v_invite.recipient_email is not null
     and (v_email is null or v_email <> lower(v_invite.recipient_email)) then
    raise exception 'This invitation is assigned to a different email address';
  end if;
  if exists (
    select 1 from public.staff_members sm
    where sm.user_id = v_user and sm.tenant_id <> v_invite.tenant_id
      and sm.status = 'active'
  ) then
    raise exception 'The user already belongs to another active business';
  end if;

  insert into public.user_profiles (id, tenant_id, email, display_name)
  values (
    v_user, v_invite.tenant_id, v_email,
    coalesce(nullif(btrim(p_display_name), ''), v_invite.display_name, v_email)
  )
  on conflict (id) do update set
    tenant_id = excluded.tenant_id,
    email = coalesce(excluded.email, user_profiles.email),
    display_name = coalesce(excluded.display_name, user_profiles.display_name);

  insert into public.staff_members (tenant_id, user_id, role_id, status)
  values (v_invite.tenant_id, v_user, v_invite.role_id, 'active')
  on conflict (tenant_id, user_id) do update set
    role_id = excluded.role_id,
    status = 'active',
    updated_at = timezone('utc', now());

  update public.invites set
    status = 'accepted', is_used = true, used_by = v_user,
    used_at = timezone('utc', now()), accepted_at = timezone('utc', now())
  where id = v_invite.id;

  return jsonb_build_object(
    'tenant_id', v_invite.tenant_id,
    'role_id', v_invite.role_id,
    'invitation_id', v_invite.id
  );
end;
$$;

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
end;
$$;

create or replace function public.create_invitations_bulk(
  p_role_id uuid,
  p_recipient_emails text[],
  p_expires_hours integer default 24
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_result jsonb;
  v_results jsonb := '[]'::jsonb;
  v_count integer := coalesce(array_length(p_recipient_emails, 1), 0);
begin
  if v_count = 0 then
    raise exception 'At least one recipient email is required';
  end if;
  if v_count > 100 then
    raise exception 'Bulk invitations are limited to 100 recipients per batch';
  end if;
  foreach v_email in array p_recipient_emails loop
    begin
      v_result := public.create_invitation(
        p_role_id,
        v_email,
        null,
        null,
        p_expires_hours
      );
      v_results := v_results || jsonb_build_array(
        jsonb_build_object(
          'email', lower(btrim(v_email)),
          'success', true,
          'code', v_result -> 'code',
          'expires_at', v_result -> 'expires_at'
        )
      );
    exception when others then
      v_results := v_results || jsonb_build_array(
        jsonb_build_object(
          'email', lower(btrim(v_email)),
          'success', false,
          'error', 'Unable to create invitation'
        )
      );
    end;
  end loop;
  return jsonb_build_object(
    'requested', v_count,
    'results', v_results
  );
end;
$$;

create or replace function public.revoke_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
begin
  select i.tenant_id into v_tenant from public.invites i where i.id = p_invitation_id;
  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then
    raise exception 'Staff management permission required';
  end if;
  update public.invites set status = 'revoked', revoked_at = timezone('utc', now()), revoked_by = v_user
  where id = p_invitation_id and status in ('pending','sent');
end;
$$;

revoke all on function public.create_invitation(uuid,text,text,text,integer) from public, anon, authenticated;
revoke all on function public.set_staff_status(uuid,text) from public, anon, authenticated;
revoke all on function public.validate_invitation(text,text) from public, anon, authenticated;
revoke all on function public.redeem_invitation(text,text,text) from public, anon, authenticated;
revoke all on function public.create_invitations_bulk(uuid,text[],integer) from public, anon, authenticated;
revoke all on function public.revoke_invitation(uuid) from public, anon, authenticated;
grant execute on function public.create_invitation(uuid,text,text,text,integer) to authenticated;
grant execute on function public.set_staff_status(uuid,text) to authenticated;
grant execute on function public.validate_invitation(text,text) to anon, authenticated;
grant execute on function public.redeem_invitation(text,text,text) to authenticated;
grant execute on function public.create_invitations_bulk(uuid,text[],integer) to authenticated;
grant execute on function public.revoke_invitation(uuid) to authenticated;
