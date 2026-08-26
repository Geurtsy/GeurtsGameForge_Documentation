# CreateGeurtsFolderStructure.ps1
# Version: 0.8.0

[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$DefinitionPath,
    [string]$Profile = "full-project-structure",
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$results = New-Object System.Collections.Generic.List[object]

function Get-FullPath([string]$Path, [string]$BasePath) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-IsContainedPath([string]$Candidate, [string]$Root) {
    $rootWithSeparator = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-DefinitionPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    if ([System.IO.Path]::IsPathRooted($Path)) { return $false }
    if ($Path.Contains("\")) { return $false }
    if ($Path.StartsWith("/") -or $Path.EndsWith("/")) { return $false }

    $segments = $Path.Split('/')
    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq "." -or $segment -eq "..") { return $false }
        if ($segment.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) { return $false }
        if ($segment.EndsWith(".") -or $segment.EndsWith(" ")) { return $false }
    }

    return $true
}

function Test-HasReparsePoint([string]$Candidate, [string]$Root) {
    $current = $Candidate
    while (Test-IsContainedPath -Candidate $current -Root $Root) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                return $true
            }
        }

        $parent = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $current -or $parent -eq $Root) { break }
        $current = $parent
    }

    return $false
}

function Get-ExpectedProfilesForPath([string]$Path) {
    if ($Path -in @(".github", ".github/instructions")) { return @("native-entry") }
    if ($Path -in @("GeurtsGameForgeDocumentation", "GeurtsGameForgeDocumentation/GeurtsTechniques")) { return @("documentation-sync") }
    if ($Path -in @("Docs", "Docs/GameDesign")) { return @("full-project-structure", "gdd-scaffolding") }
    return @("full-project-structure")
}

function Add-Result([string]$Status, [string]$Path, [string]$Message) {
    $results.Add([pscustomobject]@{
        status = $Status
        path = $Path
        message = $Message
    }) | Out-Null

    if ($OutputFormat -eq "Text") {
        Write-Host ("{0}: {1}{2}" -f $Status, $Path, $(if ($Message) { " - $Message" } else { "" }))
    }
}

