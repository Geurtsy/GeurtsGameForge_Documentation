# Version: 1.0.0
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [ValidateSet('Text', 'Json')][string]$OutputFormat = 'Text'
)
$ErrorActionPreference = 'Stop'
$passed = 0
$failures = New-Object 'System.Collections.Generic.List[string]'
function Assert-Audience([bool]$Condition, [string]$Name) {
    if ($Condition) { $script:passed++ }
    else { $script:failures.Add($Name) }
}
function Assert-Rejected([scriptblock]$Action, [string]$Name) {
    $rejected = $false
    try { & $Action | Out-Null } catch { $rejected = $true }
    Assert-Audience $rejected $Name
}
$fixture = Join-Path ([System.IO.Path]::GetTempPath()) ('ggf-audience-tests-' + [Guid]::NewGuid().ToString('N'))
try {
    Import-Module (Join-Path $RepositoryRoot 'Tools/GeurtsDocumentationAudience.psm1') -Force
    $sample = @'
<!-- GEURTS-AUDIENCE: AI-READ -->
Shared opening.
<!-- GEURTS-SECTION:BEGIN HUMAN-ONLY -->
Human walkthrough.
<!-- GEURTS-SECTION:END -->
<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
Forge implementation.
<!-- GEURTS-SECTION:END -->
Shared ending.
'@
    $game = ConvertTo-GeurtsAudienceText -Text $sample
    $forge = ConvertTo-GeurtsAudienceText -Text $sample -Mode ForgeDevelopment
    $human = ConvertTo-GeurtsAudienceText -Text $sample -IncludeHuman
    $all = ConvertTo-GeurtsAudienceText -Text $sample -Mode ForgeDevelopment -IncludeHuman
    Assert-Audience ($game.Content.Contains('Shared opening.') -and $game.Content.Contains('Shared ending.') -and -not $game.Content.Contains('walkthrough') -and -not $game.Content.Contains('implementation')) 'GameUse keeps shared rules and excludes both conditional audiences'
    Assert-Audience ($forge.Content.Contains('Forge implementation.') -and -not $forge.Content.Contains('walkthrough')) 'ForgeDevelopment includes implementation and still excludes human content'
    Assert-Audience ($human.Content.Contains('Human walkthrough.') -and -not $human.Content.Contains('implementation')) 'IncludeHuman does not enable Forge development'
    Assert-Audience ($all.Content.Contains('Human walkthrough.') -and $all.Content.Contains('Forge implementation.')) 'Explicit human review during Forge work includes both conditional audiences'
    Assert-Audience ($game.SourceCharacters -eq $sample.Length -and $game.ReturnedCharacters -eq $game.Content.Length -and $game.SkippedLines -eq 2) 'Reported counts describe actual returned content'
    $humanDefault = $sample.Replace('GEURTS-AUDIENCE: AI-READ', 'GEURTS-AUDIENCE: HUMAN-ONLY')
    $override = ConvertTo-GeurtsAudienceText -Text $humanDefault -Mode ForgeDevelopment
    Assert-Audience ($override.Content.Trim() -ceq 'Forge implementation.') 'Explicit section audience overrides a human file default'
    $untagged = "# Older document`r`nKeep every rule.`r`n"
    Assert-Audience ((ConvertTo-GeurtsAudienceText -Text $untagged).Content -ceq $untagged) 'Untagged guidance and CRLF remain unchanged'
    Assert-Audience ((ConvertTo-GeurtsAudienceText -Text '').Content.Length -eq 0) 'Empty document remains empty'
    foreach ($fence in @('```', '~~~~')) {
        $literal = $fence + "markdown`n<!-- GEURTS-SECTION:BEGIN HUMAN-ONLY -->`nLiteral template data.`n" + $fence + "`n"
        Assert-Audience ((ConvertTo-GeurtsAudienceText -Text $literal).Content -ceq $literal) "Literal audience markers inside $fence fences remain data"
    }
    $longFence = "````````markdown`n`````` `n<!-- GEURTS-AUDIENCE: INVALID -->`n````````"
    Assert-Audience ((ConvertTo-GeurtsAudienceText -Text $longFence).Content -ceq $longFence) 'Shorter fence cannot close a longer literal block'
    foreach ($invalid in @(
        '<!-- GEURTS-AUDIENCE: UNKNOWN -->',
        '<!-- GEURTS-AUDIENCE: ai-read -->',
        '<!-- GEURTS-SECTION:BEGIN UNKNOWN -->',
        '<!-- GEURTS-SECTION:BEGIN HUMAN-ONLY -->',
        '<!-- GEURTS-SECTION:END -->',
        "<!-- GEURTS-SECTION:BEGIN HUMAN-ONLY -->`n<!-- GEURTS-SECTION:BEGIN AI-READ -->",
        "<!-- GEURTS-AUDIENCE: AI-READ -->`n<!-- GEURTS-AUDIENCE: AI-READ -->",
        "# Too late`n<!-- GEURTS-AUDIENCE: HUMAN-ONLY -->",
        "<!-- GEURTS-SECTION:BEGIN HUMAN-ONLY -->`n<!-- GEURTS-SECTION:END-->",
        '```markdown'
    )) {
        Assert-Rejected { ConvertTo-GeurtsAudienceText -Text $invalid } "Malformed tag/fence fails closed: $invalid"
    }

    foreach ($bootstrap in @('AI_READ_FIRST.md', 'GeurtsTechniqueManifest.md')) {
        $raw = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $bootstrap))
        foreach ($mode in @('GameUse', 'ForgeDevelopment')) {
            $read = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document $bootstrap -Mode $mode
            Assert-Audience ($read.SkippedLines -eq 0 -and $read.Content.Contains('GeurtsTechniqueManifest.md')) "$bootstrap remains completely AI-readable in $mode"
        }
    }
    $technical = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document 'GeurtsTechniques/GeurtsTechnicalTechnique.md'
    $technicalForge = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document 'GeurtsTechniques/GeurtsTechnicalTechnique.md' -Mode ForgeDevelopment
    Assert-Audience (-not $technical.Content.Contains('## Reusable Framework Compliance Header') -and $technicalForge.Content.Contains('## Reusable Framework Compliance Header') -and $technical.Content.Contains('## Technical Priority Order') -and $technical.Content.Contains('All code suggestions,')) 'Framework header is conditional; shared technical priorities and obligations survive'
    $brick = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document 'GeurtsTechniques/GeurtsBrickContract.md'
    Assert-Audience ($brick.Content.Contains('## Use existing bricks') -and $brick.Content.Contains('Odin Inspector and Quantum Console') -and $brick.Content.Contains('losing local edits') -and $brick.Content.Contains('Install is explicit.') -and $brick.Content.Contains('Only `released: true` entries') -and -not $brick.Content.Contains('Implement `IBrick`')) 'Game consumers retain reuse, tools, release sources, confirmation and overwrite guidance'
    $readmeGame = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document 'README.md'
    $readmeForge = Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document 'README.md' -Mode ForgeDevelopment
    Assert-Audience ($readmeGame.Content.Trim().Length -eq 0 -and $readmeForge.Content.Contains('## Maintenance') -and -not $readmeForge.Content.Contains('## Changelog')) 'README walkthroughs/history skip by default; source maintenance is Forge-only'
    foreach ($payload in @('GeurtsTechniques/GeurtsAgentTechnique.md', 'GeurtsTechniques/GeurtsGitIgnoreTechnique.md')) {
        $raw = [System.IO.File]::ReadAllText((Join-Path $RepositoryRoot $payload))
        $expected = [regex]::Replace($raw, '\A<!-- GEURTS-AUDIENCE: AI-READ -->\r?\n', '')
        Assert-Audience ((Read-GeurtsAudienceDocument -RepositoryRoot $RepositoryRoot -Document $payload).Content -ceq $expected) "$payload preserves its full literal installer payload"
    }

    # Independent fixture proves the reader cannot select project/GDD files or
    # follow a registered junction out of its documentation root.
    [void][System.IO.Directory]::CreateDirectory($fixture)
    [System.IO.File]::WriteAllText((Join-Path $fixture 'GeurtsTechniqueManifest.md'), @'
<!-- GEURTS-PACKAGE-FILES:BEGIN -->
| `allowed.md` | 1.0.0 | Fixture |
| `linked/secret.md` | 1.0.0 | Fixture |
<!-- GEURTS-PACKAGE-FILES:END -->
'@)
    [System.IO.File]::WriteAllText((Join-Path $fixture 'allowed.md'), $sample)
    [System.IO.File]::WriteAllText((Join-Path $fixture 'unregistered.md'), 'Do not load this file.')
    $before = (Get-FileHash -LiteralPath (Join-Path $fixture 'allowed.md')).Hash
    Assert-Audience ((Read-GeurtsAudienceDocument -RepositoryRoot $fixture -Document 'allowed.md').Content -ceq $game.Content) 'Explicit registered file is read without a Git checkout'
    foreach ($path in @('../outside.md', 'Docs/GameDesign/../../allowed.md', 'unregistered.md', 'C:/outside.md', 'allowed.json')) {
        Assert-Rejected { Read-GeurtsAudienceDocument -RepositoryRoot $fixture -Document $path } "Reader rejects out-of-scope selection: $path"
    }
    [void][System.IO.Directory]::CreateDirectory((Join-Path $fixture 'outside'))
    [System.IO.File]::WriteAllText((Join-Path $fixture 'outside/secret.md'), 'Do not follow this link.')
    $link = New-Item -ItemType Junction -Path (Join-Path $fixture 'linked') -Target (Join-Path $fixture 'outside')
    try { Assert-Rejected { Read-GeurtsAudienceDocument -RepositoryRoot $fixture -Document 'linked/secret.md' } 'Reader refuses a registered path through a junction' }
    finally { [System.IO.Directory]::Delete($link.FullName) }
    Assert-Audience ((Get-FileHash -LiteralPath (Join-Path $fixture 'allowed.md')).Hash -ceq $before) 'Reads preserve source file bytes'
}
catch { $failures.Add("Harness error at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)") }
finally {
    $resolved = [System.IO.Path]::GetFullPath($fixture)
    $temporaryRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd([char[]]'\/') + [System.IO.Path]::DirectorySeparatorChar
    if ($resolved.StartsWith($temporaryRoot, [System.StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolved) -like 'ggf-audience-tests-*') {
        if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
    }
    else { $failures.Add('Refused unsafe fixture cleanup path.') }
}
$result = [pscustomobject]@{ passed = $passed; failed = $failures.Count; failures = $failures.ToArray() }
if ($OutputFormat -eq 'Json') { $result | ConvertTo-Json -Depth 3 }
else { $result | Format-List }
if ($failures.Count -gt 0) { exit 1 }
exit 0
