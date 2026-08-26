-- Mizan reviewed extension registry.
-- This records declarative descriptors only. It does not execute uploaded code,
-- bypass RLS, post journals, delete records, or grant permissions.

create table if not exists public.erp_extensions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  extension_key text not null check (length(btrim(extension_key)) between 1 and 120),
  display_name text not null check (length(btrim(display_name)) between 1 and 160),
  version text not null check (length(btrim(version)) between 1 and 40),
  hook text not null check (hook in ('pre_validate', 'pre_save', 'post_save')),
  capabilities jsonb not null default '[]'::jsonb,
  configuration jsonb not null default '{}'::jsonb,
  status text not null default 'proposed' check (status in ('proposed', 'under_review', 'approved', 'suspended', 'rejected')),
  requested_by uuid not null references auth.users(id) on delete restrict,
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, extension_key, version),
  unique (tenant_id, id),
  check (jsonb_typeof(capabilities) = 'array'),
  check (jsonb_typeof(configuration) = 'object'),
  check ((status in ('approved', 'suspended') and reviewed_by is not null and reviewed_at is not null) or status in ('proposed', 'under_review', 'rejected'))
);

create index if not exists erp_extensions_status_idx
  on public.erp_extensions (tenant_id, status, hook, display_name, id);

create or replace function public.register_erp_extension(
  p_extension_key text,
  p_display_name text,
  p_version text,
  p_hook text,
  p_capabilities jsonb,
  p_configuration jsonb default '{}'::jsonb
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
  v_capability text;
  v_allowed text[] := array['read_customer_context','read_report_context','add_validation_hint','add_read_model_field','emit_notification_intent'];
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageSettings']) then raise exception 'Extension management permission required'; end if;
  if p_extension_key is null or length(btrim(p_extension_key)) not between 1 and 120
     or p_display_name is null or length(btrim(p_display_name)) not between 1 and 160
     or p_version is null or length(btrim(p_version)) not between 1 and 40
     or p_hook not in ('pre_validate', 'pre_save', 'post_save')
     or p_capabilities is null or jsonb_typeof(p_capabilities) <> 'array'
     or p_configuration is null or jsonb_typeof(p_configuration) <> 'object' then
    raise exception 'Extension descriptor is invalid';
  end if;
  for v_capability in select value #>> '{}' from jsonb_array_elements(p_capabilities) loop
    if v_capability <> all(v_allowed) then raise exception 'Extension capability is not allowed: %', v_capability; end if;
  end loop;
  insert into public.erp_extensions (tenant_id, extension_key, display_name, version, hook, capabilities, configuration, requested_by)
  values (v_tenant_id, btrim(p_extension_key), btrim(p_display_name), btrim(p_version), p_hook, p_capabilities, p_configuration, auth.uid())
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'status', 'proposed', 'review_required', true);
end;
$$;

create or replace function public.review_erp_extension(
  p_extension_id uuid,
  p_status text,
  p_review_note text
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null or not public.is_tenant_owner(v_tenant_id) then raise exception 'Only the tenant owner can review extensions'; end if;
  if p_status not in ('approved', 'suspended', 'rejected') or p_review_note is null or length(btrim(p_review_note)) not between 1 and 500 then raise exception 'Extension review is invalid'; end if;
  update public.erp_extensions
  set status = p_status, reviewed_by = auth.uid(), reviewed_at = timezone('utc', now()), review_note = btrim(p_review_note)
  where id = p_extension_id and tenant_id = v_tenant_id and status in ('proposed', 'under_review', 'approved', 'suspended')
  returning id into v_id;
  if not found then raise exception 'Extension was not found or cannot be reviewed'; end if;
  return jsonb_build_object('id', v_id, 'status', p_status, 'reviewed_at', timezone('utc', now()));
end;
$$;

create or replace function public.list_erp_extensions(p_hook text default null)
returns table(id uuid, extension_key text, display_name text, version text, hook text, capabilities jsonb, configuration jsonb, status text, reviewed_at timestamptz)
language sql stable security definer set search_path = public
as $$
  select e.id, e.extension_key, e.display_name, e.version, e.hook, e.capabilities, e.configuration, e.status, e.reviewed_at
  from public.erp_extensions e
  where e.tenant_id = public.current_tenant_id()
    and (p_hook is null or e.hook = p_hook)
  order by e.display_name, e.version desc;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['erp_extensions'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy erp_extensions_select on public.erp_extensions for select to authenticated using (public.is_tenant_member(tenant_id));

revoke all on function public.register_erp_extension(text, text, text, text, jsonb, jsonb) from public, anon;
revoke all on function public.review_erp_extension(uuid, text, text) from public, anon;
revoke all on function public.list_erp_extensions(text) from public, anon;
grant execute on function public.register_erp_extension(text, text, text, text, jsonb, jsonb) to authenticated;
grant execute on function public.review_erp_extension(uuid, text, text) to authenticated;
grant execute on function public.list_erp_extensions(text) to authenticated;
