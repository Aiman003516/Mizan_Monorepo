-- Mizan dimensional accounting, parallel books, and exchange-rate provenance.
-- Additive only. Existing journal rows remain valid with leading/default values.

create table if not exists public.accounting_books (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  code text not null check (code = upper(btrim(code)) and length(btrim(code)) between 1 and 40),
  name text not null check (length(btrim(name)) between 1 and 160),
  book_type text not null default 'leading'
    check (book_type in ('leading', 'local', 'extension', 'simulation')),
  base_book_id uuid references public.accounting_books(id) on delete restrict,
  status text not null default 'active' check (status in ('active', 'archived')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, code),
  unique (tenant_id, id),
  check ((book_type = 'leading' and base_book_id is null) or book_type <> 'leading')
);

create index if not exists accounting_books_tenant_status_idx
  on public.accounting_books (tenant_id, status, book_type, code);

create table if not exists public.accounting_dimensions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  dimension_type text not null
    check (dimension_type in ('branch', 'cost_center', 'project', 'campaign', 'region', 'fund')),
  code text not null check (code = upper(btrim(code)) and length(btrim(code)) between 1 and 60),
  name text not null check (length(btrim(name)) between 1 and 160),
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, dimension_type, code),
  unique (tenant_id, id)
);

create index if not exists accounting_dimensions_lookup_idx
  on public.accounting_dimensions (tenant_id, dimension_type, is_active, code);

alter table public.journal_entries
  add column if not exists book_id uuid,
  add column if not exists base_currency_code text,
  add column if not exists exchange_rate_source text,
  add column if not exists exchange_rate_effective_on date;

alter table public.journal_lines
  add column if not exists worktags jsonb not null default '{}'::jsonb;

update public.accounting_books
set base_book_id = null
where book_type = 'leading' and base_book_id is not null;

create index if not exists journal_entries_tenant_book_date_idx
  on public.journal_entries (tenant_id, book_id, entry_date, status, id);
create index if not exists journal_lines_worktags_gin_idx
  on public.journal_lines using gin (worktags);

create or replace function public.prevent_cross_tenant_accounting_book()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.book_id is not null and not exists (
    select 1 from public.accounting_books b
    where b.id = new.book_id and b.tenant_id = new.tenant_id and b.status = 'active'
  ) then
    raise exception 'Accounting book does not belong to the active tenant';
  end if;
  if new.base_currency_code is not null
     and (new.base_currency_code <> upper(new.base_currency_code)
       or length(new.base_currency_code) not between 3 and 5) then
    raise exception 'Base currency code is invalid';
  end if;
  if new.worktags is not null and jsonb_typeof(new.worktags) <> 'object' then
    raise exception 'Worktags must be a JSON object';
  end if;
  return new;
end;
$$;

drop trigger if exists journal_entry_book_dimensions_guard on public.journal_entries;
create trigger journal_entry_book_dimensions_guard
before insert or update on public.journal_entries
for each row execute function public.prevent_cross_tenant_accounting_book();

drop trigger if exists journal_line_worktags_guard on public.journal_lines;
create trigger journal_line_worktags_guard
before insert or update on public.journal_lines
for each row execute function public.prevent_cross_tenant_accounting_book();

create or replace function public.list_accounting_books()
returns table(id uuid, code text, name text, book_type text, base_book_id uuid, status text)
language sql
stable
security definer
set search_path = public
as $$
  select b.id, b.code, b.name, b.book_type, b.base_book_id, b.status
  from public.accounting_books b
  where b.tenant_id = public.current_tenant_id()
  order by b.book_type, b.code;
$$;

create or replace function public.list_accounting_dimensions(p_dimension_type text default null)
returns table(id uuid, dimension_type text, code text, name text, is_active boolean)
language sql
stable
security definer
set search_path = public
as $$
  select d.id, d.dimension_type, d.code, d.name, d.is_active
  from public.accounting_dimensions d
  where d.tenant_id = public.current_tenant_id()
    and d.is_active
    and (p_dimension_type is null or d.dimension_type = p_dimension_type)
  order by d.dimension_type, d.code;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['accounting_books', 'accounting_dimensions'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy accounting_books_select on public.accounting_books for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy accounting_books_write on public.accounting_books for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']));

create policy accounting_dimensions_select on public.accounting_dimensions for select to authenticated
using (public.is_tenant_member(tenant_id));
create policy accounting_dimensions_write on public.accounting_dimensions for all to authenticated
using (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']))
with check (public.has_tenant_permission(tenant_id, array['manageAccounting','manageSettings']));

revoke all on function public.list_accounting_books() from public, anon;
revoke all on function public.list_accounting_dimensions(text) from public, anon;
grant execute on function public.list_accounting_books() to authenticated;
grant execute on function public.list_accounting_dimensions(text) to authenticated;
