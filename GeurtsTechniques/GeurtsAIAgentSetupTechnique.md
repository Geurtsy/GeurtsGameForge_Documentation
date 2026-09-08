<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts AI Agent Setup Technique

**Native AI Instruction Setup - Copilot and supported scoped routes**
**Version:** 2.0.0
**Status:** Draft normative technique
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Required package path:** `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`

## Purpose and Manifest Boundary

This technique owns the three exact native AI routes used by the Documentation Companion, the companion's whole-file replacement exception, and the separate optional manual manager's managed regions, exact-fingerprint legacy migration, and create-if-missing GDD scaffolds. `GeurtsTechniqueManifest.md` selects this file and version, determines its place in the package read order, and resolves cross-document applicability and conflicts.

Native entries remain concise. They route an agent into the project-local fetched copy and do not duplicate package policy, integration lifecycle, technical priorities, game-design rules, or product behaviour.

## Required Native Route

Every Geurts-managed native AI entry routes first to:

```text
GeurtsGameForgeDocumentation/AI_READ_FIRST.md
```

AI_READ_FIRST.md is the first documentation entry and routes to the package manifest. Routes must use that entry directly and must not bypass manifest selection by pointing to a technique.

The Documentation Companion's closed whole-file mappings are:

| Documentation-owned source template | Project-relative target |
|---|---|
| `Tools/AIAgentInstructionTemplates/copilot-instructions.md` | `.github/copilot-instructions.md` |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md` | `.github/instructions/geurts-unity.instructions.md` |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md` | `.github/instructions/geurts-game-design.instructions.md` |

`GeurtsTechniques/GeurtsDocumentationCompanionContract.json` owns the machine-readable copy of this exact mapping. The companion must not infer or discover any additional route.

The AGENT.md Technique owns the separately installed Codex guide. The legacy manual manager handles only the three Copilot routes and must leave Codex guide files untouched.

These routes can guide only AI tools that support the applicable native instruction surface or have been explicitly instructed to read and follow `AI_READ_FIRST.md`. Creating the files does not make every AI product discover or obey the Geurts documentation automatically.

Every v1.1.0 route template gives brick work the same concise rule: before planning or modifying any Geurts Game Forge brick code, read and follow `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`, then treat the installed documentation selected through its manifest chain as the source of truth for that work.

## Documentation Companion Whole-File Replacement

The independent Windows-only, Editor-only companion is installed from Git through Unity Package Manager. It has no Geurts Game Forge God, Game Forge Intelligence, Odin Inspector, or Quantum Console dependency. It has no external installer or bootstrap and must not execute a batch, PowerShell, or project script for setup or Update.

When the user selects `Update Geurts Game Forge Documentation`, the companion immediately shows one confirmation that identifies the complete `GeurtsGameForgeDocumentation/` folder and all three exact route targets above as overwrite targets. Cancel is the initially focused default. There is no earlier preview or dry run and no second confirmation. After affirmative confirmation, the companion directly replaces each route as a complete file with the bytes of its mapped template from the same validated authoritative archive used for the documentation copy.

Confirmation intentionally authorizes discarding every existing byte in those three files. Companion replacement does not merge managed regions, preserve surrounding content, honor `GEURTS-MANAGED-OPT-OUT`, migrate legacy payloads, create per-file backups, or inspect files other than the three declared targets. It may create only missing `.github/` and `.github/instructions/` parent directories required for those targets and must leave every unlisted file and directory under those parents untouched.

The companion reports Update success only after the complete documentation destination and all three route files are present and complete. A failure after mutation begins may leave a partial result; it must be reported as failure, and the only retry is another explicit confirmed Update. The companion must not inspect or change `Docs/GameDesign/`, run the manual manager, create GDD scaffolds, update the GDD manifest, create the full folder structure, or provision `.gitignore`.

This deliberately bounded whole-file authority is the only exception to the preservation-based manual rules below.

## Legacy Manual Manager Preservation

This section applies only to legacy or separately authorized generic maintenance outside the companion lifecycle. The manual manager is not a supported alternative for provisioning or updating the three companion-managed routes in a companion project. When a user deliberately invokes `Tools/ManageGeurtsAgentInstructions.ps1` in another context, it may change only a missing file, a valid supported Geurts-managed region, or an exact supported legacy payload. It must:

- preserve bytes outside the managed region;
- preserve supported UTF-8, UTF-8-BOM, UTF-16LE-BOM, or UTF-16BE-BOM encoding and the target managed region's newline convention;
- reject invalid text and UTF-32 without mutation;
- honor the exact `GEURTS-MANAGED-OPT-OUT` signal;
- refuse malformed, modified, unknown, or future managed content;
- create the required narrow per-file backup before any supported edit of an existing native entry;
- avoid following junctions, symbolic links, or other reparse points outside the validated Unity project root;
- remain idempotent; and
- report `created`, `updated`, `preserved`, `skipped`, and `conflicted` outcomes distinctly.

Every atomic write carries an explicit expected target state: absent for a create, or the exact raw-byte fingerprint captured during validation for an update or legacy migration. Immediately before promotion, the manager revalidates containment and the complete path chain for new reparse points, then rejects an unexpected file or any byte drift as a conflict. A backup does not authorize replacing concurrent user content.

Before promoting an adjacent safety backup, the manager likewise revalidates source and backup containment, both complete path chains, the expected raw-byte fingerprint, and the backup's expected absence. A failed backup guard preserves the target and promotes no backup.

The same final containment and full-chain reparse check applies immediately before the manager accepts an existing delegated setup directory or creates a missing one. A path changed after preflight must fail without creating content outside the project.

