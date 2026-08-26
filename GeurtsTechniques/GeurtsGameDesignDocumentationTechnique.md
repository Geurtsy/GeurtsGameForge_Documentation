# Geurts Game Design Documentation Technique

**Game Design Documentation Discovery - AI and Human Developer Reference**  
**Version:** 0.7.0
**Status:** Draft supporting technique  
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Canonical path:** `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the canonical path shown above.

---

## Purpose

This document defines how AI coding agents, automated development systems, and human developers discover, classify, maintain, and use project-specific game design documentation.

The Technical Technique defines how to build systems. Project-specific game design documentation defines what those systems should feel like, support, or express to the player.

Interpret the rules deterministically. Literal paths, explicit metadata, stable ordering, authority fields, and machine-verifiable states take precedence over elegant wording when the two conflict.

---

## Documentation Boundary

Synchronized Geurts Game Forge techniques belong at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Project-specific game design documentation belongs at:

```text
<ProjectRoot>/Docs/GameDesign/
```

Never use a template or example inside `GeurtsGameForgeDocumentation/` as the target game's design authority.

Never put canonical Geurts techniques in `Docs/GameDesign/` or project-specific GDD files in `GeurtsGameForgeDocumentation/`.

---

## Canonical Game Design Directory

Use this target-project directory for project-specific game design documentation:

```text
<ProjectRoot>/Docs/GameDesign/
```

Use this manifest as the design index when it exists:

```text
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

---

## Lightweight Session-Start Discovery

At Unity-project opening or AI-session initialization:

1. Check for `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`.
2. Read it once when it exists.
3. Record its declared version plus either a content hash or last-modified timestamp as the session fingerprint.
4. Re-read it when that fingerprint changes.
5. Use its metadata to route later work without loading every full design document.

A missing manifest does not block a purely technical task. A technical task may proceed without unrelated full GDD files.

Before changing player-facing behaviour, load every relevant document identified by the current manifest. If a relevant document is missing, unavailable, unclassified, or silent on the required decision, state the assumption before implementation. Do not invent mechanics, narrative, balance values, progression, characters, or other design facts.

---

## When AI Agents Must Consult Game Design Docs

AI agents must check the project-specific game design documentation when a task affects:

- Core mechanics.
- Player abilities.
- Enemy behaviour.
- AI behaviour that affects gameplay feel.
- Combat tuning.
- Progression, economy, rewards, or unlocks.
- Quests, objectives, or narrative content.
- Level design or encounter pacing.
- UI and UX flow.
- Accessibility or player-facing options.
- Player-visible debugging, cheats, or tuning tools.

---

## Safe Scaffolding

When these paths are missing, the setup workflow creates them from controlled templates:

