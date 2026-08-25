# Mizan Supabase Source-of-Truth Deployment

The migration in `migrations/20260825123000_cloud_source_of_truth.sql` creates canonical tenant-scoped CRM, invoice, bill, role, staff, currency, custom-field, audit, and legacy-cache-envelope tables. It also creates indexes, RLS policies, protected RPCs for business bootstrap and document creation, and audit triggers.

## Apply the migration

The connected Supabase Data API accepts authenticated REST queries, but the current session key does not have DDL privileges and no direct Postgres connection is available in the build environment. Apply the migration once in the Supabase SQL Editor or with the Supabase CLI using the project’s database credentials. Apply the complete file as one migration; do not copy individual policy fragments out of order. If an earlier run stopped with `ERROR: 42703: column "status" does not exist`, pull the latest repository version and rerun the complete file: the compatibility block now adds legacy `staff_members.status` and invite lifecycle columns before creating their indexes and policies. The migration also uses JSONB for role permissions, matching the existing `roles.permissions` column.

After applying it, run the SQL in `tests/cloud_source_of_truth.sql` with the project’s database test runner. The supplied schema export shows the legacy tables are currently empty, so no data conversion is expected for the first successful run; retain a database backup before applying to a populated project. The Data API probe should then return HTTP 200 for `currencies`, `custom_fields`, `customers`, `vendors`, `invoices`, `invoice_items`, `bills`, `bill_items`, and `audit_logs`.

## Realtime and client configuration

Enable Realtime for the canonical tables used by list/detail screens: `customers`, `vendors`, `invoices`, `invoice_items`, `bills`, `bill_items`, `roles`, `staff_members`, `currencies`, and `custom_fields`. Configure the Flutter app with the Supabase project URL and publishable key through the existing environment configuration. Never ship a service-role key in the Flutter application.

## Data migration and rollout

Existing local Drift data should be exported and staged before importing into the canonical tables. A migration script must map legacy string identifiers to UUIDs, preserve tenant ownership, validate customer/vendor references, and recalculate invoice and bill totals from line items. Do not bulk-import unvalidated local rows directly into production. During the first rollout, keep Drift as the cache and retain the Google Drive backup path so a user can restore the local SQLite cache, including the durable sync outbox table.

## Offline behavior

Online CRM and document writes target Supabase first. Temporary network failures can materialize a tenant-scoped Drift row and an outbox entry. The synchronization engine replays pending outbox entries in bounded batches, while the existing Google Drive service backs up the complete SQLite file through `VACUUM INTO`; this includes cache tables and pending outbox entries. Authorization failures, validation errors, and RLS denials are not treated as offline successes.

## Production checks

Before release, verify email-confirmation behavior, session refresh, tenant bootstrap, invite validation/redemption, RLS isolation with two test users from different tenants, system-admin immutability, role permission enforcement, atomic invoice/bill creation, duplicate currency/custom-field constraints, pagination behavior, offline creation and replay, and Google Drive backup/restore on a physical Android device. Confirm that the SQL migration is applied before enabling the cloud-mode build flag.
