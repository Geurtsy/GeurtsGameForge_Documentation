# RunAutomationTests.ps1
# Version: 0.7.0

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

function Invoke-TestScript([string]$Path, [string[]]$Arguments) {
    $hostPath = (Get-Process -Id $PID).Path
    $hostArguments = @("-NoProfile")
    if ((Split-Path -Leaf $hostPath) -like "powershell*") { $hostArguments += @("-ExecutionPolicy", "Bypass") }
    $hostArguments += @("-File", $Path)
    $hostArguments += $Arguments
    $output = @(& $hostPath @hostArguments 2>&1)
    return [pscustomobject]@{ Code = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
}

function Invoke-TestGit([string[]]$Arguments, [string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        try {
            $output = @(& git @Arguments 2>&1)
            $gitExitCode = $LASTEXITCODE
        }
        finally { $ErrorActionPreference = $previousPreference }
        if ($gitExitCode -ne 0) { throw "Git '$($Arguments -join ' ')' failed: $($output -join [Environment]::NewLine)" }
        return ($output -join [Environment]::NewLine).Trim()
    }
    finally { Pop-Location }
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
    return $path
}

if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
$toolsRoot = Join-Path $RepositoryRoot "Tools"
$manageScript = Join-Path $toolsRoot "ManageGeurtsAgentInstructions.ps1"
$gddScript = Join-Path $toolsRoot "UpdateGameDesignManifest.ps1"
$folderScript = Join-Path $toolsRoot "CreateGeurtsFolderStructure.ps1"
$bootstrapScript = Join-Path $toolsRoot "BootstrapGeurtsInstructions.ps1"
$validatorScript = Join-Path $toolsRoot "ValidateGeurtsDocumentation.ps1"
$temporaryBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$testRoot = Join-Path $temporaryBase ("ggf-automation-tests-" + [Guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null

    # Native creation, GDD scaffolding, outside-marker preservation, and idempotence.
    $fresh = New-TestProject -Parent $testRoot -Name "fresh"
    $firstSetup = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-DocumentationMode", "Skip")
    Assert-True ($firstSetup.Code -eq 0) "Fresh setup succeeds without network access"
    Assert-True ($firstSetup.Output.Contains("Created: .github") -and $firstSetup.Output.Contains("Created: Docs/GameDesign")) "Fresh setup reports managed native-entry and GDD directories"
    foreach ($relative in @("AGENTS.md", ".github/copilot-instructions.md", ".github/instructions/geurts-unity.instructions.md", ".github/instructions/geurts-game-design.instructions.md", "Docs/GameDesign/README.md", "Docs/GameDesign/GameDesignManifest.md")) {
        Assert-True (Test-Path -LiteralPath (Join-Path $fresh $relative) -PathType Leaf) "Fresh setup creates $relative"
    }
    $trackedFiles = @("AGENTS.md", ".github/copilot-instructions.md", ".github/instructions/geurts-unity.instructions.md", ".github/instructions/geurts-game-design.instructions.md", "Docs/GameDesign/README.md", "Docs/GameDesign/GameDesignManifest.md")
    $before = @{}
    foreach ($relative in $trackedFiles) { $before[$relative] = Get-FileSha -Path (Join-Path $fresh $relative) }
    $secondSetup = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-DocumentationMode", "Skip")
    Assert-True ($secondSetup.Code -eq 0) "Second setup succeeds"
    foreach ($relative in $trackedFiles) { Assert-True ((Get-FileSha -Path (Join-Path $fresh $relative)) -eq $before[$relative]) "Second setup leaves $relative byte-identical" }
    $jsonSetupRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-DocumentationMode", "Skip", "-OutputFormat", "Json")
    $jsonSetupObject = $null
    try { $jsonSetupObject = $jsonSetupRun.Output | ConvertFrom-Json }
    catch { }
    Assert-True ($jsonSetupRun.Code -eq 0 -and $jsonSetupObject -and $jsonSetupObject.status -eq "OK" -and $jsonSetupObject.gameDesignManifest.status -eq "UNCHANGED") "Managed setup JSON output remains a single parseable document across child operations"

    $agentsPath = Join-Path $fresh "AGENTS.md"
    [System.IO.File]::AppendAllText($agentsPath, "`nUser-owned note outside the managed block.`n", $utf8NoBom)
    $outsideHash = Get-FileSha -Path $agentsPath
    $outsideRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $fresh, "-DocumentationMode", "Skip")
    Assert-True ($outsideRun.Code -eq 0 -and (Get-FileSha -Path $agentsPath) -eq $outsideHash) "Content outside managed markers is preserved"

    $userOwned = New-TestProject -Parent $testRoot -Name "user-owned"
    Write-Utf8 -Path (Join-Path $userOwned "AGENTS.md") -Text "# Personal project instructions`nKeep this content.`n"
    $userHash = Get-FileSha -Path (Join-Path $userOwned "AGENTS.md")
    $userRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $userOwned, "-DocumentationMode", "Skip")
    Assert-True ($userRun.Code -eq 0 -and (Get-FileSha -Path (Join-Path $userOwned "AGENTS.md")) -eq $userHash) "Unmarked user-owned native file is preserved"

    $blockedSetup = New-TestProject -Parent $testRoot -Name "blocked-setup-directory"
    Write-Utf8 -Path (Join-Path $blockedSetup ".github") -Text "user-owned blocking file`n"
    $blockedSetupHash = Get-FileSha -Path (Join-Path $blockedSetup ".github")
    $blockedSetupRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $blockedSetup, "-DocumentationMode", "Skip")
    Assert-True ($blockedSetupRun.Code -eq 1 -and (Get-FileSha -Path (Join-Path $blockedSetup ".github")) -eq $blockedSetupHash -and -not (Test-Path -LiteralPath (Join-Path $blockedSetup "AGENTS.md"))) "Managed setup preflights blocking directories before any file mutation"

    $malformed = New-TestProject -Parent $testRoot -Name "malformed"
    $malformedPath = Join-Path $malformed "AGENTS.md"
    Write-Utf8 -Path $malformedPath -Text '<!-- GEURTS-MANAGED-BEGIN id="broken" version="0.7.0" sha256="0000000000000000000000000000000000000000000000000000000000000000" -->'
    $malformedHash = Get-FileSha -Path $malformedPath
    $malformedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $malformed, "-DocumentationMode", "Skip")
    Assert-True ($malformedRun.Code -eq 2 -and (Get-FileSha -Path $malformedPath) -eq $malformedHash) "Malformed managed markers conflict without overwriting"

    $yamlOutside = New-TestProject -Parent $testRoot -Name "yaml-outside-frontmatter"
    $yamlOutsidePath = Join-Path $yamlOutside ".github/instructions/geurts-unity.instructions.md"
    $yamlTemplateText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md"))
    $yamlRegion = [regex]::Match($yamlTemplateText, '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="unity-frontmatter".*?^#\s*GEURTS-MANAGED-END\s+id="unity-frontmatter"\s*$')
    if (-not $yamlRegion.Success) { throw "Unable to prepare the YAML marker boundary fixture." }
    $yamlOutsideText = $yamlTemplateText.Remove($yamlRegion.Index, $yamlRegion.Length).TrimEnd() + "`n`n" + $yamlRegion.Value + "`n"
    Write-Utf8 -Path $yamlOutsidePath -Text $yamlOutsideText
    $yamlOutsideHash = Get-FileSha -Path $yamlOutsidePath
    $yamlOutsideRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $yamlOutside, "-DocumentationMode", "Skip")
    Assert-True ($yamlOutsideRun.Code -eq 2 -and (Get-FileSha -Path $yamlOutsidePath) -eq $yamlOutsideHash -and $yamlOutsideRun.Output.Contains("frontmatter delimiters")) "YAML managed markers outside frontmatter conflict without overwriting"

    $optOut = New-TestProject -Parent $testRoot -Name "opt-out"
    $optOutPath = Join-Path $optOut "AGENTS.md"
    $optOutText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md")) + "`n<!-- GEURTS-MANAGED-OPT-OUT -->`nUser-owned routing remains authoritative.`n"
    Write-Utf8 -Path $optOutPath -Text $optOutText
    $optOutHash = Get-FileSha -Path $optOutPath
    $optOutRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $optOut, "-DocumentationMode", "Skip")
    Assert-True ($optOutRun.Code -eq 0 -and (Get-FileSha -Path $optOutPath) -eq $optOutHash -and $optOutRun.Output.Contains("Skipped: AGENTS.md")) "Explicit managed opt-out preserves the complete native entry"

    $editedManaged = New-TestProject -Parent $testRoot -Name "edited-managed"
    $editedManagedPath = Join-Path $editedManaged "AGENTS.md"
    $editedManagedText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md")).Replace("Geurts Game Forge - Codex Entry", "User Edited Geurts Game Forge - Codex Entry")
    Write-Utf8 -Path $editedManagedPath -Text $editedManagedText
    $editedManagedHash = Get-FileSha -Path $editedManagedPath
    $editedManagedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $editedManaged, "-DocumentationMode", "Skip")
    Assert-True ($editedManagedRun.Code -eq 2 -and (Get-FileSha -Path $editedManagedPath) -eq $editedManagedHash) "Edited managed content conflicts without overwriting"

    $futureManaged = New-TestProject -Parent $testRoot -Name "future-managed"
    $futureManagedPath = Join-Path $futureManaged "AGENTS.md"
    $futureManagedText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/AGENTS.md")).Replace('version="0.7.0"', 'version="0.8.0"')
    Write-Utf8 -Path $futureManagedPath -Text $futureManagedText
    $futureManagedHash = Get-FileSha -Path $futureManagedPath
    $futureManagedRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $futureManaged, "-DocumentationMode", "Skip")
    Assert-True ($futureManagedRun.Code -eq 2 -and (Get-FileSha -Path $futureManagedPath) -eq $futureManagedHash -and $futureManagedRun.Output.Contains("no downgrade")) "Future managed native entry is never downgraded"

    $tamperedCatalogProject = New-TestProject -Parent $testRoot -Name "tampered-catalog"
    $tamperedCatalogPath = Join-Path $tamperedCatalogProject "NativeEntryMigrationCatalog.json"
    $tamperedCatalog = Get-Content -LiteralPath (Join-Path $RepositoryRoot "Tools/NativeEntryMigrationCatalog.json") -Raw | ConvertFrom-Json
    $tamperedCatalog.entries[0].targetPath = "UserInstructions.md"
    Write-Utf8 -Path $tamperedCatalogPath -Text ($tamperedCatalog | ConvertTo-Json -Depth 10)
    $tamperedCatalogRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $tamperedCatalogProject, "-DocumentationMode", "Skip", "-MigrationCatalogPath", $tamperedCatalogPath)
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
        $migrationRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $project, "-DocumentationMode", "Skip")
        Assert-True ($migrationRun.Code -eq 0) "Exact $($set.Name) native set migrates"
        foreach ($relative in $set.Files.Keys) {
            $target = Join-Path $project $relative
            Assert-True ([System.IO.File]::ReadAllText($target).Contains("GEURTS-MANAGED-BEGIN")) "$($set.Name) $relative gains managed markers"
            Assert-True (Test-Path -LiteralPath ($target + ".pre-v0.7.0.bak") -PathType Leaf) "$($set.Name) $relative receives a pre-v0.7.0 backup"
        }
    }

    $modifiedLegacy = New-TestProject -Parent $testRoot -Name "modified-legacy"
    $modifiedLegacyPath = Join-Path $modifiedLegacy "AGENTS.md"
    Write-Utf8 -Path $modifiedLegacyPath -Text ((Get-HistoricalFile -Specification "544922c:Tools/AIAgentInstructionTemplates/AGENTS.md") + "`nUser modification.`n")
    $modifiedLegacyHash = Get-FileSha -Path $modifiedLegacyPath
    $modifiedLegacyRun = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $modifiedLegacy, "-DocumentationMode", "Skip")
    Assert-True ($modifiedLegacyRun.Code -eq 2 -and (Get-FileSha -Path $modifiedLegacyPath) -eq $modifiedLegacyHash -and $modifiedLegacyRun.Output.Contains("user-modified legacy")) "Modified legacy native entry is preserved and reported as conflicted"

    # Deterministic GDD add, metadata preservation, move detection, removal, and duplicate safety.
    $gddProject = New-TestProject -Parent $testRoot -Name "gdd"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $gddProject, "-DocumentationMode", "Skip", "-SkipGameDesignManifestUpdate") | Out-Null
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
    $noncanonicalManifest = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject, "-ManifestPath", "Docs/Other/GameDesignManifest.md")
    Assert-True ($noncanonicalManifest.Code -eq 2 -and $noncanonicalManifest.Output.Contains("Conflicted:") -and $noncanonicalManifest.Output.Contains("canonical project path")) "GDD maintainer refuses a noncanonical manifest location"
    $malformedGddProject = New-TestProject -Parent $testRoot -Name "gdd-malformed"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $malformedGddProject, "-DocumentationMode", "Skip", "-SkipGameDesignManifestUpdate") | Out-Null
    $malformedGddManifest = Join-Path $malformedGddProject "Docs/GameDesign/GameDesignManifest.md"
    $malformedGddText = [System.IO.File]::ReadAllText($malformedGddManifest).Replace('<!-- GEURTS-GDD-MANIFEST-END -->', "| malformed | row |`n<!-- GEURTS-GDD-MANIFEST-END -->")
    Write-Utf8 -Path $malformedGddManifest -Text $malformedGddText
    $malformedGddHash = Get-FileSha -Path $malformedGddManifest
    $malformedGddRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $malformedGddProject)
    Assert-True ($malformedGddRun.Code -eq 2 -and (Get-FileSha -Path $malformedGddManifest) -eq $malformedGddHash) "Malformed managed GDD records conflict without discarding user routing metadata"
    $futureGddProject = New-TestProject -Parent $testRoot -Name "gdd-future"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $futureGddProject, "-DocumentationMode", "Skip", "-SkipGameDesignManifestUpdate") | Out-Null
    $futureGddManifest = Join-Path $futureGddProject "Docs/GameDesign/GameDesignManifest.md"
    Write-Utf8 -Path $futureGddManifest -Text ([System.IO.File]::ReadAllText($futureGddManifest).Replace('GEURTS-GDD-MANIFEST-BEGIN version="0.7.0"', 'GEURTS-GDD-MANIFEST-BEGIN version="9.0.0"'))
    $futureGddHash = Get-FileSha -Path $futureGddManifest
    $futureGddRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $futureGddProject)
    Assert-True ($futureGddRun.Code -eq 2 -and (Get-FileSha -Path $futureGddManifest) -eq $futureGddHash -and $futureGddRun.Output.Contains("no downgrade")) "Future GDD manifest region is never downgraded"
    $invalidMetadataProject = New-TestProject -Parent $testRoot -Name "gdd-invalid-metadata"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $invalidMetadataProject, "-DocumentationMode", "Skip", "-SkipGameDesignManifestUpdate") | Out-Null
    Write-Utf8 -Path (Join-Path $invalidMetadataProject "Docs/GameDesign/BadVersion.md") -Text "geurtsId: bad-version`nversion: definitely-not-semver`n# Invalid version`n"
    $invalidMetadataManifest = Join-Path $invalidMetadataProject "Docs/GameDesign/GameDesignManifest.md"
    $invalidMetadataHash = Get-FileSha -Path $invalidMetadataManifest
    $invalidMetadataRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $invalidMetadataProject)
    Assert-True ($invalidMetadataRun.Code -eq 2 -and (Get-FileSha -Path $invalidMetadataManifest) -eq $invalidMetadataHash) "Invalid explicit GDD metadata is rejected before rendering"
    $lockedGddProject = New-TestProject -Parent $testRoot -Name "gdd-locked"
    Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $lockedGddProject, "-DocumentationMode", "Skip", "-SkipGameDesignManifestUpdate") | Out-Null
    $ownedLockPath = Join-Path $lockedGddProject "Docs/GameDesign/.ggf-manifest.lock"
    $ownedLock = New-Object System.IO.FileStream($ownedLockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    try {
        $lockedGddRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $lockedGddProject)
        Assert-True ($lockedGddRun.Code -eq 2 -and (Test-Path -LiteralPath $ownedLockPath -PathType Leaf)) "Failed GDD lock acquisition does not delete another operation's lock"
    }
    finally {
        $ownedLock.Dispose()
        Remove-Item -LiteralPath $ownedLockPath -Force -ErrorAction SilentlyContinue
    }
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/One.md") -Text "geurtsId: duplicate-id`n# One`n"
    Write-Utf8 -Path (Join-Path $gddProject "Docs/GameDesign/Two.md") -Text "geurtsId: duplicate-id`n# Two`n"
    $beforeDuplicate = Get-FileSha -Path $gddManifestPath
    $duplicateRun = Invoke-TestScript -Path $gddScript -Arguments @("-ProjectRoot", $gddProject)
    Assert-True ($duplicateRun.Code -eq 2 -and $duplicateRun.Output.Contains("Conflicted:") -and (Get-FileSha -Path $gddManifestPath) -eq $beforeDuplicate) "Duplicate GDD identifiers report conflict and preserve the last valid manifest"

    # Definition consumption, profile selection, idempotence, and path collision safety.
    $folderProject = New-TestProject -Parent $testRoot -Name "folders"
    # The production contract fixes the full profile at 67 entries. Use the canonical definition
    # for behavior tests.
    $definitionPath = Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
    $folderRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $folderProject, "-DefinitionPath", $definitionPath)
    Assert-True ($folderRun.Code -eq 0 -and $folderRun.Output.Contains("Skipped: .github") -and $folderRun.Output.Contains("definition 0.7.0") -and (Test-Path -LiteralPath (Join-Path $folderProject "Assets/_Project") -PathType Container)) "Folder tool consumes and reports the exact machine-definition version and skipped scope"
    $folderAgain = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $folderProject, "-DefinitionPath", $definitionPath)
    Assert-True ($folderAgain.Code -eq 0 -and $folderAgain.Output.Contains("Exists")) "Folder creation is idempotent"
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
    Assert-True ($tamperedRun.Code -ne 0 -and $tamperedRun.Output.Contains("Invalid: Builds") -and @(Get-ChildItem -LiteralPath $tamperedProject -Force).Count -eq 0) "Folder tool rejects count-preserving profile-scope tampering before mutation"
    $blockedProject = New-TestProject -Parent $testRoot -Name "folder-blocked"
    Write-Utf8 -Path (Join-Path $blockedProject "Assets") -Text "blocking file"
    $blockedRun = Invoke-TestScript -Path $folderScript -Arguments @("-ProjectRoot", $blockedProject, "-DefinitionPath", $definitionPath)
    Assert-True ($blockedRun.Code -ne 0 -and $blockedRun.Output.Contains("Conflicted: Assets") -and (Test-Path -LiteralPath (Join-Path $blockedProject "Assets") -PathType Leaf)) "Folder collision reports the exact path and fails without deleting user content"

    # Local Git remote proves Check/Update/Validate, exact layout, and last-valid-copy safety.
    $gitArea = New-TestProject -Parent $testRoot -Name "git"
    $source = New-TestProject -Parent $gitArea -Name "source"
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot "AI_READ_FIRST.md") -Destination (Join-Path $source "AI_READ_FIRST.md")
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniqueManifest.md") -Destination (Join-Path $source "GeurtsTechniqueManifest.md")
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Destination (Join-Path $source "GeurtsTechniques") -Recurse
    Write-Utf8 -Path (Join-Path $source "Unrelated.md") -Text "# Excluded`n"
    Invoke-TestGit -Arguments @("init") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("config", "user.email", "automation@example.invalid") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("config", "user.name", "Automation Tests") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("add", ".") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("commit", "-m", "valid") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("branch", "-M", "main") -WorkingDirectory $source | Out-Null
    $remote = Join-Path $gitArea "remote.git"
    Invoke-TestGit -Arguments @("clone", "--bare", $source, $remote) -WorkingDirectory $gitArea | Out-Null
    $bootstrapProject = New-TestProject -Parent $gitArea -Name "project"
    New-Item -ItemType Directory -Path (Join-Path $bootstrapProject "Tools") | Out-Null
    $bootstrapConfig = [ordered]@{
        schemaVersion = "0.7.0"; packageVersion = "0.7.0"; distributionStrategy = "authenticated-private-repository"; repositoryUrl = $remote; branch = "main"; localSyncPath = "GeurtsGameForgeDocumentation"; entryPointPath = "AI_READ_FIRST.md"; manifestPath = "GeurtsTechniqueManifest.md"; techniquesPath = "GeurtsTechniques"; folderDefinitionPath = "GeurtsTechniques/GeurtsFolderStructureDefinition.json"; fallbackPolicy = "none";
        requiredEntries = @([ordered]@{path="AI_READ_FIRST.md";type="file"},[ordered]@{path="GeurtsTechniqueManifest.md";type="file"},[ordered]@{path="GeurtsTechniques";type="directory"});
        sparsePaths = @("/AI_READ_FIRST.md", "/GeurtsTechniqueManifest.md", "/GeurtsTechniques/")
    }
    $configPath = Join-Path $bootstrapProject "Tools/GeurtsRepository.json"
    Write-Utf8 -Path $configPath -Text ($bootstrapConfig | ConvertTo-Json -Depth 8)
    $unsafeBootstrapProject = New-TestProject -Parent $gitArea -Name "unsafe-config-project"
    New-Item -ItemType Directory -Path (Join-Path $unsafeBootstrapProject "Tools") | Out-Null
    $unsafeBootstrapConfig = ($bootstrapConfig | ConvertTo-Json -Depth 8 | ConvertFrom-Json)
    $unsafeBootstrapConfig.localSyncPath = (".ge" + "urts/up" + "stream")
    $unsafeConfigPath = Join-Path $unsafeBootstrapProject "Tools/GeurtsRepository.json"
    Write-Utf8 -Path $unsafeConfigPath -Text ($unsafeBootstrapConfig | ConvertTo-Json -Depth 8)
    $unsafeBootstrapRun = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Check", "-ProjectRoot", $unsafeBootstrapProject, "-ConfigPath", $unsafeConfigPath)
    Assert-True ($unsafeBootstrapRun.Code -eq 10 -and -not (Test-Path -LiteralPath (Join-Path $unsafeBootstrapProject (".ge" + "urts")))) "Bootstrap rejects hidden or noncanonical synchronization paths before mutation"
    $bootstrapUpdate = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Update", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath)
    $syncPath = Join-Path $bootstrapProject "GeurtsGameForgeDocumentation"
    if (-not (Test-Path -LiteralPath $syncPath -PathType Container)) {
        throw "Bootstrap initial update failed with exit $($bootstrapUpdate.Code): $($bootstrapUpdate.Output)"
    }
    $visible = @(Get-ChildItem -LiteralPath $syncPath -Force | Where-Object { $_.Name -ne ".git" } | Select-Object -ExpandProperty Name)
    Assert-True ($bootstrapUpdate.Code -eq 0 -and $bootstrapUpdate.Output.Contains("SYNC OK") -and $visible.Count -eq 3 -and -not ($visible -contains "Unrelated.md")) "Bootstrap Update produces exactly three visible entries after post-promotion validation"
    $validCommit = Invoke-TestGit -Arguments @("rev-parse", "HEAD") -WorkingDirectory $syncPath
    $sourceEntryPath = Join-Path $source "AI_READ_FIRST.md"
    Write-Utf8 -Path $sourceEntryPath -Text ([System.IO.File]::ReadAllText($sourceEntryPath) + "`n<!-- valid automation update fixture -->`n")
    Invoke-TestGit -Arguments @("add", "AI_READ_FIRST.md") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("commit", "-m", "valid update") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("push", $remote, "main") -WorkingDirectory $source | Out-Null
    $reportedUpdate = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Update", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath, "-OutputFormat", "Json")
    $reportedUpdateObject = $null
    try { $reportedUpdateObject = $reportedUpdate.Output | ConvertFrom-Json }
    catch { }
    $updatedCommit = Invoke-TestGit -Arguments @("rev-parse", "HEAD") -WorkingDirectory $syncPath
    Assert-True ($reportedUpdate.Code -eq 0 -and $reportedUpdateObject -and $reportedUpdateObject.status -eq "UPDATED" -and $reportedUpdateObject.previousCommit -eq $validCommit -and $reportedUpdateObject.synchronizedCommit -eq $updatedCommit -and $reportedUpdateObject.validationOutcome -eq "PASSED") "Bootstrap Update JSON reports previous commit, synchronized commit, and validation outcome"
    $validCommit = $updatedCommit
    $checkHash = Get-FileSha -Path (Join-Path $syncPath "AI_READ_FIRST.md")
    $lockSha = [System.Security.Cryptography.SHA256]::Create()
    try { $lockHash = ([System.BitConverter]::ToString($lockSha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($syncPath.Replace('\', '/').ToLowerInvariant())))).Replace("-", "").ToLowerInvariant() }
    finally { $lockSha.Dispose() }
    $bootstrapMutex = New-Object System.Threading.Mutex($false, ("ggf-documentation-sync-" + $lockHash))
    $bootstrapMutexHeld = $bootstrapMutex.WaitOne(0)
    try {
        $lockedBootstrap = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Check", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath)
        Assert-True ($bootstrapMutexHeld -and $lockedBootstrap.Code -eq 33 -and $lockedBootstrap.Output.Contains("Another documentation synchronization operation")) "Bootstrap target lock rejects a concurrent synchronization operation"
    }
    finally {
        if ($bootstrapMutexHeld) { $bootstrapMutex.ReleaseMutex() }
        $bootstrapMutex.Dispose()
    }
    $bootstrapCheck = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Check", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath)
    Assert-True ($bootstrapCheck.Code -eq 0 -and $bootstrapCheck.Output.Contains("CHECK OK") -and -not $bootstrapCheck.Output.Contains("SYNC OK") -and $bootstrapCheck.Output.Contains("CURRENT") -and (Get-FileSha -Path (Join-Path $syncPath "AI_READ_FIRST.md")) -eq $checkHash) "Bootstrap Check is non-mutating and does not claim synchronization"
    $bootstrapValidate = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Validate", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath)
    Assert-True ($bootstrapValidate.Code -eq 0 -and $bootstrapValidate.Output.Contains("VALIDATION OK") -and -not $bootstrapValidate.Output.Contains("SYNC OK") -and $bootstrapValidate.Output.Contains("VALID") -and $bootstrapValidate.Output.Contains("Package:     0.7.0")) "Bootstrap Validate checks manifest-listed content without claiming synchronization"
    $managedBootstrapJson = Invoke-TestScript -Path $manageScript -Arguments @("-ProjectRoot", $bootstrapProject, "-DocumentationMode", "Validate", "-OutputFormat", "Json", "-SkipGameDesignManifestUpdate")
    $managedBootstrapObject = $null
    try { $managedBootstrapObject = $managedBootstrapJson.Output | ConvertFrom-Json }
    catch { }
    Assert-True ($managedBootstrapJson.Code -eq 0 -and $managedBootstrapObject -and $managedBootstrapObject.status -eq "OK" -and $managedBootstrapObject.documentation.status -eq "VALID" -and $managedBootstrapObject.documentation.validationOutcome -eq "PASSED") "Managed setup JSON embeds parseable bootstrap validation output"
    Remove-Item -LiteralPath (Join-Path $source "GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md") -Force
    Invoke-TestGit -Arguments @("add", "-A") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("commit", "-m", "invalid candidate") -WorkingDirectory $source | Out-Null
    Invoke-TestGit -Arguments @("push", $remote, "main") -WorkingDirectory $source | Out-Null
    $failedUpdate = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Update", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath, "-OutputFormat", "Json")
    $failedUpdateObject = $null
    try { $failedUpdateObject = $failedUpdate.Output | ConvertFrom-Json }
    catch { }
    $afterFailureCommit = Invoke-TestGit -Arguments @("rev-parse", "HEAD") -WorkingDirectory $syncPath
    Assert-True ($failedUpdate.Code -eq 31 -and $failedUpdateObject.lastValidCopy -eq $syncPath -and $afterFailureCommit -eq $validCommit -and (Test-Path -LiteralPath (Join-Path $syncPath "GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md") -PathType Leaf)) "Incomplete manifest-listed candidate is rejected and the confirmed last-valid synchronized copy is reported"

    $activeDefinitionPath = Join-Path $syncPath "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
    $activeDefinition = Get-Content -LiteralPath $activeDefinitionPath -Raw | ConvertFrom-Json
    $closureFixture = @($activeDefinition.managedFolders | Where-Object { $_.path -eq "Builds" })[0]
    $closureFixture.path = ".github/Foo"
    $closureFixture.parent = ".github"
    Write-Utf8 -Path $activeDefinitionPath -Text ($activeDefinition | ConvertTo-Json -Depth 12)
    $invalidActiveValidation = Invoke-TestScript -Path $bootstrapScript -Arguments @("-Mode", "Validate", "-ProjectRoot", $bootstrapProject, "-ConfigPath", $configPath, "-OutputFormat", "Json")
    $invalidActiveObject = $null
    try { $invalidActiveObject = $invalidActiveValidation.Output | ConvertFrom-Json }
    catch { }
    Assert-True ($invalidActiveValidation.Code -eq 31 -and $invalidActiveObject -and $invalidActiveObject.message.Contains("parent-closed") -and -not $invalidActiveObject.lastValidCopy -and $invalidActiveObject.preservedLocalCopy -eq $syncPath) "Bootstrap rejects non-parent-closed profiles and does not label an invalid active copy as last-valid"

    # Static validation covers manifest existence/version, canonical paths, GDD boundary,
    # folder parity, native route, chat-only classification, and multiplayer exception.
    $staticValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $RepositoryRoot)
    Assert-True ($staticValidation.Code -eq 0) "Repository static validation covers all normative acceptance rules"
    $staticJsonValidation = Invoke-TestScript -Path $validatorScript -Arguments @("-RepositoryRoot", $RepositoryRoot, "-OutputFormat", "Json")
    $staticJsonObject = $null
    try { $staticJsonObject = $staticJsonValidation.Output | ConvertFrom-Json }
    catch { }
    Assert-True ($staticJsonValidation.Code -eq 0 -and $staticJsonObject -and $staticJsonObject.status -eq "VALID" -and @($staticJsonObject.checks).Count -eq 18) "Repository validation JSON output is one parseable document"
}
catch {
    $script:Failed++
    $script:FailureMessages.Add("Test harness exception: $($_.Exception.Message)") | Out-Null
    if ($OutputFormat -eq "Text") { Write-Host "TEST HARNESS ERROR: $($_.Exception.Message)" -ForegroundColor Red }
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
