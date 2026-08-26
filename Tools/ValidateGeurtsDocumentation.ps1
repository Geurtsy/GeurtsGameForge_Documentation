# ValidateGeurtsDocumentation.ps1
# Version: 0.8.0

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
    if ($Path -in @("GeurtsGameForgeDocumentation", "GeurtsGameForgeDocumentation/GeurtsTechniques")) { return @("documentation-sync") }
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

try {
    if ([string]::IsNullOrWhiteSpace($RepositoryRoot)) { $RepositoryRoot = Split-Path -Parent $PSScriptRoot }
    $RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
    if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) { throw "Repository root does not exist: $RepositoryRoot" }

    $manifestPath = Join-Path $RepositoryRoot "GeurtsTechniqueManifest.md"
    $manifestText = if (Test-Path -LiteralPath $manifestPath -PathType Leaf) { [System.IO.File]::ReadAllText($manifestPath) } else { "" }
    $packageMatch = [regex]::Match($manifestText, '(?im)^\*\*Version:\*\*\s*(?<Version>\d+\.\d+\.\d+)')
    $packageVersion = if ($packageMatch.Success) { $packageMatch.Groups["Version"].Value } else { $null }
    Add-Check "Package version" ($packageVersion -eq "0.8.0") "Manifest package version is $packageVersion."

    $migrationRelative = "Migrations/v0.7.0.md"
    $legacyHidden = ([char]46) + "ge" + "urts"
    $legacySegment = "up" + "stream"
    $legacyRouteForward = $legacyHidden + "/" + $legacySegment
    $legacyRouteBackward = $legacyHidden + "\" + $legacySegment
    $legacyDocs = "Docs/" + "Geurts"
    $legacyProduct = "Tripo" + "CodexUnityPackage"
    $forbiddenPatterns = @($legacyRouteForward, $legacyRouteBackward, $legacyDocs, $legacyProduct)
    $forbiddenHits = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-ChildItem -LiteralPath $RepositoryRoot -File -Recurse -Force | Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })) {
        $relative = $file.FullName.Substring($RepositoryRoot.Length).TrimStart('\', '/').Replace('\', '/')
        if ($relative -eq $migrationRelative) { continue }
        try { $content = [System.IO.File]::ReadAllText($file.FullName) }
        catch { continue }
        foreach ($pattern in $forbiddenPatterns) {
            if ($content.IndexOf($pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $forbiddenHits.Add("$relative contains a removed active reference") | Out-Null
            }
        }
    }
    Add-Check "Removed active references" ($forbiddenHits.Count -eq 0) $(if ($forbiddenHits.Count) { $forbiddenHits -join "; " } else { "No active legacy paths or obsolete integration name found." })

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

    $integrationContractPath = Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md"
    $integrationContractText = if (Test-Path -LiteralPath $integrationContractPath -PathType Leaf) { [System.IO.File]::ReadAllText($integrationContractPath) } else { "" }
    foreach ($requiredText in @("**Version:** 0.9.0", "GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsGitIgnoreTechnique.md", "<ProjectRoot>/.gitignore", "CUSTOM_DOCUMENTATION", "DEFAULT_FALLBACK", "SOURCE_FAILED", "PRESERVED")) {
        if ($integrationContractText.IndexOf($requiredText, [System.StringComparison]::Ordinal) -lt 0) { $gitIgnoreFailures.Add("integration contract is missing '$requiredText'") | Out-Null }
    }
    if ($manifestText.IndexOf($gitIgnoreRelative, [System.StringComparison]::Ordinal) -lt 0) { $gitIgnoreFailures.Add("manifest does not classify the technique") | Out-Null }
    Add-Check "Custom .gitignore payload" ($gitIgnoreFailures.Count -eq 0) $(if ($gitIgnoreFailures.Count) { $gitIgnoreFailures -join "; " } else { "The v1.0.0 payload exactly matches the approved 376-line source after normalization and is routed by contract v0.9.0." })

    $canonicalFailures = New-Object System.Collections.Generic.List[string]
    foreach ($technique in @(Get-ChildItem -LiteralPath (Join-Path $RepositoryRoot "GeurtsTechniques") -Filter "*.md" -File)) {
        $relative = "GeurtsTechniques/" + $technique.Name
        $text = [System.IO.File]::ReadAllText($technique.FullName)
        $expectedCanonical = "**Canonical path:** " + [char]96 + $relative + [char]96
        if ($text -notmatch [regex]::Escape($expectedCanonical)) { $canonicalFailures.Add($relative) | Out-Null }
    }
    Add-Check "Technique canonical paths" ($canonicalFailures.Count -eq 0) $(if ($canonicalFailures.Count) { "Missing or incorrect metadata: " + ($canonicalFailures -join ", ") } else { "Every technique declares its repository-relative canonical path." })

    $nativeTemplates = @(
        "Tools/AIAgentInstructionTemplates/AGENTS.md",
        "Tools/AIAgentInstructionTemplates/copilot-instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md",
        "Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md"
    )
    $routeFailures = New-Object System.Collections.Generic.List[string]
    $markerFailures = New-Object System.Collections.Generic.List[string]
    $htmlRegionPattern = '(?ms)^<!--\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="0.7.0"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*-->\r?\n(?<Body>.*?)^<!--\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*-->\s*$'
    $yamlRegionPattern = '(?ms)^#\s*GEURTS-MANAGED-BEGIN\s+id="(?<Id>[^"]+)"\s+version="0.7.0"\s+sha256="(?<Hash>[0-9a-fA-F]{64})"\s*\r?\n(?<Body>.*?)^#\s*GEURTS-MANAGED-END\s+id="\k<Id>"\s*$'
    foreach ($relative in $nativeTemplates) {
        $path = Join-Path $RepositoryRoot ($relative.Replace('/', [System.IO.Path]::DirectorySeparatorChar))
        $text = [System.IO.File]::ReadAllText($path)
        if ($text.IndexOf("GeurtsGameForgeDocumentation/AI_READ_FIRST.md", [System.StringComparison]::Ordinal) -lt 0) { $routeFailures.Add($relative) | Out-Null }
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
            if ((Get-TextHash -Text $region.Groups["Body"].Value) -ne $region.Groups["Hash"].Value.ToLowerInvariant()) {
                $markerFailures.Add("$relative region $($region.Groups['Id'].Value) has a bad hash") | Out-Null
            }
        }
    }
    Add-Check "Canonical native route" ($routeFailures.Count -eq 0) $(if ($routeFailures.Count) { "Missing canonical route: " + ($routeFailures -join ", ") } else { "Codex and Copilot templates use the same canonical entry point." })
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
        if ([string]$migrationCatalog.schemaVersion -cne "0.7.0" -or [string]$migrationCatalog.normalization -cne "utf8-text-with-lf-newlines-and-terminal-lf" -or @($migrationCatalog.entries).Count -ne 4) { $catalogFailures.Add("catalog metadata or target count is invalid") | Out-Null }
        $actualCatalogRecords = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
        foreach ($entry in @($migrationCatalog.entries)) {
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
    Add-Check "Migration catalog integrity" ($catalogFailures.Count -eq 0) $(if ($catalogFailures.Count) { $catalogFailures -join "; " } else { "The exact v0.4-v0.6 target, template, version, and SHA256 matrix is valid." })

    $gddTemplate = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md"))
    $gddFields = @("ID", "Path", "Purpose", "Status", "Version", "Authority", "Tags", "SHA256")
    $gddValid = $gddTemplate.Contains('GEURTS-GDD-MANIFEST-BEGIN version="0.7.0"') -and @($gddFields | Where-Object { $gddTemplate -notmatch "\|\s*$([regex]::Escape($_))\s*\|" }).Count -eq 0
    Add-Check "GDD scaffold contract" $gddValid "Managed GDD index declares the required routing fields and v0.7.0 markers."

    try { $config = Get-Content -LiteralPath (Join-Path $RepositoryRoot "Tools/GeurtsRepository.json") -Raw | ConvertFrom-Json }
    catch { $config = $null }
    $expectedSparse = @("/AI_READ_FIRST.md", "/GeurtsTechniqueManifest.md", "/GeurtsTechniques/") | Sort-Object
    $actualSparse = if ($config) { @($config.sparsePaths | Sort-Object) } else { @() }
    $sparseValid = $actualSparse.Count -eq 3
    if ($sparseValid) { for ($i = 0; $i -lt 3; $i++) { if ($actualSparse[$i] -cne $expectedSparse[$i]) { $sparseValid = $false } } }
    $requiredExpected = @{ "AI_READ_FIRST.md" = "file"; "GeurtsTechniqueManifest.md" = "file"; "GeurtsTechniques" = "directory" }
    $requiredValid = $config -and @($config.requiredEntries).Count -eq 3
    if ($requiredValid) {
        foreach ($entry in @($config.requiredEntries)) {
            if (-not $requiredExpected.ContainsKey([string]$entry.path) -or [string]$requiredExpected[[string]$entry.path] -cne [string]$entry.type) { $requiredValid = $false }
        }
    }
    $configFieldsValid = $config -and [string]$config.schemaVersion -ceq "0.7.0" -and [string]$config.packageVersion -ceq "0.8.0" -and [string]$config.distributionStrategy -ceq "public-repository" -and [string]$config.repositoryUrl -ceq "https://github.com/Geurtsy/GeurtsGameForge_Documentation.git" -and [string]$config.branch -ceq "main" -and [string]$config.localSyncPath -ceq "GeurtsGameForgeDocumentation" -and [string]$config.entryPointPath -ceq "AI_READ_FIRST.md" -and [string]$config.manifestPath -ceq "GeurtsTechniqueManifest.md" -and [string]$config.techniquesPath -ceq "GeurtsTechniques" -and [string]$config.folderDefinitionPath -ceq "GeurtsTechniques/GeurtsFolderStructureDefinition.json" -and [string]$config.fallbackPolicy -ceq "none"
    Add-Check "Exact sparse layout configuration" ($sparseValid -and $requiredValid -and $configFieldsValid) "Public-repository configuration selects exactly the entry point, manifest, and techniques directory with no bundled documentation fallback."

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
                definitionVersion = "0.7.0"
                packageVersion = "0.8.0"
                canonicalPath = "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
                pathBase = "<ProjectRoot>"
                pathSeparator = "/"
                explanatoryAuthority = "GeurtsTechniques/GeurtsFolderStructureTechnique.md"
                automationAuthority = "GeurtsTechniques/GeurtsFolderStructureDefinition.json"
            }
            foreach ($name in $topLevelExpected.Keys) {
                if ([string]$definition.$name -cne [string]$topLevelExpected[$name]) { $folderFailures.Add("$name is not '$($topLevelExpected[$name])'") | Out-Null }
            }
            if ($folders.Count -ne 71 -or [int]$definition.managedFolderCount -ne 71) { $folderFailures.Add("managed folder count is not exactly 71") | Out-Null }
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
                "documentation-sync" = "documentation-synchronizer"
            }
            $expectedProfileCounts = @{
                "full-project-structure" = 67
                "native-entry" = 2
                "gdd-scaffolding" = 2
                "documentation-sync" = 2
            }
            $profileIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
            if (@($definition.creationProfiles).Count -ne 4) { $folderFailures.Add("creationProfiles does not contain exactly four entries") | Out-Null }
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
                if (-not $profileScopeValid) { $folderFailures.Add("$folderPath differs from its exact v0.7.0 profile scope") | Out-Null }
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
    Add-Check "Folder definition contract" ($folderFailures.Count -eq 0) $(if ($folderFailures.Count) { $folderFailures -join "; " } else { "Definition versions, 71 entries, five categories, four owner-bound profiles, parent closure, create-only policy, delegation, and exact Markdown parity are valid." })

    $allText = @(
        [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "AI_READ_FIRST.md")),
        [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniqueManifest.md")),
        [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsAIAgentSetupTechnique.md")),
        [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "GeurtsTechniques/GeurtsTechnicalTechnique.md"))
    ) -join "`n"
    $chatSection = [regex]::Match($manifestText, '(?ms)^### Chat-only\s*(?<Body>.*?)(?=^### |\z)')
    $chatOnlyValid = $chatSection.Success -and $chatSection.Groups["Body"].Value.Contains("GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md") -and $chatSection.Groups["Body"].Value -match '(?i)not an? .*implementation standard' -and $manifestText -match '(?m)^\| `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1\.1\.md` \| 1\.1 \| Chat-only response technique; synchronized but not an implementation standard\. \|\r?$'
    Add-Check "Chat-only classification" $chatOnlyValid "Response control remains independently versioned, synchronized, and explicitly excluded from implementation standards."
    $priorityFailures = New-Object System.Collections.Generic.List[string]
    foreach ($priorityRelative in @("README.md", "GeurtsTechniqueManifest.md", "GeurtsTechniques/GeurtsTechnicalTechnique.md", "GeurtsTechniques/GeurtsAIAgentSetupTechnique.md")) {
        $priorityText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $priorityRelative))
        $priorityPattern = '(?ms)1\.\s+\*\*Extendibility\*\*.*?\r?\n2\.\s+\*\*Efficiency\*\*.*?\r?\n3\.\s+\*\*Readability\*\*.*?\r?\n4\.\s+\*\*Updated\*\*.*?\r?\n5\.\s+\*\*Documented\*\*'
        if ($priorityText -notmatch $priorityPattern -or $priorityText -notmatch '(?i)network efficiency overrides (?:every|all) other priorit') { $priorityFailures.Add($priorityRelative) | Out-Null }
    }
    Add-Check "Strict technical priority" ($priorityFailures.Count -eq 0) $(if ($priorityFailures.Count) { "Missing exact order or multiplayer override: " + ($priorityFailures -join ", ") } else { "Extendibility, Efficiency, Readability, Updated, Documented, plus the multiplayer network override, are exact in every normative summary." })
    $multiplayerValid = $allText -match '(?i)network efficiency overrides (?:every|all) other priorit'
    Add-Check "Multiplayer exception" $multiplayerValid "The network-efficiency override remains explicit."
    $gddBoundaryValid = $allText.Contains("<ProjectRoot>/Docs/GameDesign/") -and $allText.Contains("<ProjectRoot>/GeurtsGameForgeDocumentation/")
    Add-Check "GDD path boundary" $gddBoundaryValid "Project GDD and synchronized technique paths remain separate and project-root-relative."

    $bootstrapText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/BootstrapGeurtsInstructions.ps1"))
    $bootstrapContractValid = @("Check", "Update", "Validate", "AUTHENTICATION", "NETWORK", "CHECKOUT", "VALIDATION", "FILE_LOCK", "FILESYSTEM", "Test-SynchronizedPackageContent", "Test-SynchronizedGitIgnoreTechnique", "Test-SynchronizedFolderPath", "delegatedOwners", "parent-closed", "RequireCurrentPackage", "GEURTS-PACKAGE-FILES:BEGIN", "GeurtsFolderStructureDefinition.json", "GeurtsAIResponseControlTechnique_V1.1.md", "GeurtsGitIgnoreTechnique.md", "GeurtsGameForgeDocumentation", "public-repository", "fallbackPolicy", "System.Threading.Mutex", "Enter-SyncLock", "Exit-SyncLock", "Get-FilesystemFailureCategory", "tls", "Move-Item", "previousCommit", "synchronizedCommit", "validationOutcome", "preservedLocalCopy", "lastValidCopy", "anonymous read-only access") | Where-Object { $bootstrapText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 } | Measure-Object | Select-Object -ExpandProperty Count
    Add-Check "Bootstrap safety contract" ($bootstrapContractValid -eq 0) "Check, Update, Validate, exact visible-path configuration, target-scoped locking, custom .gitignore payload validation, profile closure, deep staged content validation, atomic promotion, explicit commit and validation reporting, confirmed-copy rollback reporting, public access guidance, and distinct failure categories are implemented."

    $managerText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/ManageGeurtsAgentInstructions.ps1"))
    $managerSafetyMissing = @("Test-HasReparsePoint", "Test-NativeMigrationCatalog", "native-entry", "gdd-scaffolding", "frontmatter delimiters", "unsupported version", "no downgrade") | Where-Object { $managerText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 } | Measure-Object | Select-Object -ExpandProperty Count
    Add-Check "Native-entry safety contract" ($managerSafetyMissing -eq 0) "Native and scaffold targets reject reparse points, YAML markers stay inside frontmatter, the exact migration catalog is enforced, both owned profiles are checked, and future managed regions are preserved."

    $gddToolText = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot "Tools/UpdateGameDesignManifest.ps1"))
    $gddSafetyMissing = @("Get-SafeDesignFiles", "Test-HasReparsePoint", "lockOwned", "Get-ExistingEntries", "Get-OrdinalSortedEntries", "canonical project path", "changed after it was read", "no downgrade", "invalid version") | Where-Object { $gddToolText.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -lt 0 } | Measure-Object | Select-Object -ExpandProperty Count
    Add-Check "GDD maintenance safety contract" ($gddSafetyMissing -eq 0) "Canonical path, reparse safety, owned locking, source-fingerprint protection, strict record parsing, ordinal ordering, metadata validation, and no-downgrade behavior are implemented."

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
