<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts Game Design Documentation Technique

**Game Design Documentation Discovery - AI and Human Developer Reference**  
**Version:** 0.10.0
**Status:** Draft normative technique
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Required package path:** `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`

> `GeurtsTechniqueManifest.md` selects this file and version from one validated package commit. This technique defines GDD discovery and maintenance boundaries only.

---

## Purpose

This document defines how AI coding agents, automated development systems, and human developers discover, classify, maintain, and use project-specific game design documentation.

The Technical Technique defines how to build systems. Project-specific game design documentation defines what those systems should feel like, support, or express to the player.

Interpret the rules deterministically. Literal paths, explicit metadata, stable ordering, authority fields, and machine-verifiable states take precedence over elegant wording when the two conflict.

---

## Documentation Boundary

The sole Geurts Game Forge documentation source and authority is `Geurtsy/GeurtsGameForge_Documentation`. Its detached project-local fetched copy belongs at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Project-specific game design documentation belongs at:

```text
<ProjectRoot>/Docs/GameDesign/
```

The managed copy is outside the independent Documentation Companion's Unity Package Manager package. Companion-only `Documentation~` is not a source or duplicate of Geurts documentation. The companion is independent of Geurts Game Forge God and Game Forge Intelligence and has no Odin Inspector or Quantum Console dependency. Never use a template or example inside `GeurtsGameForgeDocumentation/` as the target game's design authority.

Never put Geurts source-package files in `Docs/GameDesign/` or project-specific GDD files in `GeurtsGameForgeDocumentation/`.

After one confirmation, the companion's `Update Geurts Game Forge Documentation` action may replace the complete managed documentation folder and only the four project AI-route files declared by `GeurtsDocumentationCompanionContract.json`. It must not enumerate, inspect, create, validate, hash, modify, or delete any path under `Docs/GameDesign/`. Copying the exact scoped game-design route template to `.github/instructions/geurts-game-design.instructions.md` grants no access to the paths that template may later route an AI tool toward. GDD scaffolding and bounded manifest maintenance remain separate optional manual operations under this technique and the AI Agent Setup Technique.

---

## Project Game Design Directory

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

Before changing player-facing behaviour, load every relevant document identified by the project's current `GameDesignManifest.md`. If a relevant document is missing, unavailable, unclassified, or silent on a decision that would establish or change player-facing design intent, stop and ask for that decision before implementation. Do not invent or assume mechanics, narrative, balance values, progression, characters, or other design facts. A stated assumption is allowed only for a reversible technical detail that does not create, alter, or overwrite design intent.

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

Only after separate explicit authorization, the setup workflow may create these missing paths from controlled templates:

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

Installing the companion through Unity Package Manager and using its Update create no GDD paths and never invoke a script. Native-entry migration alone also creates no GDD paths. A separately authorized optional manual operation may use the copied manager with explicit project root and opt-in:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -IncludeGameDesignScaffolding
```

The manual scaffolding opt-in does not update the manifest. Deterministic manifest maintenance requires another separate explicit manual operation, either the copied manager with `-UpdateGameDesignManifest` or the copied maintainer invocation below. The safe invocation contract is defined in `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`. None of these manual operations are part of the companion lifecycle.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -UpdateGameDesignManifest
```

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

`<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` is the project-specific routing index. It must not list project-local fetched Geurts package files as project design authority.

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

After explicit authorization, use the copied tool with the Unity root supplied explicitly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/UpdateGameDesignManifest.ps1" -ProjectRoot "<ProjectRoot>"
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
- limited to an explicit managed manifest section while preserving the exact bytes outside it;
- able to preserve the manifest's original UTF-8, UTF-8-BOM, UTF-16LE-BOM, or UTF-16BE-BOM encoding and reject invalid text or UTF-32 without mutation;
- able to preserve manually authored purpose, status, version, authority, and tags where practical;
- protected from recursive self-triggering by excluding the manifest itself and ignoring its own unchanged output hash;
- fail-safe when identifiers conflict or parsing is ambiguous.

`-ManifestPath`, when supplied, must resolve exactly to `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`. The maintainer must reject reparse points anywhere in the project, design, or discovered directory path; keep its single-writer lock and temporary replacement artifacts at a validated project-root-owned location rather than beneath the swappable game-design parent; acquire the lock with create-new, handle-owned delete-on-close semantics before reading the manifest; treat any pre-existing lock path as a conflict and preserve its exact bytes; remove only the lock represented by its acquired handle; parse every non-empty managed-region line strictly; validate explicit metadata before rendering; and treat unsupported future managed-region versions as conflicts without downgrade. It must retain the raw-byte fingerprint captured at read time and, immediately before atomic promotion, revalidate containment and the full path chain, then reject any existence or byte drift instead of overwriting concurrent content.

The managed table is bounded by matching `GEURTS-GDD-MANIFEST-BEGIN` and `GEURTS-GDD-MANIFEST-END` markers. Manually authored notes belong outside that region.

New documents without reliable metadata receive `RequiresClassification`. Unsupported files are reported and must not be silently treated as design authority. Duplicate identifiers are conflicts: do not choose a winner or overwrite the manifest silently.

A compatible host may detect imports or debounced file-watcher events, invalidate cached discovery data, report manifest drift, and offer a user-approved handoff to the external maintainer. It must not invoke the maintainer automatically or write project GDD content. The Documentation Companion is not such a host: its startup metadata check and confirmed Update must not inspect `Docs/GameDesign/` at all.

### Design Document Conflicts

Cross-document conflict resolution is centralized in `GeurtsTechniqueManifest.md`. Record explicit design-source precedence in `GameDesignManifest.md`; otherwise surface a material conflict and ask when its resolution would establish design intent. Do not choose a stray document merely because it has a higher version or newer date.

---

## Manifest Relationship

The manifest selects this technique alongside any other applicable subject owner. Project-specific game-design documents define player-facing facts within their recorded scope; if those facts materially conflict with a selected technical requirement, state the conflict rather than silently choosing one.
