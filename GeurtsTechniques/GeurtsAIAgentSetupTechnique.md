# Geurts AI Agent Setup Technique

**Native AI Instruction Setup - Copilot, Codex, and Future Agents**  
**Version:** 0.7.0
**Status:** Draft supporting technique  
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Canonical path:** `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`  
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the canonical repository and path shown above.

---

## Purpose

This document defines how Geurts Game Forge exposes its development rules to Codex, GitHub Copilot, and compatible AI coding agents and automated development systems.

Native agent files must remain concise. Their job is to route agents into the canonical documentation system, not to duplicate every technique.

The authoritative interpretation rules are in `AI_READ_FIRST.md`. AI reliability, explicit ownership, literal paths, and deterministic validation take precedence over stylistic elegance.

---

## Integration Identity and Canonical Source

**Game Forge Intelligence** is the current concrete Unity plugin. Use **Geurts-compatible Unity AI integration package** only as the generic category for reusable implementations of this contract.

The authoritative documentation repository is:

`https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`

Canonical branch:

`main`

The current distribution strategy is an authenticated private canonical repository. Do not assume anonymous clone access. Authentication failures must be reported with actionable guidance.

Game Forge Intelligence and compatible packages store the last validated copy at:

`<ProjectRoot>/GeurtsGameForgeDocumentation/`

and direct every native AI entry to:

`<ProjectRoot>/GeurtsGameForgeDocumentation/AI_READ_FIRST.md`

A synchronized local copy is a cache of the canonical repository. It must not become a competing source of truth or be described as current after a failed update check.

The reusable integration requirements are defined in `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.

---

## Project-Local Documentation Layout

Use this visible project-root directory:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

The required core layout is:

```text
GeurtsGameForgeDocumentation/
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
└── GeurtsTechniques/
```

Do not use a hidden or nested substitute for the canonical project-local path unless the user explicitly changes this contract.

Project-specific design documents are separate:

```text
<ProjectRoot>/Docs/GameDesign/
```

The synchronized documentation layout contains exactly the three visible entries shown above. Never put project GDD files in `GeurtsGameForgeDocumentation/` or canonical techniques in `Docs/GameDesign/`.

---

## AI Documentation Entry Point

All AI agents reaching the canonical repository must begin with:

`AI_READ_FIRST.md`

Within a synchronized Unity project, begin with:

`<ProjectRoot>/GeurtsGameForgeDocumentation/AI_READ_FIRST.md`

That file owns the universal reading order, task routing, authority order, path boundary, and pre-code lock.

---

## Codex

Codex should receive repository-level instructions from:

`AGENTS.md`

For a Unity project using a compatible integration package, the generated project-root `AGENTS.md` should:

1. identify the canonical GitHub repository;
2. require successful session initialization before code changes;
3. point Codex to `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`;
4. prohibit project changes until required documentation has been read;
5. keep implementation standards in the synchronized techniques rather than duplicating them locally.

---

## Required Initialization and Pre-Code Sequence

Before creating, modifying, moving, renaming, or deleting target-project files, AI agents must follow:

`CHECK LOCAL DOCS -> UPDATE WHEN REQUIRED -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

### CHECK LOCAL DOCS

Normal prompts use the last validated local documentation and do not contact GitHub.

At Unity-project opening or AI-session initialization, Game Forge Intelligence performs one lightweight commit/version check through:

```text
Tools/BootstrapGeurtsInstructions.ps1 -Mode Check
Tools/BootstrapGeurtsInstructions.ps1 -Mode Update
Tools/BootstrapGeurtsInstructions.ps1 -Mode Validate
```

Use `-Mode Check` for the lightweight comparison, `-Mode Update` for safe synchronization, and `-Mode Validate` for local validation. When no update exists, report the validated local commit and continue. When an update exists, report current and available versions/commits and follow package policy to update automatically or request approval. After success, report the exact synchronized commit. The manual action is named **Update Geurts Game Forge Documentation**.

The update must acquire a target-scoped single-writer lock, then stage and validate before replacing the live copy. Validation requires `AI_READ_FIRST.md`, `GeurtsTechniqueManifest.md`, every manifest-listed synchronized file with matching version and canonical path, deep folder-definition safety and Markdown parity, and chat-only classification. Failed authentication, network, checkout, validation, or file locking must preserve the previous valid copy and be reported distinctly. An invalid first installation must be removed rather than reported as a valid local copy.

v0.7.0 has no approved bundled fallback. Package policy or the user may explicitly permit the last validated local copy as a potentially stale fallback. Report its version and commit, and never let it outrank a newer successfully synchronized canonical copy. Without an allowed fallback, required synchronization failure blocks project modification.

### READ

Read:

