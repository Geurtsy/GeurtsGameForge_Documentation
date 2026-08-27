# Geurts Game Forge Documentation

**Version:** 0.9.0
**Status:** Draft technique package
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Documentation source repository:** `Geurtsy/GeurtsGameForge_Documentation`

## Start Here

Begin with `AGENTS.md`, then its sibling `AI_READ_FIRST.md`, then `GeurtsTechniqueManifest.md`. Do not start implementation from this README.

The manifest is the single resolver for package-file selection, versions, subject ownership, applicability, post-entry order, and cross-document conflicts. It selects every required package technique from one validated package commit. When it selects the GDD Technique, that technique uses the project-authored `Docs/GameDesign/GameDesignManifest.md` to identify relevant design facts.

## What This Repository Is

This repository is the documentation source for reusable Geurts Game Forge development techniques and package-local project automation. Game Forge Intelligence installs the complete Git-tracked source tree into a top-level Unity-project directory alongside `Assets/`, `Packages/`, and `ProjectSettings/`:

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

Those are the current Git-tracked top-level entries. The current source has zero Git-tracked hidden paths and only regular tracked files. This is a description of the present repository, not an installation allowlist; the selected Game Forge Intelligence Technique owns complete-copy and fidelity requirements.

Clone-internal metadata such as `.git/` and every non-content integration artifact is excluded. The manifest-selected Game Forge Intelligence Technique owns that integration boundary.

Project-specific game-design documentation is a separate authority domain under `<ProjectRoot>/Docs/GameDesign/`. It is never synchronized source content.

## Package Map

- `AGENTS.md` - first repository entry; routes to the sibling AI router.
- `AI_READ_FIRST.md` - second-stage local-package and session boundary; routes to the manifest.
- `GeurtsTechniqueManifest.md` - package registry and sole resolver.
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` - technical implementation and the package's sole technical-priority owner.
- `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` - generic AI-assisted automation behaviour.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` and `GeurtsTechniques/GeurtsFolderStructureDefinition.json` - folder meaning and exact creation registry.
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` - concise native-entry setup, safe migration, and create-if-missing scaffolding.
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` - GDD discovery and maintenance boundary.
- `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` - Game Forge Intelligence documentation lifecycle and compatibility boundary.
- `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` - approved, hash-validated project-root `.gitignore` payload.
- `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` - chat-only response behaviour, never a coding standard.

The former `GeurtsGameForgeIntelligenceIntegrationContract.md` is only a non-normative compatibility redirect for a released consumer. The manifest selects the renamed technique only; do not load both as authorities.

## Source and Integration Boundary

Game Forge Intelligence integration requirements are defined only by the manifest-selected Game Forge Intelligence Technique. Direct users obtain one complete source commit through ordinary Git or repository download outside a package-tool contract, and must not mix files from different commits or place clone-internal `.git/` metadata inside the Unity-project documentation container.

This repository contains documentation, schemas, templates, platform-neutral scripts, and tests. It does not contain the Game Forge Intelligence Unity plugin source, product UI, feature modes, runtime settings, or product-specific feature policy. The manifest selects the Game Forge Intelligence Technique only when that integration boundary is involved.

Every Geurts-managed native AI entry routes first to `GeurtsGameForgeDocumentation/AGENTS.md`. The optional managed region in project-root `AGENTS.md` is only a concise external-tool shim. Safe preservation, exact-fingerprint migration, backups, conflicts, and opt-out are defined by the AI Agent Setup Technique.

## Package Tools in an Installed Project

