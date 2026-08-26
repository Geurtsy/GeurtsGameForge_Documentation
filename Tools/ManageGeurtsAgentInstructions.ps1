# ManageGeurtsAgentInstructions.ps1
# Version: 0.7.0

[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$TemplateRoot,
    [string]$MigrationCatalogPath,
    [ValidateSet("Update", "Check", "Validate", "Skip")]
    [string]$DocumentationMode = "Update",
    [switch]$SkipGameDesignManifestUpdate,
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$results = New-Object System.Collections.Generic.List[object]
$documentationResult = $null
$manifestResult = $null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$htmlMarkerPattern = '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[^"]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*-->\r?\n(?<Body>.*?)^<!--\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*-->\s*$'
$yamlMarkerPattern = '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[^"]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*\r?\n(?<Body>.*?)^#\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*$'

function Get-FullPath([string]$Path, [string]$BasePath) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-IsContainedPath([string]$Candidate, [string]$Root) {
    $rootWithSeparator = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-HasReparsePoint([string]$Candidate, [string]$Root) {
    $rootItem = Get-Item -LiteralPath $Root -Force
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
    $current = $Candidate
    while (Test-IsContainedPath -Candidate $current -Root $Root) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return $true }
        }
        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current -or $parent -eq $Root) { break }
        $current = $parent
    }
    return $false
}

function Get-NormalizedText([string]$Text) {
    if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    if ($normalized.Length -gt 0 -and -not $normalized.EndsWith("`n")) { $normalized += "`n" }
    return $normalized
}

