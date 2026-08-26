begin;
select plan(12);

select has_function(
  'public',
  'refresh_customer_balance_from_invoices',
  array[]::text[],
  'customer balance trigger function exists'
);
select has_function(
  'public',
  'refresh_vendor_balance_from_bills',
  array[]::text[],
  'vendor balance trigger function exists'
);
select has_function(
  'public',
  'update_customer',
  array['uuid', 'timestamptz', 'jsonb'],
  'authenticated customer update wrapper exists'
);
select has_function(
  'public',
  'update_vendor',
  array['uuid', 'timestamptz', 'jsonb'],
  'authenticated vendor update wrapper exists'
);
select ok(
  exists (
    select 1
      from pg_trigger
     where tgrelid = 'public.invoices'::regclass
       and tgname = 'refresh_customer_balance_after_invoice'
       and not tgisinternal
  ),
  'invoice balance trigger exists'
);
select ok(
  exists (
    select 1
      from pg_trigger
     where tgrelid = 'public.bills'::regclass
       and tgname = 'refresh_vendor_balance_after_bill'
       and not tgisinternal
  ),
  'bill balance trigger exists'
);
select is(
  has_function_privilege('anon', 'public.update_customer(uuid,timestamptz,jsonb)', 'EXECUTE'),
  false,
  'anonymous customer updates remain blocked'
);
select is(
  has_function_privilege('authenticated', 'public.update_customer(uuid,timestamptz,jsonb)', 'EXECUTE'),
  true,
  'authenticated customer updates are available'
);
select is(
  has_function_privilege('anon', 'public.update_vendor(uuid,timestamptz,jsonb)', 'EXECUTE'),
  false,
  'anonymous vendor updates remain blocked'
);
select is(
  has_function_privilege('authenticated', 'public.update_vendor(uuid,timestamptz,jsonb)', 'EXECUTE'),
  true,
  'authenticated vendor updates are available'
);
select ok(
  pg_get_functiondef('public.refresh_customer_balance_from_invoices()'::regprocedure) like '%v_old_contribution%'
  and pg_get_functiondef('public.refresh_customer_balance_from_invoices()'::regprocedure) like '%v_new_contribution%',
  'customer trigger applies balance deltas'
);
select ok(
  pg_get_functiondef('public.refresh_vendor_balance_from_bills()'::regprocedure) like '%v_old_contribution%'
  and pg_get_functiondef('public.refresh_vendor_balance_from_bills()'::regprocedure) like '%v_new_contribution%',
  'vendor trigger applies balance deltas'
);

select * from finish();
rollback;
