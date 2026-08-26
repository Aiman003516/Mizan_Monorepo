# Mizan Owner Control Center Phase 1 Audit

Generated from repository inspection; this is a static audit, not a live Supabase verification.

## Current feature packages
packages/features
packages/features/feature_accounts
packages/features/feature_accounts/.dart_tool
packages/features/feature_accounts/lib
packages/features/feature_ai
packages/features/feature_ai/.dart_tool
packages/features/feature_ai/lib
packages/features/feature_ai/test
packages/features/feature_auth
packages/features/feature_auth/.dart_tool
packages/features/feature_auth/lib
packages/features/feature_contacts
packages/features/feature_contacts/.dart_tool
packages/features/feature_contacts/lib
packages/features/feature_dashboard
packages/features/feature_dashboard/.dart_tool
packages/features/feature_dashboard/lib
packages/features/feature_data_import
packages/features/feature_data_import/.dart_tool
packages/features/feature_data_import/lib
packages/features/feature_products
packages/features/feature_products/.dart_tool
packages/features/feature_products/lib
packages/features/feature_reports
packages/features/feature_reports/.dart_tool
packages/features/feature_reports/build
packages/features/feature_reports/lib
packages/features/feature_reports/test
packages/features/feature_settings
packages/features/feature_settings/.dart_tool
packages/features/feature_settings/build
packages/features/feature_settings/lib
packages/features/feature_settings/test
packages/features/feature_sync
packages/features/feature_sync/.dart_tool
packages/features/feature_sync/build
packages/features/feature_sync/lib
packages/features/feature_sync/test
packages/features/feature_transactions
packages/features/feature_transactions/.dart_tool
packages/features/feature_transactions/lib

## Existing settings screens
packages/features/feature_settings/lib/src/data/billing_repository.dart
packages/features/feature_settings/lib/src/data/currencies_repository.dart
packages/features/feature_settings/lib/src/data/custom_fields_repository.dart
packages/features/feature_settings/lib/src/data/fixed_assets_repository.dart
packages/features/feature_settings/lib/src/data/ghost_money_repository.dart
packages/features/feature_settings/lib/src/presentation/buy_now_screen.dart
packages/features/feature_settings/lib/src/presentation/company_profile_screen.dart
packages/features/feature_settings/lib/src/presentation/currency_controller.dart
packages/features/feature_settings/lib/src/presentation/currency_settings_screen.dart
packages/features/feature_settings/lib/src/presentation/custom_fields/custom_fields_screen.dart
packages/features/feature_settings/lib/src/presentation/depreciation_screen.dart
packages/features/feature_settings/lib/src/presentation/fixed_assets_screen.dart
packages/features/feature_settings/lib/src/presentation/ghost_money_screen.dart
packages/features/feature_settings/lib/src/presentation/onboarding_screen.dart
packages/features/feature_settings/lib/src/presentation/onboarding_tutorial_screen.dart
packages/features/feature_settings/lib/src/presentation/roles/role_editor_screen.dart
packages/features/feature_settings/lib/src/presentation/roles/roles_list_screen.dart
packages/features/feature_settings/lib/src/presentation/security_settings_screen.dart
packages/features/feature_settings/lib/src/presentation/set_passcode_screen.dart
packages/features/feature_settings/lib/src/presentation/settings_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/bulk_invite_staff_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/employee_sign_in_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/invite_staff_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/staff_list_screen.dart
packages/features/feature_settings/lib/src/presentation/subscription/subscription_screen.dart

