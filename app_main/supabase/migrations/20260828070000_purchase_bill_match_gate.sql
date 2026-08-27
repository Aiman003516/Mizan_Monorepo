-- Mizan migration
-- id: 20260828070000_purchase_bill_match_gate.sql
-- owner: accounting-and-procurement
-- prerequisites: 20260828050000_procurement_foundation.sql
-- changes: three-way-match eligibility gate for purchase-bill approval/posting callers
-- security: tenant scope, accounting/procurement permissions, and restricted RPC execution
-- verification: supabase/tests/20260828070000_purchase_bill_match_gate.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

-- This gate is deliberately separate from bill creation and journal posting. A future
-- bill-posting command must call it before creating financial effects.
create or replace function public.assert_purchase_bill_match(p_bill_id uuid)
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_total_lines integer;
  v_blocked_lines integer;
  v_bill_status text;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageBills','manageAccounting','manageSettings']) then raise exception 'Purchase bill approval permission required'; end if;
  select status into v_bill_status
  from public.bills
  where id = p_bill_id and tenant_id = v_tenant_id;
  if not found or v_bill_status = 'void' then raise exception 'Purchase bill was not found'; end if;
  select count(*), count(*) filter (where match_status = 'blocked')
    into v_total_lines, v_blocked_lines
  from public.purchase_bill_three_way_match(p_bill_id);
  if v_total_lines = 0 then raise exception 'Purchase bill has no matchable lines'; end if;
  if v_blocked_lines > 0 then
    raise exception 'Purchase bill is blocked by three-way matching';
  end if;
  return jsonb_build_object(
    'bill_id', p_bill_id,
    'status', 'eligible_for_posting_gate',
    'line_count', v_total_lines,
    'blocked_line_count', v_blocked_lines
  );
end;
$$;

revoke all on function public.assert_purchase_bill_match(uuid) from public, anon, authenticated;
grant execute on function public.assert_purchase_bill_match(uuid) to authenticated;
