# Geurts Game Forge Documentation

## Geurts Game Forge God brick contract

Adds the manifest-selected [brick contract](GeurtsTechniques/GeurtsBrickContract.md) and [machine-readable catalogue](GeurtsTechniques/GeurtsBrickCatalogue.json). AI-assisted Unity development must use a suitable available Geurts brick before recreating its functionality. God owns package management, lifecycle, shared contracts and settings. The current user's mandatory Odin Inspector and Quantum Console requirement supersedes older Unity companion tool exemptions. Documentation-interface implementation remains in its separately maintained repository.

God 0.1.1, the minimal Diagnostics test consumer 0.2.0 and Documentation Companion 0.5.2 are available from their merged Git sources. The catalogue pins those exact verified revisions. The later six bricks remain future work and are not listed as available releases.

**Version:** 0.11.0
**Unity target:** Unity 6.3 LTS (6000.3)
**Status:** Draft technique package
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Documentation source repository:** `Geurtsy/GeurtsGameForge_Documentation`

## Start Here

Begin with `AGENTS.md`, then its sibling `AI_READ_FIRST.md`, then `GeurtsTechniqueManifest.md`. Do not start implementation from this README.

The manifest is the single resolver for package-file selection, versions, subject ownership, applicability, post-entry order, and cross-document conflicts. It selects every required technique from one validated source checkout or project-local fetched copy. When it selects the GDD Technique, that technique uses the project-authored `Docs/GameDesign/GameDesignManifest.md` to identify relevant design facts.

## Unity Target

