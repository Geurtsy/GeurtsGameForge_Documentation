<!-- GEURTS-AUDIENCE: HUMAN-ONLY -->
# Geurts Game Forge Documentation

## Geurts Game Forge God brick contract

Adds the manifest-selected [brick contract](GeurtsTechniques/GeurtsBrickContract.md) and [machine-readable catalogue](GeurtsTechniques/GeurtsBrickCatalogue.json). AI-assisted Unity development must use a suitable available Geurts brick before recreating its functionality. God owns package management, lifecycle, shared contracts and settings. God, dependent bricks and the optional Documentation Companion require separately installed licensed Odin Inspector and Quantum Console assemblies. The companion remains independent without God or other Unity Package Manager package dependencies. Documentation-interface implementation remains in its separately maintained repository.

God is maintained in its own [com.geurts.gameforge.god repository](https://github.com/Geurtsy/com.geurts.gameforge.god). The catalogue publishes five immutable package sources: **God 0.14.0**, **Scene Loading and Bootstrap 0.1.3**, **Documentation Companion 0.9.2**, **Diagnostics 0.6.1** and the **User Interface Foundations 0.1.2 preview**. God 0.11.0 removes the Developer Mode option, banner, red outline and mode-specific catalogue and local-source controls. Use Unity Package Manager to install packages from disk for development. God 0.14.0 keeps the complete Activity panel pinned above the scrolling dashboard, including current phases and details, operation results, history and available actions. Status text stays on the left beside a larger animated forge on the right. It retains optional scene-startup and shared gameplay-input cooperation, God-first installation and optional Documentation integration. Scene Loading and Bootstrap 0.1.3 and Diagnostics 0.6.1 require God 0.14.0 for the shared window opener. Four catalogue entries remain **Planned**: Settings System; Save and Load; Audio; Object Pooling. These planned entries have no release version or installation source and do not represent published packages.

[User Interface Foundations 0.1.2](https://github.com/Geurtsy/com.geurts.gameforge.userinterface) provides editable UI Toolkit main and pause menus, modal navigation, shared colors and fonts, approved player appearance choices with immediate saving and Reset, and automatic persistence of supported source-asset authoring during Play. Version 0.1.1 fixes approved heading, body and button font choices that previously left text unchanged under Unity themes. Its initial input scope is mouse and keyboard. God 0.14.0 is its only required Geurts brick; Unity Input System 1.20.0, uGUI 2.0.0 and separately licensed Odin Inspector and Quantum Console are also required. Peer bricks remain optional. This remains a preview: native input and visual acceptance remain pending, as recorded in its [validation checkpoint](https://github.com/Geurtsy/com.geurts.gameforge.userinterface/blob/main/Documentation~/Validation.md). The separate repository is private and requires Git access. Refresh the catalogue in Game Forge God to check availability, then install or update through its package controls. Catalogue publication does not install the package into an existing Unity project.

God 0.14.0 and standalone Diagnostics 0.6.1 follow the shared logging and session contracts governed by the [Diagnostics Technique](GeurtsTechniques/GeurtsDiagnosticsTechnique.md). Diagnostics retains the resizable performance overlay with a font-safe ASCII resize grip and formats Help so every command name has its own line with indented details. Its Editor window and owned inspectors reuse God's shared theme; install or update God to 0.14.0 or newer before Diagnostics 0.6.1.

God 0.12.0 adds **Installed Brick Menus**. Only installed packages appear, including disabled bricks and packages missing from the catalogue. God's entry opens Build Forge; Documentation, Diagnostics and Scene Loading open their existing windows. Every other installed brick has an Information page, and missing or failed menus also show information with an explanation. New bricks can supply a primary Editor opener with `BrickEditorMenuAttribute`, requiring God 0.12.0 or newer. The [Brick Contract](GeurtsTechniques/GeurtsBrickContract.md#installed-brick-menus) defines the registration, fallback and installation checks without adding optional package dependencies.

[Scene Loading and Bootstrap](https://github.com/Geurtsy/com.geurts.gameforge.sceneloading) provides persistent bootstrap-first startup, scene groups, unload-before-replacement and additive operations, configurable transitions and loading screens, scene-readiness hooks, and retry/safe-scene recovery. Editor Play loads bootstrap before gameplay scenes; temporary copies preserve dirty or untitled originals, and stopping Play restores the original Editor scene arrangement. Copies use different runtime paths, so path-sensitive code should use the brick's logical scene identity. Multiplayer integration points are framework-independent; a concrete networking adapter is not included. Install God 0.10.0 first, then use this brick's exact catalogue source. The repository is private, so Git access to it is required.

Scene Loading and Bootstrap 0.1.2 adds Odin file pickers filtered to Unity scene files for the bootstrap scene, destination scene lists and main scene, and per-scene presentation overrides. Selections retain project-relative paths with forward slashes and the `.unity` extension; existing saved paths remain compatible.

Diagnostics 0.6.0 separates runtime Quantum Console **Channel** (Player/Developer), **Window controls** (Fullscreen/Restore), **Views** and **Logs** actions, with dark surfaces and green interaction accents. Views are Logs, Filters, Health, Inspect, Metrics, History and Session; the renamed Filters and Metrics controls retain their existing topic/severity and overlay behavior. Fullscreen keeps native zoom available, and Restore returns to the previous window layout within the current display. Audience classification, command permissions and the separate Editor-only theme standard remain unchanged.

Diagnostics 0.6.0 includes **Background transparency** in Metrics and the same saved preference in Odin settings: 0% is solid, 100% is clear, and the 12% default preserves the previous appearance. Only the overlay background fades; text and movement/resize handles retain their opacity. Layout reset leaves transparency unchanged.

Diagnostics 0.6.0 adds **Select text** / **Exit selection** to runtime and Editor Logs. Select and copy across the current loaded page with pointer/Shift selection and Ctrl+A/C while capture continues; the snapshot is read-only and clears when its display scope changes. Ctrl+V remains in the existing runtime command input without automatically executing pasted text. Runtime selection refuses pages exceeding 12,000 rendered visual lines and explains how to reduce the loaded page or collapse details; this renderer guard does not limit Editor selection or retained history.

Game Forge God distinguishes **Planned**, **Available** and **Installed** independently of update status. `released: false` marks an unreleased catalogue entry; `released: true` marks a published release. Installed is determined from the actual Unity project. Unreleased entries carry no installation actions or update checks. Their package identifiers reserve catalogue identities; release versions, sources and verified compatibility are selected when the packages are implemented and published.

**Version:** 0.23.0
**Unity target:** Unity 6.3 LTS (6000.3)
**Status:** Draft technique package
**Primary audience:** Human developers
**Secondary audience:** AI maintaining the documentation source
**Documentation source repository:** `Geurtsy/GeurtsGameForge_Documentation`

## Installing God or switching an existing installation

Import licensed Odin Inspector and Quantum Console, then install God 0.14.0 through Unity Package Manager. Documentation is optional and does not need to be installed first. Select **Add package from Git URL** and use God's verified exact `source` from the [current catalogue](GeurtsTechniques/GeurtsBrickCatalogue.json). God is the package at its repository root, so its source has no `?path=/Packages/...` suffix. The package identifier, assembly names and asset GUIDs remain unchanged.

Open **Game Forge God** to install the Documentation Companion from its package card. Package **Update** updates the Unity companion; **Update Geurts Game Forge Documentation** separately installs or replaces the actual `GeurtsGameForgeDocumentation/` content through the companion. The content action keeps the companion's one cancel-default confirmation covering the documentation folder and three AI routes. Updating a package or selecting package **Update All** does not silently replace documentation content. If a compatible companion is missing, the interface explains which package to install or update. God remains usable without it.

Each brick opens its own larger Editor window, including Game Forge God, Build Forge, Documentation, Diagnostics, Scene Loading and User Interface Foundations. New floating windows target 1000 × 760 Editor points, reduced to fit the main Editor area where space permits, and remain resizable and dockable. Each supported minimum stays in force, so a smaller main Editor area may not fully contain the window. Opening an existing window preserves its size, position and docking layout. The independent Documentation Companion retains no God dependency.

All catalogue entries and the main **Dependencies** section start collapsed. Click a catalogue heading or arrow to expand or collapse that card independently. Collapsed cards keep the package name, installation/lifecycle state and update status visible; expand a card to view its details and package actions. Each window retains its expansion choices through searches, filters, catalogue refreshes and script reloads.

The larger forge icon retains its clean silhouette without a decorative outline. It puffs smoke and bounces gently during active work, then rests when work ends. The pinned Activity panel describes actual changing phases and useful details on the left, with operation results, history and available actions kept in the same panel. The animation is an activity indicator rather than a completion percentage; phases and percentages are shown only when supplied by the underlying operation.

Existing immutable pins to God in `Geurtsy/GeurtsGameForge` remain valid in that repository's history. Existing clients check the Git repository from which they were installed and do not automatically cross repository boundaries; refreshing the catalogue alone does not switch that source. Switch an existing installation once through Unity Package Manager using the verified exact catalogue source, then verify the resolved identity, version and commit from `Geurtsy/com.geurts.gameforge.god`. God 0.7.1 and earlier retain their historical Documentation dependency until upgraded.

## Audience tags

Documentation now labels material as **AI-READ**, **HUMAN-ONLY**, or **FORGE-DEVELOPMENT-ONLY**. AI reads shared rules, skips human walkthroughs and history, and includes Forge implementation details only when developing Forge itself. Making a game with Forge stays in GameUse mode. The manifest defines the tags and the bundled read-only section reader; no AI tool is assumed to obey tags automatically. Humans can read every section normally.

## Start Here

Begin with `AI_READ_FIRST.md`, then `GeurtsTechniqueManifest.md`. Do not start implementation from this README.

The manifest is the single resolver for package-file selection, versions, subject ownership, applicability, post-entry order, and cross-document conflicts. It selects every required technique from one validated source checkout or project-local fetched copy. When it selects the GDD Technique, that technique uses the project-authored `Docs/GameDesign/GameDesignManifest.md` to identify relevant design facts.

## Unity Target

New and modified Unity code and examples target **Unity 6.3 LTS (6000.3)**. The manifest-selected [Technical Technique](GeurtsTechniques/GeurtsTechnicalTechnique.md#unity-63-lts-compatibility-baseline) owns Editor patch selection, compatible stable dependencies, C#/.NET limits, current APIs, migration checks, and validation requirements. Follow that baseline when updating consuming projects; newer Unity release lines do not silently change this target.

Within its declared implementation scope, the Technical Technique requires licensed, Unity 6.3-compatible Odin Inspector and Quantum Console dependencies and requires meaningful use of their authoring, validation, inspection, command, logging, and diagnostics capabilities. Missing dependencies are implementation blockers. The independent Documentation Companion also requires these separately installed licensed assemblies while retaining no God or other Unity Package Manager package dependency; this documentation source repository contains no commercial tool assets.

This repository contains documentation, C# fragments, and host-side PowerShell utilities. It contains no Unity project or companion implementation. Its checks validate the documentation package and tools; actual Unity compilation and player compatibility must be verified in the consuming project. The package remains the v0.23.0 draft; the Technical Technique is v0.12.9.

## Mandatory Forge Editor theme

The [Editor UI Theme Technique](GeurtsTechniques/GeurtsEditorUIThemeTechnique.md) makes the dark sci-fi theme with green accents mandatory for every existing and future Forge brick's Editor UI. It covers Game Forge God, Build Forge, Diagnostics, Documentation, settings and custom inspector presentation. Shared surfaces, typography, spacing, focus states and readable status messages keep the interface consistent; warnings stay yellow, errors stay red, and disabled actions explain the reason and next step.

God owns the shared `ForgeEditorTheme` API and USS. Dependent bricks reuse them; the independent Documentation Companion uses a generated copy checked for parity without depending on God. New custom Editor UI retains the UI Toolkit standard and existing Odin configuration remains supported. Runtime and project-authored game UI are outside this Editor-only theme. Source validators check the documented standard and its routes; actual visual review and behavior checks remain required before publication.

## Source and Ownership Boundary

This repository and its `main` branch are the sole primary source and authority for all generic Geurts Game Forge documentation. All Geurts techniques are sourced, versioned, and updated here. The separate Editor-only Geurts Documentation Companion consumes this repository but does not own or embed its content. A documentation release requires a companion-package release only when the machine-readable contract schema itself changes incompatibly.

The relevant locations have different owners:

| Location | Meaning and owner |
|---|---|
| `Geurtsy/GeurtsGameForge_Documentation` | Authoritative source for all Geurts Game Forge documentation. |
| `<ProjectRoot>/GeurtsGameForgeDocumentation/` | Detached, archive-sourced project-local snapshot managed as logically read-only content. A confirmed companion Update replaces it completely. |
| `Geurtsy/com.geurts.gameforge.documentation` | Owns the Windows-only, Editor-only Unity Package Manager implementation, package metadata, and companion-specific documentation. No companion code lives here. It has no Geurts Game Forge God or Game Forge Intelligence dependency. |
| The three project AI-route targets declared in `GeurtsDocumentationCompanionContract.json` | Whole files managed by the companion. One confirmation explicitly authorizes replacement from the three documentation-owned templates. |
| `<ProjectRoot>/Docs/GameDesign/` | Project-authored game-design authority. The companion must not inspect or change it. |
| Game Forge Intelligence | A separate optional product with a frozen v2 compatibility technique. Its historical documentation updater is superseded and it is not required by the companion. |

The project-local fetched copy contains the complete supported Git-tracked source tree from one selected `main` commit:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
â”œâ”€â”€ AI_READ_FIRST.md
â”œâ”€â”€ GeurtsTechniqueManifest.md
â”œâ”€â”€ GeurtsTechniques/
â”œâ”€â”€ Ideas/
â”œâ”€â”€ Migrations/
â”œâ”€â”€ README.md
â””â”€â”€ Tools/
```

Those are the current tracked top-level entries, not an installation allowlist. The selected Git tree defines the complete content set. The managed copy contains no `.git` metadata or continuing repository, worktree, branch, remote, or synchronization connection. Logical read-only status is an ownership rule rather than a Windows file-attribute requirement: local edits are unsupported and the next confirmed Update discards them without drift inspection or preservation.

## Independent Unity Editor Companion

The Windows-only, Editor-only companion is installed into an existing Unity project from its separate Git repository through Unity Package Manager, either directly or through Game Forge God's package card. That is the only companion installation mechanism. It requires licensed Odin Inspector and Quantum Console installations. There is no external installer, Windows bootstrap, batch-driven setup, separate setup action, or dependency on Geurts Game Forge God or Game Forge Intelligence.

After importing the licensed tools, in Unity Package Manager choose **Add package from Git URL** and use the companion repository's merged Windows package source:

```text
https://github.com/Geurtsy/com.geurts.gameforge.documentation.git#main
```

On each normal Unity project launch or open, the companion may perform at most one remote metadata-only request for the authoritative repository's current `main` head commit and compare it with a companion-owned last-successful commit value scoped to that Unity project and stored outside the project and installed package. One project's value must never suppress another project's update signal. The check must not download an archive, inspect the managed documentation folder or AI routes, mutate the project, execute setup work, or synchronize content. A skipped or failed check is non-blocking. Ordinary AI/session initialization performs no additional remote check.

The UI exposes one action labelled `Update Geurts Game Forge Documentation`. Selecting it immediately shows one confirmation dialog, with Cancel as the initially focused default. There is no earlier preview or dry run and no second confirmation. Cancelling or dismissing the dialog causes no network or filesystem change from the Update action.

The confirmation lists all four destructive targets: the complete `GeurtsGameForgeDocumentation/` folder and these three whole files:

```text
.github/copilot-instructions.md
.github/instructions/geurts-unity.instructions.md
.github/instructions/geurts-game-design.instructions.md
```

It states that every local change in those four targets will be overwritten and lost, there is no backup or rollback, and `Docs/GameDesign/` plus every unlisted project path will not be accessed or changed. Approval applies only to that closed set; the companion does not scan for other AI configuration.

After confirmation, the companion resolves the exact current `main` head commit, downloads an archive pinned to that commit outside the Unity project, and performs the basic validation required by `GeurtsTechniques/GeurtsDocumentationCompanionContract.json`. Only a complete valid candidate may proceed. It then replaces the complete documentation destination and writes each AI route from its exact mapped source template in that same archive. It may create only `.github/` and `.github/instructions/` when needed as parents for the listed routes. It never runs a repository or project script.

Update succeeds only when the complete documentation folder and all three route files are present and complete. The per-project comparison commit is then written on a best-effort basis; a storage failure produces a warning and may make the same Update appear available again, but it does not undo or reclassify the successful four-target replacement. A managed-target failure may leave a partial result and must be reported plainly; the user may retry only through another explicit Update and the same confirmation. There is no preview, dry run, backup, rollback, journal, recovery, migration, drift-preservation, or setup-plan engine.

All three route files tell agents to read `GeurtsGameForgeDocumentation/AI_READ_FIRST.md` before planning or modifying any Geurts Game Forge brick code and to treat the installed, manifest-selected documentation as the source of truth for that work. They help only AI tools that support those native instruction surfaces or have been explicitly told to read and follow `AI_READ_FIRST.md`; neither the documentation nor the companion can force every AI product to discover or obey them automatically.

The manifest-selected `GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md` owns this lifecycle, and `GeurtsTechniques/GeurtsDocumentationCompanionContract.json` owns its exact machine-readable source, destination, validation entries, confirmation targets, and route mappings. The companion implementation lives only in its separate package repository.

## Package Map

- `AI_READ_FIRST.md` - first-entry local-copy and session boundary; routes to the manifest.
- `GeurtsTechniqueManifest.md` - package registry and sole resolver.
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` - technical implementation and the package's sole technical-priority owner.
- `GeurtsTechniques/GeurtsEditorUIThemeTechnique.md` - mandatory dark sci-fi and green-accent presentation for every existing and future Forge Editor UI, shared implementation and visual conformance.
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

Package scripts remain available under `GeurtsGameForgeDocumentation/Tools/` for legacy or separately authorized generic maintenance. They are not a supported alternative for provisioning or updating companion-managed documentation or AI routes in a companion project. Such a project uses only Unity Package Manager to install the companion and its confirmed in-Editor Update for those four targets. The scripts are inert documentation-package content, are not duplicated into project-root `Tools/`, and are not part of companion installation, setup, or Update. The companion must not scan for or execute `.bat`, `.cmd`, `.ps1`, or any other script. Always pass the Unity project root explicitly when deliberately invoking a project-mutating legacy utility outside that lifecycle.

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

Each manual tool's permissions and preservation boundary are owned by its manifest-selected subject technique. Generic tools must not invent project design facts, overwrite project-authored GDD, automatically delete project folders, or alter a differing project-root `.gitignore`. The separately authorized GDD maintainer may update only its bounded managed manifest index. These manual rules do not reduce the companion's separately confirmed authority to replace its three exact whole-file routes.

<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
## Source-Repository Validation

From a source checkout, run the read-only package validator and isolated automation harness; neither command accepts or mutates a real Unity project:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\ValidateGeurtsDocumentation.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Tools\Tests\RunAutomationTests.ps1"
```

PowerShell 7 may replace `powershell` with `pwsh`. The validator checks package, registry, authority, lifecycle, schema, template, and payload rules without writing repository content. The automation harness uses guarded temporary fixtures outside the checkout and includes negative lifecycle-boundary regressions. Both commands accept `-OutputFormat Json`; `-RepositoryRoot` is an optional explicit source-checkout override.

<!-- GEURTS-SECTION:END -->

## Supporting Documents

- `Migrations/v0.11.0.md` - non-normative transition guide for the independent companion and closed whole-file AI-route contract.
- `Migrations/v0.11.0.md` - superseded transition guide for the Game Forge Intelligence manual-update model.
- `Migrations/v0.9.0.md`, `Migrations/v0.8.0.md`, and `Migrations/v0.7.0.md` - superseded historical notes; they do not define an executable current workflow.
- `Ideas/GameForgeIntelligenceIdeas.md` - non-normative historical product pointer.

## Codex guide installation

The current verified companion package is 0.9.2; use its immutable source from the catalogue. In Geurts Documentation, select **Install Codex guide**, choose a location and confirm the displayed entry point. The installer creates AGENTS.md for automatic Codex discovery. The template exists only in GeurtsAgentTechnique.md. Normal documentation updates do not manage a root Codex guide; replace an old guide by selecting its location in the installer. The content-update contract remains schema 2.0.0.

## Changelog

### v0.23.0 — Larger separate brick windows

- Adds Theme Technique 1.2.0 guidance for the shared larger primary-window opener: prefer 1000 × 760 Editor points fitted to the main Editor area where space permits, give each supported minimum precedence and preserve existing or docked layouts.
- Updates the catalogue to God 0.14.0, Documentation Companion 0.9.2, Diagnostics 0.6.1, Scene Loading and Bootstrap 0.1.3 and User Interface Foundations 0.1.2. Dependent packages using the new API require God 0.14.0; Documentation remains independent.
- Advances Technical to 0.12.9, Diagnostics to 0.3.8, Documentation Companion Technique to 2.1.2 and AI Agent Setup to 2.0.2 for their current release references. Theme colors, runtime UI, package operations, confirmation rules, the installed-menu API minimum, schemas and historical releases remain unchanged.

### v0.22.8 — Fold catalogue entries and Dependencies by default

- Updates the God catalogue release to 0.13.2. All brick catalogue cards and the main Dependencies section start collapsed, with individual expansion available when their details or actions are needed.
- Retains visible card names and status summaries, independent expansion choices, the pinned Activity panel and existing package operation behavior.
- Advances Technical to 0.12.8 and Diagnostics to 0.3.7 only for their current God baseline references. Brick Contract, theme rules, minimum API versions, other catalogue sources, schemas and historical releases are unchanged.

### v0.22.7 — Collapsible catalogue entries

- Updates the God catalogue release to 0.13.1. Each catalogue card expands and collapses independently, keeping its package name and status summaries visible while collapsed and showing details and package actions when expanded.
- Preserves the pinned Activity panel, installed brick menus, package operation behavior and confirmation boundaries.
- Advances Technical to 0.12.7 and Diagnostics to 0.3.6 only for their current God baseline references. Brick Contract, theme rules, minimum API versions, other catalogue sources, schemas and historical releases are unchanged.

### v0.22.6 — Keep the complete Activity panel pinned

- Updates the God catalogue release to 0.13.0. The complete Activity panel stays above the scrolling dashboard, including current phase details, operation results, history and available actions, with text on the left and a larger animated forge on the right.
- Advances Brick Contract to 1.6.3 for the pinned panel and changing, truthful operation descriptions. The clean icon without a decorative outline, smoke puffs, gentle bounce, resting state and animation cleanup rules remain unchanged.
- Advances Technical to 0.12.6 and Diagnostics to 0.3.5 only for their current God baseline references. Preserves User Interface Foundations 0.1.1, the other catalogue sources, minimum API versions, theme tokens, optional dependencies, contract schemas and historical releases.

### v0.22.5 — Correct User Interface font choices

- Updates User Interface Foundations to 0.1.1 with an immutable Git source for Game Forge God installation and updates.
- Records the fix for approved heading, body and button font choices being overridden by Unity theme font definitions; Reset restores the project defaults. Native input and visual acceptance remain pending for this preview.
- Synchronizes documentation package metadata at 0.22.5 while preserving God 0.12.2, the other eight catalogue entries, five released and four planned packages, generic technique rules, managed payloads and historical releases.

### v0.22.4 — Publish User Interface Foundations initial preview

- Publishes User Interface Foundations 0.1.0 from its separate repository using an immutable Git source, enabling Game Forge God catalogue installation and future updates. The inventory now contains five released packages and four planned entries.
- Records editable main and pause menus, modal navigation, shared appearance, immediate player preference saves and Reset, and automatic persistence of supported source-asset authoring during Play. Mouse and keyboard are the initial input scope; native input and visual validation remain pending.
- Declares God 0.12.0 as the only required Geurts brick, alongside Unity Input System 1.20.0, uGUI 2.0.0 and separately licensed Odin Inspector and Quantum Console. Peer bricks remain optional.
- Synchronizes documentation package metadata at 0.22.4 while retaining God 0.12.2, all other package entries and immutable sources, generic technique rules, managed instruction payloads and historical release records.

### v0.22.3 — Clean forge icon without an outline

- Updates the God catalogue release to 0.12.2, removing the decorative outline from the compact pinned forge icon. Current activity text remains on the left and the icon remains on the right.
- Advances Brick Contract to 1.6.2 for the clean icon requirement. Smoke puffs and gentle bounce still indicate actual work; the resting frame, truthful stage text and animation cleanup rules are unchanged.
- Advances Technical to 0.12.5 and Diagnostics to 0.3.4 only for their current God baseline references. Theme tokens, installed brick menu rules and minimum API versions, optional dependencies, contract schemas and other catalogue pins are unchanged.

### v0.22.2 — Compact pinned forge activity

- Updates the God catalogue release to 0.12.1. A single compact animated forge remains pinned above the dashboard, with current activity text on the left and the outlined icon on the right; the large dashboard furnace and its duplicate activity label are removed.
- Records the clearer small-view forge silhouette while preserving smoke puffs and gentle bounce during actual work, the resting frame when idle and truthful operation messages.
- Advances Technical to 0.12.4 and Diagnostics to 0.3.3 only for their current God baseline references. Theme tokens, installed brick menu rules and minimum API versions, optional dependencies, contract schemas and other catalogue pins are unchanged.

### v0.22.1 — Prioritize Codex compatibility across Geurts code

- Requires all first-party Geurts code to support efficient Codex authoring through clear supported interfaces, predictable structure, discoverable configuration, useful examples, documentation and repeatable checks, within the existing technical priorities and multiplayer override.
- Makes extendibility-first priorities and Codex compatibility apply explicitly to every brick and all first-party code Codex creates or materially updates while following Forge documentation, including ordinary project-specific/game code; the narrower reusable-framework compliance header remains unchanged.
- Requires all existing and future bricks to be designed and maintained with Codex in mind. Codex and other AI agents proactively inspect and reuse suitable available bricks, explaining concrete capability gaps or incompatibilities before custom substitutes.
- Keeps God as the shared required Geurts brick, peer integrations optional and the Documentation Companion independent. No live connector, Codex runtime dependency, plugin installation, source-code implementation or completed audit of all existing components is implied.
- Advances Technical to 0.12.3 and Brick Contract to 1.6.1, selects brick guidance during planning and synchronizes package metadata at 0.22.1. Published brick versions and contract schemas are unchanged.

### v0.22.0 — Installed brick menus

- Publishes God 0.12.0 with an Installed Brick Menus section, existing primary-window routes and a shared information fallback for every installed brick. Disabled and uncatalogued installed packages remain accessible; uninstalled packages are hidden.
- Advances Brick Contract to 1.6.0 with the Editor-only `BrickEditorMenuAttribute` registration contract, minimum God 0.12.0 for new providers, safe missing/failed-menu behavior and actual installation rechecks. Executable routes come from local code, never remote catalogue fields.
- Updates Technical to 0.12.2 and Diagnostics to 0.3.2 only for their current God baseline references. Existing optional-dependency boundaries, Developer Mode removal, Editor theme, companion schema 2.0.0, folder definition 0.11.0 and other package pins remain unchanged.

### v0.21.0 — Remove Game Forge God's Developer Mode

- Updates God to 0.11.0, removing its Developer Mode toggle, persistent warning banner, red outline and mode-specific test-catalogue and local-source controls. Use Unity Package Manager to install packages from disk for development.
- Retains published update checks for installed local packages, explicit overwrite warnings, cancellation, Git metadata preservation and protection for every path outside the named package folder.
- Advances Brick Contract to 1.5.0 and Editor UI Theme to 1.1.0 for the revised package-development and presentation rules. Technical 0.12.1 and Diagnostics 0.3.1 remove obsolete God-mode cross-references; Diagnostics' Player/Developer tabs and restricted testing override retain their existing contracts.
- Keeps Scene Loading and Bootstrap 0.1.2, Documentation Companion 0.9.1 and Diagnostics 0.6.0 pins, dependency minimums and contract schemas unchanged. Catalogue publication does not install or update packages or documentation in an existing Unity project.

### v0.20.3 — Keep Game Forge God activity visible while scrolling

- Updates the God catalogue release to 0.10.1, with current activity text pinned at the top left and the existing animated forge on the right while the package list scrolls below.
- Keeps Scene Loading and Bootstrap 0.1.2, Documentation Companion 0.9.1 and Diagnostics 0.6.0 pins and dependency minimums unchanged. Synchronizes documentation release metadata and tool guards without changing technique rules or contract schemas.
- Catalogue publication does not update or install packages or documentation in an existing Unity project; those remain separate explicit actions.

### v0.20.2 — Publish scene-filtered authoring pickers

- Updates Scene Loading and Bootstrap to 0.1.2 at verified immutable main commit `459a5b00a31ec1971f55f24c2cd97b085fe941b7`, with Odin scene-filtered file pickers for the bootstrap scene, destination scene lists and main scene, and per-scene presentation overrides. Paths remain project-relative with forward slashes and the `.unity` extension, and their string storage is unchanged.
- Keeps God 0.10.0, Documentation Companion 0.9.1 and Diagnostics 0.6.0 pins unchanged. Synchronizes documentation release metadata and tool guards without changing technique rules or contract schemas.

### v0.20.1 — Publish Scene Loading and Bootstrap

- Makes Scene Loading and Bootstrap 0.1.1 available in the catalogue from its standalone repository at verified immutable main commit `d0f8199ee85bdb2650fbec4206d3a289f1099bfb`, requiring God 0.10.0 and Unity 6000.3.
- Advances the God catalogue pin to verified immutable main commit `a69af957400183d52afe3f4696740c13fafd2644` for God 0.10.0, including optional scene-startup and shared gameplay-input cooperation. God remains independent of the Scene Loading package.
- Documents bootstrap-first Editor Play, preservation through temporary copies, scene identity, transitions, loading screens and recovery. Multiplayer remains framework-independent without a concrete networking adapter.
- Retains Documentation Companion 0.9.1 and Diagnostics 0.6.0 pins, all five remaining planned bricks, technique rules, companion schema 2.0.0 and folder definition 0.11.0. Synchronizes documentation release metadata and tool guards.
- Catalogue publication does not update or install packages or documentation in an existing Unity project; those remain separate explicit actions.

### v0.20.0 — Select and copy console text

- Advances Diagnostics Technique to 0.3.0 with an explicit Select text / Exit selection mode in runtime Quantum Console and the Forge Diagnostics Editor console, supporting selection across the current filtered, loaded log page and Ctrl+A/C.
- Requires a stable read-only snapshot, plain literal message text, expanded-only source/context details, continued capture independent of log pause, and clearing selection when audience, view, page, settings or service scope changes.
- Preserves native Quantum Console command-input paste without automatic execution and existing Editor clipboard destinations; adds no parallel command executor or retained-history export.
- Defines the runtime-only 12,000-rendered-line selection capacity guard, checked again after width changes, with a persistent explanation to reduce the History loaded limit or collapse expanded records; snapshots are never silently truncated.
- Publishes Diagnostics 0.6.0 in the catalogue at verified immutable main commit `ed5818781f034651ce55686f5cddade007940724`. Other package pins, Scene Loading and Bootstrap guidance, Editor theme rules and companion/folder schemas remain unchanged.
- Diagnostics validation against the local release source passed 67 EditMode and 10 PlayMode tests. Mono and IL2CPP player builds each passed 140 runtime checks with no build warnings or errors, and screenshots of selected-text highlights were visually reviewed. The published source was separately verified through remote Git. These checks are separate from this repository's documentation validation and do not claim a consuming project's Git package upgrade.
- Synchronizes documentation package metadata and tool guards for the new minor release.

### v0.19.2 — Add performance-overlay background transparency

- Advances Diagnostics Technique to 0.2.4 with a labelled Metrics transparency slider, a visible 0–100% value, a 12% default, and the same persisted Odin preference. Transparency affects only the background, retaining metric text and drag/resize-handle opacity.
- Keeps layout reset limited to sizing and position and requires endpoint, default, persistence and interaction verification.
- Publishes Diagnostics 0.5.2 in the catalogue at verified immutable main commit `dbb7e5b751546d97d52d01fdea15ec7aef6be60d`. Other package pins and Scene Loading and Bootstrap guidance remain unchanged.
- Synchronizes documentation package metadata and tool guards; companion schema 2.0.0, folder definition 0.11.0 and Editor theme rules are unchanged.

### v0.19.1 — Clarify runtime Quantum Console controls

- Advances Diagnostics Technique to 0.2.3 with separate Channel, Window, Views and Logs controls, scoped dark surfaces and green runtime accents, and focused visual and interaction validation. Views show Filters and Metrics in place of Topics and Overlay, and retain Session; Logs actions include Help.
- Documents Fullscreen/Restore within the existing Quantum Console container, native zoom and resize-grip behavior, restored geometry bounded after display shrink, and runtime height growth to retain space for logs and command input. Vendor assets, resize settings and saved Diagnostics preferences remain unchanged.
- Preserves Player/Developer classification, topic/severity filters, command and cheat/host permission checks, the existing Quantum Console integration and the separate Editor-only theme standard.
- Publishes Diagnostics 0.5.1 in the catalogue at verified immutable main commit `0f87755b178d777b5a82019ee6d54590f7708abe`. God remains 0.9.1 with Diagnostics' minimum God dependency at 0.9.0; Documentation Companion remains 0.9.1.
- Synchronizes documentation package metadata and tool guards without changing companion schema 2.0.0, folder definition 0.11.0, managed routes or Scene Loading and Bootstrap guidance.

### v0.19.0 — Make the Forge Editor theme mandatory

- Adds Editor UI Theme Technique 1.0.0 and selects it through the manifest for all existing and future Forge brick and Editor-tool presentation.
- Advances Technical to 0.12.0 and Brick Contract to 1.4.0, requiring shared God theme reuse, readable interactive states, actionable disabled explanations, semantic severity and truthful progress. Preserves Odin configuration, UI Toolkit for new custom UI and the red Developer Mode warning.
- Requires a generated, parity-checked theme copy for the independent Documentation Companion, adding no God/UPM package dependency and retaining its required licensed Odin/QC assemblies and closed content-update contract. Runtime/player and game-authored UI remain outside the Editor theme.
- Corrects stale companion tooling exemptions in Companion Technique 2.1.1, Folder 0.13.1, AI Agent Setup 2.0.1 and Game Design Documentation 0.11.1; placement, game-design authority, payloads and contract schemas are unchanged.
- Adds source routing/palette/shared-implementation validation and regression fixtures that reject missing or weakened theme guidance. Adds the theme to the companion's source-completeness entries without changing schema 2.0.0 or any managed target.
- Layers on the 0.18.0 God-first installation, optional Documentation integration, interface rename and furnace animation. Publishes verified immutable main commits for God 0.9.1, Documentation Companion 0.9.1 and Diagnostics 0.5.0; Diagnostics requires God 0.9.0.
- Advances Diagnostics Technique to 0.2.2 to record the current published implementation baseline. Runtime logging, history, console and gameplay-session contracts are unchanged.

### v0.18.0 — Install God first and manage Documentation through Game Forge God

- Removes Documentation as a required God package or assembly dependency. God stays usable without the optional companion and offers installation through its catalogue interface.
- Separates companion package updates from updates of the actual documentation content. The content action delegates to the companion and preserves its schema-2.0.0 confirmation, source and exact four-target boundary.
- Renames the package-management interface to **Game Forge God** and specifies an outlined forge with smoke-puff and bounce activity animation.
- Advances Brick Contract to 1.3.0 and Companion Technique to 2.1.0; preserves the prior Build Forge step 5 guidance, independent GDD authority, route templates, payloads and contract schemas.
- Marks God 0.8.0 as unreleased without an invented install source; keeps existing verified companion and Diagnostics pins until new releases are verified.

### v0.17.1 — Count game design context as Build Forge step 5

- Documents God 0.7.1's **Game design context** as numbered setup step **5**, after bootstrap scene preparation, and includes it in the checklist progress and **Forge ready** result.
- Requires a valid primary Game Design Document to complete step 5. Importing or changing the primary selection uses the existing Markdown import and project-manifest routing contract; missing or invalid selections remain incomplete with an actionable explanation.
- Keeps game-context authority, technical guidance, document preservation, folder permissions and contract schemas unchanged.

### v0.17.0 — Import a primary Game Design Document through Build Forge

- Publishes God 0.7.0 in the catalogue at its verified immutable release commit, including the Build Forge Markdown import and primary-document controls.

- Routes game context through the project manifest's explicit primary Markdown document while keeping technical design and implementation guidance in the Geurts documentation techniques.
- Defines Build Forge's user-selected, byte-preserving Markdown import and separately managed primary-pointer section. Existing documents, table rows and project notes remain preserved.
- Verifies that ordinary manifest maintenance preserves the primary pointer, including when source metadata names another authority or the primary document moves.
- Keeps the Documentation Companion's three-route replacement boundary, schema 2.0.0 and the existing GDD table format 0.7.0 unchanged.

### v0.16.6 — Publish God from its standalone repository

- Publishes God 0.6.4 from `Geurtsy/com.geurts.gameforge.god` at a verified immutable commit and updates its catalogue website.
- Documents the one-time Package Manager source switch for existing God installations; historical monorepo pins remain valid and existing clients do not automatically cross repository boundaries.
- Synchronizes documentation release metadata and validation expectations. Diagnostics 0.4.2, Documentation Companion 0.8.1, technique rules, folder definitions and contract schemas remain unchanged.

### v0.16.5 — Correct Build Forge completion checks

- Publishes God 0.6.3 and Documentation Companion 0.8.1 together, with the matching companion minimum dependency.
- Recognizes the approved `.gitignore` when it uses Windows CRLF or other normalized newlines, preserving its exact bytes and timestamp. Other differences remain preserved for review.
- Adds green borders to verified Build Forge steps and synchronizes release metadata and validation expectations. Diagnostics 0.4.2, technique rules, folder definitions and contract schemas remain unchanged.

### v0.16.4 — Publish Build Forge setup releases

- Publishes God 0.6.2 and Documentation Companion 0.8.0 at their verified immutable main commits so Brick Manager can offer these updates.
- Records God's Documentation Companion 0.8.0 minimum dependency for the step-by-step Build Forge setup window, verified completion ticks, shared installers and furnace presentation.
- Preserves Diagnostics 0.4.2 and its exact catalogue source. Synchronizes documentation release metadata and validator expectations without changing technique rules, folder definitions or contract schemas.

### v0.16.3 — Publish Diagnostics 0.4.2

- Publishes standalone Diagnostics 0.4.2 at its verified immutable merge commit, with each command name in `Help` on a separate line and its signature, classification, cheat requirement and description indented beneath it.
- Advances Diagnostics Technique to 0.2.1 and records the matching Help presentation contract and Diagnostics 0.4.2 implementation baseline.
- Synchronizes documentation release metadata and validator expectations. God remains 0.5.0, the companion schema remains 2.0.0, the folder definition remains 0.11.0 and the companion package remains 0.7.0.

### v0.16.2 — Publish Diagnostics 0.4.1

- Publishes standalone Diagnostics 0.4.1 at its verified immutable merge commit, replacing the unsupported Unicode resize-grip glyph with a font-safe ASCII label to prevent repeated TextMesh Pro missing-glyph warnings with Quantum Console's bundled font.
- Synchronizes documentation release metadata and validator expectations. Technique versions, folder rules and companion contract schema remain unchanged.

### v0.16.1 — Publish Diagnostics 0.4.0

- Publishes standalone Diagnostics 0.4.0 at its verified immutable merge commit so commit-pinned installations can discover and install the resizable performance overlay update.
- Synchronizes documentation release metadata and validator expectations. Technique versions, folder rules and companion contract schema remain unchanged.

### v0.16.0 — Resizable Diagnostics overlay

- Advances Diagnostics Technique to 0.2.0 with content-aware automatic sizing, persistent manual position and size, canvas clamping and reset behavior.
- Records Diagnostics 0.4.0 as a review candidate while retaining the exact merged Diagnostics 0.3.0 catalogue release until the new implementation is approved and published.
- Keeps the companion schema, managed routes, folder definition and God 0.5.0 contract unchanged.

### v0.15.0 — Diagnostics integration

- Adds Diagnostics Technique 0.1.0 and registers its logging, full all-build QC console, history, health/inspection, sticky gameplay cheat sessions and six Windows metrics contract.
- Advances Technical to 0.11.0 and Brick Contract to 1.2.0; replaces earlier console-access assumptions with explicit Player/Developer classification and a separately restricted testing override.
- Publishes immutable catalogue sources for God 0.5.0 and standalone Diagnostics 0.3.0 after their approved merges, including the God 0.5.0 minimum dependency and the standalone Diagnostics repository.
- Synchronizes package metadata and validates the host/server testing boundary. Companion schema, managed routes, folder definition and historical releases are unchanged.

### v0.14.2

- Publishes God 0.4.1 at its verified immutable release commit. Build Forge now creates scenes while preserving an open untitled scene without requiring a save or discard.
- Synchronizes documentation release metadata and validator expectations. Folder rules, technique versions and contract schemas are unchanged.

### v0.14.1

- Publishes God 0.4.0 in the brick catalogue at its verified immutable release commit.
- Adds Build Forge project setup to the God catalogue description: documented folders, required boot/development scenes, Quantum Console setup and default additive startup are implemented by the God package.
- Synchronizes documentation package metadata and validation expectations. Folder rules, definition 0.11.0 and contract schemas are unchanged.

### v0.14.0

- Requires all five scene folders: Boot, Frontend, Gameplay, Test and Sandbox, including in minimal projects.
- Requires SCN_BigBang.unity in Assets/_Project/Scenes/Boot for booting at build index 0, followed by SCN_DevPlayground.unity in Assets/_Project/Scenes/Test for initial testing at build index 1. Both must be enabled in each game Build Profile's effective scene list.
- Keeps the existing folder tool limited to creating folders; Unity scene creation and build-list configuration remain separate project-setup work that preserves existing content.
- Advances the Folder Structure Technique to 0.12.0, its definition to 0.11.0 and the Technical Technique to 0.10.0. Synchronizes package metadata and definition consumers without changing schema versions or published brick releases.

### v0.13.2

- Requires all logging throughout the entire project to route through Geurts Game Forge Diagnostics whenever a compatible logging service is available, regardless of ownership, severity or logging API.
- Covers game scripts, all bricks, Editor tools, Unity-generated messages, third-party packages, plugins, generated code and custom loggers through the central facade or required capture integrations. Uncapturable sources must be reported as integration gaps.
- Defines unavailable-service fallback, optional brick integration, preserved Unity/Quantum Console output, and protection against duplicate or recursive logging. The minimal Diagnostics 0.2.0 test consumer does not yet implement this service.
- Advances the Technical Technique to 0.9.1 and synchronizes documentation package metadata; published brick versions and pins remain unchanged.

### v0.13.1

- Updates the God catalogue release to 0.3.2, fixing the Documentation card failing to draw after a package update leaves an incomplete style cache.
- Preserves the AI audience tags, documentation reader and compatible Documentation Companion 0.7.0.

### v0.13.0

- Adds manifest-owned file and section audience tags, separating game-use guidance, human material and Forge development details.
- Adds a read-only Markdown reader that filters before loading AI context, with GameUse and ForgeDevelopment modes, explicit human-content access, and character counts.
- Validates tag syntax, preserved shared rules, literal fenced payloads, file boundaries and both reading modes. Compatibility schemas and installation template versions remain unchanged.

### v0.12.1 — Dependency readiness labels

- Publish God 0.3.1 with required external dependency boxes on the Documentation card. Loaded tools are green when Unity reports no script compilation errors.
- Preserve Documentation 0.7.0, the Codex guide installer, schema 2.0.0 and the current three-route documentation update contract.
- Synchronize the package metadata and versioned tool checks without restoring obsolete documentation entry files.

### v0.12.0

- Make AI_READ_FIRST.md the direct documentation entry point.
- Add one technique-owned Codex guide template and user-selected installation.
- Remove both deprecated AGENTS.md files and exclude Codex guides from documentation Update and the manual native-entry manager.
- Move the three Copilot routes to the direct entry point and adopt companion contract schema 2.0.0.

### v0.11.5

- Publishes God 0.3.0 with a Dependencies section for Odin Inspector, Quantum Console and project-defined Asset Store tools. Tracks installation and downloaded versions separately from current Unity-account ownership, including hidden purchases; installation uses Unity My Assets and native import choices.
- Synchronizes the exact God catalogue pin, package metadata and validator expectations while retaining Documentation Companion 0.6.1.

### v0.11.4

- Publishes Documentation Companion 0.6.1 with a dedicated Check for updates box and a larger button.
- Synchronizes the catalogue pin, documentation metadata and version expectations for this visual patch.

### v0.11.3

- Publishes Documentation Companion 0.6.0 with matching dependency status colours, owned-asset access through Unity My Assets, and interactive import of licensed package files.
- Synchronizes package metadata and validator expectations; the documentation replacement boundary stays unchanged.

### v0.11.2

- Publishes God 0.2.1: the Developer Mode header is pinned only while enabled and scrolls with the Brick Manager while disabled.
- Synchronizes documentation package metadata and validator expectations for this catalogue patch.

### v0.11.1

- Requires reading the manifest-selected documentation before work on any part of Game Forge.
- Requires an appropriate major, minor or patch version bump for every delivered update, however small, including documentation and catalogue edits.
- Defines developer-only package source switching and explicitly confirmed overwriting of local package changes in God 0.2.0.

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

<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
## Maintenance

When a package file changes, update the manifest registry and affected migrations, schemas, tests, and validator expectations in the same change. Keep native AI entries concise and preserve semantic versions. Human-facing metadata uses `Required package path` or `Required project path`; the JSON `canonicalPath` key remains only as a legacy serialized compatibility field where schema consumers require it.
<!-- GEURTS-SECTION:END -->
