-- Mizan procurement-to-inventory adapter regression checks.
-- Execute in a disposable/staging database after the canonical migrations.

begin;
select plan(16);

select has_table('public', 'procurement_inventory_receipt_links', 'receipt adapter link table exists');
select has_table('public', 'procurement_inventory_return_links', 'return adapter link table exists');
select has_table('public', 'inventory_returns', 'inventory returns table exists');
select has_column('public', 'inventory_returns', 'journal_entry_id', 'inventory returns link to accounting draft');
select has_index('public', 'procurement_inventory_receipt_links_lookup_idx', 'receipt adapter lookup index exists');
select has_index('public', 'procurement_inventory_return_links_lookup_idx', 'return adapter lookup index exists');
select has_index('public', 'inventory_returns_status_idx', 'inventory returns status index exists');
select has_function('public', 'v_receipt_currency', array['uuid', 'uuid'], 'internal receipt currency helper exists');
select has_function('public', 'create_inventory_return_draft', array['text', 'text', 'numeric', 'bigint', 'text', 'uuid', 'uuid', 'text', 'date'], 'inventory return draft RPC exists');
select has_function('public', 'post_purchase_receipt_to_inventory', array['uuid', 'uuid', 'uuid', 'text'], 'receipt inventory adapter RPC exists');
select has_function('public', 'post_purchase_return_to_inventory', array['uuid', 'uuid', 'uuid', 'text'], 'return inventory adapter RPC exists');
select ok(
  pg_get_functiondef('public.post_purchase_receipt_to_inventory(uuid,uuid,uuid,text)'::regprocedure)
    like '%public.create_inventory_receipt_draft%',
  'receipt adapter delegates to the existing inventory receipt accounting command'
);
select ok(
  pg_get_functiondef('public.post_purchase_return_to_inventory(uuid,uuid,uuid,text)'::regprocedure)
    like '%public.create_inventory_return_draft%',
  'return adapter delegates to the inventory return accounting command'
);
select ok(
  pg_get_functiondef('public.sync_inventory_after_post()'::regprocedure)
    like '%inventory_return%',
  'inventory posting trigger handles return drafts'
);
select ok(
  not exists (
    select 1
    from information_schema.role_routine_grants
    where routine_schema = 'public'
      and routine_name in ('post_purchase_receipt_to_inventory', 'post_purchase_return_to_inventory')
      and grantee in ('anon', 'public')
      and privilege_type = 'EXECUTE'
  ),
  'anonymous and public roles cannot execute inventory adapters'
);
select ok(
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'procurement_inventory_receipt_links'
      and policyname = 'procurement_inventory_receipt_links_select'
  ),
  'receipt adapter links are protected by a tenant-scoped read policy'
);

select * from finish();
rollback;
