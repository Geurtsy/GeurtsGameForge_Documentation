# Geurts Game Forge Documentation

**Version:** 0.10.0
**Status:** Draft technique package
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Documentation source repository:** `Geurtsy/GeurtsGameForge_Documentation`

## Start Here

Begin with `AGENTS.md`, then its sibling `AI_READ_FIRST.md`, then `GeurtsTechniqueManifest.md`. Do not start implementation from this README.

The manifest is the single resolver for package-file selection, versions, subject ownership, applicability, post-entry order, and cross-document conflicts. It selects every required technique from one validated source checkout or project-local fetched copy. When it selects the GDD Technique, that technique uses the project-authored `Docs/GameDesign/GameDesignManifest.md` to identify relevant design facts.

## Source and Ownership Boundary

This repository and its `main` branch are the sole primary source and authority for all Geurts Game Forge documentation. All Geurts techniques are sourced, versioned, and updated here. A documentation release does not require a `com.gameforge.intelligence` Unity-package release.

The four relevant locations have different owners:

| Location | Meaning and owner |
|---|---|
| `Geurtsy/GeurtsGameForge_Documentation` | Authoritative source for all Geurts Game Forge documentation. |
| `<ProjectRoot>/GeurtsGameForgeDocumentation/` | Detached, writable project-local fetched copy used by AI and tools. It is replaceable in full only through the confirmed Game Forge Intelligence Update action. |
| `<PluginPackageRoot>/Documentation~/` in `com.gameforge.intelligence` | Plugin-specific operation, implementation, and maintenance documentation only. It may reference this repository but must not embed, duplicate, or become authority for Geurts documentation. |
| `<ProjectRoot>/Docs/GameDesign/` | Project-authored game-design authority. It is outside the fetched copy and remains byte-untouched by documentation Update. |

The project-local fetched copy contains the complete supported Git-tracked source tree from one selected `main` commit:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
├── AGENTS.md
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
├── GeurtsTechniques/
├── Ideas/
├── Migrations/
├── README.md
└── Tools/
```

Those are the current tracked top-level entries, not an installation allowlist. The selected Git tree defines the complete content set. The fetched copy contains no `.git` metadata, repository/worktree/remote connection, or acquisition-preserved read-only attributes. Users may edit it locally, but the next confirmed Update unconditionally discards and replaces all content inside it.

## Game Forge Intelligence Manual Update

Each normal Unity project launch/open performs exactly one lightweight remote metadata check against the authoritative repository's `main` branch. When the exact destination exists, it compares the remote head commit ID with the authoritative selected commit ID in the current installed receipt and notifies only when those commit identities differ. Package version is display-only and never determines availability. If the remote commit is unavailable, the destination is absent, or there is no valid installed commit ID, availability is unknown and the plugin must not infer it from local files or package-version comparison. The check does not download documentation, install or synchronize files, inspect local content, mutate the project, recover content, or reintegrate anything. Failure is non-blocking. Ordinary AI/session initialization uses the existing local copy and performs no additional remote check.

The current installed receipt lives outside the fetched copy. Every successful Update records its authoritative selected commit ID and its authoritative package version when valid. The receipt is not a Git connection, repository/worktree/remote, local-drift ledger, backup, recovery gate, or authority. Local edits do not affect update availability. A missing copy remains unavailable until the user explicitly selects `Update Geurts Game Forge Documentation`.

The Geurts Documentation UI keeps version identities separate. `Installed Geurts Documentation` uses only the valid package version in the current installed receipt, never mutable local file bytes. It shows `Not installed` when the exact destination is known missing and `Unknown` when a copy exists without a trustworthy current receipt and valid package version. `GameForgeIntelligence Plugin` uses only the canonical installed Unity package version and shows `Unknown` when that metadata is unavailable or invalid. When commit-ID inequality establishes availability and bounded remote metadata provides a valid package version, the notification also shows `Available Geurts Documentation`; otherwise that notification says the available version is unknown. Integration Technique and Compatibility Schema versions are separate diagnostic values and must not be substituted for either primary label.

The action first presents a destructive warning with Cancel as the safe default. It states that the fetched copy will be deleted and replaced from the official repository's current `main`, every local edit inside it will be overwritten and lost, `Docs/GameDesign` and every other project file will remain untouched, and without rollback a failure or interruption can leave the copy missing or incomplete.

After confirmation, Game Forge Intelligence may use an ephemeral acquisition location and proportionate source/package validation, then replaces only `<ProjectRoot>/GeurtsGameForgeDocumentation/`. Immediately before destructive live deletion it invalidates the current installed receipt; a historical receipt can never drive the installed label afterward. It writes the new receipt only after the complete copy succeeds. Failure after invalidation shows `Not installed` when the destination is absent and `Unknown` when an incomplete directory exists. It does not track or preserve local drift, merge changes, create a backup, request an override, or maintain transaction/recovery state. Ephemeral cleanup is best-effort and never blocks a later Update. Legacy recovery evidence under `Library/GameForgeIntelligence/` remains untouched and cannot block use or Update.

The manifest-selected `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` is the normative owner of this source, replacement, and consumption boundary. The separate Game Forge Intelligence repository owns its plugin implementation and warning UI. No Unity plugin source lives in this repository.

## Package Map

- `AGENTS.md` - first repository entry; routes to the sibling AI router.
- `AI_READ_FIRST.md` - second-stage local-copy and session boundary; routes to the manifest.
- `GeurtsTechniqueManifest.md` - package registry and sole resolver.
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` - technical implementation and the package's sole technical-priority owner.
- `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` - generic AI-assisted automation behaviour.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` and `GeurtsTechniques/GeurtsFolderStructureDefinition.json` - folder meaning and exact creation registry.
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` - concise native-entry setup, safe migration, and create-if-missing scaffolding.
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` - GDD discovery and maintenance boundary.
- `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` - Game Forge Intelligence notification-only availability, manual documentation-update, ownership, and consumption boundary.
- `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` - approved, hash-validated project-root `.gitignore` payload.
- `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` - chat-only response behaviour, never a coding standard.

The former `GeurtsGameForgeIntelligenceIntegrationContract.md` is only a non-normative compatibility redirect for a released consumer. The manifest selects the renamed technique only; do not load both as authorities.

## Package Tools in a Unity Project

Package scripts are present under `GeurtsGameForgeDocumentation/Tools/` and are not duplicated into project-root `Tools/`. The Folder Structure Technique still requires a separate project-owned `<ProjectRoot>/Tools/` directory for project automation and integration tooling. Always pass the Unity project root explicitly to project-mutating scripts.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/CreateGeurtsFolderStructure.ps1" -ProjectRoot "<ProjectRoot>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/UpdateGameDesignManifest.ps1" -ProjectRoot "<ProjectRoot>"
```

