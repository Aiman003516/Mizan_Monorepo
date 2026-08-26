# Mizan End-to-End Persistence and Workflow Audit

## Executive conclusion

The intermittent “saved but not visible” behavior was not one defect. It came from several interacting paths: authenticated CRM repositories depended on Supabase Realtime for active streams, vendor edits lacked the customer-equivalent offline retry path, queued partial updates could replace a previously queued insert payload, some status mutations bypassed cloud persistence, and authenticated sessions could briefly be treated as guest-local while tenant membership was still resolving. The affected code has been repaired without applying SQL to production.

The application remains deliberately **local-first for genuine guests** and **Supabase-first for authenticated tenant sessions**. Drift remains the local cache and outbox; Supabase remains the tenant-authoritative source for cloud CRM records. Authorization and tenant scope remain enforced by Supabase RLS/RPC contracts rather than UI visibility.

## System map

| Layer | Responsibility | Verified implementation |
|---|---|---|
| Flutter presentation | Validates fields, awaits writes, displays success/error state, and invalidates parent providers after navigation | Customer/vendor forms, document forms, product/account/settings forms, and report workflows |
| Feature repositories | Selects local or cloud path and translates UI inputs into persistence operations | `ar_repository.dart`, `ap_repository.dart`, feature repositories |
| Cloud CRM bridge | Supabase CRUD/RPC, write-through Drift cache, and tenant-scoped retry queue | [`cloud_crm_repository.dart`](../packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart) |
| Drift database | Guest persistence, offline cache, and durable mutation queue | [`core_database`](../packages/core/core_database) and `sync_queue_entries` |
| Generic sync engine | Synchronizes non-CRM tables through `synced_*` shadow tables | [`cloud_sync_service.dart`](../packages/features/feature_sync/lib/src/data/cloud_sync_service.dart) |
| Supabase migrations | Canonical tables, RLS, RPCs, audit functions, accounting contracts, and realtime publication | [`supabase/migrations`](../supabase/migrations) |
| Supabase Realtime | Live remote changes for cloud CRM list/detail streams | `20260825190000_enable_realtime_publication.sql` |

## Migration and RPC inventory

The canonical application migration directory is `app_main/supabase/migrations`. The repository also contains a legacy root-level `supabase/migrations` directory; it is not the current full Mizan schema. Deploying only the root directory would omit the tenant-scoped CRM, accounting, AI, outbox, and workflow migrations.

| Check | Result |
|---|---:|
| Canonical app migration files | 29, including the balance consistency repair and authenticated CRM wrapper migrations |
| Supabase functions declared in canonical migrations | 99 distinct function names |
| RPC names called from Dart | 55 distinct names |
| Dart RPC names absent from the migration inventory | 0 |
| Accounting/CRM workflow RPCs found but not directly called by ordinary Flutter CRUD | Update, archive, void, balance-adjustment, journal-posting, and AI execution contracts are available for governed workflows |

The migration sequence is timestamp ordered from the legacy compatibility preflight through cloud source of truth, employee and owner controls, AI phases, accounting ledger foundations, CRM pipeline, tax/revenue/settlement workflows, inventory/POS bridge, CRM 360, transactional outbox, document intake, extension registry, and the new CRM balance consistency repair. The migration files are committed for controlled deployment, but **no production migration was executed by this audit**.

## Write-path findings

### Cloud CRM writes

Customer, vendor, invoice, and bill list/detail screens use `CloudCrmRepository` when `cloudDataModeProvider` resolves an authenticated tenant. Successful cloud writes now write the authoritative response back into Drift. Retryable failures materialize a tenant-scoped local row and enqueue a durable mutation for later replay.

Before this repair, customer updates had an offline fallback but vendor updates did not. Vendor edits could therefore fail during a transient network interruption without becoming locally visible or retryable. Customer and vendor edits also used direct table updates even though the repository already contained tenant-scoped update RPCs with permission checks and optimistic-concurrency validation. The repaired path calls `update_customer_for_tenant` or `update_vendor_for_tenant` with the cached `updated_at` version, then caches the committed response.

### Queued mutation replay

The queue previously used `insertOrReplace` with the same `${table}_$recordId` key for every operation. If a new offline record was queued as an insert and edited before connectivity returned, the later update could replace the complete insert payload with only changed fields. A replaying upsert could then omit required columns or fail to represent the final row. The queue now coalesces insert-plus-update mutations into one complete insert payload. Existing rows continue to use partial updates, and replay now uses tenant-scoped `UPDATE` for update operations rather than treating every non-delete mutation as an upsert.

