# Version: 1.0.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Document,
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
    [ValidateSet('GameUse', 'ForgeDevelopment')][string]$Mode = 'GameUse',
    [switch]$IncludeHuman,
    [ValidateSet('Text', 'Json')][string]$OutputFormat = 'Text'
)
$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot 'GeurtsDocumentationAudience.psm1') -Force
    $result = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document $Document -Mode $Mode -IncludeHuman:$IncludeHuman
    if ($OutputFormat -eq 'Json') {
        [pscustomobject]@{
            document = $Document
            mode = $Mode
            includeHuman = [bool]$IncludeHuman
            fileAudience = $result.FileAudience
            sourceCharacters = $result.SourceCharacters
            returnedCharacters = $result.ReturnedCharacters
            skippedLines = $result.SkippedLines
            content = $result.Content
        } | ConvertTo-Json -Depth 3
    }
    else { $result.Content }
}
catch {
    Write-Error -Message $_.Exception.Message -ErrorAction Continue
    exit 1
}
