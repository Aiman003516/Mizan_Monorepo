-- Mizan AI action expansion Phase 4.
-- Adds reversible CRM/document edits, balanced adjustment/journal posting,
-- and archive/void semantics. Hard deletion remains unavailable.

alter table public.ai_action_requests
  drop constraint if exists ai_action_requests_action_type_check;

alter table public.ai_action_requests
  add constraint ai_action_requests_action_type_check check (action_type in (
    'invoice_draft',
    'bill_draft',
    'customer_draft',
    'vendor_draft',
    'journal_entry_draft',
    'staff_invitation_batch_draft',
    'customer_update',
    'vendor_update',
    'invoice_update',
    'bill_update',
    'balance_adjustment',
    'journal_entry_post',
    'customer_archive',
    'vendor_archive',
    'invoice_void',
    'bill_void'
  ));

create or replace function public.create_invoice_for_tenant(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_invoice_date date,
  p_due_date date,
  p_currency_code text,
  p_notes text,
  p_items jsonb,
  p_action_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_invoice public.invoices;
  v_subtotal bigint;
  v_number text := 'INV-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageCrm','createInvoices','manageInvoices','manageSettings']) then raise exception 'Invoice creation permission required'; end if;
  if not exists (select 1 from public.customers where id=p_customer_id and tenant_id=p_tenant_id and not is_deleted) then raise exception 'Customer does not belong to the current tenant'; end if;
  if p_action_request_id is null or p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>100 then raise exception 'Invoice item data is invalid'; end if;
  if p_due_date < p_invoice_date then raise exception 'Invoice due date cannot precede invoice date'; end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or p_currency_code !~ '^[A-Z]{3,5}$' then raise exception 'Currency code is invalid'; end if;
  if exists (select 1 from jsonb_array_elements(p_items) item where coalesce(length(btrim(item->>'description')),0)=0 or coalesce((item->>'quantity')::numeric,0)<=0 or coalesce((item->>'unit_price')::bigint,-1)<0) then raise exception 'Invoice item data is invalid'; end if;
  select coalesce(sum(round((item->>'quantity')::numeric*(item->>'unit_price')::bigint)),0)::bigint into v_subtotal from jsonb_array_elements(p_items) item;
  insert into public.invoices(tenant_id,customer_id,invoice_number,invoice_date,due_date,subtotal,tax_amount,total_amount,currency_code,notes,created_by)
  values(p_tenant_id,p_customer_id,v_number,p_invoice_date,p_due_date,v_subtotal,0,v_subtotal,p_currency_code,nullif(btrim(p_notes),''),v_user) returning * into v_invoice;
  insert into public.invoice_items(tenant_id,invoice_id,description,quantity,unit_price,amount,product_id)
  select p_tenant_id,v_invoice.id,btrim(item->>'description'),(item->>'quantity')::numeric,(item->>'unit_price')::bigint,round((item->>'quantity')::numeric*(item->>'unit_price')::bigint)::bigint,nullif(item->>'product_id','')::uuid from jsonb_array_elements(p_items) item;
  return jsonb_build_object('invoice',to_jsonb(v_invoice),'items',coalesce((select jsonb_agg(to_jsonb(ii)) from public.invoice_items ii where ii.invoice_id=v_invoice.id),'[]'::jsonb));
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception 'Invoice item data is invalid';
end;
$$;

create or replace function public.create_bill_for_tenant(
  p_tenant_id uuid,
  p_vendor_id uuid,
  p_bill_date date,
  p_due_date date,
  p_currency_code text,
  p_vendor_bill_number text,
  p_notes text,
  p_items jsonb,
  p_action_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_bill public.bills;
  v_subtotal bigint;
  v_number text := 'BILL-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageCrm','createBills','manageBills','manageSettings']) then raise exception 'Bill creation permission required'; end if;
  if not exists (select 1 from public.vendors where id=p_vendor_id and tenant_id=p_tenant_id and not is_deleted) then raise exception 'Vendor does not belong to the current tenant'; end if;
  if p_action_request_id is null or p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 or jsonb_array_length(p_items)>100 then raise exception 'Bill item data is invalid'; end if;
  if p_due_date < p_bill_date then raise exception 'Bill due date cannot precede bill date'; end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or p_currency_code !~ '^[A-Z]{3,5}$' then raise exception 'Currency code is invalid'; end if;
  if exists (select 1 from jsonb_array_elements(p_items) item where coalesce(length(btrim(item->>'description')),0)=0 or coalesce((item->>'quantity')::numeric,0)<=0 or coalesce((item->>'unit_price')::bigint,-1)<0) then raise exception 'Bill item data is invalid'; end if;
  select coalesce(sum(round((item->>'quantity')::numeric*(item->>'unit_price')::bigint)),0)::bigint into v_subtotal from jsonb_array_elements(p_items) item;
  insert into public.bills(tenant_id,vendor_id,bill_number,bill_date,due_date,subtotal,tax_amount,total_amount,currency_code,vendor_bill_number,notes,created_by)
  values(p_tenant_id,p_vendor_id,v_number,p_bill_date,p_due_date,v_subtotal,0,v_subtotal,p_currency_code,nullif(btrim(p_vendor_bill_number),''),nullif(btrim(p_notes),''),v_user) returning * into v_bill;
  insert into public.bill_items(tenant_id,bill_id,description,quantity,unit_price,amount,product_id)
  select p_tenant_id,v_bill.id,btrim(item->>'description'),(item->>'quantity')::numeric,(item->>'unit_price')::bigint,round((item->>'quantity')::numeric*(item->>'unit_price')::bigint)::bigint,nullif(item->>'product_id','')::uuid from jsonb_array_elements(p_items) item;
  return jsonb_build_object('bill',to_jsonb(v_bill),'items',coalesce((select jsonb_agg(to_jsonb(bi)) from public.bill_items bi where bi.bill_id=v_bill.id),'[]'::jsonb));
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception 'Bill item data is invalid';
end;
$$;

