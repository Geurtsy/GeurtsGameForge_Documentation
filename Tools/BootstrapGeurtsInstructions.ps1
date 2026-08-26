# BootstrapGeurtsInstructions.ps1
# Version: 0.8.0

[CmdletBinding()]
param(
    [ValidateSet("Check", "Update", "Validate")]
    [string]$Mode = "Update",
    [string]$ConfigPath,
    [string]$ProjectRoot,
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$exitCodes = @{
    CONFIGURATION = 10
    DEPENDENCY = 11
    AUTHENTICATION = 20
    NETWORK = 21
    REMOTE = 22
    CHECKOUT = 30
    VALIDATION = 31
    CONFLICT = 32
    FILE_LOCK = 33
    FILESYSTEM = 34
    UNKNOWN = 35
}
$script:StagePath = $null
$script:BackupPath = $null
$script:TargetPath = $null
$script:Promoted = $false
$script:ValidatedPackageVersion = $null
$script:SyncMutex = $null
$script:SyncMutexHeld = $false
$script:LastValidCopyConfirmed = $false
$script:SuccessWarnings = New-Object System.Collections.Generic.List[string]

function Stop-Bootstrap([string]$Category, [string]$Message) {
    $exception = New-Object System.InvalidOperationException($Message)
    $exception.Data["BootstrapCategory"] = $Category
    throw $exception
}

function Get-FullPath([string]$Path, [string]$BasePath) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Get-SyncLockName([string]$TargetPath) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $normalizedTarget = $TargetPath.Replace('\', '/').ToLowerInvariant()
        $hash = ([System.BitConverter]::ToString($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalizedTarget)))).Replace("-", "").ToLowerInvariant()
        return "ggf-documentation-sync-$hash"
    }
    finally { $sha.Dispose() }
}

function Enter-SyncLock([string]$TargetPath) {
    $mutex = New-Object System.Threading.Mutex($false, (Get-SyncLockName -TargetPath $TargetPath))
    $acquired = $false
    try { $acquired = $mutex.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] { $acquired = $true }
    if (-not $acquired) {
        $mutex.Dispose()
        Stop-Bootstrap "FILE_LOCK" "Another documentation synchronization operation is already using this project target. Retry after it completes."
    }
    $script:SyncMutexHeld = $true
    return $mutex
}

function Exit-SyncLock {
    if ($script:SyncMutex) {
        if ($script:SyncMutexHeld) {
            try { $script:SyncMutex.ReleaseMutex() }
            catch { }
        }
        $script:SyncMutex.Dispose()
    }
    $script:SyncMutex = $null
    $script:SyncMutexHeld = $false
}

function Test-IsContainedPath([string]$Candidate, [string]$Root) {
    $rootWithSeparator = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-HasReparsePoint([string]$Candidate, [string]$Root) {
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

function Invoke-Git([string[]]$Arguments) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git @Arguments 2>&1)
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    return [pscustomobject]@{
        Code = $code
        Output = ($output -join [Environment]::NewLine).Trim()
    }
}

function Get-GitFailureCategory([string]$Output, [string]$DefaultCategory) {
    if ($Output -match '(?i)authentication failed|could not read username|permission denied|repository not found|access denied|http.*(?:401|403)|terminal prompts disabled') {
        return "AUTHENTICATION"
    }
    if ($Output -match '(?i)could not resolve host|failed to connect|connection.*(?:timed out|reset|refused)|network is unreachable|unable to access.*proxy') {
        return "NETWORK"
    }
    if ($Output -match '(?i)tls|ssl certificate|certificate problem|server certificate verification failed|schannel|http[^\r\n]*(?:500|502|503|504)|service unavailable|bad gateway|gateway timeout') {
        return "NETWORK"
    }
    if ($Output -match '(?i)unable to create.*lock|could not lock|permission denied.*\.lock|being used by another process') {
        return "FILE_LOCK"
    }
    return $DefaultCategory
}

function Get-FilesystemFailureCategory([System.Exception]$Exception) {
    if ($Exception.Message -match '(?i)being used by another process|sharing violation|lock violation|cannot access.*because it is being used') { return "FILE_LOCK" }
    return "FILESYSTEM"
}

function Invoke-GitRequired([string[]]$Arguments, [string]$DefaultCategory, [string]$Operation) {
    $result = Invoke-Git -Arguments $Arguments
    if ($result.Code -ne 0) {
        $category = Get-GitFailureCategory -Output $result.Output -DefaultCategory $DefaultCategory
        $guidance = ""
        if ($category -eq "AUTHENTICATION") {
            $guidance = " Optional authentication failed against the public repository. Retry using anonymous read-only access without embedding credentials in the repository URL or logs."
        }
        Stop-Bootstrap -Category $category -Message ("{0} failed. {1}{2}" -f $Operation, $result.Output, $guidance)
    }
    return $result.Output
}

function Get-RequiredEntries($Config) {
    $entries = @($Config.requiredEntries)
    if ($entries.Count -ne 3) {
        Stop-Bootstrap "CONFIGURATION" "requiredEntries must contain exactly three entries."
    }

    $expected = @{
        "AI_READ_FIRST.md" = "file"
        "GeurtsTechniqueManifest.md" = "file"
        "GeurtsTechniques" = "directory"
    }
    foreach ($entry in $entries) {
        $path = [string]$entry.path
        $type = [string]$entry.type
        if (-not $expected.ContainsKey($path) -or $expected[$path] -ne $type) {
            Stop-Bootstrap "CONFIGURATION" "requiredEntries does not define the exact synchronized layout."
        }
    }
    return $entries
}

function Test-SparseConfiguration($Config) {
    $actual = @($Config.sparsePaths | Sort-Object)
    $expected = @("/AI_READ_FIRST.md", "/GeurtsTechniqueManifest.md", "/GeurtsTechniques/") | Sort-Object
    if ($actual.Count -ne $expected.Count) {
        Stop-Bootstrap "CONFIGURATION" "sparsePaths must contain exactly three canonical paths."
    }
    for ($index = 0; $index -lt $expected.Count; $index++) {
        if ($actual[$index] -cne $expected[$index]) {
            Stop-Bootstrap "CONFIGURATION" "sparsePaths must contain only the canonical visible layout."
        }
    }
}

