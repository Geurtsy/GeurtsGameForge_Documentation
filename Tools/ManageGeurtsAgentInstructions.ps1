# ManageGeurtsAgentInstructions.ps1
# Version: 0.12.1

[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$TemplateRoot,
    [string]$MigrationCatalogPath,
    [switch]$IncludeGameDesignScaffolding,
    [switch]$UpdateGameDesignManifest,
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$results = New-Object System.Collections.Generic.List[object]
$manifestResult = $null
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$htmlMarkerPattern = '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[^"]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*-->\r?\n(?<Body>.*?)^<!--\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*-->[^\S\r\n]*(?=\r?\n|\z)'
$yamlMarkerPattern = '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[^"]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*\r?\n(?<Body>.*?)^#\s*GEURTS-MANAGED-END\s+id="\k<Id>"[^\S\r\n]*(?=\r?\n|\z)'

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
    return $normalized.TrimEnd("`n") + "`n"
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

function Get-ByteHash([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace("-", "").ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-FileByteHash([string]$Path) {
    return Get-ByteHash -Bytes ([System.IO.File]::ReadAllBytes($Path))
}

function Convert-Newlines([string]$Text, [string]$Newline) {
    return (($Text -replace "`r`n", "`n") -replace "`r", "`n").Replace("`n", $Newline)
}

function Get-NewlineConvention([string]$Text) {
    if ($Text.Contains("`r`n")) { return "`r`n" }
    return "`n"
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

function Read-ManagedTextFile([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $offset = 0
    $encoding = $null
    if ($bytes.Length -ge 4 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) -or ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF))) {
        throw "Unsupported UTF-32 encoding; no content was overwritten."
    }
    elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $offset = 3
        $encoding = New-Object System.Text.UTF8Encoding($true, $true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $offset = 2
        $encoding = New-Object System.Text.UnicodeEncoding($false, $true, $true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $offset = 2
        $encoding = New-Object System.Text.UnicodeEncoding($true, $true, $true)
    }
    else {
        $encoding = New-Object System.Text.UTF8Encoding($false, $true)
    }
    try { $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset) }
    catch { throw "Unsupported or invalid text encoding; no content was overwritten." }
    return [pscustomobject]@{ Text = $text; Encoding = $encoding; ByteHash = (Get-ByteHash -Bytes $bytes) }
}

function Invoke-TestWriteBarrier([string]$TargetPath) {
    $barrierPath = [Environment]::GetEnvironmentVariable("GEURTS_TEST_WRITE_BARRIER_PATH")
    $barrierTarget = [Environment]::GetEnvironmentVariable("GEURTS_TEST_WRITE_BARRIER_TARGET")
    if ([string]::IsNullOrWhiteSpace($barrierPath) -or [string]::IsNullOrWhiteSpace($barrierTarget)) { return }
    $fullTarget = [System.IO.Path]::GetFullPath($TargetPath)
    if (-not $fullTarget.Equals([System.IO.Path]::GetFullPath($barrierTarget), [System.StringComparison]::OrdinalIgnoreCase)) { return }
    $fullBarrier = [System.IO.Path]::GetFullPath($barrierPath)
    $temporaryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullBarrier.StartsWith($temporaryRoot, [System.StringComparison]::OrdinalIgnoreCase)) { throw "Automation test write barrier must remain below the system temporary directory." }
    $readyPath = $fullBarrier + ".ready"
    $continuePath = $fullBarrier + ".continue"
    [System.IO.File]::WriteAllText($readyPath, "ready", $utf8NoBom)
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    while (-not (Test-Path -LiteralPath $continuePath -PathType Leaf)) {
        if ([DateTime]::UtcNow -ge $deadline) { throw "Automation test write barrier timed out." }
        Start-Sleep -Milliseconds 20
    }
    Remove-Item -LiteralPath $continuePath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $readyPath -Force -ErrorAction SilentlyContinue
}

function Write-AtomicText(
    [string]$Path,
    [string]$Text,
    [string]$AllowedRoot,
    [ValidateSet("Absent", "Existing")][string]$ExpectedState,
    [string]$ExpectedByteHash,
    [System.Text.Encoding]$Encoding = $null
) {
    if ($null -eq $Encoding) { $Encoding = $utf8NoBom }
    $directory = [System.IO.Path]::GetFullPath((Split-Path -Parent $Path))
    $initialRoot = [System.IO.Path]::GetFullPath($AllowedRoot)
    $parentIsRootOrContained = $directory.Equals($initialRoot, [System.StringComparison]::OrdinalIgnoreCase) -or (Test-IsContainedPath -Candidate $directory -Root $initialRoot)
    if (-not $parentIsRootOrContained -or (Test-HasReparsePoint -Candidate $directory -Root $initialRoot) -or -not (Test-Path -LiteralPath $directory -PathType Container)) {
        throw "Atomic target parent must already exist safely below the validated project root."
    }
    # Keep transaction artifacts at the validated root so a late swap of the
    # target's parent cannot redirect or strand them through a reparse point.
    $temporary = Join-Path $AllowedRoot (".ggf-write-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    $replacementBackup = Join-Path $AllowedRoot (".ggf-replace-" + [Guid]::NewGuid().ToString("N") + ".bak")
    try {
        [System.IO.File]::WriteAllText($temporary, $Text, $Encoding)
        Invoke-TestWriteBarrier -TargetPath $Path
        $resolvedTarget = [System.IO.Path]::GetFullPath($Path)
        $resolvedRoot = [System.IO.Path]::GetFullPath($AllowedRoot)
        if (-not (Test-IsContainedPath -Candidate $resolvedTarget -Root $resolvedRoot) -or (Test-HasReparsePoint -Candidate $resolvedTarget -Root $resolvedRoot)) { throw "Target path changed or uses an unsafe reparse point immediately before promotion." }
        if ($ExpectedState -ceq "Absent") {
            if (Test-Path -LiteralPath $resolvedTarget) { throw "Target appeared after preflight; concurrent content was preserved." }
            [System.IO.File]::Move($temporary, $resolvedTarget)
        }
        else {
            if (-not (Test-Path -LiteralPath $resolvedTarget -PathType Leaf)) { throw "Target disappeared or changed type after it was read." }
            if ([string]::IsNullOrWhiteSpace($ExpectedByteHash) -or (Get-FileByteHash -Path $resolvedTarget) -cne $ExpectedByteHash) { throw "Target bytes changed after they were read; concurrent content was preserved." }
            [System.IO.File]::Replace($temporary, $resolvedTarget, $replacementBackup)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $replacementBackup) { Remove-Item -LiteralPath $replacementBackup -Force -ErrorAction SilentlyContinue }
    }
}

function New-Backup([string]$TargetPath, [string]$AllowedRoot, [string]$ExpectedByteHash) {
    $base = "$TargetPath.pre-v0.9.0.bak"
    $backup = $base
    $index = 1
    while (Test-Path -LiteralPath $backup) {
        $backup = "$base.$index"
        $index++
    }
    $root = [System.IO.Path]::GetFullPath($AllowedRoot)
    $source = [System.IO.Path]::GetFullPath($TargetPath)
    $temporary = Join-Path $root (".ggf-backup-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    try {
        if (-not (Test-IsContainedPath -Candidate $source -Root $root) -or (Test-HasReparsePoint -Candidate $source -Root $root) -or -not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Backup source is missing or unsafe."
        }
        if ([string]::IsNullOrWhiteSpace($ExpectedByteHash) -or (Get-FileByteHash -Path $source) -cne $ExpectedByteHash) {
            throw "Target bytes changed before backup capture; concurrent content was preserved."
        }
        [System.IO.File]::Copy($source, $temporary, $false)
        if ((Get-FileByteHash -Path $temporary) -cne $ExpectedByteHash) { throw "Backup capture did not match the validated target bytes." }

        Invoke-TestWriteBarrier -TargetPath $backup
        $finalSource = [System.IO.Path]::GetFullPath($TargetPath)
        $finalBackup = [System.IO.Path]::GetFullPath($backup)
        $finalRoot = [System.IO.Path]::GetFullPath($AllowedRoot)
        if (-not (Test-IsContainedPath -Candidate $finalSource -Root $finalRoot) -or -not (Test-IsContainedPath -Candidate $finalBackup -Root $finalRoot) -or (Test-HasReparsePoint -Candidate $finalSource -Root $finalRoot) -or (Test-HasReparsePoint -Candidate $finalBackup -Root $finalRoot)) {
            throw "Backup path changed or uses an unsafe reparse point immediately before promotion."
        }
        if (-not (Test-Path -LiteralPath $finalSource -PathType Leaf) -or (Get-FileByteHash -Path $finalSource) -cne $ExpectedByteHash) {
            throw "Target bytes changed before backup promotion; concurrent content was preserved."
        }
        if (Test-Path -LiteralPath $finalBackup) { throw "Backup target appeared after preflight; it was preserved." }
        [System.IO.File]::Move($temporary, $finalBackup)
        return $finalBackup
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
    }
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

function Assert-UnityProjectRoot([string]$Root) {
    $toolContainer = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    if ($Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar).Equals($toolContainer, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Project root must not be the documentation source or project-local fetched documentation copy: $Root"
    }
    foreach ($marker in @("Assets", "Packages", "ProjectSettings")) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $marker) -PathType Container)) {
            throw "Project root must be explicit and identify a Unity project containing Assets, Packages, and ProjectSettings: $Root"
        }
    }
}

