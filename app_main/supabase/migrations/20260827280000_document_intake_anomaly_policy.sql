-- Mizan governed document intake and policy context.
-- File bytes stay in protected storage; this schema stores references and
-- reviewable extraction drafts only. No OCR/provider is assumed or enabled.

create table if not exists public.document_intake_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  source_type text not null check (source_type in ('invoice', 'bill', 'receipt', 'bank_statement', 'other')),
  source_id uuid,
  storage_path text not null check (length(btrim(storage_path)) between 1 and 500),
  file_name text not null check (length(btrim(file_name)) between 1 and 240),
  mime_type text not null check (length(btrim(mime_type)) between 1 and 120),
  sha256 text check (sha256 is null or sha256 ~ '^[A-Fa-f0-9]{64}$'),
  status text not null default 'received' check (status in ('received', 'extracted_draft', 'reviewed', 'rejected')),
  extraction_provider text,
  extraction_version text,
  extracted_data jsonb not null default '{}'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id)
);

create table if not exists public.document_anomalies (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  document_id uuid not null references public.document_intake_items(id) on delete cascade,
  rule_code text not null check (length(btrim(rule_code)) between 1 and 100),
  severity text not null check (severity in ('low', 'medium', 'high')),
  message text not null check (length(btrim(message)) between 1 and 500),
  evidence jsonb not null default '{}'::jsonb,
  status text not null default 'open' check (status in ('open', 'accepted', 'dismissed')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id)
);

create table if not exists public.ai_policy_rules (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  policy_code text not null check (length(btrim(policy_code)) between 1 and 100),
  scope text not null check (length(btrim(scope)) between 1 and 100),
  action text not null check (length(btrim(action)) between 1 and 100),
  policy_text text not null check (length(btrim(policy_text)) between 1 and 4000),
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, policy_code)
);

create index if not exists document_intake_status_idx on public.document_intake_items (tenant_id, status, created_at desc, id);
create index if not exists document_anomalies_open_idx on public.document_anomalies (tenant_id, status, severity, created_at desc, id);
create index if not exists ai_policy_scope_action_idx on public.ai_policy_rules (tenant_id, scope, action, is_active, id);

