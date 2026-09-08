<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts Git Ignore Technique

**Version:** 1.0.0
**Status:** Approved normative technique
**Primary audience:** AI coding agents, automated development systems, and compatible setup integrations
**Secondary audience:** Human developers and package maintainers
**Required package path:** `GeurtsTechniques/GeurtsGitIgnoreTechnique.md`
**Target path:** `<ProjectRoot>/.gitignore`

---

## Purpose and Authority

This document owns the approved custom Unity project `.gitignore` payload consumed by compatible setup tools. The payload preserves the exact logical contents of the approved source template after newline normalization. The approved source was UTF-8 without a byte-order mark, used CRLF newlines, ended with a newline, and had raw SHA-256 `c8412a38435bccd89f1fefb855da3c24680612c27609341e64dcbaf99c0f88ab` before normalization.

`GeurtsTechniqueManifest.md` selects this technique when the payload is needed. Prose and Markdown outside the marked payload below are explanatory only and must never be copied into a project `.gitignore`.

## Deterministic Payload Contract

The document must contain exactly one begin marker, one end marker, and one enclosed `gitignore` fenced block. The begin marker must be a complete line with the exact attribute order shown below. The immediately following line must consist of three backticks followed by `gitignore`; the payload begins after that line's newline. The closing-fence line must consist of exactly three backticks, must immediately follow the payload's terminal newline, and must be immediately followed by the exact end-marker line. Extra in-region prose, blank lines outside the payload, indentation, attributes, markers, or fences are invalid.

Decode the document as valid UTF-8, permitting a byte-order mark only at the beginning of the Markdown document and removing it before parsing. The payload itself must not begin with a byte-order mark. Normalize the extracted text to UTF-8 without a byte-order mark, LF newlines, and exactly one terminal LF. The marker version must equal this technique's declared version and its manifest registry version. The normalized payload must have these values:

| Field | Value |
|---|---|
| Template version | `1.0.0` |
| Target | `.gitignore` |
| Logical line count | `376` |
| Normalized SHA-256 | `7223a9449718942d3a5cad00cf4d4e0dee9c89eb64951541fa4ebfb803acb45b` |
| Approved CRLF source SHA-256 | `c8412a38435bccd89f1fefb855da3c24680612c27609341e64dcbaf99c0f88ab` |

If the marked documentation payload is missing or its metadata, fence structure, normalized line count, terminal newline, or hash does not match, fail safely and preserve the target exactly. Do not create a missing target from an invalid payload and do not copy a partial payload. This payload contract has `fallbackPolicy: none`; `com.gameforge.intelligence` must not bundle or substitute a plugin-owned copy of this Geurts payload.

A compatible setup operation may act only with explicit user authorization for this `.gitignore` subject. When authorized, it may create `<ProjectRoot>/.gitignore` only when the target is missing and this marked payload validates exactly. An identical existing target is reported unchanged and without rewriting. If the target already exists and differs, preserve its bytes and timestamp exactly and report `preserved` or `conflict`; never append, merge, replace, or reformat it. There is no Git index mutation: never stage, unstage, add, remove, or otherwise change Git tracking state through this operation.

The fenced bytes below are a literal imported compatibility source. Names and comments inside the fenced payload are preserved source content, not generic Geurts assumptions, and must not be edited to modernize prose.

## Approved Payload