function Get-CurrentNativeTemplateVersion($Entry) {
    return "1.1.0"
}

function Test-NativeTemplateRoute($Entry, [string]$Text) {
    if (-not $Text.Contains("GeurtsGameForgeDocumentation/AI_READ_FIRST.md") -or $Text.Contains("GeurtsGameForgeDocumentation/AGENTS.md")) { return $false }
    if (-not $Text.Contains("Before planning or modifying any Geurts Game Forge brick code") -or -not $Text.Contains("installed, manifest-selected documentation") -or -not $Text.Contains("source of truth")) { return $false }
    return -not $Text.Contains("owns the complete documentation chain")
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
        ".github/copilot-instructions.md" = @{ Template = "copilot-instructions.md"; Hashes = @{ "0.4.0" = "d72006b497ed12ae97ef3d4ef9248f634af7159b7011434987ea3bd60cbd8da7"; "0.5.0" = "d72006b497ed12ae97ef3d4ef9248f634af7159b7011434987ea3bd60cbd8da7"; "0.6.0" = "cfeb6826447b74d391c7afa40f07e19171086ee0f6e8a107887360fa4e6fd7e3" } }
        ".github/instructions/geurts-unity.instructions.md" = @{ Template = "instructions/geurts-unity.instructions.md"; Hashes = @{ "0.4.0" = "27bff44e8cd8a26962b2b2890b3ca6c02a5a1ee6c0531c195514d70b9ffde92f"; "0.5.0" = "27bff44e8cd8a26962b2b2890b3ca6c02a5a1ee6c0531c195514d70b9ffde92f"; "0.6.0" = "799fe2cc0a720cd5e9f7f350b7480d219c0f92309a4a6201953e3a452faa0fa3" } }
        ".github/instructions/geurts-game-design.instructions.md" = @{ Template = "instructions/geurts-game-design.instructions.md"; Hashes = @{ "0.4.0" = "724549bbd75e2ed1f83167992747f5b56adac9d0b4e40886085b65d497cddbd9"; "0.5.0" = "724549bbd75e2ed1f83167992747f5b56adac9d0b4e40886085b65d497cddbd9"; "0.6.0" = "2805d6be2804eff71668625a83725d02338070a9b6988bde20bc521d455d17c0" } }
    }
    if ([string]$Catalog.schemaVersion -cne "2.0.0" -or [string]$Catalog.normalization -cne "utf8-text-with-lf-newlines-and-terminal-lf" -or @($Catalog.entries).Count -ne 3) {
        throw "Migration catalog metadata does not match the exact v2.0.0 contract."
    }
    $seenTargets = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($entry in @($Catalog.entries)) {
        $expectedEntryFields = @("legacyFingerprints", "targetPath", "templatePath")
        $actualEntryFields = @($entry.PSObject.Properties | Select-Object -ExpandProperty Name | Sort-Object)
        if ($actualEntryFields.Count -ne $expectedEntryFields.Count) { throw "Migration catalog entry shape is invalid." }
        for ($fieldIndex = 0; $fieldIndex -lt $expectedEntryFields.Count; $fieldIndex++) {
            if ([string]$actualEntryFields[$fieldIndex] -cne [string]$expectedEntryFields[$fieldIndex]) { throw "Migration catalog entry shape is invalid." }
        }
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
        foreach ($version in @($expected[$target].Hashes.Keys)) { if (-not $seenVersions.Contains([string]$version)) { throw "Migration catalog is missing '$target' version '$version'." } }

    }
    foreach ($target in $expected.Keys) { if (-not $seenTargets.Contains($target)) { throw "Migration catalog is missing native target '$target'." } }
}

