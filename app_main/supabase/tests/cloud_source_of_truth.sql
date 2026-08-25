begin;

select plan(14);

select has_table('public', 'tenants', 'tenants table exists');
select has_table('public', 'user_profiles', 'user_profiles table exists');
select has_table('public', 'roles', 'roles table exists');
select has_table('public', 'staff_members', 'staff_members table exists');
select has_table('public', 'customers', 'customers table exists');
select has_table('public', 'vendors', 'vendors table exists');
select has_table('public', 'invoices', 'invoices table exists');
select has_table('public', 'bills', 'bills table exists');
select has_table('public', 'audit_logs', 'audit_logs table exists');

select is((select relrowsecurity from pg_class where oid = 'public.customers'::regclass), true, 'customers has RLS enabled');
select is((select relrowsecurity from pg_class where oid = 'public.vendors'::regclass), true, 'vendors has RLS enabled');
select is((select relrowsecurity from pg_class where oid = 'public.invoices'::regclass), true, 'invoices has RLS enabled');
select is((select relrowsecurity from pg_class where oid = 'public.bills'::regclass), true, 'bills has RLS enabled');
select ok(to_regclass('public.customers_tenant_updated_idx') is not null, 'customer tenant/update index exists');

select * from finish();
rollback;
