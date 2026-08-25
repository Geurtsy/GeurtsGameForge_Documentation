# Geurts Game Forge AI Entry Point

**Purpose:** Single starting point for AI agents, Codex sessions, and human developers using this repository as the canonical Geurts documentation source.

## Start Here

If you are an AI agent, read this file before implementation work.

This repository is the canonical source of truth for Geurts Game Forge development techniques. Do not assume a copied technique file in another project is newer than this repository.

## Required Reading Order

Before creating, modifying, moving, renaming, or deleting implementation files:

1. Read `GeurtsTechniqueManifest.md`.
2. Read `Docs/GeurtsAIAgentSetupTechnique.md`.
3. Read `Docs/GeurtsTechnicalTechnique.md` for technical implementation rules.
4. Read `Docs/GeurtsFolderStructureTechnique.md` before creating or moving files or assets.
5. If the task changes player-facing behaviour, read `Docs/GeurtsGameDesignDocumentationTechnique.md`.
6. When design context is required, inspect `Docs/GameDesign/GameDesignManifest.md` and then the relevant design documents.
7. Inspect the target project's existing implementation before creating a replacement system.
8. Plan the smallest maintainable change.
9. Implement.
10. Validate against the applicable Geurts Definition of Done and report what changed.

Use the highest semantic version when multiple versions of the same technique exist, unless the manifest explicitly declares another authority rule.

## Task Routing

### Technical or Unity code task

Always read:

- `GeurtsTechniqueManifest.md`
- `Docs/GeurtsAIAgentSetupTechnique.md`
- `Docs/GeurtsTechnicalTechnique.md`
- `Docs/GeurtsFolderStructureTechnique.md`

### Gameplay or player-facing task

Read the technical set above, plus:

- `Docs/GeurtsGameDesignDocumentationTechnique.md`
- `Docs/GameDesign/GameDesignManifest.md`
- every design document relevant to the requested behaviour

Player-facing includes gameplay, movement, combat, enemies, AI behaviour, progression, balance, rewards, quests, levels, UI/UX, accessibility, narrative, and player-facing debugging.

### Documentation-only task

Read the manifest and the technique that owns the documentation being changed. Preserve established terminology, semantic versioning, canonical paths, and authority rules.

## Authority and Conflict Order

Resolve instructions in this order unless a more specific document explicitly owns the subject:

1. Current explicit user instruction.
2. Applicable repository `AGENTS.md` instructions.
3. Latest applicable Geurts technique document identified by the manifest.
4. Project-specific game-design documentation.
5. Existing project conventions.
6. General Unity or software-engineering practice.
7. AI assumptions.

Do not silently choose between contradictory project rules. State the conflict or assumption when it materially affects implementation.

## Important Classification

`GeurtsAIResponseControlTechnique_V1.1.md` governs chat-response behaviour. It is not a Unity coding or architecture standard unless a later manifest explicitly changes that classification.

## Canonical Repository

Repository: `Geurtsy/GeurtsGameForge_Documentation`

Branch: `main`

The TripoCodexUnityPackage should bootstrap or synchronize this repository before Codex modifies project code, then direct Codex to this file.

## Pre-Code Lock

Do not create, modify, move, rename, or delete target-project files until the required Geurts documents for the task have been read.

The intended sequence is:

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

Never treat the documentation as optional background reading.