# Mizan Scale and Windows Build Plan

## Executive position

Mizan can be engineered toward very large multi-tenant workloads, but no responsible implementation can guarantee that every request will complete in one or two seconds for more than one million users without a defined workload, provisioned Supabase tier, indexes, cache strategy, concurrency target, device profile, and measured load-test evidence. The target is therefore treated as a service-level objective for bounded operations, not a blanket promise for reports, exports, first-time synchronization, or cold mobile launches.

The current codebase has two concrete scale risks. Several authenticated tenant-wide realtime streams materialize complete customer, vendor, invoice, bill, staff, and invitation sets and then cache every returned row in Drift. Several server list methods also return unbounded arrays. These patterns are acceptable for small tenants but are not a safe basis for million-record tenants. Accounting reports are already server-RPC based, which is the correct direction for large datasets.

## Acceptance targets

| Area | Initial measurable target | Evidence required |
|---|---:|---|
| Tenant-scoped detail read | p95 ≤ 500 ms at the agreed concurrency | Staging load test with `EXPLAIN (ANALYZE, BUFFERS)` and request timings |
| Bounded list page | p95 ≤ 1 s for up to 100 rows | Keyset cursor tests over representative high-cardinality data |
| Dashboard summaries | p95 ≤ 2 s | Server aggregation timings and cold/warm measurements |
| Large report/export | Asynchronous or streamed; no 2-second blanket promise | Job status, bounded chunks, memory profile, and completion time |
| Mobile/desktop cache | No full-tenant materialization by default | Drift row counts, sync window, and memory measurements |
| Windows debug build | Clean build on a documented supported toolchain | `flutter doctor -v`, `flutter pub get`, `flutter build windows` log |
| Windows release build | Clean signed/unsigned release build on CI and a developer PC | CI artifact, local artifact, and dependency/network diagnostics |

## Implementation order

First, add server-authoritative keyset page contracts for high-cardinality lists. The cursor is `(updated_at, id)`, with a tenant-leading query and a hard maximum page size. Existing realtime streams remain compatibility paths while screens migrate to bounded pages and delta synchronization; they must not be described as million-record safe.

Second, retain server-side aggregation for trial balance, balance sheet, profit and loss, aging, and dashboard summaries. Any new report must return grouped rows or a bounded result, never an entire journal-line universe to the client. Add query-plan checks and tenant-leading indexes only through additive migrations after schema inspection.

Third, tune Drift conservatively for concurrent cache/outbox access, but treat Drift as a local cache rather than a second authoritative database. Local cache limits, eviction, sync windows, retry backoff, and conflict handling must be explicit.

Fourth, make Windows builds reproducible. The repository must document the Flutter channel, Visual Studio Desktop C++ workload, Windows SDK, CMake/Ninja, Java, Android tooling where applicable, package-registry endpoints, and proxy overrides. Network failures must be separated from CMake/MSBuild failures. No script may print secrets.

## Non-negotiable correctness constraints

Every page and RPC remains tenant-scoped and RLS-protected. Cursor pagination must use a deterministic tie-breaker and must never bypass authorization. Posted accounting facts remain immutable. Performance migrations are additive and must be tested in disposable or staging Supabase only; production application requires explicit approval. A faster query that leaks another tenant, skips rows, duplicates rows, or weakens auditability is a defect.

## Windows failure interpretation

The sandbox build attempt exposed two environment issues rather than a Flutter source compile error: the first attempt lacked an Android SDK, and the later Gradle attempt used a full Java runtime without a compiler until a JDK was installed; an earlier daemon also disappeared under an 8 GB heap request on a 3.8 GB host. The Android Gradle memory settings were reduced and should remain conservative. Windows cannot be proven from Linux; final Windows acceptance requires the user’s Windows machine or CI with Visual Studio and the documented network endpoints.

## Next measured work

The next scale slice is to migrate the main customer, vendor, invoice, bill, staff, and invitation screens from full-tenant snapshots to keyset pages and bounded local sync windows. The next Windows slice is to run the diagnostics script on the affected PC, record the exact endpoint/toolchain failure, and then fix only the identified class of failure. Model binaries and provider credentials remain outside Git.

## Windows commands

From the repository root in PowerShell, use the scripts now located under `scripts/`:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows_build_diagnostics.ps1 -RunFlutterDoctor -RunPubGet
.\scripts\build_windows.ps1 -Configuration debug -SkipPubGet
```

The diagnostics report is written to `windows-build-diagnostics/`. If dependency resolution fails, preserve the report and check the endpoint, proxy, `PUB_HOSTED_URL`, `FLUTTER_STORAGE_BASE_URL`, Visual Studio Desktop C++ workload, Windows SDK, CMake, and Ninja. If dependency resolution passes but CMake or MSBuild fails, the failure is local toolchain/configuration rather than an ISP diagnosis. Do not paste provider keys or other secrets into the report.
