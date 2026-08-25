# BootstrapGeurtsInstructions.ps1
# Version: 0.6.0

param(
    [string]$ConfigPath = "Tools/GeurtsRepository.json"
)

$ErrorActionPreference = "Stop"

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "SYNC FAILED: $Message" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ConfigPath)) {
    Fail "Repository configuration not found: $ConfigPath"
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

if (-not $config.repositoryUrl) { Fail "repositoryUrl is missing." }
if (-not $config.branch) { Fail "branch is missing." }
if (-not $config.localSyncPath) { Fail "localSyncPath is missing." }
if (-not $config.entryPointPath) { Fail "entryPointPath is missing." }
if (-not $config.manifestPath) { Fail "manifestPath is missing." }
if (-not $config.techniquesPath) { Fail "techniquesPath is missing." }
if (-not $config.sparsePaths -or $config.sparsePaths.Count -eq 0) { Fail "sparsePaths is missing or empty." }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fail "Git is not installed or is not available on PATH."
}

$syncPath = $config.localSyncPath
$parent = Split-Path -Parent $syncPath
if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

if (-not (Test-Path (Join-Path $syncPath ".git"))) {
    if (Test-Path $syncPath) {
        Remove-Item -Recurse -Force $syncPath
    }

    Write-Host "Cloning canonical Geurts documentation..."
    & git clone --depth 1 --filter=blob:none --no-checkout --branch $config.branch $config.repositoryUrl $syncPath
    if ($LASTEXITCODE -ne 0) { Fail "git clone failed. Confirm GitHub authentication for the repository." }
}
else {
    Write-Host "Refreshing canonical Geurts documentation..."

    & git -C $syncPath remote set-url origin $config.repositoryUrl
    if ($LASTEXITCODE -ne 0) { Fail "Could not update origin URL." }

    & git -C $syncPath fetch --depth 1 origin $config.branch
    if ($LASTEXITCODE -ne 0) { Fail "git fetch failed. Confirm GitHub authentication and network access." }
}

& git -C $syncPath sparse-checkout init --no-cone
if ($LASTEXITCODE -ne 0) { Fail "Could not initialize sparse checkout." }

$sparseInput = (@($config.sparsePaths) -join [Environment]::NewLine)
$sparseInput | & git -C $syncPath sparse-checkout set --no-cone --stdin
if ($LASTEXITCODE -ne 0) { Fail "Could not apply the required documentation layout." }

& git -C $syncPath checkout -B $config.branch "origin/$($config.branch)"
if ($LASTEXITCODE -ne 0) { Fail "Could not check out origin/$($config.branch)." }

& git -C $syncPath reset --hard "origin/$($config.branch)"
if ($LASTEXITCODE -ne 0) { Fail "Could not reset the synchronized copy." }

& git -C $syncPath clean -fd
if ($LASTEXITCODE -ne 0) { Fail "Could not clean the synchronized copy." }

$entryPoint = Join-Path $syncPath $config.entryPointPath
$manifest = Join-Path $syncPath $config.manifestPath
$techniques = Join-Path $syncPath $config.techniquesPath

if (-not (Test-Path $entryPoint)) { Fail "AI entry point not found after sync: $entryPoint" }
if (-not (Test-Path $manifest)) { Fail "Technique manifest not found after sync: $manifest" }
if (-not (Test-Path $techniques -PathType Container)) { Fail "Technique directory not found after sync: $techniques" }

$commit = (& git -C $syncPath rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { Fail "Unable to read synchronized commit SHA." }

Write-Host ""
Write-Host "SYNC OK" -ForegroundColor Green
Write-Host "Repository:  $($config.repositoryUrl)"
Write-Host "Branch:      $($config.branch)"
Write-Host "Commit:      $commit"
Write-Host "Local docs:  $syncPath"
Write-Host "AI entry:    $entryPoint"
Write-Host "Manifest:    $manifest"
Write-Host "Techniques:  $techniques"
Write-Host ""
Write-Host "The AI agent must now read the root AGENTS.md and then $entryPoint before modifying project files."
