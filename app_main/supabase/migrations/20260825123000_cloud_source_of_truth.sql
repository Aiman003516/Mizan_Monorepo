-- Mizan cloud source of truth: tenants, identity, RBAC, CRM, documents, and audit.
-- This migration is intentionally additive and uses stable text status values so the
-- Flutter client can evolve without destructive enum changes.

create extension if not exists pgcrypto;

create table if not exists public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(btrim(name)) between 1 and 200),
  tax_id text,
  phone text,
  owner_uid uuid not null references auth.users(id) on delete restrict,
  subscription_status text not null default 'trial'
    check (subscription_status in ('trial', 'active', 'past_due', 'cancelled', 'offline')),
  currency_code text not null default 'USD'
    check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  tenant_id uuid references public.tenants(id) on delete set null,
  email text,
  display_name text check (display_name is null or length(btrim(display_name)) between 1 and 200),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 100),
  permissions jsonb not null default '[]'::jsonb,
  is_system_admin boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, id)
);

create unique index if not exists roles_tenant_name_unique_idx
  on public.roles (tenant_id, lower(name));

create table if not exists public.staff_members (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references public.user_profiles(id) on delete cascade,
  role_id uuid not null,
  status text not null default 'active'
    check (status in ('active', 'suspended', 'removed')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, user_id),
  foreign key (tenant_id, role_id) references public.roles(tenant_id, id) on delete restrict
);

create table if not exists public.invites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  role_id uuid not null,
  code text not null unique check (code ~ '^[0-9]{6}$'),
  created_by uuid not null references auth.users(id) on delete restrict,
  expires_at timestamptz not null,
  is_used boolean not null default false,
  used_by uuid references auth.users(id) on delete set null,
  used_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  foreign key (tenant_id, role_id) references public.roles(tenant_id, id) on delete restrict
);

create table if not exists public.currencies (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  code text not null check (code = upper(code) and length(code) between 3 and 5),
  name text not null check (length(btrim(name)) between 1 and 100),
  symbol text,
  is_default boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, code)
);

create unique index if not exists currencies_one_default_per_tenant_idx
  on public.currencies (tenant_id) where is_default;

create table if not exists public.custom_fields (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  target_table text not null check (target_table in ('products', 'accounts', 'transactions', 'customers', 'vendors')),
  key text not null check (key ~ '^[a-z][a-z0-9_]{0,62}$'),
  label text not null check (length(btrim(label)) between 1 and 120),
  data_type text not null default 'text' check (data_type in ('text', 'number', 'boolean', 'date')),
  is_required boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, target_table, key)
);

create index if not exists custom_fields_tenant_target_idx
  on public.custom_fields (tenant_id, target_table, lower(label));

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 200),
  email text,
  phone text,
  address text,
  tax_id text,
  credit_limit bigint not null default 0 check (credit_limit >= 0),
  balance bigint not null default 0,
  is_on_hold boolean not null default false,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false
);

create index if not exists customers_tenant_name_idx
  on public.customers (tenant_id, lower(name), id) where not is_deleted;
create index if not exists customers_tenant_email_idx
  on public.customers (tenant_id, lower(email)) where email is not null and not is_deleted;
create index if not exists customers_tenant_updated_idx
  on public.customers (tenant_id, updated_at desc, id);

create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  name text not null check (length(btrim(name)) between 1 and 200),
  email text,
  phone text,
  address text,
  tax_id text,
  balance bigint not null default 0,
  payment_terms text,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  is_deleted boolean not null default false
);

create index if not exists vendors_tenant_name_idx
  on public.vendors (tenant_id, lower(name), id) where not is_deleted;
create index if not exists vendors_tenant_email_idx
  on public.vendors (tenant_id, lower(email)) where email is not null and not is_deleted;
create index if not exists vendors_tenant_updated_idx
  on public.vendors (tenant_id, updated_at desc, id);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete restrict,
  invoice_number text not null,
  invoice_date date not null,
  due_date date not null,
  subtotal bigint not null default 0 check (subtotal >= 0),
  tax_amount bigint not null default 0 check (tax_amount >= 0),
  total_amount bigint not null default 0 check (total_amount = subtotal + tax_amount),
  amount_paid bigint not null default 0 check (amount_paid >= 0 and amount_paid <= total_amount),
  status text not null default 'draft'
    check (status in ('draft', 'sent', 'partial', 'paid', 'overdue', 'void')),
  currency_code text not null default 'USD'
    check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, invoice_number),
  check (due_date >= invoice_date)
);