function Test-SynchronizedFolderPath([string]$FolderPath) {
    if ([string]::IsNullOrWhiteSpace($FolderPath) -or [System.IO.Path]::IsPathRooted($FolderPath) -or $FolderPath.Contains('\') -or $FolderPath.StartsWith('/') -or $FolderPath.EndsWith('/')) { return $false }
    foreach ($segment in $FolderPath.Split('/')) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -in @('.', '..') -or $segment.EndsWith('.') -or $segment.EndsWith(' ') -or $segment.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) { return $false }
    }
    return $true
}

function Get-SynchronizedExpectedProfiles([string]$FolderPath) {
    if ($FolderPath -in @(".github", ".github/instructions")) { return @("native-entry") }
    if ($FolderPath -in @("GeurtsGameForgeDocumentation", "GeurtsGameForgeDocumentation/GeurtsTechniques")) { return @("documentation-sync") }
    if ($FolderPath -in @("Docs", "Docs/GameDesign")) { return @("full-project-structure", "gdd-scaffolding") }
    return @("full-project-structure")
}

function Get-SynchronizedDeclaredVersion([string]$FilePath) {
    if ([System.IO.Path]::GetExtension($FilePath) -ieq ".json") {
        try { $json = Get-Content -LiteralPath $FilePath -Raw | ConvertFrom-Json }
        catch { Stop-Bootstrap "VALIDATION" "Synchronized JSON is invalid: $FilePath" }
        return [string]$json.packageVersion
    }
    $text = [System.IO.File]::ReadAllText($FilePath)
    $versionMatch = [regex]::Match($text, '(?im)^\*\*Version:\*\*\s*v?(?<Version>[0-9]+(?:\.[0-9]+){1,2})\s*$')
    if (-not $versionMatch.Success) { return $null }
    return $versionMatch.Groups["Version"].Value
}

function Test-SynchronizedGitIgnoreTechnique([string]$Path) {
    $relativePath = "GeurtsTechniques/GeurtsGitIgnoreTechnique.md"
    $techniquePath = Join-Path $Path $relativePath
    if (-not (Test-Path -LiteralPath $techniquePath -PathType Leaf)) {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore technique is missing."
    }

    $bytes = [System.IO.File]::ReadAllBytes($techniquePath)
    $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $offset = 3 }
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try { $text = $strictUtf8.GetString($bytes, $offset, $bytes.Length - $offset) }
    catch { Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore technique is not valid UTF-8." }

    if ([regex]::Matches($text, 'GEURTS-GITIGNORE-BEGIN').Count -ne 1 -or [regex]::Matches($text, 'GEURTS-GITIGNORE-END').Count -ne 1) {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore technique must contain exactly one marker pair."
    }

    $pattern = '(?ms)^<!-- GEURTS-GITIGNORE-BEGIN version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)" target="(?<Target>[^"]+)" sha256="(?<Hash>[0-9a-f]{64})" -->\r?\n```gitignore\r?\n(?<Payload>.*?)^```\r?\n<!-- GEURTS-GITIGNORE-END -->(?:\r?\n)?\z'
    $matches = @([regex]::Matches($text, $pattern))
    if ($matches.Count -ne 1) {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore marker and fence grammar is invalid."
    }

    $match = $matches[0]
    $declaredVersion = Get-SynchronizedDeclaredVersion -FilePath $techniquePath
    if ($declaredVersion -cne "1.0.0" -or $match.Groups["Version"].Value -cne $declaredVersion -or $match.Groups["Target"].Value -cne ".gitignore") {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore version or target is invalid."
    }

    $payload = $match.Groups["Payload"].Value
    if ($payload.Length -gt 0 -and $payload[0] -eq [char]0xFEFF) {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore payload must not contain a byte-order mark."
    }
    $normalized = $payload -replace "`r`n", "`n" -replace "`r", "`n"
    if (-not $normalized.EndsWith("`n") -or $normalized.EndsWith("`n`n") -or [regex]::Matches($normalized, "`n").Count -ne 376) {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore payload must contain 376 logical lines and exactly one terminal newline."
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $actualHash = ([System.BitConverter]::ToString($sha.ComputeHash($strictUtf8.GetBytes($normalized)))).Replace("-", "").ToLowerInvariant()
    }
    finally { $sha.Dispose() }
    $expectedHash = "7223a9449718942d3a5cad00cf4d4e0dee9c89eb64951541fa4ebfb803acb45b"
    if ($match.Groups["Hash"].Value -cne $expectedHash -or $actualHash -cne $expectedHash) {
        Stop-Bootstrap "VALIDATION" "The synchronized custom .gitignore payload hash is invalid."
    }

    $contractPath = Join-Path $Path "GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md"
    $contractText = [System.IO.File]::ReadAllText($contractPath)
    foreach ($requiredText in @($relativePath, "CUSTOM_DOCUMENTATION", "DEFAULT_FALLBACK", "<ProjectRoot>/.gitignore")) {
        if ($contractText.IndexOf($requiredText, [System.StringComparison]::Ordinal) -lt 0) {
            Stop-Bootstrap "VALIDATION" "The integration contract does not point to the complete custom .gitignore setup contract."
        }
    }
}

