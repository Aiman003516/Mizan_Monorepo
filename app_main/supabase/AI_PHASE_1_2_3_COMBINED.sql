-- Mizan AI combined deployment script.
-- Run this complete file once in the Supabase SQL Editor for project ref eawkctancunjpatujzpu.
-- It preserves migration order: Phase 1, Phase 2, Phase 3.
-- Do not run this file if any of these three migrations were already partially applied; inspect the exact prior error first.

-- ===== BEGIN 20260827100000_ai_agent_phase1.sql =====
-- Mizan AI Agent Phase 1.
-- Conversations and audit events are accessed through the server-side Edge Function.
-- Direct client table access remains revoked; service_role is used only inside the function.

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  locale text not null default 'en' check (locale in ('en', 'ar')),
  title text check (title is null or length(btrim(title)) between 1 and 160),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, user_id, id)
);

create index if not exists ai_conversations_user_updated_idx
  on public.ai_conversations (tenant_id, user_id, updated_at desc, id);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (length(content) between 1 and 16000),
  model text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists ai_messages_conversation_created_idx
  on public.ai_messages (conversation_id, created_at asc, id);
create index if not exists ai_messages_tenant_user_created_idx
  on public.ai_messages (tenant_id, user_id, created_at desc, id);

create table if not exists public.ai_audit_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid references public.ai_conversations(id) on delete set null,
  event_type text not null check (event_type in ('request', 'tool_call', 'response', 'error')),
  tool_name text,
  success boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists ai_audit_events_tenant_created_idx
  on public.ai_audit_events (tenant_id, created_at desc, id);
create index if not exists ai_audit_events_request_idx
  on public.ai_audit_events (request_id, created_at, id);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_audit_events enable row level security;

-- The Edge Function is the only application entry point. No Flutter client can
-- directly read, insert, update, or delete AI records with its publishable key.
revoke all on public.ai_conversations from anon, authenticated;
revoke all on public.ai_messages from anon, authenticated;
revoke all on public.ai_audit_events from anon, authenticated;
grant all on public.ai_conversations to service_role;
grant all on public.ai_messages to service_role;
grant all on public.ai_audit_events to service_role;

create or replace function public.touch_ai_conversation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

revoke all on function public.touch_ai_conversation() from public, anon, authenticated;
drop trigger if exists ai_conversations_touch_updated_at on public.ai_conversations;
create trigger ai_conversations_touch_updated_at
before update on public.ai_conversations
for each row execute function public.touch_ai_conversation();
-- ===== END 20260827100000_ai_agent_phase1.sql =====
-- ===== BEGIN 20260827110000_ai_action_requests_phase2.sql =====
-- Mizan AI action requests Phase 2.
-- This stores previews only. No action is executed by this migration.

create table if not exists public.ai_action_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid references public.ai_conversations(id) on delete set null,
  action_type text not null check (action_type in (
    'invoice_draft',
    'bill_draft',
    'customer_draft',
    'vendor_draft',
    'journal_entry_draft',
    'staff_invitation_batch_draft'
  )),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  preview jsonb not null check (jsonb_typeof(preview) = 'object'),
  status text not null default 'pending' check (status in (
    'pending', 'cancelled', 'expired', 'confirmed', 'executed', 'failed'
  )),
  idempotency_key uuid not null,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null default timezone('utc', now()) + interval '15 minutes',
  confirmed_at timestamptz,
  executed_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, user_id, idempotency_key)
);

create index if not exists ai_action_requests_user_status_idx
  on public.ai_action_requests (tenant_id, user_id, status, created_at desc, id);
create index if not exists ai_action_requests_expiry_idx
  on public.ai_action_requests (status, expires_at);

alter table public.ai_action_requests enable row level security;
revoke all on public.ai_action_requests from anon, authenticated;
grant all on public.ai_action_requests to service_role;

create or replace function public.touch_ai_action_request()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

