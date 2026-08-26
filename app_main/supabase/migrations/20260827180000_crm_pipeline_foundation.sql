-- Mizan CRM pipeline foundation.
-- Additive only: leads, pipeline stages, opportunities, activities,
-- interaction history, tenant RLS, indexes, and audited stage transitions.

create table if not exists public.crm_pipeline_stages (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 120),
  sort_order integer not null check (sort_order >= 0),
  probability_percent numeric(5,2) not null default 0 check (probability_percent >= 0 and probability_percent <= 100),
  is_won boolean not null default false,
  is_lost boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, name),
  check (not (is_won and is_lost))
);

create unique index if not exists crm_pipeline_stage_order_idx
  on public.crm_pipeline_stages (tenant_id, sort_order) where is_active;

create table if not exists public.crm_leads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  display_name text not null check (length(btrim(display_name)) between 1 and 200),
  email text,
  phone text,
  company_name text,
  source text check (source is null or length(btrim(source)) between 1 and 80),
  status text not null default 'new' check (status in ('new', 'qualified', 'unqualified', 'converted', 'lost')),
  owner_staff_member_id uuid references public.staff_members(id) on delete set null,
  notes text,
  converted_customer_id uuid references public.customers(id) on delete set null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false,
  check (email is null or length(btrim(email)) between 3 and 320),
  check (phone is null or length(btrim(phone)) between 7 and 40)
);

create index if not exists crm_leads_search_idx
  on public.crm_leads (tenant_id, status, lower(display_name), id) where not is_deleted;
create index if not exists crm_leads_owner_idx
  on public.crm_leads (tenant_id, owner_staff_member_id, status, updated_at desc);

create table if not exists public.crm_opportunities (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  title text not null check (length(btrim(title)) between 1 and 240),
  lead_id uuid references public.crm_leads(id) on delete set null,
  customer_id uuid references public.customers(id) on delete set null,
  stage_id uuid not null references public.crm_pipeline_stages(id) on delete restrict,
  owner_staff_member_id uuid references public.staff_members(id) on delete set null,
  amount_minor bigint not null default 0 check (amount_minor >= 0),
  currency_code text not null default 'USD' check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  expected_close_on date,
  status text not null default 'open' check (status in ('open', 'won', 'lost', 'cancelled')),
  probability_percent numeric(5,2) not null default 0 check (probability_percent >= 0 and probability_percent <= 100),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false
);

create index if not exists crm_opportunities_pipeline_idx
  on public.crm_opportunities (tenant_id, stage_id, status, expected_close_on, id) where not is_deleted;
create index if not exists crm_opportunities_owner_idx
  on public.crm_opportunities (tenant_id, owner_staff_member_id, status, updated_at desc);
create index if not exists crm_opportunities_customer_idx
  on public.crm_opportunities (tenant_id, customer_id, status, updated_at desc);

