# Mizan Supabase Source-of-Truth Deployment

The migration in `migrations/20260825123000_cloud_source_of_truth.sql` creates canonical tenant-scoped CRM, invoice, bill, role, staff, currency, custom-field, audit, and legacy-cache-envelope tables. It also creates indexes, RLS policies, protected RPCs for business bootstrap and document creation, and audit triggers.

## Apply the migration

The connected Supabase Data API accepts authenticated REST queries, but the current session key does not have DDL privileges and no direct Postgres connection is available in the build environment. Apply the migration once in the Supabase SQL Editor or with the Supabase CLI using the project’s database credentials. Apply the complete file as one migration; do not copy individual policy fragments out of order. If an earlier run stopped with `ERROR: 42703: column "status" does not exist`, pull the latest repository version and rerun the complete file: the compatibility block now adds legacy `staff_members.status` and invite lifecycle columns before creating their indexes and policies. The migration also uses JSONB for role permissions, matching the existing `roles.permissions` column.

After applying it, apply `migrations/20260827100000_ai_agent_phase1.sql` for the read-only Copilot conversation and audit schema. Apply `migrations/20260827110000_ai_action_requests_phase2.sql` only when the draft-action endpoint is being enabled; it stores confirmation-gated previews and does not execute business mutations. Deploy `functions/mizan-ai-agent` after the Phase 1 AI migration, and deploy `functions/mizan-ai-action` only when the action-draft workflow is ready. Keep the SQL migrations and function deployments in this order.

After applying it, run the SQL in `tests/cloud_source_of_truth.sql` with the project’s database test runner. The supplied schema export shows the legacy tables are currently empty, so no data conversion is expected for the first successful run; retain a database backup before applying to a populated project. The Data API probe should then return HTTP 200 for `currencies`, `custom_fields`, `customers`, `vendors`, `invoices`, `invoice_items`, `bills`, `bill_items`, and `audit_logs`.

## Realtime and client configuration

Enable Realtime for the canonical tables used by list/detail screens: `customers`, `vendors`, `invoices`, `invoice_items`, `bills`, `bill_items`, `roles`, `staff_members`, `currencies`, and `custom_fields`. Configure the Flutter app with the Supabase project URL and publishable key through the existing environment configuration. Never ship a service-role key in the Flutter application.

## Data migration and rollout

Existing local Drift data should be exported and staged before importing into the canonical tables. A migration script must map legacy string identifiers to UUIDs, preserve tenant ownership, validate customer/vendor references, and recalculate invoice and bill totals from line items. Do not bulk-import unvalidated local rows directly into production. During the first rollout, keep Drift as the cache and retain the Google Drive backup path so a user can restore the local SQLite cache, including the durable sync outbox table.

## Offline behavior

Online CRM and document writes target Supabase first. Temporary network failures can materialize a tenant-scoped Drift row and an outbox entry. The synchronization engine replays pending outbox entries in bounded batches, while the existing Google Drive service backs up the complete SQLite file through `VACUUM INTO`; this includes cache tables and pending outbox entries. Authorization failures, validation errors, and RLS denials are not treated as offline successes.

## AI Copilot deployment

The Mizan AI Copilot requires migration `20260827100000_ai_agent_phase1.sql` and the Edge Function at `functions/mizan-ai-agent`. Deploy the function only after the migration is applied. For the attached OpenRouter workflow, configure `OPENROUTER_API_KEY`, `MIZAN_AI_BASE_URL=https://openrouter.ai/api/v1`, and optional `MIZAN_AI_MODELS`/`MIZAN_AI_MODEL` as Supabase Function secrets; never place provider credentials in Flutter or Git. The function discovers the configured model IDs from OpenRouter’s `/models` endpoint, retains only models advertising tool support, and uses the reference fallback list if discovery is unavailable. It derives the tenant from the authenticated `staff_members` membership, uses the user-scoped client for RLS-protected reads, exposes only bounded tools, prepares proposals without mutations, and records minimal tenant/user-scoped conversation and audit events. Guest mode must remain local and must not call this function.

```bash
supabase functions deploy mizan-ai-agent --project-ref eawkctancunjpatujzpu
supabase functions secrets set --project-ref eawkctancunjpatujzpu OPENROUTER_API_KEY=... MIZAN_AI_BASE_URL=https://openrouter.ai/api/v1 MIZAN_AI_MODELS=...
```

Before enabling the feature for users, test an owner, an ordinary member, a guest, and a user from a second tenant. Confirm read-only answers, structured draft proposals only for explicit create requests, permission-safe failures, provider-unavailable handling, no cross-tenant data, no secrets in logs, and audit events for request/tool/response/error outcomes. After the user reviews a proposal, confirm that the Flutter client calls `mizan-ai-action`, receives a one-time confirmation token, and displays the committed or safely failed result. Mutation and scheduled-agent phases require separate review and migrations.

