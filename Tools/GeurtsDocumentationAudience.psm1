# Version: 1.0.0
Set-StrictMode -Version Latest

function ConvertTo-GeurtsAudienceText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text,
        [ValidateSet('GameUse', 'ForgeDevelopment')][string]$Mode = 'GameUse',
        [switch]$IncludeHuman
    )

    $audiences = @('AI-READ', 'HUMAN-ONLY', 'FORGE-DEVELOPMENT-ONLY')
    $fileAudience = 'AI-READ'
    $sectionAudience = $null
    $fileTagSeen = $false
    $contentSeen = $false
    $fenceCharacter = $null
    $fenceLength = 0
    $skippedLines = 0
    $result = New-Object System.Text.StringBuilder
    $lineNumber = 0

    # Keep original line endings and literal fenced payloads. Tags must stand alone.
    foreach ($match in [regex]::Matches($Text, '[^\r\n]*(?:\r\n|\n|\r|$)')) {
        if ($match.Length -eq 0) { continue }
        $lineNumber++
        $line = $match.Value.TrimEnd([char[]]"`r`n")
        if ($null -eq $fenceCharacter) {
            if ($line -cmatch '^<!-- GEURTS-AUDIENCE: ([A-Z-]+) -->$') {
                if ($fileTagSeen -or $contentSeen -or $null -ne $sectionAudience) {
                    throw "Line ${lineNumber}: the file audience tag must occur once, before content."
                }
                $fileAudience = $Matches[1]
                if ($fileAudience -cnotin $audiences) { throw "Line ${lineNumber}: unknown audience '$fileAudience'." }
                $fileTagSeen = $true
                continue
            }
            if ($line -cmatch '^<!-- GEURTS-SECTION:BEGIN ([A-Z-]+) -->$') {
                if ($null -ne $sectionAudience) { throw "Line ${lineNumber}: audience sections cannot nest." }
                $sectionAudience = $Matches[1]
                if ($sectionAudience -cnotin $audiences) { throw "Line ${lineNumber}: unknown audience '$sectionAudience'." }
                $contentSeen = $true
                continue
            }
            if ($line -ceq '<!-- GEURTS-SECTION:END -->') {
                if ($null -eq $sectionAudience) { throw "Line ${lineNumber}: section end has no matching begin." }
                $sectionAudience = $null
                continue
            }
            if ($line -match '<!--\s*GEURTS-(?:AUDIENCE|SECTION)') {
                throw "Line ${lineNumber}: malformed audience tag."
            }
            if ($line -match '^ {0,3}(`{3,}|~{3,})(.*)$') {
                $delimiter = $Matches[1]
                $info = $Matches[2]
                if ($delimiter[0] -ne [char]96 -or -not $info.Contains([string][char]96)) {
                    $fenceCharacter = $delimiter[0]
                    $fenceLength = $delimiter.Length
                }
            }
        }
        elseif ($line -match '^ {0,3}(`{3,}|~{3,})\s*$') {
            $delimiter = $Matches[1]
            if ($delimiter[0] -eq $fenceCharacter -and $delimiter.Length -ge $fenceLength) {
                $fenceCharacter = $null
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($line)) { $contentSeen = $true }
        $audience = if ($null -ne $sectionAudience) { $sectionAudience } else { $fileAudience }
        $include = $audience -ceq 'AI-READ' -or
            ($audience -ceq 'FORGE-DEVELOPMENT-ONLY' -and $Mode -eq 'ForgeDevelopment') -or
            ($audience -ceq 'HUMAN-ONLY' -and $IncludeHuman)
        if ($include) { [void]$result.Append($match.Value) }
        else { $skippedLines++ }
    }
    if ($null -ne $sectionAudience) { throw 'Unclosed audience section; no filtered content returned.' }
    if ($null -ne $fenceCharacter) { throw 'Unclosed Markdown fence; audience boundaries cannot be verified.' }

    [pscustomobject]@{
        Content = $result.ToString()
        FileAudience = $fileAudience
        HasFileTag = $fileTagSeen
        SourceCharacters = $Text.Length
        ReturnedCharacters = $result.Length
        SkippedLines = $skippedLines
    }
}

function Read-GeurtsAudienceDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$Document,
        [ValidateSet('GameUse', 'ForgeDevelopment')][string]$Mode = 'GameUse',
        [switch]$IncludeHuman
    )
    # This reader never discovers project files or follows paths outside this package.
    $root = [System.IO.Path]::GetFullPath($RepositoryRoot)
    $relative = $Document.Replace('\', '/')
    if ($relative -notmatch '^(?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_.-]+\.md$' -or
        @($relative.Split('/') | Where-Object { $_ -in @('.', '..') }).Count -gt 0) {
        throw 'Document must be a relative Markdown path listed in the package manifest.'
    }
    foreach ($candidate in @('GeurtsTechniqueManifest.md', $relative)) {
        $current = Get-Item -LiteralPath $root -Force -ErrorAction Stop
        if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Linked documentation roots are not supported.' }
        foreach ($segment in $candidate.Split('/')) {
            $current = Get-Item -LiteralPath (Join-Path $current.FullName $segment) -Force -ErrorAction Stop
            if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'Linked documentation paths are not supported.' }
        }
        if ($current.PSIsContainer) { throw 'A documentation file was expected.' }
    }
    $manifest = [System.IO.File]::ReadAllText((Join-Path $root 'GeurtsTechniqueManifest.md'))
    $registry = [regex]::Match($manifest, '(?s)<!-- GEURTS-PACKAGE-FILES:BEGIN -->(.*?)<!-- GEURTS-PACKAGE-FILES:END -->')
    $registered = @([regex]::Matches($registry.Groups[1].Value, '(?m)^\| `([^`]+)` \|') | ForEach-Object { $_.Groups[1].Value })
    if (-not $registry.Success -or $relative -cnotin $registered) { throw "Document is not registered in this package: $relative" }
    $text = [System.IO.File]::ReadAllText((Join-Path $root $relative))
    ConvertTo-GeurtsAudienceText -Text $text -Mode $Mode -IncludeHuman:$IncludeHuman
}

Export-ModuleMember -Function ConvertTo-GeurtsAudienceText, Read-GeurtsAudienceDocument
