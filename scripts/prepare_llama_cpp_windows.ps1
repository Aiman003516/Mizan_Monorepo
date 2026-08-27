[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$revision = '47c786924ad1ab7e91da2cdc72fcdb563780c2bd'
$archiveName = "llama.cpp-$revision.zip"
$archiveUrl = "https://github.com/ggml-org/llama.cpp/archive/$revision.zip"
$expectedSha256 = '9416d95607230f8a4e4379e1b86604e127c7c0eafa5e5c8c76605e43805b8c88'
$cacheDir = Join-Path $repoRoot '.local_llama_cpp_cache'
$archivePath = Join-Path $cacheDir $archiveName
$partialPath = "$archivePath.partial"
$sourcePath = Join-Path $cacheDir "llama.cpp-$revision"
$markerPath = Join-Path $sourcePath '.mizan_llama_revision'
$temporaryExtractPath = Join-Path $cacheDir "extract-$revision-$([Guid]::NewGuid().ToString('N'))"

New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null

if ($Force -and (Test-Path -LiteralPath $sourcePath)) {
    Remove-Item -LiteralPath $sourcePath -Recurse -Force
}

if (-not (Test-Path -LiteralPath $archivePath)) {
    Write-Host "Downloading pinned llama.cpp archive ($archiveName)..."
    if (Test-Path -LiteralPath $partialPath) {
        Remove-Item -LiteralPath $partialPath -Force
    }
    Invoke-WebRequest -Uri $archiveUrl -OutFile $partialPath
    Move-Item -LiteralPath $partialPath -Destination $archivePath -Force
}

$actualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash.ToLowerInvariant()
if ($actualSha256 -ne $expectedSha256) {
    Write-Error "Checksum verification failed. Expected $expectedSha256 but found $actualSha256."
    exit 1
}

$sourceReady = (Test-Path -LiteralPath (Join-Path $sourcePath 'CMakeLists.txt')) -and
    (Test-Path -LiteralPath $markerPath) -and
    ((Get-Content -Raw -LiteralPath $markerPath).Trim() -eq $revision)

if (-not $sourceReady) {
    if (Test-Path -LiteralPath $sourcePath) {
        Remove-Item -LiteralPath $sourcePath -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $temporaryExtractPath | Out-Null
    try {
        Write-Host "Extracting llama.cpp revision $revision..."
        Expand-Archive -LiteralPath $archivePath -DestinationPath $temporaryExtractPath -Force
        $extractedSourcePath = Join-Path $temporaryExtractPath "llama.cpp-$revision"
        if (-not (Test-Path -LiteralPath (Join-Path $extractedSourcePath 'CMakeLists.txt'))) {
            throw "The archive did not contain the expected llama.cpp source tree."
        }
        Move-Item -LiteralPath $extractedSourcePath -Destination $sourcePath
        Set-Content -LiteralPath $markerPath -Value $revision -NoNewline
    }
    finally {
        if (Test-Path -LiteralPath $temporaryExtractPath) {
            Remove-Item -LiteralPath $temporaryExtractPath -Recurse -Force
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'CMakeLists.txt'))) {
    throw "llama.cpp preparation did not produce a valid source directory: $sourcePath"
}

Write-Host "Verified llama.cpp archive"
Write-Host "Revision: $revision"
Write-Host "SHA-256: $actualSha256"
Write-Host "Archive: $archivePath"
Write-Host "Source: $sourcePath"
