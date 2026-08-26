# Mizan Supabase Migration Runbook

## Safety boundary

The development sandbox does not apply these migrations to the user’s Supabase project. Production execution requires an explicit approval, a verified backup or rollback plan, and confirmation that the target project contains the expected legacy schema. Never paste service-role secrets into source files, chat, or Flutter build definitions.

## Migration order

Run the files in filename order. The current sequence is:

| Order | Migration | Purpose | Production state in this work |
|---:|---|---|---|
| 1 | `20260825122999_legacy_status_preflight.sql` | Legacy compatibility preparation | Existing repository migration; live status must be verified |
| 2 | `20260825123000_cloud_source_of_truth.sql` | Tenant, identity, RBAC, CRM, documents, and audit foundation | Existing repository migration; live status must be verified |
| 3 | `20260825190000_enable_realtime_publication.sql` | Realtime publication for consumed tables | Existing repository migration; live status must be verified |
| 4 | `20260826150000_employee_invitation_phase1.sql` | Recipient-bound invitations and secure code/token fields | Existing repository migration; live status must be verified |
| 5 | `20260826170000_employee_management_phase2.sql` | Idempotent email-array bulk invitation compatibility | Existing repository migration; live status must be verified |
| 6 | `20260826190000_owner_control_center_phase1.sql` | Owner settings and administrative controls | Existing repository migration; live status must be verified |
| 7 | `20260826200000_employee_invitation_phase3.sql` | Structured recipients, readable history, delivery intents, resend/revoke, onboarding redemption | Added previously; not assumed live |
| 8 | `20260827100000_ai_agent_phase1.sql` | AI assistant foundation | Existing repository migration; live status must be verified |
| 9 | `20260827110000_ai_action_requests_phase2.sql` | Proposal and confirmation records | Existing repository migration; live status must be verified |
| 10 | `20260827130000_ai_action_execution_phase3.sql` | Confirmed action execution boundary | Existing repository migration; live status must be verified |
| 11 | `20260827150000_ai_action_expansion_phase4.sql` | Expanded proposal/action types | Existing repository migration; live status must be verified |
| 12 | `20260827160000_platform_foundation_hardening.sql` | Branch scope, idempotency reservations, durable sync mutations, tenant helpers, and new RLS | Added in the current upgrade; not applied |
| 13 | `20260827170000_accounting_ledger_foundation.sql` | Accounting periods, tax codes, chart of accounts, journal entries/lines, balanced posting, and trial balance | Added in the current upgrade; not applied |
| 14 | `20260827180000_crm_pipeline_foundation.sql` | CRM leads, pipeline, opportunities, activities, and interaction history | Added in the current upgrade; not applied |
| 15 | `20260827190000_accounting_flutter_contract.sql` | Flutter RPCs for journal drafts, P&L, balance sheet, and accounting-period closing | Added in the current upgrade; not applied |
| 16 | `20260827200000_schema_health_preflight.sql` | Read-only tenant-scoped schema, RLS, index, currency, orphan-reference, and posted-journal health checks | Added in the current upgrade; not applied |
| 17 | `20260827210000_dimensions_books_fx.sql` | Accounting books, controlled dimensions, worktags, and exchange-rate provenance fields | Added in the current upgrade; not applied |
| 18 | `20260827220000_tax_engine_foundation.sql` | Effective-dated tax metadata, deterministic calculation, tax snapshots, RLS, and audit hooks | Added in the current upgrade; not applied |
| 19 | `20260827230000_revenue_recognition_foundation.sql` | Tenant-scoped contracts, deterministic schedules, recognition drafts, posting synchronization, RLS, and audit hooks | Added in the current upgrade; not applied |
| 20 | `20260827240000_ar_ap_settlement_aging.sql` | AR/AP settlement drafts, outstanding-balance guards, posting synchronization, receivables/payables aging, RLS, and audit hooks | Added in the current upgrade; not applied |
| 21 | `20260827241000_dimensions_books_fx_repair.sql` | Table-aware dimensional triggers, leading-book seeding/backfill, and extended journal-draft book/FX/worktag contract | Added in the current upgrade; not applied |
| 22 | `20260827250000_inventory_pos_accounting_bridge.sql` | Server inventory balances, receipt/sale drafts, weighted-average costing, posting-time stock guards, RLS, and audit hooks | Added in the current upgrade; not applied |
| 23 | `20260827260000_crm_360_health_cpq.sql` | Customer 360 metrics, deterministic advisory health scores, interaction recording, draft-only quote/CPQ contracts, RLS, and audit hooks | Added in the current upgrade; not applied |

## Preflight checklist

Before applying anything, export the schema and record the current migration state. Confirm that `auth.users`, `public.tenants`, `public.user_profiles`, `public.roles`, and `public.staff_members` exist, that legacy columns referenced by the preflight blocks have compatible types, and that no production object already uses the new table or function names with an incompatible contract.

Run a read-only inspection for orphaned tenant references, staff members without valid roles, invites with invalid status or expiry, duplicate tenant-scoped codes, currencies that are not uppercase, and any existing accounting records whose debit and credit totals do not balance. Preserve the output as a deployment artifact before changing schema.

## Apply and verify

Use the Supabase SQL editor or the project’s approved migration pipeline while authenticated to the correct Supabase account. Apply one migration at a time and stop on the first error. Do not use a broad “ignore errors” mode. After each file, verify that the expected tables, functions, grants, indexes, and policies exist.

After the platform hardening migration, verify that a tenant administrator can create and read a branch, a non-administrator cannot change branches, a branch assignment cannot reference another tenant’s staff member or branch, duplicate idempotency keys return the original result, and duplicate sync mutation IDs do not create duplicate rows.

After the accounting migration, verify that a user can create a draft journal, cannot directly post through a table update, cannot mutate posted entries or lines, cannot post an unbalanced entry, cannot post into a locked/closed period, and can read a tenant-scoped trial balance that excludes drafts and reversed entries. Verify that the sum of trial-balance debits and credits is equal for a balanced test dataset.

## Client rollout

Deploy the Flutter client only after the corresponding migration contracts are present in the target project. If production has not received a migration, the client must use a compatible fallback or keep the feature disabled with a clear unavailable state. No UI should claim that branch scope, journal posting, structured sync, or new report data is active until the live RPC and table contract has been verified.

## Rollback posture

Prefer forward corrective migrations. Do not drop tables or columns during an incident. Disable the affected feature flag or route, preserve audit and sync records, correct the schema or function in a new migration, and re-run the affected regression tests. Any destructive contract change requires an approved expand/migrate/contract sequence and a separate data restoration plan.
