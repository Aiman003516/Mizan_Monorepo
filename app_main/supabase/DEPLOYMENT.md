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

The read-only Mizan AI Copilot requires migration `20260827100000_ai_agent_phase1.sql` and the Edge Function at `functions/mizan-ai-agent`. Deploy the function only after the migration is applied. Configure `OPENAI_API_KEY` and optional `MIZAN_AI_MODEL`/`MIZAN_AI_BASE_URL` as Supabase Function secrets; never place provider credentials in Flutter or Git. The function derives the tenant from the authenticated `staff_members` membership, uses the user-scoped client for RLS-protected reads, exposes only bounded read-only tools, and records minimal tenant/user-scoped conversation and audit events. Guest mode must remain local and must not call this function.

```bash
supabase functions deploy mizan-ai-agent --project-ref eawkctancunjpatujzpu
supabase secrets set --project-ref eawkctancunjpatujzpu OPENAI_API_KEY=... MIZAN_AI_MODEL=gpt-5-mini MIZAN_AI_BASE_URL=https://api.openai.com/v1
```

Before enabling the feature for users, test an owner, an ordinary member, a guest, and a user from a second tenant. Confirm read-only answers, permission-safe failures, provider-unavailable handling, no cross-tenant data, no secrets in logs, and audit events for request/tool/response/error outcomes. Mutation and scheduled-agent phases require separate review and migrations.

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

If the project contains migrations that were applied manually and are not present in the local migration history, do not run `supabase db push` blindly. Use the SQL Editor for the three AI migration files, or reconcile migration history first. The repository sandbox does not contain a Supabase CLI, so the SQL Editor procedure is the safe available path here.

After applying Phase 3, verify the schema and privileges with:

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

The expected privilege results are `false`, `false`, `false`, and `true`, respectively. Run the pgTAP file `tests/ai_action_execution_phase3.sql` in a disposable or test project before production. Then test the runtime matrix with an owner, a restricted staff member, a guest session, and users belonging to separate tenants: create a draft, confirm it once with its token, retry the same confirmation, attempt a wrong token, attempt an expired draft, and verify that a failed action leaves no partial invoice, bill, CRM, or invitation records. Review `ai_action_requests`, `ai_audit_events`, and the relevant business audit rows after every test.

Keep the provider secret server-side. Configure `OPENAI_API_KEY`, and optionally `MIZAN_AI_MODEL` and `MIZAN_AI_BASE_URL`, with Supabase Function Secrets. Never put the service-role key or provider key in Flutter, SQL payloads, Git, or client logs. Take a database backup before applying Phase 3 to populated production data and deploy `mizan-ai-action` only after the SQL migration succeeds.
