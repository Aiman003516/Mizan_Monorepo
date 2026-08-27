[CmdletBinding()]
param(
    [switch]$RunFlutterDoctor,
    [switch]$RunPubGet,
    [switch]$RunBuild
)

$ErrorActionPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptRoot
$appRoot = Join-Path $repoRoot 'app_main/apps'
$reportRoot = Join-Path $repoRoot 'windows-build-diagnostics'
New-Item -ItemType Directory -Force -Path $reportRoot | Out-Null
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportPath = Join-Path $reportRoot "windows-build-$timestamp.txt"

function Write-Report {
    param([string]$Message)
    $Message | Tee-Object -FilePath $reportPath -Append
}

function Test-Endpoint {
    param([string]$Name, [string]$Uri)
    Write-Report "`n[$Name] $Uri"
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method Head -UseBasicParsing -TimeoutSec 20
        Write-Report "HTTP $([int]$response.StatusCode) $($response.StatusDescription)"
        Write-Report 'PASS: HTTPS request completed.'
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status) {
            Write-Report "HTTP $status"
        }
        Write-Report "FAIL: $($_.Exception.Message)"
    }
}

"Mizan Windows build diagnostics" | Set-Content -Path $reportPath
Write-Report "Timestamp: $(Get-Date -Format o)"
Write-Report "Repository: $repoRoot"
Write-Report "Application: $appRoot"

Write-Report "`n=== Host and proxy information ==="
Write-Report "Computer: $env:COMPUTERNAME"
Write-Report "User: $env:USERNAME"
Write-Report "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Report "PUB_CACHE: $env:PUB_CACHE"
Write-Report "PUB_HOSTED_URL: $env:PUB_HOSTED_URL"
Write-Report "FLUTTER_STORAGE_BASE_URL: $env:FLUTTER_STORAGE_BASE_URL"
Write-Report "HTTP_PROXY: $env:HTTP_PROXY"
Write-Report "HTTPS_PROXY: $env:HTTPS_PROXY"
Write-Report "NO_PROXY: $env:NO_PROXY"

Write-Report "`n=== DNS and HTTPS endpoint checks ==="
$endpoints = @(
    @{ Name = 'Dart package registry'; Uri = 'https://pub.dev' },
    @{ Name = 'Flutter release metadata'; Uri = 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json' },
    @{ Name = 'Flutter storage'; Uri = 'https://storage.googleapis.com' },
    @{ Name = 'Gradle distribution service'; Uri = 'https://services.gradle.org' },
    @{ Name = 'Google Maven'; Uri = 'https://dl.google.com/dl/android/maven2/' },
    @{ Name = 'Maven Central'; Uri = 'https://repo.maven.apache.org/maven2/' },
    @{ Name = 'GitHub'; Uri = 'https://github.com' },
    @{ Name = 'NuGet'; Uri = 'https://api.nuget.org/v3/index.json' }
)
foreach ($endpoint in $endpoints) {
    try {
        $hostName = ([System.Uri]$endpoint.Uri).Host
        $addresses = [System.Net.Dns]::GetHostAddresses($hostName) | ForEach-Object { $_.IPAddressToString }
        Write-Report "DNS $hostName -> $($addresses -join ', ')"
    } catch {
        Write-Report "DNS FAIL $($endpoint.Uri): $($_.Exception.Message)"
    }
    Test-Endpoint -Name $endpoint.Name -Uri $endpoint.Uri
}

Write-Report "`n=== Flutter tool information ==="
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
    Write-Report 'FAIL: flutter was not found on PATH.'
} else {
    Write-Report "Flutter executable: $($flutter.Source)"
    Push-Location $appRoot
    try {
        & flutter --version 2>&1 | Tee-Object -FilePath $reportPath -Append
        & flutter config 2>&1 | Tee-Object -FilePath $reportPath -Append
    } finally {
        Pop-Location
    }
}

if ($RunFlutterDoctor) {
    Write-Report "`n=== flutter doctor -v ==="
    Push-Location $appRoot
    try { & flutter doctor -v 2>&1 | Tee-Object -FilePath $reportPath -Append }
    finally { Pop-Location }
}

if ($RunPubGet) {
    Write-Report "`n=== flutter pub get -v ==="
    Push-Location $appRoot
    try { & flutter pub get -v 2>&1 | Tee-Object -FilePath $reportPath -Append }
    finally { Pop-Location }
}

if ($RunBuild) {
    Write-Report "`n=== flutter build windows -v ==="
    Push-Location $appRoot
    try { & flutter build windows -v 2>&1 | Tee-Object -FilePath $reportPath -Append }
    finally { Pop-Location }
}

Write-Report "`nReport saved to: $reportPath"
Write-Report 'Interpretation: HTTP/DNS/TLS failures identify a network path problem; package resolution failures identify pub-cache or pub.dev access; CMake/MSBuild failures identify local Windows toolchain issues.'