## Existing reports and operations screens
packages/features/feature_reports/lib/src/data/analytics_repository.dart
packages/features/feature_reports/lib/src/data/budget_repository.dart
packages/features/feature_reports/lib/src/data/export_service.dart
packages/features/feature_reports/lib/src/data/inventory_repository.dart
packages/features/feature_reports/lib/src/data/report_models.dart
packages/features/feature_reports/lib/src/data/report_templates_repository.dart
packages/features/feature_reports/lib/src/data/reports_service.dart
packages/features/feature_reports/lib/src/presentation/account_activity_screen.dart
packages/features/feature_reports/lib/src/presentation/amount_details_screen.dart
packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart
packages/features/feature_reports/lib/src/presentation/analytics_providers.dart
packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart
packages/features/feature_reports/lib/src/presentation/balance_sheet_screen.dart
packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliation_screen.dart
packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart
packages/features/feature_reports/lib/src/presentation/budget_screen.dart
packages/features/feature_reports/lib/src/presentation/cash_flow_screen.dart
packages/features/feature_reports/lib/src/presentation/dynamic_report_screen.dart
packages/features/feature_reports/lib/src/presentation/financial_ratios_widget.dart
packages/features/feature_reports/lib/src/presentation/general_ledger_provider.dart
packages/features/feature_reports/lib/src/presentation/monthly_amounts_screen.dart
packages/features/feature_reports/lib/src/presentation/operations_report_screens.dart
packages/features/feature_reports/lib/src/presentation/profit_and_loss_screen.dart
packages/features/feature_reports/lib/src/presentation/report_marketplace_screen.dart
packages/features/feature_reports/lib/src/presentation/reports_hub_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/ap_aging_report_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/ar_aging_report_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/capital_budgeting_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/cvp_analysis_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/fraud_detection_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/standard_costing_screen.dart
packages/features/feature_reports/lib/src/presentation/total_amounts_screen.dart
packages/features/feature_reports/lib/src/presentation/total_classifications_screen.dart
packages/features/feature_reports/lib/src/presentation/trial_balance_screen.dart
packages/features/feature_transactions/lib/src/data/adjusting_entries_repository.dart
packages/features/feature_transactions/lib/src/data/bank_reconciliation_repository.dart
packages/features/feature_transactions/lib/src/data/database_provider.dart
packages/features/feature_transactions/lib/src/data/receipt_service.dart
packages/features/feature_transactions/lib/src/data/transactions_repository.dart
packages/features/feature_transactions/lib/src/presentation/add_amount_screen.dart
packages/features/feature_transactions/lib/src/presentation/adjusting_entries_screen.dart
packages/features/feature_transactions/lib/src/presentation/bank_reconciliation/bank_matching_screen.dart
packages/features/feature_transactions/lib/src/presentation/bank_reconciliation_screen.dart
packages/features/feature_transactions/lib/src/presentation/barcode_scanner_screen.dart
packages/features/feature_transactions/lib/src/presentation/general_journal_screen.dart
packages/features/feature_transactions/lib/src/presentation/make_payment_screen.dart
packages/features/feature_transactions/lib/src/presentation/order_details_screen.dart
packages/features/feature_transactions/lib/src/presentation/order_history_provider.dart
packages/features/feature_transactions/lib/src/presentation/order_history_screen.dart
packages/features/feature_transactions/lib/src/presentation/period_end_wizard_screen.dart
packages/features/feature_transactions/lib/src/presentation/pos_receipt_provider.dart
packages/features/feature_transactions/lib/src/presentation/pos_screen.dart
packages/features/feature_transactions/lib/src/presentation/pos_state_provider.dart
packages/features/feature_transactions/lib/src/presentation/purchase_screen.dart
packages/features/feature_transactions/lib/src/presentation/return_items_screen.dart
packages/features/feature_transactions/lib/src/presentation/transactions_list_provider.dart
packages/features/feature_transactions/lib/src/presentation/transactions_list_screen.dart
packages/features/feature_transactions/lib/src/presentation/widgets/pos_cart_sheet.dart
packages/features/feature_transactions/lib/src/presentation/widgets/pos_checkout_panel.dart
packages/features/feature_transactions/lib/src/presentation/widgets/pos_order_table.dart
packages/features/feature_transactions/lib/src/presentation/widgets/pos_product_grid.dart
packages/features/feature_transactions/lib/src/presentation/widgets/virtual_numpad.dart

## Database migration inventory
20260825122999_legacy_status_preflight.sql
20260825123000_cloud_source_of_truth.sql
20260825190000_enable_realtime_publication.sql
20260826150000_employee_invitation_phase1.sql
20260826170000_employee_management_phase2.sql
20260827100000_ai_agent_phase1.sql
20260827110000_ai_action_requests_phase2.sql
20260827130000_ai_action_execution_phase3.sql
20260827150000_ai_action_expansion_phase4.sql