revoke all on function public.touch_ai_action_request() from public, anon, authenticated;
drop trigger if exists ai_action_requests_touch_updated_at on public.ai_action_requests;
create trigger ai_action_requests_touch_updated_at
before update on public.ai_action_requests
for each row execute function public.touch_ai_action_request();
-- ===== END 20260827110000_ai_action_requests_phase2.sql =====
-- ===== BEGIN 20260827130000_ai_action_execution_phase3.sql =====
-- Mizan AI action execution Phase 3.
-- Confirmation is one-time, tenant-scoped, permission-revalidated, audited, and idempotent.
-- Guest sessions never reach this function because auth.uid() is mandatory.

alter table public.ai_action_requests
  add column if not exists confirmation_token uuid,
  add column if not exists execution_result jsonb,
  add column if not exists execution_error text;

update public.ai_action_requests
   set confirmation_token = gen_random_uuid()
 where confirmation_token is null;

alter table public.ai_action_requests
  alter column confirmation_token set default gen_random_uuid(),
  alter column confirmation_token set not null;

create unique index if not exists ai_action_requests_confirmation_token_idx
  on public.ai_action_requests (confirmation_token);

create or replace function public.create_customer_for_tenant(
  p_tenant_id uuid,
  p_name text,
  p_email text default null,
  p_phone text default null,
  p_address text default null,
  p_tax_id text default null,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_customer public.customers;
  v_email text := nullif(lower(btrim(p_email)), '');
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select sm.tenant_id into v_tenant
    from public.staff_members sm
   where sm.user_id = v_user and sm.status = 'active'
     and sm.tenant_id = p_tenant_id
   order by sm.created_at limit 1;
  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageCrm','manageCustomers','manageSettings']) then
    raise exception 'Customer creation permission required';
  end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 200 then
    raise exception 'Customer name is invalid';
  end if;
  if v_email is not null and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Email is invalid';
  end if;
  insert into public.customers (
    tenant_id, name, email, phone, address, tax_id, notes, created_by
  ) values (
    v_tenant, btrim(p_name), v_email, nullif(btrim(p_phone), ''),
    nullif(btrim(p_address), ''), nullif(btrim(p_tax_id), ''),
    nullif(btrim(p_notes), ''), v_user
  ) returning * into v_customer;
  return to_jsonb(v_customer);
end;
$$;

create or replace function public.create_vendor_for_tenant(
  p_tenant_id uuid,
  p_name text,
  p_email text default null,
  p_phone text default null,
  p_address text default null,
  p_tax_id text default null,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_vendor public.vendors;
  v_email text := nullif(lower(btrim(p_email)), '');
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  select sm.tenant_id into v_tenant
    from public.staff_members sm
   where sm.user_id = v_user and sm.status = 'active'
     and sm.tenant_id = p_tenant_id
   order by sm.created_at limit 1;
  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageCrm','manageVendors','manageSettings']) then
    raise exception 'Vendor creation permission required';
  end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 200 then
    raise exception 'Vendor name is invalid';
  end if;
  if v_email is not null and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    raise exception 'Email is invalid';
  end if;
  insert into public.vendors (
    tenant_id, name, email, phone, address, tax_id, notes, created_by
  ) values (
    v_tenant, btrim(p_name), v_email, nullif(btrim(p_phone), ''),
    nullif(btrim(p_address), ''), nullif(btrim(p_tax_id), ''),
    nullif(btrim(p_notes), ''), v_user
  ) returning * into v_vendor;
  return to_jsonb(v_vendor);
end;
$$;

revoke all on function public.create_customer_for_tenant(uuid,text,text,text,text,text,text) from public, anon, authenticated;
revoke all on function public.create_vendor_for_tenant(uuid,text,text,text,text,text,text) from public, anon, authenticated;
grant execute on function public.create_customer_for_tenant(uuid,text,text,text,text,text,text) to authenticated;
grant execute on function public.create_vendor_for_tenant(uuid,text,text,text,text,text,text) to authenticated;

create or replace function public.execute_ai_action(
  p_action_request_id uuid,
  p_confirmation_token uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_request public.ai_action_requests;
  v_tenant uuid;
  v_result jsonb;
  v_payload jsonb;
  v_item jsonb;
  v_party_id uuid;
  v_name text;
  v_email text;
  v_phone text;
  v_address text;
  v_tax_id text;
  v_notes text;
  v_role_id uuid;
  v_recipients text[];
  v_execution_summary jsonb;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_action_request_id is null or p_confirmation_token is null then
    raise exception 'Confirmation is required';
  end if;

  select * into v_request
    from public.ai_action_requests
   where id = p_action_request_id
   for update;
  if not found or v_request.user_id <> v_user then
    raise exception 'Action request is unavailable';
  end if;
  if v_request.confirmation_token <> p_confirmation_token then
    raise exception 'Confirmation token is invalid';
  end if;

  -- Repeated delivery after a committed execution is safe and returns the same result.
  if v_request.status = 'executed' then
    return jsonb_build_object(
      'status', v_request.status,
      'action_type', v_request.action_type,
      'result', coalesce(v_request.execution_result, '{}'::jsonb)
    );
  end if;
  if v_request.status <> 'pending' then
    raise exception 'Action request is no longer pending';
  end if;
  if v_request.expires_at <= timezone('utc', now()) then
    update public.ai_action_requests
       set status = 'expired', execution_error = 'Action request expired'
     where id = v_request.id;
    raise exception 'Action request is expired';
  end if;

  v_tenant := v_request.tenant_id;
  if not exists (
    select 1 from public.staff_members sm
     where sm.tenant_id = v_tenant and sm.user_id = v_user and sm.status = 'active'
  ) then
    raise exception 'Active tenant membership required';
  end if;
  v_payload := v_request.payload;

  begin
    if v_request.action_type = 'invoice_draft' then
      if not public.has_tenant_permission(v_tenant, array['manageCrm','createInvoices','manageInvoices','manageSettings']) then
        raise exception 'Invoice creation permission required';
      end if;
      v_result := public.create_invoice(
        (v_payload->>'customer_id')::uuid,
        (v_payload->>'invoice_date')::date,
        (v_payload->>'due_date')::date,
        v_payload->>'currency_code',
        nullif(v_payload->>'notes', ''),
        coalesce(v_payload->'items', '[]'::jsonb)
      );
      v_execution_summary := jsonb_build_object(
        'record_type', 'invoice',
        'record_id', v_result->'invoice'->>'id'
      );
    elsif v_request.action_type = 'bill_draft' then
      if not public.has_tenant_permission(v_tenant, array['manageCrm','createBills','manageBills','manageSettings']) then
        raise exception 'Bill creation permission required';
      end if;
      v_result := public.create_bill(
        (v_payload->>'vendor_id')::uuid,
        (v_payload->>'bill_date')::date,
        (v_payload->>'due_date')::date,
        v_payload->>'currency_code',
        nullif(v_payload->>'vendor_bill_number', ''),
        nullif(v_payload->>'notes', ''),
        coalesce(v_payload->'items', '[]'::jsonb)
      );
      v_execution_summary := jsonb_build_object(
        'record_type', 'bill',
        'record_id', v_result->'bill'->>'id'
      );
    elsif v_request.action_type = 'customer_draft' then
      if not public.has_tenant_permission(v_tenant, array['manageCrm','manageCustomers','manageSettings']) then
        raise exception 'Customer creation permission required';
      end if;
      v_name := nullif(btrim(v_payload->>'name'), '');
      v_email := nullif(lower(btrim(v_payload->>'email')), '');
      v_phone := nullif(btrim(v_payload->>'phone'), '');
      v_address := nullif(btrim(v_payload->>'address'), '');
      v_tax_id := nullif(btrim(v_payload->>'tax_id'), '');
      v_notes := nullif(btrim(v_payload->>'notes'), '');
      v_result := public.create_customer_for_tenant(
        v_tenant, v_name, v_email, v_phone, v_address, v_tax_id, v_notes
      );
      v_execution_summary := jsonb_build_object(
        'record_type', 'customer',
        'record_id', v_result->>'id'
      );
    elsif v_request.action_type = 'vendor_draft' then
      if not public.has_tenant_permission(v_tenant, array['manageCrm','manageVendors','manageSettings']) then
        raise exception 'Vendor creation permission required';
      end if;
      v_name := nullif(btrim(v_payload->>'name'), '');
      v_email := nullif(lower(btrim(v_payload->>'email')), '');
      v_phone := nullif(btrim(v_payload->>'phone'), '');
      v_address := nullif(btrim(v_payload->>'address'), '');
      v_tax_id := nullif(btrim(v_payload->>'tax_id'), '');
      v_notes := nullif(btrim(v_payload->>'notes'), '');
      v_result := public.create_vendor_for_tenant(
        v_tenant, v_name, v_email, v_phone, v_address, v_tax_id, v_notes
      );
      v_execution_summary := jsonb_build_object(
        'record_type', 'vendor',
        'record_id', v_result->>'id'
      );
    elsif v_request.action_type = 'staff_invitation_batch_draft' then
      if not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then
        raise exception 'Staff management permission required';
      end if;
      v_role_id := (v_payload->>'role_id')::uuid;
      select array_agg(value::text order by ordinality)
        into v_recipients
        from jsonb_array_elements_text(v_payload->'recipient_emails') with ordinality;
      v_result := public.create_invitations_bulk(
        v_role_id,
        v_recipients,
        24,
        v_request.id
      );
      v_execution_summary := jsonb_build_object(
        'record_type', 'invitation_batch',
        'batch_id', v_result->>'batch_id',
        'requested', v_result->'requested'
      );
    else
      raise exception 'Action type is not executable';
    end if;

    update public.ai_action_requests
       set status = 'executed',
           executed_at = timezone('utc', now()),
           execution_result = v_result,
           execution_error = null
     where id = v_request.id;

    insert into public.ai_audit_events (
      request_id, tenant_id, user_id, conversation_id, event_type,
      tool_name, success, metadata
    ) values (
      v_request.id, v_tenant, v_user, v_request.conversation_id, 'response',
      'execute_ai_action', true,
      jsonb_build_object(
        'action_type', v_request.action_type,
        'execution', 'committed',
        'summary', v_execution_summary
      )
    );

    return jsonb_build_object(
      'status', 'executed',
      'action_type', v_request.action_type,
      'result', v_result
    );
  exception when others then
    update public.ai_action_requests
       set status = 'failed',
           execution_error = 'Action execution failed'
     where id = v_request.id;
    insert into public.ai_audit_events (
      request_id, tenant_id, user_id, conversation_id, event_type,
      tool_name, success, metadata
    ) values (
      v_request.id, v_tenant, v_user, v_request.conversation_id, 'error',
      'execute_ai_action', false,
      jsonb_build_object('action_type', v_request.action_type, 'execution', 'rolled_back')
    );
    return jsonb_build_object(
      'status', 'failed',
      'action_type', v_request.action_type,
      'error', 'Action execution failed'
    );
  end;
end;
$$;

revoke all on function public.execute_ai_action(uuid, uuid) from public, anon, authenticated;
grant execute on function public.execute_ai_action(uuid, uuid) to authenticated;
-- ===== END 20260827130000_ai_action_execution_phase3.sql =====

-- ===== BEGIN VERIFICATION =====
select to_regclass('public.ai_conversations') as ai_conversations,
       to_regclass('public.ai_messages') as ai_messages,
       to_regclass('public.ai_audit_events') as ai_audit_events,
       to_regclass('public.ai_action_requests') as ai_action_requests,
       to_regprocedure('public.execute_ai_action(uuid,uuid)') as execute_function;

select attname, attnotnull
from pg_attribute
where attrelid = 'public.ai_action_requests'::regclass
  and attname in ('confirmation_token', 'execution_result', 'execution_error')
  and not attisdropped
order by attname;

select has_table_privilege('anon', 'public.ai_action_requests', 'SELECT') as anon_can_read,
       has_table_privilege('authenticated', 'public.ai_action_requests', 'SELECT') as authenticated_can_read,
       has_function_privilege('anon', 'public.execute_ai_action(uuid,uuid)', 'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated', 'public.execute_ai_action(uuid,uuid)', 'EXECUTE') as authenticated_can_execute;
-- Expected privilege result: false, false, false, true.
-- ===== END VERIFICATION =====