## AI action expansion Phase 4

Phase 4 adds typed proposals and confirmed execution for `customer_update`, `vendor_update`, `invoice_update`, `bill_update`, `balance_adjustment`, `journal_entry_post`, `customer_archive`, `vendor_archive`, `invoice_void`, and `bill_void`. The action service revalidates the exact target tenant and permission, captures an `updated_at` concurrency value, and rejects a stale preview. Invoice edits are limited to draft invoices; bill edits are limited to pending bills. Paid or previously voided documents cannot be deleted or voided through AI.

Balance adjustments are not direct arbitrary balance writes. They require a positive amount, a debit account, a credit account, a reason, the tenant base currency, and an exact target timestamp. The server inserts two equal and opposite ledger entries and updates the customer/vendor balance in one transaction. Journal posting requires two to 100 non-zero lines, tenant-owned accounts, and a debit-credit sum of zero. Hard-delete AI RPCs do not exist; posted accounting records must use a protected void or reversal workflow.

Apply `migrations/20260827150000_ai_action_expansion_phase4.sql` after the Phase 3 migration, or use the refreshed `AI_PHASE_1_2_3_COMBINED.sql` file. The internal tenant-explicit helper RPCs are revoked from direct client execution; authenticated clients receive access only to `execute_ai_action(uuid,uuid)`. Run `tests/ai_action_expansion_phase4.sql` in a disposable project.

The Phase 4 rollout must test, in order, a CRM edit, a draft-invoice edit, a draft-bill edit, a base-currency balance adjustment, a balanced journal, an unbalanced journal rejection, a stale-preview rejection, an unauthorized-user rejection, a cross-tenant identifier rejection, a paid-document void rejection, and a repeated confirmation. Confirm that each successful mutation has both an `ai_audit_events` row and an `audit_logs` row, and that failed actions leave no partial business data.

Application source-code editing remains outside the accounting Copilot. If a developer assistant is introduced later, it must be a separate local-only patch generator with no production database credentials and no automatic file application.

## CRM persistence repair migration

Apply `migrations/20260827291000_repair_crm_balance_consistency.sql` after the existing CRM, invoice, bill, and settlement migrations. It installs tenant-scoped invoice/bill balance-delta triggers without overwriting opening balances or separately posted adjustments. Then apply `migrations/20260827292000_crm_edit_rpc_wrappers.sql`; it grants authenticated clients access only to tenant-derived `update_customer` and `update_vendor` wrappers while keeping the AI-only `*_for_tenant` helpers revoked from direct clients. Next apply `migrations/20260827293000_manual_balance_adjustment_workflow.sql`; it installs the durable adjustment register, realtime publication entry, RLS, audit hooks, and the atomic double-entry `post_manual_balance_adjustment` RPC. Run `tests/crm_persistence_consistency.sql` and `tests/manual_balance_adjustment_workflow.sql` in a disposable or project test database after the migrations. Do not apply these migrations to production without an approved backup, migration-state check, and rollback plan.

The Flutter cloud edit implementation depends on the wrapper migration. The enhanced manual adjustment flow additionally depends on `post_manual_balance_adjustment` and `balance_adjustments`. If these contracts are absent, the app must not be switched to an authenticated cloud build that uses the repaired customer/vendor adjustment path.

## Production checks

Before release, verify email-confirmation behavior, session refresh, tenant bootstrap, invite validation/redemption, RLS isolation with two test users from different tenants, system-admin immutability, role permission enforcement, atomic invoice/bill creation, duplicate currency/custom-field constraints, pagination behavior, offline creation and replay, and Google Drive backup/restore on a physical Android device. Confirm that the SQL migration is applied before enabling the cloud-mode build flag.

## AI action execution Phase 3

Phase 3 enables actual execution only after an authenticated user supplies the one-time confirmation token issued with the draft. The database function revalidates the request owner, exact tenant membership, expiry, status, and permissions, then calls the protected invoice, bill, CRM, or bulk-invitation RPC inside the same transaction. It records `executed` or `failed` state and writes an AI audit event. Guest sessions cannot call the function, and direct client access to AI tables remains revoked.

Apply `migrations/20260827130000_ai_action_execution_phase3.sql` only after `20260827110000_ai_action_requests_phase2.sql`. Run `tests/ai_action_execution_phase3.sql` after the migration. In the Supabase SQL Editor, use one query tab per migration, paste the complete file contents from the repository, run each file in order, and stop immediately if any statement fails. Do not enable the production UI action button until the verification query passes.