A recorded version is metadata only and never authorizes replacement. Generic legacy migration is limited to a Geurts-owned legacy template or managed region with structurally valid Geurts markers and an exact supported normalized fingerprint from `Tools/NativeEntryMigrationCatalog.json`.

Markdown managed regions use matching `GEURTS-MANAGED-BEGIN` and `GEURTS-MANAGED-END` HTML comments with an ID, template version, payload SHA-256, and valid comment closers. YAML-frontmatter regions use the catalog's matching `#` markers inside the frontmatter delimiters. A valid newer unsupported managed version is a conflict and must not be downgraded.

The narrow backup made before a supported per-file managed edit protects that native entry only. It is not companion Update backup or rollback and grants no authority over the project-local managed documentation copy. This generic per-file safeguard remains independent from the companion lifecycle.

## Product-Owned or Unrecognized Legacy Entries

The generic manager and its three-entry Geurts catalog own only Geurts-managed markers and templates. A product-owned or otherwise unrecognized block is outside their mutation authority: preserve it unchanged and report a conflict. Any product-specific migration belongs to that product's integration and must preserve surrounding and user-authored content. Preserved legacy material must not be loaded as a competing Geurts package authority.

## Legacy Manual Tool Invocation

The package tools live inside the documentation container. Invoke them from their copied paths and always supply the validated Unity project root explicitly; do not assume a duplicate package-tool copy under `<ProjectRoot>/Tools/` or infer the project from the current working directory. A separate project-owned `<ProjectRoot>/Tools/` directory may still exist under the Folder Structure Technique.

Example from any working directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>"
```

This legacy manual command changes supported native managed regions only. It is not required by, invoked by, equivalent to, or a supported alternative for the Documentation Companion's installation or Update. Documentation acquisition and whole-file companion replacement are outside this manager. GDD scaffolding and GDD manifest maintenance require the separate positive opt-ins below.

PowerShell 7 may use `pwsh` with the same script path and arguments. The retained batch file is only a compatibility launcher for a user who deliberately chooses the separate manual manager; it is not an external installer or bootstrap, and the companion must never scan for or execute it.

Before writing, the manager validates that `-ProjectRoot` is a Unity project containing `Assets/`, `Packages/`, and `ProjectSettings/`, that the tool is not treating its source checkout or project-local fetched documentation copy as the project root, and that all source and target paths remain within their intended roots.

## Separately Authorized Create-If-Missing GDD Scaffolding

Native-entry creation or migration does not implicitly create or update `Docs/GameDesign/`. A separate, explicit user-authorized GDD scaffolding operation may use the setup manager to create only missing:

```text
<ProjectRoot>/Docs/GameDesign/
<ProjectRoot>/Docs/GameDesign/README.md
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

It uses controlled templates under `GeurtsGameForgeDocumentation/Tools/AIAgentInstructionTemplates/GameDesign/`. Re-running the authorized scaffolding operation preserves every existing project-specific file. Templates identify unknown design decisions as unprovided and must not fabricate project design facts.

Invoke that separate operation with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -IncludeGameDesignScaffolding
```

`-IncludeGameDesignScaffolding` creates missing scaffolds only; it does not update the GDD manifest. Manifest maintenance is a third independently authorized effect. Invoke it through the manager with the positive opt-in:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/ManageGeurtsAgentInstructions.ps1" -ProjectRoot "<ProjectRoot>" -UpdateGameDesignManifest
```

The same independently authorized maintenance may invoke the copied maintainer directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<ProjectRoot>/GeurtsGameForgeDocumentation/Tools/UpdateGameDesignManifest.ps1" -ProjectRoot "<ProjectRoot>"
```

The Game Design Documentation Technique owns discovery, import, drift, and no-invention rules. This setup technique owns only safe invocation and create-if-missing scaffolding.

These independent opt-ins describe optional manual manager use. The companion's `Update Geurts Game Forge Documentation` action must not invoke this manager; it applies the separately confirmed whole-file mappings defined above. Any separately invoked manual native-entry operation requires its own explicit user action and must apply the exact-fingerprint, preservation, conflict, backup, and opt-out rules above. It still must not create GDD scaffolding or update the GDD manifest without the separate explicit authorization above.

## Delegated Setup Subjects

- Folder creation uses the copied `Tools/CreateGeurtsFolderStructure.ps1` with explicit `-ProjectRoot`; folder meaning and permitted creation remain owned by the manifest-selected Folder Structure Technique and Definition.
- Project-root `.gitignore` payload and preservation behaviour remain owned by the manifest-selected Git Ignore Technique.
- Documentation checking, acquisition, complete destination replacement, exact route mappings, and companion-specific reading remain owned exclusively by the manifest-selected Documentation Companion Technique and Contract. The frozen Game Forge Intelligence 2.0 technique exists only for released-consumer compatibility; its historical updater is non-applicable and it is not a companion dependency.

## Maintenance

When a managed template changes, update its version, normalized payload hash, migration catalog, companion contract mapping and validation entries, manifest registry row, manual-manager behaviour, regression tests, and validator expectations together. Never update a template without preserving the manual manager's safe migration and opt-out contract. Companion Update still replaces each mapped target as a complete file after confirmation.

## Separate Codex guide installation

The AGENTS.md Technique owns the separate **Install Codex guide** action. Documentation Update excludes Codex guides. The user chooses a folder and confirms replacement of only its AGENTS.md; that guide points directly to the installed AI_READ_FIRST.md. No guide is automatically created at the project root or shipped as a standalone file inside this documentation package. Update the companion to 0.7.0 before installing this schema-2.0.0 documentation release.
