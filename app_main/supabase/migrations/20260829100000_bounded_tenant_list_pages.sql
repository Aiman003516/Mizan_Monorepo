-- Mizan migration
-- id: 20260829100000_bounded_tenant_list_pages.sql
-- owner: platform-performance
-- prerequisites: 20260828150000_crm_quote_approval_history.sql
-- changes: bounded keyset-pagination RPCs for high-cardinality tenant lists
-- security: authenticated execution only; current-tenant scope; RLS remains authoritative
-- verification: supabase/tests/20260829100000_bounded_tenant_list_pages.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create or replace function public.list_customers_page(
  p_after_updated_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 50
)
returns setof public.customers
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  if p_limit is null or p_limit not between 1 and 100 then
    raise exception 'Page limit must be between 1 and 100';
  end if;
  if (p_after_updated_at is null) <> (p_after_id is null) then
    raise exception 'Cursor timestamp and id must be supplied together';
  end if;
  return query
    select c.*
    from public.customers c
    where c.tenant_id = public.current_tenant_id()
      and not c.is_deleted
      and (
        p_after_updated_at is null
        or c.updated_at > p_after_updated_at
        or (c.updated_at = p_after_updated_at and c.id > p_after_id)
      )
    order by c.updated_at asc, c.id asc
    limit p_limit;
end;
$$;

create or replace function public.list_vendors_page(
  p_after_updated_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 50
)
returns setof public.vendors
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  if p_limit is null or p_limit not between 1 and 100 then
    raise exception 'Page limit must be between 1 and 100';
  end if;
  if (p_after_updated_at is null) <> (p_after_id is null) then
    raise exception 'Cursor timestamp and id must be supplied together';
  end if;
  return query
    select v.*
    from public.vendors v
    where v.tenant_id = public.current_tenant_id()
      and not v.is_deleted
      and (
        p_after_updated_at is null
        or v.updated_at > p_after_updated_at
        or (v.updated_at = p_after_updated_at and v.id > p_after_id)
      )
    order by v.updated_at asc, v.id asc
    limit p_limit;
end;
$$;

create or replace function public.list_invoices_page(
  p_after_updated_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 50
)
returns setof public.invoices
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  if p_limit is null or p_limit not between 1 and 100 then
    raise exception 'Page limit must be between 1 and 100';
  end if;
  if (p_after_updated_at is null) <> (p_after_id is null) then
    raise exception 'Cursor timestamp and id must be supplied together';
  end if;
  return query
    select i.*
    from public.invoices i
    where i.tenant_id = public.current_tenant_id()
      and (
        p_after_updated_at is null
        or i.updated_at > p_after_updated_at
        or (i.updated_at = p_after_updated_at and i.id > p_after_id)
      )
    order by i.updated_at asc, i.id asc
    limit p_limit;
end;
$$;

create or replace function public.list_bills_page(
  p_after_updated_at timestamptz default null,
  p_after_id uuid default null,
  p_limit integer default 50
)
returns setof public.bills
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  if p_limit is null or p_limit not between 1 and 100 then
    raise exception 'Page limit must be between 1 and 100';
  end if;
  if (p_after_updated_at is null) <> (p_after_id is null) then
    raise exception 'Cursor timestamp and id must be supplied together';
  end if;
  return query
    select b.*
    from public.bills b
    where b.tenant_id = public.current_tenant_id()
      and (
        p_after_updated_at is null
        or b.updated_at > p_after_updated_at
        or (b.updated_at = p_after_updated_at and b.id > p_after_id)
      )
    order by b.updated_at asc, b.id asc
    limit p_limit;
end;
$$;

revoke all on function public.list_customers_page(timestamptz, uuid, integer) from public, anon;
revoke all on function public.list_vendors_page(timestamptz, uuid, integer) from public, anon;
revoke all on function public.list_invoices_page(timestamptz, uuid, integer) from public, anon;
revoke all on function public.list_bills_page(timestamptz, uuid, integer) from public, anon;
grant execute on function public.list_customers_page(timestamptz, uuid, integer) to authenticated;
grant execute on function public.list_vendors_page(timestamptz, uuid, integer) to authenticated;
grant execute on function public.list_invoices_page(timestamptz, uuid, integer) to authenticated;
grant execute on function public.list_bills_page(timestamptz, uuid, integer) to authenticated;