PowerShell 7 may use `pwsh` with the same paths and arguments. The two batch compatibility launchers also require `-ProjectRoot <UnityProjectRoot>` as their first argument.

These tools run without Game Forge Intelligence and are independent of documentation acquisition or replacement. `Update Geurts Game Forge Documentation` does not invoke them. The default manager command handles native entries only and does not implicitly create or update `Docs/GameDesign/`. GDD scaffolding and GDD manifest maintenance are separate positive opt-ins:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -IncludeGameDesignScaffolding
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -UpdateGameDesignManifest
```

Each tool's permissions and preservation boundary are owned by its manifest-selected subject technique. Generic tools must not invent project design facts, overwrite project-authored GDD, silently replace user-authored native entries, automatically delete project folders, or alter a differing project-root `.gitignore`. The separately authorized GDD maintainer may update only its bounded managed manifest index.

## Source-Repository Validation

From a source checkout, run the read-only package validator and isolated automation harness; neither command accepts or mutates a real Unity project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\ValidateGeurtsDocumentation.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\Tests\RunAutomationTests.ps1"
```

PowerShell 7 may replace `powershell` with `pwsh`. The validator checks package, registry, authority, lifecycle, schema, template, and payload rules without writing repository content. The automation harness uses guarded temporary fixtures outside the checkout and includes negative lifecycle-boundary regressions. Both commands accept `-OutputFormat Json`; `-RepositoryRoot` is an optional explicit source-checkout override.

## Supporting Documents

- `Migrations/v0.10.0.md` - non-normative transition guide for the explicit destructive manual-update model.
- `Migrations/v0.9.0.md`, `Migrations/v0.8.0.md`, and `Migrations/v0.7.0.md` - superseded historical notes; they do not define an executable current workflow.
- `Ideas/GameForgeIntelligenceIdeas.md` - non-normative historical product pointer.

## Changelog

### Target v0.10.0

- Makes this repository the explicit sole authority for all Geurts documentation and prohibits embedding or duplicating it in `com.gameforge.intelligence`.
- Replaces automatic launch-time download/installation and the transaction/recovery lifecycle with one notification-only metadata check plus an explicit `Update Geurts Game Forge Documentation` action.
- Defines the project-local copy as a detached writable snapshot that a confirmed Update destructively replaces in full.
- Makes remote-head commit inequality the sole availability signal, treats package version as display-only, and invalidates the current installed receipt at destructive mutation until complete success writes a replacement.
- Separates installed/available Geurts documentation versions from the GameForgeIntelligence plugin, integration-technique, and schema versions, with explicit missing and unknown states.
- Removes rollback, recovery journals and gates, snapshots, quarantine, last-valid state, drift preservation/override, reintegration, and plugin-managed legacy installer requirements.
- Establishes the strict replacement boundary: only `GeurtsGameForgeDocumentation` is replaceable; `Docs/GameDesign`, native entries, `.gitignore`, and every other project path remain untouched.
- Advances the Folder Structure Technique and definition together to v0.9.0 for the detached writable-copy placement while keeping the folder registry unchanged.
- Adds validator and negative-regression coverage for the manual lifecycle and source/plugin ownership boundary.

### v0.9.0

- Introduced complete-tree copying and the renamed Game Forge Intelligence technique.
- Its stateful launch-check/download, transaction, rollback, recovery, drift-preservation, and reintegration model is obsolete and must not be implemented; only the new notification metadata check remains.

### v0.8.0 and earlier

- Added the approved `.gitignore` payload, AI-first entry chain, strict technical priority model, machine-readable folders, lightweight GDD discovery, safe native-entry management, migrations, and automated validation.
- Historical notes retain provenance without runnable alternate workflows.

## Maintenance

When a package file changes, update the manifest registry and affected migrations, schemas, tests, and validator expectations in the same change. Keep native AI entries concise and preserve semantic versions. Human-facing metadata uses `Required package path` or `Required project path`; the JSON `canonicalPath` key remains only as a legacy serialized compatibility field where schema consumers require it.