function Test-SynchronizedPackageContent([string]$Path) {
    $manifestPath = Join-Path $Path "GeurtsTechniqueManifest.md"
    $manifestText = [System.IO.File]::ReadAllText($manifestPath)
    $packageVersion = Get-SynchronizedDeclaredVersion -FilePath $manifestPath
    if ($packageVersion -cne "0.8.0") {
        Stop-Bootstrap "VALIDATION" "The candidate manifest must declare package version 0.8.0."
    }

    $beginMarker = '<!-- GEURTS-PACKAGE-FILES:BEGIN -->'
    $endMarker = '<!-- GEURTS-PACKAGE-FILES:END -->'
    if ([regex]::Matches($manifestText, [regex]::Escape($beginMarker)).Count -ne 1 -or [regex]::Matches($manifestText, [regex]::Escape($endMarker)).Count -ne 1) {
        Stop-Bootstrap "VALIDATION" "The package manifest must contain one package-file registry."
    }
    $beginIndex = $manifestText.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
    $endIndex = $manifestText.IndexOf($endMarker, [System.StringComparison]::Ordinal)
    if ($endIndex -le $beginIndex) { Stop-Bootstrap "VALIDATION" "The package-file registry markers are out of order." }
    $registryBody = $manifestText.Substring($beginIndex + $beginMarker.Length, $endIndex - ($beginIndex + $beginMarker.Length))
    $registryRows = New-Object System.Collections.Generic.List[object]
    $registryPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($line in ($registryBody -split '\r?\n')) {
        $row = [regex]::Match($line, '^\|\s*`(?<Path>[^`]+)`\s*\|\s*(?<Version>[^|]+?)\s*\|\s*(?<Scope>.*?)\s*\|\s*$')
        if (-not $row.Success) { continue }
        $registryPath = $row.Groups["Path"].Value
        if (-not $registryPaths.Add($registryPath)) { Stop-Bootstrap "VALIDATION" "Duplicate package registry path: $registryPath" }
        $registryRows.Add([pscustomobject]@{
            Path = $registryPath
            Version = $row.Groups["Version"].Value.Trim()
            Scope = $row.Groups["Scope"].Value.Trim()
        }) | Out-Null
    }
    if ($registryRows.Count -eq 0) { Stop-Bootstrap "VALIDATION" "The package-file registry contains no file rows." }

    $synchronizedRows = @($registryRows | Where-Object { $_.Scope -match '(?i)\bsynchronized\b' })
    $expectedSynchronizedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    [void]$expectedSynchronizedPaths.Add("AI_READ_FIRST.md")
    [void]$expectedSynchronizedPaths.Add("GeurtsTechniqueManifest.md")
    $techniqueRoot = Join-Path $Path "GeurtsTechniques"
    foreach ($file in @(Get-ChildItem -LiteralPath $techniqueRoot -File -Recurse -Force)) {
        $relative = $file.FullName.Substring($Path.Length).TrimStart('\', '/').Replace('\', '/')
        [void]$expectedSynchronizedPaths.Add($relative)
    }
    if ($synchronizedRows.Count -ne $expectedSynchronizedPaths.Count) {
        Stop-Bootstrap "VALIDATION" "The synchronized registry rows do not match the complete synchronized file set."
    }

    foreach ($row in $synchronizedRows) {
        if (-not $expectedSynchronizedPaths.Contains($row.Path)) {
            Stop-Bootstrap "VALIDATION" "The registry marks an unexpected synchronized path: $($row.Path)"
        }
        $filePath = Join-Path $Path ($row.Path.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
            Stop-Bootstrap "VALIDATION" "A manifest-listed synchronized file is missing: $($row.Path)"
        }
        $declaredVersion = Get-SynchronizedDeclaredVersion -FilePath $filePath
        if ([string]::IsNullOrWhiteSpace($declaredVersion) -or $declaredVersion -cne $row.Version) {
            Stop-Bootstrap "VALIDATION" "Version mismatch for synchronized file '$($row.Path)'."
        }

        if ([System.IO.Path]::GetExtension($filePath) -ieq ".json") {
            try { $contentJson = Get-Content -LiteralPath $filePath -Raw | ConvertFrom-Json }
            catch { Stop-Bootstrap "VALIDATION" "Synchronized JSON is invalid: $($row.Path)" }
            if ([string]$contentJson.canonicalPath -cne $row.Path) {
                Stop-Bootstrap "VALIDATION" "Canonical path mismatch for synchronized file '$($row.Path)'."
            }
        }
        else {
            $contentText = [System.IO.File]::ReadAllText($filePath)
            $canonicalLine = '**Canonical path:** `' + $row.Path + '`'
            $hasCanonicalLine = @($contentText -split '\r?\n' | Where-Object { $_.TrimEnd() -ceq $canonicalLine }).Count -eq 1
            if (-not $hasCanonicalLine) {
                Stop-Bootstrap "VALIDATION" "Canonical path metadata is missing or duplicated for '$($row.Path)'."
            }
        }
    }

    foreach ($expectedPath in $expectedSynchronizedPaths) {
        if (@($synchronizedRows | Where-Object { $_.Path -ceq $expectedPath }).Count -ne 1) {
            Stop-Bootstrap "VALIDATION" "A synchronized file is missing from the manifest registry: $expectedPath"
        }
    }

    Test-SynchronizedGitIgnoreTechnique -Path $Path

    $folderDefinitionPath = Join-Path $Path "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
    try { $folderDefinition = Get-Content -LiteralPath $folderDefinitionPath -Raw | ConvertFrom-Json }
    catch { Stop-Bootstrap "VALIDATION" "The synchronized folder definition is invalid JSON." }
    if ([string]$folderDefinition.schemaVersion -cne "1.0.0" -or [string]$folderDefinition.definitionVersion -cne "0.7.0" -or [string]$folderDefinition.packageVersion -cne "0.8.0" -or [string]$folderDefinition.canonicalPath -cne "GeurtsTechniques/GeurtsFolderStructureDefinition.json" -or [string]$folderDefinition.pathBase -cne "<ProjectRoot>" -or [string]$folderDefinition.pathSeparator -cne "/" -or [string]$folderDefinition.explanatoryAuthority -cne "GeurtsTechniques/GeurtsFolderStructureTechnique.md" -or [string]$folderDefinition.automationAuthority -cne "GeurtsTechniques/GeurtsFolderStructureDefinition.json" -or @($folderDefinition.managedFolders).Count -ne 71 -or [int]$folderDefinition.managedFolderCount -ne 71 -or [int]$folderDefinition.projectStructureFolderCount -ne 67) {
        Stop-Bootstrap "VALIDATION" "The synchronized folder definition does not match definition v0.7.0, package v0.8.0, and the required count and authority contract."
    }
    $allowedFolderCategories = @("documentation", "generated-content", "third-party-content", "tooling", "unity-project")
    $declaredFolderCategories = @($folderDefinition.contentCategories | Sort-Object)
    if ($declaredFolderCategories.Count -ne $allowedFolderCategories.Count) { Stop-Bootstrap "VALIDATION" "The synchronized folder definition has an invalid category set." }
    for ($categoryIndex = 0; $categoryIndex -lt $allowedFolderCategories.Count; $categoryIndex++) {
        if ([string]$declaredFolderCategories[$categoryIndex] -cne $allowedFolderCategories[$categoryIndex]) { Stop-Bootstrap "VALIDATION" "The synchronized folder definition has an invalid category set." }
    }
    $expectedProfileOwners = @{ "full-project-structure" = "folder-structure-tool"; "native-entry" = "native-entry-manager"; "gdd-scaffolding" = "native-entry-manager"; "documentation-sync" = "documentation-synchronizer" }
    $expectedProfileCounts = @{ "full-project-structure" = 67; "native-entry" = 2; "gdd-scaffolding" = 2; "documentation-sync" = 2 }
    if (@($folderDefinition.creationProfiles).Count -ne 4) { Stop-Bootstrap "VALIDATION" "The synchronized folder definition must contain exactly four creation profiles." }
    $profileIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($profile in @($folderDefinition.creationProfiles)) {
        $profileId = [string]$profile.id
        if (-not $profileIds.Add($profileId) -or -not $expectedProfileOwners.ContainsKey($profileId) -or [string]$profile.owner -cne [string]$expectedProfileOwners[$profileId] -or [string]::IsNullOrWhiteSpace([string]$profile.purpose)) {
            Stop-Bootstrap "VALIDATION" "The synchronized folder definition contains an invalid profile or owner."
        }
    }
    foreach ($profileId in $expectedProfileOwners.Keys) { if (-not $profileIds.Contains($profileId)) { Stop-Bootstrap "VALIDATION" "The synchronized folder definition is missing profile '$profileId'." } }

    $folderPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $folderPathsIgnoreCase = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $profileCounts = @{}
    foreach ($profileId in $expectedProfileOwners.Keys) { $profileCounts[$profileId] = 0 }
    foreach ($folder in @($folderDefinition.managedFolders)) {
        $folderEntryPath = [string]$folder.path
        if (-not (Test-SynchronizedFolderPath -FolderPath $folderEntryPath) -or -not $folderPaths.Add($folderEntryPath) -or -not $folderPathsIgnoreCase.Add($folderEntryPath)) { Stop-Bootstrap "VALIDATION" "The synchronized folder definition contains an unsafe or duplicate path '$folderEntryPath'." }
        if ($folder.requirement -notin @("required", "optional") -or [string]::IsNullOrWhiteSpace([string]$folder.purpose) -or [string]$folder.contentCategory -notin $allowedFolderCategories) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has invalid descriptive metadata." }
        if (-not $folder.automation -or $folder.automation.mayCreate -isnot [bool] -or $folder.automation.mayRemove -isnot [bool] -or $folder.automation.mayCreate -ne $true -or $folder.automation.mayRemove -ne $false) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' violates the create-only automation policy." }
        $actualProfiles = @($folder.automation.creationProfiles | ForEach-Object { [string]$_ } | Sort-Object)
        $expectedProfiles = @(Get-SynchronizedExpectedProfiles -FolderPath $folderEntryPath | Sort-Object)
        if ($actualProfiles.Count -ne $expectedProfiles.Count) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has an invalid profile scope." }
        for ($profileIndex = 0; $profileIndex -lt $expectedProfiles.Count; $profileIndex++) { if ($actualProfiles[$profileIndex] -cne $expectedProfiles[$profileIndex]) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has an invalid profile scope." } }
        $delegations = @{}
        if ($folder.automation.PSObject.Properties["delegatedOwners"]) { foreach ($delegation in @($folder.automation.delegatedOwners.PSObject.Properties)) { $delegations[[string]$delegation.Name] = [string]$delegation.Value } }
        if ($folderEntryPath -in @("Docs", "Docs/GameDesign")) {
            if ($delegations.Count -ne 1 -or -not $delegations.ContainsKey("gdd-scaffolding") -or [string]$delegations["gdd-scaffolding"] -cne "native-entry-manager") { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has invalid GDD delegation." }
        }
        elseif ($delegations.Count -ne 0) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has an unauthorized delegation." }
        foreach ($profileId in $actualProfiles) {
            $profileCounts[$profileId] = [int]$profileCounts[$profileId] + 1
            $primaryMatches = [string]$folder.automation.owner -ceq [string]$expectedProfileOwners[$profileId]
            $delegatedMatches = $delegations.ContainsKey($profileId) -and [string]$delegations[$profileId] -ceq [string]$expectedProfileOwners[$profileId]
            if (-not $primaryMatches -and -not $delegatedMatches) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has an unauthorized automation owner." }
        }
    }
    foreach ($folder in @($folderDefinition.managedFolders)) {
        $folderEntryPath = [string]$folder.path
        $parent = [string]$folder.parent
        if ($folderEntryPath.Contains('/')) {
            $expectedParent = $folderEntryPath.Substring(0, $folderEntryPath.LastIndexOf('/'))
            if ($parent -cne $expectedParent -or -not $folderPaths.Contains($parent)) { Stop-Bootstrap "VALIDATION" "Folder '$folderEntryPath' has an invalid parent '$parent'." }
        }
        elseif (-not [string]::IsNullOrWhiteSpace($parent)) { Stop-Bootstrap "VALIDATION" "Root folder '$folderEntryPath' must not declare a parent." }
    }
    foreach ($profileId in $expectedProfileOwners.Keys) {
        $selectedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($selectedFolder in @($folderDefinition.managedFolders | Where-Object { @($_.automation.creationProfiles) -contains $profileId })) {
            [void]$selectedPaths.Add([string]$selectedFolder.path)
        }
        foreach ($selectedFolder in @($folderDefinition.managedFolders | Where-Object { @($_.automation.creationProfiles) -contains $profileId })) {
            $selectedParent = [string]$selectedFolder.parent
            if (-not [string]::IsNullOrWhiteSpace($selectedParent) -and -not $selectedPaths.Contains($selectedParent)) {
                Stop-Bootstrap "VALIDATION" "Profile '$profileId' is not parent-closed at '$($selectedFolder.path)'."
            }
        }
    }
    foreach ($profileId in $expectedProfileCounts.Keys) { if ([int]$profileCounts[$profileId] -ne [int]$expectedProfileCounts[$profileId]) { Stop-Bootstrap "VALIDATION" "Profile '$profileId' has an invalid exact path count." } }

    $folderTechniqueText = [System.IO.File]::ReadAllText((Join-Path $Path "GeurtsTechniques/GeurtsFolderStructureTechnique.md"))
    $folderRegistry = [regex]::Match($folderTechniqueText, '(?ms)<!-- GEURTS-FOLDER-PATHS:BEGIN -->\s*```text\s*(?<Paths>.*?)\s*```\s*<!-- GEURTS-FOLDER-PATHS:END -->')
    if (-not $folderRegistry.Success -or [regex]::Matches($folderTechniqueText, 'GEURTS-FOLDER-PATHS:BEGIN').Count -ne 1 -or [regex]::Matches($folderTechniqueText, 'GEURTS-FOLDER-PATHS:END').Count -ne 1) { Stop-Bootstrap "VALIDATION" "The synchronized Markdown folder registry is malformed." }
    $documentedFolderPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($line in ($folderRegistry.Groups["Paths"].Value -split '\r?\n')) {
        $documentedPath = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($documentedPath)) { continue }
        if (-not (Test-SynchronizedFolderPath -FolderPath $documentedPath) -or -not $documentedFolderPaths.Add($documentedPath)) { Stop-Bootstrap "VALIDATION" "The synchronized Markdown folder registry contains an invalid or duplicate path." }
    }
    if ($documentedFolderPaths.Count -ne $folderPaths.Count) { Stop-Bootstrap "VALIDATION" "The synchronized JSON and Markdown folder registries differ." }
    foreach ($folderEntryPath in $folderPaths) { if (-not $documentedFolderPaths.Contains($folderEntryPath)) { Stop-Bootstrap "VALIDATION" "JSON folder path '$folderEntryPath' is absent from the Markdown registry." } }
    foreach ($documentedPath in $documentedFolderPaths) { if (-not $folderPaths.Contains($documentedPath)) { Stop-Bootstrap "VALIDATION" "Markdown folder path '$documentedPath' is absent from the JSON registry." } }

    $responsePath = "GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md"
    $chatSection = [regex]::Match($manifestText, '(?ms)^### Chat-only\s*(?<Body>.*?)(?=^### |\z)')
    $responseRow = @($synchronizedRows | Where-Object { $_.Path -ceq $responsePath })
    if (-not $chatSection.Success -or $chatSection.Groups["Body"].Value.IndexOf($responsePath, [System.StringComparison]::Ordinal) -lt 0 -or $chatSection.Groups["Body"].Value -notmatch '(?i)not an? .*implementation standard' -or $responseRow.Count -ne 1 -or $responseRow[0].Scope -notmatch '(?i)chat-only') {
        Stop-Bootstrap "VALIDATION" "The response-control technique is not classified consistently as chat-only."
    }

    $script:ValidatedPackageVersion = $packageVersion
}

function Test-SyncLayout([string]$Path, $Config, [switch]$RequireClean, [switch]$RequireCurrentPackage) {
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        Stop-Bootstrap "VALIDATION" "Synchronized documentation directory is missing: $Path"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Path ".git") -PathType Container)) {
        Stop-Bootstrap "VALIDATION" "Synchronized documentation is not a managed Git copy: $Path"
    }

    $requiredEntries = Get-RequiredEntries -Config $Config
    foreach ($entry in $requiredEntries) {
        $candidate = Join-Path $Path ([string]$entry.path)
        if ($entry.type -eq "file" -and -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            Stop-Bootstrap "VALIDATION" "Required synchronized file is missing: $($entry.path)"
        }
        if ($entry.type -eq "directory" -and -not (Test-Path -LiteralPath $candidate -PathType Container)) {
            Stop-Bootstrap "VALIDATION" "Required synchronized directory is missing: $($entry.path)"
        }
    }

    $visible = @(Get-ChildItem -LiteralPath $Path -Force | Where-Object { $_.Name -ne ".git" } | Select-Object -ExpandProperty Name | Sort-Object)
    $expectedVisible = @($requiredEntries | Select-Object -ExpandProperty path | Sort-Object)
    if ($visible.Count -ne $expectedVisible.Count) {
        Stop-Bootstrap "VALIDATION" "Synchronized copy has unexpected visible top-level entries."
    }
    for ($index = 0; $index -lt $expectedVisible.Count; $index++) {
        if ($visible[$index] -cne $expectedVisible[$index]) {
            Stop-Bootstrap "VALIDATION" "Synchronized copy does not match the exact visible layout."
        }
    }

    if ($RequireCurrentPackage) {
        Test-SynchronizedPackageContent -Path $Path
    }

    if ($RequireClean) {
        $dirty = Invoke-GitRequired -Arguments @("-C", $Path, "status", "--porcelain", "--untracked-files=all") -DefaultCategory "VALIDATION" -Operation "Local cache status check"
        if (-not [string]::IsNullOrWhiteSpace($dirty)) {
            Stop-Bootstrap "CONFLICT" "The synchronized copy contains local changes. Preserve or remove them before updating."
        }
    }

    $commitOutput = Invoke-GitRequired -Arguments @("-C", $Path, "rev-parse", "HEAD") -DefaultCategory "VALIDATION" -Operation "Commit identification"
    $commit = ($commitOutput -split '\r?\n' | Select-Object -First 1).Trim()
    if ($commit -notmatch '^[0-9a-fA-F]{40,64}$') {
        Stop-Bootstrap "VALIDATION" "The synchronized commit identifier is invalid."
    }
    return $commit.ToLowerInvariant()
}

