# Geurts Game Forge AI Entry Point

**Version:** 0.6.0  
**Purpose:** Single starting point for AI agents, Codex sessions, and human developers using this repository as the canonical Geurts documentation source.

## Start Here

If you are an AI agent, read this file before implementation work.

This repository is the canonical source of truth for Geurts Game Forge development techniques. A synchronized project copy is stored at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Do not assume another copied technique file is newer than the canonical repository or the synchronized copy created from it.

## Required Reading Order

Before creating, modifying, moving, renaming, or deleting implementation files:

1. Read `GeurtsTechniqueManifest.md`.
2. Read `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`.
3. Read `GeurtsTechniques/GeurtsTechnicalTechnique.md` for technical implementation rules.
4. Read `GeurtsTechniques/GeurtsFolderStructureTechnique.md` before creating or moving files or assets.
5. If the task changes player-facing behaviour, read `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`.
6. When design context is required, inspect the target Unity project's `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` and then the relevant project-specific design documents.
7. Inspect the target project's existing implementation before creating a replacement system.
8. Plan the smallest maintainable change.
9. Implement.
10. Validate against the applicable Geurts Definition of Done and report what changed.

Use the highest semantic version when multiple versions of the same technique exist, unless the manifest explicitly declares another authority rule.

## Path Boundary

Keep these two documentation domains separate:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Contains synchronized Geurts Game Forge techniques and AI entry files.

```text
<ProjectRoot>/Docs/GameDesign/
```

Contains the target game's project-specific design documents.

Never treat files inside `GeurtsGameForgeDocumentation/` as the target game's GDD.

## Task Routing

### Technical or Unity code task

Always read:

- `GeurtsTechniqueManifest.md`
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`
- `GeurtsTechniques/GeurtsTechnicalTechnique.md`
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md`

### Gameplay or player-facing task

Read the technical set above, plus:

- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`
- `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`
- every project-specific design document relevant to the requested behaviour

Player-facing includes gameplay, movement, combat, enemies, AI behaviour, progression, balance, rewards, quests, levels, UI/UX, accessibility, narrative, and player-facing debugging.

### Documentation-only task

Read the manifest and the technique that owns the documentation being changed. Preserve established terminology, semantic versioning, canonical paths, and authority rules.

## Authority and Conflict Order

Resolve instructions in this order unless a more specific document explicitly owns the subject:

1. Current explicit user instruction.
2. Applicable repository or project `AGENTS.md` instructions.
3. Latest applicable Geurts technique document identified by the manifest.
4. Project-specific game-design documentation.
5. Existing project conventions.
6. General Unity or software-engineering practice.
7. AI assumptions.

Do not silently choose between contradictory project rules. State the conflict or assumption when it materially affects implementation.

## Important Classification

`GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` governs chat-response behaviour. It is not a Unity coding or architecture standard unless a later manifest explicitly changes that classification.

## Canonical Repository

Repository: `Geurtsy/GeurtsGameForge_Documentation`

Branch: `main`

A Geurts-compatible Unity AI integration package should synchronize this repository before an AI agent modifies project code, store the synchronized copy at `GeurtsGameForgeDocumentation/`, and direct the agent to `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`.

## Pre-Code Lock

Do not create, modify, move, rename, or delete target-project files until the required Geurts documents for the task have been read.

The intended sequence is:

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

Never treat the documentation as optional background reading.