Queued deletes and updates now verify that a row was actually affected before the queue entry is marked successful. A tenant mismatch, missing row, or RLS-filtered operation therefore remains retryable and observable instead of being silently discarded.

### Reactive UI behavior

When a remote Supabase stream fails, the CRM watchers previously performed one local query and then stopped reacting. A local write could complete but the active UI would not observe later Drift changes. Customer, invoice, vendor, and bill fallback streams now remain live Drift watches. The parent screens also invalidate their providers after successful form navigation, so the normal online path reopens the stream and re-reads the committed row.

Realtime still requires the migration and project publication settings to be applied in Supabase. The code cannot prove that a user’s remote project has executed that migration; the deployment runbook remains the authority for that step.

### Authenticated tenant-resolution race

During sign-in, a Supabase session can exist before active `staff_members` membership resolution finishes. The previous boolean cloud-mode provider could briefly select guest-local repositories. A write during that window could be stored without a tenant scope and would not be uploaded to the tenant later. The provider now keeps an authenticated session on the cloud path while tenant resolution is in progress. This avoids silent unscoped writes; if membership is genuinely absent, the operation fails rather than pretending the cloud write succeeded.

### Status mutations

Invoice and bill status methods previously wrote only to local Drift even when the application was in authenticated cloud mode. They now delegate to tenant-scoped cloud status methods that write through to Supabase, cache the returned row, and queue retryable network failures.

### Balances

The new migration [`20260827291000_repair_crm_balance_consistency.sql`](../supabase/migrations/20260827291000_repair_crm_balance_consistency.sql) adds guarded database triggers for invoice and bill lifecycle changes. The triggers apply the delta in outstanding amount rather than overwriting the balance column, preserving opening balances and separately posted manual adjustments. They handle insert, update, reassignment, and delete cases. The migration is intentionally not auto-applied because production schema changes require explicit approval and a backup/rollback checkpoint.

## Workflow matrix

| Workflow | Guest/local behavior | Authenticated tenant behavior | Refresh strategy | Result of audit |
|---|---|---|---|---|
| Create customer | Atomic Drift transaction, including optional opening-balance entries | Supabase insert, then Drift cache; retryable failures queue | Customer list/detail invalidation plus stream | Verified and repaired around cloud edit symmetry |
| Edit customer | Awaited Drift update; watched query emits | Tenant-scoped update RPC with `updated_at` concurrency; retryable fallback | Parent invalidation and live fallback watch | Repaired |
| Create vendor | Atomic Drift transaction, including optional opening-balance entries | Supabase insert, then Drift cache; retryable failures queue | Vendor list/detail invalidation plus stream | Verified |
| Edit vendor | Awaited Drift update; watched query emits | Tenant-scoped update RPC with `updated_at` concurrency; retryable fallback now matches customer | Parent invalidation and live fallback watch | Repaired |
| Create invoice/bill | Atomic Drift header/items write | Existing protected create RPC; response cached | Detail provider invalidation | Verified; balance trigger added for deployed cloud schema |
| Invoice/bill status | Drift update | Tenant-scoped Supabase update and cache | Parent/detail invalidation | Repaired |
| Customer/vendor quick adjustment | Local journal transaction | Existing UI path has no ordinary manual cloud RPC contract; it must not be treated as a cloud success without a governed server workflow | Explicit workflow review required | Identified for follow-up; AI balance adjustment RPC exists separately |
| Customer/vendor payment | Local Drift payment/allocation transaction | No ordinary cloud payment call site was found; settlement drafts are a separate governed RPC workflow | Explicit workflow review required | Identified; not silently advertised as cloud-complete |
| Products/categories | Drift writes and Drift streams; generic sync pushes `synced_*` envelopes for tenant mode | Local cache plus generic sync engine | Reactive Drift watchers | Control path verified; shadow-table deployment must remain aligned |
| Accounts/journals | Drift repositories and accounting services; governed cloud contracts exist for newer ledger workflows | Cloud availability varies by feature contract | Provider invalidation or Drift watch | Requires workflow-by-workflow deployment testing |
| Settings/owner controls | Awaited local or direct tenant-scoped repository writes | RLS/RPC-controlled where cloud contracts exist | Screen-specific invalidation/reload | Static analysis completed; live authorization remains environment-dependent |
| AI actions | Guest local assistant remains proposal-only | Authenticated execution is confirmation-gated and server-authoritative | AI request/action result state | No autonomous execution or source-file editing enabled |

