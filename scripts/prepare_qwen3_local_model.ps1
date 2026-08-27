[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$modelName = 'Qwen_Qwen3-0.6B-Q4_K_M.gguf'
$modelUrl = 'https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF/resolve/60b85c0e3d8fe0f6474f406922a26d12aca4550d/Qwen_Qwen3-0.6B-Q4_K_M.gguf'
$expectedSha256 = '9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14'
$cacheDir = Join-Path $repoRoot '.local_ai_model_cache'
$assetDir = Join-Path $repoRoot 'app_main/apps/assets/local_ai'
$modelPath = Join-Path $cacheDir $modelName
$partialPath = "$modelPath.partial"

New-Item -ItemType Directory -Force -Path $cacheDir, $assetDir | Out-Null
if (-not (Test-Path -LiteralPath $modelPath)) {
    Write-Host "Downloading $modelName from the pinned revision..."
    Invoke-WebRequest -Uri $modelUrl -OutFile $partialPath
    Move-Item -Force $partialPath $modelPath
}

$actualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $modelPath).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    Write-Error "Checksum verification failed. Expected $expectedSha256 but found $actualSha256."
    exit 1
}

Copy-Item -Force -LiteralPath $modelPath -Destination (Join-Path $assetDir $modelName)
Write-Host "Verified $modelName"
Write-Host "SHA-256: $actualSha256"
Write-Host "Copied to: $(Join-Path $assetDir $modelName)"