New and modified Unity code and examples target **Unity 6.3 LTS (6000.3)**. The manifest-selected [Technical Technique](GeurtsTechniques/GeurtsTechnicalTechnique.md#unity-63-lts-compatibility-baseline) owns Editor patch selection, compatible stable dependencies, C#/.NET limits, current APIs, migration checks, and validation requirements. Follow that baseline when updating consuming projects; newer Unity release lines do not silently change this target.

Within its declared implementation scope, the Technical Technique requires licensed, Unity 6.3-compatible Odin Inspector and Quantum Console dependencies and requires meaningful use of their authoring, validation, inspection, command, logging, and diagnostics capabilities. Missing dependencies are implementation blockers. The manifest-selected Brick Contract extends that requirement to the independent Documentation Companion; this documentation source repository contains no commercial tool assets.

This repository contains documentation, C# fragments, and host-side PowerShell utilities. It contains no Unity project or companion implementation. Its checks validate the documentation package and tools; actual Unity compilation and player compatibility must be verified in the consuming project. The package remains the v0.11.0 draft; the Technical Technique advances independently to v0.9.0.

## Source and Ownership Boundary

This repository and its `main` branch are the sole primary source and authority for all generic Geurts Game Forge documentation. All Geurts techniques are sourced, versioned, and updated here. The separate Editor-only Geurts Documentation Companion consumes this repository but does not own or embed its content. A documentation release requires a companion-package release only when the machine-readable contract schema itself changes incompatibly.

The relevant locations have different owners:

| Location | Meaning and owner |
|---|---|
| `Geurtsy/GeurtsGameForge_Documentation` | Authoritative source for all Geurts Game Forge documentation. |
| `<ProjectRoot>/GeurtsGameForgeDocumentation/` | Detached, archive-sourced project-local snapshot managed as logically read-only content. A confirmed companion Update replaces it completely. |
| `Geurtsy/com.geurts.gameforge.documentation` | Owns the Windows-only, Editor-only Unity Package Manager implementation, package metadata, and companion-specific documentation. No companion code lives here. It has no Geurts Game Forge God or Game Forge Intelligence dependency. |
| The four project AI-route targets declared in `GeurtsDocumentationCompanionContract.json` | Whole files managed by the companion. One confirmation explicitly authorizes replacement from the four documentation-owned templates. |
| `<ProjectRoot>/Docs/GameDesign/` | Project-authored game-design authority. The companion must not inspect or change it. |
| Game Forge Intelligence | A separate optional product with a frozen v2 compatibility technique. Its historical documentation updater is superseded and it is not required by the companion. |

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

Those are the current tracked top-level entries, not an installation allowlist. The selected Git tree defines the complete content set. The managed copy contains no `.git` metadata or continuing repository, worktree, branch, remote, or synchronization connection. Logical read-only status is an ownership rule rather than a Windows file-attribute requirement: local edits are unsupported and the next confirmed Update discards them without drift inspection or preservation.

## Independent Unity Editor Companion

The Windows-only, Editor-only companion is installed into an existing Unity project from its separate Git repository through Unity Package Manager. That is the only companion installation mechanism. It requires licensed Odin Inspector and Quantum Console installations. There is no external installer, Windows bootstrap, batch-driven setup, separate setup action, or dependency on Geurts Game Forge God or Game Forge Intelligence.

After importing the licensed tools, in Unity Package Manager choose **Add package from Git URL** and use the companion repository's merged Windows package source:

```text
https://github.com/Geurtsy/com.geurts.gameforge.documentation.git#main
```

On each normal Unity project launch or open, the companion may perform at most one remote metadata-only request for the authoritative repository's current `main` head commit and compare it with a companion-owned last-successful commit value scoped to that Unity project and stored outside the project and installed package. One project's value must never suppress another project's update signal. The check must not download an archive, inspect the managed documentation folder or AI routes, mutate the project, execute setup work, or synchronize content. A skipped or failed check is non-blocking. Ordinary AI/session initialization performs no additional remote check.

The UI exposes one action labelled `Update Geurts Game Forge Documentation`. Selecting it immediately shows one confirmation dialog, with Cancel as the initially focused default. There is no earlier preview or dry run and no second confirmation. Cancelling or dismissing the dialog causes no network or filesystem change from the Update action.

The confirmation lists all five destructive targets: the complete `GeurtsGameForgeDocumentation/` folder and these four whole files:

```text
AGENTS.md
.github/copilot-instructions.md
.github/instructions/geurts-unity.instructions.md
.github/instructions/geurts-game-design.instructions.md
```

It states that every local change in those five targets will be overwritten and lost, there is no backup or rollback, and `Docs/GameDesign/` plus every unlisted project path will not be accessed or changed. Approval applies only to that closed set; the companion does not scan for other AI configuration.

After confirmation, the companion resolves the exact current `main` head commit, downloads an archive pinned to that commit outside the Unity project, and performs the basic validation required by `GeurtsTechniques/GeurtsDocumentationCompanionContract.json`. Only a complete valid candidate may proceed. It then replaces the complete documentation destination and writes each AI route from its exact mapped source template in that same archive. It may create only `.github/` and `.github/instructions/` when needed as parents for the listed routes. It never runs a repository or project script.

Update succeeds only when the complete documentation folder and all four route files are present and complete. The per-project comparison commit is then written on a best-effort basis; a storage failure produces a warning and may make the same Update appear available again, but it does not undo or reclassify the successful five-target replacement. A managed-target failure may leave a partial result and must be reported plainly; the user may retry only through another explicit Update and the same confirmation. There is no preview, dry run, backup, rollback, journal, recovery, migration, drift-preservation, or setup-plan engine.

All four route files tell agents to read `GeurtsGameForgeDocumentation/AGENTS.md` before planning or modifying any Geurts Game Forge brick code and to treat the installed, manifest-selected documentation as the source of truth for that work. They help only AI tools that support those native instruction surfaces or have been explicitly told to read and follow `AGENTS.md`; neither the documentation nor the companion can force every AI product to discover or obey them automatically.

The manifest-selected `GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md` owns this lifecycle, and `GeurtsTechniques/GeurtsDocumentationCompanionContract.json` owns its exact machine-readable source, destination, validation entries, confirmation targets, and route mappings. The companion implementation lives only in its separate package repository.

## Package Map

- `AGENTS.md` - first repository entry; routes to the sibling AI router.
- `AI_READ_FIRST.md` - second-stage local-copy and session boundary; routes to the manifest.
- `GeurtsTechniqueManifest.md` - package registry and sole resolver.
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` - technical implementation and the package's sole technical-priority owner.
- `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` - generic AI-assisted automation behaviour.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` and `GeurtsTechniques/GeurtsFolderStructureDefinition.json` - folder meaning and exact creation registry.
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` - exact companion AI routes and whole-file replacement exception, plus separate preservation-based manual tooling.
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` - GDD discovery, maintenance, and companion no-access boundary.
- `GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md` and `GeurtsTechniques/GeurtsDocumentationCompanionContract.json` - independent Windows-only, Editor-only UPM lifecycle and its closed machine-readable contract.
- `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` - frozen compatibility contract for released v2 consumers; not a current documentation updater.
- `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` - approved, hash-validated project-root `.gitignore` payload.
- `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` - chat-only response behaviour, never a coding standard.

The former `GeurtsGameForgeIntelligenceIntegrationContract.md` is only a non-normative compatibility redirect for a released consumer. The manifest may select the renamed technique only for that bounded compatibility work; neither file owns current documentation setup or Update.

## Legacy Manual Utilities (Not Companion Setup)

Package scripts remain available under `GeurtsGameForgeDocumentation/Tools/` for legacy or separately authorized generic maintenance. They are not a supported alternative for provisioning or updating companion-managed documentation or AI routes in a companion project. Such a project uses only Unity Package Manager to install the companion and its confirmed in-Editor Update for those five targets. The scripts are inert documentation-package content, are not duplicated into project-root `Tools/`, and are not part of companion installation, setup, or Update. The companion must not scan for or execute `.bat`, `.cmd`, `.ps1`, or any other script. Always pass the Unity project root explicitly when deliberately invoking a project-mutating legacy utility outside that lifecycle.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/CreateGeurtsFolderStructure.ps1" -ProjectRoot "<ProjectRoot>"
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/UpdateGameDesignManifest.ps1" -ProjectRoot "<ProjectRoot>"
```

PowerShell 7 may use `pwsh` with the same paths and arguments. Retained batch files are legacy compatibility launchers for separately chosen manual operations; they are not external installers or bootstraps.

These utilities run independently from the companion and from Game Forge Intelligence. `Update Geurts Game Forge Documentation` does not invoke them. The legacy manager preserves supported managed regions; unlike the companion's confirmed whole-file route replacement, it does not silently replace arbitrary user content. It does not implicitly create or update `Docs/GameDesign/`. GDD scaffolding and GDD manifest maintenance remain separate positive manual opt-ins outside the companion lifecycle:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -IncludeGameDesignScaffolding
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -UpdateGameDesignManifest
```

Each manual tool's permissions and preservation boundary are owned by its manifest-selected subject technique. Generic tools must not invent project design facts, overwrite project-authored GDD, automatically delete project folders, or alter a differing project-root `.gitignore`. The separately authorized GDD maintainer may update only its bounded managed manifest index. These manual rules do not reduce the companion's separately confirmed authority to replace its four exact whole-file routes.

## Source-Repository Validation

From a source checkout, run the read-only package validator and isolated automation harness; neither command accepts or mutates a real Unity project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\ValidateGeurtsDocumentation.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\Tests\RunAutomationTests.ps1"
```

PowerShell 7 may replace `powershell` with `pwsh`. The validator checks package, registry, authority, lifecycle, schema, template, and payload rules without writing repository content. The automation harness uses guarded temporary fixtures outside the checkout and includes negative lifecycle-boundary regressions. Both commands accept `-OutputFormat Json`; `-RepositoryRoot` is an optional explicit source-checkout override.

## Supporting Documents

- `Migrations/v0.11.0.md` - non-normative transition guide for the independent companion and closed whole-file AI-route contract.
- `Migrations/v0.10.0.md` - superseded transition guide for the Game Forge Intelligence manual-update model.
- `Migrations/v0.9.0.md`, `Migrations/v0.8.0.md`, and `Migrations/v0.7.0.md` - superseded historical notes; they do not define an executable current workflow.
- `Ideas/GameForgeIntelligenceIdeas.md` - non-normative historical product pointer.

## Changelog

### Target v0.11.0

- Establishes Unity 6.3 LTS (6000.3) as the explicit technical target, with required Odin Inspector and Quantum Console use for scoped Geurts implementation, stable compatible dependency selection, C# 9.0/.NET Standard 2.1 guidance, modern API choices, 6.3 migration checks, and honest compilation/build evidence requirements.
- Adds source validation and negative regression coverage for the Unity baseline and obsolete or unsupported C# example patterns.
- Defines the independent Windows-only, Editor-only Geurts Documentation Companion installed from Git through Unity Package Manager, with no God, Game Forge Intelligence, Odin Inspector, or Quantum Console dependency.
- Adds the schema 1.0.0 machine-readable companion contract for the authoritative source, one complete documentation destination, basic validation entries, confirmation targets, and four exact template-to-route mappings.
- Permits one metadata-only remote check at Unity open and requires one explicit in-Editor Update action with one cancel-default confirmation; there is no earlier preview, dry run, or second confirmation.
- Makes `GeurtsGameForgeDocumentation/` logically read-only managed content and authorizes confirmed complete replacement together with whole-file replacement of exactly four project AI routes.
- Removes external installer/bootstrap and script-driven setup expectations from the companion lifecycle. Existing package scripts remain optional manual tools and are never discovered or executed by the companion.
- Requires complete success across the documentation folder and all four AI routes, honest partial-failure reporting, and explicit retry without backup, rollback, journal, recovery, migration, drift preservation, or a setup-plan engine.
- Prohibits access to `Docs/GameDesign/` and every unlisted project path, and documents that AI routing works only for tools that support the routes or are instructed to follow `AGENTS.md`.
- Updates all four v1.0.0 AI-route templates so Geurts Game Forge brick work reads the installed manifest-selected documentation before planning or code changes and treats it as source of truth.
- Freezes Game Forge Intelligence 2.0.0 as released-consumer compatibility while making its historical updater non-applicable; it is not a companion dependency.

### v0.10.0

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
- Its stateful launch-check/download, transaction, rollback, recovery, drift-preservation, and reintegration model became obsolete under the v0.10.0 Game Forge Intelligence contract.

### v0.8.0 and earlier

- Added the approved `.gitignore` payload, AI-first entry chain, strict technical priority model, machine-readable folders, lightweight GDD discovery, safe native-entry management, migrations, and automated validation.
- Historical notes retain provenance without runnable alternate workflows.

## Maintenance

When a package file changes, update the manifest registry and affected migrations, schemas, tests, and validator expectations in the same change. Keep native AI entries concise and preserve semantic versions. Human-facing metadata uses `Required package path` or `Required project path`; the JSON `canonicalPath` key remains only as a legacy serialized compatibility field where schema consumers require it.
