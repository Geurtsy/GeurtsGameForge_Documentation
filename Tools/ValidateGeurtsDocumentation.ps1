# ValidateGeurtsDocumentation.ps1
# Version: 0.11.4

[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [switch]$RunAutomationTests,
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$checks = New-Object System.Collections.Generic.List[object]
$failures = New-Object System.Collections.Generic.List[string]
$automationTests = $null

function Add-Check([string]$Name, [bool]$Passed, [string]$Message) {
    $checks.Add([pscustomobject]@{ name = $Name; passed = $Passed; message = $Message }) | Out-Null
    if (-not $Passed) { $failures.Add("$Name - $Message") | Out-Null }
    if ($OutputFormat -eq "Text") {
        $label = if ($Passed) { "PASS" } else { "FAIL" }
        Write-Host ("[{0}] {1}: {2}" -f $label, $Name, $Message) -ForegroundColor $(if ($Passed) { "Green" } else { "Red" })
    }
}

function Get-DeclaredVersion([string]$Path) {
    $text = [System.IO.File]::ReadAllText($Path)
    foreach ($pattern in @(
        '(?im)^\s*#\s*Version:\s*(?<Version>\d+\.\d+(?:\.\d+)?)',
        '(?im)^\s*rem\s+Version:\s*(?<Version>\d+\.\d+(?:\.\d+)?)',
        '(?im)^\*\*(?:Template )?Version:\*\*\s*(?<Version>\d+\.\d+(?:\.\d+)?)',
        '(?im)^Version:\s*(?<Version>\d+\.\d+(?:\.\d+)?)'
    )) {
        $match = [regex]::Match($text, $pattern)
        if ($match.Success) { return $match.Groups["Version"].Value }
    }
    if ([System.IO.Path]::GetExtension($Path) -eq ".json") {
        try {
            $json = $text | ConvertFrom-Json
            if ($json.packageVersion) { return [string]$json.packageVersion }
            if ($json.schemaVersion) { return [string]$json.schemaVersion }
        }
        catch { return $null }
    }
    return $null
}

function Test-SafeDefinitionPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path) -or [System.IO.Path]::IsPathRooted($Path) -or $Path.Contains('\') -or $Path.StartsWith('/') -or $Path.EndsWith('/')) { return $false }
    foreach ($segment in $Path.Split('/')) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -in @('.', '..') -or $segment.EndsWith('.') -or $segment.EndsWith(' ') -or $segment.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) { return $false }
    }
    return $true
}

function Test-ExactStringSequence([object[]]$Actual, [string[]]$Expected) {
    $actualValues = @($Actual | ForEach-Object { [string]$_ })
    if ($actualValues.Count -ne $Expected.Count) { return $false }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ($actualValues[$index] -cne $Expected[$index]) { return $false }
    }
    return $true
}

function Test-ExactPropertySet($Object, [string[]]$Expected) {
    if ($null -eq $Object) { return $false }
    $actualNames = @($Object.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object)
    $expectedNames = @($Expected | Sort-Object)
    return Test-ExactStringSequence -Actual $actualNames -Expected $expectedNames
}

function Get-ExpectedFolderProfiles([string]$Path) {
    if ($Path -in @(".github", ".github/instructions")) { return @("native-entry") }
    if ($Path -in @("Docs", "Docs/GameDesign")) { return @("full-project-structure", "gdd-scaffolding") }
    return @("full-project-structure")
}

