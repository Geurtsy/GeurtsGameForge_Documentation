# Geurts Folder Structure Technique

**Unity Project Structure - AI-First Automation and Human Developer Reference**
**Version:** 0.7.0
**Status:** Draft supporting technique  
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Canonical path:** `GeurtsTechniques/GeurtsFolderStructureTechnique.md`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the copy in the canonical path shown above.

---

## Purpose

This document defines a stable, scalable Unity project structure for Geurts Game Forge. Its language is intentionally literal and deterministic so automated systems can make consistent placement decisions without sacrificing human readability.

The structure is optimised for:

- AI readability.
- Automation.
- Long-term team consistency.
- Fast asset discovery.
- Safe refactoring.
- Clear separation between first-party, third-party, generated, and external content.

This Markdown document is the **explanatory authority** for folder meaning, placement, and constraints. `GeurtsTechniques/GeurtsFolderStructureDefinition.json` is the **automation authority** for the literal managed-folder registry and folder creation. Neither authority may contradict the other.

The main technical rules remain in `GeurtsTechniques/GeurtsTechnicalTechnique.md`. AI agent setup files are governed by `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`. Game Forge Intelligence integration requirements are governed by `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.

If the Markdown and JSON disagree, validation must fail. An agent or tool must not guess which path to create.

---

## Design Goals

- Minimise ambiguity.
- Keep each folder's purpose singular and obvious.
- Separate source, generated, and external content.
- Support solo development and team scaling.
- Make assets easy to locate, validate, and refactor.

---

## Automation

The full project-structure profile is generated from:

```text
GeurtsTechniques/GeurtsFolderStructureDefinition.json
```

using:

```text
Tools/CreateGeurtsFolderStructure.ps1
```

`Tools/CreateGeurtsFolderStructure.bat` is a compatibility launcher. It must delegate folder selection to the PowerShell tool and must not contain an independent complete path list.

The definition has four creation profiles:

| Profile | Owner | Exact scope |
|---|---|---|
| `full-project-structure` | `folder-structure-tool` | The 67 project-structure paths historically created by the folder script. |
| `native-entry` | `native-entry-manager` | `.github` and `.github/instructions` only. |
| `gdd-scaffolding` | `native-entry-manager` | `Docs` and `Docs/GameDesign` only, as an explicit delegation from their primary folder-structure owner. |
| `documentation-sync` | `documentation-synchronizer` | `GeurtsGameForgeDocumentation` and `GeurtsGameForgeDocumentation/GeurtsTechniques` only. |

An automation tool may create a registry entry only when all of these conditions are true:

1. The entry's `automation.mayCreate` value is `true`.
2. The requested creation profile appears in `automation.creationProfiles`.
3. The calling tool is the declared `automation.owner`, or the entry's `automation.delegatedOwners` object explicitly authorizes that profile's owner.
4. Every declared parent is already present or is created first from the same authorized profile.

Every v0.7.0 entry has `automation.mayRemove` set to `false`. No folder may be automatically deleted merely because it is absent from a later definition. Missing folders may be created; existing folders and their contents must be preserved.

`required` means the folder is part of the applicable Geurts project or integration baseline. `optional` means content may not need the folder, although the full creation profile may still create the empty organizational path. Requirement status never grants deletion authority.

All definition paths are relative to `<ProjectRoot>`, use `/` as their canonical separator, preserve canonical letter case, contain no `.` or `..` segments, and have no leading or trailing slash.

The folder tool must report created, existing, skipped, invalid, and conflicted paths. Re-running it with the same definition and project state must be idempotent.

AI agent instruction files and the canonical documentation can be initialized with:

```text
Tools/CreateAIAgentInstructionFiles.bat
```

Run project tools from the Unity project root. If a compatibility launcher is stored inside `Tools/`, it must resolve the parent directory as `<ProjectRoot>` without changing the canonical path base.

---

## Root Structure

```text
ProjectRoot/
├── Assets/
├── Packages/
├── ProjectSettings/
├── UserSettings/
├── Docs/
├── GeurtsGameForgeDocumentation/
├── Builds/
├── Tools/
└── External/
```

---

## Automation-Owned Supporting Folders

These managed folders are documented here but are not members of the `full-project-structure` creation profile:

```text
ProjectRoot/
├── .github/
│   └── instructions/
└── GeurtsGameForgeDocumentation/
    └── GeurtsTechniques/
