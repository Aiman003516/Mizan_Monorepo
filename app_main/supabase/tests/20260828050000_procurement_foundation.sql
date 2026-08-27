-- Mizan procure-to-pay regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(23);

select has_table('public', 'purchase_requisitions', 'purchase requisitions table exists');
select has_table('public', 'purchase_requisition_lines', 'requisition lines table exists');
select has_table('public', 'purchase_orders', 'purchase orders table exists');
select has_table('public', 'purchase_order_lines', 'purchase order lines table exists');
select has_table('public', 'purchase_receipts', 'purchase receipts table exists');
select has_table('public', 'purchase_receipt_lines', 'purchase receipt lines table exists');
select has_table('public', 'purchase_returns', 'purchase returns table exists');
select has_table('public', 'purchase_return_lines', 'purchase return lines table exists');
select has_column('public', 'bills', 'purchase_order_id', 'bills can link to purchase orders');
select has_column('public', 'bill_items', 'purchase_order_line_id', 'bill lines can link to purchase order lines');
select has_index('public', 'purchase_orders_vendor_idx', 'purchase orders have vendor/status lookup index');
select has_index('public', 'purchase_receipt_lines_po_line_idx', 'receipt lines have PO-line lookup index');
select has_index('public', 'purchase_return_lines_po_line_idx', 'return lines have PO-line lookup index');
select has_function('public', 'create_purchase_requisition', array['text', 'uuid', 'date', 'text', 'text', 'jsonb'], 'requisition creation RPC exists');
select has_function('public', 'submit_purchase_order_for_approval', array['uuid', 'text'], 'purchase-order approval RPC exists');
select has_function('public', 'create_purchase_receipt_draft', array['uuid', 'text', 'text', 'date', 'jsonb'], 'receipt draft RPC exists');
select has_function('public', 'post_purchase_receipt', array['uuid'], 'receipt posting RPC exists');
select has_function('public', 'create_purchase_return_draft', array['uuid', 'uuid', 'text', 'date', 'text', 'jsonb'], 'return draft RPC exists');
select has_function('public', 'post_purchase_return', array['uuid'], 'return posting RPC exists');
select has_function('public', 'purchase_bill_three_way_match', array['uuid'], 'three-way match RPC exists');
select ok(
  pg_get_functiondef('public.purchase_bill_three_way_match(uuid)'::regprocedure)
    like '%public.current_tenant_id()%',
  'three-way matching is tenant scoped'
);
select ok(
  pg_get_functiondef('public.purchase_bill_three_way_match(uuid)'::regprocedure)
    like '%Cumulative billed quantity exceeds received quantity after returns.%',
  'three-way matching blocks billing beyond received quantity after returns'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name in ('create_purchase_requisition', 'create_purchase_order_draft', 'post_purchase_receipt', 'post_purchase_return')
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute procurement commands'
);

select * from finish();
rollback;