create table if not exists public.crm_activities (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  activity_type text not null check (activity_type in ('call', 'email', 'meeting', 'task', 'note', 'follow_up')),
  subject text not null check (length(btrim(subject)) between 1 and 240),
  body text,
  lead_id uuid references public.crm_leads(id) on delete cascade,
  opportunity_id uuid references public.crm_opportunities(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete cascade,
  owner_staff_member_id uuid references public.staff_members(id) on delete set null,
  due_at timestamptz,
  completed_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false,
  check (num_nonnulls(lead_id, opportunity_id, customer_id) >= 1)
);

create index if not exists crm_activities_due_idx
  on public.crm_activities (tenant_id, owner_staff_member_id, due_at, completed_at) where not is_deleted;
create index if not exists crm_activities_lead_idx
  on public.crm_activities (tenant_id, lead_id, created_at desc) where not is_deleted;
create index if not exists crm_activities_opportunity_idx
  on public.crm_activities (tenant_id, opportunity_id, created_at desc) where not is_deleted;
create index if not exists crm_activities_customer_idx
  on public.crm_activities (tenant_id, customer_id, created_at desc) where not is_deleted;

create table if not exists public.crm_interactions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  entity_type text not null check (entity_type in ('lead', 'customer', 'vendor', 'opportunity')),
  entity_id uuid not null,
  channel text not null check (channel in ('phone', 'email', 'sms', 'whatsapp', 'meeting', 'note', 'other')),
  direction text not null default 'outbound' check (direction in ('inbound', 'outbound', 'internal')),
  summary text not null check (length(btrim(summary)) between 1 and 500),
  occurred_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists crm_interactions_entity_idx
  on public.crm_interactions (tenant_id, entity_type, entity_id, occurred_at desc, id);

create or replace function public.validate_crm_tenant_references()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_table_name = 'crm_opportunities' then
    if new.lead_id is not null and not exists (select 1 from public.crm_leads l where l.id = new.lead_id and l.tenant_id = new.tenant_id) then raise exception 'CRM lead tenant is invalid'; end if;
    if new.customer_id is not null and not exists (select 1 from public.customers c where c.id = new.customer_id and c.tenant_id = new.tenant_id) then raise exception 'CRM customer tenant is invalid'; end if;
    if not exists (select 1 from public.crm_pipeline_stages ps where ps.id = new.stage_id and ps.tenant_id = new.tenant_id) then raise exception 'CRM pipeline stage tenant is invalid'; end if;
    if new.owner_staff_member_id is not null and not exists (select 1 from public.staff_members sm where sm.id = new.owner_staff_member_id and sm.tenant_id = new.tenant_id) then raise exception 'CRM owner tenant is invalid'; end if;
  elsif tg_table_name = 'crm_activities' then
    if new.lead_id is not null and not exists (select 1 from public.crm_leads l where l.id = new.lead_id and l.tenant_id = new.tenant_id) then raise exception 'CRM lead tenant is invalid'; end if;
    if new.opportunity_id is not null and not exists (select 1 from public.crm_opportunities o where o.id = new.opportunity_id and o.tenant_id = new.tenant_id) then raise exception 'CRM opportunity tenant is invalid'; end if;
    if new.customer_id is not null and not exists (select 1 from public.customers c where c.id = new.customer_id and c.tenant_id = new.tenant_id) then raise exception 'CRM customer tenant is invalid'; end if;
    if new.owner_staff_member_id is not null and not exists (select 1 from public.staff_members sm where sm.id = new.owner_staff_member_id and sm.tenant_id = new.tenant_id) then raise exception 'CRM owner tenant is invalid'; end if;
  end if;
  return new;
end;
$$;

drop trigger if exists crm_opportunities_tenant_refs on public.crm_opportunities;
create trigger crm_opportunities_tenant_refs before insert or update on public.crm_opportunities
for each row execute function public.validate_crm_tenant_references();
drop trigger if exists crm_activities_tenant_refs on public.crm_activities;
create trigger crm_activities_tenant_refs before insert or update on public.crm_activities
for each row execute function public.validate_crm_tenant_references();

revoke all on function public.validate_crm_tenant_references() from public, anon, authenticated;

create or replace function public.transition_crm_opportunity(
  p_opportunity_id uuid,
  p_stage_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_opportunity public.crm_opportunities;
  v_stage public.crm_pipeline_stages;
  v_status text;
begin
  if v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageCrm','manageCustomers','manageSettings']) then raise exception 'CRM permission required'; end if;
  select * into v_opportunity from public.crm_opportunities where id = p_opportunity_id and tenant_id = v_tenant_id and not is_deleted for update;
  if not found then raise exception 'Opportunity was not found'; end if;
  select * into v_stage from public.crm_pipeline_stages where id = p_stage_id and tenant_id = v_tenant_id and is_active;
  if not found then raise exception 'Pipeline stage is invalid'; end if;
  v_status := case when v_stage.is_won then 'won' when v_stage.is_lost then 'lost' else 'open' end;
  update public.crm_opportunities set stage_id = v_stage.id, status = v_status, probability_percent = v_stage.probability_percent where id = v_opportunity.id;
  if nullif(btrim(p_note), '') is not null then
    insert into public.crm_interactions (tenant_id, entity_type, entity_id, channel, direction, summary, created_by)
    values (v_tenant_id, 'opportunity', v_opportunity.id, 'note', 'internal', btrim(p_note), (select auth.uid()));
  end if;
  return jsonb_build_object('id', v_opportunity.id, 'stage_id', v_stage.id, 'stage_name', v_stage.name, 'status', v_status, 'probability_percent', v_stage.probability_percent);
end;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['crm_pipeline_stages','crm_leads','crm_opportunities','crm_activities','crm_interactions'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy crm_pipeline_stages_select on public.crm_pipeline_stages for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy crm_pipeline_stages_write on public.crm_pipeline_stages for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageSettings']));
create policy crm_leads_select on public.crm_leads for select to authenticated
using (public.is_tenant_member(tenant_id) and not is_deleted);
create policy crm_leads_write on public.crm_leads for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']));
create policy crm_opportunities_select on public.crm_opportunities for select to authenticated
using (public.is_tenant_member(tenant_id) and not is_deleted);
create policy crm_opportunities_write on public.crm_opportunities for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']));
create policy crm_activities_select on public.crm_activities for select to authenticated
using (public.is_tenant_member(tenant_id) and not is_deleted);
create policy crm_activities_write on public.crm_activities for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']));
create policy crm_interactions_select on public.crm_interactions for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy crm_interactions_write on public.crm_interactions for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']));

grant select, insert, update, delete on public.crm_pipeline_stages, public.crm_leads, public.crm_opportunities, public.crm_activities, public.crm_interactions to authenticated;
revoke all on function public.transition_crm_opportunity(uuid,uuid,text) from public, anon, authenticated;
grant execute on function public.transition_crm_opportunity(uuid,uuid,text) to authenticated;