## Tables/functions/policies in migrations
supabase/migrations/20260825123000_cloud_source_of_truth.sql:109:create table if not exists public.custom_fields (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:125:create table if not exists public.customers (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:150:create table if not exists public.vendors (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:174:create table if not exists public.invoices (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:204:create table if not exists public.invoice_items (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:220:create table if not exists public.bills (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:251:create table if not exists public.bill_items (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:267:create table if not exists public.audit_logs (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:284:create or replace function public.set_updated_at()
supabase/migrations/20260825123000_cloud_source_of_truth.sql:296:create or replace function public.prevent_tenant_owner_change()
supabase/migrations/20260825123000_cloud_source_of_truth.sql:29:create table if not exists public.tenants (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:368:create or replace function public.is_tenant_member(p_tenant_id uuid)
supabase/migrations/20260825123000_cloud_source_of_truth.sql:384:create or replace function public.has_tenant_permission(p_tenant_id uuid, p_permissions text[])
supabase/migrations/20260825123000_cloud_source_of_truth.sql:424:create or replace function public.audit_row_change()
supabase/migrations/20260825123000_cloud_source_of_truth.sql:43:create table if not exists public.user_profiles (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:448:create or replace function public.prevent_system_admin_mutation()
supabase/migrations/20260825123000_cloud_source_of_truth.sql:465:create or replace function public.create_profile_for_new_user()
supabase/migrations/20260825123000_cloud_source_of_truth.sql:522:    execute format('alter table public.%I enable row level security', t);
supabase/migrations/20260825123000_cloud_source_of_truth.sql:52:create table if not exists public.roles (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:544:create policy tenants_select on public.tenants for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:547:create policy tenants_insert on public.tenants for insert to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:550:create policy tenants_update on public.tenants for update to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:554:create policy user_profiles_select on public.user_profiles for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:556:create policy user_profiles_update on public.user_profiles for update to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:559:create policy roles_select on public.roles for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:561:create policy roles_insert on public.roles for insert to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:563:create policy roles_update on public.roles for update to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:566:create policy roles_delete on public.roles for delete to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:569:create policy staff_members_select on public.staff_members for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:571:create policy staff_members_insert on public.staff_members for insert to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:573:create policy staff_members_update on public.staff_members for update to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:576:create policy staff_members_delete on public.staff_members for delete to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:580:create policy invites_select on public.invites for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:582:create policy invites_insert on public.invites for insert to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:584:create policy invites_update on public.invites for update to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:588:create policy currencies_select on public.currencies for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:590:create policy currencies_write on public.currencies for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:594:create policy custom_fields_select on public.custom_fields for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:596:create policy custom_fields_write on public.custom_fields for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:600:create policy customers_select on public.customers for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:602:create policy customers_write on public.customers for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:606:create policy vendors_select on public.vendors for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:608:create policy vendors_write on public.vendors for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:612:create policy invoices_select on public.invoices for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:614:create policy invoices_write on public.invoices for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:619:create policy invoice_items_select on public.invoice_items for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:621:create policy invoice_items_write on public.invoice_items for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:626:create policy bills_select on public.bills for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:628:create policy bills_write on public.bills for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:633:create policy bill_items_select on public.bill_items for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:635:create policy bill_items_write on public.bill_items for all to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:640:create policy audit_logs_select on public.audit_logs for select to authenticated
supabase/migrations/20260825123000_cloud_source_of_truth.sql:650:create or replace function public.create_business(
supabase/migrations/20260825123000_cloud_source_of_truth.sql:67:create table if not exists public.staff_members (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:708:create or replace function public.create_invite(p_role_id uuid)
supabase/migrations/20260825123000_cloud_source_of_truth.sql:745:create or replace function public.redeem_invite(p_code text, p_display_name text)
supabase/migrations/20260825123000_cloud_source_of_truth.sql:798:create or replace function public.validate_invite(p_code text)
supabase/migrations/20260825123000_cloud_source_of_truth.sql:80:create table if not exists public.invites (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:849:    execute format('alter table public.%I enable row level security', remote_name);
supabase/migrations/20260825123000_cloud_source_of_truth.sql:853:    execute format('create policy tenant_read on public.%I for select to authenticated using (public.is_tenant_member(tenant_id))', remote_name);
supabase/migrations/20260825123000_cloud_source_of_truth.sql:855:    execute format('create policy tenant_write on public.%I for all to authenticated using (public.is_tenant_member(tenant_id)) with check (public.is_tenant_member(tenant_id))', remote_name);
supabase/migrations/20260825123000_cloud_source_of_truth.sql:860:create or replace function public.activate_existing_business(p_tenant_id uuid)
supabase/migrations/20260825123000_cloud_source_of_truth.sql:912:create or replace function public.create_invoice(
supabase/migrations/20260825123000_cloud_source_of_truth.sql:94:create table if not exists public.currencies (
supabase/migrations/20260825123000_cloud_source_of_truth.sql:991:create or replace function public.create_bill(
supabase/migrations/20260826150000_employee_invitation_phase1.sql:157:create or replace function public.validate_invitation(p_token text default null, p_code text default null)
supabase/migrations/20260826150000_employee_invitation_phase1.sql:197:create or replace function public.redeem_invitation(
supabase/migrations/20260826150000_employee_invitation_phase1.sql:270:create or replace function public.set_staff_status(
supabase/migrations/20260826150000_employee_invitation_phase1.sql:310:create or replace function public.create_invitations_bulk(
supabase/migrations/20260826150000_employee_invitation_phase1.sql:35:create or replace function public.sync_invitation_status()
supabase/migrations/20260826150000_employee_invitation_phase1.sql:366:create or replace function public.revoke_invitation(p_invitation_id uuid)
supabase/migrations/20260826150000_employee_invitation_phase1.sql:63:create or replace function public.create_invitation(
supabase/migrations/20260826170000_employee_management_phase2.sql:21:alter table public.invitation_batches enable row level security;
supabase/migrations/20260826170000_employee_management_phase2.sql:23:create policy invitation_batches_tenant_read
supabase/migrations/20260826170000_employee_management_phase2.sql:27:create or replace function public.set_staff_status(
supabase/migrations/20260826170000_employee_management_phase2.sql:6:create table if not exists public.invitation_batches (
supabase/migrations/20260826170000_employee_management_phase2.sql:79:create or replace function public.create_invitations_bulk(
supabase/migrations/20260827100000_ai_agent_phase1.sql:19:create table if not exists public.ai_messages (
supabase/migrations/20260827100000_ai_agent_phase1.sql:35:create table if not exists public.ai_audit_events (
supabase/migrations/20260827100000_ai_agent_phase1.sql:53:alter table public.ai_conversations enable row level security;
supabase/migrations/20260827100000_ai_agent_phase1.sql:54:alter table public.ai_messages enable row level security;
supabase/migrations/20260827100000_ai_agent_phase1.sql:55:alter table public.ai_audit_events enable row level security;
supabase/migrations/20260827100000_ai_agent_phase1.sql:5:create table if not exists public.ai_conversations (
supabase/migrations/20260827100000_ai_agent_phase1.sql:66:create or replace function public.touch_ai_conversation()
supabase/migrations/20260827110000_ai_action_requests_phase2.sql:36:alter table public.ai_action_requests enable row level security;
supabase/migrations/20260827110000_ai_action_requests_phase2.sql:40:create or replace function public.touch_ai_action_request()
supabase/migrations/20260827110000_ai_action_requests_phase2.sql:4:create table if not exists public.ai_action_requests (
supabase/migrations/20260827130000_ai_action_execution_phase3.sql:118:create or replace function public.execute_ai_action(
supabase/migrations/20260827130000_ai_action_execution_phase3.sql:21:create or replace function public.create_customer_for_tenant(
supabase/migrations/20260827130000_ai_action_execution_phase3.sql:67:create or replace function public.create_vendor_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:105:create or replace function public.create_invitation_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:139:create or replace function public.create_invitations_bulk_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:182:create or replace function public.update_customer_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:243:create or replace function public.update_vendor_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:28:create or replace function public.create_invoice_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:294:create or replace function public.update_invoice_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:376:create or replace function public.update_bill_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:457:create or replace function public.post_balance_adjustment_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:547:create or replace function public.post_journal_entry_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:603:create or replace function public.archive_customer_for_tenant(p_tenant_id uuid, p_customer_id uuid, p_expected_updated_at timestamptz)
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:616:create or replace function public.archive_vendor_for_tenant(p_tenant_id uuid, p_vendor_id uuid, p_expected_updated_at timestamptz)
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:629:create or replace function public.void_invoice_for_tenant(p_tenant_id uuid, p_invoice_id uuid, p_expected_updated_at timestamptz)
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:642:create or replace function public.void_bill_for_tenant(p_tenant_id uuid, p_bill_id uuid, p_expected_updated_at timestamptz)
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:66:create or replace function public.create_bill_for_tenant(
supabase/migrations/20260827150000_ai_action_expansion_phase4.sql:680:create or replace function public.execute_ai_action(

## Existing setting and configuration repositories
packages/core/core_data/lib/src/env_config.dart
packages/core/core_data/lib/src/providers/currency_providers.dart
packages/core/core_data/lib/src/repositories/bank_reconciliation_repository.dart
packages/core/core_data/lib/src/repositories/roles_repository.dart
packages/core/core_data/lib/src/repositories/staff_repository.dart
packages/core/core_data/lib/src/repositories/warehouse_repository.dart
packages/core/core_data/lib/src/services/budgeting_service.dart
packages/core/core_data/lib/src/services/capital_budgeting_service.dart
packages/core/core_data/lib/src/services/currency_service.dart
packages/core/core_data/lib/src/services/permission_service.dart
packages/core/core_data/lib/src/services/sync_queue_service.dart
packages/core/core_data/test/sync_queue_service_test.dart
packages/features/feature_contacts/lib/src/presentation/customers/ar_aging_report_screen.dart
packages/features/feature_contacts/lib/src/presentation/vendors/ap_aging_report_screen.dart
packages/features/feature_products/lib/feature_products.dart
packages/features/feature_products/lib/src/data/accounts_repository.dart
packages/features/feature_products/lib/src/data/categories_repository.dart
packages/features/feature_products/lib/src/data/database_provider.dart
packages/features/feature_products/lib/src/data/import_service.dart
packages/features/feature_products/lib/src/data/products_repository.dart
packages/features/feature_products/lib/src/presentation/add_product_screen.dart
packages/features/feature_products/lib/src/presentation/all_products_list_widget.dart
packages/features/feature_products/lib/src/presentation/all_products_stream_provider.dart
packages/features/feature_products/lib/src/presentation/categories_hub_screen.dart
packages/features/feature_products/lib/src/presentation/product_import_screen.dart
packages/features/feature_products/lib/src/presentation/products_hub_screen.dart
packages/features/feature_products/lib/src/presentation/products_list_provider.dart
packages/features/feature_products/lib/src/presentation/products_list_screen.dart
packages/features/feature_reports/.dart_tool/flutter_build/dart_plugin_registrant.dart
packages/features/feature_reports/lib/feature_reports.dart
packages/features/feature_reports/lib/main.dart
packages/features/feature_reports/lib/src/data/analytics_repository.dart
packages/features/feature_reports/lib/src/data/budget_repository.dart
packages/features/feature_reports/lib/src/data/export_service.dart
packages/features/feature_reports/lib/src/data/inventory_repository.dart
packages/features/feature_reports/lib/src/data/report_models.dart
packages/features/feature_reports/lib/src/data/report_templates_repository.dart
packages/features/feature_reports/lib/src/data/reports_service.dart
packages/features/feature_reports/lib/src/presentation/account_activity_screen.dart
packages/features/feature_reports/lib/src/presentation/amount_details_screen.dart
packages/features/feature_reports/lib/src/presentation/analytics_dashboard_screen.dart
packages/features/feature_reports/lib/src/presentation/analytics_providers.dart
packages/features/feature_reports/lib/src/presentation/ar_ap_summary_cards.dart
packages/features/feature_reports/lib/src/presentation/balance_sheet_screen.dart
packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliation_screen.dart
packages/features/feature_reports/lib/src/presentation/bank/bank_reconciliations_list_screen.dart
packages/features/feature_reports/lib/src/presentation/budget_screen.dart
packages/features/feature_reports/lib/src/presentation/cash_flow_screen.dart
packages/features/feature_reports/lib/src/presentation/dynamic_report_screen.dart
packages/features/feature_reports/lib/src/presentation/financial_ratios_widget.dart
packages/features/feature_reports/lib/src/presentation/general_ledger_provider.dart
packages/features/feature_reports/lib/src/presentation/monthly_amounts_screen.dart
packages/features/feature_reports/lib/src/presentation/operations_report_screens.dart
packages/features/feature_reports/lib/src/presentation/profit_and_loss_screen.dart
packages/features/feature_reports/lib/src/presentation/report_marketplace_screen.dart
packages/features/feature_reports/lib/src/presentation/reports_hub_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/ap_aging_report_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/ar_aging_report_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/capital_budgeting_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/cvp_analysis_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/financial_ratios_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/fraud_detection_screen.dart
packages/features/feature_reports/lib/src/presentation/tools/standard_costing_screen.dart
packages/features/feature_reports/lib/src/presentation/total_amounts_screen.dart
packages/features/feature_reports/lib/src/presentation/total_classifications_screen.dart
packages/features/feature_reports/lib/src/presentation/trial_balance_screen.dart
packages/features/feature_reports/test/budget_repository_test.dart
packages/features/feature_reports/test/inventory_repository_test.dart
packages/features/feature_settings/.dart_tool/flutter_build/dart_plugin_registrant.dart
packages/features/feature_settings/lib/feature_settings.dart
packages/features/feature_settings/lib/src/data/billing_repository.dart
packages/features/feature_settings/lib/src/data/currencies_repository.dart
packages/features/feature_settings/lib/src/data/custom_fields_repository.dart
packages/features/feature_settings/lib/src/data/fixed_assets_repository.dart
packages/features/feature_settings/lib/src/data/ghost_money_repository.dart
packages/features/feature_settings/lib/src/presentation/buy_now_screen.dart
packages/features/feature_settings/lib/src/presentation/company_profile_screen.dart
packages/features/feature_settings/lib/src/presentation/currency_controller.dart
packages/features/feature_settings/lib/src/presentation/currency_settings_screen.dart
packages/features/feature_settings/lib/src/presentation/custom_fields/custom_fields_screen.dart
packages/features/feature_settings/lib/src/presentation/depreciation_screen.dart
packages/features/feature_settings/lib/src/presentation/fixed_assets_screen.dart
packages/features/feature_settings/lib/src/presentation/ghost_money_screen.dart
packages/features/feature_settings/lib/src/presentation/onboarding_screen.dart
packages/features/feature_settings/lib/src/presentation/onboarding_tutorial_screen.dart
packages/features/feature_settings/lib/src/presentation/roles/role_editor_screen.dart
packages/features/feature_settings/lib/src/presentation/roles/roles_list_screen.dart
packages/features/feature_settings/lib/src/presentation/security_settings_screen.dart
packages/features/feature_settings/lib/src/presentation/set_passcode_screen.dart
packages/features/feature_settings/lib/src/presentation/settings_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/bulk_invite_staff_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/employee_sign_in_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/invite_staff_screen.dart
packages/features/feature_settings/lib/src/presentation/staff/staff_list_screen.dart
packages/features/feature_settings/lib/src/presentation/subscription/subscription_screen.dart
packages/features/feature_settings/test/roles_list_screen_test.dart
packages/features/feature_settings/test/staff_list_screen_test.dart
packages/features/feature_sync/.dart_tool/flutter_build/dart_plugin_registrant.dart
packages/features/feature_sync/lib/feature_sync.dart
packages/features/feature_sync/lib/src/data/cloud_sync_service.dart
packages/features/feature_sync/lib/src/data/sync_service.dart
packages/features/feature_sync/lib/src/data/sync_worker.dart
packages/features/feature_sync/lib/src/presentation/sync_controller.dart
packages/features/feature_sync/lib/src/presentation/sync_gatekeeper.dart
packages/features/feature_sync/test/sync_worker_test.dart
packages/features/feature_transactions/lib/src/data/bank_reconciliation_repository.dart
packages/features/feature_transactions/lib/src/presentation/bank_reconciliation/bank_matching_screen.dart
packages/features/feature_transactions/lib/src/presentation/bank_reconciliation_screen.dart
packages/features/feature_transactions/lib/src/presentation/make_payment_screen.dart
packages/features/feature_transactions/lib/src/presentation/widgets/pos_product_grid.dart

## Static constraints
- Flutter app root: apps/
- Feature architecture: packages/features/*
- Supabase migrations: supabase/migrations/
- Local guest startup exists; cloud synchronization remains optional.
- No live Supabase DDL or mutation was executed during this audit.
- Android device verification is unavailable in this sandbox.
