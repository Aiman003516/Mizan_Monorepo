# Mizan Android Local Qwen3 + llama.cpp Build Runbook

This runbook describes the required order for building Mizan’s Android application with the local Qwen3 GGUF model and the native llama.cpp NDK libraries. It is written for the Samsung Note9 target, which uses the `arm64-v8a` ABI.

> The Android build uses the Qwen3 GGUF locally through llama.cpp/JNI. It does not use OpenRouter, OpenAI, Supabase, or another cloud model for local inference. Local AI remains proposal-only, and every native result is validated again by Dart before it reaches the application.

## 1. What is prepared once and what is rebuilt

The Qwen3 model and llama.cpp source are downloaded and verified separately from Flutter’s build outputs.

| Component | Location | Recreate after every `flutter clean`? |
|---|---|---:|
| Qwen3 GGUF cache | `D:\mizan_monorepo\.local_ai_model_cache\` | No |
| Prepared llama.cpp source | `D:\mizan_monorepo\.local_llama_cpp_cache\` | No |
| Flutter model asset | `D:\mizan_monorepo\app_main\apps\assets\local_ai\Qwen_Qwen3-0.6B-Q4_K_M.gguf` | No |
| Android CMake intermediates | `app_main\apps\android\app\.cxx\` | Yes, when a native configuration changes or a native build is stale |
| Flutter/Gradle build output | `app_main\apps\build\` | Yes, when a clean build is required |

The preparation scripts are idempotent. They verify existing files and avoid downloading them again when the checksum and expected layout are already correct.

## 2. Repository and tool prerequisites

Use PowerShell 7 or Windows PowerShell from the repository root. The Android machine must have Flutter, Android SDK/NDK, CMake, Java, and the Android platform tools installed.

The project currently expects the Flutter application at `app_main\apps`. The native Android CMake project is at `app_main\apps\android\app\src\main\cpp\CMakeLists.txt`.

Check the tools before starting:

```powershell
cd D:\mizan_monorepo

flutter --version
flutter doctor -v
adb version
java -version
```

The Android SDK must include an NDK and CMake installation compatible with the Flutter project. The app uses the Flutter-provided NDK version and CMake `3.22.1`.

## 3. Pull the latest source

Run this before building:

```powershell
cd D:\mizan_monorepo
git pull origin main
git status --short
```

Do not use `git reset --hard` to resolve local changes unless you intentionally want to destroy local work. The downloaded model and llama.cpp cache are ignored by Git and should not appear as tracked changes.

## 4. Prepare the Qwen3 model and llama.cpp source

Run these commands once on a fresh clone, or again if either prepared cache was deleted or failed checksum verification:

```powershell
cd D:\mizan_monorepo
Set-ExecutionPolicy -Scope Process Bypass

.\scripts\prepare_qwen3_local_model.ps1
.\scripts\prepare_llama_cpp_windows.ps1
```

The second script name contains `windows` because it was first introduced for the Windows native runner. Its extracted llama.cpp source is platform-neutral and is also consumed by the Android NDK CMake build.

Verify the model asset:

```powershell
$model = 'D:\mizan_monorepo\app_main\apps\assets\local_ai\Qwen_Qwen3-0.6B-Q4_K_M.gguf'
Test-Path -LiteralPath $model
Get-Item -LiteralPath $model | Select-Object FullName, Length
(Get-FileHash -Algorithm SHA256 -LiteralPath $model).Hash.ToLowerInvariant()
```

Expected model values:

```text
Length: 484220320
SHA-256: 9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14
```

Verify the prepared llama.cpp source:

```powershell
$llamaRoot = 'D:\mizan_monorepo\.local_llama_cpp_cache\llama.cpp-47c786924ad1ab7e91da2cdc72fcdb563780c2bd'
Test-Path -LiteralPath (Join-Path $llamaRoot 'CMakeLists.txt')
Get-Item -LiteralPath (Join-Path $llamaRoot 'CMakeLists.txt') | Select-Object FullName, Length
```

Expected source revision and archive checksum:

```text
Revision: 47c786924ad1ab7e91da2cdc72fcdb563780c2bd
Archive SHA-256: 9416d95607230f8a4e4379e1b86604e127c7c0eafa5e5c8c76605e43805b8c88
```

## 5. Clean the abandoned Windows build only

The abandoned Windows build output is independent of Android. Remove only its generated output if you want to reclaim space:

```powershell
Remove-Item -Recurse -Force `
  'D:\mizan_monorepo\app_main\apps\build\windows' `
  -ErrorAction SilentlyContinue