create or replace function public.create_invitation_for_tenant(
  p_tenant_id uuid,
  p_role_id uuid,
  p_recipient_email text,
  p_expires_hours integer default 24
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_invite public.invites;
  v_email text := nullif(lower(btrim(p_recipient_email)), '');
  v_code text;
  v_token text;
  v_expires timestamptz;
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageStaff','manageSettings']) then raise exception 'Staff management permission required'; end if;
  if p_expires_hours is null or p_expires_hours not between 1 and 168 or v_email is null or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Invitation data is invalid'; end if;
  if not exists(select 1 from public.roles where id=p_role_id and tenant_id=p_tenant_id and not is_system_admin) then raise exception 'Role does not belong to the current tenant'; end if;
  v_expires := timezone('utc',now()) + make_interval(hours=>p_expires_hours);
  loop
    v_code := lpad((floor(random()*900000)+100000)::bigint::text,6,'0');
    exit when not exists(select 1 from public.invites where code=v_code);
  end loop;
  v_token := encode(gen_random_bytes(32),'hex');
  insert into public.invites(tenant_id,role_id,code,created_by,expires_at,recipient_email,status,token_hash,code_hash,last_sent_at)
  values(p_tenant_id,p_role_id,v_code,v_user,v_expires,v_email,'sent',encode(digest(v_token,'sha256'),'hex'),encode(digest(v_code,'sha256'),'hex'),timezone('utc',now())) returning * into v_invite;
  return jsonb_build_object('id',v_invite.id,'code',v_code,'token',v_token,'tenant_id',p_tenant_id,'role_id',p_role_id,'recipient_email',v_email,'expires_at',v_expires);
end;
$$;

create or replace function public.create_invitations_bulk_for_tenant(
  p_tenant_id uuid,
  p_role_id uuid,
  p_recipient_emails text[],
  p_expires_hours integer,
  p_idempotency_key uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_count integer := coalesce(array_length(p_recipient_emails,1),0);
  v_email text;
  v_invite jsonb;
  v_results jsonb := '[]'::jsonb;
  v_batch_id uuid;
  v_existing jsonb;
  v_result jsonb;
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id,array['manageStaff','manageSettings']) then raise exception 'Staff management permission required'; end if;
  if v_count=0 or v_count>100 or p_expires_hours not between 1 and 168 or p_idempotency_key is null then raise exception 'Invitation batch data is invalid'; end if;
  if not exists(select 1 from public.roles where id=p_role_id and tenant_id=p_tenant_id and not is_system_admin) then raise exception 'Role does not belong to the current tenant'; end if;
  select id,result_json into v_batch_id,v_existing from public.invitation_batches where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key;
  if found then return v_existing || jsonb_build_object('batch_id',v_batch_id); end if;
  insert into public.invitation_batches(tenant_id,created_by,role_id,requested_count,idempotency_key) values(p_tenant_id,v_user,p_role_id,v_count,p_idempotency_key) returning id into v_batch_id;
  foreach v_email in array p_recipient_emails loop
    begin
      v_invite := public.create_invitation_for_tenant(p_tenant_id,p_role_id,v_email,p_expires_hours);
      v_results := v_results || jsonb_build_array(jsonb_build_object('email',lower(btrim(v_email)),'success',true,'code',v_invite->'code','expires_at',v_invite->'expires_at'));
    exception when others then
      v_results := v_results || jsonb_build_array(jsonb_build_object('email',lower(btrim(v_email)),'success',false,'error','Unable to create invitation'));
    end;
  end loop;
  v_result := jsonb_build_object('batch_id',v_batch_id,'requested',v_count,'results',v_results);
  update public.invitation_batches set result_json=v_result where id=v_batch_id;
  insert into public.audit_logs(tenant_id,user_id,action,target_table,record_id,new_data) values(p_tenant_id,v_user,'INSERT','invitation_batches',v_batch_id,v_result);
  return v_result;
end;
$$;

create or replace function public.update_customer_for_tenant(
  p_tenant_id uuid,
  p_customer_id uuid,
  p_expected_updated_at timestamptz,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_customer public.customers;
  v_email text;
  v_credit_limit bigint;
  v_is_on_hold boolean;
  v_key text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_expected_updated_at is null then raise exception 'Concurrency version is required'; end if;
  if p_patch is null or jsonb_typeof(p_patch) <> 'object' then raise exception 'Customer update data is invalid'; end if;
  if exists (select 1 from jsonb_object_keys(p_patch) as k(key)
             where k.key not in ('name','email','phone','address','tax_id','credit_limit','notes','is_on_hold')) then
    raise exception 'Customer update contains an unsupported field';
  end if;
  if not public.is_tenant_member(p_tenant_id)
     or not public.has_tenant_permission(p_tenant_id, array['manageCrm','manageCustomers','manageSettings']) then
    raise exception 'Customer update permission required';
  end if;
  select * into v_customer
    from public.customers
   where id = p_customer_id and tenant_id = p_tenant_id and not is_deleted
   for update;
  if not found then raise exception 'Customer does not belong to the current tenant'; end if;
  if v_customer.updated_at is distinct from p_expected_updated_at then raise exception 'Customer changed since the preview'; end if;

  v_email := case when p_patch ? 'email' then nullif(lower(btrim(p_patch->>'email')), '') else v_customer.email end;
  if v_email is not null and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Email is invalid'; end if;
  v_credit_limit := case when p_patch ? 'credit_limit' then (p_patch->>'credit_limit')::bigint else v_customer.credit_limit end;
  if v_credit_limit < 0 then raise exception 'Credit limit cannot be negative'; end if;
  v_is_on_hold := case when p_patch ? 'is_on_hold' then (p_patch->>'is_on_hold')::boolean else v_customer.is_on_hold end;

  update public.customers set
    name = case when p_patch ? 'name' then btrim(p_patch->>'name') else name end,
    email = v_email,
    phone = case when p_patch ? 'phone' then nullif(btrim(p_patch->>'phone'), '') else phone end,
    address = case when p_patch ? 'address' then nullif(btrim(p_patch->>'address'), '') else address end,
    tax_id = case when p_patch ? 'tax_id' then nullif(btrim(p_patch->>'tax_id'), '') else tax_id end,
    credit_limit = v_credit_limit,
    notes = case when p_patch ? 'notes' then nullif(btrim(p_patch->>'notes'), '') else notes end,
    is_on_hold = v_is_on_hold
  where id = p_customer_id and tenant_id = p_tenant_id
  returning * into v_customer;
  if length(btrim(v_customer.name)) not between 1 and 200 then raise exception 'Customer name is invalid'; end if;
  return to_jsonb(v_customer);
exception when invalid_text_representation then
  raise exception 'Customer update data is invalid';
end;
$$;

create or replace function public.update_vendor_for_tenant(
  p_tenant_id uuid,
  p_vendor_id uuid,
  p_expected_updated_at timestamptz,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_vendor public.vendors;
  v_email text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_expected_updated_at is null then raise exception 'Concurrency version is required'; end if;
  if p_patch is null or jsonb_typeof(p_patch) <> 'object' then raise exception 'Vendor update data is invalid'; end if;
  if exists (select 1 from jsonb_object_keys(p_patch) as k(key)
             where k.key not in ('name','email','phone','address','tax_id','payment_terms','notes')) then
    raise exception 'Vendor update contains an unsupported field';
  end if;
  if not public.is_tenant_member(p_tenant_id)
     or not public.has_tenant_permission(p_tenant_id, array['manageCrm','manageVendors','manageSettings']) then
    raise exception 'Vendor update permission required';
  end if;
  select * into v_vendor
    from public.vendors
   where id = p_vendor_id and tenant_id = p_tenant_id and not is_deleted
   for update;
  if not found then raise exception 'Vendor does not belong to the current tenant'; end if;
  if v_vendor.updated_at is distinct from p_expected_updated_at then raise exception 'Vendor changed since the preview'; end if;
  v_email := case when p_patch ? 'email' then nullif(lower(btrim(p_patch->>'email')), '') else v_vendor.email end;
  if v_email is not null and v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Email is invalid'; end if;

  update public.vendors set
    name = case when p_patch ? 'name' then btrim(p_patch->>'name') else name end,
    email = v_email,
    phone = case when p_patch ? 'phone' then nullif(btrim(p_patch->>'phone'), '') else phone end,
    address = case when p_patch ? 'address' then nullif(btrim(p_patch->>'address'), '') else address end,
    tax_id = case when p_patch ? 'tax_id' then nullif(btrim(p_patch->>'tax_id'), '') else tax_id end,
    payment_terms = case when p_patch ? 'payment_terms' then nullif(btrim(p_patch->>'payment_terms'), '') else payment_terms end,
    notes = case when p_patch ? 'notes' then nullif(btrim(p_patch->>'notes'), '') else notes end
  where id = p_vendor_id and tenant_id = p_tenant_id
  returning * into v_vendor;
  if length(btrim(v_vendor.name)) not between 1 and 200 then raise exception 'Vendor name is invalid'; end if;
  return to_jsonb(v_vendor);
end;
$$;

create or replace function public.update_invoice_for_tenant(
  p_tenant_id uuid,
  p_invoice_id uuid,
  p_expected_updated_at timestamptz,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_invoice public.invoices;
  v_items jsonb;
  v_item jsonb;
  v_subtotal bigint;
  v_quantity numeric;
  v_unit_price bigint;
  v_description text;
  v_currency text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_expected_updated_at is null or p_patch is null or jsonb_typeof(p_patch) <> 'object' then raise exception 'Invoice update data is invalid'; end if;
  if exists (select 1 from jsonb_object_keys(p_patch) as k(key)
             where k.key not in ('invoice_date','due_date','currency_code','notes','items')) then
    raise exception 'Invoice update contains an unsupported field';
  end if;
  if not public.is_tenant_member(p_tenant_id)
     or not public.has_tenant_permission(p_tenant_id, array['manageCrm','manageInvoices','createInvoices','manageSettings']) then
    raise exception 'Invoice update permission required';
  end if;
  select * into v_invoice from public.invoices
   where id = p_invoice_id and tenant_id = p_tenant_id for update;
  if not found then raise exception 'Invoice does not belong to the current tenant'; end if;
  if v_invoice.status <> 'draft' then raise exception 'Only draft invoices can be edited'; end if;
  if v_invoice.updated_at is distinct from p_expected_updated_at then raise exception 'Invoice changed since the preview'; end if;

  v_currency := case when p_patch ? 'currency_code' then upper(btrim(p_patch->>'currency_code')) else v_invoice.currency_code end;
  if v_currency !~ '^[A-Z]{3,5}$' then raise exception 'Currency code is invalid'; end if;
  if p_patch ? 'invoice_date' and (p_patch->>'invoice_date')::date is null then raise exception 'Invoice date is invalid'; end if;
  if p_patch ? 'due_date' and (p_patch->>'due_date')::date < coalesce((p_patch->>'invoice_date')::date, v_invoice.invoice_date) then raise exception 'Invoice due date cannot precede invoice date'; end if;
  if p_patch ? 'items' then
    v_items := p_patch->'items';
    if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) = 0 or jsonb_array_length(v_items) > 100 then raise exception 'Invoice item data is invalid'; end if;
    for v_item in select value from jsonb_array_elements(v_items) loop
      v_description := nullif(btrim(v_item->>'description'), '');
      v_quantity := (v_item->>'quantity')::numeric;
      v_unit_price := (v_item->>'unit_price')::bigint;
      if v_description is null or length(v_description) > 500 or v_quantity <= 0 or v_unit_price < 0 then raise exception 'Invoice item data is invalid'; end if;
    end loop;
    select coalesce(sum(round((value->>'quantity')::numeric * (value->>'unit_price')::bigint)),0)::bigint
      into v_subtotal from jsonb_array_elements(v_items);
  else
    v_items := null;
    v_subtotal := v_invoice.subtotal;
  end if;

  update public.invoices set
    invoice_date = case when p_patch ? 'invoice_date' then (p_patch->>'invoice_date')::date else invoice_date end,
    due_date = case when p_patch ? 'due_date' then (p_patch->>'due_date')::date else due_date end,
    currency_code = v_currency,
    notes = case when p_patch ? 'notes' then nullif(btrim(p_patch->>'notes'), '') else notes end,
    subtotal = v_subtotal,
    total_amount = v_subtotal + tax_amount
  where id = p_invoice_id and tenant_id = p_tenant_id
  returning * into v_invoice;
  if v_items is not null then
    delete from public.invoice_items where invoice_id = p_invoice_id and tenant_id = p_tenant_id;
    insert into public.invoice_items (tenant_id, invoice_id, description, quantity, unit_price, amount, product_id)
    select p_tenant_id, p_invoice_id, btrim(value->>'description'), (value->>'quantity')::numeric,
           (value->>'unit_price')::bigint,
           round((value->>'quantity')::numeric * (value->>'unit_price')::bigint)::bigint,
           nullif(value->>'product_id','')::uuid
      from jsonb_array_elements(v_items);
  end if;
  return jsonb_build_object('invoice', to_jsonb(v_invoice), 'items', coalesce((select jsonb_agg(to_jsonb(ii)) from public.invoice_items ii where ii.invoice_id = p_invoice_id), '[]'::jsonb));
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception 'Invoice update data is invalid';
end;
$$;

create or replace function public.update_bill_for_tenant(
  p_tenant_id uuid,
  p_bill_id uuid,
  p_expected_updated_at timestamptz,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_bill public.bills;
  v_items jsonb;
  v_item jsonb;
  v_subtotal bigint;
  v_currency text;
  v_description text;
  v_quantity numeric;
  v_unit_price bigint;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_expected_updated_at is null or p_patch is null or jsonb_typeof(p_patch) <> 'object' then raise exception 'Bill update data is invalid'; end if;
  if exists (select 1 from jsonb_object_keys(p_patch) as k(key)
             where k.key not in ('bill_date','due_date','currency_code','vendor_bill_number','notes','items')) then
    raise exception 'Bill update contains an unsupported field';
  end if;
  if not public.is_tenant_member(p_tenant_id)
     or not public.has_tenant_permission(p_tenant_id, array['manageCrm','manageBills','createBills','manageSettings']) then
    raise exception 'Bill update permission required';
  end if;
  select * into v_bill from public.bills where id = p_bill_id and tenant_id = p_tenant_id for update;
  if not found then raise exception 'Bill does not belong to the current tenant'; end if;
  if v_bill.status <> 'pending' then raise exception 'Only pending bills can be edited'; end if;
  if v_bill.updated_at is distinct from p_expected_updated_at then raise exception 'Bill changed since the preview'; end if;

  v_currency := case when p_patch ? 'currency_code' then upper(btrim(p_patch->>'currency_code')) else v_bill.currency_code end;
  if v_currency !~ '^[A-Z]{3,5}$' then raise exception 'Currency code is invalid'; end if;
  if p_patch ? 'due_date' and (p_patch->>'due_date')::date < coalesce((p_patch->>'bill_date')::date, v_bill.bill_date) then raise exception 'Bill due date cannot precede bill date'; end if;
  if p_patch ? 'items' then
    v_items := p_patch->'items';
    if jsonb_typeof(v_items) <> 'array' or jsonb_array_length(v_items) = 0 or jsonb_array_length(v_items) > 100 then raise exception 'Bill item data is invalid'; end if;
    for v_item in select value from jsonb_array_elements(v_items) loop
      v_description := nullif(btrim(v_item->>'description'), '');
      v_quantity := (v_item->>'quantity')::numeric;
      v_unit_price := (v_item->>'unit_price')::bigint;
      if v_description is null or length(v_description) > 500 or v_quantity <= 0 or v_unit_price < 0 then raise exception 'Bill item data is invalid'; end if;
    end loop;
    select coalesce(sum(round((value->>'quantity')::numeric * (value->>'unit_price')::bigint)),0)::bigint
      into v_subtotal from jsonb_array_elements(v_items);
  else
    v_items := null;
    v_subtotal := v_bill.subtotal;
  end if;

  update public.bills set
    bill_date = case when p_patch ? 'bill_date' then (p_patch->>'bill_date')::date else bill_date end,
    due_date = case when p_patch ? 'due_date' then (p_patch->>'due_date')::date else due_date end,
    currency_code = v_currency,
    vendor_bill_number = case when p_patch ? 'vendor_bill_number' then nullif(btrim(p_patch->>'vendor_bill_number'), '') else vendor_bill_number end,
    notes = case when p_patch ? 'notes' then nullif(btrim(p_patch->>'notes'), '') else notes end,
    subtotal = v_subtotal,
    total_amount = v_subtotal + tax_amount
  where id = p_bill_id and tenant_id = p_tenant_id
  returning * into v_bill;
  if v_items is not null then
    delete from public.bill_items where bill_id = p_bill_id and tenant_id = p_tenant_id;
    insert into public.bill_items (tenant_id, bill_id, description, quantity, unit_price, amount, product_id)
    select p_tenant_id, p_bill_id, btrim(value->>'description'), (value->>'quantity')::numeric,
           (value->>'unit_price')::bigint,
           round((value->>'quantity')::numeric * (value->>'unit_price')::bigint)::bigint,
           nullif(value->>'product_id','')::uuid
      from jsonb_array_elements(v_items);
  end if;
  return jsonb_build_object('bill', to_jsonb(v_bill), 'items', coalesce((select jsonb_agg(to_jsonb(bi)) from public.bill_items bi where bi.bill_id = p_bill_id), '[]'::jsonb));
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception 'Bill update data is invalid';
end;
$$;

create or replace function public.post_balance_adjustment_for_tenant(
  p_tenant_id uuid,
  p_party_type text,
  p_party_id uuid,
  p_amount bigint,
  p_direction text,
  p_currency_code text,
  p_debit_account_id text,
  p_credit_account_id text,
  p_description text,
  p_expected_updated_at timestamptz,
  p_action_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_transaction_id text;
  v_old_balance bigint;
  v_new_balance bigint;
  v_signed bigint;
  v_updated_at timestamptz;
  v_account_count integer;
  v_base_currency text;
  v_txn_data jsonb;
  v_debit_entry_id text;
  v_credit_entry_id text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_amount <= 0 or p_direction not in ('increase','decrease') or p_party_type not in ('customer','vendor') then raise exception 'Balance adjustment data is invalid'; end if;
  if p_debit_account_id is null or p_credit_account_id is null or p_debit_account_id = p_credit_account_id then raise exception 'Balance accounts are invalid'; end if;
  if p_expected_updated_at is null or p_action_request_id is null then raise exception 'Balance concurrency data is invalid'; end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or p_currency_code !~ '^[A-Z]{3,5}$' then raise exception 'Currency code is invalid'; end if;
  select currency_code into v_base_currency from public.tenants where id=p_tenant_id;
  if v_base_currency is null or p_currency_code <> v_base_currency then raise exception 'Balance adjustments must use the tenant base currency'; end if;
  if length(btrim(coalesce(p_description,''))) not between 1 and 500 then raise exception 'Adjustment description is invalid'; end if;
  if not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageAccounting','manageCrm','manageCustomers','manageVendors','manageSettings']) then raise exception 'Balance adjustment permission required'; end if;

  select count(*) into v_account_count from public.synced_accounts
   where tenant_id = p_tenant_id and not is_deleted and id in (p_debit_account_id, p_credit_account_id);
  if v_account_count <> 2 then raise exception 'Adjustment accounts do not belong to the current tenant'; end if;

  select id into v_transaction_id from public.synced_transactions
   where tenant_id = p_tenant_id and not is_deleted and data->>'ai_action_request_id' = p_action_request_id::text limit 1;
  if v_transaction_id is not null then
    return (select data from public.synced_transactions where tenant_id = p_tenant_id and id = v_transaction_id);
  end if;

  if p_party_type = 'customer' then
    select balance, updated_at into v_old_balance, v_updated_at from public.customers where id = p_party_id and tenant_id = p_tenant_id and not is_deleted for update;
  else
    select balance, updated_at into v_old_balance, v_updated_at from public.vendors where id = p_party_id and tenant_id = p_tenant_id and not is_deleted for update;
  end if;
  if v_old_balance is null then raise exception 'Balance target does not belong to the current tenant'; end if;
  if v_updated_at is distinct from p_expected_updated_at then raise exception 'Balance target changed since the preview'; end if;
  v_signed := case when p_direction = 'increase' then p_amount else -p_amount end;
  v_new_balance := v_old_balance + v_signed;
  if v_new_balance < 0 then raise exception 'Balance cannot become negative'; end if;

  v_transaction_id := gen_random_uuid()::text;
  v_txn_data := jsonb_build_object(
    'id', v_transaction_id,
    'tenant_id', p_tenant_id,
    'description', btrim(p_description),
    'transaction_date', timezone('utc', now()),
    'currency_code', p_currency_code,
    'is_adjustment', true,
    'created_by_user_id', v_user,
    'ai_action_request_id', p_action_request_id,
    'status', 'posted'
  );
  insert into public.synced_transactions (id, tenant_id, data, last_updated, is_deleted) values (v_transaction_id, p_tenant_id, v_txn_data, timezone('utc', now()), false);
  v_debit_entry_id := gen_random_uuid()::text;
  v_credit_entry_id := gen_random_uuid()::text;
  insert into public.synced_transaction_entries (id, tenant_id, data, last_updated, is_deleted) values
    (v_debit_entry_id, p_tenant_id, jsonb_build_object('id', v_debit_entry_id, 'tenant_id', p_tenant_id, 'transaction_id', v_transaction_id, 'account_id', p_debit_account_id, 'amount', p_amount, 'currency_rate', 1.0), timezone('utc', now()), false),
    (v_credit_entry_id, p_tenant_id, jsonb_build_object('id', v_credit_entry_id, 'tenant_id', p_tenant_id, 'transaction_id', v_transaction_id, 'account_id', p_credit_account_id, 'amount', -p_amount, 'currency_rate', 1.0), timezone('utc', now()), false);

  if p_party_type = 'customer' then
    update public.customers set balance = v_new_balance where id = p_party_id and tenant_id = p_tenant_id;
  else
    update public.vendors set balance = v_new_balance where id = p_party_id and tenant_id = p_tenant_id;
  end if;
  return v_txn_data;
end;
$$;

create or replace function public.post_journal_entry_for_tenant(
  p_tenant_id uuid,
  p_description text,
  p_transaction_date date,
  p_currency_code text,
  p_lines jsonb,
  p_action_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_transaction_id text;
  v_line jsonb;
  v_account_id text;
  v_amount bigint;
  v_total bigint := 0;
  v_count integer := 0;
  v_txn_data jsonb;
  v_entry_id text;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['postJournalEntries','manageAccounting','manageSettings']) then raise exception 'Journal posting permission required'; end if;
  if length(btrim(coalesce(p_description,''))) not between 1 and 500 or p_transaction_date is null or p_action_request_id is null then raise exception 'Journal data is invalid'; end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or p_currency_code !~ '^[A-Z]{3,5}$' then raise exception 'Currency code is invalid'; end if;
  if jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) < 2 or jsonb_array_length(p_lines) > 100 then raise exception 'Journal must contain between 2 and 100 lines'; end if;
  if exists (select 1 from public.synced_transactions where tenant_id = p_tenant_id and not is_deleted and data->>'ai_action_request_id' = p_action_request_id::text) then
    return (select data from public.synced_transactions where tenant_id = p_tenant_id and not is_deleted and data->>'ai_action_request_id' = p_action_request_id::text limit 1);
  end if;
  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_count := v_count + 1;
    v_account_id := nullif(v_line->>'account_id','');
    v_amount := (v_line->>'amount')::bigint;
    if v_account_id is null or v_amount = 0 then raise exception 'Journal line is invalid'; end if;
    if not exists (select 1 from public.synced_accounts where tenant_id = p_tenant_id and id = v_account_id and not is_deleted) then raise exception 'Journal account does not belong to the current tenant'; end if;
    v_total := v_total + v_amount;
  end loop;
  if v_total <> 0 then raise exception 'Journal is unbalanced'; end if;

  v_transaction_id := gen_random_uuid()::text;
  v_txn_data := jsonb_build_object('id', v_transaction_id, 'tenant_id', p_tenant_id, 'description', btrim(p_description), 'transaction_date', p_transaction_date, 'currency_code', p_currency_code, 'is_adjustment', false, 'created_by_user_id', v_user, 'ai_action_request_id', p_action_request_id, 'status', 'posted');
  insert into public.synced_transactions (id, tenant_id, data, last_updated, is_deleted) values (v_transaction_id, p_tenant_id, v_txn_data, timezone('utc', now()), false);
  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_entry_id := gen_random_uuid()::text;
    insert into public.synced_transaction_entries (id, tenant_id, data, last_updated, is_deleted)
    values (v_entry_id, p_tenant_id, jsonb_build_object('id', v_entry_id, 'tenant_id', p_tenant_id, 'transaction_id', v_transaction_id, 'account_id', v_line->>'account_id', 'amount', (v_line->>'amount')::bigint, 'currency_rate', coalesce((v_line->>'currency_rate')::numeric, 1.0)), timezone('utc', now()), false);
  end loop;
  return v_txn_data;
exception when invalid_text_representation or numeric_value_out_of_range then
  raise exception 'Journal data is invalid';
end;
$$;

create or replace function public.archive_customer_for_tenant(p_tenant_id uuid, p_customer_id uuid, p_expected_updated_at timestamptz)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_customer public.customers; v_user uuid := (select auth.uid());
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageCrm','manageCustomers','manageSettings']) then raise exception 'Customer archive permission required'; end if;
  select * into v_customer from public.customers where id=p_customer_id and tenant_id=p_tenant_id and not is_deleted for update;
  if not found then raise exception 'Customer does not belong to the current tenant'; end if;
  if v_customer.updated_at is distinct from p_expected_updated_at then raise exception 'Customer changed since the preview'; end if;
  if exists (select 1 from public.invoices where tenant_id=p_tenant_id and customer_id=p_customer_id and status not in ('paid','void')) then raise exception 'Customer has open invoices and cannot be archived'; end if;
  update public.customers set is_deleted=true where id=p_customer_id and tenant_id=p_tenant_id returning * into v_customer;
  return to_jsonb(v_customer);
end; $$;

create or replace function public.archive_vendor_for_tenant(p_tenant_id uuid, p_vendor_id uuid, p_expected_updated_at timestamptz)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_vendor public.vendors; v_user uuid := (select auth.uid());
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageCrm','manageVendors','manageSettings']) then raise exception 'Vendor archive permission required'; end if;
  select * into v_vendor from public.vendors where id=p_vendor_id and tenant_id=p_tenant_id and not is_deleted for update;
  if not found then raise exception 'Vendor does not belong to the current tenant'; end if;
  if v_vendor.updated_at is distinct from p_expected_updated_at then raise exception 'Vendor changed since the preview'; end if;
  if exists (select 1 from public.bills where tenant_id=p_tenant_id and vendor_id=p_vendor_id and status not in ('paid','void')) then raise exception 'Vendor has open bills and cannot be archived'; end if;
  update public.vendors set is_deleted=true where id=p_vendor_id and tenant_id=p_tenant_id returning * into v_vendor;
  return to_jsonb(v_vendor);
end; $$;

create or replace function public.void_invoice_for_tenant(p_tenant_id uuid, p_invoice_id uuid, p_expected_updated_at timestamptz)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_invoice public.invoices; v_user uuid := (select auth.uid());
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageInvoices','manageCrm','manageSettings']) then raise exception 'Invoice void permission required'; end if;
  select * into v_invoice from public.invoices where id=p_invoice_id and tenant_id=p_tenant_id for update;
  if not found then raise exception 'Invoice does not belong to the current tenant'; end if;
  if v_invoice.status in ('paid','void') or v_invoice.amount_paid <> 0 then raise exception 'Invoice cannot be voided'; end if;
  if v_invoice.updated_at is distinct from p_expected_updated_at then raise exception 'Invoice changed since the preview'; end if;
  update public.invoices set status='void' where id=p_invoice_id and tenant_id=p_tenant_id returning * into v_invoice;
  return to_jsonb(v_invoice);
end; $$;

create or replace function public.void_bill_for_tenant(p_tenant_id uuid, p_bill_id uuid, p_expected_updated_at timestamptz)
returns jsonb language plpgsql security definer set search_path = public as $$
declare v_bill public.bills; v_user uuid := (select auth.uid());
begin
  if v_user is null or not public.is_tenant_member(p_tenant_id) or not public.has_tenant_permission(p_tenant_id, array['manageBills','manageCrm','manageSettings']) then raise exception 'Bill void permission required'; end if;
  select * into v_bill from public.bills where id=p_bill_id and tenant_id=p_tenant_id for update;
  if not found then raise exception 'Bill does not belong to the current tenant'; end if;
  if v_bill.status in ('paid','void') or v_bill.amount_paid <> 0 then raise exception 'Bill cannot be voided'; end if;
  if v_bill.updated_at is distinct from p_expected_updated_at then raise exception 'Bill changed since the preview'; end if;
  update public.bills set status='void' where id=p_bill_id and tenant_id=p_tenant_id returning * into v_bill;
  return to_jsonb(v_bill);
end; $$;

revoke all on function public.create_invoice_for_tenant(uuid,uuid,date,date,text,text,jsonb,uuid) from public, anon, authenticated;
revoke all on function public.create_bill_for_tenant(uuid,uuid,date,date,text,text,text,jsonb,uuid) from public, anon, authenticated;
revoke all on function public.create_invitation_for_tenant(uuid,uuid,text,integer) from public, anon, authenticated;
revoke all on function public.create_invitations_bulk_for_tenant(uuid,uuid,text[],integer,uuid) from public, anon, authenticated;
revoke all on function public.update_customer_for_tenant(uuid,uuid,timestamptz,jsonb) from public, anon, authenticated;
revoke all on function public.update_vendor_for_tenant(uuid,uuid,timestamptz,jsonb) from public, anon, authenticated;
revoke all on function public.update_invoice_for_tenant(uuid,uuid,timestamptz,jsonb) from public, anon, authenticated;
revoke all on function public.update_bill_for_tenant(uuid,uuid,timestamptz,jsonb) from public, anon, authenticated;
revoke all on function public.post_balance_adjustment_for_tenant(uuid,text,uuid,bigint,text,text,text,text,text,timestamptz,uuid) from public, anon, authenticated;
revoke all on function public.post_journal_entry_for_tenant(uuid,text,date,text,jsonb,uuid) from public, anon, authenticated;
revoke all on function public.archive_customer_for_tenant(uuid,uuid,timestamptz) from public, anon, authenticated;
revoke all on function public.archive_vendor_for_tenant(uuid,uuid,timestamptz) from public, anon, authenticated;
revoke all on function public.void_invoice_for_tenant(uuid,uuid,timestamptz) from public, anon, authenticated;
revoke all on function public.void_bill_for_tenant(uuid,uuid,timestamptz) from public, anon, authenticated;

do $$
begin
  if to_regprocedure('public.execute_ai_action(uuid,uuid)') is not null
     and to_regprocedure('public.execute_ai_action_phase3(uuid,uuid)') is null then
    execute 'alter function public.execute_ai_action(uuid, uuid) rename to execute_ai_action_phase3';
  end if;
end;
$$;
revoke all on function public.execute_ai_action_phase3(uuid, uuid) from public, anon, authenticated;

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
  v_result jsonb;
  v_summary jsonb;
  v_payload jsonb;
  v_patch jsonb;
  v_expected timestamptz;
  v_party_type text;
  v_direction text;
  v_party_id uuid;
  v_amount bigint;
  v_currency text;
  v_description text;
  v_debit text;
  v_credit text;
  v_lines jsonb;
  v_role_id uuid;
  v_recipients text[];
  v_action_is_new boolean;
  v_audit_action text;
  v_audit_record_id uuid;
begin
  if v_user is null then raise exception 'Authentication required'; end if;
  if p_action_request_id is null or p_confirmation_token is null then raise exception 'Confirmation is required'; end if;
  select * into v_request from public.ai_action_requests where id=p_action_request_id for update;
  if not found or v_request.user_id <> v_user then raise exception 'Action request is unavailable'; end if;
  if v_request.action_type in ('customer_draft','vendor_draft') then
    return public.execute_ai_action_phase3(p_action_request_id, p_confirmation_token);
  end if;
  v_action_is_new := v_request.action_type in ('invoice_draft','bill_draft','staff_invitation_batch_draft','customer_update','vendor_update','invoice_update','bill_update','balance_adjustment','journal_entry_post','customer_archive','vendor_archive','invoice_void','bill_void');
  if not v_action_is_new then raise exception 'Action type is not executable'; end if;
  if v_request.confirmation_token <> p_confirmation_token then raise exception 'Confirmation token is invalid'; end if;
  if v_request.status = 'executed' then
    return jsonb_build_object('status','executed','action_type',v_request.action_type,'result',coalesce(v_request.execution_result,'{}'::jsonb));
  end if;
  if v_request.status <> 'pending' then raise exception 'Action request is no longer pending'; end if;
  if v_request.expires_at <= timezone('utc', now()) then
    update public.ai_action_requests set status='expired', execution_error='Action request expired' where id=v_request.id;
    raise exception 'Action request is expired';
  end if;
  if not exists (select 1 from public.staff_members where tenant_id=v_request.tenant_id and user_id=v_user and status='active') then raise exception 'Active tenant membership required'; end if;
  v_payload := v_request.payload;
  begin
    if v_request.action_type = 'invoice_draft' then
      v_result := public.create_invoice_for_tenant(v_request.tenant_id,(v_payload->>'customer_id')::uuid,(v_payload->>'invoice_date')::date,(v_payload->>'due_date')::date,v_payload->>'currency_code',nullif(v_payload->>'notes',''),coalesce(v_payload->'items','[]'::jsonb),v_request.id);
      v_summary := jsonb_build_object('record_type','invoice','record_id',v_result->'invoice'->>'id');
    elsif v_request.action_type = 'bill_draft' then
      v_result := public.create_bill_for_tenant(v_request.tenant_id,(v_payload->>'vendor_id')::uuid,(v_payload->>'bill_date')::date,(v_payload->>'due_date')::date,v_payload->>'currency_code',nullif(v_payload->>'vendor_bill_number',''),nullif(v_payload->>'notes',''),coalesce(v_payload->'items','[]'::jsonb),v_request.id);
      v_summary := jsonb_build_object('record_type','bill','record_id',v_result->'bill'->>'id');
    elsif v_request.action_type = 'staff_invitation_batch_draft' then
      v_role_id := (v_payload->>'role_id')::uuid;
      select array_agg(value::text order by ordinality) into v_recipients from jsonb_array_elements_text(v_payload->'recipient_emails') with ordinality;
      v_result := public.create_invitations_bulk_for_tenant(v_request.tenant_id,v_role_id,v_recipients,24,v_request.id);
      v_summary := jsonb_build_object('record_type','invitation_batch','batch_id',v_result->>'batch_id','requested',v_result->>'requested');
    elsif v_request.action_type = 'customer_update' then
      v_patch := coalesce(v_payload->'patch', '{}'::jsonb); v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_party_id := (v_payload->>'customer_id')::uuid;
      v_result := public.update_customer_for_tenant(v_request.tenant_id,v_party_id,v_expected,v_patch); v_summary := jsonb_build_object('record_type','customer','record_id',v_party_id);
    elsif v_request.action_type = 'vendor_update' then
      v_patch := coalesce(v_payload->'patch', '{}'::jsonb); v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_party_id := (v_payload->>'vendor_id')::uuid;
      v_result := public.update_vendor_for_tenant(v_request.tenant_id,v_party_id,v_expected,v_patch); v_summary := jsonb_build_object('record_type','vendor','record_id',v_party_id);
    elsif v_request.action_type = 'invoice_update' then
      v_patch := coalesce(v_payload->'patch', '{}'::jsonb); v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_party_id := (v_payload->>'invoice_id')::uuid;
      v_result := public.update_invoice_for_tenant(v_request.tenant_id,v_party_id,v_expected,v_patch); v_summary := jsonb_build_object('record_type','invoice','record_id',v_party_id);
    elsif v_request.action_type = 'bill_update' then
      v_patch := coalesce(v_payload->'patch', '{}'::jsonb); v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_party_id := (v_payload->>'bill_id')::uuid;
      v_result := public.update_bill_for_tenant(v_request.tenant_id,v_party_id,v_expected,v_patch); v_summary := jsonb_build_object('record_type','bill','record_id',v_party_id);
    elsif v_request.action_type = 'balance_adjustment' then
      v_party_type := v_payload->>'party_type'; v_party_id := (v_payload->>'party_id')::uuid; v_amount := (v_payload->>'amount_minor')::bigint; v_direction := v_payload->>'direction'; v_currency := upper(v_payload->>'currency_code'); v_debit := v_payload->>'debit_account_id'; v_credit := v_payload->>'credit_account_id'; v_description := v_payload->>'description'; v_expected := (v_payload->>'expected_updated_at')::timestamptz;
      v_result := public.post_balance_adjustment_for_tenant(v_request.tenant_id,v_party_type,v_party_id,v_amount,v_direction,v_currency,v_debit,v_credit,v_description,v_expected,v_request.id); v_summary := jsonb_build_object('record_type','balance_adjustment','record_id',v_party_id);
    elsif v_request.action_type = 'journal_entry_post' then
      v_description := v_payload->>'description'; v_currency := upper(v_payload->>'currency_code'); v_lines := v_payload->'lines';
      v_result := public.post_journal_entry_for_tenant(v_request.tenant_id,v_description,(v_payload->>'transaction_date')::date,v_currency,v_lines,v_request.id); v_summary := jsonb_build_object('record_type','journal_entry','record_id',v_result->>'id');
    elsif v_request.action_type = 'customer_archive' then
      v_party_id := (v_payload->>'customer_id')::uuid; v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_result := public.archive_customer_for_tenant(v_request.tenant_id,v_party_id,v_expected); v_summary := jsonb_build_object('record_type','customer_archive','record_id',v_party_id);
    elsif v_request.action_type = 'vendor_archive' then
      v_party_id := (v_payload->>'vendor_id')::uuid; v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_result := public.archive_vendor_for_tenant(v_request.tenant_id,v_party_id,v_expected); v_summary := jsonb_build_object('record_type','vendor_archive','record_id',v_party_id);
    elsif v_request.action_type = 'invoice_void' then
      v_party_id := (v_payload->>'invoice_id')::uuid; v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_result := public.void_invoice_for_tenant(v_request.tenant_id,v_party_id,v_expected); v_summary := jsonb_build_object('record_type','invoice_void','record_id',v_party_id);
    elsif v_request.action_type = 'bill_void' then
      v_party_id := (v_payload->>'bill_id')::uuid; v_expected := (v_payload->>'expected_updated_at')::timestamptz; v_result := public.void_bill_for_tenant(v_request.tenant_id,v_party_id,v_expected); v_summary := jsonb_build_object('record_type','bill_void','record_id',v_party_id);
    end if;

    v_audit_action := case when v_request.action_type in ('customer_archive','vendor_archive','invoice_void','bill_void') then 'UPDATE' else 'INSERT' end;
    v_audit_record_id := nullif(v_summary->>'record_id','')::uuid;
    insert into public.audit_logs(tenant_id,user_id,action,target_table,record_id,new_data)
    values(v_request.tenant_id,v_user,v_audit_action,v_request.action_type,v_audit_record_id,jsonb_build_object('action_request_id',v_request.id,'payload',v_payload,'result',v_result));
    update public.ai_action_requests set status='executed', confirmed_at=coalesce(confirmed_at,timezone('utc',now())), executed_at=timezone('utc',now()), execution_result=v_result, execution_error=null where id=v_request.id;
    insert into public.ai_audit_events(request_id,tenant_id,user_id,conversation_id,event_type,tool_name,success,metadata) values(v_request.id,v_request.tenant_id,v_user,v_request.conversation_id,'response','execute_ai_action',true,jsonb_build_object('action_type',v_request.action_type,'execution','committed','summary',v_summary));
    return jsonb_build_object('status','executed','action_type',v_request.action_type,'result',v_result);
  exception when others then
    update public.ai_action_requests set status='failed', execution_error='Action execution failed' where id=v_request.id;
    insert into public.ai_audit_events(request_id,tenant_id,user_id,conversation_id,event_type,tool_name,success,metadata) values(v_request.id,v_request.tenant_id,v_user,v_request.conversation_id,'error','execute_ai_action',false,jsonb_build_object('action_type',v_request.action_type,'execution','rolled_back'));
    return jsonb_build_object('status','failed','action_type',v_request.action_type,'error','Action execution failed');
  end;
end;
$$;

revoke all on function public.execute_ai_action(uuid,uuid) from public, anon, authenticated;
grant execute on function public.execute_ai_action(uuid,uuid) to authenticated;

-- Hard deletion is intentionally not exposed. Posted financial records must be voided or reversed.