```

- `.github/` and `.github/instructions/` are owned by the native-entry manager. They hold generated Copilot entry files and other GitHub-native repository configuration. The folder-structure tool must not create them as part of the 67-path project profile.
- `GeurtsGameForgeDocumentation/` and `GeurtsGameForgeDocumentation/GeurtsTechniques/` are owned by the documentation synchronizer. The folder-structure tool must not create an empty substitute for synchronized documentation.
- These owners may create their assigned folders but may never delete an existing directory or user content through the folder-definition contract.
- `Docs/` and `Docs/GameDesign/` remain members of the full project profile and additionally delegate the closed `gdd-scaffolding` profile to the native-entry manager, so missing GDD scaffolding can be created without granting that manager access to unrelated folders.

---

## Non-Unity Root Folders

### Docs/

Project documentation.

Examples:

- Project-specific design docs.
- Naming conventions.
- Onboarding notes.
- Game design documentation under `Docs/GameDesign/`.

Canonical Geurts implementation techniques do not belong here. They are synchronized into `GeurtsGameForgeDocumentation/`.

### GeurtsGameForgeDocumentation/

Plugin-managed, synchronized Geurts Game Forge reference documentation.

Required core layout:

```text
GeurtsGameForgeDocumentation/
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
└── GeurtsTechniques/
```

Rules:

- Treat this directory as read-only synchronized reference material.
- Do not store project-specific GDD files here.
- Keep project-specific game design documentation under `Docs/GameDesign/`.
- Do not replace this directory with a hidden or nested substitute path unless the user explicitly changes the contract.

### Builds/

Generated playable builds only.

Rules:

- Do not store source assets here.
- This folder should be safe to delete and regenerate.

### Tools/

Project-specific tooling.

Examples:

- Build scripts.
- Validation scripts.
- Import processors.
- Automation utilities.
- Folder creation scripts.

### External/

Third-party or raw source material not yet integrated into Unity.

Examples:

- Vendor drops.
- Raw art/audio.
- Reference files.
- Export sources.

Treat `External/` as a quarantine zone for content that is not yet part of the Unity asset pipeline.

---

## Unity Assets Structure

```text
Assets/
├── _Project/
├── _ThirdParty/
├── _Addressables/
├── _Generated/
└── Gizmos/
```

---

## Assets Folder Rules

### Assets/_Project/

All first-party production content belongs here.

This is the main source of truth for Geurts-authored Unity assets.

### Assets/_ThirdParty/

Imported plugins, packages, and external Unity assets.

Rules:

- Never mix studio code with vendor code.
- Preserve vendor structure when practical.
- Do not directly modify vendor code unless necessary and documented.

### Assets/_Addressables/

Optional grouping layer for addressable content if used.

Rules:

- Only include addressable-managed assets or groups.
- Do not place unrelated production assets here only because they are loaded at runtime.

### Assets/_Generated/

Procedurally generated or tool-generated assets.

Rules:

- Rebuildable content only.
- Avoid manual edits unless explicitly allowed.
- Generated content should be safe to regenerate.

### Assets/Gizmos/

Unity editor gizmo textures and icons.

---

## Recommended _Project Structure

```text
Assets/_Project/
├── Art/
├── Audio/
├── Data/
├── Materials/
├── Prefabs/
├── Scenes/
├── Scripts/
├── Settings/
├── Shaders/
├── UI/
├── VFX/
└── Testing/
```

---

## Folder Definitions

### Art/

Visual source assets and imported art.

```text
Art/
├── 2D/
├── 3D/
├── Animations/
├── Sprites/
├── Textures/
└── Concept/
```

### Audio/

All audio assets.

```text
Audio/
├── Music/
├── SFX/
├── Ambience/
├── Dialogue/
└── Mixers/
```

### Data/

ScriptableObjects and structured gameplay data.

```text
Data/
├── Items/
├── Enemies/
├── Weapons/
├── Progression/
└── Tuning/
```

### Materials/

Shared material assets.

### Prefabs/

Reusable prefab assets.

```text
Prefabs/
├── Characters/
├── Environment/
├── Props/
├── UI/
├── Weapons/
└── Systems/
```

### Scenes/

Scene files only.

```text
Scenes/
├── Boot/
├── Frontend/
├── Gameplay/
├── Test/
└── Sandbox/
```

### Scripts/

All first-party code.

```text
Scripts/
├── Core/
├── Gameplay/
├── AI/
├── UI/
├── Audio/
├── Networking/
├── Editor/
├── Tools/
└── Testing/
```

### Settings/

Config assets and project-level runtime settings.

### Shaders/

Custom shaders and shader graphs.

### UI/

UI-specific assets not already stored elsewhere.

```text
UI/
├── Fonts/
├── Icons/
├── Layouts/
├── Themes/
└── Screens/
```

### VFX/

Particles, visual effects, flipbooks, and effect prefabs.

### Testing/

Test scenes, test data, mocks, and QA helpers.

---

## Scene Structure Recommendation

Use scene folders by function, not by chronology.

- `Boot/` - Initialisation scenes.
- `Frontend/` - Menus, shell, and meta systems.
- `Gameplay/` - Shipping game scenes.
- `Test/` - Feature validation scenes.
- `Sandbox/` - Experimental scenes.

---

## Script Structure Recommendation

Use domain-based grouping.

- `Core/` - Foundational systems.
- `Gameplay/` - Player, enemies, combat, and objectives.
- `AI/` - Decision logic and behaviours.
- `UI/` - Menus, HUD, and presentation logic.
- `Audio/` - Runtime audio systems.
- `Networking/` - Replicated systems and transport glue.
- `Editor/` - Editor-only tools.
- `Tools/` - Runtime-safe utilities.
- `Testing/` - Tests and test helpers.

---

## Timeless Rules

- Prefer function-based top-level folders over temporary feature names.
- Separate first-party content from third-party content.
- Keep scenes, prefabs, scripts, and data distinct.
- Do not bury reusable assets inside scene-specific folders unless they are truly local.
- Avoid deep nesting unless it reduces confusion.
- Every folder should answer: what belongs here, and what does not?

---

## Anti-Patterns

Do not create or rely on folders named:

- `Misc/`
- `New Folder/`
- `Temp/`

Avoid:

- Mixed folders containing scripts, prefabs, textures, and data together.
- Feature folders at the root when the project is still small and domains are clearer.
- Third-party code mixed into first-party code locations.
- Generated assets placed among manually authored production assets.

---

## Naming Guidance for Folders

- Use PascalCase for subfolders inside Unity content areas.
- Keep names short and literal.
- Prefer nouns over vague labels.
- Avoid abbreviations unless team-standard.

---

## Machine-Readable Definition Contract

Before creating folders, Game Forge Intelligence and platform-neutral tools must:

1. Load `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureDefinition.json` from the last validated synchronized copy.
2. Confirm supported `schemaVersion`, `definitionVersion`, and `packageVersion` values.
3. Confirm `managedFolderCount` is 71 and `projectStructureFolderCount` is 67 for definition v0.7.0.
4. Reject duplicate paths, absolute paths, traversal segments, backslashes, unknown content categories, missing parents, unknown profiles, or malformed automation objects.
5. Confirm every registry path appears in the literal Markdown registry below.
6. Select only the creation profile owned by the calling operation.
7. Create missing authorized folders parent-first.
8. Preserve every existing folder and file.
9. Report the exact definition version and every created, existing, skipped, invalid, or conflicted path.

A newer definition may add or reclassify paths. It must not cause a tool to delete a path that appeared in an older definition. An obsolete path is a reportable migration candidate, not deletion authorization.

### Literal Documented Path Registry

The following normalized paths must match the JSON `managedFolders[].path` set exactly. Validation compares the two literal registries; ordering is not authority.

<!-- GEURTS-FOLDER-PATHS:BEGIN -->

```text
Assets
Packages
ProjectSettings
UserSettings
Docs
Docs/GameDesign
Builds
Tools
External
Assets/_Project
Assets/_ThirdParty
Assets/_Addressables
Assets/_Generated
Assets/Gizmos
Assets/_Project/Art
Assets/_Project/Art/2D
Assets/_Project/Art/3D
Assets/_Project/Art/Animations
Assets/_Project/Art/Sprites
Assets/_Project/Art/Textures
Assets/_Project/Art/Concept
Assets/_Project/Audio
Assets/_Project/Audio/Music
Assets/_Project/Audio/SFX
Assets/_Project/Audio/Ambience
Assets/_Project/Audio/Dialogue
Assets/_Project/Audio/Mixers
Assets/_Project/Data
Assets/_Project/Data/Items
Assets/_Project/Data/Enemies
Assets/_Project/Data/Weapons
Assets/_Project/Data/Progression
Assets/_Project/Data/Tuning
Assets/_Project/Materials
Assets/_Project/Prefabs
Assets/_Project/Prefabs/Characters
Assets/_Project/Prefabs/Environment
Assets/_Project/Prefabs/Props
Assets/_Project/Prefabs/UI
Assets/_Project/Prefabs/Weapons
Assets/_Project/Prefabs/Systems
Assets/_Project/Scenes
Assets/_Project/Scenes/Boot
Assets/_Project/Scenes/Frontend
Assets/_Project/Scenes/Gameplay
Assets/_Project/Scenes/Test
Assets/_Project/Scenes/Sandbox
Assets/_Project/Scripts
Assets/_Project/Scripts/Core
Assets/_Project/Scripts/Gameplay
Assets/_Project/Scripts/AI
Assets/_Project/Scripts/UI
Assets/_Project/Scripts/Audio
Assets/_Project/Scripts/Networking
Assets/_Project/Scripts/Editor
Assets/_Project/Scripts/Tools
Assets/_Project/Scripts/Testing
Assets/_Project/Settings
Assets/_Project/Shaders
Assets/_Project/UI
Assets/_Project/UI/Fonts
Assets/_Project/UI/Icons
Assets/_Project/UI/Layouts
Assets/_Project/UI/Themes
Assets/_Project/UI/Screens
Assets/_Project/VFX
Assets/_Project/Testing
.github
.github/instructions
GeurtsGameForgeDocumentation
GeurtsGameForgeDocumentation/GeurtsTechniques
```

<!-- GEURTS-FOLDER-PATHS:END -->

---

## Recommendations

1. Keep `_Project` as the single source of truth for studio-owned assets.
2. Run `Tools/ValidateGeurtsDocumentation.ps1` whenever the Markdown technique or JSON definition changes.
3. Create new folders only when a category has multiple assets or a stable workflow need.
4. Use `Test` and `Sandbox` intentionally so experimental work does not pollute production content.
5. Treat `External` and `_ThirdParty` as quarantine zones for anything not authored by the studio.

---

## Minimal Version

If the project is very small, start with this:

```text
Assets/_Project/
├── Art/
├── Audio/
├── Data/
├── Prefabs/
├── Scenes/
├── Scripts/
└── UI/
```

---

## Expansion Rule

Only expand the structure when search time, onboarding friction, or asset collisions become noticeable.

The `full-project-structure` automation profile creates the complete 67-path structure. Teams may choose the minimal subset manually at the beginning of a small project; v0.7.0 does not define an automated minimal profile. A future profile must be versioned in both authorities and must preserve the no-deletion rule.

---

## Definition of Done

A folder-definition change is complete only when:

- the Markdown and JSON versions and literal paths agree;
- every JSON parent exists in the registry;
- every content category is from the declared five-value set;
- every automation owner and creation profile is valid;
- all `automation.mayRemove` values remain `false`;
- the full project profile contains exactly the intended project-structure paths;
- folder creation is executed twice in a temporary project and the second run creates nothing;
- the manifest and affected integration references are updated in the same change.