The CLI sequence, when the Supabase CLI is installed and authenticated, is:

```bash
supabase link --project-ref eawkctancunjpatujzpu
supabase db push
supabase functions deploy mizan-ai-agent --project-ref eawkctancunjpatujzpu
supabase functions deploy mizan-ai-action --project-ref eawkctancunjpatujzpu
```

If the project contains migrations that were applied manually and are not present in the local migration history, do not run `supabase db push` blindly. Use the SQL Editor for the four AI migration files, or use the refreshed combined script, or reconcile migration history first. The repository sandbox does not contain a Supabase CLI, so the SQL Editor procedure is the safe available path here. The combined file now contains AI Phase 1, Phase 2, Phase 3, and Phase 4 in order.

After applying Phase 3 and Phase 4, verify the schema and privileges with:

```sql
select to_regclass('public.ai_action_requests') as action_requests,
       to_regprocedure('public.execute_ai_action(uuid,uuid)') as execute_function;
select attname, attnotnull
from pg_attribute
where attrelid = 'public.ai_action_requests'::regclass
  and attname in ('confirmation_token', 'execution_result', 'execution_error')
  and not attisdropped;
select has_table_privilege('anon', 'public.ai_action_requests', 'SELECT') as anon_can_read,
       has_table_privilege('authenticated', 'public.ai_action_requests', 'SELECT') as authenticated_can_read,
       has_function_privilege('anon', 'public.execute_ai_action(uuid,uuid)', 'EXECUTE') as anon_can_execute,
       has_function_privilege('authenticated', 'public.execute_ai_action(uuid,uuid)', 'EXECUTE') as authenticated_can_execute;
```

The expected AI-table/execution privilege results are `false`, `false`, `false`, and `true`, respectively. The Phase 4 direct-helper check must also be `false`. Run the pgTAP file `tests/ai_action_execution_phase3.sql` in a disposable or test project before production. Then test the runtime matrix with an owner, a restricted staff member, a guest session, and users belonging to separate tenants: create a draft, confirm it once with its token, retry the same confirmation, attempt a wrong token, attempt an expired draft, and verify that a failed action leaves no partial invoice, bill, CRM, or invitation records. Review `ai_action_requests`, `ai_audit_events`, and the relevant business audit rows after every test.

Keep the provider secret server-side. Configure `OPENAI_API_KEY`, and optionally `MIZAN_AI_MODEL` and `MIZAN_AI_BASE_URL`, with Supabase Function Secrets. Never put the service-role key or provider key in Flutter, SQL payloads, Git, or client logs. Take a database backup before applying Phase 3 to populated production data and deploy `mizan-ai-action` only after the SQL migration succeeds.

## Approval enforcement Phase 3

Apply `migrations/20260828000000_approval_enforcement_phase3.sql` only after `20260827293000_manual_balance_adjustment_workflow.sql` and the platform branch foundation are present. This migration adds branch scope and idempotency to approval requests, creates append-only `approval_request_events`, removes direct authenticated table mutations, and exposes only `create_approval_request` and `decide_approval_request` for authenticated workflow changes. It does not apply itself to any Supabase project from this repository session.

Run `tests/20260828000000_approval_enforcement_phase3.sql` in a disposable or staging database with the canonical migrations applied. Verify that a requester can create a pending request, cannot decide their own request, an authorized approver can decide only within the permitted tenant/branch scope, a second decision is rejected, request facts cannot be edited, and event rows cannot be updated or deleted. Verify the `approval_requests` and `approval_request_events` grants and policies before enabling any UI action gate.

The current migration provides the governed approval contract and decision audit trail. Individual accounting or CRM commands must call an approval-aware server RPC before they are considered approval-enforced; do not treat a client-side threshold or `SharedPreferences` flag as authorization. No production SQL should be applied without an approved backup, migration-state check, staging verification, and explicit user approval.

## Approval-aware balance adjustment gate

Migration `migrations/20260828010000_approval_balance_adjustment_gate.sql` adds the first approval-consuming accounting command. It requires an approved `balance_adjustment` request whose target, amount, currency, and reason exactly match the requested posting, atomically marks the request consumed, delegates to the canonical double-entry balance-adjustment RPC, and records one append-only execution row. Replaying or changing the approved request is rejected.

This migration is an additive contract for the next client workflow. Do not revoke the legacy posting grant or enable this gate in production until the Flutter balance-adjustment flow creates, displays, and submits the approval request identifier through the new RPC. Run `tests/20260828010000_approval_balance_adjustment_gate.sql` in staging first; production SQL still requires explicit approval.

## Party statement read contract

