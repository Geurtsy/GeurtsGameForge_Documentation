# Geurts Folder Structure Technique

**Unity Project Structure - AI and Human Developer Reference**  
**Version:** 0.4.0  
**Status:** Draft supporting technique  
**Audience:** AI systems and human developers  
**Canonical path:** `Docs/GeurtsFolderStructureTechnique.md`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the copy in the canonical path shown above.

---

## Purpose

This document defines a stable, scalable Unity project structure for Geurts Game Forge.

The structure is optimised for:

- AI readability.
- Automation.
- Long-term team consistency.
- Fast asset discovery.
- Safe refactoring.
- Clear separation between first-party, third-party, generated, and external content.

This document is the authority for folder layout and asset placement. The main technical rules remain in `Docs/GeurtsTechnicalTechnique.md`. AI agent setup files are governed by `Docs/GeurtsAIAgentSetupTechnique.md`.

---

## Design Goals

- Minimise ambiguity.
- Keep each folder's purpose singular and obvious.
- Separate source, generated, and external content.
- Support solo development and team scaling.
- Make assets easy to locate, validate, and refactor.

---

## Automation

The full folder structure can be generated with:

```text
Tools/CreateGeurtsFolderStructure.bat
```

The batch file is safe to run multiple times. It creates missing folders only and must not delete, overwrite, rename, or move existing files.

AI agent instruction files and game design documentation placeholders can be created with:

```text
Tools/CreateAIAgentInstructionFiles.bat
```

Run the batch file from the Unity project root or keep it inside `Tools/`. If it is inside `Tools/`, it will create folders in the parent project root.

---

## Root Structure

```text
ProjectRoot/
├── Assets/
├── Packages/
├── ProjectSettings/
├── UserSettings/
├── Docs/
├── Builds/
├── Tools/
└── External/
```

---

## Non-Unity Root Folders

### Docs/

Project documentation.

Examples:

- Design docs.
- Technical docs.
- Naming conventions.
- Onboarding notes.
- AI instructions.
- Game design documentation under `Docs/GameDesign/`.

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

## Recommendations

1. Keep `_Project` as the single source of truth for studio-owned assets.
2. Add validation tools later to enforce the structure automatically.
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

The provided batch file creates the full recommended structure, but teams may choose to use the minimal version manually at the beginning of a small project.
