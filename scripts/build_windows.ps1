[CmdletBinding()]
param(
    [ValidateSet('debug', 'release')]
    [string]$Configuration = 'debug',
    [switch]$SkipPubGet,
    [switch]$RunDiagnostics
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$appRoot = Join-Path $repoRoot 'app_main/apps'

function Invoke-Checked {
    param(
        [string]$Name,
        [scriptblock]$Command
    )
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE."
    }
}

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
    throw 'Flutter was not found on PATH. Install Flutter or add its bin directory to PATH.'
}

if ($RunDiagnostics) {
    & (Join-Path $PSScriptRoot 'windows_build_diagnostics.ps1') -RunFlutterDoctor -RunPubGet
}

Push-Location $appRoot
try {
    Invoke-Checked -Name 'Flutter version' -Command { flutter --version }
    Invoke-Checked -Name 'Flutter doctor' -Command { flutter doctor -v }
    if (-not $SkipPubGet) {
        Invoke-Checked -Name 'Dependency resolution' -Command { flutter pub get }
    }
    $buildArgs = if ($Configuration -eq 'release') {
        @('build', 'windows', '--release')
    } else {
        @('build', 'windows', '--debug')
    }
    Invoke-Checked -Name "Windows $Configuration build" -Command { flutter @buildArgs }
} finally {
    Pop-Location
}