```

Do **not** remove `.local_llama_cpp_cache`; the Android build needs that prepared source.

## 6. Clean Android native intermediates

Run this after pulling the Android native-runtime changes, after changing CMake/Gradle native settings, or if a stale CMake configuration is suspected:

```powershell
cd D:\mizan_monorepo\app_main\apps

flutter clean
Remove-Item -Recurse -Force '.\android\app\.cxx' -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force '.\build' -ErrorAction SilentlyContinue
```

The clean command does not delete the Qwen3 asset or the prepared llama.cpp source because both are outside the generated build directories.

## 7. Fetch Flutter packages and generate localization files

Run these commands from the Flutter app directory:

```powershell
cd D:\mizan_monorepo\app_main\apps
flutter pub get
flutter gen-l10n
```

Run static checks before compiling native code:

```powershell
flutter analyze
```

## 8. Build the arm64 debug APK for the Samsung Note9

The Note9 target is arm64. Build the split arm64 APK so that the test package does not contain unnecessary x86 or 32-bit native libraries:

```powershell
cd D:\mizan_monorepo\app_main\apps

flutter build apk `
  --debug `
  --split-per-abi `
  --target-platform android-arm64 `
  -v 2>&1 | Tee-Object 'D:\mizan_monorepo\mizan-android-arm64-build.log'
```

The expected output is:

```text
D:\mizan_monorepo\app_main\apps\build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk
```

A successful build must end with a line similar to:

```text
BUILD SUCCESSFUL
Built build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk
exiting with code 0
```

If `--split-per-abi` does not produce the expected filename in a particular Flutter version, inspect the output directory:

```powershell
Get-ChildItem '.\build\app\outputs\flutter-apk' -Filter '*.apk' |
  Select-Object FullName, Length, LastWriteTime
```

## 9. Verify the APK contains the model and native libraries

Run these commands after the build:

```powershell
$apk = 'D:\mizan_monorepo\app_main\apps\build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk'
Test-Path -LiteralPath $apk
Get-Item -LiteralPath $apk | Select-Object FullName, Length

jar tf $apk | Select-String 'assets/flutter_assets/assets/local_ai/Qwen_Qwen3-0.6B-Q4_K_M.gguf|lib/arm64-v8a/lib(mizan_local_ai|llama|ggml)'
```

The output should include entries equivalent to:

```text
assets/flutter_assets/assets/local_ai/Qwen_Qwen3-0.6B-Q4_K_M.gguf
lib/arm64-v8a/libmizan_local_ai.so
lib/arm64-v8a/libllama.so
lib/arm64-v8a/libggml.so
lib/arm64-v8a/libggml-base.so
lib/arm64-v8a/libggml-cpu.so
```

To verify the model bytes inside the APK, extract only the model entry to a temporary file and hash it:

```powershell
$tempModel = Join-Path $env:TEMP 'mizan-qwen3-from-apk.gguf'
Remove-Item -LiteralPath $tempModel -Force -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($apk)
try {
    $entry = $zip.GetEntry('assets/flutter_assets/assets/local_ai/Qwen_Qwen3-0.6B-Q4_K_M.gguf')
    if ($null -eq $entry) { throw 'Qwen3 GGUF is missing from the APK.' }
    $input = $entry.Open()
    $output = [System.IO.File]::Create($tempModel)
    try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
} finally {
    $zip.Dispose()
}

