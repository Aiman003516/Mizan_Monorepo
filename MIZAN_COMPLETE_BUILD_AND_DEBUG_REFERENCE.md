# Mizan Complete Build, Model, Debugging, and Verification Reference

**Project:** Mizan Accounting and CRM System
**Repository:** `https://github.com/Aiman003516/Mizan_Monorepo`
**Working branch:** `main`
**Application directory:** `app_main/apps`
**Reference author:** Manus AI

> This file is a practical reference for rebuilding the project, preparing the local Qwen3 model, diagnosing Windows problems, running verification, and understanding which capabilities are proven versus still pending.

## 1. Repository layout and important paths

| Purpose | Path |
|---|---|
| Flutter application | `app_main/apps` |
| Flutter workspace manifest | `app_main/pubspec.yaml` |
| Canonical Supabase migrations | `app_main/supabase/migrations` |
| Migration registry | `app_main/supabase/MIGRATION_REGISTRY.md` |
| SQL verification files | `app_main/supabase/tests` |
| Local AI feature | `app_main/packages/features/feature_ai` |
| Windows runner | `app_main/apps/windows` |
| Android runner | `app_main/apps/android` |
| Local model asset | `app_main/apps/assets/local_ai/Qwen_Qwen3-0.6B-Q4_K_M.gguf` |
| Model preparation scripts | `scripts/prepare_qwen3_local_model.sh` and `scripts/prepare_qwen3_local_model.ps1` |
| Windows diagnostics | `scripts/windows_build_diagnostics.ps1` |
| Windows build wrapper | `scripts/build_windows.ps1` |
| Scale plan | `app_main/docs/MIZAN_SCALE_AND_WINDOWS_PLAN.md` |
| Scale verification report | `app_main/docs/MIZAN_SCALE_WINDOWS_VERIFICATION_REPORT.md` |
| Model handoff | `app_main/docs/MIZAN_LOCAL_AI_MODEL_ARTIFACT.md` |
| AI evaluation | `app_main/docs/MIZAN_ON_DEVICE_AI_EVALUATION.md` |

## 2. Latest pushed commits

The latest synchronized GitHub `main` commit containing the Windows llama.cpp runtime integration is:

```text
8e463e6 feat: add Windows llama.cpp local AI runtime
```

The preceding relevant commits include:

```text
08e6383 feat: add bounded tenant pagination and Windows build tooling
17b8245 feat: warn on local AI fallback
a86e6d3 docs: add Windows local model preparation
e2c7494 feat: add safe offline AI copilot orchestration
```

The repository was synchronized at the last verification with:

```text
HEAD = origin/main
Ahead/behind = 0 0
```

The pre-existing untracked audit artifacts must remain uncommitted:

```text
MIZAN_IMPLEMENTATION_PROGRESS_REPORT.md
analysis_inputs/
audit_inventory.txt
mizan-analysis-report.md
mizan-fixes.patch
mizan-localization-validation-report.md
mizan-localization-validation.patch
reusable_skill_smoke_audit.md
screen_inventory.txt
```

## 3. What has been implemented

Mizan now contains a modular accounting and CRM foundation with Supabase as the authoritative authenticated data source and Drift as the local cache/outbox/guest persistence layer. The accounting side includes ledger, journals, periods, taxes, FX provenance, trial balance, balance sheet, profit and loss, settlements, close preflight, approval enforcement, manual balance adjustments, procurement, purchase bills, warehouse transfers, inventory reservations, source drill-downs, audit controls, and governed posting paths.

The CRM side includes customers, vendors, leads, pipeline stages, opportunities, activities, CRM interaction history, CRM 360 views, quotes, quote approval, localized English/Arabic flows, and typed repository contracts. Employee invitations and role management include invitation lifecycle, validation, redemption, bulk invitation contracts, role assignment, permissions, branch scope, and maker-checker boundaries.

The AI side includes a deterministic bilingual local assistant, versioned local proposal schema, fail-closed proposal validation, allowlisted navigation, bounded bilingual workflow knowledge, a rule-first orchestrator, localized safe-fallback warnings, and a pinned Qwen3 GGUF artifact catalog. Local AI proposals cannot directly execute accounting actions. Authenticated actions remain server-authoritative and confirmation-gated.

## 4. Chosen local model

