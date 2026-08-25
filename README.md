# Geurts Game Forge Documentation

**Version:** 0.6.0  
**Status:** Draft technique package  
**Audience:** AI agents and human developers  
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`

## AI: Start Here

If you are an AI agent, Codex session, or automated development tool, begin with:

`AI_READ_FIRST.md`

Do not start implementation from this README. `AI_READ_FIRST.md` defines the mandatory reading order, task routing, authority hierarchy, and pre-code lock.

## What This Repository Is

This repository is the canonical source for Geurts Game Forge development techniques. Unity projects and compatible AI integration packages should synchronize this repository rather than maintaining independent copies of the technique set.

The intended flow is:

`GitHub canonical docs -> project synchronization -> GeurtsGameForgeDocumentation/ -> project AGENTS.md -> AI agent -> Unity implementation`

## Project-Local Documentation Layout

A synchronized Unity project should use:

```text
ProjectRoot/
└── GeurtsGameForgeDocumentation/
    ├── AI_READ_FIRST.md
    ├── GeurtsTechniqueManifest.md
    └── GeurtsTechniques/
```

Project-specific game design documentation remains separate at:

```text
ProjectRoot/Docs/GameDesign/
```

## Core Entry Points

- `AI_READ_FIRST.md` - primary AI documentation entry point.
- `AGENTS.md` - repository-level Codex instructions for this documentation repository.
- `GeurtsTechniqueManifest.md` - current package/version index and instruction classifications.
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` - AI integration and bootstrap rules.
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` - implementation standards.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` - Unity folder and asset placement standards.
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` - rules for discovering player-facing design context.
- `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` - target game's design-document index when present.

## Unity Integration

A compatible package should configure this repository as its canonical documentation source:

`https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`

Canonical branch:

`main`

The package should synchronize the repository before an AI agent changes target-project files, store the synchronized copy at `GeurtsGameForgeDocumentation/`, and direct the agent to `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`.

If synchronization is required and fails, the package must fail visibly rather than silently pretending stale instructions are current.

## Required AI Sequence

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

The mandatory and conditional documents for each task are defined in `AI_READ_FIRST.md` and `GeurtsTechniqueManifest.md`.

## Technical Priority

The current default Geurts technical priority is:

1. **Extendibility**
2. **Readability**
3. **Efficiency**
4. **Updated**
5. **Documented**

For multiplayer systems, **network efficiency overrides all other priorities**.

## Important Classification

`GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` controls chat-response behaviour. It is not a Unity coding, architecture, engineering, or implementation standard unless a later manifest explicitly reclassifies it.

## Version Selection

When multiple versions of the same technique exist, use the highest semantic version. When versions tie, prefer the canonical repository/path declared by the technique or manifest.

## Changelog

### v0.6.0

- Replaced the legacy hidden synchronization path with the visible project folder `GeurtsGameForgeDocumentation/`.
- Renamed the canonical implementation-technique directory from `Docs/` to `GeurtsTechniques/`.
- Separated synchronized Geurts techniques from project-specific GDD files under `<ProjectRoot>/Docs/GameDesign/`.
- Updated bootstrap configuration, entry files, templates, and validation paths.

### v0.5.0

- Made GitHub the canonical documentation authority.
- Added `AI_READ_FIRST.md` as the single AI documentation entry point.
- Added a root repository `AGENTS.md`.
- Added a pre-code lock and the `SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT` workflow.
- Classified the response-control technique as chat-only rather than a coding standard.
- Updated Codex bootstrap guidance for the Unity integration package.

### v0.4.0

- Renamed package terminology to Technique throughout.
- Updated Copilot, Codex, README, manifest, and design-discovery references to Technique documents.
- Corrected the response-control document filename and bumped it to v1.1.

## Maintenance

When a technique changes, update `GeurtsTechniqueManifest.md` and any affected entry-point references in the same change. Keep native AI instruction files short and route agents to authoritative documentation rather than copying entire standards into every project.
