# Geurts Game Forge AI Entry Point

**Version:** 0.7.0
**Purpose:** Single authoritative starting point for AI coding agents, automated development systems, and human developers using Geurts Game Forge documentation.
**Canonical path:** `AI_READ_FIRST.md`

## Start Here

If you are an AI agent, read this file before implementation work.

This repository is the canonical source of truth for Geurts Game Forge development techniques. A synchronized project copy is stored at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Do not assume another copied technique file is newer than the canonical repository or the synchronized copy created from it.

## AI-First Interpretation

The primary audience is **AI coding agents and automated development systems**. Human developers are the secondary audience.

Interpret this documentation deterministically. Prefer explicit requirements, stable terminology, literal paths, machine-readable sections, clear authority rules, and behaviour that can be validated automatically. If elegant prose conflicts with reliable machine interpretation, machine precision wins. Do not use that rule to ignore an explicit user instruction or make the documentation intentionally difficult for humans to read.

## Session or Project Initialization

Normal operation uses the last validated local copy under `GeurtsGameForgeDocumentation/`. Do not contact GitHub for every prompt.

At Unity-project opening or AI-session initialization:

1. The host integration performs one lightweight documentation update check with `Tools/BootstrapGeurtsInstructions.ps1 -Mode Check` or an equivalent plugin action.
2. The host records the exact validated documentation commit used by the AI session.
3. The AI reads `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` once when it exists.
4. The session records a manifest fingerprint using its version and either its hash or last-modified timestamp.
5. The manifest is re-read when that fingerprint changes.
6. Full project-specific design documents are not loaded until task routing requires them.

A missing design manifest does not block a purely technical task. It does not permit an AI to invent project-specific design facts.

## Required Reading Order

Before creating, modifying, moving, renaming, or deleting implementation files:

1. Read `GeurtsTechniqueManifest.md`.
2. Read `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`.
3. Read `GeurtsTechniques/GeurtsTechnicalTechnique.md` for technical implementation rules.
4. Read `GeurtsTechniques/GeurtsFolderStructureTechnique.md` before creating or moving files or assets.
5. When automation creates folders, also use `GeurtsTechniques/GeurtsFolderStructureDefinition.json` as the machine-readable creation authority.
6. If the task changes player-facing behaviour, read `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`.
7. When design context is required, use the initialized `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` and load every relevant project-specific design document.
8. If the task changes Game Forge Intelligence, documentation synchronization, managed AI entries, folder generation, or GDD manifest automation, read `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.
9. Inspect the target project's existing implementation before creating a replacement system.
10. Plan the smallest maintainable change.
11. Implement.
12. Validate against the applicable Geurts Definition of Done and report what changed.

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

Purely technical tasks may proceed without loading unrelated full game-design documents after the lightweight manifest discovery step.

### Gameplay or player-facing task

Read the technical set above, plus:

- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`
- `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`
- every project-specific design document relevant to the requested behaviour

Player-facing includes gameplay, movement, combat, enemies, AI behaviour, progression, balance, rewards, quests, levels, UI/UX, accessibility, narrative, and player-facing debugging.

If a relevant listed document is missing or does not provide the required decision, state the assumption before changing player-facing behaviour. Never fabricate mechanics, narrative, balance values, progression, characters, or other design facts to fill a documentation gap.

### Integration or automation task

Read the applicable technical set plus:

- `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`
- `GeurtsTechniques/GeurtsFolderStructureDefinition.json` when folder automation is involved
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` when GDD discovery, scaffolding, importing, or manifest maintenance is involved

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

**Game Forge Intelligence** is the current concrete Unity plugin. A **Geurts-compatible Unity AI integration package** is the generic category for other implementations of the same published contract.

The integration stores a validated local copy at `GeurtsGameForgeDocumentation/` and directs every native AI entry to `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`. The required visible synchronized layout is exactly:

```text
GeurtsGameForgeDocumentation/
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
└── GeurtsTechniques/
```

At initialization, perform a lightweight comparison of the local commit/version with the available canonical commit/version. If an update exists, report both values and follow package policy to request approval or update automatically. After a successful update, validate the three required entries and report the exact synchronized commit. The manual action is named **Update Geurts Game Forge Documentation**.

The script modes are `-Mode Check` for the lightweight comparison, `-Mode Update` for safe synchronization, and `-Mode Validate` for local validation.

An update must be staged and validated before replacing the last valid local copy. Report authentication, network, checkout, validation, and file-lock failures distinctly. Never claim a stale copy is current. v0.7.0 has no approved bundled fallback. Package policy or the user may explicitly permit the last validated local copy as a potentially stale fallback; report its version and commit, and never let it outrank a newer successfully synchronized canonical copy.

The detailed reusable contract is `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.

## Pre-Code Lock

Do not create, modify, move, rename, or delete target-project files until initialization has established a valid documentation state and the required Geurts documents for the task have been read.

The intended sequence is:

`CHECK LOCAL DOCS -> UPDATE WHEN REQUIRED -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

If an update check fails, preserve the last valid copy and follow the explicit fallback policy. Without an allowed fallback, required synchronization failure blocks target-project modification.

Never treat the documentation as optional background reading.