function Get-RemoteCommit($Config) {
    $reference = "refs/heads/$($Config.branch)"
    $output = Invoke-GitRequired -Arguments @("ls-remote", "--exit-code", "--", [string]$Config.repositoryUrl, $reference) -DefaultCategory "REMOTE" -Operation "Remote update check"
    $line = $output -split '\r?\n' | Where-Object { $_ -match '\S' } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($line)) {
        Stop-Bootstrap "REMOTE" "The configured branch was not returned by the remote."
    }
    $commit = ($line -split '\s+')[0]
    if ($commit -notmatch '^[0-9a-fA-F]{40,64}$') {
        Stop-Bootstrap "REMOTE" "The remote returned an invalid commit identifier."
    }
    return $commit.ToLowerInvariant()
}

function Remove-GeneratedDirectory([string]$Path, [string]$ExpectedParent, [string]$ExpectedPrefix) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return }
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $parent = Split-Path -Parent $fullPath
    $leaf = Split-Path -Leaf $fullPath
    if ($parent -cne $ExpectedParent -or -not $leaf.StartsWith($ExpectedPrefix, [System.StringComparison]::Ordinal)) {
        Stop-Bootstrap "FILESYSTEM" "Refused to remove an unverified generated directory: $fullPath"
    }
    Remove-Item -LiteralPath $fullPath -Recurse -Force -ErrorAction Stop
}