function Get-ManagedFolderDefinition([string]$Root, [bool]$IncludeGameDesign) {
    $definitionCandidates = @(
        (Join-Path $Root "GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureDefinition.json"),
        (Join-Path (Split-Path -Parent $PSScriptRoot) "GeurtsTechniques/GeurtsFolderStructureDefinition.json")
    )
    $definitionPath = $definitionCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace([string]$definitionPath)) {
        throw "The authoritative folder definition is required before creating managed setup folders."
    }
    $definitionTrustRoot = if (Test-IsContainedPath -Candidate ([System.IO.Path]::GetFullPath($definitionPath)) -Root $Root) { $Root } else { Split-Path -Parent $PSScriptRoot }
    if (Test-HasReparsePoint -Candidate ([System.IO.Path]::GetFullPath($definitionPath)) -Root $definitionTrustRoot) { throw "The authoritative folder definition uses an unsafe reparse point." }

    try { $definition = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json }
    catch { throw "The authoritative folder definition is invalid JSON: $($_.Exception.Message)" }
    if ([string]$definition.definitionVersion -ne "0.10.0" -or [string]$definition.packageVersion -ne "0.12.1") {
        throw "Managed setup requires folder definition v0.10.0 from package v0.12.1."
    }

    $requiredProfiles = @("native-entry")
    if ($IncludeGameDesign) { $requiredProfiles += "gdd-scaffolding" }
    foreach ($profileId in $requiredProfiles) {
        $profiles = @($definition.creationProfiles | Where-Object { [string]$_.id -ceq $profileId })
        if ($profiles.Count -ne 1 -or [string]$profiles[0].owner -cne "native-entry-manager") {
            throw "The folder definition does not assign '$profileId' to native-entry-manager."
        }
    }
    $expectedFolders = @(
        @{ Path = ".github"; Parent = ""; Profile = "native-entry"; Delegated = $false },
        @{ Path = ".github/instructions"; Parent = ".github"; Profile = "native-entry"; Delegated = $false }
    )
    if ($IncludeGameDesign) {
        $expectedFolders += @(
            @{ Path = "Docs"; Parent = ""; Profile = "gdd-scaffolding"; Delegated = $true },
            @{ Path = "Docs/GameDesign"; Parent = "Docs"; Profile = "gdd-scaffolding"; Delegated = $true }
        )
    }
    foreach ($expected in $expectedFolders) {
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
    $currentTemplateVersion = Get-CurrentNativeTemplateVersion -Entry $Entry
    if (-not (Test-NativeTemplateRoute -Entry $Entry -Text $templateText)) {
        throw "Template does not use its required concise documentation route: $templatePath"
    }
    $templateRegions = Get-ManagedRegions -Text $templateText
    if ($templateRegions.Count -eq 0) { throw "Template has no managed regions: $templatePath" }
    foreach ($region in $templateRegions) {
        if ($region.Version -cne $currentTemplateVersion) {
            throw "Template managed region '$($region.Id)' must use current version '$currentTemplateVersion'."
        }
        if ($region.ActualHash -ne $region.DeclaredHash) {
            throw "Template managed-region hash is invalid for '$($region.Id)'."
        }
    }

    if (-not (Test-Path -LiteralPath $targetPath)) {
        try { Write-AtomicText -Path $targetPath -Text $templateText -AllowedRoot $Root -ExpectedState "Absent" }
        catch {
            Add-Result "Conflicted" ([string]$Entry.targetPath) ("Managed entry creation lost its expected-absent state: " + $_.Exception.Message) $null
            return
        }
        Add-Result "Created" ([string]$Entry.targetPath) "Installed managed v$currentTemplateVersion entry." $null
        return
    }
    if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
        Add-Result "Conflicted" ([string]$Entry.targetPath) "A directory exists where a native instruction file is required." $null
        return
    }

    try { $targetFile = Read-ManagedTextFile -Path $targetPath }
    catch {
        Add-Result "Conflicted" ([string]$Entry.targetPath) $_.Exception.Message $null
        return
    }
    $targetText = [string]$targetFile.Text
    $targetEncoding = $targetFile.Encoding
    $targetByteHash = [string]$targetFile.ByteHash
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
            $supportedTargetVersions = @("0.7.0", "0.9.0", "1.0.0", "1.1.0")
            if ($supportedTargetVersions -notcontains $region.Version) {
                Add-Result "Conflicted" ([string]$Entry.targetPath) "Managed region '$($region.Id)' uses unsupported version '$($region.Version)'; no downgrade or overwrite occurred." $null
                return
            }
        }

        $updatedText = $targetText
        foreach ($region in @($targetRegions | Sort-Object Index -Descending)) {
            $replacement = Convert-Newlines -Text $templateById[$region.Id].FullText -Newline (Get-NewlineConvention -Text $region.FullText)
            $updatedText = $updatedText.Substring(0, $region.Index) + $replacement + $updatedText.Substring($region.Index + $region.Length)
        }
        if ($updatedText -ceq $targetText) {
            Add-Result "Preserved" ([string]$Entry.targetPath) "Managed content is current; user content outside markers is unchanged." $null
            return
        }

        $backup = $null
        try {
            $backup = New-Backup -TargetPath $targetPath -AllowedRoot $Root -ExpectedByteHash $targetByteHash
            Write-AtomicText -Path $targetPath -Text $updatedText -AllowedRoot $Root -ExpectedState "Existing" -ExpectedByteHash $targetByteHash -Encoding $targetEncoding
        }
        catch {
            $backupDetail = if ([string]::IsNullOrWhiteSpace([string]$backup)) { " No safety backup was promoted." } else { " The safety backup was preserved." }
            Add-Result "Conflicted" ([string]$Entry.targetPath) ("Atomic managed update failed: " + $_.Exception.Message + " The target was preserved." + $backupDetail) $backup
            return
        }
        Add-Result "Updated" ([string]$Entry.targetPath) "Refreshed managed regions and preserved content outside markers." $backup
        return
    }

    $targetHash = Get-TextHash -Text $targetText
    $knownLegacy = @($Entry.legacyFingerprints | Where-Object { ([string]$_.sha256).ToLowerInvariant() -eq $targetHash }).Count -gt 0
    if ($knownLegacy) {
        $legacyReplacement = Convert-Newlines -Text $templateText -Newline (Get-NewlineConvention -Text $targetText)
        $backup = $null
        try {
            $backup = New-Backup -TargetPath $targetPath -AllowedRoot $Root -ExpectedByteHash $targetByteHash
            Write-AtomicText -Path $targetPath -Text $legacyReplacement -AllowedRoot $Root -ExpectedState "Existing" -ExpectedByteHash $targetByteHash -Encoding $targetEncoding
        }
        catch {
            $backupDetail = if ([string]::IsNullOrWhiteSpace([string]$backup)) { " No safety backup was promoted." } else { " The safety backup was preserved." }
            Add-Result "Conflicted" ([string]$Entry.targetPath) ("Legacy migration failed: " + $_.Exception.Message + " The target was preserved." + $backupDetail) $backup
            return
        }
        Add-Result "Updated" ([string]$Entry.targetPath) "Migrated an exact known legacy template to managed v$currentTemplateVersion content." $backup
        return
    }

    if ($targetText -match '(?im)^\s*(?:\*\*)?Version\s*:?\s*(?:\*\*)?\s*v?0\.[456](?:\.0)?' -and $targetText -match '(?i)Geurts') {
        Add-Result "Conflicted" ([string]$Entry.targetPath) "This appears to be a user-modified legacy Geurts file. Migrate it manually or restore an exact known template." $null
        return
    }

    if ($targetText -match '(?m)^<!--\s*[A-Z0-9_-]+_(?:START|END)\s*-->\s*$') {
        Add-Result "Conflicted" ([string]$Entry.targetPath) "An unknown product- or user-owned managed block was preserved without changes." $null
        return
    }
    Add-Result "Skipped" ([string]$Entry.targetPath) "User-owned unmarked file was preserved without changes." $null
}