create index if not exists invoices_tenant_customer_date_idx
  on public.invoices (tenant_id, customer_id, invoice_date desc, id);
create index if not exists invoices_tenant_status_due_idx
  on public.invoices (tenant_id, status, due_date, id);
create index if not exists invoices_tenant_updated_idx
  on public.invoices (tenant_id, updated_at desc, id);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null check (length(btrim(description)) between 1 and 500),
  quantity numeric(18, 6) not null check (quantity > 0),
  unit_price bigint not null check (unit_price >= 0),
  amount bigint not null check (amount = round(quantity * unit_price)),
  product_id uuid,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists invoice_items_tenant_invoice_idx
  on public.invoice_items (tenant_id, invoice_id, id);

create table if not exists public.bills (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete restrict,
  bill_number text not null,
  vendor_bill_number text,
  bill_date date not null,
  due_date date not null,
  subtotal bigint not null default 0 check (subtotal >= 0),
  tax_amount bigint not null default 0 check (tax_amount >= 0),
  total_amount bigint not null default 0 check (total_amount = subtotal + tax_amount),
  amount_paid bigint not null default 0 check (amount_paid >= 0 and amount_paid <= total_amount),
  status text not null default 'pending'
    check (status in ('pending', 'partial', 'paid', 'overdue', 'void')),
  currency_code text not null default 'USD'
    check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, bill_number),
  check (due_date >= bill_date)
);

create index if not exists bills_tenant_vendor_date_idx
  on public.bills (tenant_id, vendor_id, bill_date desc, id);
create index if not exists bills_tenant_status_due_idx
  on public.bills (tenant_id, status, due_date, id);
create index if not exists bills_tenant_updated_idx
  on public.bills (tenant_id, updated_at desc, id);

create table if not exists public.bill_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  bill_id uuid not null references public.bills(id) on delete cascade,
  description text not null check (length(btrim(description)) between 1 and 500),
  quantity numeric(18, 6) not null check (quantity > 0),
  unit_price bigint not null check (unit_price >= 0),
  amount bigint not null check (amount = round(quantity * unit_price)),
  product_id uuid,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists bill_items_tenant_bill_idx
  on public.bill_items (tenant_id, bill_id, id);

