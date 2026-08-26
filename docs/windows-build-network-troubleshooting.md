# Mizan Windows Build: Network and ISP Troubleshooting

## Diagnosis

A Windows desktop build does not use the Android Gradle wrapper for its main compilation. It uses the Flutter Windows toolchain, Dart package resolution, Flutter Windows engine artifacts, CMake, Visual Studio/MSBuild, and native plugin dependencies. The repository confirms that Dart packages are hosted from `https://pub.dev`; Flutter desktop artifacts are obtained from Google Cloud Storage when they are missing; the Android project separately uses `https://services.gradle.org`, Google Maven, and Maven Central.

The fact that the same project works on a rented cloud desktop is strong evidence that the local machine’s network path, DNS, TLS inspection, firewall, proxy, or local tool caches differ from the cloud desktop. It does not prove that the ISP is the only possible cause. A failed build log must identify the exact host and phase before changing source code.

## Most likely failure classes

| Build phase | Typical dependency or host | What failure usually means |
|---|---|---|
| `flutter pub get` | `pub.dev` or a configured Dart package mirror | DNS, TLS, proxy, ISP filtering, corrupt cache, or package-host timeout |
| Flutter Windows artifact preparation | `storage.googleapis.com` | Missing Flutter Windows engine cache or blocked Google Cloud Storage path |
| Windows native compilation | Visual Studio C++ workload, Windows SDK, CMake, Ninja | Local toolchain missing or misconfigured; not normally an ISP problem |
| Native package restore | NuGet or plugin-specific source | NuGet access blocked, certificate interception, or missing local cache |
| Android build | `services.gradle.org`, Google Maven, Maven Central | Android-only network/toolchain issue; unrelated to `flutter build windows` |
| Application runtime | Supabase, Google Drive, payment/AI endpoints | Runtime connectivity/configuration issue; does not explain a compile-time package failure |

## First action on the Windows PC

From the repository root, run the included diagnostic script in PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\windows_build_diagnostics.ps1 -RunFlutterDoctor -RunPubGet
```

If `flutter pub get` succeeds but the build still fails, run the verbose build capture:

```powershell
.\scripts\windows_build_diagnostics.ps1 -RunBuild
```

Send the resulting report or the first error block containing the failing URL and command. Do not send `.env`, tokens, signing keys, or the full private environment.

## Endpoint checks

The local network or corporate/ISP firewall should permit outbound HTTPS connections to the following hosts when the corresponding cache is missing:

| Purpose | Host |
|---|---|
| Dart packages | `pub.dev`, `storage.googleapis.com` |
| Flutter Windows engine | `storage.googleapis.com` |
| Android Gradle wrapper | `services.gradle.org` |
| Android dependencies | `dl.google.com`, `repo.maven.apache.org` |
| Source repository | `github.com` |
| Native package restore, if required | `api.nuget.org` |

Do not disable TLS validation globally. If antivirus, endpoint security, or a proxy performs HTTPS inspection, whitelist the specific executables and hosts under the organization’s approved policy instead.

## Recommended Windows prerequisites

Install and verify the following on the local Windows machine:

| Requirement | Purpose |
|---|---|
| The same Flutter stable version used by the project | Prevents repeated engine/tool downloads and version drift |
| Visual Studio with Desktop development with C++ | Compiles the Windows runner and native plugins |
| Windows 10/11 SDK | Provides Windows headers and libraries |
| CMake and Ninja | Used by Flutter’s Windows desktop build |
| Git | Repository and package source access |
| PowerShell | Runs the diagnostic and cache scripts |

The required Visual Studio workload is **Desktop development with C++**, including the MSVC toolset, Windows SDK, CMake tools, and Ninja support.

## Cache-first recovery procedure

Use a machine/network where the downloads succeed—your rented cloud desktop is suitable—then copy the caches to the Windows PC using an approved transfer method.

First, on the working machine, use the exact same Flutter version and warm the caches:

```powershell
flutter --version
flutter precache --windows
cd app_main
flutter pub get
flutter build windows --debug
```

On Windows, the important locations are usually:

```text
%FLUTTER_ROOT%\bin\cache
%LOCALAPPDATA%\Pub\Cache
%USERPROFILE%\.gradle\caches       # Android builds only
```

If `PUB_CACHE` is defined, use that path instead of `%LOCALAPPDATA%\Pub\Cache`. Do not copy `.env`, signing files, or credentials into the project or cache archive.

After copying the caches, use:

```powershell
cd app_main
flutter pub get --offline
flutter build windows --debug
```

`flutter pub get --offline` can resolve only packages already present in the local Pub cache. If it reports a missing package, warm that package on the working network first; do not remove the lockfile or randomly upgrade dependencies.

## Reliable build sequence

Use this sequence on the local Windows PC:

```powershell
cd D:\mizan_monorepo\app_main
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build windows --debug -v
```

If `flutter clean` is used while the network is blocked, the next build may need to regenerate Flutter artifacts. Therefore, do not clean repeatedly. Prefer `flutter build windows --debug -v` first and preserve the existing cache.

For a release build after Debug succeeds:

```powershell
flutter build windows --release -v
```

Release builds may additionally fail because of signing, Visual Studio configuration, antivirus locking output files, or native linker memory usage. Those failures are distinct from package-host connectivity errors.

## ISP, DNS, proxy, and firewall isolation

Test the same endpoint from the local PC and the cloud desktop. If DNS resolves but HTTPS fails locally, investigate firewall, TLS interception, proxy, or ISP filtering. If DNS itself fails, test the organization-approved DNS configuration. Changing DNS may help a resolver problem, but it will not reliably fix an upstream block.

Check whether PowerShell has a proxy configured:

```powershell
Get-ChildItem Env:*proxy*
netsh winhttp show proxy
```

If the organization requires a proxy, configure it according to the organization’s policy rather than relying on random environment variables. If no proxy is required, stale proxy variables can cause misleading “internet connection lost” errors and should be removed from the user/system environment after confirmation.

Check Windows Firewall and endpoint security logs for blocks involving:

```text
flutter.bat
flutter_tools.snapshot
dart.exe
git.exe
cmake.exe
ninja.exe
MSBuild.exe
```

Do not disable security software globally. Create narrowly scoped, approved exceptions only when the security administrator confirms the process and host.

## Repository-side changes included

The repository now includes:

```text
scripts/windows_build_diagnostics.ps1
docs/windows-build-network-troubleshooting.md
```

The script is non-destructive. It tests DNS and HTTPS access, prints relevant proxy/cache variables, captures Flutter doctor output, and can optionally capture verbose Pub or Windows build logs. It does not modify firewall settings, environment variables, dependencies, or application data.

## Important conclusion

The cloud desktop result makes a local network/toolchain difference highly probable. The fastest reliable solution is to identify the exact blocked endpoint, warm the Flutter and Pub caches on the working network, transfer only safe caches, and then build offline or cache-first on the local PC. If the diagnostic shows that all endpoints work but compilation fails, the fix is likely Visual Studio/CMake/Windows SDK configuration rather than the ISP.