function Get-TextHash([string]$Text) {
    if ($Text.Length -gt 0 -and $Text[0] -eq [char]0xFEFF) { $Text = $Text.Substring(1) }
    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-GitTrackedPaths([string]$Root) {
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git -c core.quotepath=false -C $Root ls-files --cached -- 2>&1)
        $exitCode = $LASTEXITCODE
        $deletedOutput = @(& git -c core.quotepath=false -C $Root ls-files --deleted -- 2>&1)
        $deletedExitCode = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previousPreference }
    if ($exitCode -ne 0 -or $deletedExitCode -ne 0) {
        throw "Unable to enumerate Git-tracked source files: $($output -join [Environment]::NewLine)"
    }
    $deletedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($deletedPath in $deletedOutput) { [void]$deletedSet.Add(([string]$deletedPath).Replace('\', '/')) }
    return @($output | ForEach-Object { ([string]$_).Replace('\', '/') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $deletedSet.Contains($_) })
}

try {
    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
    $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) { throw "Repository root does not exist: $RepositoryRoot" }

    $manifestPath = Join-Path $RepositoryRoot "GeurtsTechniqueManifest.md"
    $manifestText = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) { [System.IO.File]::ReadAllText($manifestPath) } else { "" }
    $packageMatch = [regex]::Match($manifestText, '(?im)^\*\*Version:\*\*\s*(?<Version>\d+\.\d+\.\d+)')
    $packageVersion = if ($packageMatch.Success) { $packageMatch.Groups["Version"].Value } else { $null }
    Add-Check "Package version" ($packageVersion -eq "0.11.3") "Manifest package version is $packageVersion."

    $entryPolicy = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "AI_READ_FIRST.md"))
    $versionPolicyValid = $entryPolicy.Contains("Before planning or editing any part of Geurts Game Forge") -and
        $entryPolicy.Contains("no matter how small") -and $entryPolicy.Contains("Never publish changed content under the same version") -and
        $entryPolicy.Contains('MAJOR.MINOR.PATCH') -and $entryPolicy.Contains("new version exceeds the previous published version")
    Add-Check "Mandatory reading and version policy" $versionPolicyValid "AI_READ_FIRST requires current documentation reading and an appropriate version bump for every update, however small."

    $readmeStatusText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "README.md"))
    $targetMigrationText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Migrations/v0.11.0.md"))
    $gfiMigrationText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Migrations/v0.10.0.md"))
    $gfiStatusText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"))
    $companionStatusText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"))
    $draftStatusValid = $manifestText -match '(?im)^\*\*Status:\*\*\s*Draft normative package manifest\s*$' -and $readmeStatusText -match '(?im)^\*\*Status:\*\*\s*Draft technique package\s*$' -and $gfiStatusText -match '(?im)^\*\*Status:\*\*\s*Draft normative technique\s*$' -and $companionStatusText -match '(?im)^\*\*Status:\*\*\s*Draft normative technique\s*$' -and $targetMigrationText -match '(?i)planned transition' -and $targetMigrationText -match '(?i)target-release snapshot' -and $targetMigrationText -notmatch '(?i)(?:v0\.11\.3|package v0\.11\.3)[^\r\n]{0,80}(?:is|was|has been) released'
    Add-Check "Draft target-release status" $draftStatusValid "Package v0.11.3 remains a Draft target release; its migration guide is a planned target-release snapshot, not a completed-release claim."

    $listedRecords = New-Object System.Collections.Generic.List[object]
    foreach ($match in [regex]::Matches($manifestText, '(?m)^- `(?<Path>[^`]+)` v(?<Version>\d+\.\d+\.\d+|\d+\.\d+)\s*$')) {
        $listedRecords.Add([pscustomobject]@{ Path = $match.Groups["Path"].Value; Version = $match.Groups["Version"].Value }) | Out-Null
    }
    foreach ($match in [regex]::Matches($manifestText, '(?m)^\| `(?<Path>[^`]+)` \| (?<Version>\d+\.\d+\.\d+|\d+\.\d+) \|')) {
        $listedRecords.Add([pscustomobject]@{ Path = $match.Groups["Path"].Value; Version = $match.Groups["Version"].Value }) | Out-Null
    }
    $missingListed = New-Object System.Collections.Generic.List[string]
    $versionMismatches = New-Object System.Collections.Generic.List[string]
    foreach ($record in $listedRecords) {
        $relative = $record.Path
        if ($relative.Contains("<ProjectRoot>")) { continue }
        $fullPath = Join-Path $RepositoryRoot ($relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $fullPath)) {
            $missingListed.Add($relative) | Out-Null
            continue
        }
        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $declared = Get-DeclaredVersion -Path $fullPath
            $listed = $record.Version
            if ([string]::IsNullOrWhiteSpace($declared)) { $versionMismatches.Add("$relative listed $listed but has no readable declared version") | Out-Null }
            elseif ($declared -ne $listed) { $versionMismatches.Add("$relative listed $listed but declares $declared") | Out-Null }
        }
    }
    Add-Check "Manifest-listed files" ($listedRecords.Count -gt 0 -and $missingListed.Count -eq 0) $(if ($missingListed.Count) { "Missing: " + ($missingListed -join ", ") } else { "$($listedRecords.Count) listed files exist." })
    Add-Check "Listed file versions" ($versionMismatches.Count -eq 0) $(if ($versionMismatches.Count) { $versionMismatches -join "; " } else { "Manifest-listed versions agree with declared file versions." })

    $trackedPaths = @(Get-GitTrackedPaths -Root $RepositoryRoot)
    $trackedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $trackedInventoryFailures = New-Object System.Collections.Generic.List[string]
    foreach ($trackedPath in $trackedPaths) {
        if (-not $trackedSet.Add([string]$trackedPath)) { $trackedInventoryFailures.Add("duplicate Git path '$trackedPath'") | Out-Null }
    }
    $registrySection = [regex]::Match($manifestText, '(?ms)<!-- GEURTS-PACKAGE-FILES:BEGIN -->(?<Body>.*?)<!-- GEURTS-PACKAGE-FILES:END -->')
    $registrySet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    if (-not $registrySection.Success -or [regex]::Matches($manifestText, 'GEURTS-PACKAGE-FILES:BEGIN').Count -ne 1 -or [regex]::Matches($manifestText, 'GEURTS-PACKAGE-FILES:END').Count -ne 1) {
        $trackedInventoryFailures.Add("package registry markers are missing or duplicated") | Out-Null
    }
    else {
        foreach ($row in [regex]::Matches($registrySection.Groups["Body"].Value, '(?m)^\| `(?<Path>[^`]+)` \| (?<Version>\d+\.\d+\.\d+|\d+\.\d+) \|')) {
            $registryPath = $row.Groups["Path"].Value
            if (-not $registrySet.Add($registryPath)) { $trackedInventoryFailures.Add("duplicate registry path '$registryPath'") | Out-Null }
        }
    }
    foreach ($trackedPath in $trackedSet) {
        if (-not $registrySet.Contains($trackedPath)) { $trackedInventoryFailures.Add("tracked path missing from registry: $trackedPath") | Out-Null }
    }
    foreach ($registryPath in $registrySet) {
        if (-not $trackedSet.Contains($registryPath)) { $trackedInventoryFailures.Add("registry path is not Git-tracked: $registryPath") | Out-Null }
    }
    Add-Check "Git-tracked package inventory" ($trackedInventoryFailures.Count -eq 0 -and $trackedSet.Count -gt 0 -and $trackedSet.Count -eq $registrySet.Count) $(if ($trackedInventoryFailures.Count) { $trackedInventoryFailures -join "; " } else { "The manifest registry exactly matches all $($trackedSet.Count) Git-tracked source files." })

    $expectedTopLevel = @("AGENTS.md", "AI_READ_FIRST.md", "GeurtsTechniqueManifest.md", "GeurtsTechniques", "Ideas", "Migrations", "README.md", "Tools") | Sort-Object
    $actualTopLevel = @($trackedPaths | ForEach-Object { ($_ -split '/')[0] } | Sort-Object -Unique)
    $topLevelValid = $actualTopLevel.Count -eq $expectedTopLevel.Count
    if ($topLevelValid) {
        for ($topLevelIndex = 0; $topLevelIndex -lt $expectedTopLevel.Count; $topLevelIndex++) {
            if ([string]$actualTopLevel[$topLevelIndex] -cne [string]$expectedTopLevel[$topLevelIndex]) { $topLevelValid = $false; break }
        }
    }
    $currentHiddenTracked = @($trackedPaths | Where-Object { $_ -match '(^|/)\.[^/]+' })
    Add-Check "Current source tree shape" ($topLevelValid -and $currentHiddenTracked.Count -eq 0) $(if (-not $topLevelValid) { "Top-level tracked entries differ: " + ($actualTopLevel -join ", ") } elseif ($currentHiddenTracked.Count -ne 0) { "Current tracked hidden paths differ: " + ($currentHiddenTracked -join ", ") } else { "The eight confirmed top-level entries are tracked, and the current source has zero Git-tracked hidden paths." })

    $resolverFailures = New-Object System.Collections.Generic.List[string]
    $resolverSection = [regex]::Match($manifestText, '(?ms)^## 1\. Manifest Resolver\s*(?<Body>.*?)(?=^## 2\.)')
    $subjectSection = [regex]::Match($manifestText, '(?ms)^## 2\. Subject Ownership and Applicability\s*(?<Body>.*?)(?=^## 3\.)')
    if (-not $resolverSection.Success) { $resolverFailures.Add("manifest resolver section is missing") | Out-Null }
    if (-not $subjectSection.Success) { $resolverFailures.Add("subject ownership and applicability section is missing") | Out-Null }
    if ($resolverSection.Success) {
        $resolverBody = $resolverSection.Groups["Body"].Value
        foreach ($term in @("package-file selection", "versions", "subject ownership", "applicability", "post-entry reading order", "cross-document conflicts")) {
            if ($resolverBody.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { $resolverFailures.Add("resolver omits $term") | Out-Null }
        }
        $sequenceLines = @([regex]::Matches($resolverBody, '(?m)^(?<Number>[0-9]+)\.\s+(?<Text>[^\r\n]+)\r?$'))
        if ($sequenceLines.Count -lt 6) { $resolverFailures.Add("numbered file-read sequence is missing or incomplete") | Out-Null }
        else {
            for ($sequenceIndex = 0; $sequenceIndex -lt $sequenceLines.Count; $sequenceIndex++) {
                if ([int]$sequenceLines[$sequenceIndex].Groups["Number"].Value -ne ($sequenceIndex + 1)) { $resolverFailures.Add("numbered file-read sequence is not unique and contiguous") | Out-Null; break }
            }
            $firstRead = $sequenceLines[0].Groups["Text"].Value
            $secondRead = $sequenceLines[1].Groups["Text"].Value
            $thirdRead = $sequenceLines[2].Groups["Text"].Value
            if ($firstRead.IndexOf("AGENTS.md", [System.StringComparison]::Ordinal) -lt 0 -or $secondRead.IndexOf("AI_READ_FIRST.md", [System.StringComparison]::Ordinal) -lt 0 -or $thirdRead.IndexOf("manifest", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { $resolverFailures.Add("file-read sequence does not start AGENTS.md, AI_READ_FIRST.md, then manifest") | Out-Null }
            if (@($sequenceLines | Where-Object { $_.Groups["Text"].Value -match '(?i)current user|user instruction' }).Count -gt 0) { $resolverFailures.Add("user authority is incorrectly represented as a file-read item") | Out-Null }
        }
        $genericPosition = $resolverBody.IndexOf("selected generic subject techniques", [System.StringComparison]::OrdinalIgnoreCase)
        $companionPosition = $resolverBody.IndexOf("selected Documentation Companion", [System.StringComparison]::OrdinalIgnoreCase)
        $gfiPosition = $resolverBody.IndexOf("frozen Game Forge Intelligence", [System.StringComparison]::OrdinalIgnoreCase)
        $gddPosition = $resolverBody.IndexOf("project-specific game-design", [System.StringComparison]::OrdinalIgnoreCase)
        $productPosition = $resolverBody.IndexOf("product- or plugin-owned", [System.StringComparison]::OrdinalIgnoreCase)
        if ($companionPosition -lt 0 -or $gfiPosition -le $companionPosition -or $genericPosition -le $gfiPosition -or $gddPosition -le $genericPosition -or $productPosition -le $gddPosition) { $resolverFailures.Add("post-entry companion, optional integration, generic, project-design, and subordinate-product order is not deterministic") | Out-Null }
    }

    $expectedSubjectOwners = @(
        "GeurtsTechniques/GeurtsTechnicalTechnique.md",
        "GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md",
        "GeurtsTechniques/GeurtsFolderStructureTechnique.md",
        "GeurtsTechniques/GeurtsFolderStructureDefinition.json",
        "GeurtsTechniques/GeurtsAIAgentSetupTechnique.md",
        "GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md",
        "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md",
        "GeurtsTechniques/GeurtsDocumentationCompanionContract.json",
        "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md",
        "GeurtsTechniques/GeurtsGitIgnoreTechnique.md",
        "GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md"
    )
    $subjectOwners = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    if ($subjectSection.Success) {
        $subjectRows = @([regex]::Matches($subjectSection.Groups["Body"].Value, '(?m)^\| (?<Subject>[^|]+) \| `(?<Owner>[^`]+)` \| (?<When>[^|]+) \|\r?$'))
        foreach ($subjectRow in $subjectRows) {
            $owner = $subjectRow.Groups["Owner"].Value
            if (-not $subjectOwners.Add($owner)) { $resolverFailures.Add("duplicate manifest subject owner '$owner'") | Out-Null }
            if (-not $registrySet.Contains($owner) -or -not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $owner) -PathType Leaf)) { $resolverFailures.Add("selected owner is absent from the tracked package: $owner") | Out-Null }
            if ([string]::IsNullOrWhiteSpace($subjectRow.Groups["When"].Value)) { $resolverFailures.Add("selected owner has no applicability rule: $owner") | Out-Null }
        }
        if ($subjectRows.Count -ne $expectedSubjectOwners.Count) { $resolverFailures.Add("subject-owner row count is not exactly $($expectedSubjectOwners.Count)") | Out-Null }
        foreach ($expectedOwner in $expectedSubjectOwners) { if (-not $subjectOwners.Contains($expectedOwner)) { $resolverFailures.Add("missing manifest subject owner '$expectedOwner'") | Out-Null } }
        if ($subjectSection.Groups["Body"].Value.IndexOf("current user's explicit instruction", [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -or $subjectSection.Groups["Body"].Value -notmatch '(?i)material conflict.*(?:surface|ask)') { $resolverFailures.Add("user authority and unresolved material conflicts are not handled in the conflict section") | Out-Null }
    }

    $alternateResolverFiles = New-Object System.Collections.Generic.List[string]
    foreach ($technique in @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Filter "*.md" -File)) {
        if ($technique.Name -ceq "GeurtsGameForgeIntelligenceIntegrationContract.md") { continue }
        $techniqueText = [System.IO.File]::ReadAllText($technique.FullName)
        if ($techniqueText -match '(?im)^##\s+(?:[0-9]+\.\s*)?Manifest Resolver\s*$' -or $techniqueText -match '(?im)^##\s+(?:[0-9]+\.\s*)?Subject Ownership and Applicability\s*$' -or $techniqueText -match '(?m)^\|\s*Subject\s*\|\s*Manifest-selected owner\s*\|') { $alternateResolverFiles.Add($technique.Name) | Out-Null }
    }
    if ($alternateResolverFiles.Count -gt 0) { $resolverFailures.Add("competing cross-document resolver structure: " + ($alternateResolverFiles -join ", ")) | Out-Null }
    Add-Check "Central manifest resolver" ($resolverFailures.Count -eq 0) $(if ($resolverFailures.Count) { $resolverFailures -join "; " } else { "The manifest alone defines a contiguous AGENTS-to-AI-to-manifest read sequence, selected owners, applicability, ordering, and conflict resolution; all selected paths exist." })

    $aiReadFirstText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "AI_READ_FIRST.md"))
    $aiCommitBoundaryValid = $aiReadFirstText -match "(?i)active package.?s single validated commit" -and $aiReadFirstText -notmatch '(?i)(?:manifest[^\r\n]{0,80}select(?:s|ed)?[^\r\n]{0,40}commit|commit[^\r\n]{0,40}selected by (?:the )?manifest)'
    $aiRouterValid = $aiReadFirstText -match '(?i)immediately continue to' -and $aiReadFirstText -match '(?i)GeurtsTechniqueManifest\.md' -and $aiReadFirstText -match '(?i)Do not inspect or select project GDD files here' -and $aiReadFirstText -match '(?i)manifest first decides whether the GDD Technique applies' -and $aiReadFirstText -notmatch '(?i)timestamp|fingerprint' -and $aiCommitBoundaryValid
    Add-Check "Second-stage package router" $aiRouterValid "AI_READ_FIRST routes immediately to the manifest, refers to the active package's validated commit without making the manifest select Git state, and performs no pre-manifest GDD inspection or fingerprint selection."

    $gitIgnoreFailures = New-Object System.Collections.Generic.List[string]
    $gitIgnoreRelative = "GeurtsTechniques/GeurtsGitIgnoreTechnique.md"
    $gitIgnorePath = Join-Path $RepositoryRoot $gitIgnoreRelative
    $gitIgnoreText = $null
    if (-not (Test-Path -LiteralPath $gitIgnorePath -PathType Leaf)) {
        $gitIgnoreFailures.Add("technique is missing") | Out-Null
    }
    else {
        try {
            $gitIgnoreBytes = [System.IO.File]::ReadAllBytes($gitIgnorePath)
            $gitIgnoreOffset = 0
            if ($gitIgnoreBytes.Length -ge 3 -and $gitIgnoreBytes[0] -eq 0xEF -and $gitIgnoreBytes[1] -eq 0xBB -and $gitIgnoreBytes[2] -eq 0xBF) { $gitIgnoreOffset = 3 }
            $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
            $gitIgnoreText = $strictUtf8.GetString($gitIgnoreBytes, $gitIgnoreOffset, $gitIgnoreBytes.Length - $gitIgnoreOffset)
        }
        catch { $gitIgnoreFailures.Add("technique is not valid UTF-8") | Out-Null }
    }

    if ($null -ne $gitIgnoreText) {
        if ([regex]::Matches($gitIgnoreText, 'GEURTS-GITIGNORE-BEGIN').Count -ne 1 -or [regex]::Matches($gitIgnoreText, 'GEURTS-GITIGNORE-END').Count -ne 1) {
            $gitIgnoreFailures.Add("marker count is invalid") | Out-Null
        }
        $gitIgnorePattern = '(?ms)^<!-- GEURTS-GITIGNORE-BEGIN version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)" target="(?<Target>[^"]+)" sha256="(?<Hash>[0-9a-f]{64})" -->\r?\n```gitignore\r?\n(?<Payload>.*?)^```\r?\n<!-- GEURTS-GITIGNORE-END -->(?:\r?\n)?\z'
        $gitIgnoreMatches = @([regex]::Matches($gitIgnoreText, $gitIgnorePattern))
        if ($gitIgnoreMatches.Count -ne 1) {
            $gitIgnoreFailures.Add("marker or fence grammar is invalid") | Out-Null
        }
        else {
            $gitIgnoreMatch = $gitIgnoreMatches[0]
            $techniqueVersion = Get-DeclaredVersion -Path $gitIgnorePath
            if ($techniqueVersion -cne "1.0.0" -or $gitIgnoreMatch.Groups["Version"].Value -cne $techniqueVersion) { $gitIgnoreFailures.Add("template version is invalid") | Out-Null }
            if ($gitIgnoreMatch.Groups["Target"].Value -cne ".gitignore") { $gitIgnoreFailures.Add("target is not ordinal-exact .gitignore") | Out-Null }
            $payload = $gitIgnoreMatch.Groups["Payload"].Value
            if ($payload.Length -gt 0 -and $payload[0] -eq [char]0xFEFF) { $gitIgnoreFailures.Add("payload contains a byte-order mark") | Out-Null }
            $normalizedPayload = $payload -replace "`r`n", "`n" -replace "`r", "`n"
            if (-not $normalizedPayload.EndsWith("`n") -or $normalizedPayload.EndsWith("`n`n")) { $gitIgnoreFailures.Add("payload terminal newline is invalid") | Out-Null }
            if ([regex]::Matches($normalizedPayload, "`n").Count -ne 376) { $gitIgnoreFailures.Add("payload logical line count is not 376") | Out-Null }
            $expectedNormalizedHash = "7223a9449718942d3a5cad00cf4d4e0dee9c89eb64951541fa4ebfb803acb45b"
            if ($gitIgnoreMatch.Groups["Hash"].Value -cne $expectedNormalizedHash -or (Get-TextHash -Text $normalizedPayload) -cne $expectedNormalizedHash) { $gitIgnoreFailures.Add("normalized payload hash is invalid") | Out-Null }

            $sourceSha = [System.Security.Cryptography.SHA256]::Create()
            try { $approvedSourceHash = ([System.BitConverter]::ToString($sourceSha.ComputeHash($strictUtf8.GetBytes($normalizedPayload.Replace("`n", "`r`n"))))).Replace("-", "").ToLowerInvariant() }
            finally { $sourceSha.Dispose() }
            if ($approvedSourceHash -cne "c8412a38435bccd89f1fefb855da3c24680612c27609341e64dcbaf99c0f88ab") { $gitIgnoreFailures.Add("approved CRLF source hash is invalid") | Out-Null }
        }
    }

    $gfiTechniquePath = Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"
    $gfiTechniqueText = if (Test-Path -LiteralPath $gfiTechniquePath -PathType Leaf) { [System.IO.File]::ReadAllText($gfiTechniquePath) } else { "" }
    $gitIgnoreOwnerRow = [regex]::Match($manifestText, '(?m)^\| Approved project-root `\.gitignore` payload \| `GeurtsTechniques/GeurtsGitIgnoreTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    if (-not $gitIgnoreOwnerRow.Success -or $gitIgnoreOwnerRow.Groups["When"].Value -notmatch '(?i)exact payload') { $gitIgnoreFailures.Add("manifest does not select the Git Ignore Technique as the exact-payload owner") | Out-Null }
    if ($gitIgnoreText -notmatch '(?i)fallbackPolicy:\s*none' -or $gitIgnoreText -notmatch '(?i)literal imported compatibility source' -or $gitIgnoreText -notmatch '(?i)comments inside the fenced payload are preserved source content') { $gitIgnoreFailures.Add("technique does not preserve the imported compatibility asset and no-fallback boundary") | Out-Null }
    $gitIgnoreAuthorizationValid = $gitIgnoreText -match '(?i)explicit(?:ly)? (?:user[- ]?)?authori[sz]'
    $gitIgnoreMissingTargetValid = $gitIgnoreText -match '(?i)target is missing' -and $gitIgnoreText -match '(?i)(?:create|write)[^\r\n]{0,120}(?:only when|only if)[^\r\n]{0,120}(?:validates exactly|exact payload)'
    $gitIgnoreMatchingTargetValid = $gitIgnoreText -match '(?i)(?:identical|matches)[^\r\n]{0,100}(?:target|payload)' -and $gitIgnoreText -match '(?i)(?:report(?:ed)?[^\r\n]{0,80}(?:unchanged|match)|without rewriting|not rewrite)'
    $gitIgnoreDifferingTargetValid = $gitIgnoreText -match '(?i)(?:target|file)[^\r\n]{0,100}(?:differs|different)' -and $gitIgnoreText -match '(?i)preserve[^\r\n]{0,80}bytes[^\r\n]{0,80}timestamp' -and $gitIgnoreText -match '(?i)conflict'
    $gitIgnoreMutationBoundaryValid = $gitIgnoreText -match '(?i)never[^\r\n]{0,120}append' -and $gitIgnoreText -match '(?i)never[^\r\n]{0,160}merge' -and $gitIgnoreText -match '(?i)never[^\r\n]{0,160}replace' -and $gitIgnoreText -match '(?i)never[^\r\n]{0,160}reformat'
    $gitIgnoreIndexBoundaryValid = $gitIgnoreText -match '(?i)(?:no|never|must not)[^\r\n]{0,100}Git (?:index|tracking state)' -and $gitIgnoreText -match '(?i)never[^\r\n]{0,120}(?:stage|unstage|add|remove)'
    $gitIgnoreProvisioningValid = $gitIgnoreAuthorizationValid -and $gitIgnoreMissingTargetValid -and $gitIgnoreMatchingTargetValid -and $gitIgnoreDifferingTargetValid -and $gitIgnoreMutationBoundaryValid -and $gitIgnoreIndexBoundaryValid
    if (-not $gitIgnoreProvisioningValid) { $gitIgnoreFailures.Add("technique does not define the full authorized create-if-missing, exact-match, differing-target preservation, and Git-index boundary") | Out-Null }
    if ($gfiTechniqueText.Contains("GEURTS-GITIGNORE-BEGIN") -or $gfiTechniqueText -match '(?ms)```gitignore.*?```') { $gitIgnoreFailures.Add("Game Forge Intelligence technique duplicates the payload instead of deferring to its subject owner") | Out-Null }
    Add-Check "Custom .gitignore payload" ($gitIgnoreFailures.Count -eq 0) $(if ($gitIgnoreFailures.Count) { $gitIgnoreFailures -join "; " } else { "The v1.0.0 literal imported compatibility payload retains exact bytes; its subject owner alone defines explicit create-if-missing authorization, identical no-rewrite, differing-target conflict/preservation, no merge or replacement, and no Git-index mutation." })

    $requiredPathFailures = New-Object System.Collections.Generic.List[string]
    $legacyGfiRedirectRelative = "GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md"
    foreach ($technique in @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Filter "*.md" -File)) {
        $relative = "GeurtsTechniques/" + $technique.Name
        if ($relative -ceq $legacyGfiRedirectRelative) { continue }
        $text = [System.IO.File]::ReadAllText($technique.FullName)
        $expectedRequiredPath = "**Required package path:** " + [char]96 + $relative + [char]96
        if ($text -notmatch [regex]::Escape($expectedRequiredPath)) { $requiredPathFailures.Add($relative) | Out-Null }
    }
    Add-Check "Technique required-path metadata" ($requiredPathFailures.Count -eq 0) $(if ($requiredPathFailures.Count) { "Missing or incorrect required package path metadata: " + ($requiredPathFailures -join ", ") } else { "Every normative technique declares its required package path; the legacy redirect is checked separately." })

    $plainPathFailures = New-Object System.Collections.Generic.List[string]
    $packageMetadataPaths = @("AI_READ_FIRST.md", "GeurtsTechniqueManifest.md")
    $packageMetadataPaths += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Filter "*.md" -File | ForEach-Object { "GeurtsTechniques/" + $_.Name } | Where-Object { $_ -cne $legacyGfiRedirectRelative })
    $packageMetadataPaths += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "Ideas") -Filter "*.md" -File | ForEach-Object { "Ideas/" + $_.Name })
    $packageMetadataPaths += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "Migrations") -Filter "*.md" -File | ForEach-Object { "Migrations/" + $_.Name })
    foreach ($relative in $packageMetadataPaths) {
        $text = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $relative))
        $expected = "**Required package path:** " + [char]96 + $relative + [char]96
        if (-not $text.Contains($expected)) { $plainPathFailures.Add("$relative does not declare its required package path") | Out-Null }
    }
    foreach ($projectMetadata in @(
        @{ File = "Tools/AIAgentInstructionTemplates/GameDesign/README.md"; Required = "Docs/GameDesign/README.md" },
        @{ File = "Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md"; Required = "Docs/GameDesign/GameDesignManifest.md" }
    )) {
        $text = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $projectMetadata.File))
        $expected = "**Required project path:** " + [char]96 + $projectMetadata.Required + [char]96
        if (-not $text.Contains($expected)) { $plainPathFailures.Add("$($projectMetadata.File) does not declare its required project path") | Out-Null }
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text.Replace("canonicalPath", "").Replace("CanonicalPath", "") -match '(?i)\bcanonical(?: package| project)? path\b') {
            $plainPathFailures.Add("$($file.FullName.Substring($RepositoryRoot.Length).TrimStart([char]92, [char]47)) contains obsolete human-facing path terminology") | Out-Null
        }
    }
    $folderTechniqueTextForPathTerms = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureTechnique.md"))
    $readmeTextForPathTerms = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "README.md"))
    if ($folderTechniqueTextForPathTerms -notmatch '(?i)`canonicalPath`[^\r\n]{0,100}legacy serialized compatibility key' -or $readmeTextForPathTerms -notmatch '(?i)`canonicalPath`[^\r\n]{0,100}legacy serialized compatibility') {
        $plainPathFailures.Add("canonicalPath is not explicitly documented as a legacy serialized compatibility key") | Out-Null
    }
    Add-Check "Plain-language path terminology" ($plainPathFailures.Count -eq 0) $(if ($plainPathFailures.Count) { $plainPathFailures -join "; " } else { "Human-facing metadata uses required package/project paths; canonicalPath remains only as an explicitly documented legacy serialized compatibility key." })

    $legacyGfiRedirectPath = Join-Path $RepositoryRoot $legacyGfiRedirectRelative
    $legacyGfiRedirectText = if (Test-Path -LiteralPath $legacyGfiRedirectPath -PathType Leaf) { [System.IO.File]::ReadAllText($legacyGfiRedirectPath) } else { "" }
    $subjectSectionForRedirect = [regex]::Match($manifestText, '(?ms)^## 2\. Subject Ownership and Applicability\s*(?<Body>.*?)(?=^## 3\.)')
    $redirectRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract\.md` \| 2\.0\.0 \| (?<Role>[^|]+) \|\r?$')
    $redirectValid = $legacyGfiRedirectText.StartsWith("# Moved: Geurts Game Forge Intelligence Integration Contract", [System.StringComparison]::Ordinal) -and $legacyGfiRedirectText.Contains("**Version:** 2.0.0") -and $legacyGfiRedirectText.Contains("**Status:** Non-normative compatibility redirect") -and $legacyGfiRedirectText.Contains('**Legacy compatibility redirect path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`') -and $legacyGfiRedirectText.Contains("GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md") -and $legacyGfiRedirectText -match '(?i)former v1 stateful launch-check/download, transaction, rollback, recovery, drift-preservation, and reintegration lifecycle is obsolete' -and $legacyGfiRedirectText -match '(?i)notification-and-manual-update contract' -and $legacyGfiRedirectText -match '(?i)fail closed' -and -not $legacyGfiRedirectText.Contains("**Required package path:**") -and -not $legacyGfiRedirectText.Contains("| Subject |") -and $legacyGfiRedirectText.Length -lt 2000 -and $redirectRegistryRow.Success -and $redirectRegistryRow.Groups["Role"].Value -match '(?i)non-normative compatibility redirect' -and $redirectRegistryRow.Groups["Role"].Value -match '(?i)never selected' -and $subjectSectionForRedirect.Success -and $subjectSectionForRedirect.Groups["Body"].Value.IndexOf($legacyGfiRedirectRelative, [System.StringComparison]::Ordinal) -lt 0
    Add-Check "Frozen GFI v2 compatibility redirect" $redirectValid "The legacy path is a short v2 non-normative fail-closed pointer that marks the v1 automatic transaction/recovery lifecycle obsolete and cannot become a second owner."

    $gfiRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique\.md` \| 2\.0\.0 \| (?<Role>[^|]+) \|\r?$')
    $gfiLifecycleOwnerRow = [regex]::Match($manifestText, '(?m)^\| Frozen Game Forge Intelligence 2\.0 integration compatibility \| `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    $activeGfiContractSurfaceText = @($gfiTechniqueText, $gfiMigrationText) -join [Environment]::NewLine
    $packageAvailabilityContradiction = $activeGfiContractSurfaceText -match '(?i)package[- ]version(?: ordering| equality| inequality)?\s+(?:alone\s+)?(?:determines|may determine|can determine)[^\r\n]{0,120}(?:availability|Update is available)'
    $sourceBoundaryValid = $gfiTechniqueText -match '(?im)^\*\*Version:\*\*\s*2\.0\.0\s*$' -and $gfiTechniqueText -match '(?im)^\*\*Compatibility schema:\*\*\s*2\.0\.0\s*$' -and $gfiRegistryRow.Success -and $gfiRegistryRow.Groups["Role"].Value -match '(?i)Frozen released-consumer compatibility technique' -and $gfiRegistryRow.Groups["Role"].Value -match '(?i)schema-2\.0\.0 updater is superseded and non-applicable under package v0\.11\.3' -and $gfiLifecycleOwnerRow.Success -and $gfiLifecycleOwnerRow.Groups["When"].Value -match '(?i)Only when maintaining or assessing a released v2 consumer' -and $gfiLifecycleOwnerRow.Groups["When"].Value -match '(?i)historical updater is non-applicable under package v0\.11\.3' -and $gfiLifecycleOwnerRow.Groups["When"].Value -match '(?i)current setup, checking, and Update belong exclusively to the Documentation Companion' -and $gfiTechniqueText.Contains("https://github.com/Geurtsy/GeurtsGameForge_Documentation.git") -and $gfiTechniqueText -match '(?im)^Branch:\s*main\s*$' -and $gfiTechniqueText -match '(?i)sole primary source and authority for all Geurts Game Forge documentation' -and $gfiTechniqueText -match '(?i)documentation update[^\r\n]{0,120}must not require[^\r\n]{0,80}Unity-package release' -and $gfiTechniqueText -match '(?i)`<PluginPackageRoot>/Documentation~/`[^\r\n]{0,140}only plugin-specific' -and $gfiTechniqueText -match '(?i)must not embed, duplicate, redefine, or become authority' -and $gfiTechniqueText -match '(?i)must not ship a bundled or fallback copy of Geurts documentation' -and $activeGfiContractSurfaceText -notmatch '(?i)(?:may|must|shall)\s+(?:embed|bundle|duplicate)[^\r\n]{0,120}Geurts[^\r\n]{0,120}Documentation~'
    Add-Check "Frozen GFI v2 source and compatibility boundary" $sourceBoundaryValid "The internally validated schema-2.0.0 contract remains available only for released-consumer compatibility; package v0.11.3 assigns current setup, checking, and Update exclusively to the Documentation Companion."

    $manualTriggerValid = $gfiTechniqueText -match '(?i)There is one live project-local Geurts documentation copy' -and $gfiTechniqueText -match '(?i)On each normal Unity project launch or open[^\r\n]{0,180}exactly one lightweight remote metadata check' -and $gfiTechniqueText -match '(?i)obtains the authoritative current `main` head commit ID' -and $gfiTechniqueText -match '(?i)Update availability is determined only by commit identity' -and $gfiTechniqueText -match '(?is)exact destination directory exists.{0,300}remote `main` head commit ID differs.{0,120}Update is available' -and $gfiTechniqueText -match '(?i)commit IDs are identical, do not report an Update' -and $gfiTechniqueText -match '(?i)Package-version ordering or inequality is display-only and must not determine availability' -and $gfiTechniqueText -match '(?is)remote head commit ID is unavailable.{0,260}exact destination is absent.{0,260}no current receipt with a valid installed commit ID.{0,260}startup comparison result is unknown' -and $gfiTechniqueText -match '(?i)do not claim that an Update is available or that the installed copy is current by inspecting local files or comparing package versions' -and $gfiTechniqueText -match '(?i)notification check must not download documentation, install or synchronize files, inspect or hash the project-local copy, mutate any project path, recover content, or run reintegration' -and $gfiTechniqueText -match '(?i)failed or unavailable metadata request is non-blocking and leaves the local copy usable' -and $gfiTechniqueText -match '(?i)Ordinary AI/session initialization uses the existing local copy and performs no additional remote documentation check' -and $gfiTechniqueText -match '(?i)Local edits inside the detached writable copy do not affect update availability' -and $gfiTechniqueText -match '(?i)project-local copy is missing[^\r\n]{0,160}documentation as unavailable' -and $gfiTechniqueText -match '(?i)must not install, reconstruct, recover, or fetch it automatically' -and $gfiTechniqueText -match '(?i)only by explicitly invoking the Update action' -and $gfiTechniqueText -match '(?i)exposes exactly one documentation lifecycle action labelled' -and $gfiTechniqueText.Contains("Update Geurts Game Forge Documentation") -and $gfiMigrationText -match '(?i)remote head commit ID differs[^\r\n]{0,180}current installed receipt' -and $gfiMigrationText -match '(?i)Package version is display-only and never determines availability' -and $gfiMigrationText -match '(?i)no valid installed commit ID, availability is unknown' -and -not $packageAvailabilityContradiction
    Add-Check "Frozen GFI v2 startup and manual trigger" $manualTriggerValid "The frozen released-consumer contract retains its internally coherent metadata-only launch check and explicit manual Update semantics without authorizing package-v0.11.3 behavior."

    $versionDisplayValid = $gfiTechniqueText.Contains("Installed Geurts Documentation: <version | Not installed | Unknown>") -and $gfiTechniqueText.Contains("GameForgeIntelligence Plugin: <version | Unknown>") -and $gfiTechniqueText -match '(?i)`Installed Geurts Documentation` comes only from the valid package-version field in the current installed receipt' -and $gfiTechniqueText -match '(?i)Never derive, refresh, or override that displayed version by reading, parsing, or hashing mutable project-local documentation files' -and $gfiTechniqueText -match '(?i)`Not installed` whenever the exact project-local destination is known to be missing, regardless of any receipt or retained history' -and $gfiTechniqueText -match '(?i)check only whether that exact directory exists[^\r\n]{0,160}must not inspect its contents' -and $gfiTechniqueText -match '(?i)`Unknown` when the directory exists but there is no current installed receipt[^\r\n]{0,220}new copy was not completed successfully' -and $gfiTechniqueText -match '(?i)recorded package version when the directory exists and the current installed receipt contains both a valid authoritative selected commit ID and a valid authoritative package version' -and $gfiTechniqueText -match '(?i)`GameForgeIntelligence Plugin` comes only from the canonical installed Unity package metadata for `com\.gameforge\.intelligence`' -and $gfiTechniqueText -match '(?i)Show `Unknown` if that canonical plugin version is unavailable or invalid' -and $gfiTechniqueText.Contains("Available Geurts Documentation: <version>") -and $gfiTechniqueText.Contains("Available Geurts Documentation: Update available (version unknown)") -and $gfiTechniqueText -match '(?i)available package version is display-only and never changes the commit-identity result' -and $gfiTechniqueText -match '(?i)package version, Game Forge Intelligence Technique version, compatibility schema version, and GameForgeIntelligence plugin version are distinct values' -and $gfiTechniqueText -match '(?i)label them separately as `Integration Technique` and `Compatibility Schema`' -and $activeGfiContractSurfaceText -notmatch '(?i)(?:may|must|shall)\s+(?:display|use)[^\r\n]{0,120}(?:compatibility schema|integration technique)[^\r\n]{0,120}(?:as|for)\s+(?:the\s+)?(?:installed Geurts Documentation|GameForgeIntelligence Plugin)' -and $gfiMigrationText -match '(?i)known missing destination shows `Not installed`' -and $gfiMigrationText -match '(?i)existing copy without a trustworthy current receipt and valid package version shows `Unknown`'
    Add-Check "Frozen GFI v2 separated versions" $versionDisplayValid "The frozen released-consumer contract keeps its documentation, plugin, technique, and schema values internally distinct."

    $companionTechniqueRelative = "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"
    $companionContractRelative = "GeurtsTechniques/GeurtsDocumentationCompanionContract.json"
    $companionTechniquePath = Join-Path $RepositoryRoot $companionTechniqueRelative
    $companionContractPath = Join-Path $RepositoryRoot $companionContractRelative
    $companionTechniqueText = if (Test-Path -LiteralPath $companionTechniquePath -PathType Leaf) { [System.IO.File]::ReadAllText($companionTechniquePath) } else { "" }
    $companionContractText = if (Test-Path -LiteralPath $companionContractPath -PathType Leaf) { [System.IO.File]::ReadAllText($companionContractPath) } else { "" }
    $companionContractFailures = New-Object System.Collections.Generic.List[string]
    $companionContract = $null
    if ([string]::IsNullOrWhiteSpace($companionContractText)) {
        $companionContractFailures.Add("contract file is missing or empty") | Out-Null
    }
    else {
        try { $companionContract = $companionContractText | ConvertFrom-Json }
        catch { $companionContractFailures.Add("contract JSON is invalid") | Out-Null }
    }

    $expectedValidationEntries = @(
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
    $expectedRouteMappings = @(
        [pscustomobject]@{ Template = "Tools/AIAgentInstructionTemplates/AGENTS.md"; Target = "AGENTS.md" },
        [pscustomobject]@{ Template = "Tools/AIAgentInstructionTemplates/copilot-instructions.md"; Target = ".github/copilot-instructions.md" },
        [pscustomobject]@{ Template = "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md"; Target = ".github/instructions/geurts-unity.instructions.md" },
        [pscustomobject]@{ Template = "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"; Target = ".github/instructions/geurts-game-design.instructions.md" }
    )

    if ($companionContract) {
        if (-not (Test-ExactPropertySet -Object $companionContract -Expected @("schemaVersion", "packageVersion", "source", "destination", "validationEntries", "updateUi", "routeMappings"))) { $companionContractFailures.Add("top-level property set is not closed") | Out-Null }
        if ([string]$companionContract.schemaVersion -cne "1.0.0" -or [string]$companionContract.packageVersion -cne "0.11.3" -or [string]$companionContract.packageVersion -cne [string]$packageVersion) { $companionContractFailures.Add("schemaVersion, current packageVersion, or manifest parity is invalid") | Out-Null }

        if (-not (Test-ExactPropertySet -Object $companionContract.source -Expected @("repository", "branch", "selection"))) { $companionContractFailures.Add("source property set is not closed") | Out-Null }
        elseif ([string]$companionContract.source.repository -cne "https://github.com/Geurtsy/GeurtsGameForge_Documentation.git" -or [string]$companionContract.source.branch -cne "main" -or [string]$companionContract.source.selection -cne "exact-resolved-head-commit-archive") { $companionContractFailures.Add("official repository/main exact-commit archive source differs") | Out-Null }

        if (-not (Test-ExactPropertySet -Object $companionContract.destination -Expected @("projectRelativePath", "replacement", "access"))) { $companionContractFailures.Add("destination property set is not closed") | Out-Null }
        elseif ([string]$companionContract.destination.projectRelativePath -cne "GeurtsGameForgeDocumentation" -or [string]$companionContract.destination.replacement -cne "complete-directory" -or [string]$companionContract.destination.access -cne "logically-read-only") { $companionContractFailures.Add("managed documentation destination differs") | Out-Null }

        if (-not (Test-ExactStringSequence -Actual @($companionContract.validationEntries) -Expected $expectedValidationEntries)) { $companionContractFailures.Add("current validationEntries is not the exact nine-entry package-v0.11.3 list") | Out-Null }
        $validationEntrySet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($validationEntry in @($companionContract.validationEntries)) {
            $validationRelative = [string]$validationEntry
            if (-not $validationEntrySet.Add($validationRelative) -or -not (Test-SafeDefinitionPath -Path $validationRelative) -or -not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $validationRelative) -PathType Leaf)) { $companionContractFailures.Add("validation entry is duplicate, unsafe, or absent: $validationRelative") | Out-Null }
        }

        if (-not (Test-ExactPropertySet -Object $companionContract.updateUi -Expected @("actionLabel", "confirmationDefault", "cancelResult", "confirmationTargets"))) { $companionContractFailures.Add("updateUi property set is not closed") | Out-Null }
        elseif ([string]$companionContract.updateUi.actionLabel -cne "Update Geurts Game Forge Documentation" -or [string]$companionContract.updateUi.confirmationDefault -cne "cancel" -or [string]$companionContract.updateUi.cancelResult -cne "no-network-or-filesystem-change") { $companionContractFailures.Add("Update action or cancel behavior differs") | Out-Null }

        $confirmationTargets = @($companionContract.updateUi.confirmationTargets)
        if ($confirmationTargets.Count -ne 5) { $companionContractFailures.Add("confirmation target count is not exactly five") | Out-Null }
        else {
            $expectedConfirmationPaths = @("GeurtsGameForgeDocumentation") + @($expectedRouteMappings | ForEach-Object { $_.Target })
            for ($confirmationIndex = 0; $confirmationIndex -lt $confirmationTargets.Count; $confirmationIndex++) {
                $confirmationTarget = $confirmationTargets[$confirmationIndex]
                $expectedEffect = if ($confirmationIndex -eq 0) { "replace-complete-directory" } else { "replace-complete-file" }
                if (-not (Test-ExactPropertySet -Object $confirmationTarget -Expected @("path", "effect")) -or [string]$confirmationTarget.path -cne $expectedConfirmationPaths[$confirmationIndex] -or [string]$confirmationTarget.effect -cne $expectedEffect) { $companionContractFailures.Add("confirmation target $confirmationIndex differs from the exact path/effect list") | Out-Null }
            }
        }

        $routeMappings = @($companionContract.routeMappings)
        $routeTargets = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        $routeTemplates = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        if ($routeMappings.Count -ne 4) { $companionContractFailures.Add("route mapping count is not exactly four") | Out-Null }
        else {
            for ($routeIndex = 0; $routeIndex -lt $routeMappings.Count; $routeIndex++) {
                $routeMapping = $routeMappings[$routeIndex]
                $template = [string]$routeMapping.template
                $target = [string]$routeMapping.target
                if (-not (Test-ExactPropertySet -Object $routeMapping -Expected @("template", "target")) -or $template -cne $expectedRouteMappings[$routeIndex].Template -or $target -cne $expectedRouteMappings[$routeIndex].Target) { $companionContractFailures.Add("route mapping $routeIndex differs from the exact template-to-target list") | Out-Null }
                if (-not $routeTemplates.Add($template) -or -not $routeTargets.Add($target)) { $companionContractFailures.Add("duplicate route template or target") | Out-Null }
                if (-not (Test-SafeDefinitionPath -Path $template) -or -not (Test-SafeDefinitionPath -Path $target) -or -not (Test-Path -LiteralPath (Join-Path $RepositoryRoot $template) -PathType Leaf)) { $companionContractFailures.Add("route mapping is unsafe or its template is absent: $template -> $target") | Out-Null }
            }
        }
    }
    Add-Check "Documentation companion closed contract" ($companionContractFailures.Count -eq 0) $(if ($companionContractFailures.Count) { $companionContractFailures -join "; " } else { "The current schema-1.0.0/package-v0.11.3 source contract fixes the official exact-commit archive, one managed directory, nine validation entries, one five-target confirmation, and four exact full-file route mappings." })

    $companionForwardCompatibilityValid = $companionTechniqueText -match '(?i)`packageVersion` is source-release metadata, not a companion compatibility gate' -and $companionTechniqueText -match '(?i)valid version and exactly match the package manifest in the same archive' -and $companionTechniqueText -match '(?i)later package version alone must not require a companion release while schema 1\.0\.0 remains supported' -and $companionTechniqueText -match '(?i)`validationEntries` is the archive.?s closed current completeness list' -and $companionTechniqueText -match '(?i)schema-1\.0\.0 consumer may read a later list rather than pinning v0\.11\.0' -and $companionTechniqueText -match '(?i)every entry must be unique, safe, readable, and archive-root-relative before mutation' -and $companionTechniqueText -match '(?i)Validation entries grant no project-read or project-write authority'
    Add-Check "Companion schema forward compatibility" $companionForwardCompatibilityValid "Schema 1.0.0 pins mutation paths, not documentation releases: packageVersion must match the same archive manifest, and later safe validation-entry lists remain consumable without a companion release."

    $companionTechniqueRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsDocumentationCompanionTechnique\.md` \| 1\.0\.1 \| (?<Role>[^|]+) \|\r?$')
    $companionContractRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsDocumentationCompanionContract\.json` \| 0\.11\.3 \| (?<Role>[^|]+) \|\r?$')
    $companionOwnerRow = [regex]::Match($manifestText, '(?m)^\| Independent Windows Unity Editor companion source, metadata check, confirmed replacement, project-boundary, and AI-routing lifecycle \| `GeurtsTechniques/GeurtsDocumentationCompanionTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    $companionContractOwnerRow = [regex]::Match($manifestText, '(?m)^\| Exact companion source, documentation destination, validation entries, confirmation targets, and template-to-route mappings \| `GeurtsTechniques/GeurtsDocumentationCompanionContract\.json` \| (?<When>[^|]+) \|\r?$')
    $companionArchitectureValid = $companionTechniqueText -match '(?im)^\*\*Version:\*\*\s*1\.0\.1\s*$' -and $companionTechniqueText -match '(?im)^\*\*Contract schema:\*\*\s*1\.0\.0\s*$' -and $companionTechniqueText -match '(?im)^\*\*Package version:\*\*\s*0\.11\.3\s*$' -and $companionTechniqueRegistryRow.Success -and $companionTechniqueRegistryRow.Groups["Role"].Value -match '(?i)independent Windows Editor-only UPM documentation companion' -and $companionTechniqueRegistryRow.Groups["Role"].Value -match '(?i)contract schema 1\.0\.0' -and $companionContractRegistryRow.Success -and $companionContractRegistryRow.Groups["Role"].Value -match '(?i)package version 0\.11\.3' -and $companionContractRegistryRow.Groups["Role"].Value -match '(?i)schema 1\.0\.0' -and $companionOwnerRow.Success -and $companionOwnerRow.Groups["When"].Value -match '(?i)checks metadata.*offers or performs Update.*validates a candidate.*replaces managed content' -and $companionContractOwnerRow.Success -and $companionContractOwnerRow.Groups["When"].Value -match '(?i)Technique is selected.*schema is implemented or validated' -and $companionTechniqueText -match '(?i)Windows-only.*Editor-only Unity package installed into an existing Unity project through Unity Package Manager from its separate `Geurtsy/com\.geurts\.gameforge\.documentation` Git repository' -and $companionTechniqueText -match '(?i)no dependency on any other Unity package, including Geurts Game Forge God, Odin Inspector, Quantum Console, or Game Forge Intelligence' -and $companionTechniqueText -match '(?i)sole source and authority for generic Geurts Game Forge documentation' -and $companionTechniqueText -match '(?i)contains no Documentation Companion plugin code' -and $companionTechniqueText -match '(?i)There is no external installer, Windows bootstrap, batch-driven setup, or separate companion setup action'
    Add-Check "Documentation companion architecture boundary" $companionArchitectureValid "The manifest selects a schema-1.0.0 independent Windows-only, Editor-only UPM companion from its named package repository, while this package remains the sole generic-documentation authority and contains no companion implementation."

    $forbiddenPluginPaths = @($trackedPaths | Where-Object { [System.IO.Path]::GetFileName($_) -ceq "package.json" -or [System.IO.Path]::GetExtension($_) -in @(".cs", ".asmdef", ".asmref") })
    Add-Check "No Unity companion implementation in documentation source" ($forbiddenPluginPaths.Count -eq 0) $(if ($forbiddenPluginPaths.Count) { "Unity package implementation files are tracked here: " + ($forbiddenPluginPaths -join ", ") } else { "No package.json, C#, asmdef, or asmref implementation file is tracked in this documentation repository." })

    $companionActiveSurfaceText = @($companionTechniqueText, $manifestText, $aiReadFirstText, $readmeTextForPathTerms, $targetMigrationText) -join [Environment]::NewLine
    $startupMutationContradiction = $companionActiveSurfaceText -match '(?i)the companion automatically (?:downloads?|installs?|replaces?|repairs?|synchroni[sz]es?|mutates?)[^\r\n]{0,120}(?:at|during|on) Unity (?:project )?(?:launch|open|startup)' -or $companionActiveSurfaceText -match '(?i)(?:at|during|on) Unity (?:project )?(?:launch|open|startup),? the companion automatically (?:downloads?|installs?|replaces?|repairs?|synchroni[sz]es?|mutates?)'
    $companionStartupValid = $companionTechniqueText -match '(?i)On each normal Unity project launch or open[^\r\n]{0,180}may perform at most one lightweight metadata-only request' -and $companionTechniqueText -match '(?i)official repository.?s current `main` head commit' -and $companionTechniqueText -match '(?i)compares that remote commit ID with one (?:persistent )?companion-owned last-successful-installed commit value for this Unity project' -and $companionTechniqueText -match '(?i)held outside the Unity project filesystem and outside the installed UPM package' -and $companionTechniqueText -match '(?i)keyed by a Unity-provided project identity or normalized project-root path derived without reading project content' -and $companionTechniqueText -match '(?i)value for one project must never suppress availability in another' -and $companionTechniqueText -match '(?i)must not create a project file or project path for this value' -and $companionTechniqueText -match '(?i)Update is available when the last-successful-installed commit value is missing or differs' -and $companionTechniqueText -match '(?i)Matching values mean only that the authoritative source has not advanced' -and $companionTechniqueText -match '(?i)When the remote commit is unavailable, availability is unknown' -and $companionTechniqueText -match '(?i)must not download an archive, inspect the managed documentation copy, inspect any AI target, mutate a managed project target, execute setup work, or synchronize content' -and $companionTechniqueText -match '(?i)skipped, failed, or unavailable request is non-blocking' -and $companionTechniqueText -match '(?i)explicit Update action remains available in every state' -and $companionTechniqueText -match '(?i)Ordinary AI-session initialization performs no additional remote check' -and $companionTechniqueText -match '(?i)comparison-only, non-authoritative, and non-blocking' -and $companionTechniqueText -match '(?i)not a receipt, package-version record, compatibility state' -and $companionTechniqueText -match '(?i)write is attempted only after full managed-target success' -and -not $startupMutationContradiction
    Add-Check "Companion metadata-only startup" $companionStartupValid "Unity-open may perform at most one non-blocking remote-head metadata comparison, keyed outside the project/package per Unity project; it never downloads, inspects, executes setup, or mutates."

    $companionUpdateSection = [regex]::Match($companionTechniqueText, '(?ms)^## 6\. Confirmed Update Sequence\s*(?<Body>.*?)(?=^## 7\.)')
    $companionUpdateBody = if ($companionUpdateSection.Success) { $companionUpdateSection.Groups["Body"].Value } else { "" }
    $companionUpdatePositions = @(
        $companionUpdateBody.IndexOf('Resolve the official repository''s current `main` head commit', [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf("Download an archive pinned to that exact commit", [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf("Perform basic pre-mutation validation", [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf('Delete any existing `<ProjectRoot>/GeurtsGameForgeDocumentation/`', [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf("Directly replace each of the four AI target files", [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf("Verify that the complete documentation destination and all four mapped target files were written successfully", [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf("After every managed-target verification passes", [System.StringComparison]::Ordinal),
        $companionUpdateBody.IndexOf("Remove temporary acquisition content on a best-effort basis", [System.StringComparison]::Ordinal)
    )
    $companionUpdateOrderValid = $companionUpdateSection.Success -and $companionUpdatePositions[0] -ge 0
    for ($positionIndex = 1; $positionIndex -lt $companionUpdatePositions.Count; $positionIndex++) { if ($companionUpdatePositions[$positionIndex] -le $companionUpdatePositions[$positionIndex - 1]) { $companionUpdateOrderValid = $false } }
    $downloadedContractExpansionContradiction = $companionActiveSurfaceText -match '(?i)downloaded contract may (?:change|expand|add)[^\r\n]{0,100}(?:mutation|destination|effect|mapping|target)'
    $companionConfirmationValid = $companionTechniqueText -match '(?i)exposes exactly one lifecycle action' -and $companionTechniqueText.Contains("Update Geurts Game Forge Documentation") -and $companionTechniqueText -match '(?i)Selecting it immediately shows one confirmation dialog' -and $companionTechniqueText -match '(?i)There is no earlier preview, dry run, check phase, setup screen, or second confirmation' -and $companionTechniqueText -match '(?i)Cancel is the initially focused and default response' -and $companionTechniqueText -match '(?i)declining must cause no network or filesystem change' -and $companionTechniqueText -match '(?i)confirmation must identify all five destructive targets and no implied broader scope' -and $companionTechniqueText -match '(?i)every local change in those targets will be overwritten and lost' -and $companionTechniqueText -match '(?i)`Docs/GameDesign/` and every unlisted project path will not be accessed or changed' -and $companionTechniqueText -match '(?i)No archive acquisition or project mutation may begin before affirmative confirmation' -and $companionTechniqueText -match '(?i)confirmation occurs before archive acquisition[^\r\n]{0,220}must carry this exact supported destination, five-target list, and four template-to-target mappings' -and $companionTechniqueText -match '(?i)After confirmation and download[^\r\n]{0,120}parse the archive.?s contract' -and $companionTechniqueText -match '(?i)pre-approved source selection, destination, action, confirmation behavior[^\r\n]{0,180}mapping order before the first project mutation' -and $companionTechniqueText -match '(?i)earlier approval does not authorize a changed or expanded managed target set' -and -not $downloadedContractExpansionContradiction
    $comparisonStateFailureContradiction = $companionActiveSurfaceText -match '(?i)comparison-state (?:write|persistence) failure[^\r\n]{0,120}(?:reclassifies|invalidates|undoes|rolls back)[^\r\n]{0,80}(?:content|managed-target|replacement|Update)'
    $companionCompletionValid = $companionUpdateOrderValid -and $companionTechniqueText -match '(?i)exact resolved main-head commit' -and $companionTechniqueText -match '(?i)archive pinned to that exact commit' -and $companionTechniqueText -match '(?i)readability of every contract-listed validation entry' -and $companionTechniqueText -match '(?i)support for contract schema 1\.0\.0' -and $companionTechniqueText -match '(?i)equality between the contract and manifest package versions' -and $companionTechniqueText -match '(?i)directly materialize the complete validated archive tree' -and $companionTechniqueText -match '(?i)result contains no `\.git` metadata or continuing repository, worktree, branch, remote, or synchronization connection' -and $companionTechniqueText -match '(?i)After every managed-target verification passes, report the content Update as successful and attempt to write' -and $companionTechniqueText -match '(?i)comparison-state write fails, report a warning[^\r\n]{0,160}do not reclassify, undo, or repair the successful five-target replacement' -and $companionTechniqueText -match '(?i)reports failure plainly and never reports partial completion as success' -and $companionTechniqueText -match '(?i)no automatic repair or recovery flow' -and -not $comparisonStateFailureContradiction
    Add-Check "Companion confirmation and complete update" ($companionConfirmationValid -and $companionCompletionValid) "One cancel-default confirmation authorizes only the five listed replacements; content success requires all five targets, while later comparison-state persistence failure warns without undoing that success."

    $companionBoundaryValid = $companionTechniqueText -match '(?i)complete replacement of those four files from the exact template mappings' -and $companionTechniqueText -match '(?i)may create only the missing parent directories required to materialize the listed targets' -and $companionTechniqueText -match '(?i)preserve every unlisted file and directory within those parents' -and $companionTechniqueText -match '(?i)Every other project path is outside the lifecycle' -and $companionTechniqueText -match '(?i)must not enumerate, inspect, create, validate, hash, modify, or delete anything under' -and $companionTechniqueText.Contains("<ProjectRoot>/Docs/GameDesign/") -and $companionTechniqueText -match '(?i)must not discover additional work from repository contents' -and $companionTechniqueText -match '(?i)scan for or execute `\.bat`, `\.cmd`, `\.ps1`, or any other script from either the documentation package or the Unity project' -and $companionTechniqueText -match '(?i)complete documentation tree is copied as inert content' -and $companionTechniqueText -match '(?i)presence of tools within that tree does not authorize their execution'
    Add-Check "Companion bounded project and script boundary" $companionBoundaryValid "Only the managed documentation directory, four mapped files, and their missing parents are in scope; Docs/GameDesign and unlisted paths are uninspected, and package/project scripts remain inert."

    $requiredCompanionExclusions = @("preview", "dry run", "backup", "snapshot", "rollback", "quarantine", "journal", "recovery gate", "last-valid copy", "merge", "opt-out", "migration path")
    $companionForbiddenSection = [regex]::Match($companionTechniqueText, '(?ms)^## 7\. Forbidden Behavior\s*(?<Body>.*?)(?=^## 8\.)')
    $missingCompanionExclusions = if ($companionForbiddenSection.Success) { @($requiredCompanionExclusions | Where-Object { $companionForbiddenSection.Groups["Body"].Value.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 }) } else { @("forbidden behavior section") }
    $affirmativeLifecycleContradiction = $companionActiveSurfaceText -match '(?i)\b(?:companion|Update) (?:provides|creates|uses|maintains|requires|offers) (?:an? )?(?:preview|dry run|backup|snapshot|rollback|quarantine|journal|recovery|migration)' -or $companionActiveSurfaceText -match '(?i)\b(?:companion|Update) (?:shows|requires|uses|offers) (?:an? )?second confirmation' -or $companionActiveSurfaceText -match '(?i)\b(?:companion|Update) (?:preserves|reconciles|merges) (?:local )?drift' -or $companionActiveSurfaceText -match '(?i)\b(?:companion|UPM package) (?:runs|executes|launches|requires|uses) (?:an? )?(?:external )?(?:\.bat|batch|bootstrap)' -or $companionActiveSurfaceText -match '(?i)\bcompanion scans (?:the )?(?:repository|project|documentation).*?(?:scripts?|\.bat)'
    $minimalLifecycleValid = $missingCompanionExclusions.Count -eq 0 -and -not $affirmativeLifecycleContradiction -and $companionTechniqueText -match '(?i)not a general setup-plan format, script manifest, extensible task engine, or permission catalogue' -and $companionTechniqueText -match '(?i)does not merge managed regions, preserve content in those files, honor a native-entry opt-out, migrate legacy content' -and $companionForbiddenSection.Groups["Body"].Value -match '(?i)inspect or preserve local drift' -and $companionTechniqueText -match '(?i)no external installer, Windows bootstrap, batch-driven setup' -and $companionTechniqueText -match '(?i)no automatic repair or recovery flow'
    Add-Check "Companion minimal lifecycle exclusions" $minimalLifecycleValid "The companion contract has no preview/dry-run, second confirmation, setup engine, external bootstrap, script execution, drift handling, backup, rollback, journal, quarantine, migration, or recovery machinery."

    $aiRoutingLimitationValid = $companionTechniqueText -match '(?i)do not make every AI product obey the documentation automatically' -and $companionTechniqueText -match '(?i)AI tool must support the applicable native instruction file or be explicitly instructed to read and follow `AGENTS\.md`' -and $companionTechniqueText -match '(?i)Tools that ignore those instruction surfaces may not discover or follow the Geurts documentation' -and $companionTechniqueText -match '(?i)must not claim universal AI control or compliance'
    Add-Check "Companion AI-routing limitation" $aiRoutingLimitationValid "The contract accurately limits routing to tools that support the declared native files or are explicitly instructed to follow AGENTS.md."

    $nativeTemplates = @(
        "Tools/AIAgentInstructionTemplates/AGENTS.md",
        "Tools/AIAgentInstructionTemplates/copilot-instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
    )
    $expectedTemplateVersion = "1.0.0"
    $expectedBrickRouteText = 'Before planning or modifying any Geurts Game Forge brick code, read and follow `GeurtsGameForgeDocumentation/AGENTS.md`; it routes to the installed, manifest-selected documentation. Treat that documentation as the source of truth for the work.'
    $expectedManagedRegionHashes = @{
        "Tools/AIAgentInstructionTemplates/AGENTS.md|agents-body" = "93464c8bace065ddfe2f305dfedafafbb8a1099cb318c21dad185d46d22451eb"
        "Tools/AIAgentInstructionTemplates/copilot-instructions.md|copilot-body" = "c4493666c6135143f8c97d0f3b0aafd72375998b68359cf5bca13aa6cdb6a775"
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md|unity-frontmatter" = "98e4fd786bbd1474e28d3800b91d749c29ff2acf94b89ef821d6860645829688"
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md|unity-body" = "655d9a82ce462a8501ed3542589e5010abc995f2ed27beae4bc30550ecfc28cb"
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md|game-design-frontmatter" = "334b60274fe81a1891e1500785d29a249a0d4e32957bb665a770402163fa2cd4"
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md|game-design-body" = "a064e41b0e80aac9c5109203c68cdc74eae6920c47e8e84d369a2395f19e3ec3"
    }
    $routeFailures = New-Object System.Collections.Generic.List[string]
    $markerFailures = New-Object System.Collections.Generic.List[string]
    $seenManagedRegionKeys = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $htmlRegionPattern = '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*-->\r?\n(?<Body>.*?)^<!--\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*-->[^\S\r\n]*(?=\r?\n|\z)'
    $yamlRegionPattern = '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*\r?\n(?<Body>.*?)^#\s*GEURTS-MANAGED-END\s+id="\k<Id>"[^\S\r\n]*(?=\r?\n|\z)'
    foreach ($relative in $nativeTemplates) {
        $path = Join-Path $RepositoryRoot ($relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        $text = [System.IO.File]::ReadAllText($path)
        if ([regex]::Matches($text, [regex]::Escape($expectedBrickRouteText)).Count -ne 1) { $routeFailures.Add("$relative does not contain the exact approved brick route once") | Out-Null }
        if ($text.IndexOf("GeurtsGameForgeDocumentation/AGENTS.md", [System.StringComparison]::Ordinal) -lt 0 -or $text.IndexOf("GeurtsGameForgeDocumentation/AI_READ_FIRST.md", [System.StringComparison]::Ordinal) -ge 0) { $routeFailures.Add("$relative does not route first through copied AGENTS.md") | Out-Null }
        if ($text.IndexOf("network efficiency", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $routeFailures.Add("$relative duplicates implementation policy instead of remaining a concise route") | Out-Null }
        if ($relative -ceq "Tools/AIAgentInstructionTemplates/AGENTS.md") {
            if ($text.IndexOf("Docs/GameDesign/", [System.StringComparison]::Ordinal) -ge 0) { $routeFailures.Add("$relative is not a concise copied-AGENTS discovery shim") | Out-Null }
        }
        elseif ($text.IndexOf("installed, manifest-selected documentation", [System.StringComparison]::Ordinal) -lt 0 -or $text.IndexOf("owns the complete documentation chain", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $routeFailures.Add("$relative does not defer authority to the installed, manifest-selected documentation") | Out-Null
        }
        $begins = [regex]::Matches($text, 'GEURTS-MANAGED-BEGIN').Count
        $ends = [regex]::Matches($text, 'GEURTS-MANAGED-END').Count
        $htmlMatches = @([regex]::Matches($text, $htmlRegionPattern))
        $yamlMatches = @([regex]::Matches($text, $yamlRegionPattern))
        $matches = $htmlMatches + $yamlMatches
        if ($begins -eq 0 -or $ends -ne $begins -or $matches.Count -ne $begins) { $markerFailures.Add("$relative has malformed markers") | Out-Null; continue }
        $managedIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($region in $matches) { if (-not $managedIds.Add($region.Groups["Id"].Value)) { $markerFailures.Add("$relative has duplicate managed ID $($region.Groups['Id'].Value)") | Out-Null } }
        if ($yamlMatches.Count -gt 0) {
            $frontmatter = [regex]::Match($text, '(?s)\A---\r?\n.*?\r?\n---')
            foreach ($yamlMatch in $yamlMatches) {
                if (-not $frontmatter.Success -or $yamlMatch.Index -le 3 -or ($yamlMatch.Index + $yamlMatch.Length) -gt ($frontmatter.Index + $frontmatter.Length)) { $markerFailures.Add("$relative has a YAML marker outside frontmatter") | Out-Null }
            }
        }
        foreach ($region in $matches) {
            $regionKey = "$relative|$($region.Groups['Id'].Value)"
            if (-not $seenManagedRegionKeys.Add($regionKey)) { $markerFailures.Add("duplicate managed region $regionKey") | Out-Null }
            if ($region.Groups["Version"].Value -cne $expectedTemplateVersion) {
                $markerFailures.Add("$relative region $($region.Groups['Id'].Value) declares version $($region.Groups['Version'].Value) instead of $expectedTemplateVersion") | Out-Null
            }
            if (-not $expectedManagedRegionHashes.ContainsKey($regionKey)) {
                $markerFailures.Add("$relative contains unexpected managed region $($region.Groups['Id'].Value)") | Out-Null
            }
            elseif ($region.Groups["Hash"].Value.ToLowerInvariant() -cne $expectedManagedRegionHashes[$regionKey]) {
                $markerFailures.Add("$relative region $($region.Groups['Id'].Value) does not declare the approved hash") | Out-Null
            }
            if ((Get-TextHash -Text $region.Groups["Body"].Value) -cne $region.Groups["Hash"].Value.ToLowerInvariant()) {
                $markerFailures.Add("$relative region $($region.Groups['Id'].Value) has a bad hash") | Out-Null
            }
        }
    }
    foreach ($regionKey in $expectedManagedRegionHashes.Keys) { if (-not $seenManagedRegionKeys.Contains($regionKey)) { $markerFailures.Add("missing approved managed region $regionKey") | Out-Null } }
    Add-Check "Managed native routes" ($routeFailures.Count -eq 0) $(if ($routeFailures.Count) { "Invalid managed route: " + ($routeFailures -join ", ") } else { "Every native template contains the exact concise brick route through copied AGENTS.md into the installed manifest-selected source of truth." })
    Add-Check "Managed template integrity" ($markerFailures.Count -eq 0 -and $seenManagedRegionKeys.Count -eq $expectedManagedRegionHashes.Count) $(if ($markerFailures.Count) { $markerFailures -join "; " } else { "All six approved v1.0.0 native managed regions and hashes are exact and valid." })

    $expectedCatalogRecords = @(
        "AGENTS.md|AGENTS.md|0.4.0|24232b85e9c5f18e1c055e0c1d59ba9d4b9f294472b25dbb966ae682e4d1d9d7",
        "AGENTS.md|AGENTS.md|0.5.0|3bec9754a17f3387f27e0678feb69e541c921d81d55f6093a87c27c1fca98534",
        "AGENTS.md|AGENTS.md|0.6.0|a44874e2feedfe903caf805c0dd91fb71cb5ce2db5696330d1a37c399501118e",
        ".github/copilot-instructions.md|copilot-instructions.md|0.4.0|d72006b497ed12ae97ef3d4ef9248f634af7159b7011434987ea3bd60cbd8da7",
        ".github/copilot-instructions.md|copilot-instructions.md|0.5.0|d72006b497ed12ae97ef3d4ef9248f634af7159b7011434987ea3bd60cbd8da7",
        ".github/copilot-instructions.md|copilot-instructions.md|0.6.0|cfeb6826447b74d391c7afa40f07e19171086ee0f6e8a107887360fa4e6fd7e3",
        ".github/instructions/geurts-unity.instructions.md|instructions/geurts-unity.instructions.md|0.4.0|27bff44e8cd8a26962b2b2890b3ca6c02a5a1ee6c0531c195514d70b9ffde92f",
        ".github/instructions/geurts-unity.instructions.md|instructions/geurts-unity.instructions.md|0.5.0|27bff44e8cd8a26962b2b2890b3ca6c02a5a1ee6c0531c195514d70b9ffde92f",
        ".github/instructions/geurts-unity.instructions.md|instructions/geurts-unity.instructions.md|0.6.0|799fe2cc0a720cd5e9f7f350b7480d219c0f92309a4a6201953e3a452faa0fa3",
        ".github/instructions/geurts-game-design.instructions.md|instructions/geurts-game-design.instructions.md|0.4.0|724549bbd75e2ed1f83167992747f5b56adac9d0b4e40886085b65d497cddbd9",
        ".github/instructions/geurts-game-design.instructions.md|instructions/geurts-game-design.instructions.md|0.5.0|724549bbd75e2ed1f83167992747f5b56adac9d0b4e40886085b65d497cddbd9",
        ".github/instructions/geurts-game-design.instructions.md|instructions/geurts-game-design.instructions.md|0.6.0|2805d6be2804eff71668625a83725d02338070a9b6988bde20bc521d455d17c0"
    )
    $catalogFailures = New-Object System.Collections.Generic.List[string]
    try { $migrationCatalog = Get-Content -LiteralPath (Join-Path $RepositoryRoot "Tools/NativeEntryMigrationCatalog.json") -Raw | ConvertFrom-Json }
    catch { $migrationCatalog = $null; $catalogFailures.Add("catalog JSON is invalid") | Out-Null }
    if ($migrationCatalog) {
        if ([string]$migrationCatalog.schemaVersion -cne "1.0.0" -or [string]$migrationCatalog.normalization -cne "utf8-text-with-lf-newlines-and-terminal-lf" -or @($migrationCatalog.entries).Count -ne 4) { $catalogFailures.Add("catalog metadata or target count is invalid") | Out-Null }
        $actualCatalogRecords = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($entry in @($migrationCatalog.entries)) {
            $expectedEntryFields = @("legacyFingerprints", "targetPath", "templatePath")
            $actualEntryFields = @($entry.PSObject.Properties | Select-Object -ExpandProperty Name | Sort-Object)
            if ($actualEntryFields.Count -ne $expectedEntryFields.Count) { $catalogFailures.Add("catalog entry property set is not generic") | Out-Null }
            else { for ($entryFieldIndex = 0; $entryFieldIndex -lt $expectedEntryFields.Count; $entryFieldIndex++) { if ([string]$actualEntryFields[$entryFieldIndex] -cne [string]$expectedEntryFields[$entryFieldIndex]) { $catalogFailures.Add("catalog entry property set is not generic") | Out-Null; break } } }
            foreach ($fingerprint in @($entry.legacyFingerprints)) {
                foreach ($version in @($fingerprint.versions)) {
                    $record = "{0}|{1}|{2}|{3}" -f [string]$entry.targetPath, [string]$entry.templatePath, [string]$version, ([string]$fingerprint.sha256).ToLowerInvariant()
                    if (-not $actualCatalogRecords.Add($record)) { $catalogFailures.Add("duplicate catalog record $record") | Out-Null }
                }
            }
        }
        $expectedCatalogSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($record in $expectedCatalogRecords) { [void]$expectedCatalogSet.Add($record) }
        if ($actualCatalogRecords.Count -ne $expectedCatalogSet.Count) { $catalogFailures.Add("catalog record count differs from the approved historical matrix") | Out-Null }
        foreach ($record in $expectedCatalogSet) { if (-not $actualCatalogRecords.Contains($record)) { $catalogFailures.Add("missing approved catalog record $record") | Out-Null } }
        foreach ($record in $actualCatalogRecords) { if (-not $expectedCatalogSet.Contains($record)) { $catalogFailures.Add("unexpected catalog record $record") | Out-Null } }
    }
    Add-Check "Migration catalog integrity" ($catalogFailures.Count -eq 0) $(if ($catalogFailures.Count) { $catalogFailures -join "; " } else { "The exact Geurts-owned historical native-entry fingerprints are valid, with no product-owned block migration data." })

    $gddTemplate = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md"))
    $gddReadmeTemplate = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/GameDesign/README.md"))
    $gddFields = @("ID", "Path", "Purpose", "Status", "Version", "Authority", "Tags", "SHA256")
    $gddValid = $gddTemplate.Contains('GEURTS-GDD-MANIFEST-BEGIN version="0.7.0"') -and @($gddFields | Where-Object { $gddTemplate -notmatch "\|\s*$([regex]::Escape($_))\s*\|" }).Count -eq 0 -and $gddReadmeTemplate.Contains('GEURTS-SCAFFOLD-BEGIN version="0.10.0"') -and $gddReadmeTemplate -match '(?i)project-local fetched Geurts documentation copy' -and $gddReadmeTemplate -match '(?i)missing information would establish or change player-facing design intent' -and $gddReadmeTemplate -match '(?i)reversible technical details that do not create or overwrite design facts'
    Add-Check "GDD scaffold contract" $gddValid "Managed GDD index retains its deterministic v0.7.0 format, while the v0.10.0 README separates project-authored GDD from the fetched copy, stops for missing design intent, and permits only reversible non-design assumptions."

    $definitionPath = Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
    $folderFailures = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $definitionPath -PathType Leaf)) {
        $folderFailures.Add("definition missing") | Out-Null
    }
    else {
        try { $definition = Get-Content -LiteralPath $definitionPath -Raw | ConvertFrom-Json }
        catch { $definition = $null; $folderFailures.Add("invalid JSON") | Out-Null }
        if ($definition) {
            $folders = @($definition.managedFolders)
            $topLevelExpected = @{
                schemaVersion = "1.0.0"
                definitionVersion = "0.10.0"
                packageVersion = "0.11.3"
                canonicalPath = "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
                pathBase = "<ProjectRoot>"
                pathSeparator = "/"
                explanatoryAuthority = "GeurtsTechniques/GeurtsFolderStructureTechnique.md"
                automationAuthority = "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
            }
            foreach ($name in $topLevelExpected.Keys) {
                if ([string]$definition.$name -cne [string]$topLevelExpected[$name]) { $folderFailures.Add("$name is not '$($topLevelExpected[$name])'") | Out-Null }
            }
            if ($folders.Count -ne 69 -or [int]$definition.managedFolderCount -ne 69) { $folderFailures.Add("managed folder count is not exactly 69") | Out-Null }
            if ([int]$definition.projectStructureFolderCount -ne 67) { $folderFailures.Add("projectStructureFolderCount is not 67") | Out-Null }

            $allowedCategories = @("documentation", "generated-content", "third-party-content", "tooling", "unity-project")
            $declaredCategories = @($definition.contentCategories | Sort-Object)
            if ($declaredCategories.Count -ne $allowedCategories.Count) { $folderFailures.Add("contentCategories does not contain exactly five entries") | Out-Null }
            else {
                for ($categoryIndex = 0; $categoryIndex -lt $allowedCategories.Count; $categoryIndex++) {
                    if ([string]$declaredCategories[$categoryIndex] -cne $allowedCategories[$categoryIndex]) { $folderFailures.Add("contentCategories differs from the five-value authority") | Out-Null; break }
                }
            }

            $expectedProfileOwners = @{
                "full-project-structure" = "folder-structure-tool"
                "native-entry" = "native-entry-manager"
                "gdd-scaffolding" = "native-entry-manager"
            }
            $expectedProfileCounts = @{
                "full-project-structure" = 67
                "native-entry" = 2
                "gdd-scaffolding" = 2
            }
            $profileIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
            if (@($definition.creationProfiles).Count -ne 3) { $folderFailures.Add("creationProfiles does not contain exactly three entries") | Out-Null }
            foreach ($profile in @($definition.creationProfiles)) {
                $profileId = [string]$profile.id
                if (-not $profileIds.Add($profileId)) { $folderFailures.Add("duplicate creation profile '$profileId'") | Out-Null }
                if (-not $expectedProfileOwners.ContainsKey($profileId)) { $folderFailures.Add("unknown creation profile '$profileId'") | Out-Null }
                elseif ([string]$profile.owner -cne [string]$expectedProfileOwners[$profileId]) { $folderFailures.Add("profile '$profileId' has incorrect owner") | Out-Null }
                if ([string]::IsNullOrWhiteSpace([string]$profile.purpose)) { $folderFailures.Add("profile '$profileId' has no purpose") | Out-Null }
            }
            foreach ($profileId in $expectedProfileOwners.Keys) {
                if (-not $profileIds.Contains($profileId)) { $folderFailures.Add("missing creation profile '$profileId'") | Out-Null }
            }

            $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
            $seenIgnoreCase = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
            $profileCounts = @{}
            foreach ($profileId in $expectedProfileOwners.Keys) { $profileCounts[$profileId] = 0 }
            $folderTechniqueText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureTechnique.md"))
            foreach ($folder in $folders) {
                $folderPath = [string]$folder.path
                if ($folderPath -ceq "GeurtsGameForgeDocumentation") { $folderFailures.Add("reserved documentation container appears in the managed creation registry") | Out-Null }
                if (-not (Test-SafeDefinitionPath -Path $folderPath)) { $folderFailures.Add("unsafe folder path '$folderPath'") | Out-Null }
                if (-not $seen.Add($folderPath) -or -not $seenIgnoreCase.Add($folderPath)) { $folderFailures.Add("duplicate folder path '$folderPath'") | Out-Null }
                if ($folder.requirement -notin @("required", "optional") -or [string]::IsNullOrWhiteSpace([string]$folder.purpose) -or [string]$folder.contentCategory -notin $allowedCategories) { $folderFailures.Add("$folderPath has invalid requirement, purpose, or category") | Out-Null }
                if (-not $folder.automation -or $folder.automation.mayCreate -isnot [bool] -or $folder.automation.mayRemove -isnot [bool] -or $folder.automation.mayCreate -ne $true -or $folder.automation.mayRemove -ne $false -or [string]::IsNullOrWhiteSpace([string]$folder.automation.owner)) {
                    $folderFailures.Add("$folderPath has an invalid create-only automation policy") | Out-Null
                    continue
                }

                $profiles = @($folder.automation.creationProfiles)
                if ($profiles.Count -eq 0) { $folderFailures.Add("$folderPath has no creation profile") | Out-Null }
                $expectedFolderProfiles = @(Get-ExpectedFolderProfiles -Path $folderPath | Sort-Object)
                $actualFolderProfiles = @($profiles | ForEach-Object { [string]$_ } | Sort-Object)
                $profileScopeValid = $actualFolderProfiles.Count -eq $expectedFolderProfiles.Count
                if ($profileScopeValid) {
                    for ($profileIndex = 0; $profileIndex -lt $expectedFolderProfiles.Count; $profileIndex++) {
                        if ($actualFolderProfiles[$profileIndex] -cne $expectedFolderProfiles[$profileIndex]) { $profileScopeValid = $false; break }
                    }
                }
                if (-not $profileScopeValid) { $folderFailures.Add("$folderPath differs from its exact v0.10.0 profile scope") | Out-Null }
                $folderDelegations = @{}
                if ($folder.automation.PSObject.Properties["delegatedOwners"]) {
                    foreach ($delegation in @($folder.automation.delegatedOwners.PSObject.Properties)) {
                        $delegatedProfile = [string]$delegation.Name
                        $delegatedOwner = [string]$delegation.Value
                        if (-not $expectedProfileOwners.ContainsKey($delegatedProfile) -or $profiles -notcontains $delegatedProfile -or $delegatedOwner -cne [string]$expectedProfileOwners[$delegatedProfile]) {
                            $folderFailures.Add("$folderPath has invalid delegation for '$delegatedProfile'") | Out-Null
                        }
                        $folderDelegations[$delegatedProfile] = $delegatedOwner
                    }
                    if ($folderPath -notin @("Docs", "Docs/GameDesign") -or @($folder.automation.delegatedOwners.PSObject.Properties).Count -ne 1 -or -not $folderDelegations.ContainsKey("gdd-scaffolding")) {
                        $folderFailures.Add("$folderPath has an unauthorized delegation object") | Out-Null
                    }
                }
                elseif ($folderPath -in @("Docs", "Docs/GameDesign")) {
                    $folderFailures.Add("$folderPath is missing its gdd-scaffolding delegation") | Out-Null
                }

                foreach ($profileId in $profiles) {
                    $profileId = [string]$profileId
                    if (-not $expectedProfileOwners.ContainsKey($profileId)) { $folderFailures.Add("$folderPath references unknown profile '$profileId'") | Out-Null; continue }
                    $profileCounts[$profileId] = [int]$profileCounts[$profileId] + 1
                    $primaryMatches = ([string]$folder.automation.owner -ceq [string]$expectedProfileOwners[$profileId])
                    $delegationMatches = $folderDelegations.ContainsKey($profileId) -and ([string]$folderDelegations[$profileId] -ceq [string]$expectedProfileOwners[$profileId])
                    if (-not $primaryMatches -and -not $delegationMatches) { $folderFailures.Add("$folderPath is not authorized for profile '$profileId'") | Out-Null }
                }
            }

            foreach ($folder in $folders) {
                $folderPath = [string]$folder.path
                $parent = [string]$folder.parent
                if ($folderPath.Contains('/')) {
                    $expectedParent = $folderPath.Substring(0, $folderPath.LastIndexOf('/'))
                    if ($parent -cne $expectedParent -or -not $seen.Contains($parent)) { $folderFailures.Add("$folderPath has invalid parent '$parent'") | Out-Null }
                }
                elseif (-not [string]::IsNullOrWhiteSpace($parent)) { $folderFailures.Add("root folder $folderPath must not declare a parent") | Out-Null }
            }
            foreach ($profileId in $expectedProfileCounts.Keys) {
                if ([int]$profileCounts[$profileId] -ne [int]$expectedProfileCounts[$profileId]) { $folderFailures.Add("profile '$profileId' selects $($profileCounts[$profileId]) folders instead of $($expectedProfileCounts[$profileId])") | Out-Null }
                $selectedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
                foreach ($selectedFolder in @($folders | Where-Object { @($_.automation.creationProfiles) -contains $profileId })) { [void]$selectedPaths.Add([string]$selectedFolder.path) }
                foreach ($selectedFolder in @($folders | Where-Object { @($_.automation.creationProfiles) -contains $profileId })) {
                    $parent = [string]$selectedFolder.parent
                    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not $selectedPaths.Contains($parent)) { $folderFailures.Add("profile '$profileId' is not parent-closed at '$($selectedFolder.path)'") | Out-Null }
                }
            }

            $registryMatch = [regex]::Match($folderTechniqueText, '(?ms)<!-- GEURTS-FOLDER-PATHS:BEGIN -->\s*```text\s*(?<Paths>.*?)\s*```\s*<!-- GEURTS-FOLDER-PATHS:END -->')
            if (-not $registryMatch.Success -or [regex]::Matches($folderTechniqueText, 'GEURTS-FOLDER-PATHS:BEGIN').Count -ne 1 -or [regex]::Matches($folderTechniqueText, 'GEURTS-FOLDER-PATHS:END').Count -ne 1) {
                $folderFailures.Add("Markdown literal path registry is missing or malformed") | Out-Null
            }
            else {
                $documentedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
                foreach ($line in ($registryMatch.Groups["Paths"].Value -split '\r?\n')) {
                    $documentedPath = $line.Trim()
                    if ([string]::IsNullOrWhiteSpace($documentedPath)) { continue }
                    if (-not (Test-SafeDefinitionPath -Path $documentedPath) -or -not $documentedPaths.Add($documentedPath)) { $folderFailures.Add("invalid or duplicate Markdown registry path '$documentedPath'") | Out-Null }
                }
                if ($documentedPaths.Count -ne $seen.Count) { $folderFailures.Add("Markdown and JSON path counts differ") | Out-Null }
                foreach ($folderPath in $seen) { if (-not $documentedPaths.Contains($folderPath)) { $folderFailures.Add("JSON path '$folderPath' is absent from Markdown registry") | Out-Null } }
                foreach ($documentedPath in $documentedPaths) { if (-not $seen.Contains($documentedPath)) { $folderFailures.Add("Markdown path '$documentedPath' is absent from JSON") | Out-Null } }
            }
        }
    }
    $folderToolText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/CreateGeurtsFolderStructure.ps1"))
    $folderManagerText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/ManageGeurtsAgentInstructions.ps1"))
    $folderTechniqueVersion = Get-DeclaredVersion -Path (Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsFolderStructureTechnique.md")
    $folderDefinitionVersion = if ($definition) { [string]$definition.definitionVersion } else { $null }
    $folderVersionParityValid = $folderTechniqueVersion -ceq "0.10.0" -and $folderDefinitionVersion -ceq $folderTechniqueVersion -and $folderToolText.Contains('[string]$definition.definitionVersion -ne "0.10.0"') -and $folderToolText.Contains('Folder definition version must be 0.10.0') -and $folderManagerText.Contains('[string]$definition.definitionVersion -ne "0.10.0"') -and $folderManagerText.Contains('Managed setup requires folder definition v0.10.0')
    if (-not $folderVersionParityValid) { $folderFailures.Add("folder technique, JSON definition, and both consuming tools do not agree on definition v0.10.0") | Out-Null }
    if ($folderToolText.Contains('(Join-Path $ProjectRoot "GeurtsTechniques/GeurtsFolderStructureDefinition.json")')) { $folderFailures.Add("folder tool still discovers an unselected raw project-root definition") | Out-Null }
    $folderDirectoryBarrier = $folderToolText.IndexOf('Invoke-TestDirectoryBarrier -TargetPath $folder.TargetPath', [System.StringComparison]::Ordinal)
    $folderFinalContainment = if ($folderDirectoryBarrier -ge 0) { $folderToolText.IndexOf('Test-IsContainedPath -Candidate $finalTargetPath', $folderDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $folderFinalReparse = if ($folderDirectoryBarrier -ge 0) { $folderToolText.IndexOf('Test-HasReparsePoint -Candidate $finalTargetPath', $folderDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $folderExistingAcceptance = if ($folderDirectoryBarrier -ge 0) { $folderToolText.IndexOf('Test-Path -LiteralPath $finalTargetPath -PathType Container', $folderDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $folderDirectoryCreate = if ($folderDirectoryBarrier -ge 0) { $folderToolText.IndexOf('New-Item -ItemType Directory -Path $finalTargetPath', $folderDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $folderDirectoryGuardOrderValid = $folderDirectoryBarrier -ge 0 -and $folderFinalContainment -gt $folderDirectoryBarrier -and $folderFinalReparse -ge $folderFinalContainment -and $folderExistingAcceptance -gt $folderFinalReparse -and $folderDirectoryCreate -gt $folderExistingAcceptance
    $folderOwnerSafetyValid = $folderTechniqueTextForPathTerms -match '(?i)Unity project root itself must not be a junction, symbolic link, or other reparse point' -and $folderTechniqueTextForPathTerms -match '(?i)Immediately before accepting an existing managed directory or creating a missing one' -and $folderTechniqueTextForPathTerms -match '(?i)re-resolve containment below the validated project root' -and $folderTechniqueTextForPathTerms -match '(?i)complete path chain.*newly introduced reparse points' -and $folderTechniqueTextForPathTerms -match '(?i)must not create a descendant outside the project'
    if ($folderToolText -notmatch '(?is)function Assert-UnityProjectRoot.*?rootItem.*?FileAttributes\]::ReparsePoint') { $folderFailures.Add("folder tool does not reject a reparse-point Unity root") | Out-Null }
    if (-not $folderDirectoryGuardOrderValid) { $folderFailures.Add("folder tool does not recheck containment and the full reparse chain immediately before directory acceptance/creation") | Out-Null }
    if (-not $folderOwnerSafetyValid) { $folderFailures.Add("Folder Technique does not own the root and final directory reparse boundary") | Out-Null }
    Add-Check "Folder definition contract" ($folderFailures.Count -eq 0) $(if ($folderFailures.Count) { $folderFailures -join "; " } else { "Definition versions, 69 entries, owner-bound profiles, package-only resolution, and exact Markdown parity are valid; root and per-directory final reparse guards prevent creation outside the project." })

    $chatSubjectRow = [regex]::Match($manifestText, '(?m)^\| Chat-only response style and scope \| `(?<Path>[^`]+)` \| (?<Applicability>[^|]+) \|\r?$')
    $chatRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1\.1\.md` \| 1\.1 \| (?<Role>[^|]+) \|\r?$')
    $chatOnlyValid = $chatSubjectRow.Success -and $chatSubjectRow.Groups["Path"].Value -ceq "GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md" -and $chatSubjectRow.Groups["Applicability"].Value -match '(?i)compatible chat interface.*select' -and $chatSubjectRow.Groups["Applicability"].Value -match '(?i)never.*coding or architecture standard' -and $chatRegistryRow.Success -and $chatRegistryRow.Groups["Role"].Value -match '(?i)chat-only' -and $chatRegistryRow.Groups["Role"].Value -match '(?i)not an? implementation standard'
    Add-Check "Chat-only classification" $chatOnlyValid "Manifest applicability and registry role independently classify Response Control as explicitly selected chat-only behaviour, never an implementation standard."

    $technicalRelative = "GeurtsTechniques/GeurtsTechnicalTechnique.md"
    $technicalText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $technicalRelative))
    $unityTargetFailures = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @("README.md", "GeurtsTechniqueManifest.md", $technicalRelative)) {
        $targetText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $relative))
        $targetMatches = @([regex]::Matches($targetText, '(?m)^\*\*Unity target:\*\*\s*(?<Target>[^\r\n]+)\r?$'))
        if ($targetMatches.Count -ne 1 -or $targetMatches[0].Groups["Target"].Value.Trim() -cne "Unity 6.3 LTS (6000.3)") {
            $unityTargetFailures.Add("$relative must declare exactly one Unity 6.3 LTS (6000.3) target") | Out-Null
        }
    }
    $baselineSection = [regex]::Match($technicalText, '(?ms)^## Unity 6\.3 LTS Compatibility Baseline\s*(?<Body>.*?)(?=^## )')
    $baselineBody = if ($baselineSection.Success) { $baselineSection.Groups["Body"].Value } else { "" }
    foreach ($requiredTerm in @(
        "ProjectSettings/ProjectVersion.txt", "Packages/manifest.json", "Packages/packages-lock.json",
        "6000.3.x", "newest stable package release verified compatible", "C# 9.0", ".NET Standard 2.1",
        ".NET Framework 4.8", "Input System", "Build Profiles", "UnityEngine.Awaitable",
        "Render Graph", "Edit Mode", "Play Mode", "IL2CPP", "do not certify separate game or companion repositories",
        "Odin Inspector and Quantum Console are required dependencies", "report that concrete blocker",
        "documentation-only repository", "Documentation Companion"
    )) {
        if ($baselineBody.IndexOf($requiredTerm, [System.StringComparison]::Ordinal) -lt 0) {
            $unityTargetFailures.Add("Technical compatibility baseline omits '$requiredTerm'") | Out-Null
        }
    }
    Add-Check "Unity 6.3 LTS target" ($unityTargetFailures.Count -eq 0) $(if ($unityTargetFailures.Count) { $unityTargetFailures -join "; " } else { "README, manifest, and the Technical Technique agree on 6000.3; the technical owner declares dependency, language/API, migration, and verification requirements." })

    # This is a bounded lint of current Markdown examples, not a Unity compiler or API compatibility proof.
    $exampleFailures = New-Object System.Collections.Generic.List[string]
    $exampleCount = 0
    $unsupportedExamplePatterns = @(
        @{ Name = "obsolete object discovery"; Pattern = '\bFind(?:ObjectOfType|ObjectsOfType)\s*(?:<|\()' },
        @{ Name = "legacy input polling"; Pattern = '\b(?:UnityEngine\.)?Input\s*\.\s*Get(?:Axis(?:Raw)?|Button(?:Down|Up)?|Key(?:Down|Up)?|MouseButton(?:Down|Up)?)\s*\(' },
        @{ Name = "legacy Netcode RPC attribute"; Pattern = '\[\s*(?:Unity\.Netcode\.)?(?:ServerRpc|ClientRpc)(?:Attribute)?\b' },
        @{ Name = "legacy UXML factory or traits"; Pattern = '\b(?:UxmlFactory|UxmlTraits)\b' },
        @{ Name = "C# 10 file-scoped namespace"; Pattern = '(?m)^\s*namespace\s+[A-Za-z_][\w.]*\s*;' },
        @{ Name = "C# 10 global using"; Pattern = '(?m)^\s*global\s+using\s+' },
        @{ Name = "C# 10 record struct"; Pattern = '\brecord\s+struct\s+' }
    )
    $examplePaths = @($trackedPaths | Where-Object { $_ -like "*.md" -and $_ -notmatch '^(?:Migrations|Ideas)/' -and $_ -notmatch 'GeurtsGameForgeIntelligence(?:Technique|IntegrationContract)\.md$' })
    foreach ($relative in $examplePaths) {
        $exampleText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $relative))
        foreach ($fence in [regex]::Matches($exampleText, '(?ms)^```(?:csharp|cs|c#)[ \t]*\r?\n(?<Code>.*?)^```[ \t]*\r?$')) {
            $exampleCount++
            foreach ($rule in $unsupportedExamplePatterns) {
                if ([regex]::IsMatch($fence.Groups["Code"].Value, $rule.Pattern)) {
                    $line = 1 + [regex]::Matches($exampleText.Substring(0, $fence.Index), '\n').Count
                    $exampleFailures.Add("${relative}:${line} uses $($rule.Name)") | Out-Null
                }
            }
        }
    }
    Add-Check "Unity C# example patterns" ($exampleCount -gt 0 -and $exampleFailures.Count -eq 0) $(if ($exampleFailures.Count) { $exampleFailures -join "; " } else { "$exampleCount current C# fragments pass the bounded legacy-API and language-pattern lint; Unity compilation and player compatibility are not established by this check." })

    $priorityPattern = '(?ms)^1\.\s+\*\*Extendibility\*\*.*?^2\.\s+\*\*Efficiency\*\*.*?^3\.\s+\*\*Readability\*\*.*?^4\.\s+\*\*Updated\*\*.*?^5\.\s+\*\*Documented\*\*'
    $technicalPriorityMatches = @([regex]::Matches($technicalText, $priorityPattern))
    $duplicatePriorityFiles = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @("README.md", "AGENTS.md", "AI_READ_FIRST.md", "GeurtsTechniqueManifest.md")) {
        if ([regex]::IsMatch([System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $relative)), $priorityPattern)) { $duplicatePriorityFiles.Add($relative) | Out-Null }
    }
    foreach ($technique in @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Filter "*.md" -File)) {
        $relative = "GeurtsTechniques/" + $technique.Name
        if ($relative -ceq $technicalRelative -or $relative -ceq $legacyGfiRedirectRelative) { continue }
        if ([regex]::IsMatch([System.IO.File]::ReadAllText($technique.FullName), $priorityPattern)) { $duplicatePriorityFiles.Add($relative) | Out-Null }
    }
    $technicalOwnerRow = [regex]::Match($manifestText, '(?m)^\| Technical implementation and technical trade-offs \| `GeurtsTechniques/GeurtsTechnicalTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    $priorityValid = $technicalPriorityMatches.Count -eq 1 -and $duplicatePriorityFiles.Count -eq 0 -and $technicalOwnerRow.Success -and $technicalOwnerRow.Groups["When"].Value -match '(?i)sole package owner of the five technical priorities and multiplayer override' -and $technicalText -match '(?i)network efficiency overrides all other priorities' -and $technicalText -match '(?i)override applies regardless of the selected networking framework'
    Add-Check "Technical priority ownership" $priorityValid $(if ($duplicatePriorityFiles.Count) { "Competing full priority list: " + ($duplicatePriorityFiles -join ", ") } else { "The exact five priorities and framework-independent multiplayer override occur normatively only in the manifest-selected Technical Technique." })

    $technicalPolicyFailures = New-Object System.Collections.Generic.List[string]
    $odinSection = [regex]::Match($technicalText, '(?ms)^## Odin Inspector Usage\s*(?<Body>.*?)(?=^---\s*$)')
    $odinBody = if ($odinSection.Success) { $odinSection.Groups["Body"].Value } else { "" }
    if (-not $odinSection.Success -or $odinBody -notmatch '(?i)Odin Inspector is required within the implementation scope' -or $odinBody -notmatch '(?i)installed, licensed, and referenced by each applicable assembly definition' -or $odinBody -notmatch '(?i)Use Odin attributes as the default authoring layer' -or $odinBody -notmatch '(?i)declarative drawers, validation, buttons, tables, and grouping' -or $odinBody -notmatch '(?i)\[Required\].*\[MinValue\].*\[MaxValue\]' -or $odinBody -notmatch '(?i)\[ValidateInput\]' -or $odinBody -notmatch '(?i)\[ReadOnly\].*\[ShowInInspector\]' -or $odinBody -notmatch '(?i)\[OdinSerialize\]`? only when Odin serialization is required' -or $odinBody -notmatch '(?i)support Undo and dirty/prefab recording') { $technicalPolicyFailures.Add("Odin Inspector is not a required, licensed, meaningfully used implementation dependency") | Out-Null }
    $odinTokens = @([regex]::Matches($technicalText, '\[(?:OdinSerialize|BoxGroup|TabGroup|FoldoutGroup|Button|ValidateInput)(?:\(|\])'))
    foreach ($odinToken in $odinTokens) { if (-not $odinSection.Success -or $odinToken.Index -lt $odinSection.Index -or $odinToken.Index -ge ($odinSection.Index + $odinSection.Length)) { $technicalPolicyFailures.Add("Odin-specific attribute guidance appears outside its owned section") | Out-Null; break } }
    $quantumSection = [regex]::Match($technicalText, '(?ms)^### Required Quantum Console Use\s*(?<Body>.*?)(?=^### Accessibility)')
    $quantumBody = if ($quantumSection.Success) { $quantumSection.Groups["Body"].Value } else { "" }
    if (-not $quantumSection.Success -or $quantumBody -notmatch '(?i)Quantum Console is the required runtime developer console' -or $quantumBody -notmatch '(?i)QFSW\.QC.*\[Command\].*\[CommandDescription\]' -or $quantumBody -notmatch '(?i)Play Mode and development builds' -or $quantumBody -notmatch '(?i)required EventSystem' -or $quantumBody -notmatch '(?i)SRP-compatible prefab/theme' -or $quantumBody -notmatch '(?i)integrate.*activate/deactivate events.*Input System' -or $quantumBody -notmatch '(?i)inspection, validation, tuning, recovery, performance, AI, and multiplayer diagnostics' -or $quantumBody -notmatch '(?i)logging facade') { $technicalPolicyFailures.Add("Quantum Console is not the required, meaningfully integrated runtime developer console") | Out-Null }
    if ($technicalText -notmatch '(?i)Player access is off by default and requires explicit project GDD or current-user selection' -or $technicalText -notmatch '(?i)console UI and command execution unavailable to players by default') { $technicalPolicyFailures.Add("Quantum Console player access is not strictly default-off") | Out-Null }
    if ($technicalText -notmatch '(?i)Missing dependencies are implementation blockers' -or $technicalText -notmatch '(?i)do not create a fallback inspector, serializer, command console, or parallel diagnostics framework' -or $technicalText -notmatch '(?i)companion retains its manifest-selected zero-dependency contract' -or $technicalText -match '(?i)Conditional Quantum Console Use|Odin Inspector is already installed') { $technicalPolicyFailures.Add("Required dependency scope, blocker behavior, fallback prohibition, or companion exception is incomplete") | Out-Null }
    if ($technicalText -notmatch '(?i)Unity Netcode for GameObjects only when it is already installed or selected' -or $technicalText -notmatch '(?i)Do not introduce or install it merely because this technique mentions it') { $technicalPolicyFailures.Add("Netcode for GameObjects is not strictly project-selected") | Out-Null }
    if ($technicalText -notmatch '(?i)Use UI Toolkit for new Geurts UI work' -or $technicalText -notmatch '(?i)Inspect the existing UI before changing it' -or $technicalText -notmatch '(?i)explicit user/project requirements for a scoped integration or migration' -or $technicalText -notmatch '(?i)do not perform a destructive automatic conversion' -or $technicalText -match '(?i)Unity.?s new UI system|new UI system') { $technicalPolicyFailures.Add("UI Toolkit or safe existing-UI migration rule is invalid") | Out-Null }
    if ($technicalText -notmatch '(?i)reusable cross-game Geurts Game Forge framework, library, or tooling component' -or $technicalText -notmatch '(?i)Geurts Game Forge Bricks is a positive example' -or $technicalText -notmatch '(?i)project-specific 2D map generator does not receive this header' -or $technicalText -notmatch '(?i)AI authorship alone is insufficient' -or $technicalText -notmatch '(?i)third-party packages, vendored code, generated code, read-only files' -or $technicalText -notmatch '(?i)format/tooling surface that forbids the header') { $technicalPolicyFailures.Add("compliance-header reusable-framework scope is incomplete") | Out-Null }
    Add-Check "Required technical dependencies and policies" ($technicalPolicyFailures.Count -eq 0) $(if ($technicalPolicyFailures.Count) { $technicalPolicyFailures -join "; " } else { "Odin Inspector and Quantum Console are required and meaningfully used in scoped Geurts implementation; their blocker and companion-exception boundaries, UI Toolkit, optional Netcode, player access, and compliance-header scope are explicit." })

    $gddTechniqueText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md"))
    $gddOwnerRow = [regex]::Match($manifestText, '(?m)^\| Project-specific design-document discovery and maintenance boundary \| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    $gddAuthorityValid = $gddOwnerRow.Success -and $gddOwnerRow.Groups["When"].Value -match '(?i)player-facing work' -and $gddTechniqueText -match '(?i)load every relevant document identified by the project.?s current `GameDesignManifest\.md`' -and $gddTechniqueText -match '(?i)stop and ask' -and $gddTechniqueText -match '(?i)establish or change player-facing design intent' -and $gddTechniqueText -match '(?i)reversible technical detail' -and $gddTechniqueText -match '(?i)does not create, alter, or overwrite design intent'
    Add-Check "Project GDD authority" $gddAuthorityValid "The package manifest selects the GDD Technique; the project GameDesignManifest selects relevant project facts; missing design intent is asked, never invented."

    $destructiveWarningValid = $gfiTechniqueText -match '(?i)destructive confirmation whose safe default is Cancel' -and $gfiTechniqueText -match '(?i)before any acquisition or project mutation begins' -and $gfiTechniqueText -match '(?i)Every local edit anywhere inside GeurtsGameForgeDocumentation will be overwritten and lost' -and $gfiTechniqueText -match '(?i)Project-authored Docs/GameDesign content and every other project file will remain untouched' -and $gfiTechniqueText -match '(?i)update has no rollback' -and $gfiTechniqueText -match '(?is)fails or is interrupted.{0,200}missing or incomplete' -and $gfiTechniqueText -match '(?i)Cancel must be the initially focused and default response' -and $gfiTechniqueText -match '(?i)Dismissing the warning, pressing Escape, closing the window[^\r\n]{0,160}no filesystem or network change'
    Add-Check "Frozen GFI v2 destructive warning" $destructiveWarningValid "The frozen released-consumer contract retains its cancel-default destructive-warning requirements."

    $manualUpdateSection = [regex]::Match($gfiTechniqueText, '(?ms)^## 4\. Explicit Manual Update\s*(?<Body>.*?)(?=^## 5\.)')
    $manualUpdateBody = if ($manualUpdateSection.Success) { $manualUpdateSection.Groups["Body"].Value } else { "" }
    $acquirePosition = $manualUpdateBody.IndexOf("Download or otherwise acquire", [System.StringComparison]::Ordinal)
    $validatePosition = $manualUpdateBody.IndexOf("Perform proportionate validation before deletion", [System.StringComparison]::Ordinal)
    $invalidateReceiptPosition = $manualUpdateBody.IndexOf("Immediately before the first destructive mutation of the live destination", [System.StringComparison]::Ordinal)
    $deletePosition = $manualUpdateBody.IndexOf('Delete the existing `<ProjectRoot>/GeurtsGameForgeDocumentation/`', [System.StringComparison]::Ordinal)
    $materializePosition = $manualUpdateBody.IndexOf("Materialize the validated complete tree", [System.StringComparison]::Ordinal)
    $writeReceiptPosition = $manualUpdateBody.IndexOf("Only then write a new current installed receipt", [System.StringComparison]::Ordinal)
    $cleanupPosition = $manualUpdateBody.IndexOf("Attempt to remove ephemeral acquisition residue", [System.StringComparison]::Ordinal)
    $replacementOrderValid = $acquirePosition -ge 0 -and $validatePosition -gt $acquirePosition -and $invalidateReceiptPosition -gt $validatePosition -and $deletePosition -gt $invalidateReceiptPosition -and $materializePosition -gt $deletePosition -and $writeReceiptPosition -gt $materializePosition -and $cleanupPosition -gt $writeReceiptPosition
    $completeReplacementValid = $manualUpdateSection.Success -and $replacementOrderValid -and $gfiTechniqueText -match '(?i)resolves the current head of `main`, captures that authoritative selected commit ID' -and $gfiTechniqueText -match '(?i)complete Git-tracked source tree' -and $gfiTechniqueText -match '(?i)selected Git tree[^\r\n]{0,120}defines the content set' -and $gfiTechniqueText -match '(?i)Preserve the tracked file bytes' -and $gfiTechniqueText -match '(?i)Reject unsafe paths, unsupported tracked object types, or an invalid package before deleting' -and $gfiTechniqueText -match '(?i)ephemeral location outside the live destination' -and $gfiTechniqueText -match '(?i)detached, writable content snapshot' -and $gfiTechniqueText -match '(?i)contains no `\.git` directory or file and no other Git metadata' -and $gfiTechniqueText -match '(?i)no repository, worktree, branch, remote, or continuing connection' -and $gfiTechniqueText -match '(?i)read-only file or directory attributes must be cleared' -and $gfiTechniqueText -match '(?i)cleanup failure or leftover ephemeral residue must never block a later' -and $gfiTechniqueText -match '(?i)best-effort basis'
    Add-Check "Frozen GFI v2 complete-tree replacement" $completeReplacementValid "The frozen released-consumer contract retains its internally coherent validated complete-tree replacement sequence."

    $receiptContradiction = $activeGfiContractSurfaceText -match '(?i)(?:historical|prior|former|older) receipt[^\r\n]{0,120}(?:may|can)\s+(?:continue to\s+)?(?:drive|supply|determine)' -or $activeGfiContractSurfaceText -match '(?i)package[- ]version(?: ordering| equality| inequality)?\s+(?:alone\s+)?(?:determines|may determine|can determine)[^\r\n]{0,120}(?:availability|Update is available)' -or $activeGfiContractSurfaceText -match '(?i)current installed receipt[^\r\n]{0,100}(?:retained|remains valid|kept)[^\r\n]{0,100}(?:through|after)[^\r\n]{0,60}(?:deletion|destructive mutation)' -or $activeGfiContractSurfaceText -match '(?i)(?:write|record)[^\r\n]{0,80}(?:new )?(?:current installed )?receipt[^\r\n]{0,100}before[^\r\n]{0,80}(?:copy|update).*(?:complete|success)'
    $receiptLifecycleValid = $replacementOrderValid -and $gfiTechniqueText -match '(?i)Every successful Update receipt records the authoritative selected commit ID' -and $gfiTechniqueText -match '(?i)also records the authoritative package version when the selected package exposes a valid version' -and $gfiTechniqueText -match '(?i)commit ID is the comparison baseline; the package version is display metadata' -and $gfiTechniqueText -match '(?i)historical receipt is diagnostic history only and must never drive the installed label or availability comparison' -and $gfiTechniqueText -match '(?i)report success only after that receipt is written' -and $gfiTechniqueText -match '(?i)Failure before receipt invalidation leaves the existing live copy and its current receipt unchanged' -and $gfiTechniqueText -match '(?i)Failure or interruption after receipt invalidation must leave the current receipt absent or invalid' -and $gfiTechniqueText -match '(?is)exact destination directory is absent.{0,160}UI shows `Not installed`.{0,200}directory exists there but the new copy did not complete successfully.{0,160}UI shows `Unknown`' -and $gfiTechniqueText -match '(?i)Do not restore or reuse a historical receipt' -and $gfiMigrationText -match '(?i)Immediately before destructive live deletion, it invalidates the current installed receipt' -and $gfiMigrationText -match '(?i)historical receipt must never drive the installed label or availability comparison afterward' -and $gfiMigrationText -match '(?i)new receipt is written only after complete success' -and -not $receiptContradiction
    Add-Check "Frozen GFI v2 receipt lifecycle" $receiptLifecycleValid "The frozen released-consumer contract retains its internally coherent commit-identity and current-receipt lifecycle."

    $aiBoundaryDelegates = $aiReadFirstText.Contains("<ProjectRoot>/GeurtsGameForgeDocumentation/") -and $aiReadFirstText.Contains("<ProjectRoot>/Docs/GameDesign/") -and $aiReadFirstText -match '(?i)(?:membership|integration lifecycle)[^\r\n]{0,100}outside this router.?s subject' -and $aiReadFirstText -match '(?i)manifest selects the applicable owner'
    $folderBoundaryDelegates = $folderTechniqueTextForPathTerms -match '(?i)placement boundary for a detached, writable project-local fetched copy' -and $folderTechniqueTextForPathTerms -match '(?i)folder-structure tool has no creation, replacement, or lifecycle authority' -and $folderTechniqueTextForPathTerms -match '(?i)manifest-selected integration technique owns the explicit manual Update boundary'
    $strictOverwriteBoundaryValid = $gfiTechniqueText -match '(?i)only project path this documentation Update may delete or replace' -and $gfiTechniqueText -match '(?i)Every file and byte there, and every other project file outside `<ProjectRoot>/GeurtsGameForgeDocumentation/`, must remain untouched' -and $gfiTechniqueText -match '(?i)documentation Update changes only `<ProjectRoot>/GeurtsGameForgeDocumentation/`' -and $gfiTechniqueText -match '(?i)must not invoke native-entry setup, GDD scaffolding, GDD manifest maintenance, folder creation, or `\.gitignore` provisioning' -and $gfiTechniqueText -match '(?i)must not invent project-specific GDD facts' -and $gfiTechniqueText -match '(?i)overwrite project-authored GDD' -and $gfiTechniqueText -match '(?i)silently overwrite user-authored native entries' -and $gfiTechniqueText -match '(?i)alter a differing project-root `\.gitignore`' -and $activeGfiContractSurfaceText -notmatch '(?i)(?:may|must|shall|will)\s+(?:also\s+)?(?:delete(?:\s+and\s+replace)?|replace|overwrite)\s+(?:the\s+)?(?:project-authored\s+)?`?(?:<ProjectRoot>/)?Docs/GameDesign'
    Add-Check "Frozen GFI v2 overwrite boundary" $strictOverwriteBoundaryValid "The frozen released-consumer contract remains bounded to its historical GeurtsGameForgeDocumentation-only replacement and never touches Docs/GameDesign."

    $requiredDiscardedTerms = @(
        "automatic documentation downloader or installer",
        "startup check that downloads or inspects local documentation",
        "activation transaction",
        "activation snapshot",
        "rollback system",
        "durable recovery journal",
        "recovery gate",
        "cleanup quarantine",
        "reset-recovery flow",
        "last-valid-copy mechanism",
        "local-drift preservation or override flow",
        "reintegration state machine",
        "backup/recovery state that blocks an update",
        "plugin-managed legacy installer migration"
    )
    $missingDiscardedTerms = @($requiredDiscardedTerms | Where-Object { $gfiTechniqueText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 })
    $activeGfiSurfaceText = $activeGfiContractSurfaceText
    $obsoleteAffirmativePhrases = @(
        "exactly one routine remote documentation check per Unity project launch or open",
        "acquire and stage an exact complete-tree candidate",
        "promote the candidate atomically",
        "combined rollback",
        "retain the validated candidate and last-valid evidence",
        "category/status=REINTEGRATION",
        "rerun integration reconciliation",
        "recognized prior package version may be migrated only through the plugin-owned transaction",
        '`contractFingerprint`'
    )
    $presentObsoleteAffirmative = @($obsoleteAffirmativePhrases | Where-Object { $activeGfiSurfaceText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 })
    $legacyEvidenceValid = $gfiTechniqueText.Contains("<ProjectRoot>/Library/GameForgeIntelligence/") -and $gfiTechniqueText -match '(?i)outside compatibility schema 2\.0\.0' -and $gfiTechniqueText -match '(?i)must not consult it, depend on it, or allow it to block documentation use or replacement' -and $gfiTechniqueText -match '(?i)leaves that legacy evidence untouched' -and $gfiTechniqueText -match '(?i)future cleanup requires a separate explicit operation and authority'
    $discardedLifecycleValid = $missingDiscardedTerms.Count -eq 0 -and $presentObsoleteAffirmative.Count -eq 0 -and $gfiTechniqueText -match '(?i)Do not recreate any of those mechanisms under different terminology' -and $legacyEvidenceValid
    Add-Check "Frozen GFI v2 discarded lifecycle exclusion" $discardedLifecycleValid $(if ($missingDiscardedTerms.Count) { "Missing explicit lifecycle exclusions: " + ($missingDiscardedTerms -join ", ") } elseif ($presentObsoleteAffirmative.Count) { "Obsolete affirmative lifecycle language reintroduced: " + ($presentObsoleteAffirmative -join ", ") } else { "The frozen v2 contract forbids its older automatic transaction/recovery system and leaves legacy Library evidence untouched and non-blocking." })

    $draftStatusValid = @(
        @{ Path = "GeurtsTechniques/GeurtsFolderStructureTechnique.md"; Registry = '(?m)^\| `GeurtsTechniques/GeurtsFolderStructureTechnique\.md` \| 0\.10\.0 \| Normative ' },
        @{ Path = "GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md"; Registry = '(?m)^\| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique\.md` \| 0\.10\.0 \| Normative ' },
        @{ Path = "GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md"; Registry = '(?m)^\| `GeurtsTechniques/GeurtsDocumentationCompanionTechnique\.md` \| 1\.0\.1 \| Normative ' }
    ) | ForEach-Object { ([System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $_.Path)) -match '(?im)^\*\*Status:\*\* Draft normative technique\s*$') -and ($manifestText -match $_.Registry) } | Where-Object { -not $_ } | Measure-Object | Select-Object -ExpandProperty Count
    Add-Check "Normative status and registry roles" ($draftStatusValid -eq 0) "Folder, GDD, and Documentation Companion techniques consistently declare Draft normative status and normative manifest roles."

    $managerText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/ManageGeurtsAgentInstructions.ps1"))
    $managerSafetyMissing = @("Test-HasReparsePoint", "Test-NativeMigrationCatalog", "native-entry", "gdd-scaffolding", "IncludeGameDesignScaffolding", "UpdateGameDesignManifest", "frontmatter delimiters", "unsupported version", "no downgrade", "GEURTS-MANAGED-OPT-OUT", ".pre-v0.9.0.bak", "Read-ManagedTextFile", "Unsupported UTF-32 encoding", "UnicodeEncoding", "UTF8Encoding", "Get-ByteHash", "Get-FileByteHash", "ExpectedState", "ExpectedByteHash", "Convert-Newlines", "Get-NewlineConvention", "Target bytes changed after they were read", "Target appeared after preflight", ".ggf-backup-", "Backup target appeared after preflight") | Where-Object { $managerText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 } | Measure-Object | Select-Object -ExpandProperty Count
    $catalogText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/NativeEntryMigrationCatalog.json"))
    $managerScopeValid = $managerText -notmatch '(?i)SkipGameDesignManifestUpdate' -and $catalogText -notmatch '(?i)knownWholeFileSha256|beginMarker|endMarker'
    $managerWriterMatch = [regex]::Match($managerText, '(?ms)^function Write-AtomicText\(.*?^}\r?$')
    $managerWriterText = if ($managerWriterMatch.Success) { $managerWriterMatch.Value } else { "" }
    $managerWriterBarrier = $managerWriterText.IndexOf("Invoke-TestWriteBarrier", [System.StringComparison]::Ordinal)
    $managerWriterContainment = if ($managerWriterBarrier -ge 0) { $managerWriterText.IndexOf("Test-IsContainedPath", $managerWriterBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerWriterReparse = if ($managerWriterBarrier -ge 0) { $managerWriterText.IndexOf("Test-HasReparsePoint", $managerWriterBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerWriterState = $managerWriterText.IndexOf('if ($ExpectedState', [System.StringComparison]::Ordinal)
    $managerWriterMove = $managerWriterText.IndexOf("[System.IO.File]::Move", [System.StringComparison]::Ordinal)
    $managerWriterHash = $managerWriterText.IndexOf("Get-FileByteHash", [System.StringComparison]::Ordinal)
    $managerWriterReplace = $managerWriterText.IndexOf("[System.IO.File]::Replace", [System.StringComparison]::Ordinal)
    $managerWriterOrderValid = $managerWriterBarrier -ge 0 -and $managerWriterContainment -gt $managerWriterBarrier -and $managerWriterReparse -ge $managerWriterContainment -and $managerWriterState -gt $managerWriterReparse -and $managerWriterMove -gt $managerWriterState -and $managerWriterHash -gt $managerWriterState -and $managerWriterReplace -gt $managerWriterHash -and $managerWriterText.Contains('Join-Path $AllowedRoot') -and $managerWriterText.Contains('$parentIsRootOrContained') -and $managerWriterText.Contains('Atomic target parent must already exist safely below the validated project root') -and $managerWriterText.IndexOf('New-Item', [System.StringComparison]::OrdinalIgnoreCase) -lt 0
    $managerBackupMatch = [regex]::Match($managerText, '(?ms)^function New-Backup\(.*?^}\r?$')
    $managerBackupText = if ($managerBackupMatch.Success) { $managerBackupMatch.Value } else { "" }
    $managerBackupCapture = $managerBackupText.IndexOf("[System.IO.File]::Copy", [System.StringComparison]::Ordinal)
    $managerBackupBarrier = $managerBackupText.IndexOf("Invoke-TestWriteBarrier", [System.StringComparison]::Ordinal)
    $managerBackupContainment = if ($managerBackupBarrier -ge 0) { $managerBackupText.IndexOf("Test-IsContainedPath", $managerBackupBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerBackupReparse = if ($managerBackupBarrier -ge 0) { $managerBackupText.IndexOf("Test-HasReparsePoint", $managerBackupBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerBackupHash = if ($managerBackupBarrier -ge 0) { $managerBackupText.IndexOf("Get-FileByteHash", $managerBackupBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerBackupAbsent = if ($managerBackupBarrier -ge 0) { $managerBackupText.IndexOf('Test-Path -LiteralPath $finalBackup', $managerBackupBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerBackupMove = if ($managerBackupBarrier -ge 0) { $managerBackupText.IndexOf("[System.IO.File]::Move", $managerBackupBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerBackupOrderValid = $managerBackupText.Contains('Join-Path $root') -and $managerBackupCapture -ge 0 -and $managerBackupBarrier -gt $managerBackupCapture -and $managerBackupContainment -gt $managerBackupBarrier -and $managerBackupReparse -ge $managerBackupContainment -and $managerBackupHash -gt $managerBackupReparse -and $managerBackupAbsent -gt $managerBackupHash -and $managerBackupMove -gt $managerBackupAbsent
    $managerDirectoryBarrier = $managerText.IndexOf('Invoke-TestWriteBarrier -TargetPath $directory.Path', [System.StringComparison]::Ordinal)
    $managerDirectoryContainment = if ($managerDirectoryBarrier -ge 0) { $managerText.IndexOf('Test-IsContainedPath -Candidate $finalDirectoryPath', $managerDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerDirectoryReparse = if ($managerDirectoryBarrier -ge 0) { $managerText.IndexOf('Test-HasReparsePoint -Candidate $finalDirectoryPath', $managerDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerDirectoryAcceptance = if ($managerDirectoryBarrier -ge 0) { $managerText.IndexOf('Test-Path -LiteralPath $finalDirectoryPath -PathType Container', $managerDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerDirectoryCreate = if ($managerDirectoryBarrier -ge 0) { $managerText.IndexOf('New-Item -ItemType Directory -Path $finalDirectoryPath', $managerDirectoryBarrier, [System.StringComparison]::Ordinal) } else { -1 }
    $managerDirectoryOrderValid = $managerDirectoryBarrier -ge 0 -and $managerDirectoryContainment -gt $managerDirectoryBarrier -and $managerDirectoryReparse -ge $managerDirectoryContainment -and $managerDirectoryAcceptance -gt $managerDirectoryReparse -and $managerDirectoryCreate -gt $managerDirectoryAcceptance
    $setupTechniqueText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsAIAgentSetupTechnique.md"))
    $managerOwnerSafetyValid = $setupTechniqueText -match '(?i)preserve bytes outside the managed region' -and $setupTechniqueText -match '(?i)UTF-8, UTF-8-BOM, UTF-16LE-BOM, or UTF-16BE-BOM' -and $setupTechniqueText -match '(?i)reject invalid text and UTF-32 without mutation' -and $setupTechniqueText -match '(?i)target managed region.?s newline convention' -and $setupTechniqueText -match '(?i)explicit expected target state.*absent.*exact raw-byte fingerprint' -and $setupTechniqueText -match '(?i)Immediately before promotion.*revalidates containment.*complete path chain.*reparse points' -and $setupTechniqueText -match '(?i)unexpected file or any byte drift.*conflict' -and $setupTechniqueText -match '(?i)backup does not authorize replacing concurrent user content' -and $setupTechniqueText -match '(?i)Before promoting an adjacent safety backup.*revalidates source and backup containment' -and $setupTechniqueText -match '(?i)both complete path chains.*expected raw-byte fingerprint.*expected absence' -and $setupTechniqueText -match '(?i)failed backup guard preserves the target and promotes no backup' -and $setupTechniqueText -match '(?i)final containment and full-chain reparse check applies immediately before.*accepts an existing delegated setup directory or creates a missing one'
    Add-Check "Native-entry safety contract" ($managerSafetyMissing -eq 0 -and $managerScopeValid -and $managerWriterOrderValid -and $managerBackupOrderValid -and $managerDirectoryOrderValid -and $managerOwnerSafetyValid) "Native entries use strict supported encodings, exact outside bytes, target-region newlines, byte-CAS expected state, root-owned write/backup artifacts, and final file/backup/directory containment plus reparse guards; backups never authorize overwrite."

    $explicitRootFailures = New-Object System.Collections.Generic.List[string]
    foreach ($relative in @("Tools/CreateGeurtsFolderStructure.ps1", "Tools/ManageGeurtsAgentInstructions.ps1", "Tools/UpdateGameDesignManifest.ps1")) {
        $toolText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $relative))
        $commonRootGuardInvalid = $toolText.IndexOf("ProjectRoot is required", [System.StringComparison]::OrdinalIgnoreCase) -lt 0 -or @(@("Assets", "Packages", "ProjectSettings") | Where-Object { $toolText.IndexOf($_, [System.StringComparison]::Ordinal) -lt 0 }).Count -gt 0 -or $toolText.IndexOf('$ProjectRoot = Split-Path -Parent $PSScriptRoot', [System.StringComparison]::Ordinal) -ge 0
        $containerGuardInvalid = $toolText.IndexOf("Assert-UnityProjectRoot", [System.StringComparison]::Ordinal) -lt 0 -or $toolText.IndexOf("documentation source or project-local fetched documentation copy", [System.StringComparison]::OrdinalIgnoreCase) -lt 0
        if ($commonRootGuardInvalid -or $containerGuardInvalid) {
            $explicitRootFailures.Add($relative) | Out-Null
        }
    }
    foreach ($relative in @("Tools/CreateAIAgentInstructionFiles.bat", "Tools/CreateGeurtsFolderStructure.bat")) {
        $launcherText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $relative))
        if ($launcherText -notmatch '(?im)^rem Version: 0\.9\.0\s*$' -or $launcherText -notmatch '(?i)if /I not "%~1"=="-ProjectRoot"' -or $launcherText -notmatch '(?i)-ProjectRoot requires a Unity project path') { $explicitRootFailures.Add($relative) | Out-Null }
    }
    Add-Check "Explicit Unity project roots" ($explicitRootFailures.Count -eq 0) $(if ($explicitRootFailures.Count) { "Unsafe or ambiguous project-root handling: " + ($explicitRootFailures -join ", ") } else { "All project-mutating PowerShell tools and launchers require an explicit Unity root with Assets, Packages, and ProjectSettings; none derives it from the copied Tools location." })

    $usageFailures = New-Object System.Collections.Generic.List[string]
    $usageDocuments = @("README.md", "AI_READ_FIRST.md", "AGENTS.md", "GeurtsTechniqueManifest.md", "Migrations/v0.11.0.md")
    $usageDocuments += @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Filter "*.md" -File | ForEach-Object { "GeurtsTechniques/" + $_.Name })
    $toolInvocationPattern = '(?i)(?:powershell|pwsh|\.bat).*?(?:ManageGeurtsAgentInstructions|CreateGeurtsFolderStructure|UpdateGameDesignManifest|CreateAIAgentInstructionFiles)'
    foreach ($relative in $usageDocuments) {
        $lineNumber = 0
        foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $RepositoryRoot $relative))) {
            $lineNumber++
            if ($line -match $toolInvocationPattern -and $line.IndexOf("-ProjectRoot", [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { $usageFailures.Add("$relative`:$lineNumber omits explicit -ProjectRoot") | Out-Null }
        }
    }
    $readmeText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "README.md"))
    $batchText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/CreateAIAgentInstructionFiles.bat"))
    foreach ($surface in @($setupTechniqueText, $readmeText)) {
        if ($surface.IndexOf("-IncludeGameDesignScaffolding", [System.StringComparison]::Ordinal) -lt 0 -or $surface.IndexOf("-UpdateGameDesignManifest", [System.StringComparison]::Ordinal) -lt 0 -or $surface -notmatch '(?i)(?:native-entry|native entries|manual manager|legacy manager).*?(?:does not implicitly create|never creates|handles native entries only|changes native entries only).*?Docs/GameDesign') { $usageFailures.Add("manager scope is not documented as native-only with two positive GDD opt-ins") | Out-Null }
    }
    if ($managerText.IndexOf("[switch]`$IncludeGameDesignScaffolding", [System.StringComparison]::Ordinal) -lt 0 -or $managerText.IndexOf("[switch]`$UpdateGameDesignManifest", [System.StringComparison]::Ordinal) -lt 0 -or $batchText.IndexOf("-IncludeGameDesignScaffolding", [System.StringComparison]::Ordinal) -lt 0 -or $batchText.IndexOf("-UpdateGameDesignManifest", [System.StringComparison]::Ordinal) -lt 0) { $usageFailures.Add("manager or launcher does not expose both positive GDD opt-ins") | Out-Null }
    Add-Check "Tool invocation and scope documentation" ($usageFailures.Count -eq 0) $(if ($usageFailures.Count) { $usageFailures -join "; " } else { "Every current/v0.11 manual-tool example passes explicit -ProjectRoot; native-only default, create-missing GDD scaffolding, and independent manifest maintenance match the CLI." })

    $gddToolText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/UpdateGameDesignManifest.ps1"))
    $gddSafetyMissing = @("Get-SafeDesignFiles", "Test-HasReparsePoint", "lockOwned", "Get-ExistingEntries", "Get-OrdinalSortedEntries", "required project path", "Manifest bytes changed after they were read", "no downgrade", "invalid version", "Read-ManagedTextFile", "Unsupported UTF-32 encoding", "UnicodeEncoding", "UTF8Encoding", "ByteHash", "ExpectedState", "ExpectedByteHash", "Invoke-TestWriteBarrier", "FileMode]::CreateNew", "FileOptions]::DeleteOnClose") | Where-Object { $gddToolText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 } | Measure-Object | Select-Object -ExpandProperty Count
    $gddWriterMatch = [regex]::Match($gddToolText, '(?ms)^function Write-AtomicText\(.*?^}\r?$')
    $gddWriterText = if ($gddWriterMatch.Success) { $gddWriterMatch.Value } else { "" }
    $gddWriterBarrier = $gddWriterText.IndexOf("Invoke-TestWriteBarrier", [System.StringComparison]::Ordinal)
    $gddWriterContainment = $gddWriterText.IndexOf("Test-IsContainedPath", [System.StringComparison]::Ordinal)
    $gddWriterReparse = $gddWriterText.IndexOf("Test-HasReparsePoint", [System.StringComparison]::Ordinal)
    $gddWriterState = $gddWriterText.IndexOf('if ($ExpectedState', [System.StringComparison]::Ordinal)
    $gddWriterMove = $gddWriterText.IndexOf("[System.IO.File]::Move", [System.StringComparison]::Ordinal)
    $gddWriterHash = $gddWriterText.IndexOf("Get-FileSha256", [System.StringComparison]::Ordinal)
    $gddWriterReplace = $gddWriterText.IndexOf("[System.IO.File]::Replace", [System.StringComparison]::Ordinal)
    $gddWriterOrderValid = $gddWriterBarrier -ge 0 -and $gddWriterContainment -gt $gddWriterBarrier -and $gddWriterReparse -ge $gddWriterContainment -and $gddWriterState -gt $gddWriterReparse -and $gddWriterMove -gt $gddWriterState -and $gddWriterHash -gt $gddWriterState -and $gddWriterReplace -gt $gddWriterHash -and $gddWriterText.Contains('Join-Path $AllowedRoot')
    $gddOwnerSafetyValid = $gddTechniqueText -match '(?i)preserving the exact bytes outside' -and $gddTechniqueText -match '(?i)UTF-8, UTF-8-BOM, UTF-16LE-BOM, or UTF-16BE-BOM' -and $gddTechniqueText -match '(?i)reject invalid text or UTF-32 without mutation' -and $gddTechniqueText -match '(?i)create-new, handle-owned delete-on-close semantics' -and $gddTechniqueText -match '(?i)pre-existing lock path.*conflict.*preserve its exact bytes' -and $gddTechniqueText -match '(?i)remove only the lock represented by its acquired handle' -and $gddTechniqueText -match '(?i)raw-byte fingerprint captured at read time' -and $gddTechniqueText -match '(?i)immediately before atomic promotion.*revalidate containment and the full path chain' -and $gddTechniqueText -match '(?i)reject any existence or byte drift instead of overwriting concurrent content'
    $gddRootArtifactsValid = $gddToolText.Contains('Join-Path $ProjectRoot ".ggf-manifest.lock"') -and $gddToolText.Contains('[System.IO.FileMode]::CreateNew') -and $gddToolText.Contains('[System.IO.FileOptions]::DeleteOnClose') -and $gddToolText -notmatch '\[System\.IO\.FileMode\]::OpenOrCreate' -and $gddToolText -notmatch 'Join-Path\s+\$designRoot\s+"\.ggf-manifest\.lock"' -and $gddWriterText.Contains('Join-Path $AllowedRoot')
    Add-Check "GDD maintenance safety contract" ($gddSafetyMissing -eq 0 -and $gddWriterOrderValid -and $gddOwnerSafetyValid -and $gddRootArtifactsValid) "GDD maintenance preserves supported encoding and exact outside bytes, rejects invalid/UTF-32 input, uses raw-byte expected-state protection, keeps ephemeral artifacts at ProjectRoot, and rechecks containment/reparse paths immediately before promotion."

    if ($RunAutomationTests) {
        $testScript = Join-Path $RepositoryRoot "Tools/Tests/RunAutomationTests.ps1"
        $hostPath = (Get-Process -Id $PID).Path
        $testArguments = @("-NoProfile", "-File", $testScript, "-RepositoryRoot", $RepositoryRoot)
        if ($OutputFormat -eq "Json") { $testArguments += @("-OutputFormat", "Json") }
        $testOutput = @(& $hostPath @testArguments 2>&1)
        $testExitCode = $LASTEXITCODE
        if ($OutputFormat -eq "Text") {
            foreach ($line in $testOutput) { Write-Host ([string]$line) }
        }
        else {
            try { $automationTests = ($testOutput -join [Environment]::NewLine) | ConvertFrom-Json }
            catch {
                $automationTests = [pscustomobject]@{ status = "INVALID_OUTPUT"; exitCode = $testExitCode }
                $testExitCode = 1
            }
        }
        Add-Check "Automation test suite" ($testExitCode -eq 0) "Automation tests exited with code $testExitCode."
    }

    $passed = $failures.Count -eq 0
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{ status = $(if ($passed) { "VALID" } else { "INVALID" }); checks = $checks.ToArray(); failures = $failures.ToArray(); automationTests = $automationTests } | ConvertTo-Json -Depth 9
    }
    if ($passed) { exit 0 }
    exit 1
}
catch {
    if ($OutputFormat -eq "Json") { [pscustomobject]@{ status = "FAILED"; message = $_.Exception.Message; checks = $checks.ToArray(); automationTests = $automationTests } | ConvertTo-Json -Depth 9 }
    else { Write-Host "VALIDATION FAILED: $($_.Exception.Message)" -ForegroundColor Red }
    exit 1
}