The selected model is:

```text
Base model:       Qwen/Qwen3-0.6B
Artifact:         Qwen_Qwen3-0.6B-Q4_K_M.gguf
Quantization:     Q4_K_M
Artifact size:    484,220,320 bytes
SHA-256:          9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14
Model revision:   60b85c0e3d8fe0f6474f406922a26d12aca4550d
Runtime target:   llama.cpp-compatible local runtime
Languages:        Arabic and English
Task:             Proposal extraction only
```

The original Qwen3 model is Apache 2.0. The GGUF is a community conversion and must always be used with the pinned source, revision, and SHA-256 recorded in the repository. The model binary is intentionally not committed to GitHub because of its size.

## 5. Download and prepare the model on Windows

Run these commands from the repository root:

```powershell
cd D:\mizan_monorepo
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\prepare_qwen3_local_model.ps1
```

The script downloads the model into the ignored cache and copies it to:

```text
D:\mizan_monorepo\app_main\apps\assets\local_ai\Qwen_Qwen3-0.6B-Q4_K_M.gguf
```

Verify the file manually:

```powershell
$model = ".\app_main\apps\assets\local_ai\Qwen_Qwen3-0.6B-Q4_K_M.gguf"
Test-Path $model
Get-Item $model | Select-Object FullName, Length
Get-FileHash $model -Algorithm SHA256
```

Expected values:

```text
Length: 484220320
SHA256: 9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14
```

The model must not be renamed. If the download is interrupted, rerun the preparation script. Git pull does not download the model; Git and model preparation are separate operations.

## 6. Windows environment diagnostics

From the repository root:

```powershell
cd D:\mizan_monorepo
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows_build_diagnostics.ps1 -RunFlutterDoctor -RunPubGet
```

The report is created under:

```text
D:\mizan_monorepo\windows-build-diagnostics\
```

Useful direct environment checks:

```powershell
flutter --version
flutter doctor -v
cmake --version
where.exe cmake
where.exe msbuild
where.exe cl
```

A correct Windows desktop environment requires Flutter with Windows desktop enabled, Visual Studio with **Desktop development with C++**, a Windows SDK, MSBuild, CMake, and the required native build components. Network access is required for package retrieval and, when enabled, the pinned llama.cpp source fetch.

The diagnostics report that was supplied showed the following successful checks:

```text
Flutter: passed
Visual Studio 2022 and Windows SDK: passed
Android SDK: passed
Network resources: passed
flutter pub get: passed
```

The HTTP 400 from the storage root and HTTP 404 from the Google Maven directory root were not build blockers because those URLs are directory/root probes rather than specific artifact URLs.

## 7. Windows build commands

After pulling the latest code and preparing the model:

```powershell
cd D:\mizan_monorepo
git pull --tags origin main
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\build_windows.ps1 -Configuration debug -SkipPubGet
```

The equivalent direct build command with a complete log is:

```powershell
cd D:\mizan_monorepo\app_main\apps
flutter build windows --debug -v 2>&1 | Tee-Object D:\mizan_monorepo\windows-build.log
```

For a release build:

```powershell
cd D:\mizan_monorepo
.\scripts\build_windows.ps1 -Configuration release -SkipPubGet
```

Find the executable:

```powershell
cd D:\mizan_monorepo
Get-ChildItem .\app_main\apps\build\windows -Recurse -Filter *.exe
```

Typical paths are:

```text
app_main\apps\build\windows\x64\runner\Debug\mizan.exe
app_main\apps\build\windows\x64\runner\Release\mizan.exe
```

The previous Windows log proved that Flutter successfully packaged the GGUF asset:

```text
-- Installing: ...\data\flutter_assets\assets\local_ai\Qwen_Qwen3-0.6B-Q4_K_M.gguf
Built build\windows\x64\runner\Debug\mizan.exe
exiting with code 0
```

## 8. Windows local-model runtime status

The model asset can be packaged into the Windows Flutter bundle. The safe deterministic assistant and fallback path are available independently of native inference.

The Windows llama.cpp integration is included in pushed commit `8e463e6`. It adds a pinned `llama.cpp` CMake dependency, a Windows `com.mizan/local_ai` method channel, a CPU-only Qwen3 loading path, model-path resolution from the Flutter asset bundle, SHA-256 verification, strict pinned-manifest checking, proposal-only inference, and Dart-side proposal validation. The Windows build fetches and compiles the pinned llama.cpp source during CMake configuration.

