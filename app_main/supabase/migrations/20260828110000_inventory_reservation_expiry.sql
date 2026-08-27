-- Mizan migration
-- id: 20260828110000_inventory_reservation_expiry.sql
-- owner: inventory-and-pos
-- prerequisites: 20260828100000_inventory_reservations.sql
-- changes: manual tenant-scoped expiry of stale inventory reservations
-- security: authenticated permission check, tenant scope, audit trigger coverage
-- verification: supabase/tests/20260828110000_inventory_reservation_expiry.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create or replace function public.expire_inventory_reservations()
returns integer
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_count integer;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['performSale','manageProducts','manageSettings']) then raise exception 'Inventory reservation permission required'; end if;
  update public.inventory_reservations
  set status = 'expired'
  where tenant_id = v_tenant_id and status = 'active' and expires_at is not null and expires_at <= timezone('utc', now());
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.expire_inventory_reservations() from public, anon, authenticated;
grant execute on function public.expire_inventory_reservations() to authenticated;
