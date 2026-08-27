# UpdateGameDesignManifest.ps1
# Version: 0.9.0

[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$ManifestPath,
    [string[]]$ImportedPath = @(),
    [ValidateSet("Text", "Json")]
    [string]$OutputFormat = "Text"
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$events = New-Object System.Collections.Generic.List[object]
$supportedExtension = ".md"
$manifestPattern = '(?ms)<!-- GEURTS-GDD-MANIFEST-BEGIN version="(?<Version>[^"]+)" -->\r?\n(?<Body>.*?)<!-- GEURTS-GDD-MANIFEST-END -->'
$lockStream = $null
$lockPath = $null
$lockOwned = $false

function Get-FullPath([string]$Path, [string]$BasePath) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-IsContainedPath([string]$Candidate, [string]$Root) {
    $rootWithSeparator = $Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    return $Candidate.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-UnityProjectRoot([string]$Root) {
    $toolContainer = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    if ($Root.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar).Equals($toolContainer, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Project root must not be the documentation source or synchronized documentation container: $Root"
    }
    foreach ($marker in @("Assets", "Packages", "ProjectSettings")) {
        if (-not (Test-Path -LiteralPath (Join-Path $Root $marker) -PathType Container)) {
            throw "Project root must be explicit and identify a Unity project containing Assets, Packages, and ProjectSettings: $Root"
        }
    }
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

function Get-SafeDesignFiles([string]$DesignRoot, [string]$Root) {
    $files = New-Object System.Collections.Generic.List[object]
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push($DesignRoot)
    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        foreach ($item in @(Get-ChildItem -LiteralPath $directory -Force)) {
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Game-design discovery encountered an unsafe reparse point: $($item.FullName)" }
            if ($item.PSIsContainer) {
                if ($item.Name.StartsWith(".", [System.StringComparison]::Ordinal) -or ($item.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0) { continue }
                if (-not (Test-IsContainedPath -Candidate $item.FullName -Root $Root)) { throw "Game-design discovery escaped the project root." }
                $pending.Push($item.FullName)
            }
            else { $files.Add($item) | Out-Null }
        }
    }
    return $files.ToArray()
}

function Get-StringHash([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

function Get-ByteHash([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace("-", "").ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Read-ManagedTextFile([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $offset = 0
    $encoding = $null
    if ($bytes.Length -ge 4 -and (($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) -or ($bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF))) {
        throw "Unsupported UTF-32 encoding; the manifest was preserved."
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
    catch { throw "Unsupported or invalid text encoding; the manifest was preserved." }
    return [pscustomobject]@{ Text = $text; Encoding = $encoding; ByteHash = (Get-ByteHash -Bytes $bytes) }
}

function Get-FileSha256([string]$Path) {
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Escape-MarkdownCell([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "Unprovided" }
    return $Value.Replace("\", "\\").Replace("|", "\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Split-MarkdownRow([string]$Line) {
    $trimmed = $Line.Trim()
    if (-not $trimmed.StartsWith("|") -or -not $trimmed.EndsWith("|")) { return @() }
    $text = $trimmed.Substring(1, $trimmed.Length - 2)
    $cells = New-Object System.Collections.Generic.List[string]
    $builder = New-Object System.Text.StringBuilder
    $escaped = $false
    foreach ($character in $text.ToCharArray()) {
        if ($escaped) {
            [void]$builder.Append($character)
            $escaped = $false
        }
        elseif ($character -eq '\') {
            $escaped = $true
        }
        elseif ($character -eq '|') {
            $cells.Add($builder.ToString().Trim()) | Out-Null
            [void]$builder.Clear()
        }
        else {
            [void]$builder.Append($character)
        }
    }
    if ($escaped) { [void]$builder.Append('\') }
    $cells.Add($builder.ToString().Trim()) | Out-Null
    return @($cells)
}

function Get-ExistingEntries([string]$Body) {
    $entries = New-Object System.Collections.Generic.List[object]
    $headerSeen = $false
    $separatorSeen = $false
    $expectedHeader = @("ID", "Path", "Purpose", "Status", "Version", "Authority", "Tags", "SHA256")
    foreach ($line in ($Body -split '\r?\n')) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if (-not $line.TrimStart().StartsWith("|")) { throw "Managed manifest contains a non-table line." }
        $cells = Split-MarkdownRow -Line $line
        if ($cells.Count -ne 8) { throw "Managed manifest row does not contain exactly eight fields." }
        if ($cells[0] -eq "ID") {
            if ($headerSeen -or $separatorSeen -or $entries.Count -gt 0) { throw "Managed manifest table header is duplicated or out of order." }
            for ($headerIndex = 0; $headerIndex -lt $expectedHeader.Count; $headerIndex++) {
                if ($cells[$headerIndex] -cne $expectedHeader[$headerIndex]) { throw "Managed manifest table header does not match the v0.7.0 field contract." }
            }
            $headerSeen = $true
            continue
        }
        if (@($cells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -eq 0) {
            if (-not $headerSeen -or $separatorSeen -or $entries.Count -gt 0) { throw "Managed manifest separator is duplicated or out of order." }
            $separatorSeen = $true
            continue
        }
        if (-not $headerSeen -or -not $separatorSeen) { throw "Managed manifest data appears before its header and separator." }
        $entryPath = $cells[1].Trim('`')
        if ($cells[0] -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') { throw "Managed manifest contains an invalid identifier '$($cells[0])'." }
        if ($entryPath -notmatch '^Docs/GameDesign/(?!GameDesignManifest\.md$)[^\\]+\.md$' -or $entryPath.Contains('//')) { throw "Managed manifest contains an invalid or out-of-bound path '$entryPath'." }
        foreach ($segment in $entryPath.Split('/')) {
            if ([string]::IsNullOrWhiteSpace($segment) -or $segment -in @('.', '..') -or $segment.StartsWith('.', [System.StringComparison]::Ordinal)) { throw "Managed manifest contains an unsafe or hidden path '$entryPath'." }
        }
        if (@($cells[2..6] | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) { throw "Managed manifest record '$($cells[0])' has an empty routing field." }
        if ($cells[4] -ne "Unprovided" -and $cells[4] -notmatch '^\d+\.\d+(?:\.\d+)?(?:[-+][0-9A-Za-z.-]+)?$') { throw "Managed manifest record '$($cells[0])' has an invalid version." }
        if ($cells[7] -notmatch '^[0-9a-fA-F]{64}$') { throw "Managed manifest record '$($cells[0])' has an invalid SHA256 value." }
        $entries.Add([pscustomobject]@{
            Id = $cells[0]
            Path = $entryPath
            Purpose = $cells[2]
            Status = $cells[3]
            Version = $cells[4]
            Authority = $cells[5]
            Tags = $cells[6]
            Hash = $cells[7]
        }) | Out-Null
    }
    if (-not $headerSeen -or -not $separatorSeen) { throw "Managed manifest is missing its exact header or separator." }
    return $entries.ToArray()
}

function Get-OrdinalSortedEntries([object[]]$Items) {
    $sorted = [object[]]@($Items)
    $comparison = [System.Comparison[object]]{
        param($left, $right)
        $pathOrder = [System.StringComparer]::Ordinal.Compare([string]$left.Path, [string]$right.Path)
        if ($pathOrder -ne 0) { return $pathOrder }
        return [System.StringComparer]::Ordinal.Compare([string]$left.Id, [string]$right.Id)
    }
    [System.Array]::Sort($sorted, $comparison)
    return $sorted
}

function Get-ExplicitMetadata([string]$Path, [string]$Extension) {
    $metadata = @{}
    if ($Extension -ne ".md") { return $metadata }
    try {
        $reader = New-Object System.IO.StreamReader($Path, [System.Text.Encoding]::UTF8, $true)
        try {
            $buffer = New-Object char[] 16384
            $read = $reader.ReadBlock($buffer, 0, $buffer.Length)
            $text = New-Object string($buffer, 0, $read)
        }
        finally { $reader.Dispose() }
    }
    catch { return $metadata }

    $patterns = @{
        Id = '(?im)^\s*(?:geurtsId|designDocumentId)\s*:\s*["'']?(?<Value>[^"''\r\n]+)'
        Purpose = '(?im)^\s*(?:purpose\s*:|\*\*Purpose:\*\*)\s*(?<Value>[^\r\n]+)'
        Status = '(?im)^\s*(?:status\s*:|\*\*Status:\*\*)\s*(?<Value>[^\r\n]+)'
        Version = '(?im)^\s*(?:version\s*:|\*\*Version:\*\*)\s*(?<Value>[^\r\n]+)'
        Authority = '(?im)^\s*(?:authority\s*:|\*\*Authority:\*\*)\s*(?<Value>[^\r\n]+)'
        Tags = '(?im)^\s*(?:tags\s*:|\*\*Tags:\*\*)\s*(?<Value>[^\r\n]+)'
    }
    foreach ($name in $patterns.Keys) {
        $match = [regex]::Match($text, $patterns[$name])
        if ($match.Success) {
            $value = $match.Groups["Value"].Value.Trim().Trim('"').Trim("'").Trim()
            if (-not [string]::IsNullOrWhiteSpace($value)) { $metadata[$name] = $value }
        }
    }
    return $metadata
}

function Select-Metadata([hashtable]$Explicit, $Existing, [string]$Name, [string]$Default) {
    if ($Explicit.ContainsKey($Name) -and -not [string]::IsNullOrWhiteSpace([string]$Explicit[$Name])) { return [string]$Explicit[$Name] }
    if ($Existing -and -not [string]::IsNullOrWhiteSpace([string]$Existing.$Name)) { return [string]$Existing.$Name }
    return $Default
}

function Add-Event([string]$Status, [string]$Path, [string]$Message) {
    $events.Add([pscustomobject]@{ status = $Status.ToLowerInvariant(); path = $Path; message = $Message }) | Out-Null
    if ($OutputFormat -eq "Text") { Write-Host ("{0}: {1} - {2}" -f $Status, $Path, $Message) }
}

function Exit-ManifestLock {
    if ($lockStream) { $lockStream.Dispose(); $script:lockStream = $null }
    $script:lockOwned = $false
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
    [System.Text.Encoding]$Encoding
) {
    # Keep transaction artifacts at the validated root so a late swap of the
    # manifest's parent cannot redirect or strand them through a reparse point.
    $temporary = Join-Path $AllowedRoot (".ggf-manifest-" + [Guid]::NewGuid().ToString("N") + ".tmp")
    $replacementBackup = Join-Path $AllowedRoot (".ggf-replace-" + [Guid]::NewGuid().ToString("N") + ".bak")
    try {
        [System.IO.File]::WriteAllText($temporary, $Text, $Encoding)
        $temporaryFile = Read-ManagedTextFile -Path $temporary
        $roundTrip = [string]$temporaryFile.Text
        if ($roundTrip -cne $Text) { throw "Temporary manifest verification failed." }
        if ([regex]::Matches($roundTrip, 'GEURTS-GDD-MANIFEST-BEGIN').Count -ne 1 -or [regex]::Matches($roundTrip, 'GEURTS-GDD-MANIFEST-END').Count -ne 1) {
            throw "Temporary manifest does not contain one valid managed region."
        }
        $roundTripMatch = [regex]::Match($roundTrip, $manifestPattern)
        if (-not $roundTripMatch.Success -or $roundTripMatch.Groups["Version"].Value -cne "0.7.0") { throw "Temporary manifest managed-region version is invalid." }
        Get-ExistingEntries -Body $roundTripMatch.Groups["Body"].Value | Out-Null
        Invoke-TestWriteBarrier -TargetPath $Path
        $resolvedTarget = [System.IO.Path]::GetFullPath($Path)
        $resolvedRoot = [System.IO.Path]::GetFullPath($AllowedRoot)
        if (-not (Test-IsContainedPath -Candidate $resolvedTarget -Root $resolvedRoot) -or (Test-HasReparsePoint -Candidate $resolvedTarget -Root $resolvedRoot)) { throw "Manifest path changed or uses an unsafe reparse point immediately before promotion." }
        if ($ExpectedState -ceq "Absent") {
            if (Test-Path -LiteralPath $resolvedTarget) { throw "Manifest target appeared after preflight; concurrent content was preserved." }
            [System.IO.File]::Move($temporary, $resolvedTarget)
        }
        else {
            if (-not (Test-Path -LiteralPath $resolvedTarget -PathType Leaf)) { throw "Manifest disappeared or changed type after it was read." }
            if ([string]::IsNullOrWhiteSpace($ExpectedByteHash) -or (Get-FileSha256 -Path $resolvedTarget) -cne $ExpectedByteHash) { throw "Manifest bytes changed after they were read; the concurrent edit was preserved." }
            [System.IO.File]::Replace($temporary, $resolvedTarget, $replacementBackup)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $replacementBackup) { Remove-Item -LiteralPath $replacementBackup -Force -ErrorAction SilentlyContinue }
    }
}

try {
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { throw "-ProjectRoot is required for game-design manifest maintenance; the tool will not infer a Unity project from its own Tools location." }
    $ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) { throw "Project root does not exist: $ProjectRoot" }
    Assert-UnityProjectRoot -Root $ProjectRoot

    $requiredManifestPath = Join-Path $ProjectRoot "Docs/GameDesign/GameDesignManifest.md"
    if ([string]::IsNullOrWhiteSpace($ManifestPath)) { $ManifestPath = $requiredManifestPath }
    else { $ManifestPath = Get-FullPath -Path $ManifestPath -BasePath $ProjectRoot }
    if ($ManifestPath -cne $requiredManifestPath) { throw "ManifestPath must resolve to the required project path Docs/GameDesign/GameDesignManifest.md." }
    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) { throw "Game Design Manifest does not exist: $ManifestPath" }

    $designRoot = Split-Path -Parent $ManifestPath
    if (Test-HasReparsePoint -Candidate $ManifestPath -Root $ProjectRoot) { throw "The required game-design path contains a reparse point and is unsafe." }
    # Keep the single-writer artifact at the validated Unity root. A late swap
    # of Docs/GameDesign must not redirect either the lock or write artifacts.
    $lockPath = Join-Path $ProjectRoot ".ggf-manifest.lock"
    try {
        $lockStream = New-Object System.IO.FileStream($lockPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::DeleteOnClose)
        $lockOwned = $true
    }
    catch { throw "Manifest maintenance lock path already exists or could not be acquired; it was preserved." }

    $importedPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($rawImportedPath in @($ImportedPath)) {
        if ([string]::IsNullOrWhiteSpace([string]$rawImportedPath)) { throw "ImportedPath cannot contain an empty value." }
        $fullImportedPath = Get-FullPath -Path ([string]$rawImportedPath) -BasePath $ProjectRoot
        if (-not (Test-IsContainedPath -Candidate $fullImportedPath -Root $designRoot)) {
            throw "Imported path must be inside the game-design directory: $rawImportedPath"
        }
        $projectRelativeImport = $fullImportedPath.Substring($ProjectRoot.Length).TrimStart('\', '/').Replace('\', '/')
        if ($projectRelativeImport -ieq "Docs/GameDesign/GameDesignManifest.md") {
            throw "The manifest itself cannot be declared as an imported design document."
        }
        if (-not $importedPaths.Add($projectRelativeImport)) { throw "ImportedPath contains a duplicate path: $projectRelativeImport" }
    }
    $manifestFile = Read-ManagedTextFile -Path $ManifestPath
    $manifestText = [string]$manifestFile.Text
    $sourceManifestHash = [string]$manifestFile.ByteHash
    $manifestEncoding = $manifestFile.Encoding
    $manifestMatch = [regex]::Match($manifestText, $manifestPattern)
    if (-not $manifestMatch.Success -or [regex]::Matches($manifestText, 'GEURTS-GDD-MANIFEST-BEGIN').Count -ne 1 -or [regex]::Matches($manifestText, 'GEURTS-GDD-MANIFEST-END').Count -ne 1) {
        Add-Event "Skipped" "Docs/GameDesign/GameDesignManifest.md" "User-owned manifest has no single valid managed index; it was preserved."
        Exit-ManifestLock
        if ($OutputFormat -eq "Json") { [pscustomobject]@{ status = "SKIPPED"; events = $events.ToArray() } | ConvertTo-Json -Depth 5 }
        exit 0
    }
    if ($manifestMatch.Groups["Version"].Value -cne "0.7.0") { throw "Managed GDD manifest version '$($manifestMatch.Groups['Version'].Value)' is unsupported; no downgrade was performed." }

    $existingEntries = Get-ExistingEntries -Body $manifestMatch.Groups["Body"].Value
    $existingByPath = @{}
    $existingById = @{}
    foreach ($entry in $existingEntries) {
        $pathKey = $entry.Path.ToLowerInvariant()
        $idKey = $entry.Id.ToLowerInvariant()
        if ($existingByPath.ContainsKey($pathKey)) { throw "Duplicate path in managed manifest: $($entry.Path)" }
        if ($existingById.ContainsKey($idKey)) { throw "Duplicate identifier in managed manifest: $($entry.Id)" }
        $existingByPath[$pathKey] = $entry
        $existingById[$idKey] = $entry
    }

    $documents = New-Object System.Collections.Generic.List[object]
    $hidden = New-Object System.Collections.Generic.List[string]
    $unsupported = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-SafeDesignFiles -DesignRoot $designRoot -Root $ProjectRoot)) {
        $relativeWithinDesign = $file.FullName.Substring($designRoot.Length).TrimStart('\', '/')
        if ($relativeWithinDesign -ieq "GameDesignManifest.md") { continue }
        if ($file.Name.StartsWith(".ggf-", [System.StringComparison]::OrdinalIgnoreCase) -or $file.Name -match '(?i)\.bak(?:\.\d+)?$') { continue }
        $projectRelative = $file.FullName.Substring($ProjectRoot.Length).TrimStart('\', '/').Replace('\', '/')
        $relativeSegments = @($relativeWithinDesign.Replace('\', '/').Split('/'))
        $hasHiddenSegment = @($relativeSegments | Where-Object { $_.StartsWith(".", [System.StringComparison]::Ordinal) }).Count -gt 0
        if (($file.Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0 -or $hasHiddenSegment) {
            $hidden.Add($projectRelative) | Out-Null
            continue
        }
        if (($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $unsupported.Add($projectRelative) | Out-Null
            continue
        }
        $extension = $file.Extension.ToLowerInvariant()
        if ($extension -ne $supportedExtension) {
            $unsupported.Add($projectRelative) | Out-Null
            continue
        }
        $documents.Add([pscustomobject]@{
            Path = $projectRelative
            FullPath = $file.FullName
            Extension = $extension
            Hash = Get-FileSha256 -Path $file.FullName
            Metadata = Get-ExplicitMetadata -Path $file.FullName -Extension $extension
        }) | Out-Null
    }

    $hiddenPaths = [string[]]$hidden.ToArray()
    [System.Array]::Sort($hiddenPaths, [System.StringComparer]::Ordinal)
    foreach ($path in $hiddenPaths) {
        Add-Event "Skipped" $path "Hidden files and files below hidden directories are excluded from discovery."
    }
    $unsupportedPaths = [string[]]$unsupported.ToArray()
    [System.Array]::Sort($unsupportedPaths, [System.StringComparer]::Ordinal)
    foreach ($path in $unsupportedPaths) {
        Add-Event "Unsupported" $path "File type is not supported for AI routing and was not added to the managed index."
    }

    $currentPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($document in $documents) { [void]$currentPaths.Add($document.Path) }
    foreach ($imported in $importedPaths) {
        if (-not $currentPaths.Contains($imported)) {
            throw "Imported path was not discovered as a supported visible Markdown file: $imported"
        }
    }
    $missingEntries = @($existingEntries | Where-Object { -not $currentPaths.Contains($_.Path) })
    $usedExistingIds = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $outputEntries = New-Object System.Collections.Generic.List[object]

    foreach ($document in @(Get-OrdinalSortedEntries -Items $documents.ToArray())) {
        $explicit = $document.Metadata
        $existing = $null
        if ($existingByPath.ContainsKey($document.Path.ToLowerInvariant())) {
            $existing = $existingByPath[$document.Path.ToLowerInvariant()]
        }
        elseif ($explicit.ContainsKey("Id") -and $existingById.ContainsKey(([string]$explicit["Id"]).ToLowerInvariant())) {
            $existing = $existingById[([string]$explicit["Id"]).ToLowerInvariant()]
            $oldDirectory = [System.IO.Path]::GetDirectoryName($existing.Path.Replace('/', '\'))
            $newDirectory = [System.IO.Path]::GetDirectoryName($document.Path.Replace('/', '\'))
            $pathStatus = if ($oldDirectory -ieq $newDirectory) { "Renamed" } else { "Moved" }
            Add-Event $pathStatus $document.Path "Matched '$($existing.Path)' by explicit stable identifier."
        }
        else {
            $hashMatches = @($missingEntries | Where-Object { $_.Hash -eq $document.Hash -and -not $usedExistingIds.Contains($_.Id) })
            if ($hashMatches.Count -eq 1) {
                $existing = $hashMatches[0]
                $oldDirectory = [System.IO.Path]::GetDirectoryName($existing.Path.Replace('/', '\'))
                $newDirectory = [System.IO.Path]::GetDirectoryName($document.Path.Replace('/', '\'))
                $pathStatus = if ($oldDirectory -ieq $newDirectory) { "Renamed" } else { "Moved" }
                Add-Event $pathStatus $document.Path "Matched '$($existing.Path)' by unique prior content hash and preserved metadata."
            }
            elseif ($hashMatches.Count -gt 1) {
                throw "Ambiguous content-hash rename for '$($document.Path)'; the previous manifest was preserved."
            }
        }

        $id = Select-Metadata -Explicit $explicit -Existing $existing -Name "Id" -Default ("gdd-" + (Get-StringHash -Text $document.Path.ToLowerInvariant()).Substring(0, 16))
        if ($id -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$') { throw "Invalid document identifier '$id' in $($document.Path)." }
        if ($existing) { [void]$usedExistingIds.Add($existing.Id) }

        $purpose = Select-Metadata -Explicit $explicit -Existing $existing -Name "Purpose" -Default "RequiresClassification"
        $documentStatus = Select-Metadata -Explicit $explicit -Existing $existing -Name "Status" -Default "RequiresClassification"
        $documentVersion = Select-Metadata -Explicit $explicit -Existing $existing -Name "Version" -Default "Unprovided"
        $authority = Select-Metadata -Explicit $explicit -Existing $existing -Name "Authority" -Default "Unprovided"
        $tags = Select-Metadata -Explicit $explicit -Existing $existing -Name "Tags" -Default "Unprovided"
        if (@(@($purpose, $documentStatus, $documentVersion, $authority, $tags) | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) { throw "Document '$($document.Path)' has an empty routing field." }
        if ($documentVersion -ne "Unprovided" -and $documentVersion -notmatch '^\d+\.\d+(?:\.\d+)?(?:[-+][0-9A-Za-z.-]+)?$') { throw "Document '$($document.Path)' has invalid version '$documentVersion'." }

        $outputEntries.Add([pscustomobject]@{
            Id = $id
            Path = $document.Path
            Purpose = $purpose
            Status = $documentStatus
            Version = $documentVersion
            Authority = $authority
            Tags = $tags
            Hash = $document.Hash
        }) | Out-Null

        if (-not $existing) {
            if ($importedPaths.Contains($document.Path)) {
                Add-Event "Imported" $document.Path "The importer explicitly identified this new Markdown document; filename semantics were not inferred."
            }
            else {
                Add-Event "Added" $document.Path "Discovered a new Markdown document without inferring purpose from its filename."
            }
        }
        elseif ($existing.Path -ieq $document.Path -and $existing.Hash -ne $document.Hash) {
            Add-Event "Updated" $document.Path "Content hash changed; manually authored routing metadata was preserved."
        }
        elseif ($existing.Path -ieq $document.Path) {
            Add-Event "Unchanged" $document.Path "Path, content hash, and routing metadata are unchanged."
        }
    }

    foreach ($entry in $missingEntries) {
        if ($usedExistingIds.Contains($entry.Id)) { continue }
        Add-Event "Removed" $entry.Path "File is absent and its managed record was removed after rename matching."
    }

    $idSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $pathSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $outputEntries) {
        if (-not $idSet.Add([string]$entry.Id)) { throw "Duplicate identifier detected after reconciliation: $($entry.Id)" }
        if (-not $pathSet.Add([string]$entry.Path)) { throw "Duplicate path detected after reconciliation: $($entry.Path)" }
    }

    $newline = if ($manifestMatch.Value.Contains("`r`n")) { "`r`n" } else { "`n" }
    $tableLines = New-Object System.Collections.Generic.List[string]
    $tableLines.Add('| ID | Path | Purpose | Status | Version | Authority | Tags | SHA256 |') | Out-Null
    $tableLines.Add('|---|---|---|---|---|---|---|---|') | Out-Null
    foreach ($entry in @(Get-OrdinalSortedEntries -Items $outputEntries.ToArray())) {
        $cells = @($entry.Id, $entry.Path, $entry.Purpose, $entry.Status, $entry.Version, $entry.Authority, $entry.Tags, $entry.Hash) | ForEach-Object { Escape-MarkdownCell -Value ([string]$_) }
        $tableLines.Add("| " + ($cells -join " | ") + " |") | Out-Null
    }
    $replacement = '<!-- GEURTS-GDD-MANIFEST-BEGIN version="0.7.0" -->' + $newline + ($tableLines.ToArray() -join $newline) + $newline + '<!-- GEURTS-GDD-MANIFEST-END -->'
    $updatedManifest = $manifestText.Substring(0, $manifestMatch.Index) + $replacement + $manifestText.Substring($manifestMatch.Index + $manifestMatch.Length)

    if ($updatedManifest -ceq $manifestText) {
        Add-Event "Preserved" "Docs/GameDesign/GameDesignManifest.md" "Managed index is already deterministic and current."
        $status = "UNCHANGED"
    }
    else {
        Write-AtomicText -Path $ManifestPath -Text $updatedManifest -AllowedRoot $ProjectRoot -ExpectedState "Existing" -ExpectedByteHash $sourceManifestHash -Encoding $manifestEncoding
        Add-Event "Updated" "Docs/GameDesign/GameDesignManifest.md" "Reconciled the managed index atomically."
        $status = "UPDATED"
    }

    Exit-ManifestLock
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{ status = $status; manifestPath = $ManifestPath; events = $events.ToArray() } | ConvertTo-Json -Depth 6
    }
    exit 0
}
catch {
    Exit-ManifestLock
    Add-Event "Conflicted" $(if ($ManifestPath) { $ManifestPath } else { "Docs/GameDesign/GameDesignManifest.md" }) $_.Exception.Message
    if ($OutputFormat -eq "Json") {
        [pscustomobject]@{ status = "CONFLICTED"; message = $_.Exception.Message; events = $events.ToArray() } | ConvertTo-Json -Depth 6
    }
    else {
        Write-Host "GDD MANIFEST CONFLICT: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "The previous manifest was preserved."
    }
    exit 2
}