(Get-FileHash -Algorithm SHA256 -LiteralPath $tempModel).Hash.ToLowerInvariant()
```

The expected hash is:

```text
9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14
```

## 10. Install the arm64 APK on the Note9

Enable USB debugging on the phone, connect it, and verify that Android Debug Bridge sees it:

```powershell
adb devices
flutter devices
```

The device must appear with an `device` state, not `unauthorized` or `offline`. Install the APK:

```powershell
adb install -r 'D:\mizan_monorepo\app_main\apps\build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk'
```

If Android reports an ABI or signature problem, do not install an x86 APK. Confirm that the device is arm64 and rebuild the arm64 split package.

## 11. Test that the model is local

Start log capture in a separate PowerShell window:

```powershell
adb logcat -c
adb logcat > 'D:\mizan_monorepo\mizan-android-local-ai-logcat.txt'
```

In the original window, start the installed app:

```powershell
cd D:\mizan_monorepo\app_main\apps
flutter run -d YOUR_DEVICE_ID --target-platform android-arm64
```

Replace `YOUR_DEVICE_ID` with the identifier printed by `flutter devices`. If the APK is already installed and you do not want Flutter to reinstall it, launch the package directly:

```powershell
adb shell monkey -p com.example.mizan 1
```

Use the assistant in this order:

1. Submit a deterministic navigation or workflow-explanation request. This confirms the rule-first path remains available and does not require model loading.
2. Submit a safe request that is not covered by the deterministic rules. This causes the Android model tier to be attempted.
3. Confirm that the response is either a strictly validated proposal or the visible localized safe-fallback warning.
4. Confirm that no accounting or CRM record changes without the existing human confirmation/server-authoritative workflow.

The native runtime never receives Supabase credentials, database handles, SQL, arbitrary tools, or cloud-provider access. A malformed Qwen3 response is rejected by Dart and results in safe fallback; that is expected and is not an accounting failure.

Stop log capture with `Ctrl+C` after testing:

```text
D:\mizan_monorepo\mizan-android-local-ai-logcat.txt
```

Do not include passwords, access tokens, personal financial data, or private customer information when sharing logs.

## 12. Troubleshooting

### Missing prepared llama.cpp source

If CMake reports that the prepared source directory or `CMakeLists.txt` is missing, run:

```powershell
cd D:\mizan_monorepo
.\scripts\prepare_llama_cpp_windows.ps1
cd app_main\apps
Remove-Item -Recurse -Force '.\android\app\.cxx' -ErrorAction SilentlyContinue
flutter build apk --debug --split-per-abi --target-platform android-arm64 -v
```

### `vld1q_f16` or `vld1_f16` errors

These indicate that an old CMake configuration selected llama.cpp’s llamafile ARM implementation. Pull the latest source, confirm that Android CMake contains `GGML_LLAMAFILE=OFF`, delete `android\app\.cxx`, and rebuild.

### Gradle daemon disappeared

This usually indicates host memory pressure rather than an accounting or Dart error. Confirm that `app_main\apps\android\gradle.properties` contains the project’s bounded settings:

```text
org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=768m -XX:ReservedCodeCacheSize=256m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
org.gradle.daemon=false
org.gradle.parallel=false
```

Retry with one native build job if necessary:

```powershell
$env:CMAKE_BUILD_PARALLEL_LEVEL = '1'
$env:GRADLE_OPTS = '-Dorg.gradle.workers.max=1 -Dorg.gradle.parallel=false'
flutter build apk --debug --split-per-abi --target-platform android-arm64 -v
```

### APK builds but the model is unavailable

Check the model hash before reinstalling, verify that the APK contains the GGUF and `libmizan_local_ai.so`, confirm that the device is arm64, and inspect the safe-fallback warning and logcat output. Do not bypass Dart proposal validation and do not replace the pinned model with an unverified file.

### APK is very large

The Qwen3 GGUF is approximately 484 MB. Use `--split-per-abi --target-platform android-arm64` for the Note9 test package. Do not commit the model binary to GitHub. The production release should separately evaluate download size, installation storage, memory pressure, cold-load latency, and thermal behavior.

## 13. What this runbook proves

A successful build and APK inspection prove that the Android native llama.cpp library and the exact Qwen3 GGUF are packaged together. They do not by themselves prove successful inference on the Note9.

Physical-device verification must still establish model load success, local inference execution, valid proposal output, malformed-output rejection, safe fallback, memory use, latency, thermal behavior, crash recovery, and absence of AI-data network egress. The server-authoritative accounting and CRM boundaries remain unchanged regardless of model availability.