<!-- GEURTS-GITIGNORE-BEGIN version="1.0.0" target=".gitignore" sha256="7223a9449718942d3a5cad00cf4d4e0dee9c89eb64951541fa4ebfb803acb45b" -->
```gitignore
# =============================================================================
# Siegefall / Geurts Unity Project .gitignore
# =============================================================================
#
# Place this file at the Unity project root, beside:
#   Assets/
#   Packages/
#   ProjectSettings/
#
# Based on GitHub's current Unity template, expanded for:
#   - Unity 6
#   - JetBrains Rider
#   - Visual Studio and Visual Studio Code
#   - Windows, Linux, and macOS
#   - Addressables, Test Runner, Visual Scripting, Android, and Web tooling
#   - Geurts update staging folders
#
# IMPORTANT:
#   - Commit Assets/, Packages/, ProjectSettings/, and normal Unity .meta files.
#   - Do not add a global *.meta rule.
#   - .gitignore does not automatically untrack files already committed.
#   - Broad *~ rules are intentionally avoided because Unity packages commonly
#     contain committed folders named Documentation~, Samples~, and Tests~.
#
# Official Unity baseline:
# https://github.com/github/gitignore/blob/main/Unity.gitignore
# =============================================================================


# =============================================================================
# Unity generated folders and local editor state
# =============================================================================

.utmp/
/[Ll]ibrary/
/[Tt]emp/
/[Oo]bj/
/[Bb]uild/
/[Bb]uilds/
/[Ll]ogs/
/[Uu]ser[Ss]ettings/

# Safe additional generated-output folders at the project root
/[Bb]uildOutput/
/[Bb]uildArtifacts/
/[Cc]rashes/
/[Cc]rashReports/
/[Mm]emoryCaptures/
/[Pp]rofileData/
/[Pp]rofilerData/
/[Rr]ecordings/


# =============================================================================
# Unity, Mono, and native crash or diagnostic files
# =============================================================================

*.log
*.dmp
*.mdmp
*.stackdump
*.stacktrace
mono_crash.*
sysinfo.txt


# =============================================================================
# Blender backup files
# Unity imports the main .blend file; numbered Blender backups are disposable.
# =============================================================================

*.blend[1-9]
*.blend[1-9].meta


# =============================================================================
# JetBrains Rider and JetBrains IDEs
# =============================================================================

.idea/
*.iml
*.DotSettings.user

# Unity-generated Rider Editor plugin
/[Aa]ssets/Plugins/Editor/JetBrains*


# =============================================================================
# Visual Studio, MonoDevelop, Consulo, and generated solution/project files
# =============================================================================

.vs/
.consulo/
ExportedObj/

*.csproj
*.unityproj
*.sln
*.slnx
*.suo
*.user
*.userprefs
*.userosscache
*.sln.docstates
*.rsuser
*.pidb
*.booproj
*.svd
*.pdb
*.mdb
*.ipdb
*.iobj
*.opendb
*.opensdf
*.sdf
*.ncb
*.VC.db
*.VC.VC.opendb

# Unity-generated metadata belonging only to ignored debug database files
*.pidb.meta
*.pdb.meta
*.mdb.meta

# Do not paste the complete generic VisualStudio.gitignore into a Unity project:
# it contains a broad *.meta rule that would break Unity asset references.


# =============================================================================
# Visual Studio Code
# Ignore local state while allowing deliberately shared workspace configuration.
# =============================================================================

/.vscode/*
!/.vscode/settings.json
!/.vscode/tasks.json
!/.vscode/launch.json
!/.vscode/extensions.json
!/.vscode/*.code-snippets

.history/
.vshistory/


# =============================================================================
# Unity packages, installers, and Asset Store publishing tools
# =============================================================================

# Imported package archives are installers, not the imported project contents.
# This also covers the KriptoFX URP/HDRP patch package files seen previously.
*.unitypackage
*.unitypackage.meta

# Safe for a game project that is not publishing packages through Asset Store Tools.
/[Aa]ssets/AssetStoreTools*


# =============================================================================
# Player builds and packaged build outputs
# =============================================================================

*.apk
*.aab
*.apks
*.xapk
*.obb
*.ipa
*.app
*.xcarchive
*.dSYM
*.dSYM.zip
*.symbols.zip

# Unity IL2CPP and Burst folders that should not ship or enter source control
**/*_BurstDebugInformation_DoNotShip/
**/*_BackUpThisFolder_ButDontShipItWithYourGame/
/[Ii]l2[Cc][Pp][Pp]OutputProject/
/[Ii]l2[Cc][Pp][Pp]Backup/


# =============================================================================
# Android and Gradle generated state
# =============================================================================

.gradle/
local.properties
**/.cxx/
**/.externalNativeBuild/

# Crashlytics-generated build file
crashlytics-build.properties


# =============================================================================
# Addressables generated data
# =============================================================================

/ServerData
/[Aa]ssets/[Ss]treamingAssets/aa*
/[Aa]ssets/[Aa]ddressable[Aa]ssets[Dd]ata/link.xml*
/[Aa]ssets/[Aa]ddressables_Temp*

# Addressables content-state files are ignored by default.
# Remove this rule before shipping remote content-update builds if you need to
# preserve addressables_content_state.bin for future content updates.
/[Aa]ssets/[Aa]ddressable[Aa]ssets[Dd]ata/*/*.bin*


# =============================================================================
# Unity Visual Scripting generated caches
# =============================================================================

/[Aa]ssets/Unity.VisualScripting.Generated/VisualScripting.Flow/UnitOptions.db
/[Aa]ssets/Unity.VisualScripting.Generated/VisualScripting.Flow/UnitOptions.db.meta
/[Aa]ssets/Unity.VisualScripting.Generated/VisualScripting.Core/Property Providers
/[Aa]ssets/Unity.VisualScripting.Generated/VisualScripting.Core/Property Providers.meta


# =============================================================================
# Unity Test Runner, code coverage, and benchmark output
# =============================================================================

InitTestScene*.unity*
/[Aa]ssets/[Ii]nit[Tt]est[Ss]cene*.unity*
/[Aa]ssets/[Ss]ceneDependencyCache*

/[Tt]est[Rr]esults/
/[Cc]odeCoverage/
/[Cc]odeCoverageResults/
/[Cc]overage/
/[Bb]enchmarkDotNet.Artifacts/

*.trx
*.coverage
*.coveragexml
coverage*.json
coverage*.xml
coverage*.info
nunit-*.xml
TestResult.xml


# =============================================================================
# Temporary editor files, merge leftovers, and backups
# =============================================================================

*.tmp
*.tmp.meta
*.temp
*.temp.meta
*.bak
*.bak.meta
*.orig
*.orig.meta
*.rej
*.rej.meta
*.swp
*.swp.meta
*.swo
*.swo.meta
*.autosave
*.autosave.meta
~$*
~$*.meta
.#*
.#*.meta
\#*\#
\#*\#.meta


# =============================================================================
# Operating system clutter
# =============================================================================

# Windows
[Tt]humbs.db
[Tt]humbs.db.meta
ehthumbs.db
ehthumbs.db.meta
[Dd]esktop.ini
[Dd]esktop.ini.meta
$RECYCLE.BIN/

# macOS
.DS_Store
.DS_Store.meta
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes

# Linux
.directory
.Trash-*
.nfs*


# =============================================================================
# Node and web tooling caches
# Useful if the repository contains Three.js tools, documentation, or a web build.
# =============================================================================

node_modules/
.npm/
.pnpm-store/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*


# =============================================================================
# Local secrets and signing credentials
# Keep templates, but never commit private local values or signing keys.
# =============================================================================

.env
.env.*
!.env.example
!.env.template
!.env.sample

*.keystore
*.keystore.meta
*.jks
*.jks.meta
*.p12
*.p12.meta
*.pfx
*.pfx.meta
*.mobileprovision
*.mobileprovision.meta
keystore.properties
keystore.properties.meta


# =============================================================================
# Source-control client metadata
# =============================================================================

.plastic/
plastic.workspace


# =============================================================================
# Geurts local update workflow
# Extracted updater payloads and their backups are temporary working material.
# =============================================================================

/[Uu]pdates/
/_[Uu]pdates/
/[Uu]pdateBackups/


# =============================================================================
# Intentionally tracked Unity project data
# =============================================================================
#
# These are comments, not ignore rules. Keep all of the following in Git:
#
#   Assets/
#   Packages/
#   ProjectSettings/
#   Packages/manifest.json
#   Packages/packages-lock.json
#   ProjectSettings/ProjectVersion.txt
#   All normal Unity .meta files
#   Embedded Geurts packages, including Documentation~, Samples~, and Tests~
#
# Large source assets such as textures, audio, models, and videos should use
# Git LFS rather than being ignored.
# =============================================================================

# GameForge Intelligence / Geurts synchronized documentation
.geurts/
```
<!-- GEURTS-GITIGNORE-END -->