## Remaining risks and required environment checks

The static and local tests cannot prove that the user’s Supabase project has applied every migration in the canonical order. The project owner must verify the migration history, Realtime publication membership, function privileges, RLS policies, and schema health in the target project. A production SQL migration was not applied during this task.

The generic sync engine synchronizes a defined set of tables through `synced_*` shadow tables and does not replace the cloud CRM repository. This split is intentional in the current architecture, but each feature must use the correct repository path. Adding a new entity requires both a server contract and a refresh/replay contract; adding only a local Drift table is insufficient for authenticated source-of-truth behavior.

Manual cloud payments and manual cloud quick adjustments need a dedicated, ordinary-user server workflow if they are to be enabled outside the existing AI action and settlement-draft contracts. They should not be implemented by silently writing local Drift rows in authenticated mode. This is a correctness and auditability boundary, not a UI limitation.

## Verification performed

| Verification | Result |
|---|---|
| `core_data` analysis after persistence changes | Passed with no issues |
| `core_data` tests after persistence changes | Passed: 41 tests |
| `feature_sync` tests | Passed: 2 tests |
| `feature_settings` tests | Passed: 12 tests |
| `feature_reports` tests | Passed: 4 tests |
| `feature_ai` tests | Passed: 36 tests |
| Queue insert-plus-update regression test | Passed |
| Guest customer/vendor edit regression test | Passed |
| RPC name cross-check against migration inventory | 0 missing client RPC names |
| `git diff --check` | Passed |
| Supabase pgTAP regression file added | `tests/crm_persistence_consistency.sql`; execution requires a disposable/project test database |
| Production Supabase migration | Not run; requires explicit approval |
| Authenticated Supabase/Realtime execution | Not run in this sandbox |
| Physical-device UI, keyboard, RTL, and live provider behavior | Not claimed; requires device/project verification |

## Files changed by this repair wave

| File | Purpose |
|---|---|
| `packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart` | RPC-backed customer/vendor updates, vendor retry fallback, cloud invoice/bill status updates, reactive local fallbacks, and safer queued replay |
| `packages/core/core_data/lib/src/repositories/ar_repository.dart` | Route invoice status changes to cloud persistence when authenticated |
| `packages/core/core_data/lib/src/repositories/ap_repository.dart` | Route bill status changes to cloud persistence when authenticated |
| `packages/core/core_data/lib/src/services/sync_queue_service.dart` | Coalesce offline insert/edit mutations and preserve complete payloads |
| `packages/core/core_data/lib/src/providers/cloud_data_mode_provider.dart` | Prevent authenticated-session writes from silently entering guest-local mode during tenant resolution |
| `packages/core/core_data/test/sync_queue_service_test.dart` | Regression test for complete queued payload coalescing |
| `packages/core/core_data/test/guest_local_invoice_test.dart` | Regression test for immediate local customer/vendor edit visibility |
| `supabase/migrations/20260827291000_repair_crm_balance_consistency.sql` | Tenant-scoped invoice/bill balance-delta triggers for controlled deployment |
| `supabase/migrations/20260827292000_crm_edit_rpc_wrappers.sql` | Authenticated tenant-derived CRM edit wrappers around the AI-only helper contracts |
| `supabase/tests/crm_persistence_consistency.sql` | SQL regression checks for triggers and wrapper privileges |
| `docs/MIZAN_PERSISTENCE_WORKFLOW_AUDIT.md` | This audit and workflow register |

## References

[1]: ../packages/core/core_data/lib/src/repositories/cloud_crm_repository.dart "Cloud CRM repository"
[2]: ../packages/core/core_data/lib/src/services/sync_queue_service.dart "Durable sync queue"
[3]: ../packages/core/core_data/lib/src/providers/cloud_data_mode_provider.dart "Cloud data mode provider"
[4]: ../packages/features/feature_sync/lib/src/data/cloud_sync_service.dart "Generic cloud sync service"
[5]: ../supabase/migrations/20260825123000_cloud_source_of_truth.sql "Canonical cloud source-of-truth migration"
[6]: ../supabase/migrations/20260825190000_enable_realtime_publication.sql "Realtime publication migration"
[7]: ../supabase/migrations/20260827150000_ai_action_expansion_phase4.sql "Governed AI action and balance-adjustment contracts"