try {
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { throw "-ProjectRoot is required for managed entry setup; the tool will not infer a Unity project from its own Tools location." }
    $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Project root does not exist: $ProjectRoot" }
    Assert-UnityProjectRoot -Root $ProjectRoot

    if ([string]::IsNullOrWhiteSpace($TemplateRoot)) { $TemplateRoot = Join-Path $PSScriptRoot "AIAgentInstructionTemplates" }
    else { $TemplateRoot = Get-FullPath -Path $TemplateRoot -BasePath $ProjectRoot }
    if ([string]::IsNullOrWhiteSpace($MigrationCatalogPath)) { $MigrationCatalogPath = Join-Path $PSScriptRoot "NativeEntryMigrationCatalog.json" }
    else { $MigrationCatalogPath = Get-FullPath -Path $MigrationCatalogPath -BasePath $ProjectRoot }
    if (-not (Test-Path -LiteralPath $TemplateRoot -PathType Container)) { throw "Template directory is missing: $TemplateRoot" }
    if (-not (Test-Path -LiteralPath $MigrationCatalogPath -PathType Leaf)) { throw "Migration catalog is missing: $MigrationCatalogPath" }

    try { $catalog = Get-Content -LiteralPath $MigrationCatalogPath -Raw | ConvertFrom-Json }
    catch { throw "Migration catalog is invalid JSON: $($_.Exception.Message)" }
    Test-NativeMigrationCatalog -Catalog $catalog -Templates $TemplateRoot -Root $ProjectRoot
    $folderDefinition = Get-ManagedFolderDefinition -Root $ProjectRoot -IncludeGameDesign ([bool]$IncludeGameDesignScaffolding)

    $githubDirectory = Join-Path $ProjectRoot ".github"
    $githubInstructionsDirectory = Join-Path $ProjectRoot ".github/instructions"
    $docsDirectory = Join-Path $ProjectRoot "Docs"
    $gameDesignDirectory = Join-Path $ProjectRoot "Docs/GameDesign"
    $managedDirectories = @(
        @{ Path = $githubDirectory; Relative = ".github"; Profile = "native-entry" },
        @{ Path = $githubInstructionsDirectory; Relative = ".github/instructions"; Profile = "native-entry" }
    )
    if ($IncludeGameDesignScaffolding) {
        $managedDirectories += @(
            @{ Path = $docsDirectory; Relative = "Docs"; Profile = "gdd-scaffolding" },
            @{ Path = $gameDesignDirectory; Relative = "Docs/GameDesign"; Profile = "gdd-scaffolding" }
        )
    }
    foreach ($directory in $managedDirectories) {
        if (Test-HasReparsePoint -Candidate $directory.Path -Root $ProjectRoot) { throw "Managed setup directory uses a reparse point and is unsafe: $($directory.Path)" }
        if ((Test-Path -LiteralPath $directory.Path) -and -not (Test-Path -LiteralPath $directory.Path -PathType Container)) {
            throw "A file blocks required managed directory '$($directory.Relative)'. No setup files were changed."
        }
    }
    $scaffolds = @()
    if ($IncludeGameDesignScaffolding) {
        $scaffolds = @(
            @{ Source = "GameDesign/README.md"; Target = "Docs/GameDesign/README.md" },
            @{ Source = "GameDesign/GameDesignManifest.md"; Target = "Docs/GameDesign/GameDesignManifest.md" }
        )
    }
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
        $currentTemplateVersion = Get-CurrentNativeTemplateVersion -Entry $entry
        if (-not (Test-NativeTemplateRoute -Entry $entry -Text $templateText)) { throw "Template does not use its required concise documentation route: $sourcePath" }
        $templateRegions = Get-ManagedRegions -Text $templateText
        if ($templateRegions.Count -eq 0 -or @($templateRegions | Where-Object { $_.ActualHash -ne $_.DeclaredHash -or $_.Version -cne $currentTemplateVersion }).Count -gt 0) { throw "Native instruction template managed regions are missing, invalid, or use the wrong current version: $sourcePath" }
    }

    foreach ($directory in $managedDirectories) {
        Invoke-TestWriteBarrier -TargetPath $directory.Path
        $finalDirectoryPath = [System.IO.Path]::GetFullPath([string]$directory.Path)
        $finalProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
        if (-not (Test-IsContainedPath -Candidate $finalDirectoryPath -Root $finalProjectRoot) -or (Test-HasReparsePoint -Candidate $finalDirectoryPath -Root $finalProjectRoot)) {
            throw "Managed setup directory changed or uses a reparse point immediately before acceptance or creation: $($directory.Relative)"
        }
        if (Test-Path -LiteralPath $finalDirectoryPath -PathType Container) {
            Add-Result "Preserved" $directory.Relative "Authorized $($directory.Profile) directory already exists." $null
        }
        elseif (Test-Path -LiteralPath $finalDirectoryPath) {
            throw "A file blocks required managed directory '$($directory.Relative)'. No setup files were changed."
        }
        else {
            New-Item -ItemType Directory -Path $finalDirectoryPath -ErrorAction Stop | Out-Null
            Add-Result "Created" $directory.Relative "Created under $($directory.Profile) delegation from folder definition $($folderDefinition.definitionVersion)." $null
        }
    }

    foreach ($entry in @($catalog.entries)) {
        Update-NativeEntry -Entry $entry -Templates $TemplateRoot -Root $ProjectRoot
    }

    if ($IncludeGameDesignScaffolding -and (Test-Path -LiteralPath $gameDesignDirectory -PathType Container)) {
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
                try {
                    Write-AtomicText -Path $targetPath -Text ([System.IO.File]::ReadAllText($sourcePath)) -AllowedRoot $ProjectRoot -ExpectedState "Absent"
                    Add-Result "Created" $scaffold.Target "Created missing scaffold from the controlled template." $null
                }
                catch { Add-Result "Conflicted" $scaffold.Target ("Scaffold creation lost its expected-absent state: " + $_.Exception.Message) $null }
            }
        }

    }

    if ($UpdateGameDesignManifest) {
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
        [pscustomobject]@{ status = "FAILED"; message = ($_.Exception.Message + $failureLocation); results = $results.ToArray(); gameDesignManifest = $manifestResult } | ConvertTo-Json -Depth 7
    }
    else {
        Write-Host "AI ENTRY SETUP FAILED: $($_.Exception.Message)$failureLocation" -ForegroundColor Red
    }
    exit 1
}
