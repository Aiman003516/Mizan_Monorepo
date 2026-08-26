-- Ordinary authenticated CRM edit entry points.
-- The underlying *_for_tenant helpers remain revoked from direct clients because
-- they are also used by the confirmation-gated AI execution workflow. These
-- wrappers derive the tenant from the current membership and delegate to the
-- same permission and optimistic-concurrency checks.

create or replace function public.update_customer(
  p_customer_id uuid,
  p_expected_updated_at timestamptz,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.update_customer_for_tenant(
    public.current_tenant_id(),
    p_customer_id,
    p_expected_updated_at,
    p_patch
  );
end;
$$;

create or replace function public.update_vendor(
  p_vendor_id uuid,
  p_expected_updated_at timestamptz,
  p_patch jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  return public.update_vendor_for_tenant(
    public.current_tenant_id(),
    p_vendor_id,
    p_expected_updated_at,
    p_patch
  );
end;
$$;

revoke all on function public.update_customer(uuid, timestamptz, jsonb) from public, anon;
revoke all on function public.update_vendor(uuid, timestamptz, jsonb) from public, anon;
grant execute on function public.update_customer(uuid, timestamptz, jsonb) to authenticated;
grant execute on function public.update_vendor(uuid, timestamptz, jsonb) to authenticated;