create or replace function public.create_document_intake(
  p_source_type text,
  p_source_id uuid,
  p_storage_path text,
  p_file_name text,
  p_mime_type text,
  p_sha256 text default null
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageCrm','manageInvoices','manageBills','manageAccounting','manageSettings']) then raise exception 'Document intake permission required'; end if;
  if p_source_type not in ('invoice', 'bill', 'receipt', 'bank_statement', 'other')
     or p_storage_path is null or length(btrim(p_storage_path)) not between 1 and 500
     or p_file_name is null or length(btrim(p_file_name)) not between 1 and 240
     or p_mime_type is null or length(btrim(p_mime_type)) not between 1 and 120
     or (p_sha256 is not null and p_sha256 !~ '^[A-Fa-f0-9]{64}$') then raise exception 'Document intake metadata is invalid'; end if;
  insert into public.document_intake_items (tenant_id, source_type, source_id, storage_path, file_name, mime_type, sha256, created_by)
  values (v_tenant_id, p_source_type, p_source_id, btrim(p_storage_path), btrim(p_file_name), btrim(p_mime_type), lower(p_sha256), auth.uid()) returning id into v_id;
  return jsonb_build_object('id', v_id, 'status', 'received', 'storage_path', p_storage_path);
end;
$$;

create or replace function public.record_document_extraction_draft(
  p_document_id uuid,
  p_provider text,
  p_version text,
  p_extracted_data jsonb
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
  v_data jsonb := coalesce(p_extracted_data, '{}'::jsonb);
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageCrm','manageInvoices','manageBills','manageAccounting','manageSettings']) then raise exception 'Document extraction permission required'; end if;
  if p_document_id is null or p_provider is null or length(btrim(p_provider)) not between 1 and 120 or jsonb_typeof(v_data) <> 'object' then raise exception 'Document extraction draft is invalid'; end if;
  update public.document_intake_items
  set status = 'extracted_draft', extraction_provider = btrim(p_provider), extraction_version = nullif(btrim(p_version), ''), extracted_data = v_data
  where id = p_document_id and tenant_id = v_tenant_id and status in ('received', 'extracted_draft')
  returning id into v_id;
  if not found then raise exception 'Document intake item was not found or is not editable'; end if;
  return jsonb_build_object('id', v_id, 'status', 'extracted_draft', 'review_required', true);
end;
$$;

create or replace function public.run_document_anomaly_rules(p_document_id uuid)
returns table(anomaly_id uuid, rule_code text, severity text, message text, evidence jsonb)
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_document public.document_intake_items;
  v_total text;
  v_currency text;
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  select * into v_document from public.document_intake_items where id = p_document_id and tenant_id = v_tenant_id;
  if not found then raise exception 'Document intake item was not found'; end if;
  delete from public.document_anomalies where document_id = p_document_id and tenant_id = v_tenant_id and status = 'open';
  if v_document.status <> 'extracted_draft' then
    insert into public.document_anomalies (tenant_id, document_id, rule_code, severity, message, evidence)
    values (v_tenant_id, p_document_id, 'EXTRACTION_NOT_REVIEWED', 'medium', 'Extraction is not available for review.', jsonb_build_object('status', v_document.status));
  end if;
  if coalesce(v_document.extracted_data->>'total_minor', '') <> '' then
    v_total := v_document.extracted_data->>'total_minor';
    if v_total !~ '^[0-9]+$' then
      insert into public.document_anomalies (tenant_id, document_id, rule_code, severity, message, evidence)
      values (v_tenant_id, p_document_id, 'INVALID_TOTAL_MINOR', 'high', 'Extracted total is not a non-negative integer minor-unit amount.', jsonb_build_object('value', v_total));
    end if;
  else
    insert into public.document_anomalies (tenant_id, document_id, rule_code, severity, message)
    values (v_tenant_id, p_document_id, 'MISSING_TOTAL', 'medium', 'Extracted document total is missing.');
  end if;
  v_currency := v_document.extracted_data->>'currency_code';
  if v_currency is not null and v_currency !~ '^[A-Z]{3,5}$' then
    insert into public.document_anomalies (tenant_id, document_id, rule_code, severity, message, evidence)
    values (v_tenant_id, p_document_id, 'INVALID_CURRENCY', 'high', 'Extracted currency code is not a supported uppercase ISO-like code.', jsonb_build_object('value', v_currency));
  end if;
  return query select a.id, a.rule_code, a.severity, a.message, a.evidence from public.document_anomalies a where a.document_id = p_document_id and a.tenant_id = v_tenant_id and a.status = 'open' order by a.severity desc, a.rule_code;
end;
$$;

create or replace function public.retrieve_ai_policy_context(
  p_scope text,
  p_action text
)
returns table(policy_code text, scope text, action text, policy_text text)
language sql stable security definer set search_path = public
as $$
  select p.policy_code, p.scope, p.action, p.policy_text
  from public.ai_policy_rules p
  where p.tenant_id = public.current_tenant_id() and p.is_active
    and (p.scope = p_scope or p.scope = '*')
    and (p.action = p_action or p.action = '*')
  order by p.scope desc, p.action desc, p.policy_code;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['document_intake_items','document_anomalies','ai_policy_rules'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy document_intake_select on public.document_intake_items for select to authenticated using (public.is_tenant_member(tenant_id));
create policy document_anomalies_select on public.document_anomalies for select to authenticated using (public.is_tenant_member(tenant_id));
create policy ai_policy_rules_select on public.ai_policy_rules for select to authenticated using (public.is_tenant_member(tenant_id));

revoke all on function public.create_document_intake(text, uuid, text, text, text, text) from public, anon;
revoke all on function public.record_document_extraction_draft(uuid, text, text, jsonb) from public, anon;
revoke all on function public.run_document_anomaly_rules(uuid) from public, anon;
revoke all on function public.retrieve_ai_policy_context(text, text) from public, anon;
grant execute on function public.create_document_intake(text, uuid, text, text, text, text) to authenticated;
grant execute on function public.record_document_extraction_draft(uuid, text, text, jsonb) to authenticated;
grant execute on function public.run_document_anomaly_rules(uuid) to authenticated;
grant execute on function public.retrieve_ai_policy_context(text, text) to authenticated;