function Write-Success([string]$Status, [string]$CurrentCommit, [string]$AvailableCommit, [string]$PreviousCommit, [string]$SynchronizedCommit, [string]$ValidationOutcome, [string]$LocalPath, [string]$PackageVersion, [string]$Message) {
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{
            result = "OK"
            mode = $Mode
            status = $Status
            currentCommit = $CurrentCommit
            availableCommit = $AvailableCommit
            previousCommit = $PreviousCommit
            synchronizedCommit = $SynchronizedCommit
            validationOutcome = $ValidationOutcome
            packageVersion = $PackageVersion
            localPath = $LocalPath
            message = $Message
            warnings = $script:SuccessWarnings.ToArray()
        } | ConvertTo-Json -Depth 4
    }
    else {
        $successBanner = if ($Mode -eq "Update" -and $Status -eq "UPDATED" -and $ValidationOutcome -eq "PASSED") { "SYNC OK" } elseif ($ValidationOutcome -eq "PASSED") { "VALIDATION OK" } else { "CHECK OK" }
        Write-Host $successBanner -ForegroundColor Green
        Write-Host "Mode:        $Mode"
        Write-Host "Status:      $Status"
        if ($CurrentCommit) { Write-Host "Current:     $CurrentCommit" }
        if ($AvailableCommit) { Write-Host "Available:   $AvailableCommit" }
        if ($PreviousCommit) { Write-Host "Previous:    $PreviousCommit" }
        if ($SynchronizedCommit) { Write-Host "Synchronized: $SynchronizedCommit" }
        Write-Host "Validation:  $ValidationOutcome"
        if ($PackageVersion) { Write-Host "Package:     $PackageVersion" }
        Write-Host "Local docs:  $LocalPath"
        if ($Message) { Write-Host $Message }
        foreach ($warningMessage in $script:SuccessWarnings) { Write-Warning $warningMessage }
    }
    Exit-SyncLock
}