```text
<ProjectRoot>/Docs/GameDesign/
<ProjectRoot>/Docs/GameDesign/README.md
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

Rules:

- Create missing directories and files only.
- Never overwrite project-specific README or manifest content.
- Mark unknown design decisions as `Unprovided`.
- Do not pre-populate fictional mechanics, narrative, balance, progression, characters, or other game facts.
- Make every rerun idempotent.
- Report which paths were created and which already existed.

`Tools/ManageGeurtsAgentInstructions.ps1` installs both safe native entries and this missing-only GDD scaffolding, then invokes `Tools/UpdateGameDesignManifest.ps1`. The workflow is defined in `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`.

---

## Recommended Design Document Set

These files are optional starting points. Create only what the project actually needs.

```text
<ProjectRoot>/Docs/GameDesign/
├── GameDesignManifest.md
├── GameDesignOverview.md
├── GameplayPillars.md
├── CoreMechanics.md
├── PlayerAbilities.md
├── EnemyAndAIDesign.md
├── ProgressionAndBalance.md
├── LevelDesign.md
├── UIUXDesign.md
├── NarrativeAndWorld.md
└── AccessibilityDesign.md
```

---

## Manifest Rules

`<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` is the project-specific routing index. It must not list synchronized Geurts techniques as project design authority.

Each document record must support:

| Field | Requirement |
|---|---|
| Identifier | Stable unique identifier used for duplicate and rename detection. |
| Document path | Project-root-relative path inside `Docs/GameDesign/`. |
| Purpose or design domain | Explicit routing description; use `RequiresClassification` when unknown. |
| Status | For example `Active`, `Draft`, `Deprecated`, `Invalid`, or `RequiresClassification`. |
| Version | Declared document version when available; otherwise `Unprovided`. |
| Authority or precedence | Explicit relationship when the document overrides or is overridden by another design source. |
| Tags or task categories | Optional stable routing labels. |

Do not infer purpose or authority from a filename when that inference is unreliable.

### Deterministic Maintenance

Use:

```text
Tools/UpdateGameDesignManifest.ps1
```

The maintainer must detect and report:

- added documents discovered by scanning;
- imported documents only when the importer passes their project-relative paths through `-ImportedPath`;
- removed documents;
- renamed documents when only the filename changes within the same directory;
- moved documents when their directory changes within `Docs/GameDesign/`;
- unchanged documents;
- duplicate identifiers or paths;
- unsupported files and conflicts.

The deterministic scan includes regular Markdown files recursively, including `README.md`, and excludes the manifest itself, hidden files or hidden directories, temporary files, backups, and tool lock files. Other extensions are reported as unsupported rather than indexed. Without an explicit `-ImportedPath` signal, a newly discovered Markdown file is `Added`, never guessed to be imported.

Persistent identifiers are the primary rename key. A file-watcher rename event or unique content fingerprint may be used when an identifier is unavailable. If a rename cannot be determined reliably, report an addition and a removal requiring review rather than guessing.

Maintenance must be:

- deterministic and idempotent;
- stably ordered by normalized project-relative path and then identifier;
- free of timestamps or formatting changes that create unnecessary source-control churn;
- limited to an explicit managed manifest section so manual notes remain intact;
- able to preserve manually authored purpose, status, version, authority, and tags where practical;
- protected from recursive self-triggering by excluding the manifest itself and ignoring its own unchanged output hash;
- fail-safe when identifiers conflict or parsing is ambiguous.

`-ManifestPath`, when supplied, must resolve exactly to `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`. The maintainer must reject reparse points anywhere in the project, design, or discovered directory path; acquire its single-writer lock before reading the manifest; remove only a lock it acquired; parse every non-empty managed-region line strictly; validate explicit metadata before rendering; and treat unsupported future managed-region versions as conflicts without downgrade.

The managed table is bounded by matching `GEURTS-GDD-MANIFEST-BEGIN` and `GEURTS-GDD-MANIFEST-END` markers. Manually authored notes belong outside that region.

New documents without reliable metadata receive `RequiresClassification`. Unsupported files are reported and must not be silently treated as design authority. Duplicate identifiers are conflicts: do not choose a winner or overwrite the manifest silently.

Game Forge Intelligence may invoke the maintainer after imports or debounced file-watcher events. The exact plugin-facing event, conflict, and audit requirements are defined in `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.

### Design Document Conflict Order

If multiple design documents conflict, AI agents should prefer:

1. The explicit authority or precedence recorded in `GameDesignManifest.md`.
2. The most specific relevant document.
3. The highest semantic version for documents with the same scope and authority.
4. The newest dated design decision note if versions are unavailable.

If ambiguity remains, the AI agent must state the conflict and assumption before implementation.

---

## Relationship to Other Techniques

- `GeurtsTechnicalTechnique.md` defines implementation standards.
- Project-specific game design docs define player-facing intent.
- `GeurtsFolderStructureTechnique.md` defines where files belong.
- `GeurtsAIAgentSetupTechnique.md` defines how agents discover and synchronize the documentation.
- `GeurtsGameForgeIntelligenceIntegrationContract.md` defines how Game Forge Intelligence and compatible packages implement discovery, watching, importing, maintenance, and audit behaviour.

Game design documents should not silently override technical safety, performance, or multiplayer network-efficiency requirements. If design intent conflicts with technical standards, the AI agent must state the conflict.