function Get-TextHash([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes((Get-NormalizedText -Text $Text))
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-ManagedRegions([string]$Text) {
    $beginCount = [regex]::Matches($Text, 'GEURTS-MANAGED-BEGIN').Count
    $endCount = [regex]::Matches($Text, 'GEURTS-MANAGED-END').Count
    $htmlMatches = @([regex]::Matches($Text, $htmlMarkerPattern))
    $yamlMatches = @([regex]::Matches($Text, $yamlMarkerPattern))
    if ($yamlMatches.Count -gt 0) {
        $frontmatter = [regex]::Match($Text, '(?s)\A(?:\uFEFF)?---\r?\n.*?\r?\n---(?=\r?\n|\z)')
        if (-not $frontmatter.Success) { throw "YAML managed markers must be inside one opening frontmatter block." }
        $frontmatterEnd = $frontmatter.Index + $frontmatter.Length
        foreach ($yamlMatch in $yamlMatches) {
            if ($yamlMatch.Index -lt $frontmatter.Index -or ($yamlMatch.Index + $yamlMatch.Length) -gt $frontmatterEnd) {
                throw "YAML managed markers must remain between the opening and closing frontmatter delimiters."
            }
        }
    }
    $matches = $htmlMatches + $yamlMatches
    $matches = @($matches | Sort-Object Index)
    if ($beginCount -ne $endCount -or $beginCount -ne $matches.Count) {
        throw "Managed markers are missing, malformed, duplicated, or nested."
    }

    $ids = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $regions = New-Object System.Collections.Generic.List[object]
    foreach ($match in $matches) {
        $id = $match.Groups["Id"].Value
        if (-not $ids.Add($id)) { throw "Managed marker ID '$id' appears more than once." }
        $body = $match.Groups["Body"].Value
        $regions.Add([pscustomobject]@{
            Id = $id
            Version = $match.Groups["Version"].Value
            DeclaredHash = $match.Groups["Hash"].Value.ToLowerInvariant()
            ActualHash = Get-TextHash -Text $body
            Body = $body
            Index = $match.Index
            Length = $match.Length
            FullText = $match.Value
        }) | Out-Null
    }
    return $regions.ToArray()
}

function Write-AtomicText([string]$Path, [string]$Text) {
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -ErrorAction Stop | Out-Null
    }
    $temporary = Join-Path $directory (".ggf-write-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    $replacementBackup = Join-Path $directory (".ggf-replace-" + [Guid]::NewGuid().ToString("N") + ".bak")
    try {
        [System.IO.File]::WriteAllText($temporary, $Text, $utf8NoBom)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [System.IO.File]::Replace($temporary, $Path, $replacementBackup)
        }
        else {
            Move-Item -LiteralPath $temporary -Destination $Path -ErrorAction Stop
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $replacementBackup) { Remove-Item -LiteralPath $replacementBackup -Force -ErrorAction SilentlyContinue }
    }
}

function New-Backup([string]$TargetPath) {
    $base = "$TargetPath.pre-v0.7.0.bak"
    $backup = $base
    $index = 1
    while (Test-Path -LiteralPath $backup) {
        $backup = "$base.$index"
        $index++
    }
    Copy-Item -LiteralPath $TargetPath -Destination $backup -ErrorAction Stop
    if (-not (Test-Path -LiteralPath $backup -PathType Leaf)) {
        throw "Backup creation failed for '$TargetPath'."
    }
    return $backup
}

function Add-Result([string]$Status, [string]$Path, [string]$Message, [string]$Backup) {
    $results.Add([pscustomobject]@{
        status = $Status.ToLowerInvariant()
        path = $Path
        message = $Message
        backup = $Backup
    }) | Out-Null
    if ($OutputFormat -eq "Text") {
        $suffix = if ($Message) { " - $Message" } else { "" }
        Write-Host ("{0}: {1}{2}" -f $Status, $Path, $suffix)
        if ($Backup) { Write-Host "  Backup: $Backup" }
    }
}

function Invoke-ChildPowerShell([string]$ScriptPath, [string[]]$Arguments, [bool]$EmitOutput) {
    $hostPath = (Get-Process -Id $PID).Path
    $hostArguments = @("-NoProfile")
    if ((Split-Path -Leaf $hostPath) -like "powershell*") {
        $hostArguments += @("-ExecutionPolicy", "Bypass")
    }
    $hostArguments += @("-File", $ScriptPath)
    $hostArguments += $Arguments
    $childOutput = @(& $hostPath @hostArguments 2>&1)
    $childExitCode = $LASTEXITCODE
    if ($EmitOutput) { foreach ($line in $childOutput) { Write-Host ([string]$line) } }
    return [pscustomobject]@{
        Code = [int]$childExitCode
        Output = ($childOutput -join [Environment]::NewLine)
    }
}

function Test-NativeMigrationCatalog($Catalog, [string]$Templates, [string]$Root) {
    $expected = @{
        "AGENTS.md" = @{ Template = "AGENTS.md"; Hashes = @{ "0.4.0" = "24232b85e9c5f18e1c055e0c1d59ba9d4b9f294472b25dbb966ae682e4d1d9d7"; "0.5.0" = "3bec9754a17f3387f27e0678feb69e541c921d81d55f6093a87c27c1fca98534"; "0.6.0" = "a44874e2feedfe903caf805c0dd91fb71cb5ce2db5696330d1a37c399501118e" } }
        ".github/copilot-instructions.md" = @{ Template = "copilot-instructions.md"; Hashes = @{ "0.4.0" = "d72006b497ed12ae97ef3d4ef9248f634af7159b7011434987ea3bd60cbd8da7"; "0.5.0" = "d72006b497ed12ae97ef3d4ef9248f634af7159b7011434987ea3bd60cbd8da7"; "0.6.0" = "cfeb6826447b74d391c7afa40f07e19171086ee0f6e8a107887360fa4e6fd7e3" } }
        ".github/instructions/geurts-unity.instructions.md" = @{ Template = "instructions/geurts-unity.instructions.md"; Hashes = @{ "0.4.0" = "27bff44e8cd8a26962b2b2890b3ca6c02a5a1ee6c0531c195514d70b9ffde92f"; "0.5.0" = "27bff44e8cd8a26962b2b2890b3ca6c02a5a1ee6c0531c195514d70b9ffde92f"; "0.6.0" = "799fe2cc0a720cd5e9f7f350b7480d219c0f92309a4a6201953e3a452faa0fa3" } }
        ".github/instructions/geurts-game-design.instructions.md" = @{ Template = "instructions/geurts-game-design.instructions.md"; Hashes = @{ "0.4.0" = "724549bbd75e2ed1f83167992747f5b56adac9d0b4e40886085b65d497cddbd9"; "0.5.0" = "724549bbd75e2ed1f83167992747f5b56adac9d0b4e40886085b65d497cddbd9"; "0.6.0" = "2805d6be2804eff71668625a83725d02338070a9b6988bde20bc521d455d17c0" } }
    }
    if ([string]$Catalog.schemaVersion -cne "0.7.0" -or [string]$Catalog.normalization -cne "utf8-text-with-lf-newlines-and-terminal-lf" -or @($Catalog.entries).Count -ne 4) {
        throw "Migration catalog metadata does not match the exact v0.7.0 contract."
    }
    $seenTargets = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($entry in @($Catalog.entries)) {
        $target = [string]$entry.targetPath
        $template = [string]$entry.templatePath
        if (-not $seenTargets.Add($target) -or -not $expected.ContainsKey($target) -or $template -cne [string]$expected[$target].Template) { throw "Migration catalog contains an unexpected or duplicate native target '$target'." }
        $targetPath = Get-FullPath -Path ($target.Replace('/', [System.IO.Path]::DirectorySeparatorChar)) -BasePath $Root
        $templatePath = Get-FullPath -Path ($template.Replace('/', [System.IO.Path]::DirectorySeparatorChar)) -BasePath $Templates
        if (-not (Test-IsContainedPath -Candidate $targetPath -Root $Root) -or -not (Test-IsContainedPath -Candidate $templatePath -Root $Templates) -or -not (Test-Path -LiteralPath $templatePath -PathType Leaf)) { throw "Migration catalog path contract is invalid for '$target'." }
        if ((Test-HasReparsePoint -Candidate $targetPath -Root $Root) -or (Test-HasReparsePoint -Candidate $templatePath -Root $Templates)) { throw "Migration catalog path uses an unsafe reparse point for '$target'." }
        $seenVersions = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($fingerprint in @($entry.legacyFingerprints)) {
            $hash = ([string]$fingerprint.sha256).ToLowerInvariant()
            if ($hash -notmatch '^[0-9a-f]{64}$' -or @($fingerprint.versions).Count -eq 0) { throw "Migration catalog contains a malformed fingerprint for '$target'." }
            foreach ($version in @($fingerprint.versions)) {
                $version = [string]$version
                if (-not $seenVersions.Add($version) -or -not $expected[$target].Hashes.ContainsKey($version) -or [string]$expected[$target].Hashes[$version] -cne $hash) { throw "Migration catalog fingerprint mismatch for '$target' version '$version'." }
            }
        }
        foreach ($version in @("0.4.0", "0.5.0", "0.6.0")) { if (-not $seenVersions.Contains($version)) { throw "Migration catalog is missing '$target' version '$version'." } }
    }
    foreach ($target in $expected.Keys) { if (-not $seenTargets.Contains($target)) { throw "Migration catalog is missing native target '$target'." } }
}

function Get-GddScaffoldingDefinition([string]$Root) {
    $definitionCandidates = @(
        (Join-Path $Root "GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureDefinition.json"),
        (Join-Path (Split-Path -Parent $PSScriptRoot) "GeurtsTechniques/GeurtsFolderStructureDefinition.json")
    )
    $definitionPath = $definitionCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace([string]$definitionPath)) {
        throw "The authoritative folder definition is required before creating GDD scaffolding."
    }
    $definitionTrustRoot = if (Test-IsContainedPath -Candidate ([System.IO.Path]::GetFullPath($definitionPath)) -Root $Root) { $Root } else { Split-Path -Parent $PSScriptRoot }
    if (Test-HasReparsePoint -Candidate ([System.IO.Path]::GetFullPath($definitionPath)) -Root $definitionTrustRoot) { throw "The authoritative folder definition uses an unsafe reparse point." }

    try { $definition = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json }
    catch { throw "The authoritative folder definition is invalid JSON: $($_.Exception.Message)" }
    if ([string]$definition.definitionVersion -ne "0.7.0" -or [string]$definition.packageVersion -ne "0.7.0") {
        throw "The GDD scaffolding delegation requires the v0.7.0 folder definition."
    }

    foreach ($profileId in @("native-entry", "gdd-scaffolding")) {
        $profiles = @($definition.creationProfiles | Where-Object { [string]$_.id -ceq $profileId })
        if ($profiles.Count -ne 1 -or [string]$profiles[0].owner -cne "native-entry-manager") {
            throw "The folder definition does not assign '$profileId' to native-entry-manager."
        }
    }
    foreach ($expected in @(
        @{ Path = ".github"; Parent = ""; Profile = "native-entry"; Delegated = $false },
        @{ Path = ".github/instructions"; Parent = ".github"; Profile = "native-entry"; Delegated = $false },
        @{ Path = "Docs"; Parent = ""; Profile = "gdd-scaffolding"; Delegated = $true },
        @{ Path = "Docs/GameDesign"; Parent = "Docs"; Profile = "gdd-scaffolding"; Delegated = $true }
    )) {
        $matches = @($definition.managedFolders | Where-Object { [string]$_.path -ceq $expected.Path })
        if ($matches.Count -ne 1) { throw "The folder definition must contain exactly one '$($expected.Path)' entry." }
        $folder = $matches[0]
        $actualParent = [string]$folder.parent
        if ($actualParent -cne $expected.Parent -or $folder.automation.mayCreate -ne $true -or $folder.automation.mayRemove -ne $false -or @($folder.automation.creationProfiles) -notcontains $expected.Profile) {
            throw "The folder definition does not authorize native-entry-manager for '$($expected.Path)'."
        }
        $primaryOwnerMatches = ([string]$folder.automation.owner -ceq "native-entry-manager")
        $delegatedOwnerMatches = $false
        if ($folder.automation.PSObject.Properties["delegatedOwners"] -and $folder.automation.delegatedOwners.PSObject.Properties[$expected.Profile]) {
            $delegatedOwnerMatches = ([string]$folder.automation.delegatedOwners.PSObject.Properties[$expected.Profile].Value -ceq "native-entry-manager")
        }
        if (($expected.Delegated -and -not $delegatedOwnerMatches) -or (-not $expected.Delegated -and -not $primaryOwnerMatches)) {
            throw "The folder definition does not delegate '$($expected.Path)' to native-entry-manager."
        }
    }
    return $definition
}

