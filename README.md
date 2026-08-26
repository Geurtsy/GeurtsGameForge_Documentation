# Geurts Game Forge Documentation

**Version:** 0.8.0
**Status:** Draft technique package  
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`

## AI: Start Here

If you are an AI agent, Codex session, or automated development tool, begin with:

`AI_READ_FIRST.md`

Do not start implementation from this README. `AI_READ_FIRST.md` defines the mandatory reading order, task routing, authority hierarchy, and pre-code lock.

## What This Repository Is

This repository is the canonical source for Geurts Game Forge development techniques. Unity projects and compatible AI integration packages should synchronize this repository rather than maintaining independent copies of the technique set.

The package is AI-first. Documentation favours deterministic interpretation, explicit requirements, literal paths, stable terminology, machine-readable data, and automated validation. Human readability remains important, but human elegance does not override reliable machine interpretation.

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
- `GeurtsTechniques/GeurtsFolderStructureDefinition.json` - machine-readable folder-creation authority.
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` - rules for discovering player-facing design context.
- `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` - reusable synchronization, managed-entry, folder-generation, and GDD automation contract.
- `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` - canonical, hash-validated custom project-root `.gitignore` payload.
- `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` - target game's design-document index when present.

## Game Forge Intelligence Integration

**Game Forge Intelligence** is the current concrete Unity plugin. **Geurts-compatible Unity AI integration package** is the generic category used for reusable contracts.

This repository contains documentation contracts and platform-neutral tooling, not the Game Forge Intelligence Unity plugin source. Plugin-specific Unity implementation belongs in its own source repository.

The canonical repository is:

`https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`

Canonical branch:

`main`

The repository is public. Integrations use anonymous read-only access for normal checks and synchronization by default; optional authentication must not be required for that path.

Normal prompts use the last validated local copy at `GeurtsGameForgeDocumentation/`. They do not contact GitHub on every prompt.

At Unity launch or AI-session initialization, the integration performs one lightweight commit/version check. When an update exists, it reports the current and available identifiers and follows package policy to request approval or update automatically. The manual action is named **Update Geurts Game Forge Documentation**.

Updates must be staged, validated, and swapped safely. A successful update reports the exact synchronized commit. A failed update preserves the last valid copy and reports optional-authentication, network, checkout, validation, or file-lock failure accurately. v0.8.0 has no approved bundled documentation fallback. Explicit policy may permit the last validated local copy as potentially stale; its version and commit must be visible, and it never outranks a newer successfully synchronized canonical copy.

Every generated native AI entry routes through `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`. The full reusable contract is `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.

During plugin setup, Game Forge Intelligence uses the marked payload in `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsGitIgnoreTechnique.md` to create a missing project-root `.gitignore`. If that custom source cannot be used, the plugin reports and uses its versioned default. A differing existing `.gitignore` remains project-owned and unchanged.

## Game Design Discovery

At session or project initialization, read `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` once when it exists and retain a version/hash/timestamp fingerprint. Re-read it when the fingerprint changes.

Do not load every full GDD for every task. Purely technical work may proceed after lightweight discovery; player-facing work must load every relevant design document first. If required intent is missing, state the assumption before changing behaviour. Never fabricate game-design facts.

## Required AI Sequence

`CHECK LOCAL DOCS -> UPDATE WHEN REQUIRED -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

The mandatory and conditional documents for each task are defined in `AI_READ_FIRST.md` and `GeurtsTechniqueManifest.md`.

## Technical Priority

The current default Geurts technical priority is:

1. **Extendibility**
2. **Efficiency**
3. **Readability**
4. **Updated**
5. **Documented**

Higher-numbered principles must not silently override lower-numbered principles. Runtime efficiency wins when it genuinely conflicts with readability, while readability remains desirable when it does not add avoidable runtime cost.

For multiplayer systems, **network efficiency overrides all other priorities**.

## Automation Tools

- `Tools/BootstrapGeurtsInstructions.ps1` - use `-Mode Check` for initialization, `-Mode Update` for safe synchronization, and `-Mode Validate` for local validation.
- `Tools/CreateGeurtsFolderStructure.ps1` - create allowed folders from the machine-readable definition without deleting user content.
- `Tools/ManageGeurtsAgentInstructions.ps1` - safely create, migrate, and update managed native AI-entry sections.
- `Tools/UpdateGameDesignManifest.ps1` - deterministically maintain the project GDD manifest.

`Tools/ManageGeurtsAgentInstructions.ps1` creates missing `Docs/GameDesign/README.md` and `Docs/GameDesign/GameDesignManifest.md` from controlled templates without overwriting project-specific content.

## Supporting Documents

- `Ideas/GameForgeIntelligenceIdeas.md` - non-normative proposals, open decisions, and deferred plugin work.
- `Migrations/v0.8.0.md` - migration notes for public access, contract reconciliation, and custom `.gitignore` provisioning.
- `Migrations/v0.7.0.md` - migration from legacy synchronized layouts and native instruction files.

## Important Classification

`GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` controls chat-response behaviour. It is not a Unity coding, architecture, engineering, or implementation standard unless a later manifest explicitly reclassifies it.

## Version Selection

When multiple versions of the same technique exist, use the highest semantic version. When versions tie, prefer the canonical repository/path declared by the technique or manifest.

## Changelog

### v0.8.0

- Aligned canonical synchronization with public anonymous read-only repository access.
- Added contract reconciliation and explicit compatibility reporting through integration contract v0.9.0.
- Added a hash-validated custom Unity project `.gitignore` payload and safe create-if-missing plugin setup with a visible default fallback.
- Preserved the three-entry synchronized top-level layout by storing the payload inside `GeurtsTechniques/`.

### v0.7.0

- Made AI coding agents and automated development systems the primary audience.
- Changed the strict technical priority to Extendibility, Efficiency, Readability, Updated, and Documented while retaining the multiplayer override.
- Added machine-readable folder creation, lightweight GDD discovery, deterministic manifest maintenance, and safe GDD scaffolding contracts.
- Added safe managed native-entry upgrades and check/update modes that preserve the last valid synchronized copy.
- Named Game Forge Intelligence as the current plugin and documented authenticated private distribution.
- Added the integration contract, ideas document, migration guide, and automated validation coverage.

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
