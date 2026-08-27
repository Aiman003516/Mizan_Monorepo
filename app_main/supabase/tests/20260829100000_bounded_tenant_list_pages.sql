-- Mizan pgTAP-style structural checks
-- These checks require a disposable or staging database with pgTAP installed.

select plan(16);

select has_function('public', 'list_customers_page', array['timestamptz', 'uuid', 'integer'], 'customer page RPC exists');
select has_function('public', 'list_vendors_page', array['timestamptz', 'uuid', 'integer'], 'vendor page RPC exists');
select has_function('public', 'list_invoices_page', array['timestamptz', 'uuid', 'integer'], 'invoice page RPC exists');
select has_function('public', 'list_bills_page', array['timestamptz', 'uuid', 'integer'], 'bill page RPC exists');

select function_lang_is('public', 'list_customers_page', array['timestamptz', 'uuid', 'integer'], 'plpgsql', 'customer page is plpgsql');
select function_lang_is('public', 'list_vendors_page', array['timestamptz', 'uuid', 'integer'], 'plpgsql', 'vendor page is plpgsql');
select function_lang_is('public', 'list_invoices_page', array['timestamptz', 'uuid', 'integer'], 'plpgsql', 'invoice page is plpgsql');
select function_lang_is('public', 'list_bills_page', array['timestamptz', 'uuid', 'integer'], 'plpgsql', 'bill page is plpgsql');

select ok(has_function_privilege('authenticated', 'public.list_customers_page(timestamptz,uuid,integer)', 'EXECUTE'), 'authenticated can execute customer page');
select ok(has_function_privilege('authenticated', 'public.list_vendors_page(timestamptz,uuid,integer)', 'EXECUTE'), 'authenticated can execute vendor page');
select ok(has_function_privilege('authenticated', 'public.list_invoices_page(timestamptz,uuid,integer)', 'EXECUTE'), 'authenticated can execute invoice page');
select ok(has_function_privilege('authenticated', 'public.list_bills_page(timestamptz,uuid,integer)', 'EXECUTE'), 'authenticated can execute bill page');

select ok(not has_function_privilege('anon', 'public.list_customers_page(timestamptz,uuid,integer)', 'EXECUTE'), 'anon cannot execute customer page');
select ok(not has_function_privilege('anon', 'public.list_vendors_page(timestamptz,uuid,integer)', 'EXECUTE'), 'anon cannot execute vendor page');
select ok(not has_function_privilege('anon', 'public.list_invoices_page(timestamptz,uuid,integer)', 'EXECUTE'), 'anon cannot execute invoice page');
select ok(not has_function_privilege('anon', 'public.list_bills_page(timestamptz,uuid,integer)', 'EXECUTE'), 'anon cannot execute bill page');

select * from finish();
