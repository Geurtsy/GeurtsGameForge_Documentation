# Geurts Game Forge Technique Package

**Version:** 0.4.0  
**Status:** Draft technique package  
**Audience:** AI agents and human developers  

> **Version Selection Notice:** If multiple copies of this package, README, technique document, or batch file are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the copy in the canonical project paths shown below.

---

## What This Package Is

This package contains the broad-scope technique set for **Geurts Game Forge**.

It defines major standards, priorities, project structure, AI agent setup, and game design documentation discovery without turning the project into a pile of tiny preference rules.

---

## Canonical File Locations

Place the package contents in the Unity project root like this:

```text
ProjectRoot/
├── README.md
├── AGENTS.md                         created by Tools/CreateAIAgentInstructionFiles.bat
├── .github/                          created by Tools/CreateAIAgentInstructionFiles.bat
│   ├── copilot-instructions.md
│   └── instructions/
│       ├── geurts-unity.instructions.md
│       └── geurts-game-design.instructions.md
├── Docs/
│   ├── GeurtsTechnicalTechnique.md
│   ├── GeurtsFolderStructureTechnique.md
│   ├── GeurtsAIAgentSetupTechnique.md
│   ├── GeurtsGameDesignDocumentationTechnique.md
│   └── GameDesign/
│       ├── README.md                  created by Tools/CreateAIAgentInstructionFiles.bat
│       └── GameDesignManifest.md       created by Tools/CreateAIAgentInstructionFiles.bat
└── Tools/
    ├── CreateGeurtsFolderStructure.bat
    ├── CreateAIAgentInstructionFiles.bat
    └── AIAgentInstructionTemplates/
```

---

## Setup Instructions

1. Copy `Docs/` into the Unity project root.
2. Copy `Tools/` into the Unity project root.
3. Run `Tools/CreateGeurtsFolderStructure.bat`.
4. Run `Tools/CreateAIAgentInstructionFiles.bat`.

Both batch files must stay inside `ProjectRoot/Tools/`.

---

## What the Batch Files Do

### `Tools/CreateGeurtsFolderStructure.bat`

Creates the Unity project folder structure from `Docs/GeurtsFolderStructureTechnique.md`.

### `Tools/CreateAIAgentInstructionFiles.bat`

Creates missing AI-native instruction files for:

- GitHub Copilot.
- Codex.
- Compatible agents that read `AGENTS.md` or `.github` instruction files.

It also creates the starting `Docs/GameDesign/` manifest files.

---

## Batch File Safety

The batch files are safe to run multiple times.

They must:

- Create missing folders or files only.
- Keep existing files and folders intact.
- Never delete files.
- Never overwrite files.
- Never rename files.
- Never move files.

If either `.bat` is not inside a folder named `Tools`, it will stop and show an error instead of guessing.

---

## Strict Priority Standards

The Geurts Technical Technique uses this strict default priority order:

1. **Extendibility**
2. **Readability**
3. **Efficiency**
4. **Updated**
5. **Documented**

These priorities are not equal. If a decision has a trade-off, the higher priority wins unless a newer technique version says otherwise.

### Multiplayer Exception

For multiplayer systems, **network efficiency overrides all other priorities**.

---

## Game Design Documentation Rule

When a task affects gameplay, balance, progression, UX, narrative, level design, AI behaviour, enemies, or player-facing content, AI agents must check:

```text
Docs/GameDesign/GameDesignManifest.md
```

If no relevant design document exists, the AI agent must state the assumption before implementation.

---

## AI Agent Build Process Rule

Before generating, modifying, moving, or organising files, AI agents must:

1. Locate the available Geurts technique documents.
2. Select the highest semantic version of each technique.
3. Prefer canonical paths when versions are tied.
4. Follow `Docs/GeurtsTechnicalTechnique.md` for technical rules.
5. Follow `Docs/GeurtsFolderStructureTechnique.md` for folder placement.
6. Follow `Docs/GeurtsAIAgentSetupTechnique.md` for AI-native instruction setup.
7. Follow `Docs/GeurtsGameDesignDocumentationTechnique.md` when design context matters.

If ambiguity remains, the AI agent must state the assumption before making changes.

---

## Changelog

### v0.4.0

- Renamed package terminology to Technique throughout.
- Renamed core document files to use `Technique` in their filenames.
- Updated Copilot, Codex, README, manifest, and design-discovery references to point at the Technique documents.
- Corrected the response-control document filename and bumped it to v1.1.

### v0.3.0

- Added `Docs/GeurtsAIAgentSetupTechnique.md`.
- Added `Docs/GeurtsGameDesignDocumentationTechnique.md`.
- Added `Tools/CreateAIAgentInstructionFiles.bat`.
- Added templates for `AGENTS.md`, `.github/copilot-instructions.md`, and `.github/instructions/*.instructions.md`.
- Added starter `Docs/GameDesign/` README and manifest templates.
- Updated technical technique to reference native AI instruction setup and game design documentation discovery.

### v0.2.1

- Updated the folder-creation batch file so it must live in and run from the `Tools/` folder.
- Added root `README.md` for clear setup and AI-agent usage.

### v0.2.0

- Added versioning to technique documents and batch file.
- Added latest-version selection notes.
- Added strict priority order.

---

## Notes

This package is still a draft. It is expected to evolve as Geurts Game Forge grows.