Package scripts are present under `GeurtsGameForgeDocumentation/Tools/` and are not duplicated into project-root `Tools/`. The Folder Structure Technique still requires a separate project-owned `<ProjectRoot>/Tools/` directory for project automation and integration tooling. Always pass the Unity project root explicitly to copied project-mutating scripts.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/CreateGeurtsFolderStructure.ps1" -ProjectRoot "<ProjectRoot>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/UpdateGameDesignManifest.ps1" -ProjectRoot "<ProjectRoot>"
```

PowerShell 7 may use `pwsh` with the same paths and arguments. The two batch compatibility launchers also require `-ProjectRoot <UnityProjectRoot>` as their first argument.

All listed package-tool operations run without Game Forge Intelligence and are independent of documentation acquisition or replacement. When Game Forge Intelligence applies, its selected technique owns the separate integration lifecycle.

The default manager command handles native entries only. GDD scaffolding is a separate user-authorized operation that adds `-IncludeGameDesignScaffolding`; native-entry migration never creates `Docs/GameDesign/` implicitly. GDD manifest maintenance is a third independently authorized effect using `-UpdateGameDesignManifest` or the standalone maintainer command.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -IncludeGameDesignScaffolding
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -UpdateGameDesignManifest
```

Each tool's permissions and preservation boundary are owned by its manifest-selected subject technique. In particular, no workflow may invent project design facts or overwrite user-authored GDD content, silently replace user-authored native entries, automatically delete project folders, or alter a differing project-root `.gitignore`. The separately authorized GDD maintainer may update only its bounded managed manifest index under the Game Design Documentation Technique.

Every public PowerShell tool accepts `-OutputFormat Text|Json`, reports categorized results, and returns nonzero on validation, conflict, containment, locking, dependency, or filesystem failure. Folder creation adds only definition-authorized missing folders. Native setup changes only supported managed entries by default. GDD scaffolding creates only missing scaffolds when opted in. Manifest maintenance changes only its validated managed region when separately requested. The batch launchers forward the same explicit arguments and exit code to their PowerShell tools.

## Source-Repository Validation

From a documentation source checkout, run the read-only package validator and the isolated automation harness directly; neither command accepts or mutates a real Unity project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\ValidateGeurtsDocumentation.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\Tests\RunAutomationTests.ps1"
```

PowerShell 7 may replace `powershell` with `pwsh`. The validator reads the current source checkout and reports package, registry, authority, schema, template, and payload failures without writing repository content. The automation harness creates and removes only guarded temporary Unity-project fixtures outside the checkout, reports its current pass/fail totals, and returns nonzero if any assertion or safe cleanup fails. Both commands accept `-OutputFormat Json`; `-RepositoryRoot` is an optional explicit source-checkout override, not a Unity-project input.

## Supporting Documents

- `Ideas/GameForgeIntelligenceIdeas.md` - non-normative historical product pointer.
- `Migrations/v0.9.0.md` - non-normative transition checklist from the three-entry installation to a complete content-only copy and renamed integration technique.
- `Migrations/v0.8.0.md` and `Migrations/v0.7.0.md` - historical migration context; they do not override the active manifest.

## Changelog

### Target v0.9.0

- Replaces selective three-entry synchronization with an exact copy of every Git-tracked source file at the selected commit.
- Makes `GeurtsGameForgeDocumentation/` a content-only top-level project folder and keeps integration artifacts outside it.
- Establishes copied `AGENTS.md` as the first package entry and centralizes resolution in the manifest.
- Adds generic automation guidance and selectively adapts non-conflicting engineering source material under the existing Technical Technique priorities.
- Renames and narrows the Game Forge Intelligence integration document while retaining a short legacy-path redirect.
- Assigns Game Forge Intelligence lifecycle ownership to its selected technique, retains safe Geurts-owned native-entry migration, and documents migration from existing three-entry installations.

### v0.8.0

- Added a hash-validated custom Unity `.gitignore` payload while retaining the then-current integration layout.

### v0.7.0 and earlier

- Added the AI-first entry chain, strict technical priority model, machine-readable folders, lightweight GDD discovery, safe native-entry management, migrations, and automated validation.
- Historical notes retain upgrade context without runnable alternate workflows.

## Maintenance

When a package file changes, update the manifest registry and affected migrations, schemas, tests, and validator expectations in the same change. Keep native AI entries concise and preserve semantic versions. Human-facing metadata uses `Required package path` or `Required project path`; the JSON `canonicalPath` key remains only as a legacy serialized compatibility field where schema consumers require it.
