# RunAutomationTests.ps1
# Version: 0.11.5

[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$script:Passed = 0
$script:Failed = 0
$script:FailureMessages = New-Object System.Collections.Generic.List[string]
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Assert-True([bool]$Condition, [string]$Name) {
    if ($Condition) {
        $script:Passed++
        if ($OutputFormat -eq "Text") { Write-Host "PASS: $Name" -ForegroundColor Green }
    }
    else {
        $script:Failed++
        $script:FailureMessages.Add($Name) | Out-Null
        if ($OutputFormat -eq "Text") { Write-Host "FAIL: $Name" -ForegroundColor Red }
    }
}

function Write-Utf8([string]$Path, [string]$Text) {
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Get-FileSha([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-BytePrefix([byte[]]$Bytes, [byte[]]$Expected) {
    if ($Bytes.Length -lt $Expected.Length) { return $false }
    for ($index = 0; $index -lt $Expected.Length; $index++) {
        if ($Bytes[$index] -ne $Expected[$index]) { return $false }
    }
    return $true
}

function Test-ByteSuffix([byte[]]$Bytes, [byte[]]$Expected) {
    if ($Bytes.Length -lt $Expected.Length) { return $false }
    $offset = $Bytes.Length - $Expected.Length
    for ($index = 0; $index -lt $Expected.Length; $index++) {
        if ($Bytes[$offset + $index] -ne $Expected[$index]) { return $false }
    }
    return $true
}

function Test-CrLfOnly([string]$Text) {
    if (-not $Text.Contains("`r`n")) { return $false }
    $withoutCrLf = $Text.Replace("`r`n", "")
    return -not $withoutCrLf.Contains("`r") -and -not $withoutCrLf.Contains("`n")
}

function Get-GitIgnorePayloadInfo([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return [pscustomobject]@{ Valid = $false } }
    $text = [System.IO.File]::ReadAllText($Path)
    $pattern = '(?ms)^<!-- GEURTS-GITIGNORE-BEGIN version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)" target="(?<Target>[^"]+)" sha256="(?<Hash>[0-9a-f]{64})" -->\r?\n```gitignore\r?\n(?<Payload>.*?)^```\r?\n<!-- GEURTS-GITIGNORE-END -->(?:\r?\n)?\z'
    $matches = @([regex]::Matches($text, $pattern))
    if ($matches.Count -ne 1 -or [regex]::Matches($text, 'GEURTS-GITIGNORE-BEGIN').Count -ne 1 -or [regex]::Matches($text, 'GEURTS-GITIGNORE-END').Count -ne 1) { return [pscustomobject]@{ Valid = $false } }
    $match = $matches[0]
    $payload = $match.Groups["Payload"].Value -replace "`r`n", "`n" -replace "`r", "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $actualHash = ([System.BitConverter]::ToString($sha.ComputeHash($utf8NoBom.GetBytes($payload)))).Replace("-", "").ToLowerInvariant() }
    finally { $sha.Dispose() }
    return [pscustomobject]@{
        Valid = ($match.Groups["Version"].Value -ceq "1.0.0" -and $match.Groups["Target"].Value -ceq ".gitignore" -and $match.Groups["Hash"].Value -ceq $actualHash -and $actualHash -ceq "7223a9449718942d3a5cad00cf4d4e0dee9c89eb64951541fa4ebfb803acb45b" -and [regex]::Matches($payload, "`n").Count -eq 376 -and $payload.EndsWith("`n") -and -not $payload.EndsWith("`n`n"))
        Hash = $actualHash
        LineCount = [regex]::Matches($payload, "`n").Count
        EndsWithOneLf = ($payload.EndsWith("`n") -and -not $payload.EndsWith("`n`n"))
    }
}

function Invoke-TestScript([string]$Path, [string[]]$Arguments) {
    $hostPath = (Get-Process -Id $PID).Path
    $hostArguments = @("-NoProfile")
    if ((Split-Path -Leaf $hostPath) -like "powershell*") { $hostArguments += @("-ExecutionPolicy", "Bypass") }
    $hostArguments += @("-File", $Path)
    $hostArguments += $Arguments
    $output = @(& $hostPath @hostArguments 2>&1)
    return [pscustomobject]@{ Code = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
}

function Start-TestScriptAtBarrier([string]$Path, [string[]]$Arguments, [string]$BarrierPath, [string]$TargetPath) {
    foreach ($suffix in @(".ready", ".continue", ".stdout", ".stderr")) { Remove-Item -LiteralPath ($BarrierPath + $suffix) -Force -ErrorAction SilentlyContinue }
    $hostPath = (Get-Process -Id $PID).Path
    $hostArguments = @("-NoProfile")
    if ((Split-Path -Leaf $hostPath) -like "powershell*") { $hostArguments += @("-ExecutionPolicy", "Bypass") }
    $hostArguments += @("-File", $Path)
    $hostArguments += $Arguments
    $quotedArguments = @($hostArguments | ForEach-Object { '"' + ([string]$_).Replace('"', '\"') + '"' })
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $hostPath
    $startInfo.Arguments = $quotedArguments -join " "
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.EnvironmentVariables["GEURTS_TEST_WRITE_BARRIER_PATH"] = [System.IO.Path]::GetFullPath($BarrierPath)
    $startInfo.EnvironmentVariables["GEURTS_TEST_WRITE_BARRIER_TARGET"] = [System.IO.Path]::GetFullPath($TargetPath)
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "Unable to start barrier test process." }
    return [pscustomobject]@{ Process = $process; Barrier = [System.IO.Path]::GetFullPath($BarrierPath); Target = [System.IO.Path]::GetFullPath($TargetPath); Disposed = $false }
}

function Close-TestScriptBarrierProcess($Run) {
    if ($null -eq $Run -or $Run.Disposed) { return }
    try {
        if ($null -ne $Run.Process) { $Run.Process.Dispose() }
    }
    finally { $Run.Disposed = $true }
}

function Stop-TestScriptBarrier($Run) {
    if ($null -eq $Run -or $Run.Disposed -or $null -eq $Run.Process) { return }
    try {
        if (-not $Run.Process.HasExited) {
            [System.IO.File]::WriteAllText(($Run.Barrier + ".continue"), "continue", $utf8NoBom)
            $Run.Process.WaitForExit()
        }
    }
    catch {
        # Cleanup is best-effort and must not replace the primary test failure.
    }
    finally {
        try { Close-TestScriptBarrierProcess -Run $Run }
        catch { }
    }
}

function Restore-TestDirectorySwap([string]$Path, [string]$ExpectedTarget, [string]$SavedPath) {
    try {
        if (Test-Path -LiteralPath $Path) {
            $item = Get-Item -LiteralPath $Path -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                Remove-TestJunction -Path $Path -ExpectedTarget $ExpectedTarget
            }
            elseif (Test-Path -LiteralPath $SavedPath -PathType Container) {
                throw "Refused to restore a directory swap over a non-junction path: $Path"
            }
        }
        if (Test-Path -LiteralPath $SavedPath -PathType Container) {
            if (Test-Path -LiteralPath $Path) { throw "Refused to restore a saved directory over an existing path: $Path" }
            Move-Item -LiteralPath $SavedPath -Destination $Path
        }
    }
    catch {
        $script:Failed++
        $script:FailureMessages.Add("Barrier directory cleanup failed for '$Path': $($_.Exception.Message)") | Out-Null
        if ($OutputFormat -eq "Text") { Write-Host "BARRIER CLEANUP ERROR: $($_.Exception.Message)" -ForegroundColor Red }
    }
}

function Wait-TestScriptBarrier($Run) {
    $readyPath = $Run.Barrier + ".ready"
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    while (-not (Test-Path -LiteralPath $readyPath -PathType Leaf)) {
        if ($Run.Process.HasExited) {
            $output = $Run.Process.StandardOutput.ReadToEnd() + $Run.Process.StandardError.ReadToEnd()
            $code = $Run.Process.ExitCode
            Close-TestScriptBarrierProcess -Run $Run
            throw "Barrier test process exited before its write boundary (code $code): $output"
        }
        if ([DateTime]::UtcNow -ge $deadline) { throw "Timed out waiting for the deterministic write barrier." }
        Start-Sleep -Milliseconds 20
    }
}

function Complete-TestScriptBarrier($Run) {
    if ($null -eq $Run -or $Run.Disposed -or $null -eq $Run.Process) { throw "Barrier test process is no longer available for completion." }
    try {
        [System.IO.File]::WriteAllText(($Run.Barrier + ".continue"), "continue", $utf8NoBom)
        $stdout = $Run.Process.StandardOutput.ReadToEnd()
        $stderr = $Run.Process.StandardError.ReadToEnd()
        $Run.Process.WaitForExit()
        $code = $Run.Process.ExitCode
        return [pscustomobject]@{ Code = $code; Output = (($stdout + $stderr).TrimEnd()) }
    }
    finally { Close-TestScriptBarrierProcess -Run $Run }
}

function Get-HistoricalFile([string]$Specification) {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "git"
    $startInfo.Arguments = "show $Specification"
    $startInfo.WorkingDirectory = $RepositoryRoot
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Unable to load historical fixture $Specification. $stderr" }
    return $stdout
}

function New-TestProject([string]$Parent, [string]$Name) {
    $path = Join-Path $Parent $Name
    New-Item -ItemType Directory -Path $path | Out-Null
    foreach ($marker in @("Assets", "Packages", "ProjectSettings")) { New-Item -ItemType Directory -Path (Join-Path $path $marker) | Out-Null }
    return $path
}

function New-StaticValidationFixture([string]$Parent, [string]$Name) {
    $path = Join-Path $Parent $Name
    New-Item -ItemType Directory -Path $path | Out-Null
    foreach ($entryName in @("AGENTS.md", "AI_READ_FIRST.md", "GeurtsTechniqueManifest.md", "GeurtsTechniques", "Ideas", "Migrations", "README.md", "Tools")) {
        Copy-Item -LiteralPath (Join-Path $RepositoryRoot $entryName) -Destination $path -Recurse -Force
    }
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $initOutput = @(& git -C $path init --quiet 2>&1)
        $initExitCode = $LASTEXITCODE
        $addOutput = @(& git -C $path add --all 2>&1)
        $addExitCode = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previousPreference }
    if ($initExitCode -ne 0) { throw "Unable to initialize a static-validation fixture repository: $path. $($initOutput -join ' ')" }
    if ($addExitCode -ne 0) { throw "Unable to stage the static-validation fixture inventory: $path. $($addOutput -join ' ')" }
    return $path
}

function Remove-TestJunction([string]$Path, [string]$ExpectedTarget) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
        throw "Refused to remove a non-junction test path: $Path"
    }
    $declaredTargets = @($item.Target)
    if ($declaredTargets.Count -ne 1 -or [string]::IsNullOrWhiteSpace([string]$declaredTargets[0])) {
        throw "Refused to remove a test junction without one inspectable target: $Path"
    }
    $declaredTarget = [string]$declaredTargets[0]
    if (-not [System.IO.Path]::IsPathRooted($declaredTarget)) { $declaredTarget = Join-Path (Split-Path -Parent $Path) $declaredTarget }
    if (-not [System.IO.Path]::GetFullPath($declaredTarget).Equals([System.IO.Path]::GetFullPath($ExpectedTarget), [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refused to remove a test junction whose target differs from the expected disposable target: $Path"
    }
    [System.IO.Directory]::Delete([System.IO.Path]::GetFullPath($Path))
    if (Test-Path -LiteralPath $Path) { throw "Failed to remove disposable test junction: $Path" }
}

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
$toolsRoot = Join-Path $RepositoryRoot "Tools"
$manageScript = Join-Path $toolsRoot "ManageGeurtsAgentInstructions.ps1"
$gddScript = Join-Path $toolsRoot "UpdateGameDesignManifest.ps1"
$folderScript = Join-Path $toolsRoot "CreateGeurtsFolderStructure.ps1"
$validatorScript = Join-Path $toolsRoot "ValidateGeurtsDocumentation.ps1"
$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$testRoot = Join-Path $temporaryBase ("ggf-automation-tests-" + [Guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null

    $repositoryGitIgnorePath = Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGitIgnoreTechnique.md"
    $repositoryGitIgnore = Get-GitIgnorePayloadInfo -Path $repositoryGitIgnorePath
    Assert-True ($repositoryGitIgnore.Valid -and $repositoryGitIgnore.LineCount -eq 376 -and $repositoryGitIgnore.EndsWithOneLf) "Approved custom .gitignore payload matches the normalized source"

    $draftManifestText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniqueManifest.md"))
    $draftReadmeText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "README.md"))
    $targetMigrationText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Migrations/v0.11.0.md"))
    Assert-True ($draftManifestText -match '(?im)^\*\*Version:\*\*\s*0\.11\.4\s*$' -and $draftManifestText -match '(?im)^\*\*Status:\*\*\s*Draft normative package manifest\s*$' -and $draftReadmeText -match '(?im)^\*\*Status:\*\*\s*Draft technique package\s*$' -and $targetMigrationText -match '(?i)planned transition' -and $targetMigrationText -match '(?i)target-release snapshot' -and $targetMigrationText -notmatch '(?i)(?:v0\.11\.4|package v0\.11\.4)[^\r\n]{0,80}(?:is|was|has been) released') "v0.11.4 remains a Draft target release with a planned snapshot rather than a completed-release claim"

    $gfiContractText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"))
    Assert-True ($gfiContractText -match '(?i)sole primary source and authority for all Geurts Game Forge documentation' -and $gfiContractText.Contains("<PluginPackageRoot>/Documentation~/") -and $gfiContractText -match '(?i)must not ship a bundled or fallback copy of Geurts documentation') "Frozen GFI v2 keeps this repository authoritative and plugin Documentation~ plugin-specific"
    Assert-True ($gfiContractText -match '(?i)exactly one lightweight remote metadata check' -and $gfiContractText -match '(?i)Update availability is determined only by commit identity' -and $gfiContractText -match '(?i)commit IDs are identical, do not report an Update' -and $gfiContractText -match '(?i)Package-version ordering or inequality is display-only and must not determine availability' -and $gfiContractText -match '(?i)startup comparison result is unknown' -and $gfiContractText -match '(?i)must not download documentation[^\r\n]{0,200}inspect or hash the project-local copy' -and $gfiContractText -match '(?i)performs no additional remote documentation check' -and $gfiContractText -match '(?i)Local edits[^\r\n]{0,100}do not affect update availability') "Frozen GFI v2 retains its one commit-identity-only notification check without local inspection or lifecycle work"
    Assert-True ($gfiContractText.Contains("Installed Geurts Documentation: <version | Not installed | Unknown>") -and $gfiContractText.Contains("GameForgeIntelligence Plugin: <version | Unknown>") -and $gfiContractText.Contains("Available Geurts Documentation: <version>") -and $gfiContractText -match '(?i)Never derive[^\r\n]{0,180}mutable project-local documentation files' -and $gfiContractText -match '(?i)distinct values. Never display one as another') "Frozen GFI v2 keeps documentation, available, plugin, technique, and schema versions separately labelled"
    Assert-True ($gfiContractText -match '(?i)Every successful Update receipt records the authoritative selected commit ID' -and $gfiContractText -match '(?i)Immediately before the first destructive mutation[^\r\n]{0,160}invalidate or clear the current installed receipt' -and $gfiContractText -match '(?i)historical receipt is diagnostic history only and must never drive' -and $gfiContractText -match '(?i)report success only after that receipt is written' -and $gfiContractText -match '(?i)Failure or interruption after receipt invalidation must leave the current receipt absent or invalid' -and $gfiContractText -match '(?is)destination directory is absent.{0,140}`Not installed`.{0,220}directory exists.{0,180}`Unknown`') "Frozen GFI v2 retains its destructive receipt transition and post-success selected-commit receipt"
    Assert-True ($gfiContractText -match '(?i)safe default is Cancel' -and $gfiContractText -match '(?i)Every local edit anywhere inside GeurtsGameForgeDocumentation will be overwritten and lost' -and $gfiContractText -match '(?i)no rollback' -and $gfiContractText -match '(?i)missing or incomplete') "Frozen GFI v2 retains its cancel-default destructive warning"
    Assert-True ($gfiContractText -match '(?i)complete Git-tracked source tree' -and $gfiContractText -match '(?i)detached, writable content snapshot' -and $gfiContractText -match '(?i)no `\.git` directory or file' -and $gfiContractText -match '(?i)read-only file or directory attributes must be cleared' -and $gfiContractText -match '(?i)residue must never block a later') "Frozen GFI v2 retains its detached complete-tree snapshot contract"
    Assert-True ($gfiContractText -match '(?i)only project path this documentation Update may delete or replace' -and $gfiContractText -match '(?i)Every file and byte there[^\r\n]{0,160}must remain untouched' -and $gfiContractText -match '(?i)must not invoke native-entry setup') "Frozen GFI v2 retains its historical documentation-only boundary and leaves GDD and generic-tool subjects untouched"
    Assert-True ($gfiContractText -match '(?i)must not create or require an automatic documentation downloader or installer' -and $gfiContractText -match '(?i)Do not recreate any of those mechanisms under different terminology' -and $gfiContractText -match '(?i)legacy evidence[^\r\n]{0,60}untouched' -and $gfiContractText -match '(?i)must not consult it, depend on it, or allow it to block') "Frozen GFI v2 keeps discarded transaction/recovery machinery forbidden and legacy Library evidence non-blocking"

    $companionTechniqueText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"))
    $companionContract = Get-Content -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsDocumentationCompanionContract.json") -Raw | ConvertFrom-Json
    $expectedCompanionValidationEntries = @(
        "AGENTS.md",
        "AI_READ_FIRST.md",
        "GeurtsTechniqueManifest.md",
        "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md",
        "GeurtsTechniques/GeurtsDocumentationCompanionContract.json",
        "Tools/AIAgentInstructionTemplates/AGENTS.md",
        "Tools/AIAgentInstructionTemplates/copilot-instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
    )
    $expectedCompanionRoutes = @(
        "Tools/AIAgentInstructionTemplates/AGENTS.md|AGENTS.md",
        "Tools/AIAgentInstructionTemplates/copilot-instructions.md|.github/copilot-instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md|.github/instructions/geurts-unity.instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md|.github/instructions/geurts-game-design.instructions.md"
    )
    $actualCompanionRoutes = @($companionContract.routeMappings | ForEach-Object { "{0}|{1}" -f [string]$_.template, [string]$_.target })
    $actualConfirmationTargets = @($companionContract.updateUi.confirmationTargets | ForEach-Object { "{0}|{1}" -f [string]$_.path, [string]$_.effect })
    $expectedConfirmationTargets = @(
        "GeurtsGameForgeDocumentation|replace-complete-directory",
        "AGENTS.md|replace-complete-file",
        ".github/copilot-instructions.md|replace-complete-file",
        ".github/instructions/geurts-unity.instructions.md|replace-complete-file",
        ".github/instructions/geurts-game-design.instructions.md|replace-complete-file"
    )
    Assert-True ([string]$companionContract.schemaVersion -ceq "1.0.0" -and [string]$companionContract.packageVersion -ceq "0.11.4" -and [string]$companionContract.source.repository -ceq "https://github.com/Geurtsy/GeurtsGameForge_Documentation.git" -and [string]$companionContract.source.branch -ceq "main" -and [string]$companionContract.source.selection -ceq "exact-resolved-head-commit-archive") "Companion contract identifies schema 1.0.0, package v0.11.4, and the official exact-main-commit archive source"
    Assert-True ([string]$companionContract.destination.projectRelativePath -ceq "GeurtsGameForgeDocumentation" -and [string]$companionContract.destination.replacement -ceq "complete-directory" -and [string]$companionContract.destination.access -ceq "logically-read-only") "Companion contract names the one logically-read-only complete documentation destination"
    Assert-True ((@($companionContract.validationEntries) -join "|") -ceq ($expectedCompanionValidationEntries -join "|") -and @($companionContract.validationEntries | Select-Object -Unique).Count -eq 9) "Current companion contract names the exact nine unique package-v0.11.4 source-validation entries"
    Assert-True (($actualCompanionRoutes -join "|") -ceq ($expectedCompanionRoutes -join "|") -and ($actualConfirmationTargets -join "|") -ceq ($expectedConfirmationTargets -join "|") -and [string]$companionContract.updateUi.actionLabel -ceq "Update Geurts Game Forge Documentation" -and [string]$companionContract.updateUi.confirmationDefault -ceq "cancel" -and [string]$companionContract.updateUi.cancelResult -ceq "no-network-or-filesystem-change") "Companion contract fixes four template routes and one cancel-default five-target Update confirmation"
    Assert-True ($companionTechniqueText -match '(?i)one confirmation dialog' -and $companionTechniqueText -match '(?i)no earlier preview, dry run[^\r\n]{0,100}second confirmation' -and $companionTechniqueText -match '(?i)confirmation occurs before archive acquisition' -and $companionTechniqueText -match '(?i)earlier approval does not authorize a changed or expanded managed target set') "Confirmation uses the built-in schema-1.0.0 target set before acquisition and cannot authorize a changed downloaded target set"
    Assert-True ($companionTechniqueText -match '(?i)`packageVersion` is source-release metadata, not a companion compatibility gate' -and $companionTechniqueText -match '(?i)later package version alone must not require a companion release' -and $companionTechniqueText -match '(?i)schema-1\.0\.0 consumer may read a later list rather than pinning v0\.11\.0' -and $companionTechniqueText -match '(?i)every entry must be unique, safe, readable, and archive-root-relative') "Schema 1.0.0 keeps package versions and safe validation entries forward-compatible while mutation routes remain fixed"
    Assert-True ($companionTechniqueText -match '(?i)must not enumerate, inspect, create, validate, hash, modify, or delete anything under' -and $companionTechniqueText.Contains("<ProjectRoot>/Docs/GameDesign/") -and $companionTechniqueText -match '(?i)scan for or execute `\.bat`, `\.cmd`, `\.ps1`' -and $companionTechniqueText -match '(?i)copied as inert content') "Companion never inspects Docs/GameDesign, scans for setup work, or executes documentation/project scripts"
    Assert-True ($companionTechniqueText -match '(?i)may perform at most one lightweight metadata-only request' -and $companionTechniqueText -match '(?i)last-successful-installed commit value for this Unity project' -and $companionTechniqueText -match '(?i)value for one project must never suppress availability in another') "Companion startup comparison is optional-at-most-once and keeps external state isolated per Unity project"
    Assert-True ($companionTechniqueText -match '(?i)reports failure plainly and never reports partial completion as success' -and $companionTechniqueText -match '(?i)After every managed-target verification passes, report the content Update as successful and attempt to write' -and $companionTechniqueText -match '(?i)comparison-state write fails, report a warning[^\r\n]{0,160}do not reclassify, undo, or repair the successful five-target replacement' -and $companionTechniqueText -match '(?i)no automatic repair or recovery flow') "Companion reports content success after all five targets and treats later comparison-state persistence failure as a non-destructive warning"
    Assert-True ($companionTechniqueText -match '(?i)AI tool must support the applicable native instruction file or be explicitly instructed to read and follow `AGENTS\.md`' -and $companionTechniqueText -match '(?i)must not claim universal AI control or compliance') "Companion states the native AI-routing support limitation without claiming universal control"

    $expectedBrickRouteText = 'Before planning or modifying any Geurts Game Forge brick code, read and follow `GeurtsGameForgeDocumentation/AGENTS.md`; it routes to the installed, manifest-selected documentation. Treat that documentation as the source of truth for the work.'
    $nativeTemplateExpectations = @(
        @{ Path = "Tools/AIAgentInstructionTemplates/AGENTS.md"; Markers = @('id="agents-body" version="1.0.0" sha256="93464c8bace065ddfe2f305dfedafafbb8a1099cb318c21dad185d46d22451eb"') },
        @{ Path = "Tools/AIAgentInstructionTemplates/copilot-instructions.md"; Markers = @('id="copilot-body" version="1.0.0" sha256="c4493666c6135143f8c97d0f3b0aafd72375998b68359cf5bca13aa6cdb6a775"') },
        @{ Path = "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md"; Markers = @('id="unity-frontmatter" version="1.0.0" sha256="98e4fd786bbd1474e28d3800b91d749c29ff2acf94b89ef821d6860645829688"', 'id="unity-body" version="1.0.0" sha256="655d9a82ce462a8501ed3542589e5010abc995f2ed27beae4bc30550ecfc28cb"') },
        @{ Path = "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"; Markers = @('id="game-design-frontmatter" version="1.0.0" sha256="334b60274fe81a1891e1500785d29a249a0d4e32957bb665a770402163fa2cd4"', 'id="game-design-body" version="1.0.0" sha256="a064e41b0e80aac9c5109203c68cdc74eae6920c47e8e84d369a2395f19e3ec3"') }
    )
    foreach ($templateExpectation in $nativeTemplateExpectations) {
        $templateText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $templateExpectation.Path))
        $missingMarkers = @($templateExpectation.Markers | Where-Object { -not $templateText.Contains([string]$_) })
        Assert-True ([regex]::Matches($templateText, [regex]::Escape($expectedBrickRouteText)).Count -eq 1 -and $missingMarkers.Count -eq 0 -and -not $templateText.Contains('version="0.9.0"')) "$($templateExpectation.Path) has the exact v1.0.0 brick-first route and approved managed-region hashes"
    }

    # Project-mutating tools copied inside the documentation container must never infer that container as a Unity root.
    $rootSafetyProject = New-TestProject -Parent $testRoot -Name "explicit-root-safety"
    $copiedDocumentationRoot = Join-Path $rootSafetyProject "GeurtsGameForgeDocumentation"
    $copiedToolsRoot = Join-Path $copiedDocumentationRoot "Tools"
    New-Item -ItemType Directory -Path $copiedToolsRoot -Force | Out-Null
    foreach ($marker in @("Assets", "Packages", "ProjectSettings")) { New-Item -ItemType Directory -Path (Join-Path $copiedDocumentationRoot $marker) | Out-Null }
    foreach ($toolName in @("ManageGeurtsAgentInstructions.ps1", "CreateGeurtsFolderStructure.ps1", "UpdateGameDesignManifest.ps1")) {
        Copy-Item -LiteralPath (Join-Path $toolsRoot $toolName) -Destination (Join-Path $copiedToolsRoot $toolName)
    }
    $omittedRootRuns = @(
        (Invoke-TestScript -Path (Join-Path $copiedToolsRoot "ManageGeurtsAgentInstructions.ps1") -Arguments @()),
        (Invoke-TestScript -Path (Join-Path $copiedToolsRoot "CreateGeurtsFolderStructure.ps1") -Arguments @()),
        (Invoke-TestScript -Path (Join-Path $copiedToolsRoot "UpdateGameDesignManifest.ps1") -Arguments @())
    )
    $containerRootRuns = @(
        (Invoke-TestScript -Path (Join-Path $copiedToolsRoot "ManageGeurtsAgentInstructions.ps1") -Arguments @("-ProjectRoot", $copiedDocumentationRoot)),
        (Invoke-TestScript -Path (Join-Path $copiedToolsRoot "CreateGeurtsFolderStructure.ps1") -Arguments @("-ProjectRoot", $copiedDocumentationRoot)),
        (Invoke-TestScript -Path (Join-Path $copiedToolsRoot "UpdateGameDesignManifest.ps1") -Arguments @("-ProjectRoot", $copiedDocumentationRoot))
    )
    $unsafeNestedWrites = @("Docs", "GeurtsGameForgeDocumentation", ".github", "Assets/_Project") | Where-Object { Test-Path -LiteralPath (Join-Path $copiedDocumentationRoot $_) }
    $markerChildren = @(@("Assets", "Packages", "ProjectSettings") | ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $copiedDocumentationRoot $_) -Force })
    Assert-True (@($omittedRootRuns | Where-Object { $_.Code -eq 0 -or $_.Output -notmatch '(?i)ProjectRoot is required' }).Count -eq 0 -and @($containerRootRuns | Where-Object { $_.Code -eq 0 -or $_.Output -notmatch '(?i)documentation source or project-local fetched documentation copy' }).Count -eq 0 -and @($unsafeNestedWrites).Count -eq 0 -and $markerChildren.Count -eq 0) "Copied project-mutating tools reject the project-local fetched documentation copy even with fake Unity markers and never create nested project or native-entry content"

    $junctionRootTarget = New-TestProject -Parent $testRoot -Name "junction-unity-target"
    $junctionRootPath = Join-Path $testRoot "junction-unity-root"
    New-Item -ItemType Junction -Path $junctionRootPath -Target $junctionRootTarget | Out-Null
    try { $junctionRootRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $junctionRootPath, "-DefinitionPath", (Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureDefinition.json")) }
    finally { Remove-TestJunction -Path $junctionRootPath -ExpectedTarget $junctionRootTarget }
    Assert-True ($junctionRootRun.Code -ne 0 -and $junctionRootRun.Output -match '(?i)project root.*reparse point' -and -not (Test-Path -LiteralPath (Join-Path $junctionRootTarget "Assets/_Project"))) "Folder creation rejects a Unity project root that is itself a junction before any managed directory mutation"

    $managerDirectorySwapProject = New-TestProject -Parent $testRoot -Name "manager-directory-parent-swap"
    $managerDirectorySwapTarget = Join-Path $managerDirectorySwapProject ".github/instructions"
    $managerDirectorySwapBarrier = Join-Path $testRoot "barrier-manager-directory-swap"
    $managerDirectorySwapProcess = Start-TestScriptAtBarrier -Path $manageScript -Arguments @("-ProjectRoot", $managerDirectorySwapProject) -BarrierPath $managerDirectorySwapBarrier -TargetPath $managerDirectorySwapTarget
    $managerDirectorySwapGitHub = Join-Path $managerDirectorySwapProject ".github"
    $managerDirectorySwapSaved = Join-Path $managerDirectorySwapProject ".github-before-swap"
    $managerDirectorySwapOutside = Join-Path $testRoot "manager-directory-swap-outside"
    $managerDirectorySwapSentinel = Join-Path $managerDirectorySwapOutside "user-sentinel.txt"
    $managerDirectorySwapRun = $null
    try {
        Wait-TestScriptBarrier -Run $managerDirectorySwapProcess
        New-Item -ItemType Directory -Path $managerDirectorySwapOutside | Out-Null
        Write-Utf8 -Path $managerDirectorySwapSentinel -Text "Outside directory content must remain untouched.`n"
        $managerDirectorySwapSentinelHash = Get-FileSha -Path $managerDirectorySwapSentinel
        Move-Item -LiteralPath $managerDirectorySwapGitHub -Destination $managerDirectorySwapSaved
        New-Item -ItemType Junction -Path $managerDirectorySwapGitHub -Target $managerDirectorySwapOutside | Out-Null
        $managerDirectorySwapRun = Complete-TestScriptBarrier -Run $managerDirectorySwapProcess
        $managerDirectorySwapProcess = $null
    }
    finally {
        Stop-TestScriptBarrier -Run $managerDirectorySwapProcess
        Restore-TestDirectorySwap -Path $managerDirectorySwapGitHub -ExpectedTarget $managerDirectorySwapOutside -SavedPath $managerDirectorySwapSaved
    }
    Assert-True ($managerDirectorySwapRun -and $managerDirectorySwapRun.Code -ne 0 -and $managerDirectorySwapRun.Output -match '(?i)reparse point immediately before acceptance or creation' -and (Get-FileSha -Path $managerDirectorySwapSentinel) -eq $managerDirectorySwapSentinelHash -and -not (Test-Path -LiteralPath (Join-Path $managerDirectorySwapOutside "instructions")) -and -not (Test-Path -LiteralPath (Join-Path $managerDirectorySwapProject "AGENTS.md"))) "Native manager rejects a parent junction introduced at the final directory boundary without creating descendants outside the project"

    # Native creation is the safe default; GDD scaffolding requires separate explicit authorization.
    $nativeOnly = New-TestProject -Parent $testRoot -Name "native-only"
    $nativeOnlyRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $nativeOnly)
    Assert-True ($nativeOnlyRun.Code -eq 0 -and (Test-Path -LiteralPath (Join-Path $nativeOnly "AGENTS.md") -PathType Leaf) -and (Test-Path -LiteralPath (Join-Path $nativeOnly ".github/instructions/geurts-unity.instructions.md") -PathType Leaf) -and -not (Test-Path -LiteralPath (Join-Path $nativeOnly "Docs")) -and -not (Test-Path -LiteralPath (Join-Path $nativeOnly ".geurts")) -and $nativeOnlyRun.Output.IndexOf("documentation operation", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) "Bare managed setup changes native discovery entries only, without GDD or documentation/network state"

    # Explicitly authorized GDD scaffolding, outside-marker preservation, and idempotence.
    $fresh = New-TestProject -Parent $testRoot -Name "fresh"
    $firstSetup = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-IncludeGameDesignScaffolding")
    Assert-True ($firstSetup.Code -eq 0) "Fresh setup succeeds without network access"
    Assert-True ($firstSetup.Output.Contains("Created: .github") -and $firstSetup.Output.Contains("Created: Docs/GameDesign")) "Fresh setup reports managed native-entry and GDD directories"
    Assert-True ($firstSetup.Output.IndexOf("Game Design Manifest summary", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) "GDD scaffolding alone does not implicitly run manifest maintenance"
    foreach ($relative in @("AGENTS.md", ".github/copilot-instructions.md", ".github/instructions/geurts-unity.instructions.md", ".github/instructions/geurts-game-design.instructions.md", "Docs/GameDesign/README.md", "Docs/GameDesign/GameDesignManifest.md")) {
        Assert-True (Test-Path -LiteralPath (Join-Path $fresh $relative) -PathType Leaf) "Fresh setup creates $relative"
    }
    $freshAgentsText = [System.IO.File]::ReadAllText((Join-Path $fresh "AGENTS.md"))
    Assert-True ($freshAgentsText.Contains('version="1.0.0"') -and [regex]::Matches($freshAgentsText, [regex]::Escape($expectedBrickRouteText)).Count -eq 1 -and -not $freshAgentsText.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md") -and -not $freshAgentsText.Contains("Docs/GameDesign/")) "Project-root AGENTS is the exact v1.0.0 brick-first copied-AGENTS discovery shim"
    foreach ($relative in @(".github/copilot-instructions.md", ".github/instructions/geurts-unity.instructions.md", ".github/instructions/geurts-game-design.instructions.md")) {
        $nativeRouteText = [System.IO.File]::ReadAllText((Join-Path $fresh $relative))
        Assert-True ($nativeRouteText.Contains('version="1.0.0"') -and [regex]::Matches($nativeRouteText, [regex]::Escape($expectedBrickRouteText)).Count -eq 1 -and -not $nativeRouteText.Contains("owns the complete documentation chain") -and -not $nativeRouteText.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md") -and -not $nativeRouteText.Contains("network efficiency")) "$relative is the exact concise v1.0.0 brick-first route through copied AGENTS.md into the installed manifest-selected documentation"
    }
    $freshGddReadmeText = [System.IO.File]::ReadAllText((Join-Path $fresh "Docs/GameDesign/README.md"))
    Assert-True ($freshGddReadmeText -match '(?i)project-local fetched Geurts documentation copy' -and $freshGddReadmeText -match '(?i)missing information would establish or change player-facing design intent' -and $freshGddReadmeText -match '(?i)reversible technical details that do not create or overwrite design facts' -and $freshGddReadmeText.Contains('GEURTS-SCAFFOLD-BEGIN version="0.10.0"')) "Managed GDD README remains separate from the fetched copy, stops for missing design intent, and permits only reversible non-design assumptions"
    $trackedFiles = @("AGENTS.md", ".github/copilot-instructions.md", ".github/instructions/geurts-unity.instructions.md", ".github/instructions/geurts-game-design.instructions.md", "Docs/GameDesign/README.md", "Docs/GameDesign/GameDesignManifest.md")
    $before = @{}
    foreach ($relative in $trackedFiles) { $before[$relative] = Get-FileSha -Path (Join-Path $fresh $relative) }
    $secondSetup = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-IncludeGameDesignScaffolding")
    Assert-True ($secondSetup.Code -eq 0) "Second setup succeeds"
    foreach ($relative in $trackedFiles) { Assert-True ((Get-FileSha -Path (Join-Path $fresh $relative)) -eq $before[$relative]) "Second setup leaves $relative byte-identical" }
    $jsonSetupRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-IncludeGameDesignScaffolding", "-UpdateGameDesignManifest", "-OutputFormat", "Json")
    $jsonSetupObject = $null
    try { $jsonSetupObject = $jsonSetupRun.Output | ConvertFrom-Json }
    catch { }
    Assert-True ($jsonSetupRun.Code -eq 0 -and $jsonSetupObject -and $jsonSetupObject.status -eq "OK" -and $jsonSetupObject.gameDesignManifest.status -eq "UPDATED") "First separately authorized manifest update indexes the new GDD scaffold in one parseable JSON result"
    $jsonSetupAgainRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-UpdateGameDesignManifest", "-OutputFormat", "Json")
    $jsonSetupAgainObject = $null
    try { $jsonSetupAgainObject = $jsonSetupAgainRun.Output | ConvertFrom-Json }
    catch { }
    Assert-True ($jsonSetupAgainRun.Code -eq 0 -and $jsonSetupAgainObject -and $jsonSetupAgainObject.status -eq "OK" -and $jsonSetupAgainObject.gameDesignManifest.status -eq "UNCHANGED") "Repeated standalone manifest maintenance is parseable and idempotent"

    $agentsPath = Join-Path $fresh "AGENTS.md"
    [System.IO.File]::AppendAllText($agentsPath, "`nUser-owned note outside the managed block.`n", $utf8NoBom)
    $outsideHash = Get-FileSha -Path $agentsPath
    $outsideRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-IncludeGameDesignScaffolding")
    Assert-True ($outsideRun.Code -eq 0 -and (Get-FileSha -Path $agentsPath) -eq $outsideHash) "Content outside managed markers is preserved"

    $managedV07 = New-TestProject -Parent $testRoot -Name "managed-v07-agents"
    $managedV07Path = Join-Path $managedV07 "AGENTS.md"
    $managedV07Base = Get-HistoricalFile -Specification "5f51965:Tools/AIAgentInstructionTemplates/AGENTS.md"
    $managedV07WithEndWhitespace = $managedV07Base.Replace('<!-- GEURTS-MANAGED-END id="agents-body" -->', '<!-- GEURTS-MANAGED-END id="agents-body" -->   ')
    $managedV07CrLf = ((($managedV07WithEndWhitespace -replace "`r`n", "`n") -replace "`r", "`n").Replace("`n", "`r`n"))
    $managedV07Text = $managedV07Base + "`nUser-owned content outside the managed region.`n"
    Write-Utf8 -Path $managedV07Path -Text $managedV07Text
    $managedV07Run = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $managedV07)
    $managedV10Text = [System.IO.File]::ReadAllText($managedV07Path)
    Assert-True ($managedV07Run.Code -eq 0 -and $managedV10Text.Contains('version="1.0.0"') -and [regex]::Matches($managedV10Text, [regex]::Escape($expectedBrickRouteText)).Count -eq 1 -and -not $managedV10Text.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md") -and $managedV10Text.Contains("User-owned content outside the managed region.")) "Valid managed v0.7 AGENTS upgrades to the exact v1.0.0 brick-first shim while preserving outside content"

    $utf8BomProject = New-TestProject -Parent $testRoot -Name "managed-utf8-bom-mixed-newlines"
    $utf8BomPath = Join-Path $utf8BomProject "AGENTS.md"
    $utf8BomEncoding = New-Object System.Text.UTF8Encoding($true, $true)
    $utf8PrefixText = "# UTF-8 user prefix`r`nMixed newline stays`n"
    $utf8SuffixText = "`r`n`r`nUTF-8 user suffix`r`n"
    [System.IO.File]::WriteAllText($utf8BomPath, ($utf8PrefixText + $managedV07CrLf + $utf8SuffixText), $utf8BomEncoding)
    $utf8BeforeHash = Get-FileSha -Path $utf8BomPath
    $utf8Run = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $utf8BomProject)
    $utf8AfterBytes = [System.IO.File]::ReadAllBytes($utf8BomPath)
    $utf8AfterText = $utf8BomEncoding.GetString($utf8AfterBytes, 3, $utf8AfterBytes.Length - 3)
    $utf8ManagedRegion = [regex]::Match($utf8AfterText, '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN.*?^<!--\s*GEURTS-MANAGED-END[^\r\n]*')
    $utf8ExpectedPrefix = [byte[]](@($utf8BomEncoding.GetPreamble()) + @($utf8BomEncoding.GetBytes($utf8PrefixText)))
    $utf8ExpectedSuffix = [byte[]]($utf8BomEncoding.GetBytes($utf8SuffixText))
    Assert-True ($utf8Run.Code -eq 0 -and (Test-BytePrefix -Bytes $utf8AfterBytes -Expected $utf8ExpectedPrefix) -and (Test-ByteSuffix -Bytes $utf8AfterBytes -Expected $utf8ExpectedSuffix) -and $utf8ManagedRegion.Success -and (Test-CrLfOnly -Text $utf8ManagedRegion.Value) -and (Get-FileSha -Path ($utf8BomPath + ".pre-v0.9.0.bak")) -eq $utf8BeforeHash) "Managed UTF-8 BOM update preserves exact outside bytes and the CRLF managed-region convention with a byte-identical backup"

    $utf16Project = New-TestProject -Parent $testRoot -Name "managed-utf16"
    $utf16Path = Join-Path $utf16Project "AGENTS.md"
    $utf16Encoding = New-Object System.Text.UnicodeEncoding($false, $true, $true)
    $utf16PrefixText = "# UTF-16 user prefix`r`n"
    $utf16SuffixText = "`r`nUTF-16 user suffix`n"
    [System.IO.File]::WriteAllText($utf16Path, ($utf16PrefixText + $managedV07CrLf + $utf16SuffixText), $utf16Encoding)
    $utf16BeforeHash = Get-FileSha -Path $utf16Path
    $utf16Run = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $utf16Project)
    $utf16AfterBytes = [System.IO.File]::ReadAllBytes($utf16Path)
    $utf16AfterText = $utf16Encoding.GetString($utf16AfterBytes, 2, $utf16AfterBytes.Length - 2)
    $utf16ManagedRegion = [regex]::Match($utf16AfterText, '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN.*?^<!--\s*GEURTS-MANAGED-END[^\r\n]*')
    $utf16ExpectedPrefix = [byte[]](@($utf16Encoding.GetPreamble()) + @($utf16Encoding.GetBytes($utf16PrefixText)))
    $utf16ExpectedSuffix = [byte[]]($utf16Encoding.GetBytes($utf16SuffixText))
    Assert-True ($utf16Run.Code -eq 0 -and (Test-BytePrefix -Bytes $utf16AfterBytes -Expected $utf16ExpectedPrefix) -and (Test-ByteSuffix -Bytes $utf16AfterBytes -Expected $utf16ExpectedSuffix) -and $utf16ManagedRegion.Success -and (Test-CrLfOnly -Text $utf16ManagedRegion.Value) -and (Get-FileSha -Path ($utf16Path + ".pre-v0.9.0.bak")) -eq $utf16BeforeHash) "Managed UTF-16LE update preserves exact outside bytes, encoding, and CRLF region with a byte-identical backup"

    $utf16BeProject = New-TestProject -Parent $testRoot -Name "managed-utf16be"
    $utf16BePath = Join-Path $utf16BeProject "AGENTS.md"
    $utf16BeEncoding = New-Object System.Text.UnicodeEncoding($true, $true, $true)
    $utf16BePrefixText = "# UTF-16BE user prefix`r`n"
    $utf16BeSuffixText = "`r`nUTF-16BE user suffix`n"
    [System.IO.File]::WriteAllText($utf16BePath, ($utf16BePrefixText + $managedV07CrLf + $utf16BeSuffixText), $utf16BeEncoding)
    $utf16BeBeforeHash = Get-FileSha -Path $utf16BePath
    $utf16BeRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $utf16BeProject)
    $utf16BeAfterBytes = [System.IO.File]::ReadAllBytes($utf16BePath)
    $utf16BeExpectedPrefix = [byte[]](@($utf16BeEncoding.GetPreamble()) + @($utf16BeEncoding.GetBytes($utf16BePrefixText)))
    $utf16BeExpectedSuffix = [byte[]]($utf16BeEncoding.GetBytes($utf16BeSuffixText))
    Assert-True ($utf16BeRun.Code -eq 0 -and (Test-BytePrefix -Bytes $utf16BeAfterBytes -Expected $utf16BeExpectedPrefix) -and (Test-ByteSuffix -Bytes $utf16BeAfterBytes -Expected $utf16BeExpectedSuffix) -and (Get-FileSha -Path ($utf16BePath + ".pre-v0.9.0.bak")) -eq $utf16BeBeforeHash) "Managed UTF-16BE update preserves exact outside bytes and encoding with a byte-identical backup"

    $unsupportedEncodingProject = New-TestProject -Parent $testRoot -Name "unsupported-managed-encoding"
    $unsupportedEncodingPath = Join-Path $unsupportedEncodingProject "AGENTS.md"
    [System.IO.File]::WriteAllBytes($unsupportedEncodingPath, [byte[]](0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00))
    $unsupportedEncodingHash = Get-FileSha -Path $unsupportedEncodingPath
    $unsupportedEncodingRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $unsupportedEncodingProject)
    Assert-True ($unsupportedEncodingRun.Code -eq 2 -and (Get-FileSha -Path $unsupportedEncodingPath) -eq $unsupportedEncodingHash -and -not (Test-Path -LiteralPath ($unsupportedEncodingPath + ".pre-v0.9.0.bak")) -and $unsupportedEncodingRun.Output -match '(?i)unsupported UTF-32') "Unsupported managed-entry encoding conflicts without rewrite, backup, or silent UTF-8 conversion"

    $invalidUtf8Project = New-TestProject -Parent $testRoot -Name "invalid-utf8-managed-entry"
    $invalidUtf8Path = Join-Path $invalidUtf8Project "AGENTS.md"
    [System.IO.File]::WriteAllBytes($invalidUtf8Path, [byte[]](0x23, 0x20, 0xC3, 0x28, 0x0A))
    $invalidUtf8Hash = Get-FileSha -Path $invalidUtf8Path
    $invalidUtf8Run = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $invalidUtf8Project)
    Assert-True ($invalidUtf8Run.Code -eq 2 -and (Get-FileSha -Path $invalidUtf8Path) -eq $invalidUtf8Hash -and -not (Test-Path -LiteralPath ($invalidUtf8Path + ".pre-v0.9.0.bak")) -and $invalidUtf8Run.Output -match '(?i)invalid text encoding') "Invalid BOM-less UTF-8 conflicts without rewrite, backup, or silent replacement"

    $concurrentCreateProject = New-TestProject -Parent $testRoot -Name "concurrent-native-create"
    $concurrentCreatePath = Join-Path $concurrentCreateProject "AGENTS.md"
    $concurrentCreateBarrier = Join-Path $testRoot "barrier-native-create"
    $concurrentCreateProcess = Start-TestScriptAtBarrier -Path $manageScript -Arguments @("-ProjectRoot", $concurrentCreateProject) -BarrierPath $concurrentCreateBarrier -TargetPath $concurrentCreatePath
    Wait-TestScriptBarrier -Run $concurrentCreateProcess
    Write-Utf8 -Path $concurrentCreatePath -Text "# Concurrent user-created instructions`r`nPreserve this file.`r`n"
    $concurrentCreateHash = Get-FileSha -Path $concurrentCreatePath
    $concurrentCreateRun = Complete-TestScriptBarrier -Run $concurrentCreateProcess
    Assert-True ($concurrentCreateRun.Code -eq 2 -and (Get-FileSha -Path $concurrentCreatePath) -eq $concurrentCreateHash -and $concurrentCreateRun.Output -match '(?i)target appeared.*concurrent content was preserved') "Concurrent native-entry creation wins the absent-state race and is never overwritten"

    $concurrentManagedProject = New-TestProject -Parent $testRoot -Name "concurrent-managed-update"
    $concurrentManagedPath = Join-Path $concurrentManagedProject "AGENTS.md"
    Write-Utf8 -Path $concurrentManagedPath -Text $managedV07Text
    $concurrentManagedOriginalHash = Get-FileSha -Path $concurrentManagedPath
    $concurrentManagedBarrier = Join-Path $testRoot "barrier-managed-update"
    $concurrentManagedProcess = Start-TestScriptAtBarrier -Path $manageScript -Arguments @("-ProjectRoot", $concurrentManagedProject) -BarrierPath $concurrentManagedBarrier -TargetPath $concurrentManagedPath
    Wait-TestScriptBarrier -Run $concurrentManagedProcess
    [System.IO.File]::AppendAllText($concurrentManagedPath, "Concurrent user edit.`r`n", $utf8NoBom)
    $concurrentManagedHash = Get-FileSha -Path $concurrentManagedPath
    $concurrentManagedRun = Complete-TestScriptBarrier -Run $concurrentManagedProcess
    Assert-True ($concurrentManagedRun.Code -eq 2 -and (Get-FileSha -Path $concurrentManagedPath) -eq $concurrentManagedHash -and (Get-FileSha -Path ($concurrentManagedPath + ".pre-v0.9.0.bak")) -eq $concurrentManagedOriginalHash -and $concurrentManagedRun.Output -match '(?i)target bytes changed.*concurrent content was preserved') "Concurrent raw-byte drift during a managed-region update is preserved and reported"

    $concurrentLegacyProject = New-TestProject -Parent $testRoot -Name "concurrent-legacy-migration"
    $concurrentLegacyPath = Join-Path $concurrentLegacyProject "AGENTS.md"
    Write-Utf8 -Path $concurrentLegacyPath -Text (Get-HistoricalFile -Specification "544922c:Tools/AIAgentInstructionTemplates/AGENTS.md")
    $concurrentLegacyOriginalHash = Get-FileSha -Path $concurrentLegacyPath
    $concurrentLegacyBarrier = Join-Path $testRoot "barrier-legacy-migration"
    $concurrentLegacyProcess = Start-TestScriptAtBarrier -Path $manageScript -Arguments @("-ProjectRoot", $concurrentLegacyProject) -BarrierPath $concurrentLegacyBarrier -TargetPath $concurrentLegacyPath
    Wait-TestScriptBarrier -Run $concurrentLegacyProcess
    [System.IO.File]::AppendAllText($concurrentLegacyPath, "Concurrent legacy edit.`n", $utf8NoBom)
    $concurrentLegacyHash = Get-FileSha -Path $concurrentLegacyPath
    $concurrentLegacyRun = Complete-TestScriptBarrier -Run $concurrentLegacyProcess
    Assert-True ($concurrentLegacyRun.Code -eq 2 -and (Get-FileSha -Path $concurrentLegacyPath) -eq $concurrentLegacyHash -and (Get-FileSha -Path ($concurrentLegacyPath + ".pre-v0.9.0.bak")) -eq $concurrentLegacyOriginalHash -and $concurrentLegacyRun.Output -match '(?i)target bytes changed.*concurrent content was preserved') "Concurrent raw-byte drift during exact legacy migration is preserved and reported"

    foreach ($backupSwapCase in @(
        @{ Name = "managed"; Specification = "5f51965:Tools/AIAgentInstructionTemplates/copilot-instructions.md"; Label = "managed-region update" },
        @{ Name = "legacy"; Specification = "544922c:Tools/AIAgentInstructionTemplates/copilot-instructions.md"; Label = "exact legacy migration" }
    )) {
        $backupSwapProject = New-TestProject -Parent $testRoot -Name ("backup-parent-swap-" + $backupSwapCase.Name)
        [System.IO.File]::Copy((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md"), (Join-Path $backupSwapProject "AGENTS.md"))
        $backupSwapGitHub = Join-Path $backupSwapProject ".github"
        New-Item -ItemType Directory -Path $backupSwapGitHub | Out-Null
        $backupSwapTarget = Join-Path $backupSwapGitHub "copilot-instructions.md"
        Write-Utf8 -Path $backupSwapTarget -Text (Get-HistoricalFile -Specification $backupSwapCase.Specification)
        $backupSwapTargetHash = Get-FileSha -Path $backupSwapTarget
        $backupSwapBackup = $backupSwapTarget + ".pre-v0.9.0.bak"
        $backupSwapBarrier = Join-Path $testRoot ("barrier-backup-parent-swap-" + $backupSwapCase.Name)
        $backupSwapProcess = Start-TestScriptAtBarrier -Path $manageScript -Arguments @("-ProjectRoot", $backupSwapProject) -BarrierPath $backupSwapBarrier -TargetPath $backupSwapBackup
        $backupSwapSaved = Join-Path $backupSwapProject ".github-before-swap"
        $backupSwapOutside = Join-Path $testRoot ("backup-parent-swap-outside-" + $backupSwapCase.Name)
        $backupSwapSentinel = Join-Path $backupSwapOutside "user-sentinel.txt"
        $backupSwapRun = $null
        try {
            Wait-TestScriptBarrier -Run $backupSwapProcess
            New-Item -ItemType Directory -Path $backupSwapOutside | Out-Null
            Write-Utf8 -Path $backupSwapSentinel -Text "Outside backup content must remain untouched.`n"
            $backupSwapSentinelHash = Get-FileSha -Path $backupSwapSentinel
            Move-Item -LiteralPath $backupSwapGitHub -Destination $backupSwapSaved
            New-Item -ItemType Junction -Path $backupSwapGitHub -Target $backupSwapOutside | Out-Null
            $backupSwapRun = Complete-TestScriptBarrier -Run $backupSwapProcess
            $backupSwapProcess = $null
        }
        finally {
            Stop-TestScriptBarrier -Run $backupSwapProcess
            Restore-TestDirectorySwap -Path $backupSwapGitHub -ExpectedTarget $backupSwapOutside -SavedPath $backupSwapSaved
        }
        $backupSwapDebris = @(
            @(Get-ChildItem -LiteralPath $backupSwapProject -Filter ".ggf-*" -Force -File -ErrorAction SilentlyContinue)
            @(Get-ChildItem -LiteralPath $backupSwapGitHub -Filter ".ggf-*" -Force -File -ErrorAction SilentlyContinue)
        )
        Assert-True ($backupSwapRun -and $backupSwapRun.Code -ne 0 -and $backupSwapRun.Output -match '(?i)backup path changed.*unsafe reparse point' -and (Get-FileSha -Path $backupSwapTarget) -eq $backupSwapTargetHash -and (Get-FileSha -Path $backupSwapSentinel) -eq $backupSwapSentinelHash -and -not (Test-Path -LiteralPath $backupSwapBackup) -and -not (Test-Path -LiteralPath (Join-Path $backupSwapOutside "copilot-instructions.md.pre-v0.9.0.bak")) -and $backupSwapDebris.Count -eq 0) "Parent swap before $($backupSwapCase.Label) backup promotion preserves target/outside bytes and leaves no backup or transaction debris"
    }

    $pathSwapProject = New-TestProject -Parent $testRoot -Name "native-parent-reparse-swap"
    $pathSwapAgents = Join-Path $pathSwapProject "AGENTS.md"
    [System.IO.File]::Copy((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md"), $pathSwapAgents)
    $pathSwapTarget = Join-Path $pathSwapProject ".github/copilot-instructions.md"
    $pathSwapBarrier = Join-Path $testRoot "barrier-native-parent-swap"
    $pathSwapProcess = Start-TestScriptAtBarrier -Path $manageScript -Arguments @("-ProjectRoot", $pathSwapProject) -BarrierPath $pathSwapBarrier -TargetPath $pathSwapTarget
    $pathSwapGitHub = Join-Path $pathSwapProject ".github"
    $pathSwapSavedGitHub = Join-Path $pathSwapProject ".github-before-swap"
    $pathSwapOutside = Join-Path $testRoot "native-parent-swap-outside"
    $pathSwapSentinel = Join-Path $pathSwapOutside "user-sentinel.txt"
    $pathSwapRun = $null
    try {
        Wait-TestScriptBarrier -Run $pathSwapProcess
        New-Item -ItemType Directory -Path $pathSwapOutside | Out-Null
        Write-Utf8 -Path $pathSwapSentinel -Text "Outside user content must remain untouched.`r`n"
        $pathSwapSentinelHash = Get-FileSha -Path $pathSwapSentinel
        Move-Item -LiteralPath $pathSwapGitHub -Destination $pathSwapSavedGitHub
        New-Item -ItemType Junction -Path $pathSwapGitHub -Target $pathSwapOutside | Out-Null
        $pathSwapRun = Complete-TestScriptBarrier -Run $pathSwapProcess
        $pathSwapProcess = $null
    }
    finally {
        Stop-TestScriptBarrier -Run $pathSwapProcess
        Restore-TestDirectorySwap -Path $pathSwapGitHub -ExpectedTarget $pathSwapOutside -SavedPath $pathSwapSavedGitHub
    }
    $pathSwapTempFiles = @(
        @(Get-ChildItem -LiteralPath $pathSwapProject -Filter ".ggf-*" -Force -File -ErrorAction SilentlyContinue)
        @(Get-ChildItem -LiteralPath $pathSwapGitHub -Filter ".ggf-*" -Force -File -ErrorAction SilentlyContinue)
    )
    Assert-True ($pathSwapRun -and $pathSwapRun.Code -ne 0 -and $pathSwapRun.Output -match '(?i)reparse point' -and (Get-FileSha -Path $pathSwapSentinel) -eq $pathSwapSentinelHash -and -not (Test-Path -LiteralPath (Join-Path $pathSwapOutside "copilot-instructions.md")) -and $pathSwapTempFiles.Count -eq 0) "Late native-entry parent reparse swap is rejected at the final guard without external writes or transaction debris"

    $unknownManagedProject = New-TestProject -Parent $testRoot -Name "unknown-product-managed-block"
    $unknownManagedPath = Join-Path $unknownManagedProject "AGENTS.md"
    Write-Utf8 -Path $unknownManagedPath -Text "<!-- PRODUCT_POLICY_START -->`nUser or product content.`n<!-- PRODUCT_POLICY_END -->`n"
    $unknownManagedHash = Get-FileSha -Path $unknownManagedPath
    $unknownManagedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $unknownManagedProject)
    Assert-True ($unknownManagedRun.Code -eq 2 -and (Get-FileSha -Path $unknownManagedPath) -eq $unknownManagedHash -and -not (Test-Path -LiteralPath ($unknownManagedPath + ".pre-v0.9.0.bak"))) "Unknown product- or user-owned managed blocks conflict and remain byte-identical"

    $userOwned = New-TestProject -Parent $testRoot -Name "user-owned"
    Write-Utf8 -Path (Join-Path $userOwned "AGENTS.md") -Text "# Personal project instructions`nKeep this content.`n"
    $userHash = Get-FileSha -Path (Join-Path $userOwned "AGENTS.md")
    $userRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $userOwned)
    Assert-True ($userRun.Code -eq 0 -and (Get-FileSha -Path (Join-Path $userOwned "AGENTS.md")) -eq $userHash) "Unmarked user-owned native file is preserved"

    $blockedSetup = New-TestProject -Parent $testRoot -Name "blocked-setup-directory"
    Write-Utf8 -Path (Join-Path $blockedSetup ".github") -Text "user-owned blocking file`n"
    $blockedSetupHash = Get-FileSha -Path (Join-Path $blockedSetup ".github")
    $blockedSetupRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $blockedSetup)
    Assert-True ($blockedSetupRun.Code -eq 1 -and (Get-FileSha -Path (Join-Path $blockedSetup ".github")) -eq $blockedSetupHash -and -not (Test-Path -LiteralPath (Join-Path $blockedSetup "AGENTS.md"))) "Managed setup preflights blocking directories before any file mutation"

    $malformed = New-TestProject -Parent $testRoot -Name "malformed"
    $malformedPath = Join-Path $malformed "AGENTS.md"
    Write-Utf8 -Path $malformedPath -Text '<!-- GEURTS-MANAGED-BEGIN id="broken" version="0.7.0" sha256="0000000000000000000000000000000000000000000000000000000000000000" -->'
    $malformedHash = Get-FileSha -Path $malformedPath
    $malformedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $malformed)
    Assert-True ($malformedRun.Code -eq 2 -and (Get-FileSha -Path $malformedPath) -eq $malformedHash) "Malformed managed markers conflict without overwriting"

    $yamlOutside = New-TestProject -Parent $testRoot -Name "yaml-outside-frontmatter"
    $yamlOutsidePath = Join-Path $yamlOutside ".github/instructions/geurts-unity.instructions.md"
    $yamlTemplateText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md"))
    $yamlRegion = [regex]::Match($yamlTemplateText, '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="unity-frontmatter".*?^#\s*GEURTS-MANAGED-END\s+id="unity-frontmatter"\s*$')
    if (-not $yamlRegion.Success) { throw "Unable to prepare the YAML marker boundary fixture." }
    $yamlOutsideText = $yamlTemplateText.Remove($yamlRegion.Index, $yamlRegion.Length).TrimEnd() + "`n`n" + $yamlRegion.Value + "`n"
    Write-Utf8 -Path $yamlOutsidePath -Text $yamlOutsideText
    $yamlOutsideHash = Get-FileSha -Path $yamlOutsidePath
    $yamlOutsideRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $yamlOutside)
    Assert-True ($yamlOutsideRun.Code -eq 2 -and (Get-FileSha -Path $yamlOutsidePath) -eq $yamlOutsideHash -and $yamlOutsideRun.Output.Contains("frontmatter delimiters")) "YAML managed markers outside frontmatter conflict without overwriting"

    $optOut = New-TestProject -Parent $testRoot -Name "opt-out"
    $optOutPath = Join-Path $optOut "AGENTS.md"
    $optOutText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md")) + "`n<!-- GEURTS-MANAGED-OPT-OUT -->`nUser-owned routing remains authoritative.`n"
    Write-Utf8 -Path $optOutPath -Text $optOutText
    $optOutHash = Get-FileSha -Path $optOutPath
    $optOutRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $optOut)
    Assert-True ($optOutRun.Code -eq 0 -and (Get-FileSha -Path $optOutPath) -eq $optOutHash -and $optOutRun.Output.Contains("Skipped: AGENTS.md")) "Explicit managed opt-out preserves the complete native entry"

    $editedManaged = New-TestProject -Parent $testRoot -Name "edited-managed"
    $editedManagedPath = Join-Path $editedManaged "AGENTS.md"
    $editedManagedText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md")).Replace("Geurts Game Forge external-tool route", "User Edited Geurts Game Forge external-tool route")
    Write-Utf8 -Path $editedManagedPath -Text $editedManagedText
    $editedManagedHash = Get-FileSha -Path $editedManagedPath
    $editedManagedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $editedManaged)
    Assert-True ($editedManagedRun.Code -eq 2 -and (Get-FileSha -Path $editedManagedPath) -eq $editedManagedHash) "Edited managed content conflicts without overwriting"

    $futureManaged = New-TestProject -Parent $testRoot -Name "future-managed"
    $futureManagedPath = Join-Path $futureManaged "AGENTS.md"
    $futureManagedText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md")).Replace('version="1.0.0"', 'version="2.0.0"')
    Write-Utf8 -Path $futureManagedPath -Text $futureManagedText
    $futureManagedHash = Get-FileSha -Path $futureManagedPath
    $futureManagedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $futureManaged)
    Assert-True ($futureManagedRun.Code -eq 2 -and (Get-FileSha -Path $futureManagedPath) -eq $futureManagedHash -and $futureManagedRun.Output.Contains("no downgrade")) "Future managed native entry is never downgraded"

    $tamperedCatalogProject = New-TestProject -Parent $testRoot -Name "tampered-catalog"
    $tamperedCatalogPath = Join-Path $tamperedCatalogProject "NativeEntryMigrationCatalog.json"
    $tamperedCatalog = Get-Content -LiteralPath (Join-Path $RepositoryRoot "Tools/NativeEntryMigrationCatalog.json") -Raw | ConvertFrom-Json
    $tamperedCatalog.entries[0].targetPath = "UserInstructions.md"
    Write-Utf8 -Path $tamperedCatalogPath -Text ($tamperedCatalog | ConvertTo-Json -Depth 10)
    $tamperedCatalogRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $tamperedCatalogProject, "-MigrationCatalogPath", $tamperedCatalogPath)
    Assert-True ($tamperedCatalogRun.Code -eq 1 -and -not (Test-Path -LiteralPath (Join-Path $tamperedCatalogProject "UserInstructions.md"))) "Tampered migration catalog is rejected before native mutation"

    # Exact historical v0.4, mixed v0.5, and v0.6 templates migrate with backups.
    $historicalSets = @(
        @{ Name = "v04"; Files = @{
            "AGENTS.md" = "b989941:Tools/AIAgentInstructionTemplates/AGENTS.md";
            ".github/copilot-instructions.md" = "b989941:Tools/AIAgentInstructionTemplates/copilot-instructions.md";
            ".github/instructions/geurts-unity.instructions.md" = "b989941:Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md";
            ".github/instructions/geurts-game-design.instructions.md" = "b989941:Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
        }},
        @{ Name = "v05"; Files = @{
            "AGENTS.md" = "a84cdd9:Tools/AIAgentInstructionTemplates/AGENTS.md";
            ".github/copilot-instructions.md" = "b989941:Tools/AIAgentInstructionTemplates/copilot-instructions.md";
            ".github/instructions/geurts-unity.instructions.md" = "b989941:Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md";
            ".github/instructions/geurts-game-design.instructions.md" = "b989941:Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
        }},
        @{ Name = "v06"; Files = @{
            "AGENTS.md" = "544922c:Tools/AIAgentInstructionTemplates/AGENTS.md";
            ".github/copilot-instructions.md" = "544922c:Tools/AIAgentInstructionTemplates/copilot-instructions.md";
            ".github/instructions/geurts-unity.instructions.md" = "544922c:Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md";
            ".github/instructions/geurts-game-design.instructions.md" = "544922c:Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
        }}
    )
    foreach ($set in $historicalSets) {
        $project = New-TestProject -Parent $testRoot -Name $set.Name
        foreach ($relative in $set.Files.Keys) { Write-Utf8 -Path (Join-Path $project $relative) -Text (Get-HistoricalFile -Specification $set.Files[$relative]) }
        $migrationRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $project)
        Assert-True ($migrationRun.Code -eq 0) "Exact $($set.Name) native set migrates"
        foreach ($relative in $set.Files.Keys) {
            $target = Join-Path $project $relative
            $migratedNativeText = [System.IO.File]::ReadAllText($target)
            Assert-True ($migratedNativeText.Contains("GEURTS-MANAGED-BEGIN") -and $migratedNativeText.Contains('version="1.0.0"') -and [regex]::Matches($migratedNativeText, [regex]::Escape($expectedBrickRouteText)).Count -eq 1 -and -not $migratedNativeText.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md")) "$($set.Name) $relative migrates to the exact managed v1.0.0 brick-first route through copied AGENTS.md"
            Assert-True (Test-Path -LiteralPath ($target + ".pre-v0.9.0.bak") -PathType Leaf) "$($set.Name) $relative receives a pre-v0.9.0 backup"
        }
    }

    $crlfLegacyProject = New-TestProject -Parent $testRoot -Name "legacy-crlf-migration"
    $crlfLegacyPath = Join-Path $crlfLegacyProject "AGENTS.md"
    $crlfLegacySource = Get-HistoricalFile -Specification "544922c:Tools/AIAgentInstructionTemplates/AGENTS.md"
    $crlfLegacyText = ((($crlfLegacySource -replace "`r`n", "`n") -replace "`r", "`n").Replace("`n", "`r`n"))
    Write-Utf8 -Path $crlfLegacyPath -Text $crlfLegacyText
    $crlfLegacyHash = Get-FileSha -Path $crlfLegacyPath
    $crlfLegacyRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $crlfLegacyProject)
    $crlfMigratedText = [System.IO.File]::ReadAllText($crlfLegacyPath)
    Assert-True ($crlfLegacyRun.Code -eq 0 -and $crlfMigratedText.Contains('version="1.0.0"') -and [regex]::Matches($crlfMigratedText, [regex]::Escape($expectedBrickRouteText)).Count -eq 1 -and (Test-CrLfOnly -Text $crlfMigratedText) -and (Get-FileSha -Path ($crlfLegacyPath + ".pre-v0.9.0.bak")) -eq $crlfLegacyHash) "Exact CRLF legacy template migration installs the v1.0.0 brick-first route while preserving its whole-file newline convention and byte-identical legacy backup"

    $modifiedLegacy = New-TestProject -Parent $testRoot -Name "modified-legacy"
    $modifiedLegacyPath = Join-Path $modifiedLegacy "AGENTS.md"
    Write-Utf8 -Path $modifiedLegacyPath -Text ((Get-HistoricalFile -Specification "544922c:Tools/AIAgentInstructionTemplates/AGENTS.md") + "`nUser modification.`n")
    $modifiedLegacyHash = Get-FileSha -Path $modifiedLegacyPath
    $modifiedLegacyRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $modifiedLegacy)
    Assert-True ($modifiedLegacyRun.Code -eq 2 -and (Get-FileSha -Path $modifiedLegacyPath) -eq $modifiedLegacyHash -and $modifiedLegacyRun.Output.Contains("user-modified legacy")) "Modified legacy native entry is preserved and reported as conflicted"

    # GDD managed-region writes preserve supported encodings and exact bytes outside the region.
    $gddEncodingCases = @(
        @{ Name = "gdd-utf8-bom"; Label = "UTF-8 BOM"; Encoding = (New-Object System.Text.UTF8Encoding($true, $true)); PreambleLength = 3 },
        @{ Name = "gdd-utf16le"; Label = "UTF-16LE"; Encoding = (New-Object System.Text.UnicodeEncoding($false, $true, $true)); PreambleLength = 2 },
        @{ Name = "gdd-utf16be"; Label = "UTF-16BE"; Encoding = (New-Object System.Text.UnicodeEncoding($true, $true, $true)); PreambleLength = 2 }
    )
    $gddManagedPattern = '(?ms)<!-- GEURTS-GDD-MANIFEST-BEGIN version="0\.7\.0" -->\r?\n.*?<!-- GEURTS-GDD-MANIFEST-END -->'
    foreach ($encodingCase in $gddEncodingCases) {
        $encodingProject = New-TestProject -Parent $testRoot -Name $encodingCase.Name
        $encodingSetup = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $encodingProject, "-IncludeGameDesignScaffolding")
        if ($encodingSetup.Code -ne 0) { throw "Unable to prepare $($encodingCase.Label) GDD encoding fixture." }
        $encodingManifestPath = Join-Path $encodingProject "Docs/GameDesign/GameDesignManifest.md"
        $encodingDesignPath = Join-Path $encodingProject "Docs/GameDesign/Encoding.md"
        Write-Utf8 -Path $encodingDesignPath -Text "geurtsId: encoding-case`npurpose: Encoding regression input`n# Encoding`n"
        $encodingBaseText = [System.IO.File]::ReadAllText($encodingManifestPath)
        $encodingBaseRegion = [regex]::Match($encodingBaseText, $gddManagedPattern)
        if (-not $encodingBaseRegion.Success) { throw "Unable to locate GDD managed region for $($encodingCase.Label)." }
        $encodingPrefixText = $encodingBaseText.Substring(0, $encodingBaseRegion.Index).Replace("`n", "`r`n") + "<!-- exact user prefix -->`n"
        $encodingRegionText = ((($encodingBaseRegion.Value -replace "`r`n", "`n") -replace "`r", "`n").Replace("`n", "`r`n"))
        $encodingSuffixText = "`r`n<!-- exact user suffix -->`n" + $encodingBaseText.Substring($encodingBaseRegion.Index + $encodingBaseRegion.Length)
        [System.IO.File]::WriteAllText($encodingManifestPath, ($encodingPrefixText + $encodingRegionText + $encodingSuffixText), $encodingCase.Encoding)
        $encodingRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $encodingProject)
        $encodingAfterBytes = [System.IO.File]::ReadAllBytes($encodingManifestPath)
        $encodingExpectedPrefix = [byte[]](@($encodingCase.Encoding.GetPreamble()) + @($encodingCase.Encoding.GetBytes($encodingPrefixText)))
        $encodingExpectedSuffix = [byte[]]($encodingCase.Encoding.GetBytes($encodingSuffixText))
        $encodingAfterText = $encodingCase.Encoding.GetString($encodingAfterBytes, [int]$encodingCase.PreambleLength, $encodingAfterBytes.Length - [int]$encodingCase.PreambleLength)
        $encodingAfterRegion = [regex]::Match($encodingAfterText, $gddManagedPattern)
        Assert-True ($encodingRun.Code -eq 0 -and $encodingRun.Output.Contains("Updated: Docs/GameDesign/GameDesignManifest.md") -and (Test-BytePrefix -Bytes $encodingAfterBytes -Expected $encodingExpectedPrefix) -and (Test-ByteSuffix -Bytes $encodingAfterBytes -Expected $encodingExpectedSuffix) -and $encodingAfterRegion.Success -and (Test-CrLfOnly -Text $encodingAfterRegion.Value)) "GDD $($encodingCase.Label) update preserves exact outside-region bytes, BOM/encoding, mixed outer newlines, and CRLF region convention"
    }

    foreach ($invalidEncodingCase in @(
        @{ Name = "gdd-invalid-utf8"; Label = "invalid BOM-less UTF-8"; Bytes = [byte[]](0x23, 0x20, 0xC3, 0x28, 0x0A); Pattern = '(?i)invalid text encoding' },
        @{ Name = "gdd-utf32"; Label = "UTF-32"; Bytes = [byte[]](0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00); Pattern = '(?i)unsupported UTF-32' }
    )) {
        $invalidEncodingProject = New-TestProject -Parent $testRoot -Name $invalidEncodingCase.Name
        $invalidDesignRoot = Join-Path $invalidEncodingProject "Docs/GameDesign"
        New-Item -ItemType Directory -Path $invalidDesignRoot -Force | Out-Null
        $invalidEncodingManifest = Join-Path $invalidDesignRoot "GameDesignManifest.md"
        [System.IO.File]::WriteAllBytes($invalidEncodingManifest, $invalidEncodingCase.Bytes)
        $invalidEncodingBefore = Get-FileSha -Path $invalidEncodingManifest
        $invalidEncodingRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $invalidEncodingProject)
        Assert-True ($invalidEncodingRun.Code -eq 2 -and (Get-FileSha -Path $invalidEncodingManifest) -eq $invalidEncodingBefore -and $invalidEncodingRun.Output -match $invalidEncodingCase.Pattern) "GDD $($invalidEncodingCase.Label) conflicts without mutation or silent re-encoding"
    }

    $gddConcurrentProject = New-TestProject -Parent $testRoot -Name "gdd-concurrent-byte-drift"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $gddConcurrentProject, "-IncludeGameDesignScaffolding") | Out-Null
    Write-Utf8 -Path (Join-Path $gddConcurrentProject "Docs/GameDesign/Concurrent.md") -Text "geurtsId: gdd-concurrent`n# Concurrent`n"
    $gddConcurrentManifest = Join-Path $gddConcurrentProject "Docs/GameDesign/GameDesignManifest.md"
    $gddConcurrentText = [System.IO.File]::ReadAllText($gddConcurrentManifest)
    $gddConcurrentBomEncoding = New-Object System.Text.UTF8Encoding($true, $true)
    $gddConcurrentBarrier = Join-Path $testRoot "barrier-gdd-byte-drift"
    $gddConcurrentProcess = Start-TestScriptAtBarrier -Path $gddScript -Arguments @("-ProjectRoot", $gddConcurrentProject) -BarrierPath $gddConcurrentBarrier -TargetPath $gddConcurrentManifest
    Wait-TestScriptBarrier -Run $gddConcurrentProcess
    [System.IO.File]::WriteAllText($gddConcurrentManifest, $gddConcurrentText, $gddConcurrentBomEncoding)
    $gddConcurrentHash = Get-FileSha -Path $gddConcurrentManifest
    $gddConcurrentRun = Complete-TestScriptBarrier -Run $gddConcurrentProcess
    $gddConcurrentBytes = [System.IO.File]::ReadAllBytes($gddConcurrentManifest)
    Assert-True ($gddConcurrentRun.Code -eq 2 -and (Get-FileSha -Path $gddConcurrentManifest) -eq $gddConcurrentHash -and $gddConcurrentBytes.Length -ge 3 -and $gddConcurrentBytes[0] -eq 0xEF -and $gddConcurrentBytes[1] -eq 0xBB -and $gddConcurrentBytes[2] -eq 0xBF -and $gddConcurrentRun.Output -match '(?i)manifest bytes changed.*concurrent edit was preserved') "GDD raw-byte guard detects an encoding-only concurrent edit and preserves it"

    $gddParentSwapProject = New-TestProject -Parent $testRoot -Name "gdd-parent-reparse-swap"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $gddParentSwapProject, "-IncludeGameDesignScaffolding") | Out-Null
    Write-Utf8 -Path (Join-Path $gddParentSwapProject "Docs/GameDesign/Swap.md") -Text "geurtsId: gdd-parent-swap`n# Swap`n"
    $gddParentSwapTarget = Join-Path $gddParentSwapProject "Docs/GameDesign/GameDesignManifest.md"
    $gddParentSwapBarrier = Join-Path $testRoot "barrier-gdd-parent-swap"
    $gddParentSwapProcess = Start-TestScriptAtBarrier -Path $gddScript -Arguments @("-ProjectRoot", $gddParentSwapProject) -BarrierPath $gddParentSwapBarrier -TargetPath $gddParentSwapTarget
    $gddParentSwapDirectory = Join-Path $gddParentSwapProject "Docs/GameDesign"
    $gddParentSwapSaved = Join-Path $gddParentSwapProject "Docs/GameDesign-before-swap"
    $gddParentSwapOutside = Join-Path $testRoot "gdd-parent-swap-outside"
    $gddParentSwapSentinel = Join-Path $gddParentSwapOutside "user-sentinel.txt"
    $gddParentSwapRun = $null
    try {
        Wait-TestScriptBarrier -Run $gddParentSwapProcess
        New-Item -ItemType Directory -Path $gddParentSwapOutside | Out-Null
        Write-Utf8 -Path $gddParentSwapSentinel -Text "Outside GDD content must remain untouched.`n"
        $gddParentSwapSentinelHash = Get-FileSha -Path $gddParentSwapSentinel
        Move-Item -LiteralPath $gddParentSwapDirectory -Destination $gddParentSwapSaved
        New-Item -ItemType Junction -Path $gddParentSwapDirectory -Target $gddParentSwapOutside | Out-Null
        $gddParentSwapRun = Complete-TestScriptBarrier -Run $gddParentSwapProcess
        $gddParentSwapProcess = $null
    }
    finally {
        Stop-TestScriptBarrier -Run $gddParentSwapProcess
        Restore-TestDirectorySwap -Path $gddParentSwapDirectory -ExpectedTarget $gddParentSwapOutside -SavedPath $gddParentSwapSaved
    }
    $gddParentSwapDebris = @(
        @(Get-ChildItem -LiteralPath $gddParentSwapProject -Filter ".ggf-*" -Force -File -ErrorAction SilentlyContinue)
        @(Get-ChildItem -LiteralPath $gddParentSwapDirectory -Filter ".ggf-*" -Force -File -ErrorAction SilentlyContinue)
    )
    Assert-True ($gddParentSwapRun -and $gddParentSwapRun.Code -eq 2 -and $gddParentSwapRun.Output -match '(?i)reparse point immediately before promotion' -and (Get-FileSha -Path $gddParentSwapSentinel) -eq $gddParentSwapSentinelHash -and -not (Test-Path -LiteralPath (Join-Path $gddParentSwapOutside "GameDesignManifest.md")) -and $gddParentSwapDebris.Count -eq 0) "GDD final guard rejects a GameDesign parent junction without external writes or root/design transaction debris"

    # Deterministic GDD add, metadata preservation, move detection, removal, and duplicate safety.
    $gddProject = New-TestProject -Parent $testRoot -Name "gdd"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $gddProject, "-IncludeGameDesignScaffolding") | Out-Null
    $designDoc = Join-Path $gddProject "Docs/GameDesign/Core.md"
    Write-Utf8 -Path $designDoc -Text "---`ngeurtsId: core-design`npurpose: Defines approved core play.`nstatus: Active`nversion: 1.0.0`nauthority: Primary`ntags: gameplay, core`n---`n# Core`n"
    $gddAdd = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    $gddManifestPath = Join-Path $gddProject "Docs/GameDesign/GameDesignManifest.md"
    $gddText = [System.IO.File]::ReadAllText($gddManifestPath)
    Assert-True ($gddAdd.Code -eq 0 -and $gddAdd.Output.Contains("Added: Docs/GameDesign/Core.md") -and $gddText.Contains("core-design") -and $gddText.Contains("Defines approved core play.")) "GDD document metadata is added without filename inference"
    $gddUnchanged = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    Assert-True ($gddUnchanged.Code -eq 0 -and $gddUnchanged.Output.Contains("Unchanged: Docs/GameDesign/Core.md")) "GDD rerun reports unchanged documents deterministically"
    $renamedDoc = Join-Path $gddProject "Docs/GameDesign/CoreRenamed.md"
    Move-Item -LiteralPath $designDoc -Destination $renamedDoc
    $gddRename = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    Assert-True ($gddRename.Code -eq 0 -and $gddRename.Output.Contains("Renamed: Docs/GameDesign/CoreRenamed.md")) "GDD same-directory rename is reported distinctly"
    $movedDoc = Join-Path $gddProject "Docs/GameDesign/Systems/CoreRenamed.md"
    New-Item -ItemType Directory -Path (Split-Path -Parent $movedDoc) | Out-Null
    Move-Item -LiteralPath $renamedDoc -Destination $movedDoc
    $gddMove = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    $gddMovedText = [System.IO.File]::ReadAllText($gddManifestPath)
    Assert-True ($gddMove.Code -eq 0 -and $gddMove.Output.Contains("Moved: Docs/GameDesign/Systems/CoreRenamed.md") -and $gddMovedText.Contains("Docs/GameDesign/Systems/CoreRenamed.md") -and $gddMovedText.Contains("core-design")) "GDD move preserves stable ID and metadata"
    Remove-Item -LiteralPath $movedDoc -Force
    $gddRemove = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    Assert-True ($gddRemove.Code -eq 0 -and -not [System.IO.File]::ReadAllText($gddManifestPath).Contains("core-design")) "Removed GDD record is deleted after same-run rename matching"

    $importedDoc = Join-Path $gddProject "Docs/GameDesign/Imported.md"
    Write-Utf8 -Path $importedDoc -Text "# Imported design notes`n"
    $gddImport = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject, "-ImportedPath", "Docs/GameDesign/Imported.md")
    Assert-True ($gddImport.Code -eq 0 -and $gddImport.Output.Contains("Imported: Docs/GameDesign/Imported.md")) "Explicit importer signal produces a distinct imported event"
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/.hidden.md") -Text "# Hidden`n"
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/.private/Hidden.md") -Text "# Hidden below hidden directory`n"
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/Unsupported.txt") -Text "Unsupported design payload`n"
    $gddFiltered = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    $gddFilteredText = [System.IO.File]::ReadAllText($gddManifestPath)
    Assert-True ($gddFiltered.Code -eq 0 -and $gddFiltered.Output.Contains("Unsupported: Docs/GameDesign/Unsupported.txt") -and -not $gddFilteredText.Contains(".hidden.md") -and -not $gddFilteredText.Contains(".private/Hidden.md") -and -not $gddFilteredText.Contains("Unsupported.txt")) "Hidden and unsupported files are excluded with explicit reporting"
    $wrongPathManifest = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject, "-ManifestPath", "Docs/Other/GameDesignManifest.md")
    Assert-True ($wrongPathManifest.Code -eq 2 -and $wrongPathManifest.Output.Contains("Conflicted:") -and $wrongPathManifest.Output.Contains("required project path")) "GDD maintainer refuses a manifest outside the required project path"
    $malformedGddProject = New-TestProject -Parent $testRoot -Name "gdd-malformed"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $malformedGddProject, "-IncludeGameDesignScaffolding") | Out-Null
    $malformedGddManifest = Join-Path $malformedGddProject "Docs/GameDesign/GameDesignManifest.md"
    $malformedGddText = [System.IO.File]::ReadAllText($malformedGddManifest).Replace('<!-- GEURTS-GDD-MANIFEST-END -->', "| malformed | row |`n<!-- GEURTS-GDD-MANIFEST-END -->")
    Write-Utf8 -Path $malformedGddManifest -Text $malformedGddText
    $malformedGddHash = Get-FileSha -Path $malformedGddManifest
    $malformedGddRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $malformedGddProject)
    Assert-True ($malformedGddRun.Code -eq 2 -and (Get-FileSha -Path $malformedGddManifest) -eq $malformedGddHash) "Malformed managed GDD records conflict without discarding user routing metadata"
    $futureGddProject = New-TestProject -Parent $testRoot -Name "gdd-future"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $futureGddProject, "-IncludeGameDesignScaffolding") | Out-Null
    $futureGddManifest = Join-Path $futureGddProject "Docs/GameDesign/GameDesignManifest.md"
    Write-Utf8 -Path $futureGddManifest -Text ([System.IO.File]::ReadAllText($futureGddManifest).Replace('GEURTS-GDD-MANIFEST-BEGIN version="0.7.0"', 'GEURTS-GDD-MANIFEST-BEGIN version="9.0.0"'))
    $futureGddHash = Get-FileSha -Path $futureGddManifest
    $futureGddRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $futureGddProject)
    Assert-True ($futureGddRun.Code -eq 2 -and (Get-FileSha -Path $futureGddManifest) -eq $futureGddHash -and $futureGddRun.Output.Contains("no downgrade")) "Future GDD manifest region is never downgraded"
    $invalidMetadataProject = New-TestProject -Parent $testRoot -Name "gdd-invalid-metadata"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $invalidMetadataProject, "-IncludeGameDesignScaffolding") | Out-Null
    Write-Utf8 -Path (Join-Path $invalidMetadataProject "Docs/GameDesign/BadVersion.md") -Text "geurtsId: bad-version`nversion: definitely-not-semver`n# Invalid version`n"
    $invalidMetadataManifest = Join-Path $invalidMetadataProject "Docs/GameDesign/GameDesignManifest.md"
    $invalidMetadataHash = Get-FileSha -Path $invalidMetadataManifest
    $invalidMetadataRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $invalidMetadataProject)
    Assert-True ($invalidMetadataRun.Code -eq 2 -and (Get-FileSha -Path $invalidMetadataManifest) -eq $invalidMetadataHash) "Invalid explicit GDD metadata is rejected before rendering"
    $lockedGddProject = New-TestProject -Parent $testRoot -Name "gdd-locked"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $lockedGddProject, "-IncludeGameDesignScaffolding") | Out-Null
    $ownedLockPath = Join-Path $lockedGddProject ".ggf-manifest.lock"
    $ownedLock = New-Object System.IO.FileStream($ownedLockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try {
        $lockedGddRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $lockedGddProject)
        Assert-True ($lockedGddRun.Code -eq 2 -and (Test-Path -LiteralPath $ownedLockPath -PathType Leaf)) "Failed GDD lock acquisition does not delete another operation's lock"
    }
    finally {
        $ownedLock.Dispose()
        Remove-Item -LiteralPath $ownedLockPath -Force -ErrorAction SilentlyContinue
    }
    $unlockedSentinelProject = New-TestProject -Parent $testRoot -Name "gdd-unlocked-lock-sentinel"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $unlockedSentinelProject, "-IncludeGameDesignScaffolding") | Out-Null
    $unlockedSentinelPath = Join-Path $unlockedSentinelProject ".ggf-manifest.lock"
    [System.IO.File]::WriteAllBytes($unlockedSentinelPath, [byte[]](0x00, 0xFF, 0x10, 0x42, 0x0D, 0x0A))
    $unlockedSentinelHash = Get-FileSha -Path $unlockedSentinelPath
    $unlockedSentinelRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $unlockedSentinelProject)
    $unlockedSentinelDebris = @(Get-ChildItem -LiteralPath $unlockedSentinelProject -Filter ".ggf-*" -Force -File | Where-Object { $_.FullName -cne $unlockedSentinelPath })
    Assert-True ($unlockedSentinelRun.Code -eq 2 -and $unlockedSentinelRun.Output -match '(?i)lock path already exists or could not be acquired.*preserved' -and (Get-FileSha -Path $unlockedSentinelPath) -eq $unlockedSentinelHash -and $unlockedSentinelDebris.Count -eq 0) "Pre-existing unlocked GDD lock sentinel conflicts, remains byte-identical, and leaves no tool-owned debris"
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/One.md") -Text "geurtsId: duplicate-id`n# One`n"
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/Two.md") -Text "geurtsId: duplicate-id`n# Two`n"
    $beforeDuplicate = Get-FileSha -Path $gddManifestPath
    $duplicateRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    Assert-True ($duplicateRun.Code -eq 2 -and $duplicateRun.Output.Contains("Conflicted:") -and (Get-FileSha -Path $gddManifestPath) -eq $beforeDuplicate) "Duplicate GDD identifiers report conflict and preserve the last valid manifest"

    # Definition consumption, profile selection, idempotence, and path collision safety.
    # The production contract fixes the full profile at 67 entries. Use the source definition
    # for behavior tests.
    $definitionPath = Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
    $folderTechniqueContractText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureTechnique.md"))
    $folderDefinitionContract = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json
    $folderToolContractText = [System.IO.File]::ReadAllText($folderScript)
    $managerToolContractText = [System.IO.File]::ReadAllText($manageScript)
    Assert-True ($folderTechniqueContractText -match '(?im)^\*\*Version:\*\*\s*0\.10\.0\s*$' -and [string]$folderDefinitionContract.definitionVersion -ceq "0.10.0" -and [string]$folderDefinitionContract.packageVersion -ceq "0.11.4" -and $folderToolContractText.Contains('[string]$definition.definitionVersion -ne "0.10.0"') -and $managerToolContractText.Contains('[string]$definition.definitionVersion -ne "0.10.0"')) "Folder technique, definition, creator, and native manager agree on definition v0.10.0 in package v0.11.4"

    $versionMismatchAuthority = Join-Path $testRoot "folder-version-mismatch-authority"
    New-Item -ItemType Directory -Path $versionMismatchAuthority | Out-Null
    $versionMismatchDefinitionPath = Join-Path $versionMismatchAuthority "GeurtsFolderStructureDefinition.json"
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureTechnique.md") -Destination (Join-Path $versionMismatchAuthority "GeurtsFolderStructureTechnique.md")
    $versionMismatchDefinition = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json
    $versionMismatchDefinition.definitionVersion = "0.8.0"
    Write-Utf8 -Path $versionMismatchDefinitionPath -Text ($versionMismatchDefinition | ConvertTo-Json -Depth 12)
    $versionMismatchProject = New-TestProject -Parent $testRoot -Name "folder-version-mismatch-project"
    $versionMismatchRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $versionMismatchProject, "-DefinitionPath", $versionMismatchDefinitionPath)
    Assert-True ($versionMismatchRun.Code -ne 0 -and $versionMismatchRun.Output.Contains("Folder definition version must be 0.10.0") -and -not (Test-Path -LiteralPath (Join-Path $versionMismatchProject "Assets/_Project"))) "Folder creator rejects a v0.8.0 definition before project mutation"

    $earlyExitProject = New-TestProject -Parent $testRoot -Name "barrier-early-exit-project"
    $earlyExitBarrierPath = Join-Path $testRoot "barrier-expected-early-exit"
    $earlyExitRun = Start-TestScriptAtBarrier -Path $folderScript -Arguments @("-ProjectRoot", $earlyExitProject, "-DefinitionPath", $versionMismatchDefinitionPath) -BarrierPath $earlyExitBarrierPath -TargetPath (Join-Path $earlyExitProject "Assets/_Project")
    $earlyExitMessage = $null
    try { Wait-TestScriptBarrier -Run $earlyExitRun }
    catch { $earlyExitMessage = $_.Exception.Message }
    finally { Stop-TestScriptBarrier -Run $earlyExitRun }
    Assert-True ($earlyExitMessage -match '(?i)exited before its write boundary.*Folder definition version must be 0\.10\.0' -and $earlyExitMessage -notmatch '(?i)No process is associated|disposed') "Barrier harness preserves the primary early-exit error without double wait or dispose"

    $folderProject = New-TestProject -Parent $testRoot -Name "folders"
    $folderRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $folderProject, "-DefinitionPath", $definitionPath)
    Assert-True ($folderRun.Code -eq 0 -and $folderRun.Output.Contains("Skipped: .github") -and $folderRun.Output.Contains("definition 0.10.0") -and (Test-Path -LiteralPath (Join-Path $folderProject "Assets/_Project") -PathType Container) -and -not (Test-Path -LiteralPath (Join-Path $folderProject "GeurtsGameForgeDocumentation"))) "Folder tool consumes the exact definition while never creating the reserved documentation container"
    $folderAgain = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $folderProject, "-DefinitionPath", $definitionPath)
    Assert-True ($folderAgain.Code -eq 0 -and $folderAgain.Output.Contains("Exists")) "Folder creation is idempotent"

    $rawCandidateProject = New-TestProject -Parent $testRoot -Name "unselected-project-root-folder-definition"
    $rawCandidateDirectory = Join-Path $rawCandidateProject "GeurtsTechniques"
    New-Item -ItemType Directory -Path $rawCandidateDirectory | Out-Null
    $rawCandidatePath = Join-Path $rawCandidateDirectory "GeurtsFolderStructureDefinition.json"
    $rawCandidate = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json
    @($rawCandidate.managedFolders | Where-Object { [string]$_.path -ceq "Builds" })[0].path = "MaliciousRawCandidate"
    Write-Utf8 -Path $rawCandidatePath -Text ($rawCandidate | ConvertTo-Json -Depth 12)
    $rawCandidateRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $rawCandidateProject)
    Assert-True ($rawCandidateRun.Code -eq 0 -and (Test-Path -LiteralPath (Join-Path $rawCandidateProject "Assets/_Project") -PathType Container) -and -not (Test-Path -LiteralPath (Join-Path $rawCandidateProject "MaliciousRawCandidate"))) "Folder tool never consumes an unselected raw project-root definition; only package resolution or explicit -DefinitionPath can select one"

    $folderDirectorySwapProject = New-TestProject -Parent $testRoot -Name "folder-directory-parent-swap"
    $folderDirectorySwapTarget = Join-Path $folderDirectorySwapProject "Assets/_Project"
    $folderDirectorySwapBarrier = Join-Path $testRoot "barrier-folder-directory-swap"
    $folderDirectorySwapProcess = Start-TestScriptAtBarrier -Path $folderScript -Arguments @("-ProjectRoot", $folderDirectorySwapProject, "-DefinitionPath", $definitionPath) -BarrierPath $folderDirectorySwapBarrier -TargetPath $folderDirectorySwapTarget
    $folderDirectorySwapAssets = Join-Path $folderDirectorySwapProject "Assets"
    $folderDirectorySwapSaved = Join-Path $folderDirectorySwapProject "Assets-before-swap"
    $folderDirectorySwapOutside = Join-Path $testRoot "folder-directory-swap-outside"
    $folderDirectorySwapSentinel = Join-Path $folderDirectorySwapOutside "user-sentinel.txt"
    $folderDirectorySwapRun = $null
    try {
        Wait-TestScriptBarrier -Run $folderDirectorySwapProcess
        New-Item -ItemType Directory -Path $folderDirectorySwapOutside | Out-Null
        Write-Utf8 -Path $folderDirectorySwapSentinel -Text "Outside folder content must remain untouched.`n"
        $folderDirectorySwapSentinelHash = Get-FileSha -Path $folderDirectorySwapSentinel
        Move-Item -LiteralPath $folderDirectorySwapAssets -Destination $folderDirectorySwapSaved
        New-Item -ItemType Junction -Path $folderDirectorySwapAssets -Target $folderDirectorySwapOutside | Out-Null
        $folderDirectorySwapRun = Complete-TestScriptBarrier -Run $folderDirectorySwapProcess
        $folderDirectorySwapProcess = $null
    }
    finally {
        Stop-TestScriptBarrier -Run $folderDirectorySwapProcess
        Restore-TestDirectorySwap -Path $folderDirectorySwapAssets -ExpectedTarget $folderDirectorySwapOutside -SavedPath $folderDirectorySwapSaved
    }
    Assert-True ($folderDirectorySwapRun -and $folderDirectorySwapRun.Code -ne 0 -and $folderDirectorySwapRun.Output -match '(?i)reparse point or changed path.*Assets/_Project' -and (Get-FileSha -Path $folderDirectorySwapSentinel) -eq $folderDirectorySwapSentinelHash -and -not (Test-Path -LiteralPath (Join-Path $folderDirectorySwapOutside "_Project"))) "Folder tool rejects a parent junction introduced at the final directory boundary without creating descendants outside the project"
    $wrongOwnerRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $folderProject, "-DefinitionPath", $definitionPath, "-Profile", "native-entry")
    Assert-True ($wrongOwnerRun.Code -ne 0 -and $wrongOwnerRun.Output.Contains("Invalid: native-entry") -and $wrongOwnerRun.Output.Contains("owned by 'native-entry-manager'")) "Folder tool cannot execute a profile owned by another automation"
    $tamperedAuthority = New-TestProject -Parent $testRoot -Name "tampered-folder-authority"
    Copy-Item -LiteralPath $definitionPath -Destination (Join-Path $tamperedAuthority "GeurtsFolderStructureDefinition.json")
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureTechnique.md") -Destination (Join-Path $tamperedAuthority "GeurtsFolderStructureTechnique.md")
    $tamperedDefinitionPath = Join-Path $tamperedAuthority "GeurtsFolderStructureDefinition.json"
    $tamperedDefinition = Get-Content -LiteralPath $tamperedDefinitionPath -Raw | ConvertFrom-Json
    foreach ($folder in @($tamperedDefinition.managedFolders)) {
        if ($folder.path -in @("Builds", "Tools")) {
            $folder.automation.owner = "native-entry-manager"
            $folder.automation.creationProfiles = @("native-entry")
        }
        elseif ($folder.path -in @(".github", ".github/instructions")) {
            $folder.automation.owner = "folder-structure-tool"
            $folder.automation.creationProfiles = @("full-project-structure")
        }
    }
    Write-Utf8 -Path $tamperedDefinitionPath -Text ($tamperedDefinition | ConvertTo-Json -Depth 12)
    $tamperedProject = New-TestProject -Parent $testRoot -Name "tampered-folder-project"
    $tamperedRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $tamperedProject, "-DefinitionPath", $tamperedDefinitionPath)
    Assert-True ($tamperedRun.Code -ne 0 -and $tamperedRun.Output.Contains("Invalid: Builds") -and @((Get-ChildItem -LiteralPath $tamperedProject -Force).Name | Where-Object { $_ -notin @("Assets", "Packages", "ProjectSettings") }).Count -eq 0) "Folder tool rejects count-preserving profile-scope tampering before mutation"
    $reservedDefinitionPath = Join-Path $tamperedAuthority "ReservedFolderDefinition.json"
    $reservedDefinition = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json
    $reservedFixture = @($reservedDefinition.managedFolders | Where-Object { [string]$_.path -ceq "Builds" })[0]
    $reservedFixture.path = "GeurtsGameForgeDocumentation"
    $reservedFixture.parent = $null
    Write-Utf8 -Path $reservedDefinitionPath -Text ($reservedDefinition | ConvertTo-Json -Depth 12)
    $reservedProject = New-TestProject -Parent $testRoot -Name "reserved-folder-project"
    $reservedRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $reservedProject, "-DefinitionPath", $reservedDefinitionPath)
    Assert-True ($reservedRun.Code -ne 0 -and $reservedRun.Output -match '(?i)reserved placement outside folder-tool authority' -and -not (Test-Path -LiteralPath (Join-Path $reservedProject "GeurtsGameForgeDocumentation"))) "Folder tool rejects a count-preserving attempt to add the project-local documentation copy to the creation registry"
    $blockedProject = New-TestProject -Parent $testRoot -Name "folder-blocked"
    Write-Utf8 -Path (Join-Path $blockedProject "Assets/_Project") -Text "blocking file"
    $blockedRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $blockedProject, "-DefinitionPath", $definitionPath)
    Assert-True ($blockedRun.Code -ne 0 -and $blockedRun.Output.Contains("Conflicted: Assets/_Project") -and (Test-Path -LiteralPath (Join-Path $blockedProject "Assets/_Project") -PathType Leaf)) "Folder collision reports the exact path and fails without deleting user content"

    # Static validation covers manifest/version integrity, source ownership, notification-only startup,
    # separated UI versions, the manual overwrite boundary, generic safeguards, and payload fidelity.
    $staticValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $RepositoryRoot)
    Assert-True ($staticValidation.Code -eq 0) "Repository static validation covers all normative acceptance rules"
    $staticJsonValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $RepositoryRoot, "-OutputFormat", "Json")
    $staticJsonObject = $null
    try { $staticJsonObject = $staticJsonValidation.Output | ConvertFrom-Json }
    catch { }
    $requiredLifecycleChecks = @(
        "Unity 6.3 LTS target",
        "Unity C# example patterns",
        "Required technical dependencies and policies",
        "Frozen GFI v2 source and compatibility boundary",
        "Frozen GFI v2 startup and manual trigger",
        "Frozen GFI v2 separated versions",
        "Frozen GFI v2 destructive warning",
        "Frozen GFI v2 complete-tree replacement",
        "Frozen GFI v2 receipt lifecycle",
        "Frozen GFI v2 overwrite boundary",
        "Frozen GFI v2 discarded lifecycle exclusion",
        "Documentation companion closed contract",
        "Companion schema forward compatibility",
        "Documentation companion architecture boundary",
        "No Unity companion implementation in documentation source",
        "Companion metadata-only startup",
        "Companion confirmation and complete update",
        "Companion bounded project and script boundary",
        "Companion minimal lifecycle exclusions",
        "Companion AI-routing limitation"
    )
    $missingLifecycleChecks = @($requiredLifecycleChecks | Where-Object { $checkName = $_; @($staticJsonObject.checks | Where-Object { $_.name -ceq $checkName -and $_.passed }).Count -ne 1 })
    Assert-True ($staticJsonValidation.Code -eq 0 -and $staticJsonObject -and $staticJsonObject.status -eq "VALID" -and @($staticJsonObject.checks | Where-Object { -not $_.passed }).Count -eq 0 -and $missingLifecycleChecks.Count -eq 0) "Repository validation JSON output is parseable and contains every passing companion and frozen-GFI boundary check"

    # Mutated package fixtures must fail without changing the source checkout or any Unity project.
    $unityTargetFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-unity-target"
    $unityTargetReadme = Join-Path $unityTargetFixture "README.md"
    Write-Utf8 -Path $unityTargetReadme -Text ([System.IO.File]::ReadAllText($unityTargetReadme).Replace('**Unity target:** Unity 6.3 LTS (6000.3)', '**Unity target:** Unity 6.0 LTS (6000.0)'))
    $policyFixture = New-StaticValidationFixture -Parent $testRoot -Name "missing-version-policy"
    $policyPath = Join-Path $policyFixture "AI_READ_FIRST.md"
    Write-Utf8 -Path $policyPath -Text ([System.IO.File]::ReadAllText($policyPath).Replace("Never publish changed content under the same version", "Version changes are optional"))
    $policyRun = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $policyFixture)
    Assert-True ($policyRun.Code -ne 0 -and $policyRun.Output.Contains("Mandatory reading and version policy")) "Validator rejects removal of the mandatory version-bump rule"

    $unityTargetRun = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $unityTargetFixture)
    Assert-True ($unityTargetRun.Code -ne 0 -and $unityTargetRun.Output.Contains("[FAIL] Unity 6.3 LTS target")) "Static validation rejects a conflicting Unity target in a package entry surface"

    $unityBaselineFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-unity-baseline-missing"
    $unityBaselineTechnique = Join-Path $unityBaselineFixture "GeurtsTechniques/GeurtsTechnicalTechnique.md"
    $withoutBaseline = [regex]::Replace([System.IO.File]::ReadAllText($unityBaselineTechnique), '(?ms)^## Unity 6\.3 LTS Compatibility Baseline\s*.*?(?=^## )', '')
    Write-Utf8 -Path $unityBaselineTechnique -Text $withoutBaseline
    $unityBaselineRun = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $unityBaselineFixture)
    Assert-True ($unityBaselineRun.Code -ne 0 -and $unityBaselineRun.Output.Contains("[FAIL] Unity 6.3 LTS target")) "Static validation rejects target metadata without the technical compatibility baseline"

    $invalidUnityExamples = @(
        @{ Name = "obsolete-find"; Code = 'var items = UnityEngine.Object.FindObjectsOfType<UnityEngine.Collider>();' },
        @{ Name = "legacy-input"; Code = 'float movement = UnityEngine.Input.GetAxis("Horizontal");' },
        @{ Name = "legacy-rpc"; Code = '[ServerRpc] public void PingServerRpc() { }' },
        @{ Name = "legacy-uxml"; Code = 'public class Factory : UxmlFactory<Example> { }' },
        @{ Name = "file-namespace"; Code = 'namespace Example;' },
        @{ Name = "global-using"; Code = 'global using UnityEngine;' },
        @{ Name = "record-struct"; Code = 'public record struct Example(int Value);' }
    )
    foreach ($exampleCase in $invalidUnityExamples) {
        $exampleFixture = New-StaticValidationFixture -Parent $testRoot -Name ("static-unity-example-" + $exampleCase.Name)
        $exampleTechnique = Join-Path $exampleFixture "GeurtsTechniques/GeurtsTechnicalTechnique.md"
        $invalidFence = [Environment]::NewLine + '```csharp' + [Environment]::NewLine + $exampleCase.Code + [Environment]::NewLine + '```' + [Environment]::NewLine
        Write-Utf8 -Path $exampleTechnique -Text ([System.IO.File]::ReadAllText($exampleTechnique) + $invalidFence)
        $exampleRun = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $exampleFixture)
        Assert-True ($exampleRun.Code -ne 0 -and $exampleRun.Output.Contains("[FAIL] Unity C# example patterns")) ("Static validation rejects unsupported current C# example: " + $exampleCase.Name)
    }

    $optionalOdinFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-optional-odin"
    $optionalOdinTechnique = Join-Path $optionalOdinFixture "GeurtsTechniques/GeurtsTechnicalTechnique.md"
    $optionalOdinText = [System.IO.File]::ReadAllText($optionalOdinTechnique).Replace('Odin Inspector is required within the implementation scope defined by the Unity 6.3 dependency baseline.', 'Odin Inspector is optional within the implementation scope defined by the Unity 6.3 dependency baseline.')
    Write-Utf8 -Path $optionalOdinTechnique -Text $optionalOdinText
    $optionalOdinRun = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $optionalOdinFixture)
    Assert-True ($optionalOdinRun.Code -ne 0 -and $optionalOdinRun.Output.Contains("[FAIL] Required technical dependencies and policies")) "Static validation rejects making Odin Inspector optional"

    $optionalQuantumFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-optional-quantum"
    $optionalQuantumTechnique = Join-Path $optionalQuantumFixture "GeurtsTechniques/GeurtsTechnicalTechnique.md"
    $optionalQuantumText = [System.IO.File]::ReadAllText($optionalQuantumTechnique).Replace('Quantum Console is the required runtime developer console', 'Quantum Console is an optional runtime developer console')
    Write-Utf8 -Path $optionalQuantumTechnique -Text $optionalQuantumText
    $optionalQuantumRun = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $optionalQuantumFixture)
    Assert-True ($optionalQuantumRun.Code -ne 0 -and $optionalQuantumRun.Output.Contains("[FAIL] Required technical dependencies and policies")) "Static validation rejects making Quantum Console optional"

    $brickRouteFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-native-brick-route"
    $brickRouteTemplatePath = Join-Path $brickRouteFixture "Tools/AIAgentInstructionTemplates/AGENTS.md"
    $weakenedBrickRoute = 'Read and follow `GeurtsGameForgeDocumentation/AGENTS.md`; it routes to the installed documentation.'
    Write-Utf8 -Path $brickRouteTemplatePath -Text ([System.IO.File]::ReadAllText($brickRouteTemplatePath).Replace($expectedBrickRouteText, $weakenedBrickRoute))
    $brickRouteValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $brickRouteFixture)
    Assert-True ($brickRouteValidation.Code -ne 0 -and $brickRouteValidation.Output.Contains("Managed native routes")) "Static validation rejects a route that drops the brick-before-planning and manifest-selected source-of-truth instruction"

    $templateHashFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-native-template-hash"
    $templateHashPath = Join-Path $templateHashFixture "Tools/AIAgentInstructionTemplates/AGENTS.md"
    Write-Utf8 -Path $templateHashPath -Text ([System.IO.File]::ReadAllText($templateHashPath).Replace('sha256="93464c8bace065ddfe2f305dfedafafbb8a1099cb318c21dad185d46d22451eb"', 'sha256="03464c8bace065ddfe2f305dfedafafbb8a1099cb318c21dad185d46d22451eb"'))
    $templateHashValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $templateHashFixture)
    Assert-True ($templateHashValidation.Code -ne 0 -and $templateHashValidation.Output.Contains("Managed template integrity")) "Static validation rejects drift from the exact approved v1.0.0 managed-region hashes"

    $extraRouteFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-extra-route"
    $extraRouteContractPath = Join-Path $extraRouteFixture "GeurtsTechniques/GeurtsDocumentationCompanionContract.json"
    $extraRouteContract = Get-Content -LiteralPath $extraRouteContractPath -Raw | ConvertFrom-Json
    $extraRouteContract.routeMappings += [pscustomobject]@{ template = "Tools/AIAgentInstructionTemplates/AGENTS.md"; target = ".cursor/rules/geurts.md" }
    Write-Utf8 -Path $extraRouteContractPath -Text ($extraRouteContract | ConvertTo-Json -Depth 10)
    $extraRouteValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $extraRouteFixture)
    Assert-True ($extraRouteValidation.Code -ne 0 -and $extraRouteValidation.Output.Contains("Documentation companion closed contract")) "Static validation rejects an added companion AI-route mapping"

    $docsRouteFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-docs-route"
    $docsRouteContractPath = Join-Path $docsRouteFixture "GeurtsTechniques/GeurtsDocumentationCompanionContract.json"
    $docsRouteContract = Get-Content -LiteralPath $docsRouteContractPath -Raw | ConvertFrom-Json
    $docsRouteContract.routeMappings[3].target = "Docs/GameDesign/geurts-game-design.instructions.md"
    $docsRouteContract.updateUi.confirmationTargets[4].path = "Docs/GameDesign/geurts-game-design.instructions.md"
    Write-Utf8 -Path $docsRouteContractPath -Text ($docsRouteContract | ConvertTo-Json -Depth 10)
    $docsRouteValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $docsRouteFixture)
    Assert-True ($docsRouteValidation.Code -ne 0 -and $docsRouteValidation.Output.Contains("Documentation companion closed contract")) "Static validation rejects a contract route or confirmation target under Docs/GameDesign"

    $forbiddenLifecycleFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-forbidden-lifecycle"
    $forbiddenLifecycleTechnique = Join-Path $forbiddenLifecycleFixture "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    Write-Utf8 -Path $forbiddenLifecycleTechnique -Text ([System.IO.File]::ReadAllText($forbiddenLifecycleTechnique) + "`nThe companion provides a preview, backup, rollback journal, and migration path for Update, then requires a second confirmation.`n")
    $forbiddenLifecycleValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $forbiddenLifecycleFixture)
    Assert-True ($forbiddenLifecycleValidation.Code -ne 0 -and $forbiddenLifecycleValidation.Output.Contains("Companion minimal lifecycle exclusions")) "Static validation rejects affirmative preview, backup, rollback, journal, migration, and second-confirmation behavior"

    $secondConfirmationFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-second-confirmation"
    $secondConfirmationTechnique = Join-Path $secondConfirmationFixture "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    Write-Utf8 -Path $secondConfirmationTechnique -Text ([System.IO.File]::ReadAllText($secondConfirmationTechnique) + "`nThe companion requires a second confirmation after archive validation.`n")
    $secondConfirmationValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $secondConfirmationFixture)
    Assert-True ($secondConfirmationValidation.Code -ne 0 -and $secondConfirmationValidation.Output.Contains("Companion minimal lifecycle exclusions")) "Static validation independently rejects a second Update confirmation"

    $startupMutationFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-startup-mutation"
    $startupMutationTechnique = Join-Path $startupMutationFixture "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    Write-Utf8 -Path $startupMutationTechnique -Text ([System.IO.File]::ReadAllText($startupMutationTechnique) + "`nAt Unity open, the companion automatically downloads and replaces documentation.`n")
    $startupMutationValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $startupMutationFixture)
    Assert-True ($startupMutationValidation.Code -ne 0 -and $startupMutationValidation.Output.Contains("Companion metadata-only startup")) "Static validation rejects automatic download or replacement during Unity open"

    $bootstrapFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-bootstrap"
    $bootstrapTechnique = Join-Path $bootstrapFixture "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    Write-Utf8 -Path $bootstrapTechnique -Text ([System.IO.File]::ReadAllText($bootstrapTechnique) + "`nThe companion uses an external batch bootstrap to execute .bat setup scripts.`n")
    $bootstrapValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $bootstrapFixture)
    Assert-True ($bootstrapValidation.Code -ne 0 -and $bootstrapValidation.Output.Contains("Companion minimal lifecycle exclusions")) "Static validation rejects an external batch/bootstrap setup claim"

    $expandedDownloadedContractFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-expanded-downloaded-contract"
    $expandedDownloadedContractTechnique = Join-Path $expandedDownloadedContractFixture "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    Write-Utf8 -Path $expandedDownloadedContractTechnique -Text ([System.IO.File]::ReadAllText($expandedDownloadedContractTechnique) + "`nThe downloaded contract may add a managed target after confirmation.`n")
    $expandedDownloadedContractValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $expandedDownloadedContractFixture)
    Assert-True ($expandedDownloadedContractValidation.Code -ne 0 -and $expandedDownloadedContractValidation.Output.Contains("Companion confirmation and complete update")) "Static validation rejects a downloaded contract that expands the pre-approved managed target set"

    $comparisonStateFailureFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-comparison-state-failure"
    $comparisonStateFailureTechnique = Join-Path $comparisonStateFailureFixture "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    Write-Utf8 -Path $comparisonStateFailureTechnique -Text ([System.IO.File]::ReadAllText($comparisonStateFailureTechnique) + "`nA comparison-state write failure reclassifies the content Update as failed and rolls back the replacement.`n")
    $comparisonStateFailureValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $comparisonStateFailureFixture)
    Assert-True ($comparisonStateFailureValidation.Code -ne 0 -and $comparisonStateFailureValidation.Output.Contains("Companion confirmation and complete update")) "Static validation rejects treating comparison-state persistence failure as failed or rolled-back managed content"

    $pluginCodeFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-companion-plugin-code"
    $pluginCodePath = Join-Path $pluginCodeFixture "Editor/DocumentationCompanion.cs"
    Write-Utf8 -Path $pluginCodePath -Text "internal static class DocumentationCompanionFixture { }`n"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $pluginCodeAddOutput = @(& git -C $pluginCodeFixture add -- "Editor/DocumentationCompanion.cs" 2>&1)
        $pluginCodeAddExitCode = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previousPreference }
    if ($pluginCodeAddExitCode -ne 0) { throw "Unable to stage plugin-code fixture: $($pluginCodeAddOutput -join ' ')" }
    $pluginCodeValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $pluginCodeFixture)
    Assert-True ($pluginCodeValidation.Code -ne 0 -and $pluginCodeValidation.Output.Contains("No Unity companion implementation in documentation source")) "Static validation rejects tracked C# companion implementation in the documentation repository"

    $legacyLifecycleFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-old-lifecycle"
    $legacyLifecycleTechnique = Join-Path $legacyLifecycleFixture "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    Write-Utf8 -Path $legacyLifecycleTechnique -Text ([System.IO.File]::ReadAllText($legacyLifecycleTechnique) + "`nGame Forge Intelligence performs exactly one routine remote documentation check per Unity project launch or open, then promotes the candidate atomically with combined rollback.`n")
    $legacyLifecycleValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $legacyLifecycleFixture)
    Assert-True ($legacyLifecycleValidation.Code -ne 0 -and $legacyLifecycleValidation.Output.Contains("Frozen GFI v2 discarded lifecycle exclusion")) "Static validation rejects reintroduced stateful launch-check, atomic-promotion, and rollback language in the frozen GFI v2 contract"

    $gddOverwriteFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-gdd-overwrite"
    $gddOverwriteTechnique = Join-Path $gddOverwriteFixture "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    Write-Utf8 -Path $gddOverwriteTechnique -Text ([System.IO.File]::ReadAllText($gddOverwriteTechnique) + "`nGame Forge Intelligence may also delete and replace <ProjectRoot>/Docs/GameDesign during documentation Update.`n")
    $gddOverwriteValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $gddOverwriteFixture)
    Assert-True ($gddOverwriteValidation.Code -ne 0 -and $gddOverwriteValidation.Output.Contains("Frozen GFI v2 overwrite boundary")) "Static validation rejects any permission for the frozen GFI v2 contract to replace project-authored Docs/GameDesign"

    $pluginEmbeddingFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-plugin-embedding"
    $pluginEmbeddingTechnique = Join-Path $pluginEmbeddingFixture "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    Write-Utf8 -Path $pluginEmbeddingTechnique -Text ([System.IO.File]::ReadAllText($pluginEmbeddingTechnique) + "`nThe plugin may embed Geurts documentation in <PluginPackageRoot>/Documentation~.`n")
    $pluginEmbeddingValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $pluginEmbeddingFixture)
    Assert-True ($pluginEmbeddingValidation.Code -ne 0 -and $pluginEmbeddingValidation.Output.Contains("Frozen GFI v2 source and compatibility boundary")) "Static validation rejects bundled Geurts documentation inside the frozen GFI plugin Documentation~ boundary"

    $versionConflationFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-version-conflation"
    $versionConflationTechnique = Join-Path $versionConflationFixture "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    Write-Utf8 -Path $versionConflationTechnique -Text ([System.IO.File]::ReadAllText($versionConflationTechnique) + "`nThe UI may display the compatibility schema as the GameForgeIntelligence Plugin version.`n")
    $versionConflationValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $versionConflationFixture)
    Assert-True ($versionConflationValidation.Code -ne 0 -and $versionConflationValidation.Output.Contains("Frozen GFI v2 separated versions")) "Static validation rejects conflation of frozen GFI v2 schema, technique, documentation, and plugin versions"

    $historicalReceiptFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-historical-receipt"
    $historicalReceiptTechnique = Join-Path $historicalReceiptFixture "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    Write-Utf8 -Path $historicalReceiptTechnique -Text ([System.IO.File]::ReadAllText($historicalReceiptTechnique) + "`nA historical receipt may continue to drive Installed Geurts Documentation and update comparison after deletion begins.`n")
    $historicalReceiptValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $historicalReceiptFixture)
    Assert-True ($historicalReceiptValidation.Code -ne 0 -and $historicalReceiptValidation.Output.Contains("Frozen GFI v2 receipt lifecycle")) "Static validation rejects historical-receipt fallback inside the frozen GFI v2 contract"

    $versionAvailabilityFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-package-version-availability"
    $versionAvailabilityTechnique = Join-Path $versionAvailabilityFixture "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    Write-Utf8 -Path $versionAvailabilityTechnique -Text ([System.IO.File]::ReadAllText($versionAvailabilityTechnique) + "`nPackage-version ordering determines whether an Update is available even when commit IDs match.`n")
    $versionAvailabilityValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $versionAvailabilityFixture)
    Assert-True ($versionAvailabilityValidation.Code -ne 0 -and $versionAvailabilityValidation.Output.Contains("Frozen GFI v2 receipt lifecycle")) "Static validation rejects package-version-based availability inside the frozen GFI v2 contract"

    $supportingSurfaceFixture = New-StaticValidationFixture -Parent $testRoot -Name "static-supporting-surface-contradictions"
    $supportingSurfaceReadme = Join-Path $supportingSurfaceFixture "README.md"
    $supportingSurfaceContradictions = @(
        "At Unity open, the companion automatically downloads and replaces documentation.",
        "The downloaded contract may add a managed target after confirmation.",
        "The companion uses an external batch bootstrap to execute .bat setup scripts."
    ) -join "`n"
    Write-Utf8 -Path $supportingSurfaceReadme -Text ([System.IO.File]::ReadAllText($supportingSurfaceReadme) + "`n" + $supportingSurfaceContradictions + "`n")
    $supportingSurfaceValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $supportingSurfaceFixture)
    Assert-True ($supportingSurfaceValidation.Code -ne 0 -and $supportingSurfaceValidation.Output.Contains("Companion metadata-only startup") -and $supportingSurfaceValidation.Output.Contains("Companion confirmation and complete update") -and $supportingSurfaceValidation.Output.Contains("Companion minimal lifecycle exclusions")) "Static validation rejects startup mutation, expanded approval, and bootstrap contradictions in current supporting surfaces"
}
catch {
    $script:Failed++
    $harnessLocation = if ($_.InvocationInfo.ScriptLineNumber) { " (line $($_.InvocationInfo.ScriptLineNumber))" } else { "" }
    $script:FailureMessages.Add("Test harness exception: $($_.Exception.Message)$harnessLocation") | Out-Null
    if ($OutputFormat -eq "Text") { Write-Host "TEST HARNESS ERROR: $($_.Exception.Message)$harnessLocation" -ForegroundColor Red }
}
finally {
    try {
        $fullTestRoot = [System.IO.Path]::GetFullPath($testRoot)
        if ($fullTestRoot.StartsWith($temporaryBase, [System.StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $fullTestRoot).StartsWith("ggf-automation-tests-", [System.StringComparison]::Ordinal)) {
            Remove-Item -LiteralPath $fullTestRoot -Recurse -Force -ErrorAction Stop
        }
        else { throw "Refused unsafe temporary cleanup path: $fullTestRoot" }
    }
    catch {
        $script:Failed++
        $script:FailureMessages.Add("Temporary cleanup failed: $($_.Exception.Message)") | Out-Null
    }
}

if ($OutputFormat -eq "Json") {
    [pscustomobject]@{
        status = $(if ($script:Failed -eq 0) { "PASSED" } else { "FAILED" })
        passed = $script:Passed
        failed = $script:Failed
        failures = $script:FailureMessages.ToArray()
    } | ConvertTo-Json -Depth 5
}
else {
    Write-Host "Automation test summary: passed=$script:Passed failed=$script:Failed"
    if ($script:FailureMessages.Count -gt 0) { $script:FailureMessages | ForEach-Object { Write-Host " - $_" -ForegroundColor Red } }
}
if ($script:Failed -gt 0) { exit 1 }
exit 0