create table if not exists public.audit_logs (
  id bigint generated always as identity primary key,
  tenant_id uuid references public.tenants(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  target_table text not null,
  record_id uuid,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists audit_logs_tenant_created_idx
  on public.audit_logs (tenant_id, created_at desc, id);
create index if not exists audit_logs_tenant_target_idx
  on public.audit_logs (tenant_id, target_table, record_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.prevent_tenant_owner_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.owner_uid is distinct from old.owner_uid then
    raise exception 'Tenant ownership cannot be changed through the client';
  end if;
  return new;
end;
$$;

drop trigger if exists tenants_owner_immutable on public.tenants;
create trigger tenants_owner_immutable
before update on public.tenants
for each row execute function public.prevent_tenant_owner_change();

-- Backward-compatible upgrades for the existing cloud schema. The first
-- deployment may already contain the identity/RBAC tables from the legacy
-- sync layer, so CREATE TABLE IF NOT EXISTS alone is not sufficient.
do $$
begin
  alter table public.tenants add column if not exists owner_uid uuid;
  alter table public.tenants add column if not exists currency_code text not null default 'USD';
  alter table public.tenants add column if not exists updated_at timestamptz not null default timezone('utc', now());
  alter table public.user_profiles add column if not exists tenant_id uuid;
  alter table public.user_profiles add column if not exists email text;
  alter table public.user_profiles add column if not exists full_name text;
  alter table public.user_profiles add column if not exists display_name text;
  alter table public.user_profiles add column if not exists updated_at timestamptz not null default timezone('utc', now());
  alter table public.roles add column if not exists tenant_id uuid;
  alter table public.roles add column if not exists permissions jsonb not null default '[]'::jsonb;
  alter table public.roles add column if not exists is_system_admin boolean not null default false;
  alter table public.roles add column if not exists created_by uuid;
  alter table public.roles add column if not exists updated_at timestamptz not null default timezone('utc', now());
  alter table public.staff_members add column if not exists tenant_id uuid;
  alter table public.staff_members add column if not exists user_id uuid;
  alter table public.staff_members add column if not exists role_id uuid;
  alter table public.staff_members add column if not exists status text not null default 'active';
  alter table public.staff_members add column if not exists created_at timestamptz not null default timezone('utc', now());
  alter table public.staff_members add column if not exists updated_at timestamptz not null default timezone('utc', now());
  alter table public.invites add column if not exists tenant_id uuid;
  alter table public.invites add column if not exists role_id uuid;
  alter table public.invites add column if not exists email text;
  alter table public.invites add column if not exists code_hash text;
  alter table public.invites add column if not exists created_by uuid;
  alter table public.invites add column if not exists status text not null default 'pending';
  alter table public.invites add column if not exists is_used boolean not null default false;
  alter table public.invites add column if not exists used_by uuid;
  alter table public.invites add column if not exists used_at timestamptz;
  alter table public.invites add column if not exists expires_at timestamptz not null default timezone('utc', now()) + interval '7 days';
  alter table public.invites add column if not exists accepted_at timestamptz;
  alter table public.invites add column if not exists invited_by uuid;
  alter table public.invites add column if not exists created_at timestamptz not null default timezone('utc', now());
  alter table public.invites add column if not exists updated_at timestamptz not null default timezone('utc', now());

  if exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'tenants' and column_name = 'owner_id') then
    execute 'update public.tenants set owner_uid = nullif(owner_id::text, '''')::uuid where owner_uid is null and owner_id::text ~ ''^[0-9a-fA-F-]{36}$''';
  end if;
  create index if not exists staff_members_user_tenant_idx
    on public.staff_members (user_id, tenant_id, status);
  create index if not exists staff_members_tenant_role_idx
    on public.staff_members (tenant_id, role_id, status);
  create index if not exists invites_tenant_expiry_idx
    on public.invites (tenant_id, expires_at, is_used);
  create index if not exists invites_code_lookup_idx
    on public.invites (code, is_used, expires_at);
end;
$$;

create or replace function public.is_tenant_member(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.staff_members sm
    where sm.tenant_id = p_tenant_id
      and sm.user_id = (select auth.uid())
      and sm.status = 'active'
  );
$$;

create or replace function public.has_tenant_permission(p_tenant_id uuid, p_permissions text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.staff_members sm
    join public.roles r on r.id = sm.role_id and r.tenant_id = sm.tenant_id
    where sm.tenant_id = p_tenant_id
      and sm.user_id = (select auth.uid())
      and sm.status = 'active'
      and (
        r.is_system_admin
        or exists (
          select 1
          from unnest(p_permissions) required_permission
          where required_permission in (
            select jsonb_array_elements_text(
              case
                when jsonb_typeof(r.permissions) = 'array' then r.permissions
                when jsonb_typeof(r.permissions) = 'object' then coalesce(
                  (
                    select jsonb_agg(permission_name)
                    from jsonb_object_keys(r.permissions) as permission_name
                    where (r.permissions -> permission_name) = 'true'::jsonb
                  ),
                  '[]'::jsonb
                )
                else '[]'::jsonb
              end
            )
          )
        )
      )
  );
$$;

create or replace function public.audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.audit_logs (tenant_id, user_id, action, target_table, record_id, old_data, new_data)
  values (
    coalesce((to_jsonb(new)->>'tenant_id')::uuid, (to_jsonb(old)->>'tenant_id')::uuid),
    (select auth.uid()),
    tg_op,
    tg_table_name,
    coalesce((to_jsonb(new)->>'id')::uuid, (to_jsonb(old)->>'id')::uuid),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) else null end
  );
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function public.prevent_system_admin_mutation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.is_system_admin and (tg_op = 'DELETE' or new.is_system_admin is distinct from old.is_system_admin or new.name is distinct from old.name or new.permissions is distinct from old.permissions) then
    raise exception 'System administrator role cannot be modified';
  end if;
  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create or replace function public.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (id, email, display_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'))
  on conflict (id) do update set email = excluded.email;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.create_profile_for_new_user();

-- Standardized timestamp and audit triggers.
do $$
declare
  t text;
begin
  foreach t in array array['tenants','user_profiles','roles','staff_members','invites','currencies','custom_fields','customers','vendors','invoices','invoice_items','bills','bill_items'] loop
    execute format('drop trigger if exists %I_updated_at on public.%I', t, t);
    execute format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
  end loop;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['tenants','roles','staff_members','invites','currencies','custom_fields','customers','vendors','invoices','invoice_items','bills','bill_items'] loop
    execute format('drop trigger if exists %I_audit on public.%I', t, t);
    execute format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
  end loop;
end;
$$;

drop trigger if exists roles_protect_system_admin on public.roles;
create trigger roles_protect_system_admin
before update or delete on public.roles
for each row execute function public.prevent_system_admin_mutation();

-- Seed a default currency per tenant when the first profile-driven business is created
-- is handled by the application/business-creation transaction; this prevents global
-- seed rows from leaking across tenants.

-- RLS: every exposed table is protected, and client grants are explicit.
do $$
declare
  t text;
begin
  foreach t in array array['tenants','user_profiles','roles','staff_members','invites','currencies','custom_fields','customers','vendors','invoices','invoice_items','bills','bill_items','audit_logs'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon, authenticated', t);
  end loop;
end;
$$;

grant select, insert, update on public.tenants to authenticated;
grant select, update on public.user_profiles to authenticated;
grant select, insert, update, delete on public.roles to authenticated;
grant select, insert, update, delete on public.staff_members to authenticated;
grant select, insert, update on public.invites to authenticated;
grant select, insert, update, delete on public.currencies to authenticated;
grant select, insert, update, delete on public.custom_fields to authenticated;
grant select, insert, update on public.customers to authenticated;
grant select, insert, update on public.vendors to authenticated;
grant select, insert, update on public.invoices to authenticated;
grant select, insert, update on public.invoice_items to authenticated;
grant select, insert, update on public.bills to authenticated;
grant select, insert, update on public.bill_items to authenticated;
grant select on public.audit_logs to authenticated;

drop policy if exists tenants_select on public.tenants;
create policy tenants_select on public.tenants for select to authenticated
using (public.is_tenant_member(id) or owner_uid = (select auth.uid()));
drop policy if exists tenants_insert on public.tenants;
create policy tenants_insert on public.tenants for insert to authenticated
with check (owner_uid = (select auth.uid()));
drop policy if exists tenants_update on public.tenants;
create policy tenants_update on public.tenants for update to authenticated
using (owner_uid = (select auth.uid()) or public.has_tenant_permission(id, array['manageSettings']))
with check (owner_uid = (select auth.uid()) or public.has_tenant_permission(id, array['manageSettings']));

create policy user_profiles_select on public.user_profiles for select to authenticated
using (id = (select auth.uid()) or (tenant_id is not null and public.is_tenant_member(tenant_id)));
create policy user_profiles_update on public.user_profiles for update to authenticated
using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy roles_select on public.roles for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy roles_insert on public.roles for insert to authenticated
with check (not is_system_admin and public.has_tenant_permission(tenant_id, array['manageSettings','manageStaff']));
create policy roles_update on public.roles for update to authenticated
using (public.has_tenant_permission(tenant_id, array['manageSettings','manageStaff']))
with check (not is_system_admin and public.has_tenant_permission(tenant_id, array['manageSettings','manageStaff']));
create policy roles_delete on public.roles for delete to authenticated
using (not is_system_admin and public.has_tenant_permission(tenant_id, array['manageSettings','manageStaff']));

create policy staff_members_select on public.staff_members for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy staff_members_insert on public.staff_members for insert to authenticated
with check (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));
create policy staff_members_update on public.staff_members for update to authenticated
using (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));
create policy staff_members_delete on public.staff_members for delete to authenticated
using (not exists (select 1 from public.tenants t where t.id = tenant_id and t.owner_uid = user_id)
  and public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));