try {
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Split-Path -Parent $PSScriptRoot
    }
    $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        Stop-Bootstrap "CONFIGURATION" "Project root does not exist: $ProjectRoot"
    }

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        $ConfigPath = Join-Path $ProjectRoot "Tools/GeurtsRepository.json"
    }
    else {
        $ConfigPath = Get-FullPath -Path $ConfigPath -BasePath $ProjectRoot
    }
    if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
        Stop-Bootstrap "CONFIGURATION" "Repository configuration not found: $ConfigPath"
    }

    try {
        $config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Stop-Bootstrap "CONFIGURATION" "Repository configuration is invalid JSON: $($_.Exception.Message)"
    }
    foreach ($property in @("schemaVersion", "packageVersion", "distributionStrategy", "repositoryUrl", "branch", "localSyncPath", "entryPointPath", "manifestPath", "techniquesPath", "folderDefinitionPath", "fallbackPolicy", "requiredEntries", "sparsePaths")) {
        if (-not $config.PSObject.Properties[$property]) {
            Stop-Bootstrap "CONFIGURATION" "Repository configuration is missing '$property'."
        }
    }
    foreach ($property in @("schemaVersion", "packageVersion", "distributionStrategy", "repositoryUrl", "branch", "localSyncPath", "entryPointPath", "manifestPath", "techniquesPath", "folderDefinitionPath", "fallbackPolicy")) {
        if ([string]::IsNullOrWhiteSpace([string]$config.$property)) { Stop-Bootstrap "CONFIGURATION" "Repository configuration is missing '$property'." }
    }
    if ([string]$config.schemaVersion -ne "0.7.0") {
        Stop-Bootstrap "CONFIGURATION" "Unsupported repository configuration schema: $($config.schemaVersion)"
    }
    $exactConfigValues = @{
        packageVersion = "0.8.0"
        distributionStrategy = "public-repository"
        branch = "main"
        localSyncPath = "GeurtsGameForgeDocumentation"
        entryPointPath = "AI_READ_FIRST.md"
        manifestPath = "GeurtsTechniqueManifest.md"
        techniquesPath = "GeurtsTechniques"
        folderDefinitionPath = "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
        fallbackPolicy = "none"
    }
    foreach ($property in $exactConfigValues.Keys) {
        if ([string]$config.$property -cne [string]$exactConfigValues[$property]) {
            Stop-Bootstrap "CONFIGURATION" "Repository configuration '$property' must be '$($exactConfigValues[$property])' for package v0.8.0."
        }
    }
    if ([string]$config.branch -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]*$' -or [string]$config.branch -match '(?:^|/)\.\.(?:/|$)') {
        Stop-Bootstrap "CONFIGURATION" "Configured branch name is unsafe."
    }
    if ([System.IO.Path]::IsPathRooted([string]$config.localSyncPath) -or [string]$config.localSyncPath -match '(^|[\\/])\.\.([\\/]|$)') {
        Stop-Bootstrap "CONFIGURATION" "localSyncPath must be a safe project-relative path."
    }
    Get-RequiredEntries -Config $config | Out-Null
    Test-SparseConfiguration -Config $config

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Stop-Bootstrap "DEPENDENCY" "Git is not installed or is not available on PATH."
    }
    $gitVersion = Invoke-GitRequired -Arguments @("--version") -DefaultCategory "DEPENDENCY" -Operation "Git version check"
    if ($gitVersion -notmatch '(\d+)\.(\d+)') {
        Stop-Bootstrap "DEPENDENCY" "Unable to determine the installed Git version."
    }
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    if ($major -lt 2 -or ($major -eq 2 -and $minor -lt 25)) {
        Stop-Bootstrap "DEPENDENCY" "Git 2.25 or newer is required for sparse checkout."
    }

    $targetPath = Get-FullPath -Path ([string]$config.localSyncPath) -BasePath $ProjectRoot
    $script:TargetPath = $targetPath
    if (-not (Test-IsContainedPath -Candidate $targetPath -Root $ProjectRoot) -or $targetPath -eq $ProjectRoot) {
        Stop-Bootstrap "CONFIGURATION" "localSyncPath resolves outside the project root."
    }
    if (Test-HasReparsePoint -Candidate $targetPath -Root $ProjectRoot) {
        Stop-Bootstrap "CONFIGURATION" "localSyncPath contains a reparse point and cannot be updated safely."
    }
    $script:SyncMutex = Enter-SyncLock -TargetPath $targetPath

    $oldPrompt = $env:GIT_TERMINAL_PROMPT
    $env:GIT_TERMINAL_PROMPT = "0"
    try {
        if ($Mode -eq "Validate") {
            $currentCommit = Test-SyncLayout -Path $targetPath -Config $config -RequireClean -RequireCurrentPackage
            Write-Success -Status "VALID" -CurrentCommit $currentCommit -AvailableCommit $null -PreviousCommit $null -SynchronizedCommit $currentCommit -ValidationOutcome "PASSED" -LocalPath $targetPath -PackageVersion $script:ValidatedPackageVersion -Message "The local synchronized copy passed validation."
            exit 0
        }

        $currentCommit = $null
        if (Test-Path -LiteralPath $targetPath) {
            if (-not (Test-Path -LiteralPath $targetPath -PathType Container) -or -not (Test-Path -LiteralPath (Join-Path $targetPath ".git") -PathType Container)) {
                Stop-Bootstrap "CONFLICT" "The synchronization path exists but is not a managed documentation cache. It was not changed."
            }
            $currentCommit = Test-SyncLayout -Path $targetPath -Config $config -RequireClean
            if ($Mode -eq "Update") {
                try {
                    $validatedCurrentCommit = Test-SyncLayout -Path $targetPath -Config $config -RequireClean -RequireCurrentPackage
                    if ($validatedCurrentCommit -eq $currentCommit) { $script:LastValidCopyConfirmed = $true }
                }
                catch {
                    # An older or invalid local package may still be repaired by a fully staged canonical update.
                    $script:LastValidCopyConfirmed = $false
                    $script:ValidatedPackageVersion = $null
                }
            }
        }

        $remoteCommit = Get-RemoteCommit -Config $config
        if ($Mode -eq "Check") {
            if (-not $currentCommit) { $status = "NOT_INSTALLED" }
            elseif ($currentCommit -eq $remoteCommit) { $status = "CURRENT" }
            else { $status = "UPDATE_AVAILABLE" }
            Write-Success -Status $status -CurrentCommit $currentCommit -AvailableCommit $remoteCommit -PreviousCommit $null -SynchronizedCommit $null -ValidationOutcome "NOT_RUN" -LocalPath $targetPath -PackageVersion $null -Message "Check mode made no filesystem changes."
            exit 0
        }

        if ($currentCommit -and $currentCommit -eq $remoteCommit -and $script:LastValidCopyConfirmed) {
            $currentCommit = Test-SyncLayout -Path $targetPath -Config $config -RequireClean -RequireCurrentPackage
            Write-Success -Status "CURRENT" -CurrentCommit $currentCommit -AvailableCommit $remoteCommit -PreviousCommit $currentCommit -SynchronizedCommit $currentCommit -ValidationOutcome "PASSED" -LocalPath $targetPath -PackageVersion $script:ValidatedPackageVersion -Message "No update was required."
            exit 0
        }

        $parentPath = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
            New-Item -ItemType Directory -Path $parentPath -ErrorAction Stop | Out-Null
        }
        $targetLeaf = Split-Path -Leaf $targetPath
        $operationId = [Guid]::NewGuid().ToString("N")
        $stagePrefix = "$targetLeaf.staging-"
        $backupPrefix = "$targetLeaf.backup-"
        $script:StagePath = Join-Path $parentPath ($stagePrefix + $operationId)
        $script:BackupPath = Join-Path $parentPath ($backupPrefix + $operationId)

        Invoke-GitRequired -Arguments @("clone", "--depth", "1", "--filter=blob:none", "--no-checkout", "--branch", [string]$config.branch, "--", [string]$config.repositoryUrl, $script:StagePath) -DefaultCategory "REMOTE" -Operation "Documentation clone" | Out-Null
        Invoke-GitRequired -Arguments @("-C", $script:StagePath, "sparse-checkout", "init", "--no-cone") -DefaultCategory "CHECKOUT" -Operation "Sparse checkout initialization" | Out-Null
        $sparseArguments = @("-C", $script:StagePath, "sparse-checkout", "set", "--no-cone") + @($config.sparsePaths)
        Invoke-GitRequired -Arguments $sparseArguments -DefaultCategory "CHECKOUT" -Operation "Sparse layout selection" | Out-Null
        Invoke-GitRequired -Arguments @("-C", $script:StagePath, "checkout", "--detach", $remoteCommit) -DefaultCategory "CHECKOUT" -Operation "Documentation checkout" | Out-Null

        $candidateCommit = Test-SyncLayout -Path $script:StagePath -Config $config -RequireClean -RequireCurrentPackage
        if ($candidateCommit -ne $remoteCommit) {
            Stop-Bootstrap "VALIDATION" "Validated candidate commit does not match the available remote commit."
        }

        if ($currentCommit) {
            try {
                Move-Item -LiteralPath $targetPath -Destination $script:BackupPath -ErrorAction Stop
            }
            catch {
                $moveCategory = Get-FilesystemFailureCategory -Exception $_.Exception
                Stop-Bootstrap $moveCategory "Could not preserve the existing local copy before promotion: $($_.Exception.Message)"
            }
        }
        try {
            Move-Item -LiteralPath $script:StagePath -Destination $targetPath -ErrorAction Stop
            $script:Promoted = $true
        }
        catch {
            if ($currentCommit -and (Test-Path -LiteralPath $script:BackupPath) -and -not (Test-Path -LiteralPath $targetPath)) {
                Move-Item -LiteralPath $script:BackupPath -Destination $targetPath -ErrorAction SilentlyContinue
            }
            $moveCategory = Get-FilesystemFailureCategory -Exception $_.Exception
            Stop-Bootstrap $moveCategory "Could not promote the validated documentation copy: $($_.Exception.Message)"
        }

        $installedCommit = Test-SyncLayout -Path $targetPath -Config $config -RequireClean -RequireCurrentPackage
        if ($installedCommit -ne $remoteCommit) {
            Stop-Bootstrap "VALIDATION" "Post-promotion commit validation failed."
        }

        if ($currentCommit -and (Test-Path -LiteralPath $script:BackupPath)) {
            try {
                Remove-GeneratedDirectory -Path $script:BackupPath -ExpectedParent $parentPath -ExpectedPrefix $backupPrefix
            }
            catch {
                $script:SuccessWarnings.Add("The update succeeded, but the preserved backup could not be removed: $($script:BackupPath)") | Out-Null
            }
        }
        $script:StagePath = $null
        $script:BackupPath = $null
        Write-Success -Status "UPDATED" -CurrentCommit $installedCommit -AvailableCommit $remoteCommit -PreviousCommit $currentCommit -SynchronizedCommit $installedCommit -ValidationOutcome "PASSED" -LocalPath $targetPath -PackageVersion $script:ValidatedPackageVersion -Message "The exact synchronized layout was validated before and after promotion."
        exit 0
    }
    finally {
        $env:GIT_TERMINAL_PROMPT = $oldPrompt
    }
}
catch {
    $originalFailure = $_
    $category = [string]$originalFailure.Exception.Data["BootstrapCategory"]
    if ([string]::IsNullOrWhiteSpace($category) -or -not $exitCodes.ContainsKey($category)) {
        if ($originalFailure.Exception.Message -match '(?i)being used by another process|sharing violation|lock violation|cannot access.*because it is being used') { $category = "FILE_LOCK" }
        elseif ($originalFailure.Exception -is [System.IO.IOException] -or $originalFailure.Exception -is [System.UnauthorizedAccessException]) { $category = "FILESYSTEM" }
        else { $category = "UNKNOWN" }
    }

    try {
        if ($script:Promoted -and $script:BackupPath -and (Test-Path -LiteralPath $script:BackupPath)) {
            if (Test-Path -LiteralPath $script:TargetPath) {
                $parent = Split-Path -Parent $script:TargetPath
                $leaf = Split-Path -Leaf $script:TargetPath
                $failedPath = Join-Path $parent ($leaf + ".failed-" + [Guid]::NewGuid().ToString("N"))
                Move-Item -LiteralPath $script:TargetPath -Destination $failedPath -ErrorAction Stop
                Move-Item -LiteralPath $script:BackupPath -Destination $script:TargetPath -ErrorAction Stop
                Remove-GeneratedDirectory -Path $failedPath -ExpectedParent $parent -ExpectedPrefix ($leaf + ".failed-")
            }
            elseif (-not (Test-Path -LiteralPath $script:TargetPath)) {
                Move-Item -LiteralPath $script:BackupPath -Destination $script:TargetPath -ErrorAction Stop
            }
        }
        elseif ($script:Promoted -and $script:TargetPath -and (Test-Path -LiteralPath $script:TargetPath)) {
            $parent = Split-Path -Parent $script:TargetPath
            $leaf = Split-Path -Leaf $script:TargetPath
            $failedPrefix = $leaf + ".failed-"
            $failedPath = Join-Path $parent ($failedPrefix + [Guid]::NewGuid().ToString("N"))
            Move-Item -LiteralPath $script:TargetPath -Destination $failedPath -ErrorAction Stop
            Remove-GeneratedDirectory -Path $failedPath -ExpectedParent $parent -ExpectedPrefix $failedPrefix
        }
        if ($script:StagePath -and (Test-Path -LiteralPath $script:StagePath)) {
            $stageParent = Split-Path -Parent $script:StagePath
            $stageLeafPrefix = (Split-Path -Leaf $script:TargetPath) + ".staging-"
            Remove-GeneratedDirectory -Path $script:StagePath -ExpectedParent $stageParent -ExpectedPrefix $stageLeafPrefix
        }
    }
    catch {
        $category = Get-FilesystemFailureCategory -Exception $_.Exception
        $rollbackMessage = " Rollback also encountered an error; the preserved backup path is '$script:BackupPath'."
    }

    Exit-SyncLock

    $message = $originalFailure.Exception.Message + $rollbackMessage
    $confirmedLastValidCopy = $null
    if ($script:LastValidCopyConfirmed) {
        if ($script:TargetPath -and (Test-Path -LiteralPath $script:TargetPath -PathType Container)) { $confirmedLastValidCopy = $script:TargetPath }
        elseif ($script:BackupPath -and (Test-Path -LiteralPath $script:BackupPath -PathType Container)) { $confirmedLastValidCopy = $script:BackupPath }
    }
    $preservedLocalCopy = $(if ($script:TargetPath -and (Test-Path -LiteralPath $script:TargetPath)) { $script:TargetPath } else { $null })
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{
            result = "FAILED"
            mode = $Mode
            category = $category
            exitCode = $exitCodes[$category]
            message = $message
            lastValidCopy = $confirmedLastValidCopy
            preservedLocalCopy = $preservedLocalCopy
            preservedBackup = $(if ($script:BackupPath -and (Test-Path -LiteralPath $script:BackupPath)) { $script:BackupPath } else { $null })
        } | ConvertTo-Json -Depth 4
    }
    else {
        Write-Host "SYNC FAILED [$category]: $message" -ForegroundColor Red
        if ($confirmedLastValidCopy) {
            Write-Host "Last valid copy preserved at: $confirmedLastValidCopy"
        }
        elseif ($preservedLocalCopy) {
            Write-Host "Existing local copy preserved but not confirmed valid by this operation: $preservedLocalCopy"
        }
        elseif ($script:BackupPath -and (Test-Path -LiteralPath $script:BackupPath)) {
            Write-Host "Preserved backup requires attention at: $script:BackupPath"
        }
    }
    exit $exitCodes[$category]
}
