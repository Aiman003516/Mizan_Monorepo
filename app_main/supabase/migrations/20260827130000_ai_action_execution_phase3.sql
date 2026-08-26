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