create policy invites_select on public.invites for select to authenticated
using (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));
create policy invites_insert on public.invites for insert to authenticated
with check (created_by = (select auth.uid()) and public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));
create policy invites_update on public.invites for update to authenticated
using (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageStaff','manageSettings']));

create policy currencies_select on public.currencies for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy currencies_write on public.currencies for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageSettings']));

create policy custom_fields_select on public.custom_fields for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy custom_fields_write on public.custom_fields for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageSettings']));

create policy customers_select on public.customers for select to authenticated
using (public.is_tenant_member(tenant_id) and not is_deleted);
create policy customers_write on public.customers for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageCustomers','manageSettings']));

create policy vendors_select on public.vendors for select to authenticated
using (public.is_tenant_member(tenant_id) and not is_deleted);
create policy vendors_write on public.vendors for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','manageVendors','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','manageVendors','manageSettings']));

create policy invoices_select on public.invoices for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy invoices_write on public.invoices for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','createInvoices','manageInvoices','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','createInvoices','manageInvoices','manageSettings'])
  and exists (select 1 from public.customers c where c.id = customer_id and c.tenant_id = tenant_id));

create policy invoice_items_select on public.invoice_items for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy invoice_items_write on public.invoice_items for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','createInvoices','manageInvoices','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','createInvoices','manageInvoices','manageSettings'])
  and exists (select 1 from public.invoices i where i.id = invoice_id and i.tenant_id = tenant_id));