try {
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Split-Path -Parent $PSScriptRoot
    }
    $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
        throw "Project root does not exist: $ProjectRoot"
    }

    if ([string]::IsNullOrWhiteSpace($DefinitionPath)) {
        $candidates = @(
            (Join-Path $ProjectRoot "GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureDefinition.json"),
            (Join-Path $ProjectRoot "GeurtsTechniques/GeurtsFolderStructureDefinition.json"),
            (Join-Path (Split-Path -Parent $PSScriptRoot) "GeurtsTechniques/GeurtsFolderStructureDefinition.json")
        )
        $DefinitionPath = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    }
    else {
        $DefinitionPath = Get-FullPath -Path $DefinitionPath -BasePath $ProjectRoot
    }

    if ([string]::IsNullOrWhiteSpace($DefinitionPath) -or -not (Test-Path -LiteralPath $DefinitionPath -PathType Leaf)) {
        throw "Folder definition not found. Synchronize the documentation or provide -DefinitionPath."
    }

    try {
        $definition = Get-Content -LiteralPath $DefinitionPath -Raw | ConvertFrom-Json
    }
    catch {
        throw "Folder definition is not valid JSON: $($_.Exception.Message)"
    }

    if ([string]$definition.schemaVersion -ne "1.0.0") { throw "Unsupported folder-definition schemaVersion '$($definition.schemaVersion)'." }
    if ([string]$definition.definitionVersion -ne "0.7.0" -or [string]$definition.packageVersion -ne "0.8.0") {
        throw "Folder definition version must be 0.7.0 and package version must be 0.8.0."
    }
    if ([string]$definition.canonicalPath -ne "GeurtsTechniques/GeurtsFolderStructureDefinition.json" -or [string]$definition.pathBase -ne "<ProjectRoot>" -or [string]$definition.pathSeparator -ne "/" -or [string]$definition.explanatoryAuthority -ne "GeurtsTechniques/GeurtsFolderStructureTechnique.md" -or [string]$definition.automationAuthority -ne "GeurtsTechniques/GeurtsFolderStructureDefinition.json") {
        throw "Folder definition declares an unsupported canonical path or path-base contract."
    }
    if (-not $definition.managedFolders -or @($definition.managedFolders).Count -ne 71 -or [int]$definition.managedFolderCount -ne 71 -or [int]$definition.projectStructureFolderCount -ne 67) {
        throw "The v0.7.0 folder definition must declare exactly 71 managed folders and 67 project-structure folders."
    }

    $allowedCategories = @("unity-project", "generated-content", "tooling", "documentation", "third-party-content")
    $declaredCategories = @($definition.contentCategories | Sort-Object)
    $expectedCategories = @($allowedCategories | Sort-Object)
    if ($declaredCategories.Count -ne $expectedCategories.Count) { throw "Folder definition must declare exactly five content categories." }
    for ($categoryIndex = 0; $categoryIndex -lt $expectedCategories.Count; $categoryIndex++) {
        if ($declaredCategories[$categoryIndex] -cne $expectedCategories[$categoryIndex]) { throw "Folder definition contentCategories does not match the supported category set." }
    }

    $expectedProfileOwners = @{
        "full-project-structure" = "folder-structure-tool"
        "native-entry" = "native-entry-manager"
        "gdd-scaffolding" = "native-entry-manager"
        "documentation-sync" = "documentation-synchronizer"
    }
    if (@($definition.creationProfiles).Count -ne $expectedProfileOwners.Count) { throw "The v0.7.0 definition must declare exactly four creation profiles." }
    $profileOwners = @{}
    foreach ($declaredProfile in @($definition.creationProfiles)) {
        $profileId = [string]$declaredProfile.id
        $profileOwner = [string]$declaredProfile.owner
        if ([string]::IsNullOrWhiteSpace($profileId) -or [string]::IsNullOrWhiteSpace($profileOwner) -or [string]::IsNullOrWhiteSpace([string]$declaredProfile.purpose)) {
            throw "Every creation profile must declare id, owner, and purpose."
        }
        if ($profileOwners.ContainsKey($profileId)) { throw "Duplicate creation profile '$profileId'." }
        if (-not $expectedProfileOwners.ContainsKey($profileId) -or [string]$expectedProfileOwners[$profileId] -cne $profileOwner) {
            throw "Creation profile '$profileId' has an unsupported owner or identifier."
        }
        $profileOwners[$profileId] = $profileOwner
    }
    foreach ($expectedProfileId in $expectedProfileOwners.Keys) {
        if (-not $profileOwners.ContainsKey($expectedProfileId)) { throw "Missing creation profile '$expectedProfileId'." }
    }
    if (-not $profileOwners.ContainsKey($Profile)) { throw "Unknown creation profile '$Profile'." }
    $callerOwner = "folder-structure-tool"
    if ([string]$profileOwners[$Profile] -cne $callerOwner) {
        throw "Creation profile '$Profile' is owned by '$($profileOwners[$Profile])' and cannot be run by '$callerOwner'."
    }

    $knownPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $knownCanonicalPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    $validated = New-Object System.Collections.Generic.List[object]

    foreach ($folder in @($definition.managedFolders)) {
        $relativePath = [string]$folder.path
        if (-not (Test-DefinitionPath -Path $relativePath)) {
            throw "Unsafe or invalid folder path in definition: '$relativePath'."
        }
        $addedCanonicalPath = $knownCanonicalPaths.Add($relativePath)
        $addedInsensitivePath = $knownPaths.Add($relativePath)
        if (-not $addedCanonicalPath -or -not $addedInsensitivePath) {
            throw "Duplicate folder path in definition: '$relativePath'."
        }
        if ($folder.requirement -notin @("required", "optional")) {
            throw "Folder '$relativePath' must declare requirement as required or optional."
        }
        if ([string]::IsNullOrWhiteSpace([string]$folder.purpose)) {
            throw "Folder '$relativePath' is missing purpose."
        }
        if ([string]::IsNullOrWhiteSpace([string]$folder.contentCategory)) {
            throw "Folder '$relativePath' is missing contentCategory."
        }
        if ([string]$folder.contentCategory -notin $allowedCategories) {
            throw "Folder '$relativePath' has unsupported contentCategory '$($folder.contentCategory)'."
        }
        if (-not $folder.automation) {
            throw "Folder '$relativePath' is missing automation policy."
        }
        if ($folder.automation.mayCreate -isnot [bool] -or $folder.automation.mayRemove -isnot [bool]) {
            throw "Folder '$relativePath' must declare Boolean mayCreate and mayRemove values."
        }
        if ($folder.automation.mayCreate -ne $true -or $folder.automation.mayRemove -ne $false) {
            throw "Folder '$relativePath' must permit creation and must not permit automatic removal."
        }

        $profiles = @($folder.automation.creationProfiles)
        $expectedFolderProfiles = @(Get-ExpectedProfilesForPath -Path $relativePath | Sort-Object)
        $actualFolderProfiles = @($profiles | ForEach-Object { [string]$_ } | Sort-Object)
        if ($actualFolderProfiles.Count -ne $expectedFolderProfiles.Count) {
            throw "Folder '$relativePath' does not declare its exact v0.7.0 creation-profile scope."
        }
        for ($profileIndex = 0; $profileIndex -lt $expectedFolderProfiles.Count; $profileIndex++) {
            if ($actualFolderProfiles[$profileIndex] -cne $expectedFolderProfiles[$profileIndex]) {
                throw "Folder '$relativePath' does not declare its exact v0.7.0 creation-profile scope."
            }
        }
        if ([string]::IsNullOrWhiteSpace([string]$folder.automation.owner)) {
            throw "Folder '$relativePath' is missing its automation owner."
        }
        $delegatedOwners = @{}
        if ($folder.automation.PSObject.Properties["delegatedOwners"]) {
            foreach ($delegation in @($folder.automation.delegatedOwners.PSObject.Properties)) {
                $delegatedProfile = [string]$delegation.Name
                $delegatedOwner = [string]$delegation.Value
                if (-not $profileOwners.ContainsKey($delegatedProfile)) {
                    throw "Folder '$relativePath' delegates unknown creation profile '$delegatedProfile'."
                }
                if ($profiles -notcontains $delegatedProfile) {
                    throw "Folder '$relativePath' delegates profile '$delegatedProfile' without selecting it."
                }
                if ([string]$profileOwners[$delegatedProfile] -cne $delegatedOwner) {
                    throw "Folder '$relativePath' delegates profile '$delegatedProfile' to an owner that does not match the profile owner."
                }
                $delegatedOwners[$delegatedProfile] = $delegatedOwner
            }
        }
        if ($relativePath -in @("Docs", "Docs/GameDesign")) {
            if ($delegatedOwners.Count -ne 1 -or -not $delegatedOwners.ContainsKey("gdd-scaffolding") -or [string]$delegatedOwners["gdd-scaffolding"] -cne "native-entry-manager") {
                throw "Folder '$relativePath' must contain only the gdd-scaffolding delegation to native-entry-manager."
            }
        }
        elseif ($delegatedOwners.Count -ne 0) {
            throw "Folder '$relativePath' contains an unauthorized delegated owner."
        }
        foreach ($declaredProfileId in $profiles) {
            if (-not $profileOwners.ContainsKey([string]$declaredProfileId)) { throw "Folder '$relativePath' references unknown creation profile '$declaredProfileId'." }
            $expectedOwner = [string]$profileOwners[[string]$declaredProfileId]
            $primaryOwnerMatches = ([string]$folder.automation.owner -ceq $expectedOwner)
            $delegatedOwnerMatches = $delegatedOwners.ContainsKey([string]$declaredProfileId) -and ([string]$delegatedOwners[[string]$declaredProfileId] -ceq $expectedOwner)
            if (-not $primaryOwnerMatches -and -not $delegatedOwnerMatches) {
                throw "Folder '$relativePath' is not owned or explicitly delegated for creation profile '$declaredProfileId'."
            }
        }
        $mayCreate = ($folder.automation.mayCreate -eq $true)
        $selected = $mayCreate -and (@($profiles | Where-Object { $_ -eq $Profile }).Count -gt 0)
        $targetPath = Get-FullPath -Path ($relativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)) -BasePath $ProjectRoot
        if (-not (Test-IsContainedPath -Candidate $targetPath -Root $ProjectRoot)) {
            throw "Folder path escapes the project root: '$relativePath'."
        }

        $validated.Add([pscustomobject]@{
            RelativePath = $relativePath
            Parent = [string]$folder.parent
            TargetPath = $targetPath
            Selected = $selected
            Depth = $relativePath.Split('/').Count
        }) | Out-Null
    }

    foreach ($folder in $validated) {
        if (-not [string]::IsNullOrWhiteSpace($folder.Parent)) {
            if (-not $knownPaths.Contains($folder.Parent)) {
                throw "Folder '$($folder.RelativePath)' references missing parent '$($folder.Parent)'."
            }
            $expectedParent = $folder.RelativePath.Substring(0, $folder.RelativePath.LastIndexOf('/'))
            if ($folder.Parent -cne $expectedParent) {
                throw "Folder '$($folder.RelativePath)' has parent '$($folder.Parent)' but expected '$expectedParent'."
            }
        }
        elseif ($folder.RelativePath.Contains('/')) {
            throw "Folder '$($folder.RelativePath)' must declare its parent."
        }
    }

    $techniquePath = Join-Path (Split-Path -Parent $DefinitionPath) "GeurtsFolderStructureTechnique.md"
    if (-not (Test-Path -LiteralPath $techniquePath -PathType Leaf)) {
        throw "The explanatory folder authority is missing beside the definition: '$techniquePath'."
    }
    $techniqueText = [System.IO.File]::ReadAllText($techniquePath)
    if ($techniqueText -notmatch '(?im)^\*\*Version:\*\*\s*0\.7\.0\s*$' -or $techniqueText -notmatch '(?m)^\*\*Canonical path:\*\* `GeurtsTechniques/GeurtsFolderStructureTechnique\.md`\s*$') {
        throw "The explanatory folder authority does not declare the v0.7.0 canonical metadata."
    }
    $registryMatch = [regex]::Match($techniqueText, '(?ms)<!-- GEURTS-FOLDER-PATHS:BEGIN -->\s*```text\s*(?<Paths>.*?)\s*```\s*<!-- GEURTS-FOLDER-PATHS:END -->')
    if (-not $registryMatch.Success -or [regex]::Matches($techniqueText, 'GEURTS-FOLDER-PATHS:BEGIN').Count -ne 1 -or [regex]::Matches($techniqueText, 'GEURTS-FOLDER-PATHS:END').Count -ne 1) {
        throw "The explanatory folder authority has no single valid literal path registry."
    }
    $documentedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($line in ($registryMatch.Groups["Paths"].Value -split '\r?\n')) {
        $documentedPath = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($documentedPath)) { continue }
        if (-not (Test-DefinitionPath -Path $documentedPath) -or -not $documentedPaths.Add($documentedPath)) {
            throw "The explanatory folder authority contains an invalid or duplicate path: '$documentedPath'."
        }
    }
    if ($documentedPaths.Count -ne $knownCanonicalPaths.Count) { throw "The JSON and Markdown folder path counts differ." }
    foreach ($canonicalPath in $knownCanonicalPaths) {
        if (-not $documentedPaths.Contains($canonicalPath)) { throw "The JSON path '$canonicalPath' is absent from the Markdown literal registry." }
    }
    foreach ($documentedPath in $documentedPaths) {
        if (-not $knownCanonicalPaths.Contains($documentedPath)) { throw "The Markdown path '$documentedPath' is absent from the JSON definition." }
    }

    if ([int]$definition.managedFolderCount -ne $validated.Count) {
        throw "managedFolderCount does not match the number of managed folders."
    }
    $declaredFullCount = @($definition.managedFolders | Where-Object { @($_.automation.creationProfiles) -contains "full-project-structure" }).Count
    if ([int]$definition.projectStructureFolderCount -ne $declaredFullCount -or $declaredFullCount -ne 67) {
        throw "projectStructureFolderCount must match the 67 full-project-structure entries."
    }

    $selectedFolders = @($validated | Where-Object { $_.Selected } | Sort-Object Depth, RelativePath)
    if ($selectedFolders.Count -eq 0) {
        throw "Creation profile '$Profile' does not select any folders."
    }

    $selectedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($folder in $selectedFolders) { $selectedPaths.Add($folder.RelativePath) | Out-Null }
    foreach ($folder in $selectedFolders) {
        if (-not [string]::IsNullOrWhiteSpace($folder.Parent) -and -not $selectedPaths.Contains($folder.Parent)) {
            throw "Creation profile '$Profile' is not parent-closed at '$($folder.RelativePath)'."
        }
    }

    foreach ($folder in @($validated | Where-Object { -not $_.Selected } | Sort-Object Depth, RelativePath)) {
        Add-Result -Status "Skipped" -Path $folder.RelativePath -Message "Not selected by profile '$Profile'."
    }

    # Complete validation and collision checks before creating anything.
    foreach ($folder in $selectedFolders) {
        if (Test-Path -LiteralPath $folder.TargetPath) {
            if (-not (Test-Path -LiteralPath $folder.TargetPath -PathType Container)) {
                throw "A file blocks required directory '$($folder.RelativePath)'."
            }
            if (Test-HasReparsePoint -Candidate $folder.TargetPath -Root $ProjectRoot) {
                throw "A reparse point makes folder creation unsafe at '$($folder.RelativePath)'."
            }
        }
    }

    foreach ($folder in $selectedFolders) {
        if (Test-Path -LiteralPath $folder.TargetPath -PathType Container) {
            Add-Result -Status "Exists" -Path $folder.RelativePath -Message ""
            continue
        }

        New-Item -ItemType Directory -Path $folder.TargetPath -ErrorAction Stop | Out-Null
        if (-not (Test-Path -LiteralPath $folder.TargetPath -PathType Container)) {
            throw "Directory creation did not produce '$($folder.RelativePath)'."
        }
        Add-Result -Status "Created" -Path $folder.RelativePath -Message ""
    }

    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{
            status = "OK"
            profile = $Profile
            definitionVersion = [string]$definition.definitionVersion
            packageVersion = [string]$definition.packageVersion
            definitionPath = $DefinitionPath
            projectRoot = $ProjectRoot
            results = $results.ToArray()
        } | ConvertTo-Json -Depth 6
    }
    else {
        Write-Host "Folder structure creation complete with definition $($definition.definitionVersion) for package $($definition.packageVersion). No folders were removed."
    }
    exit 0
}
catch {
    $failureStatus = if ($_.Exception.Message -match '(?i)blocks|required directory|reparse point|collision|conflict') { "Conflicted" } else { "Invalid" }
    $failurePath = "folder-definition"
    foreach ($pathPattern in @(
        '(?i)\bFolder\s+''(?<Path>[^'']+)''',
        '(?i)(?:definition:|project root:|directory|\bat|produce|authority is missing beside the definition:)\s*''(?<Path>[^'']+)''',
        '(?i)\bselects\s+''(?<Path>[^'']+)'''
    )) {
        $pathMatch = [regex]::Match($_.Exception.Message, $pathPattern)
        if ($pathMatch.Success) { $failurePath = $pathMatch.Groups["Path"].Value; break }
    }
    if ($failurePath -eq "folder-definition") {
        $profileMatch = [regex]::Match($_.Exception.Message, '(?i)(?:Creation profile|Unknown creation profile|Duplicate creation profile|Missing creation profile)\s+''(?<Profile>[^'']+)''')
        if ($profileMatch.Success) { $failurePath = $profileMatch.Groups["Profile"].Value }
    }
    Add-Result -Status $failureStatus -Path $failurePath -Message $_.Exception.Message
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{
            status = "FAILED"
            definitionVersion = $(if ($definition) { [string]$definition.definitionVersion } else { $null })
            packageVersion = $(if ($definition) { [string]$definition.packageVersion } else { $null })
            error = $_.Exception.Message
            results = $results.ToArray()
        } | ConvertTo-Json -Depth 6
    }
    else {
        Write-Host "FOLDER SETUP FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}