function Update-NativeEntry($Entry, [string]$Templates, [string]$Root) {
    $relativeTarget = ([string]$Entry.targetPath).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $relativeTemplate = ([string]$Entry.templatePath).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $targetPath = Get-FullPath -Path $relativeTarget -BasePath $Root
    $templatePath = Get-FullPath -Path $relativeTemplate -BasePath $Templates
    if (-not (Test-IsContainedPath -Candidate $targetPath -Root $Root)) {
        throw "Native target escapes the project root: $($Entry.targetPath)"
    }
    if (-not (Test-IsContainedPath -Candidate $templatePath -Root $Templates)) {
        throw "Native template escapes the template root: $($Entry.templatePath)"
    }
    if (Test-HasReparsePoint -Candidate $targetPath -Root $Root) {
        throw "Native target uses a reparse point and is unsafe: $($Entry.targetPath)"
    }
    if (Test-HasReparsePoint -Candidate $templatePath -Root $Templates) {
        throw "Native template uses a reparse point and is unsafe: $($Entry.templatePath)"
    }
    if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) {
        throw "Native instruction template is missing: $templatePath"
    }

    $templateText = [System.IO.File]::ReadAllText($templatePath)
    if (-not $templateText.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md")) {
        throw "Template does not route through the canonical AI entry point: $templatePath"
    }
    $templateRegions = Get-ManagedRegions -Text $templateText
    if ($templateRegions.Count -eq 0) { throw "Template has no managed regions: $templatePath" }
    foreach ($region in $templateRegions) {
        if ($region.ActualHash -ne $region.DeclaredHash) {
            throw "Template managed-region hash is invalid for '$($region.Id)'."
        }
    }

    if (-not (Test-Path -LiteralPath $targetPath)) {
        Write-AtomicText -Path $targetPath -Text $templateText
        Add-Result "Created" ([string]$Entry.targetPath) "Installed managed v0.7.0 entry." $null
        return
    }
    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        Add-Result "Conflicted" ([string]$Entry.targetPath) "A directory exists where a native instruction file is required." $null
        return
    }

    $targetText = [System.IO.File]::ReadAllText($targetPath)
    if ($targetText -match 'GEURTS-MANAGED-OPT-OUT') {
        Add-Result "Skipped" ([string]$Entry.targetPath) "Managed updates are explicitly disabled in this file." $null
        return
    }

    $beginCount = [regex]::Matches($targetText, 'GEURTS-MANAGED-BEGIN').Count
    $endCount = [regex]::Matches($targetText, 'GEURTS-MANAGED-END').Count
    if ($beginCount -gt 0 -or $endCount -gt 0) {
        try {
            $targetRegions = Get-ManagedRegions -Text $targetText
        }
        catch {
            Add-Result "Conflicted" ([string]$Entry.targetPath) $_.Exception.Message $null
            return
        }

        $templateById = @{}
        foreach ($region in $templateRegions) { $templateById[$region.Id] = $region }
        if ($targetRegions.Count -ne $templateRegions.Count) {
            Add-Result "Conflicted" ([string]$Entry.targetPath) "Managed region set does not match the current template." $null
            return
        }
        foreach ($region in $targetRegions) {
            if (-not $templateById.ContainsKey($region.Id)) {
                Add-Result "Conflicted" ([string]$Entry.targetPath) "Unknown managed region '$($region.Id)'." $null
                return
            }
            if ($region.ActualHash -ne $region.DeclaredHash) {
                Add-Result "Conflicted" ([string]$Entry.targetPath) "Managed region '$($region.Id)' was edited; no content was overwritten." $null
                return
            }
            if ($region.Version -cne "0.7.0") {
                Add-Result "Conflicted" ([string]$Entry.targetPath) "Managed region '$($region.Id)' uses unsupported version '$($region.Version)'; no downgrade or overwrite occurred." $null
                return
            }
        }

        $updatedText = $targetText
        foreach ($region in @($targetRegions | Sort-Object Index -Descending)) {
            $replacement = $templateById[$region.Id].FullText
            $updatedText = $updatedText.Substring(0, $region.Index) + $replacement + $updatedText.Substring($region.Index + $region.Length)
        }
        if ($updatedText -ceq $targetText) {
            Add-Result "Preserved" ([string]$Entry.targetPath) "Managed content is current; user content outside markers is unchanged." $null
            return
        }

        $backup = New-Backup -TargetPath $targetPath
        try {
            Write-AtomicText -Path $targetPath -Text $updatedText
        }
        catch {
            Add-Result "Conflicted" ([string]$Entry.targetPath) "Atomic managed update failed; the original and backup were preserved." $backup
            return
        }
        Add-Result "Updated" ([string]$Entry.targetPath) "Refreshed managed regions and preserved content outside markers." $backup
        return
    }

    $targetHash = Get-TextHash -Text $targetText
    $knownLegacy = @($Entry.legacyFingerprints | Where-Object { ([string]$_.sha256).ToLowerInvariant() -eq $targetHash }).Count -gt 0
    if ($knownLegacy) {
        $backup = New-Backup -TargetPath $targetPath
        try {
            Write-AtomicText -Path $targetPath -Text $templateText
        }
        catch {
            Add-Result "Conflicted" ([string]$Entry.targetPath) "Legacy migration failed; the original and backup were preserved." $backup
            return
        }
        Add-Result "Updated" ([string]$Entry.targetPath) "Migrated an exact known legacy template to managed v0.7.0 content." $backup
        return
    }

    if ($targetText -match '(?im)^\s*(?:\*\*)?Version\s*:?\s*(?:\*\*)?\s*v?0\.[456](?:\.0)?' -and $targetText -match '(?i)Geurts') {
        Add-Result "Conflicted" ([string]$Entry.targetPath) "This appears to be a user-modified legacy Geurts file. Migrate it manually or restore an exact known template." $null
        return
    }

    Add-Result "Skipped" ([string]$Entry.targetPath) "User-owned unmarked file was preserved without changes." $null
}