1. `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`.
2. `GeurtsGameForgeDocumentation/GeurtsTechniqueManifest.md`.
3. `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`.
4. `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsTechnicalTechnique.md`.
5. `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureTechnique.md`.
6. `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` for integration or automation changes.
7. Project-specific design documentation when `AI_READ_FIRST.md` classifies the task as player-facing.

At initialization, read `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` once when it exists and retain its version/hash/timestamp fingerprint. Re-read it when the fingerprint changes. This lightweight discovery does not require loading every full GDD.

### INSPECT

Search the target repository for the existing implementation before creating a new system. Avoid duplicate systems and preserve working behaviour unless the task requires changing it.

### PLAN, IMPLEMENT, VALIDATE, REPORT

Choose the smallest maintainable change, implement it, run relevant validation, and report changed files and unresolved issues.

---

## GitHub Copilot

GitHub Copilot may use:

`.github/copilot-instructions.md`

and path-specific files under:

`.github/instructions/*.instructions.md`

Those files must route back to `GeurtsGameForgeDocumentation/AI_READ_FIRST.md` and remain concise.

---

## Safe Managed Native AI Entries

Use:

```text
Tools/ManageGeurtsAgentInstructions.ps1
```

for these project files:

- `AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/instructions/geurts-unity.instructions.md`
- `.github/instructions/geurts-game-design.instructions.md`

The updater must classify each file using the integration contract's stable states:

- `fully-managed`;
- `partially-managed` through explicit begin/end markers;
- `user-owned`;
- `legacy-exact` or `legacy-modified`.

It may refresh Geurts-owned content when the template version changes. It must preserve user-authored content outside managed sections, respect the documented opt-out marker, and never silently replace a user-owned file. Before potentially destructive legacy replacement, create a backup or stop visibly.

Markdown regions use strict HTML `GEURTS-MANAGED-BEGIN` and `GEURTS-MANAGED-END` comments with matching IDs, template version, managed-payload hash, and required `-->` closers. YAML frontmatter uses strict `#` comment markers inside the opening and closing frontmatter delimiters. A valid managed region with a newer unsupported version is a visible conflict and must never be downgraded. The exact file opt-out signal is `GEURTS-MANAGED-OPT-OUT`.

Each run must be idempotent and report `created`, `updated`, `preserved`, `skipped`, and `conflicted` files. Known v0.4, mixed v0.5, and v0.6 entry styles require migration validation coverage.

---

## Safe Game Design Scaffolding

`Tools/ManageGeurtsAgentInstructions.ps1` creates only missing:

```text
<ProjectRoot>/Docs/GameDesign/
<ProjectRoot>/Docs/GameDesign/README.md
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

from controlled templates under `Tools/AIAgentInstructionTemplates/GameDesign/`.

Re-running setup must report created and existing paths and must not overwrite project-specific content. Before any mutation, the manager validates the exact migration catalog, native-entry and GDD profile authority, every source and target path, and rejects junctions, symbolic links, or other reparse points that could redirect writes outside `<ProjectRoot>`. Templates must mark unknown design decisions as unprovided and must not fabricate mechanics, narrative, balance values, progression, characters, or other design facts.

After scaffolding, the managed setup invokes `Tools/UpdateGameDesignManifest.ps1` for deterministic manifest maintenance. The detailed discovery and maintenance rules are in `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` and the plugin-facing contract is in `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`.

---

## Folder Creation Automation

`Tools/CreateGeurtsFolderStructure.ps1` consumes `GeurtsTechniques/GeurtsFolderStructureDefinition.json`. The Markdown Folder Structure Technique remains the explanatory and placement authority; the JSON definition is the folder-creation automation authority.

Automation may create only entries that explicitly permit creation. It must never delete user project content merely because a path is removed from a later definition. A contradiction between the JSON definition and the Markdown technique is a validation failure and blocks automated folder changes.

---

## Chat-Only Classification

`GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` controls chat-response behaviour.

It is not a Unity coding, software architecture, engineering, folder, or implementation standard unless a later manifest explicitly reclassifies it.

---

## Strict Priority Standards

The current default technical priority order is:

1. **Extendibility**
2. **Efficiency**
3. **Readability**
4. **Updated**
5. **Documented**

Higher-numbered principles must not silently override lower-numbered principles.

For multiplayer systems, **network efficiency overrides all other priorities**.

---

## Maintenance Rule

When canonical techniques change:

- update `GeurtsTechniqueManifest.md`;
- update `AI_READ_FIRST.md` if reading order, paths, or authority changes;
- review native AI instruction templates;
- update `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` when the shared integration contract changes;
- preserve compatibility with package bootstrap consumers when practical;
- explicitly version breaking bootstrap changes.

Do not turn native instruction files into large duplicate manuals unless a specific AI tool requires it.