Before treating native Windows model inference as production-ready, the following must pass on the user’s Windows machine:

```text
CMake fetch of the pinned llama.cpp revision
Compilation of the llama.cpp library and Windows runner
Successful loading of the exact GGUF asset
Successful inference returning valid Mizan proposal JSON
Dart proposal validation
Repeated request context reset/cleanup
Safe fallback after missing asset, load failure, or inference failure
No network request from the local inference path
Memory, latency, and thermal measurements
```

A successful Flutter build alone proves only compilation and asset packaging. It does not by itself prove that the native model loads or produces valid proposals.

## 9. Expected fallback behavior

If the model is disabled, missing, incompatible, fails to load, produces malformed JSON, or returns an unsafe proposal, the app must preserve the deterministic response or show a clear unavailable state. The UI should display the localized message that local model inference was unavailable and that the safe fallback was used. No accounting record should be changed by this fallback.

The model may explain, navigate, extract entities, or prepare a proposal. It must never receive Supabase credentials, directly access a database handle, execute SQL, post journals, edit records, delete records, send messages, or modify source files.

## 10. Android commands

From the repository root:

```powershell
cd D:\mizan_monorepo
git pull --tags origin main
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\prepare_qwen3_local_model.ps1
cd app_main
flutter pub get
flutter gen-l10n
cd apps
flutter analyze
flutter build apk --debug
```

The current implementation’s real native llama.cpp runtime is Windows-targeted in the latest integration slice. Android remains on the deterministic local assistant until its Android native runtime is built and tested separately. Do not claim Android model inference solely from the presence of the GGUF asset.

## 11. Flutter dependency, localization, analysis, and test commands

From `app_main`:

```powershell
cd D:\mizan_monorepo\app_main
flutter pub get
flutter gen-l10n
```

Analyze the application:

```powershell
cd D:\mizan_monorepo\app_main\apps
flutter analyze
```

Analyze important packages individually:

```powershell
cd D:\mizan_monorepo\app_main\packages\core\core_data
flutter analyze
flutter test

cd ..\core_database
flutter analyze

cd ..\..\..\features\feature_ai
flutter analyze
flutter test
```

The workspace-wide convention is to analyze packages individually rather than assuming the root workspace has a test directory. Packages with no `test` directory must be recorded as skipped for that reason, not reported as failures.

## 12. Migration and static verification commands

From the repository root:

```powershell
cd D:\mizan_monorepo
python3 scripts/check_mizan_migration_registry.py
git diff --check
python3 scripts/check_mizan_module_boundaries.py
```

Expected registry output after bounded pagination:

```text
migration_files=46
registered_files=46
errors=0
```

The module-boundary diagnostic previously reported a known baseline that still requires incremental remediation:

```text
feature_dependency_violations=21
direct_supabase_import_files=9
```

These are architectural debt indicators, not evidence that the accounting RLS boundary is disabled. Ordinary feature-to-feature coupling and direct Supabase imports should continue to be moved behind public typed contracts.

The newest migration is:

```text
app_main/supabase/migrations/20260829100000_bounded_tenant_list_pages.sql
```

Its associated structural test is:

```text
app_main/supabase/tests/20260829100000_bounded_tenant_list_pages.sql
```

Never apply a migration to production merely because it exists in Git. Use a disposable or explicitly confirmed staging project, check migration history, take a backup/snapshot, run the matching SQL verification, and obtain explicit production approval.

## 13. Scale work completed

The scale slice adds typed bounded keyset pagination for customers, vendors, invoices, and bills. The cursor is `(updated_at, id)` and each page is limited to 1–100 rows. The RPCs use the authenticated current tenant, are `security invoker`, and are executable only by `authenticated`.

The client exposes:

```dart
CloudPageCursor
CloudPage<T>
CloudPageLimits
CloudCrmRepository.listCustomersPage()
CloudCrmRepository.listVendorsPage()
CloudCrmRepository.listInvoicesPage()
CloudCrmRepository.listBillsPage()
```

The existing tenant-wide realtime streams remain compatibility paths and are not safe as a million-record synchronization strategy. The next scale phase is migrating the main screens from complete tenant snapshots to bounded pages and delta synchronization.