try {
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
    $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Project root does not exist: $ProjectRoot" }

    if ([string]::IsNullOrWhiteSpace($TemplateRoot)) { $TemplateRoot = Join-Path $PSScriptRoot "AIAgentInstructionTemplates" }
    else { $TemplateRoot = Get-FullPath -Path $TemplateRoot -BasePath $ProjectRoot }
    if ([string]::IsNullOrWhiteSpace($MigrationCatalogPath)) { $MigrationCatalogPath = Join-Path $PSScriptRoot "NativeEntryMigrationCatalog.json" }
    else { $MigrationCatalogPath = Get-FullPath -Path $MigrationCatalogPath -BasePath $ProjectRoot }
    if (-not (Test-Path -LiteralPath $TemplateRoot -PathType Container)) { throw "Template directory is missing: $TemplateRoot" }
    if (-not (Test-Path -LiteralPath $MigrationCatalogPath -PathType Leaf)) { throw "Migration catalog is missing: $MigrationCatalogPath" }

    if ($DocumentationMode -ne "Skip") {
        $bootstrapPath = Join-Path $PSScriptRoot "BootstrapGeurtsInstructions.ps1"
        $bootstrapArguments = @("-Mode", $DocumentationMode, "-ProjectRoot", $ProjectRoot)
        if ($OutputFormat -eq "Json") { $bootstrapArguments += @("-OutputFormat", "Json") }
        $bootstrapRun = Invoke-ChildPowerShell -ScriptPath $bootstrapPath -Arguments $bootstrapArguments -EmitOutput ($OutputFormat -eq "Text")
        if ($OutputFormat -eq "Json") {
            try { $documentationResult = $bootstrapRun.Output | ConvertFrom-Json }
            catch { throw "Documentation $DocumentationMode returned invalid JSON. No project instruction files were changed." }
        }
        if ($bootstrapRun.Code -ne 0) {
            $childMessage = if ($documentationResult -and $documentationResult.message) { " $($documentationResult.message)" } else { "" }
            throw "Documentation $DocumentationMode failed with exit code $($bootstrapRun.Code).$childMessage No project instruction files were changed."
        }
    }

    try { $catalog = Get-Content -LiteralPath $MigrationCatalogPath -Raw | ConvertFrom-Json }
    catch { throw "Migration catalog is invalid JSON: $($_.Exception.Message)" }
    Test-NativeMigrationCatalog -Catalog $catalog -Templates $TemplateRoot -Root $ProjectRoot
    $folderDefinition = Get-GddScaffoldingDefinition -Root $ProjectRoot

    $githubDirectory = Join-Path $ProjectRoot ".github"
    $githubInstructionsDirectory = Join-Path $ProjectRoot ".github/instructions"
    $docsDirectory = Join-Path $ProjectRoot "Docs"
    $gameDesignDirectory = Join-Path $ProjectRoot "Docs/GameDesign"
    $managedDirectories = @(
        @{ Path = $githubDirectory; Relative = ".github"; Profile = "native-entry" },
        @{ Path = $githubInstructionsDirectory; Relative = ".github/instructions"; Profile = "native-entry" },
        @{ Path = $docsDirectory; Relative = "Docs"; Profile = "gdd-scaffolding" },
        @{ Path = $gameDesignDirectory; Relative = "Docs/GameDesign"; Profile = "gdd-scaffolding" }
    )
    foreach ($directory in $managedDirectories) {
        if (Test-HasReparsePoint -Candidate $directory.Path -Root $ProjectRoot) { throw "Managed setup directory uses a reparse point and is unsafe: $($directory.Path)" }
        if ((Test-Path -LiteralPath $directory.Path) -and -not (Test-Path -LiteralPath $directory.Path -PathType Container)) {
            throw "A file blocks required managed directory '$($directory.Relative)'. No setup files were changed."
        }
    }
    $scaffolds = @(
        @{ Source = "GameDesign/README.md"; Target = "Docs/GameDesign/README.md" },
        @{ Source = "GameDesign/GameDesignManifest.md"; Target = "Docs/GameDesign/GameDesignManifest.md" }
    )
    foreach ($scaffold in $scaffolds) {
        $sourcePath = Get-FullPath -Path $scaffold.Source -BasePath $TemplateRoot
        $targetPath = Get-FullPath -Path $scaffold.Target -BasePath $ProjectRoot
        if (-not (Test-IsContainedPath -Candidate $sourcePath -Root $TemplateRoot) -or -not (Test-Path -LiteralPath $sourcePath -PathType Leaf) -or (Test-HasReparsePoint -Candidate $sourcePath -Root $TemplateRoot)) { throw "Scaffold template path is missing or unsafe: $sourcePath" }
        if (-not (Test-IsContainedPath -Candidate $targetPath -Root $ProjectRoot) -or (Test-HasReparsePoint -Candidate $targetPath -Root $ProjectRoot)) { throw "Scaffold target path is unsafe: $targetPath" }
        if ((Test-Path -LiteralPath $targetPath) -and -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) { throw "A directory blocks scaffold target '$($scaffold.Target)'. No setup files were changed." }
    }
    foreach ($entry in @($catalog.entries)) {
        $sourcePath = Get-FullPath -Path ([string]$entry.templatePath).Replace('/', [System.IO.Path]::DirectorySeparatorChar) -BasePath $TemplateRoot
        $targetPath = Get-FullPath -Path ([string]$entry.targetPath).Replace('/', [System.IO.Path]::DirectorySeparatorChar) -BasePath $ProjectRoot
        if ((Test-Path -LiteralPath $targetPath) -and -not (Test-Path -LiteralPath $targetPath -PathType Leaf)) { throw "A directory blocks native instruction target '$($entry.targetPath)'. No setup files were changed." }
        $templateText = [System.IO.File]::ReadAllText($sourcePath)
        if (-not $templateText.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md")) { throw "Template does not route through the canonical AI entry point: $sourcePath" }
        $templateRegions = Get-ManagedRegions -Text $templateText
        if ($templateRegions.Count -eq 0 -or @($templateRegions | Where-Object { $_.ActualHash -ne $_.DeclaredHash }).Count -gt 0) { throw "Native instruction template managed regions are missing or invalid: $sourcePath" }
    }

    foreach ($directory in $managedDirectories) {
        if (Test-Path -LiteralPath $directory.Path -PathType Container) {
            Add-Result "Preserved" $directory.Relative "Authorized $($directory.Profile) directory already exists." $null
        }
        else {
            New-Item -ItemType Directory -Path $directory.Path -ErrorAction Stop | Out-Null
            Add-Result "Created" $directory.Relative "Created under $($directory.Profile) delegation from folder definition $($folderDefinition.definitionVersion)." $null
        }
    }

    foreach ($entry in @($catalog.entries)) {
        Update-NativeEntry -Entry $entry -Templates $TemplateRoot -Root $ProjectRoot
    }

    if (Test-Path -LiteralPath $gameDesignDirectory -PathType Container) {
        foreach ($scaffold in $scaffolds) {
            $sourcePath = Get-FullPath -Path $scaffold.Source -BasePath $TemplateRoot
            $targetPath = Get-FullPath -Path $scaffold.Target -BasePath $ProjectRoot
            if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Scaffold template is missing: $sourcePath" }
            if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
                Add-Result "Preserved" $scaffold.Target "Existing project-specific content was not overwritten." $null
            }
            elseif (Test-Path -LiteralPath $targetPath) {
                Add-Result "Conflicted" $scaffold.Target "A directory exists where the scaffold file is required." $null
            }
            else {
                Write-AtomicText -Path $targetPath -Text ([System.IO.File]::ReadAllText($sourcePath))
                Add-Result "Created" $scaffold.Target "Created missing scaffold from the controlled template." $null
            }
        }

        if (-not $SkipGameDesignManifestUpdate) {
            $manifestUpdater = Join-Path $PSScriptRoot "UpdateGameDesignManifest.ps1"
            $manifestArguments = @("-ProjectRoot", $ProjectRoot)
            if ($OutputFormat -eq "Json") { $manifestArguments += @("-OutputFormat", "Json") }
            $manifestRun = Invoke-ChildPowerShell -ScriptPath $manifestUpdater -Arguments $manifestArguments -EmitOutput ($OutputFormat -eq "Text")
            if ($OutputFormat -eq "Json") {
                try { $manifestResult = $manifestRun.Output | ConvertFrom-Json }
                catch { throw "Game Design Manifest maintenance returned invalid JSON." }
            }
            if ($manifestRun.Code -ne 0) {
                Add-Result "Conflicted" "Docs/GameDesign/GameDesignManifest.md" "Deterministic manifest maintenance reported a conflict." $null
            }
        }
    }

    $counts = @{}
    foreach ($name in @("created", "updated", "preserved", "skipped", "conflicted")) {
        $counts[$name] = @($results | Where-Object { $_.status -eq $name }).Count
    }
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{
            status = $(if ($counts.conflicted -gt 0) { "CONFLICTED" } else { "OK" })
            projectRoot = $ProjectRoot
            counts = $counts
            results = $results.ToArray()
            documentation = $documentationResult
            gameDesignManifest = $manifestResult
        } | ConvertTo-Json -Depth 7
    }
    else {
        Write-Host ("Setup summary: created={0}, updated={1}, preserved={2}, skipped={3}, conflicted={4}" -f $counts.created, $counts.updated, $counts.preserved, $counts.skipped, $counts.conflicted)
    }
    if ($counts.conflicted -gt 0) { exit 2 }
    exit 0
}
catch {
    $failureLocation = if ($_.InvocationInfo.ScriptLineNumber) { " (line $($_.InvocationInfo.ScriptLineNumber))" } else { "" }
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{ status = "FAILED"; message = ($_.Exception.Message + $failureLocation); results = $results.ToArray(); documentation = $documentationResult; gameDesignManifest = $manifestResult } | ConvertTo-Json -Depth 7
    }
    else {
        Write-Host "AI ENTRY SETUP FAILED: $($_.Exception.Message)$failureLocation" -ForegroundColor Red
    }
    exit 1
}
