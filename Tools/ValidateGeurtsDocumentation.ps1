# ValidateGeurtsDocumentation.ps1
# Version: 0.9.0

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
    Add-Check "Package version" ($packageVersion -eq "0.9.0") "Manifest package version is $packageVersion."

    $readmeStatusText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "README.md"))
    $migrationStatusText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Migrations/v0.9.0.md"))
    $gfiStatusText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md"))
    $draftStatusValid = $manifestText -match '(?im)^\*\*Status:\*\*\s*Draft normative package manifest\s*$' -and $readmeStatusText -match '(?im)^\*\*Status:\*\*\s*Draft technique package\s*$' -and $gfiStatusText -match '(?im)^\*\*Status:\*\*\s*Draft normative technique\s*$' -and $migrationStatusText -match '(?i)planned transition' -and $migrationStatusText -match '(?i)target-release snapshot' -and $migrationStatusText -notmatch '(?i)(?:v0\.9\.0|package v0\.9\.0)[^\r\n]{0,80}(?:is|was|has been) released'
    Add-Check "Draft target-release status" $draftStatusValid "Package v0.9.0 remains a Draft target release; its migration guide is a planned target-release snapshot, not a completed-release claim."

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
        $sequenceLines = @([regex]::Matches($resolverBody, '(?m)^(?<Number>[0-9]+)\.\s+(?<Text>[^\r\n]+)$'))
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
        $gfiPosition = $resolverBody.IndexOf("selected Game Forge Intelligence", [System.StringComparison]::OrdinalIgnoreCase)
        $gddPosition = $resolverBody.IndexOf("project-specific game-design", [System.StringComparison]::OrdinalIgnoreCase)
        $productPosition = $resolverBody.IndexOf("product- or plugin-owned", [System.StringComparison]::OrdinalIgnoreCase)
        if ($gfiPosition -lt 0 -or $genericPosition -le $gfiPosition -or $gddPosition -le $genericPosition -or $productPosition -le $gddPosition) { $resolverFailures.Add("post-entry integration, generic, project-design, and subordinate-product order is not deterministic") | Out-Null }
    }

    $expectedSubjectOwners = @(
        "GeurtsTechniques/GeurtsTechnicalTechnique.md",
        "GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md",
        "GeurtsTechniques/GeurtsFolderStructureTechnique.md",
        "GeurtsTechniques/GeurtsFolderStructureDefinition.json",
        "GeurtsTechniques/GeurtsAIAgentSetupTechnique.md",
        "GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md",
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
    $obsoletePlainPathTerm = "canon" + "ical"
    foreach ($file in @(Get-ChildItem -LiteralPath $RepositoryRoot -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })) {
        $text = [System.IO.File]::ReadAllText($file.FullName)
        if ($text.Replace("canonicalPath", "").Replace("CanonicalPath", "") -match ("(?i)\b" + $obsoletePlainPathTerm + "\b")) {
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
    $redirectRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract\.md` \| 1\.0\.0 \| (?<Role>[^|]+) \|\r?$')
    $redirectValid = $legacyGfiRedirectText.StartsWith("# Moved: Geurts Game Forge Intelligence Integration Contract", [System.StringComparison]::Ordinal) -and $legacyGfiRedirectText.Contains("**Version:** 1.0.0") -and $legacyGfiRedirectText.Contains("**Status:** Non-normative compatibility redirect") -and $legacyGfiRedirectText.Contains('**Legacy compatibility redirect path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`') -and $legacyGfiRedirectText.Contains("GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md") -and $legacyGfiRedirectText -match '(?i)(?:fail compatibility safely|fail closed)' -and -not $legacyGfiRedirectText.Contains("**Required package path:**") -and -not $legacyGfiRedirectText.Contains("| Subject |") -and $legacyGfiRedirectText.Length -lt 2000 -and $redirectRegistryRow.Success -and $redirectRegistryRow.Groups["Role"].Value -match '(?i)non-normative compatibility redirect' -and $redirectRegistryRow.Groups["Role"].Value -match '(?i)never selected' -and $subjectSectionForRedirect.Success -and $subjectSectionForRedirect.Groups["Body"].Value.IndexOf($legacyGfiRedirectRelative, [System.StringComparison]::Ordinal) -lt 0
    Add-Check "GFI compatibility redirect" $redirectValid "The legacy path is a short non-normative fail-closed pointer to the single manifest-selected Game Forge Intelligence Technique and cannot become a second owner."

    $gfiRegistryRow = [regex]::Match($manifestText, '(?m)^\| `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique\.md` \| 1\.0\.0 \| (?<Role>[^|]+) \|\r?$')
    $gfiCompatibilityValid = $gfiTechniqueText -match '(?im)^\*\*Compatibility schema:\*\*\s*1\.0\.0\s*$' -and $gfiRegistryRow.Success -and $gfiRegistryRow.Groups["Role"].Value -match '(?i)compatibility schema 1\.0\.0' -and $gfiRegistryRow.Groups["Role"].Value -notmatch '(?i)compatibility schema v1\.0\.0' -and $gfiTechniqueText.Contains('`contractPath`') -and $gfiTechniqueText.Contains('`contractVersion`') -and $gfiTechniqueText.Contains('`contractFingerprint`') -and $gfiTechniqueText -match '(?i)`contractFingerprint` is the lowercase 64-hex SHA-256' -and $gfiTechniqueText -match '(?i)technique file.?s exact raw bytes in the active validated commit' -and $gfiTechniqueText -match '(?i)no text, encoding, or newline normalization' -and $gfiTechniqueText -match '(?i)COMPATIBILITY' -and $gfiTechniqueText -match '(?i)PLUGIN_UPDATE_REQUIRED' -and $gfiTechniqueText -match '(?i)REINTEGRATION'
    Add-Check "GFI compatibility metadata" $gfiCompatibilityValid "The normative integration boundary declares schema 1.0.0, stable contract keys, an exact-raw-byte lowercase SHA-256 fingerprint with no text normalization, and distinct compatibility, plugin-update, and reintegration outcomes."

    $gfiLifecycleOwnerRow = [regex]::Match($manifestText, '(?m)^\| Game Forge Intelligence documentation-consumption and compatibility boundary \| `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    $aiBoundaryDelegates = $aiReadFirstText.Contains("<ProjectRoot>/GeurtsGameForgeDocumentation/") -and $aiReadFirstText.Contains("<ProjectRoot>/Docs/GameDesign/") -and $aiReadFirstText -match '(?i)(?:membership|integration lifecycle)[^\r\n]{0,100}outside this router.?s subject' -and $aiReadFirstText -match '(?i)manifest selects the applicable owner'
    $folderBoundaryDelegates = $folderTechniqueTextForPathTerms -match '(?i)placement and read-only content boundary' -and $folderTechniqueTextForPathTerms -match '(?i)folder-structure tool has no creation or lifecycle authority' -and $folderTechniqueTextForPathTerms -match '(?i)manifest-selected integration technique owns installation'
    $gfiLifecycleOwns = $gfiLifecycleOwnerRow.Success -and $gfiLifecycleOwnerRow.Groups["When"].Value -match '(?i)(?:consumes|compatibility)' -and $gfiTechniqueText -match '(?im)^## 3\. Plugin-Owned Startup and Activation\s*$' -and $gfiTechniqueText -match '(?i)acquire and stage an exact complete-tree candidate' -and $gfiTechniqueText -match '(?i)preflight compatibility' -and $gfiTechniqueText -match '(?i)promote the candidate atomically' -and $gfiTechniqueText -match '(?i)combined rollback'
    $gfiStartupTimingValid = $gfiTechniqueText -match '(?i)exactly one routine remote documentation check per Unity project launch or open' -and $gfiTechniqueText -match '(?i)Ordinary AI-session initialization uses and locally validates that already-local copy' -and $gfiTechniqueText -match '(?i)must not make a second routine network check' -and $gfiTechniqueText -match '(?i)user-requested refresh capability is separate from the launch check'
    Add-Check "Integration lifecycle ownership" ($aiBoundaryDelegates -and $folderBoundaryDelegates -and $gfiLifecycleOwns -and $gfiStartupTimingValid) "AI_READ_FIRST routes the package/GDD boundary, Folder owns placement/tool exclusion, and the selected Game Forge Intelligence Technique owns one launch-time remote check while ordinary AI sessions locally validate the existing copy without a second routine network check."

    $nativeTemplates = @(
        "Tools/AIAgentInstructionTemplates/AGENTS.md",
        "Tools/AIAgentInstructionTemplates/copilot-instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
    )
    $routeFailures = New-Object System.Collections.Generic.List[string]
    $markerFailures = New-Object System.Collections.Generic.List[string]
    $htmlRegionPattern = '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*-->\r?\n(?<Body>.*?)^<!--\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*-->[^\S\r\n]*(?=\r?\n|\z)'
    $yamlRegionPattern = '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="(?<Version>[0-9]+\.[0-9]+\.[0-9]+)"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*\r?\n(?<Body>.*?)^#\s*GEURTS-MANAGED-END\s+id="\k<Id>"[^\S\r\n]*(?=\r?\n|\z)'
    foreach ($relative in $nativeTemplates) {
        $path = Join-Path $RepositoryRoot ($relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        $text = [System.IO.File]::ReadAllText($path)
        $expectedTemplateVersion = "0.9.0"
        if ($text.IndexOf("GeurtsGameForgeDocumentation/AGENTS.md", [System.StringComparison]::Ordinal) -lt 0 -or $text.IndexOf("GeurtsGameForgeDocumentation/AI_READ_FIRST.md", [System.StringComparison]::Ordinal) -ge 0) { $routeFailures.Add("$relative does not route first through copied AGENTS.md") | Out-Null }
        if ($text.IndexOf("network efficiency", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $routeFailures.Add("$relative duplicates implementation policy instead of remaining a concise route") | Out-Null }
        if ($relative -ceq "Tools/AIAgentInstructionTemplates/AGENTS.md") {
            if ($text.IndexOf("Docs/GameDesign/", [System.StringComparison]::Ordinal) -ge 0) { $routeFailures.Add("$relative is not a concise copied-AGENTS discovery shim") | Out-Null }
        }
        elseif ($text.IndexOf("manifest-controlled package chain", [System.StringComparison]::Ordinal) -lt 0 -or $text.IndexOf("owns the complete documentation chain", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $routeFailures.Add("$relative does not defer package selection and order to the manifest-controlled chain") | Out-Null
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
            if ($region.Groups["Version"].Value -cne $expectedTemplateVersion) {
                $markerFailures.Add("$relative region $($region.Groups['Id'].Value) declares version $($region.Groups['Version'].Value) instead of $expectedTemplateVersion") | Out-Null
            }
            if ((Get-TextHash -Text $region.Groups["Body"].Value) -ne $region.Groups["Hash"].Value.ToLowerInvariant()) {
                $markerFailures.Add("$relative region $($region.Groups['Id'].Value) has a bad hash") | Out-Null
            }
        }
    }
    Add-Check "Managed native routes" ($routeFailures.Count -eq 0) $(if ($routeFailures.Count) { "Invalid managed route: " + ($routeFailures -join ", ") } else { "Every native template routes first through copied AGENTS.md; non-AGENTS shims defer package selection and order to the manifest-controlled chain." })
    Add-Check "Managed template integrity" ($markerFailures.Count -eq 0) $(if ($markerFailures.Count) { $markerFailures -join "; " } else { "All native managed regions and hashes are valid." })

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
        if ([string]$migrationCatalog.schemaVersion -cne "0.9.0" -or [string]$migrationCatalog.normalization -cne "utf8-text-with-lf-newlines-and-terminal-lf" -or @($migrationCatalog.entries).Count -ne 4) { $catalogFailures.Add("catalog metadata or target count is invalid") | Out-Null }
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
    $gddValid = $gddTemplate.Contains('GEURTS-GDD-MANIFEST-BEGIN version="0.7.0"') -and @($gddFields | Where-Object { $gddTemplate -notmatch "\|\s*$([regex]::Escape($_))\s*\|" }).Count -eq 0 -and $gddReadmeTemplate.Contains('GEURTS-SCAFFOLD-BEGIN version="0.9.0"') -and $gddReadmeTemplate -match '(?i)missing information would establish or change player-facing design intent' -and $gddReadmeTemplate -match '(?i)reversible technical details that do not create or overwrite design facts'
    Add-Check "GDD scaffold contract" $gddValid "Managed GDD index retains its deterministic v0.7.0 format, while the v0.9.0 README route stops for missing design intent and permits only reversible non-design assumptions."

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
                definitionVersion = "0.8.0"
                packageVersion = "0.9.0"
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
                if (-not $profileScopeValid) { $folderFailures.Add("$folderPath differs from its exact v0.8.0 profile scope") | Out-Null }
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
    if (-not $odinSection.Success -or $odinSection.Groups["Body"].Value -notmatch '(?i)already installed.*explicitly selected' -or $odinSection.Groups["Body"].Value -notmatch '(?i)does not require or authorize installing Odin') { $technicalPolicyFailures.Add("Odin is not strictly installed/selected conditional") | Out-Null }
    $odinTokens = @([regex]::Matches($technicalText, '\[(?:OdinSerialize|BoxGroup|TabGroup|FoldoutGroup|Button|ValidateInput)(?:\(|\])'))
    foreach ($odinToken in $odinTokens) { if (-not $odinSection.Success -or $odinToken.Index -lt $odinSection.Index -or $odinToken.Index -ge ($odinSection.Index + $odinSection.Length)) { $technicalPolicyFailures.Add("Odin attribute appears outside its conditional section") | Out-Null; break } }
    if ($technicalText -notmatch '(?is)Conditional Quantum Console Use.*already installed or explicitly selected.*does not require or authorize installing it' -or $technicalText -notmatch '(?i)Player access is off by default and requires explicit project GDD or current-user selection') { $technicalPolicyFailures.Add("Quantum console/player access is not strictly selected and default-off") | Out-Null }
    if ($technicalText -notmatch '(?i)Unity Netcode for GameObjects only when it is already installed or selected' -or $technicalText -notmatch '(?i)Do not introduce or install it merely because this technique mentions it') { $technicalPolicyFailures.Add("Netcode for GameObjects is not strictly project-selected") | Out-Null }
    if ($technicalText -notmatch '(?i)Use UI Toolkit for new Geurts UI work' -or $technicalText -notmatch '(?i)Inspect the existing UI before changing it' -or $technicalText -notmatch '(?i)explicit user/project requirements for a scoped integration or migration' -or $technicalText -notmatch '(?i)do not perform a destructive automatic conversion' -or $technicalText -match '(?i)Unity.?s new UI system|new UI system') { $technicalPolicyFailures.Add("UI Toolkit or safe existing-UI migration rule is invalid") | Out-Null }
    if ($technicalText -notmatch '(?i)reusable cross-game Geurts Game Forge framework, library, or tooling component' -or $technicalText -notmatch '(?i)Geurts Game Forge Bricks is a positive example' -or $technicalText -notmatch '(?i)project-specific 2D map generator does not receive this header' -or $technicalText -notmatch '(?i)AI authorship alone is insufficient' -or $technicalText -notmatch '(?i)third-party packages, vendored code, generated code, read-only files' -or $technicalText -notmatch '(?i)format/tooling surface that forbids the header') { $technicalPolicyFailures.Add("compliance-header reusable-framework scope is incomplete") | Out-Null }
    Add-Check "Conditional technical policies" ($technicalPolicyFailures.Count -eq 0) $(if ($technicalPolicyFailures.Count) { $technicalPolicyFailures -join "; " } else { "UI Toolkit, optional dependencies, player debug access, and compliance-header scope are explicit and safe." })

    $gddTechniqueText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md"))
    $gddOwnerRow = [regex]::Match($manifestText, '(?m)^\| Project-specific design-document discovery and maintenance boundary \| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique\.md` \| (?<When>[^|]+) \|\r?$')
    $gddAuthorityValid = $gddOwnerRow.Success -and $gddOwnerRow.Groups["When"].Value -match '(?i)player-facing work' -and $gddTechniqueText -match '(?i)load every relevant document identified by the project.?s current `GameDesignManifest\.md`' -and $gddTechniqueText -match '(?i)stop and ask' -and $gddTechniqueText -match '(?i)establish or change player-facing design intent' -and $gddTechniqueText -match '(?i)reversible technical detail' -and $gddTechniqueText -match '(?i)does not create, alter, or overwrite design intent'
    Add-Check "Project GDD authority" $gddAuthorityValid "The package manifest selects the GDD Technique; the project GameDesignManifest selects relevant project facts; missing design intent is asked, never invented."

    $completeCopyBoundaryValid = $gfiTechniqueText.Contains("<ProjectRoot>/GeurtsGameForgeDocumentation/") -and $gfiTechniqueText -match '(?i)every Git-tracked source path' -and $gfiTechniqueText -match '(?i)selected Git tree' -and $gfiTechniqueText -match '(?i)complete content (?:container|set)' -and $gfiTechniqueText.Contains(".git/")
    $entryAndGddBoundaryValid = $gfiTechniqueText.Contains("<ProjectRoot>/Docs/GameDesign/") -and $gfiTechniqueText.Contains("GeurtsGameForgeDocumentation/AGENTS.md") -and $gfiTechniqueText.Contains("<ProjectRoot>/AGENTS.md")
    $gfiPreservationRule = [regex]::Match($gfiTechniqueText, '(?is)Game Forge Intelligence must not(?<Body>.*?)(?:\.\s|\z)')
    $gfiPreservationBody = if ($gfiPreservationRule.Success) { $gfiPreservationRule.Groups["Body"].Value } else { "" }
    $userContentBoundaryValid = $gfiPreservationRule.Success -and $gfiPreservationBody -match '(?i)silently overwrite' -and $gfiPreservationBody -match '(?i)user-authored project files' -and $gfiPreservationBody -match '(?i)native-entry content' -and $gfiPreservationBody -match '(?i)GDD content' -and $gfiPreservationBody -match '(?i)invent project design facts' -and $gfiPreservationBody -match '(?i)alter a differing project-root `\.gitignore`' -and $gfiTechniqueText -match '(?i)separately authorized GDD maintainer may update only the bounded managed manifest index' -and $gfiTechniqueText -match '(?i)(?:defer|delegat)[^\r\n]{0,120}(?:manifest-selected|subject owner)'
    $existingTreeSafetyValid = $gfiTechniqueText -match '(?i)recognized prior package version.*migrated only through the plugin-owned transaction' -and $gfiTechniqueText -match '(?i)detect unexpected local drift and unrecognized or user-authored content' -and $gfiTechniqueText -match '(?i)preserve that content exactly' -and $gfiTechniqueText -match '(?i)report a conflict' -and $gfiTechniqueText -match '(?i)retain the validated candidate and last-valid evidence in plugin-owned state' -and $gfiTechniqueText -match '(?i)do not treat or activate the drifted tree as documentation-source authority' -and $gfiTechniqueText -match '(?i)safely reconciled or the user explicitly authorizes'
    $gddBoundaryValid = $completeCopyBoundaryValid -and $entryAndGddBoundaryValid -and $userContentBoundaryValid
    Add-Check "Documentation boundaries" $gddBoundaryValid "The complete Git-tracked package, GDD domain, copied AGENTS entry, user-owned project shim, and clone metadata remain distinct."
    Add-Check "Existing documentation-tree preservation" $existingTreeSafetyValid "Only recognized prior-package migration may replace an existing tree through the plugin transaction; drift and unrecognized/user content remain preserved, conflicted, evidenced, and inactive until reconciled or explicitly authorized."

    $draftStatusValid = @(
        @{ Path = "GeurtsTechniques/GeurtsFolderStructureTechnique.md"; Registry = '(?m)^\| `GeurtsTechniques/GeurtsFolderStructureTechnique\.md` \| 0\.8\.0 \| Normative ' },
        @{ Path = "GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md"; Registry = '(?m)^\| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique\.md` \| 0\.8\.0 \| Normative ' }
    ) | ForEach-Object { ([System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $_.Path)) -match '(?im)^\*\*Status:\*\* Draft normative technique\s*$') -and ($manifestText -match $_.Registry) } | Where-Object { -not $_ } | Measure-Object | Select-Object -ExpandProperty Count
    Add-Check "Normative status and registry roles" ($draftStatusValid -eq 0) "Folder and GDD techniques consistently declare Draft normative status and normative manifest roles."

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
        $containerGuardInvalid = $toolText.IndexOf("Assert-UnityProjectRoot", [System.StringComparison]::Ordinal) -lt 0 -or $toolText.IndexOf("documentation source or synchronized documentation container", [System.StringComparison]::OrdinalIgnoreCase) -lt 0
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
    $usageDocuments = @("README.md", "AI_READ_FIRST.md", "AGENTS.md", "GeurtsTechniqueManifest.md", "Migrations/v0.9.0.md")
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
        if ($surface.IndexOf("-IncludeGameDesignScaffolding", [System.StringComparison]::Ordinal) -lt 0 -or $surface.IndexOf("-UpdateGameDesignManifest", [System.StringComparison]::Ordinal) -lt 0 -or $surface -notmatch '(?i)(?:native-entry|native entries).*?(?:does not implicitly create|never creates|handles native entries only|changes native entries only).*?Docs/GameDesign') { $usageFailures.Add("manager scope is not documented as native-only with two positive GDD opt-ins") | Out-Null }
    }
    if ($managerText.IndexOf("[switch]`$IncludeGameDesignScaffolding", [System.StringComparison]::Ordinal) -lt 0 -or $managerText.IndexOf("[switch]`$UpdateGameDesignManifest", [System.StringComparison]::Ordinal) -lt 0 -or $batchText.IndexOf("-IncludeGameDesignScaffolding", [System.StringComparison]::Ordinal) -lt 0 -or $batchText.IndexOf("-UpdateGameDesignManifest", [System.StringComparison]::Ordinal) -lt 0) { $usageFailures.Add("manager or launcher does not expose both positive GDD opt-ins") | Out-Null }
    Add-Check "Tool invocation and scope documentation" ($usageFailures.Count -eq 0) $(if ($usageFailures.Count) { $usageFailures -join "; " } else { "Every current/v0.9 tool example passes explicit -ProjectRoot; native-only default, create-missing GDD scaffolding, and independent manifest maintenance match the CLI." })

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