No honest claim can be made that one million users or every operation in one or two seconds has already been proven. That requires representative data, authenticated concurrency, a provisioned staging environment, query plans, database CPU/I/O, connection-pool metrics, cache memory measurements, and p50/p95/p99 timings.

## 14. Windows debugging commands

Capture a detailed build log:

```powershell
cd D:\mizan_monorepo\app_main\apps
flutter build windows --debug -v 2>&1 | Tee-Object D:\mizan_monorepo\windows-build.log
```

Search the first actionable error:

```powershell
Select-String -Path D:\mizan_monorepo\windows-build.log `
  -Pattern "CMake Error|MSBuild|error C|Exception|FAILED|LINK" `
  -Context 3,8
```

Check whether the model was packaged:

```powershell
Get-ChildItem D:\mizan_monorepo\app_main\apps\build\windows -Recurse `
  -Filter Qwen_Qwen3-0.6B-Q4_K_M.gguf
```

Check the final executable:

```powershell
Get-ChildItem D:\mizan_monorepo\app_main\apps\build\windows `
  -Recurse -Filter mizan.exe
```

Check Git state safely:

```powershell
cd D:\mizan_monorepo
git status --short
git diff --stat
git log -3 --oneline
git rev-list --left-right --count origin/main...main
```

If `git pull` reports local changes, preserve the message and do not use `git reset --hard` unless you intentionally want to discard local work. If the only changes are the downloaded model asset, it should be ignored by Git; verify with `git status --short`.

## 15. Common failure interpretations

| Failure | Likely meaning | Correct response |
|---|---|---|
| `flutter` not recognized | Flutter is not on PATH | Add `C:\flutter\bin` to PATH or use the full Flutter path. |
| `flutter pub get` fails | Registry, cache, proxy, or dependency issue | Preserve the diagnostics report and inspect the first package/network error. |
| CMake cannot configure | CMake, generator, source fetch, or native dependency problem | Inspect the first CMake error, not only the final Flutter line. |
| MSBuild or `cl.exe` error | Visual Studio C++ workload, Windows SDK, or native source problem | Run from a Visual Studio Developer PowerShell and capture the first compiler error. |
| Build succeeds but model does not answer | Asset packaging does not guarantee runtime inference | Inspect the local-AI channel/runtime status and fallback warning. |
| Model checksum mismatch | Incomplete, altered, or wrong artifact | Delete the cache/asset and rerun the pinned preparation script. |
| Model load fails | Missing asset, insufficient memory, or native runtime problem | Keep fallback enabled, preserve logs, and do not bypass validation. |
| Android model unavailable | Android native runtime is not enabled in the current slice | Use the deterministic local assistant until Android runtime work is completed. |
| Windows model unavailable | Windows llama.cpp integration did not compile/load/infer | The UI should display the safe fallback warning; no record is changed. |
| Supabase migration error | Schema/order/signature mismatch | Stop, do not rewrite applied migrations, and create an additive forward fix after staging diagnosis. |

## 16. Production and safety boundaries

Supabase remains authoritative for authenticated tenant business data, permissions, approvals, posted accounting, and audit. Drift is a cache/outbox/guest persistence layer only. Direct workflow-table writes must remain revoked where the server RPC is authoritative.

Never place provider keys, service-role keys, or secrets in Flutter, SQL payloads, Git, build logs, or the local model. Never apply production Supabase SQL without explicit approval, a backup/snapshot, a migration-state check, and successful disposable/staging verification.

The local model cannot replace RLS, server permissions, accounting validation, approval controls, audit logging, or immutable posted-fact rules. Any local output must pass the versioned proposal parser and validator. A malformed or unsafe response must fail closed.

## 17. References

1. [Mizan repository](https://github.com/Aiman003516/Mizan_Monorepo)
2. [Qwen3-0.6B model card](https://huggingface.co/Qwen/Qwen3-0.6B)
3. [Pinned Qwen3 GGUF repository](https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF)
4. [Official llama.cpp repository](https://github.com/ggml-org/llama.cpp)
5. [Official llama.cpp build guide](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)
6. [Flutter Windows desktop documentation](https://docs.flutter.dev/platform-integration/windows/building)