Migration `migrations/20260828020000_party_statements.sql` adds the tenant-safe `public.party_statement(text, uuid, date, date)` read RPC. It combines non-void invoices or bills, posted settlements, and posted balance adjustments into a reproducible statement with opening balance, debit, credit, balance delta, currency, and running balance fields. The function is read-only, derives the tenant from the authenticated context, and is not executable by anonymous or public roles.

Run `tests/20260828020000_party_statements.sql` in staging after the AR/AP settlement and balance-adjustment migrations. Verify that the statement totals agree with the source documents, posted settlement journals, and adjustment register for each tested tenant, branch, period, and currency. No production SQL is implied by the presence of this file.

## Month-end close preflight

Migration `migrations/20260828030000_close_preflight.sql` adds the tenant-scoped `public.accounting_close_preflight(uuid)` read RPC. It checks period status, pending approvals, draft journals, unposted settlements, open document anomalies, and the active leading accounting book. The result is evidence-oriented and returns severity, blocking status, issue count, and a message for each check.

Run `tests/20260828030000_close_preflight.sql` in staging after the accounting, approval, settlement, document-anomaly, and party-statement migrations. The preflight is a readiness check, not an automatic period-close command; a separate owner-authorized close action must remain server-enforced.

## Retry-safe settlement drafts

Migration `migrations/20260828040000_settlement_idempotency.sql` adds a tenant-scoped idempotency key to `ar_ap_settlements` and the `public.create_settlement_draft_idempotent(...)` RPC. The RPC serializes retries with a transaction advisory lock, returns the existing draft for a repeated key, and delegates new drafts to the canonical settlement command.

Run `tests/20260828040000_settlement_idempotency.sql` in staging and verify that repeated client retries return the same settlement identifier and journal draft rather than creating duplicate financial effects. No production grant or migration application is implied by this repository change.

## Procure-to-pay foundation

Migration `migrations/20260828050000_procurement_foundation.sql` adds purchase requisitions, purchase orders and lines, purchase receipt/return evidence, vendor-bill and bill-line linkage, procurement approval request types, and the `purchase_bill_three_way_match(uuid)` read RPC. Requisition and purchase-order submission creates immutable approval requests. Receipt and return quantities are checked against ordered and posted quantities. Three-way matching reports line-level ordered, received, returned, available, and billed quantities plus unit-price variance and a blocking reason.

Procurement workflow tables are tenant/branch scoped, protected by RLS, readable only to authenticated tenant members, and mutated through security-definer RPCs with permission checks and audit triggers. The first receipt/return posting commands record procurement evidence and update purchase-order lifecycle state; they do not claim to replace the existing inventory accounting bridge until a dedicated adapter is implemented and verified.

Run `tests/20260828050000_procurement_foundation.sql` in a disposable/staging database after all listed prerequisites. Verify approval state synchronization, duplicate-document rejection, tenant isolation, branch isolation, quantity-overrun rejection, return-over-receipt rejection, vendor mismatch blocking, currency mismatch blocking, and bill-over-receipt blocking. No production SQL is applied automatically.

## Procurement-to-inventory adapter

Migration `migrations/20260828060000_procurement_inventory_adapter.sql` adds immutable tenant-scoped links from posted procurement receipt/return lines to the existing inventory accounting draft records, an inventory-return draft command, and return handling in the existing inventory-posting trigger. The adapter requires procurement, inventory, accounting, and settings permissions because it creates accounting journal drafts; it does not post those drafts or directly mutate `inventory_balances`. Inventory quantity and average cost change only when the linked inventory journal entry is posted through the existing accounting workflow.

Run `tests/20260828060000_procurement_inventory_adapter.sql` in staging after the procurement foundation and inventory bridge migrations. Exercise a posted receipt and return with product lines, verify one link per source line, retry the adapter and confirm `already_linked` without duplicate drafts, post the generated journal drafts through the governed accounting path, and verify stock changes and audit rows. Also verify branch access, account-type validation, tenant isolation, insufficient-stock rejection for returns, and anonymous execution denial. No production SQL is applied automatically; production application requires explicit approval and a recorded deployment verification.

## Purchase-bill match eligibility gate

Migration `migrations/20260828070000_purchase_bill_match_gate.sql` adds `assert_purchase_bill_match(uuid)`. It consumes the canonical three-way evidence and rejects any non-void bill with a blocked line; a future bill approval/posting command must call this gate server-side. The gate only returns eligibility evidence and does not post the bill, create a journal, or approve an exception.

Run `tests/20260828070000_purchase_bill_match_gate.sql` in staging and verify the RPC exists, derives tenant scope from the session, rejects blocked evidence, returns `eligible_for_posting_gate` for a fully matched bill, and cannot be executed by anonymous or public roles. Production application remains subject to explicit approval and a recorded staging result.