create policy bills_select on public.bills for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy bills_write on public.bills for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','createBills','manageBills','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','createBills','manageBills','manageSettings'])
  and exists (select 1 from public.vendors v where v.id = vendor_id and v.tenant_id = tenant_id));

create policy bill_items_select on public.bill_items for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy bill_items_write on public.bill_items for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageCrm','createBills','manageBills','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageCrm','createBills','manageBills','manageSettings'])
  and exists (select 1 from public.bills b where b.id = bill_id and b.tenant_id = tenant_id));

create policy audit_logs_select on public.audit_logs for select to authenticated
using (tenant_id is not null and public.has_tenant_permission(tenant_id, array['manageSettings']));

revoke all on function public.set_updated_at() from public, anon, authenticated;
revoke all on function public.audit_row_change() from public, anon, authenticated;
revoke all on function public.prevent_tenant_owner_change() from public, anon, authenticated;
revoke all on function public.prevent_system_admin_mutation() from public, anon, authenticated;
grant execute on function public.is_tenant_member(uuid) to authenticated;
grant execute on function public.has_tenant_permission(uuid, text[]) to authenticated;

create or replace function public.create_business(
  p_name text,
  p_tax_id text default null,
  p_phone text default null,
  p_currency_code text default 'USD'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_role uuid;
  v_code text;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_name is null or length(btrim(p_name)) not between 1 and 200 then
    raise exception 'Business name is invalid';
  end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or length(p_currency_code) not between 3 and 5 then
    raise exception 'Currency code is invalid';
  end if;

  insert into public.tenants (name, tax_id, phone, owner_uid, currency_code)
  values (btrim(p_name), nullif(btrim(p_tax_id), ''), nullif(btrim(p_phone), ''), v_user, p_currency_code)
  returning id into v_tenant;

  insert into public.roles (tenant_id, name, permissions, is_system_admin, created_by)
  values (v_tenant, 'Owner', to_jsonb(array[
    'viewDashboard','viewFinancialReports','performSale','voidTransaction','processRefund',
    'viewSalesHistory','viewInventory','manageProducts','adjustInventory','manageStaff',
    'manageSettings','switchTenant','manageCrm','manageCustomers','manageVendors',
    'createInvoices','manageInvoices','createBills','manageBills'
  ]::text[]), true, v_user)
  returning id into v_role;

  insert into public.staff_members (tenant_id, user_id, role_id)
  values (v_tenant, v_user, v_role);

  insert into public.user_profiles (id, tenant_id, email, display_name)
  select v_user, v_tenant, u.email,
         coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', u.email)
  from auth.users u
  where u.id = v_user
  on conflict (id) do update set tenant_id = excluded.tenant_id, email = excluded.email;

  insert into public.currencies (tenant_id, code, name, symbol, is_default)
  values (v_tenant, p_currency_code, p_currency_code, null, true)
  on conflict (tenant_id, code) do update set is_default = true;

  return v_tenant;
end;
$$;

create or replace function public.create_invite(p_role_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_code text;
  v_expires timestamptz := timezone('utc', now()) + interval '24 hours';
begin
  select sm.tenant_id into v_tenant
  from public.staff_members sm
  where sm.user_id = v_user and sm.status = 'active'
  order by sm.created_at
  limit 1;

  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageStaff','manageSettings']) then
    raise exception 'Staff management permission required';
  end if;

  if not exists (select 1 from public.roles r where r.id = p_role_id and r.tenant_id = v_tenant) then
    raise exception 'Role does not belong to the current tenant';
  end if;

  loop
    v_code := lpad((floor(random() * 900000) + 100000)::bigint::text, 6, '0');
    exit when not exists (select 1 from public.invites i where i.code = v_code and not i.is_used and i.expires_at > timezone('utc', now()));
  end loop;

  insert into public.invites (tenant_id, role_id, code, created_by, expires_at)
  values (v_tenant, p_role_id, v_code, v_user, v_expires);
  return v_code;
end;
$$;

create or replace function public.redeem_invite(p_code text, p_display_name text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_invite public.invites;
  v_email text;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if p_code is null or p_code !~ '^[0-9]{6}$' then
    raise exception 'Invalid invite code';
  end if;

  select * into v_invite
  from public.invites i
  where i.code = p_code
    and not i.is_used
    and i.expires_at > timezone('utc', now())
  for update;

  if not found then
    raise exception 'Invalid or expired invite code';
  end if;

  select email into v_email from auth.users where id = v_user;
  insert into public.user_profiles (id, tenant_id, email, display_name)
  values (v_user, v_invite.tenant_id, v_email, nullif(btrim(p_display_name), ''))
  on conflict (id) do update set tenant_id = excluded.tenant_id, email = coalesce(excluded.email, user_profiles.email), display_name = coalesce(excluded.display_name, user_profiles.display_name);

  insert into public.staff_members (tenant_id, user_id, role_id)
  values (v_invite.tenant_id, v_user, v_invite.role_id)
  on conflict (tenant_id, user_id) do update set role_id = excluded.role_id, status = 'active', updated_at = timezone('utc', now());

  update public.invites
  set is_used = true, used_by = v_user, used_at = timezone('utc', now())
  where id = v_invite.id;

  return jsonb_build_object('tenant_id', v_invite.tenant_id, 'role_id', v_invite.role_id);
end;
$$;

revoke all on function public.create_business(text, text, text, text) from public, anon, authenticated;
revoke all on function public.create_invite(uuid) from public, anon, authenticated;
revoke all on function public.redeem_invite(text, text) from public, anon, authenticated;
grant execute on function public.create_business(text, text, text, text) to authenticated;
grant execute on function public.create_invite(uuid) to authenticated;
grant execute on function public.redeem_invite(text, text) to authenticated;

create or replace function public.validate_invite(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if p_code is null or p_code !~ '^[0-9]{6}$' then
    return null;
  end if;
  select jsonb_build_object(
    'role_id', i.role_id,
    'tenant_id', i.tenant_id,
    'expires_at', i.expires_at
  ) into v_result
  from public.invites i
  where i.code = p_code
    and not i.is_used
    and i.expires_at > timezone('utc', now());
  return v_result;
end;
$$;

revoke all on function public.validate_invite(text) from public, anon, authenticated;
grant execute on function public.validate_invite(text) to authenticated;

-- Existing Drift tables that are not yet normalized in the canonical cloud model
-- remain available through an explicit tenant-scoped envelope. This keeps the
-- offline cache uploadable while CRM and financial modules migrate table-by-table.
do $$
declare
  t text;
  remote_name text;
begin
  foreach t in array array[
    'transactions', 'products', 'accounts', 'transaction_entries',
    'orders', 'order_items', 'categories', 'inventory_cost_layers'
  ] loop
    remote_name := 'synced_' || t;
    execute format('create table if not exists public.%I (
      id text not null,
      tenant_id uuid not null references public.tenants(id) on delete cascade,
      data jsonb not null,
      last_updated timestamptz not null default timezone(''utc'', now()),
      is_deleted boolean not null default false,
      primary key (tenant_id, id)
    )', remote_name);
    execute format('create index if not exists %I on public.%I (tenant_id, last_updated desc, id)', remote_name || '_tenant_updated_idx', remote_name);
    execute format('create index if not exists %I on public.%I (tenant_id, is_deleted, last_updated desc)', remote_name || '_tenant_deleted_idx', remote_name);
    execute format('alter table public.%I enable row level security', remote_name);
    execute format('revoke all on table public.%I from anon, authenticated', remote_name);
    execute format('grant select, insert, update, delete on table public.%I to authenticated', remote_name);
    execute format('drop policy if exists tenant_read on public.%I', remote_name);
    execute format('create policy tenant_read on public.%I for select to authenticated using (public.is_tenant_member(tenant_id))', remote_name);
    execute format('drop policy if exists tenant_write on public.%I', remote_name);
    execute format('create policy tenant_write on public.%I for all to authenticated using (public.is_tenant_member(tenant_id)) with check (public.is_tenant_member(tenant_id))', remote_name);
  end loop;
end;
$$;

create or replace function public.activate_existing_business(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_role uuid;
  v_email text;
begin
  if v_user is null then
    raise exception 'Authentication required';
  end if;
  if not exists (select 1 from public.tenants where id = p_tenant_id and owner_uid = v_user) then
    raise exception 'Only the tenant owner can activate this business';
  end if;

  update public.tenants
  set subscription_status = 'active', updated_at = timezone('utc', now())
  where id = p_tenant_id;

  select email into v_email from auth.users where id = v_user;
  insert into public.user_profiles (id, tenant_id, email)
  values (v_user, p_tenant_id, v_email)
  on conflict (id) do update set tenant_id = excluded.tenant_id, email = coalesce(excluded.email, user_profiles.email);

  select id into v_role from public.roles
  where tenant_id = p_tenant_id and is_system_admin
  order by created_at
  limit 1;

  if v_role is null then
    insert into public.roles (tenant_id, name, permissions, is_system_admin, created_by)
    values (p_tenant_id, 'Owner', to_jsonb(array[
      'viewDashboard','viewFinancialReports','performSale','voidTransaction','processRefund',
      'viewSalesHistory','viewInventory','manageProducts','adjustInventory','manageStaff',
      'manageSettings','switchTenant','manageCrm','manageCustomers','manageVendors',
      'createInvoices','manageInvoices','createBills','manageBills','manageAccounting','postJournalEntries'
    ]::text[]), true, v_user)
    returning id into v_role;
  end if;

  insert into public.staff_members (tenant_id, user_id, role_id)
  values (p_tenant_id, v_user, v_role)
  on conflict (tenant_id, user_id) do update set role_id = excluded.role_id, status = 'active';
end;
$$;

revoke all on function public.activate_existing_business(uuid) from public, anon, authenticated;
grant execute on function public.activate_existing_business(uuid) to authenticated;

create or replace function public.create_invoice(
  p_customer_id uuid,
  p_invoice_date date,
  p_due_date date,
  p_currency_code text,
  p_notes text default null,
  p_items jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_invoice public.invoices;
  v_subtotal bigint;
  v_number text := 'INV-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
begin
  select sm.tenant_id into v_tenant
  from public.staff_members sm
  where sm.user_id = v_user and sm.status = 'active'
  order by sm.created_at
  limit 1;

  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageCrm','createInvoices','manageInvoices','manageSettings']) then
    raise exception 'Invoice creation permission required';
  end if;
  if not exists (select 1 from public.customers c where c.id = p_customer_id and c.tenant_id = v_tenant and not c.is_deleted) then
    raise exception 'Customer does not belong to the current tenant';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'At least one invoice item is required';
  end if;
  if p_due_date < p_invoice_date then
    raise exception 'Invoice due date cannot precede invoice date';
  end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or length(p_currency_code) not between 3 and 5 then
    raise exception 'Currency code is invalid';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) item
    where coalesce(length(btrim(item->>'description')), 0) = 0
      or coalesce((item->>'quantity')::numeric, 0) <= 0
      or coalesce((item->>'unit_price')::bigint, -1) < 0
  ) then
    raise exception 'Invoice item data is invalid';
  end if;

  select coalesce(sum(round((item->>'quantity')::numeric * (item->>'unit_price')::bigint)), 0)::bigint
  into v_subtotal
  from jsonb_array_elements(p_items) item;

  insert into public.invoices (
    tenant_id, customer_id, invoice_number, invoice_date, due_date,
    subtotal, tax_amount, total_amount, currency_code, notes, created_by
  ) values (
    v_tenant, p_customer_id, v_number, p_invoice_date, p_due_date,
    v_subtotal, 0, v_subtotal, p_currency_code, nullif(btrim(p_notes), ''), v_user
  ) returning * into v_invoice;

  insert into public.invoice_items (
    tenant_id, invoice_id, description, quantity, unit_price, amount, product_id
  )
  select
    v_tenant, v_invoice.id, btrim(item->>'description'), (item->>'quantity')::numeric,
    (item->>'unit_price')::bigint,
    round((item->>'quantity')::numeric * (item->>'unit_price')::bigint)::bigint,
    nullif(item->>'product_id', '')::uuid
  from jsonb_array_elements(p_items) item;

  return jsonb_build_object(
    'invoice', to_jsonb(v_invoice),
    'items', coalesce((select jsonb_agg(to_jsonb(ii)) from public.invoice_items ii where ii.invoice_id = v_invoice.id), '[]'::jsonb)
  );
end;
$$;

create or replace function public.create_bill(
  p_vendor_id uuid,
  p_bill_date date,
  p_due_date date,
  p_currency_code text,
  p_vendor_bill_number text default null,
  p_notes text default null,
  p_items jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := (select auth.uid());
  v_tenant uuid;
  v_bill public.bills;
  v_subtotal bigint;
  v_number text := 'BILL-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
begin
  select sm.tenant_id into v_tenant
  from public.staff_members sm
  where sm.user_id = v_user and sm.status = 'active'
  order by sm.created_at
  limit 1;

  if v_tenant is null or not public.has_tenant_permission(v_tenant, array['manageCrm','createBills','manageBills','manageSettings']) then
    raise exception 'Bill creation permission required';
  end if;
  if not exists (select 1 from public.vendors v where v.id = p_vendor_id and v.tenant_id = v_tenant and not v.is_deleted) then
    raise exception 'Vendor does not belong to the current tenant';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'At least one bill item is required';
  end if;
  if p_due_date < p_bill_date then
    raise exception 'Bill due date cannot precede bill date';
  end if;
  if p_currency_code is null or p_currency_code <> upper(p_currency_code) or length(p_currency_code) not between 3 and 5 then
    raise exception 'Currency code is invalid';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) item
    where coalesce(length(btrim(item->>'description')), 0) = 0
      or coalesce((item->>'quantity')::numeric, 0) <= 0
      or coalesce((item->>'unit_price')::bigint, -1) < 0
  ) then
    raise exception 'Bill item data is invalid';
  end if;

  select coalesce(sum(round((item->>'quantity')::numeric * (item->>'unit_price')::bigint)), 0)::bigint
  into v_subtotal
  from jsonb_array_elements(p_items) item;

  insert into public.bills (
    tenant_id, vendor_id, bill_number, bill_date, due_date,
    subtotal, tax_amount, total_amount, currency_code, vendor_bill_number, notes, created_by
  ) values (
    v_tenant, p_vendor_id, v_number, p_bill_date, p_due_date,
    v_subtotal, 0, v_subtotal, p_currency_code,
    nullif(btrim(p_vendor_bill_number), ''), nullif(btrim(p_notes), ''), v_user
  ) returning * into v_bill;

  insert into public.bill_items (
    tenant_id, bill_id, description, quantity, unit_price, amount, product_id
  )
  select
    v_tenant, v_bill.id, btrim(item->>'description'), (item->>'quantity')::numeric,
    (item->>'unit_price')::bigint,
    round((item->>'quantity')::numeric * (item->>'unit_price')::bigint)::bigint,
    nullif(item->>'product_id', '')::uuid
  from jsonb_array_elements(p_items) item;

  return jsonb_build_object(
    'bill', to_jsonb(v_bill),
    'items', coalesce((select jsonb_agg(to_jsonb(bi)) from public.bill_items bi where bi.bill_id = v_bill.id), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.create_invoice(uuid, date, date, text, text, jsonb) from public, anon, authenticated;
revoke all on function public.create_bill(uuid, date, date, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.create_invoice(uuid, date, date, text, text, jsonb) to authenticated;
grant execute on function public.create_bill(uuid, date, date, text, text, text, jsonb) to authenticated;

create extension if not exists pg_trgm;
create index if not exists customers_tenant_name_trgm_idx
  on public.customers using gin (lower(name) gin_trgm_ops)
  where not is_deleted;
create index if not exists vendors_tenant_name_trgm_idx
  on public.vendors using gin (lower(name) gin_trgm_ops)
  where not is_deleted;
