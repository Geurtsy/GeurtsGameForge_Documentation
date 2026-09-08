# Geurts Technique Package Manifest

**Version:** 0.11.5
**Unity target:** Unity 6.3 LTS (6000.3)
**Status:** Draft normative package manifest
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Required package path:** `GeurtsTechniqueManifest.md`

## 1. Manifest Resolver

This manifest is the single authoritative resolver for package-file selection, versions, subject ownership, applicability, post-entry reading order, and cross-document conflicts. Other package files define only their assigned subjects and defer resolution back here.

Use this normative file read sequence:

1. Read the package `AGENTS.md` as the first repository entry.
2. Read its sibling `AI_READ_FIRST.md` as the second-stage local-package and session router.
3. Read this manifest.
4. Read the selected Documentation Companion Technique and then its machine-readable Contract when that independent companion boundary is involved.
5. Read the frozen Game Forge Intelligence 2.0 compatibility technique only when maintaining or assessing that legacy integration; its documentation update lifecycle is superseded in this package version.
6. Read other selected generic subject techniques in this order when applicable: Technical; Brick Contract and then its Catalogue; Game Forge Automation; Folder Structure and then its Definition; AI Agent Setup; Game Design Documentation; Git Ignore; chat-only Response Control.
7. Read applicable project-specific game-design facts selected through the Game Design Documentation Technique before player-facing implementation.
8. Apply relevant product- or plugin-owned conditional policy last. Such policy remains subordinate within the Geurts package's subjects.

For an installed Unity-project package, steps 1 through 3 use:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/AGENTS.md
<ProjectRoot>/GeurtsGameForgeDocumentation/AI_READ_FIRST.md
<ProjectRoot>/GeurtsGameForgeDocumentation/GeurtsTechniqueManifest.md
```

Every selected package file must come from the same validated package commit. The Documentation Companion Contract selects an archive of the exact resolved authoritative `main` head commit; a version found elsewhere is not permission to mix files from different commits. The frozen Game Forge Intelligence 2.0 compatibility technique may describe its released integration, but it no longer owns or authorizes documentation setup, checking, acquisition, or replacement under package v0.11.5. The numbered sequence above is the normative post-entry read order. Applicability comes only from the table below. When two selected documents discuss the same action, the table's assigned subject owner controls that subject; if the assignment does not determine a material conflict, surface it to the current user instead of inventing precedence.

Under a confirmed Documentation Companion Update, the separate `<ProjectRoot>/AGENTS.md` is one of four closed, whole-file managed AI routes and is replaced from its exact documentation-owned template. Outside that companion lifecycle, the optional manual native-entry manager retains its region-preserving rules. In either case, the route is only a concise external-tool discovery shim to `GeurtsGameForgeDocumentation/AGENTS.md`; it is not a competing authority or a companion startup entry.

## 2. Subject Ownership and Applicability

| Subject | Manifest-selected owner | When selected |
|---|---|---|
| Technical implementation and technical trade-offs | `GeurtsTechniques/GeurtsTechnicalTechnique.md` | Before implementation or technical planning. This technique is the sole package owner of the five technical priorities and multiplayer override. |
| Existing-brick reuse, shared lifecycle/settings contracts and machine-readable catalogue | `GeurtsTechniques/GeurtsBrickContract.md` and `GeurtsTechniques/GeurtsBrickCatalogue.json` | Before implementing Geurts Unity functionality or installing, updating or maintaining a brick. Read after Technical and before Automation. The current user's mandatory-tool rule supersedes older companion tool exemptions for the Unity implementation. |
| Generic AI-assisted automation and project-aware operational behaviour | `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` | When an agent or automation plans, changes, validates, or reports project work. |
| Folder meaning, placement, and ownership | `GeurtsTechniques/GeurtsFolderStructureTechnique.md` | When creating, moving, renaming, or placing any file, script, asset, scene, document, or folder, and when inspecting or validating project structure. |
| Exact folder-creation registry | `GeurtsTechniques/GeurtsFolderStructureDefinition.json` | When a tool creates or validates managed folders. |
| Native AI routes, companion whole-file replacement boundary, managed regions, and optional manual setup tooling | `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` | When creating, replacing, migrating, validating, or explaining native AI route files or GDD scaffolds. |
| Project-specific design-document discovery and maintenance boundary | `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` | Before player-facing work, when design facts are needed, or when GDD discovery/manifest maintenance is requested. Relevant project GDD files selected by `Docs/GameDesign/GameDesignManifest.md` are mandatory design facts. |
| Independent Windows Unity Editor companion source, metadata check, confirmed replacement, project-boundary, and AI-routing lifecycle | `GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md` | When the Geurts Documentation Companion checks metadata, offers or performs Update, validates a candidate, replaces managed content, or reports conformance. |
| Exact companion source, documentation destination, validation entries, confirmation targets, and template-to-route mappings | `GeurtsTechniques/GeurtsDocumentationCompanionContract.json` | Whenever the Documentation Companion Technique is selected or its schema is implemented or validated. |
| Frozen Game Forge Intelligence 2.0 integration compatibility | `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` | Only when maintaining or assessing a released v2 consumer. Its historical updater is non-applicable under package v0.11.5; current setup, checking, and Update belong exclusively to the Documentation Companion. |
| Approved project-root `.gitignore` payload | `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` | When validating or provisioning that exact payload. |
| Chat-only response style and scope | `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` | Only when a compatible chat interface explicitly selects it. It is never a coding or architecture standard. |

`Ideas/GameForgeIntelligenceIdeas.md` is non-normative. Files under `Migrations/` describe historical or version-transition behaviour and do not override the active package.

### 2.1 Conflict resolution

- Apply the current user's explicit instruction when it is applicable to the requested work. It supplies task authority and context but is not a package file or an alternate file-read entry.
- Use the manifest-selected subject owner; a technique must not declare a competing cross-document order.
- Apply project-specific design facts in their scope. If a missing choice would establish or change design intent, ask the user instead of inventing it. Assumptions are limited to reversible technical details that do not create or overwrite design facts.
- When project design documents conflict, use explicit authority or precedence recorded in `Docs/GameDesign/GameDesignManifest.md`. If the index does not resolve a material conflict, surface it and ask when resolution would establish design intent; do not select a stray document by version or date alone.
- Applicable user-authored project instructions remain project authority within their scope and must be preserved at every unlisted path. The only exception is the exact four AI-route files that one confirmed Documentation Companion Update replaces in full; its cancel-default dialog must identify them before approval. Surface any material conflict outside that closed authorization instead of silently discarding either instruction.
- The managed project-root shim has no substantive authority of its own.
- Product-specific or plugin-owned conditional material may narrow its own feature behaviour, but it cannot replace or silently override the selected generic Geurts subject owner.
- For an actual technical trade-off, apply the priorities owned by `GeurtsTechnicalTechnique.md`; do not reproduce or reorder them elsewhere.

## 3. Package File Registry

Every path between the markers is part of the v0.11.5 repository package and must exist. The Role column describes package use only; current setup and replacement belong exclusively to the Documentation Companion Technique and its closed contract. The frozen Game Forge Intelligence 2.0 technique remains only for released-consumer compatibility and does not authorize a second updater.

<!-- GEURTS-PACKAGE-FILES:BEGIN -->

| Path | Version | Role |
|---|---:|---|
| `AGENTS.md` | 0.11.5 | First repository entry; routes to `AI_READ_FIRST.md`. |
| `AI_READ_FIRST.md` | 0.11.5 | Second-stage local-package and session router from `AGENTS.md` to this manifest. |
| `GeurtsTechniqueManifest.md` | 0.11.5 | Package index and single resolver for selection, versions, applicability, subject ownership, order, and conflicts. |
| `README.md` | 0.11.5 | Repository overview and package changelog. |
| `GeurtsTechniques/GeurtsTechnicalTechnique.md` | 0.9.0 | Normative technical implementation, Unity 6.3 LTS and required Odin Inspector/Quantum Console baseline, and strict-priority owner. |
| `GeurtsTechniques/GeurtsBrickContract.md` | 1.1.0 | Shared brick reuse, lifecycle, settings, catalogue and package-operation contract. Unreleased addition. |
| `GeurtsTechniques/GeurtsBrickCatalogue.json` | 0.11.5 | Authoritative data-only catalogue; unpublished God/Diagnostics versions have no release install actions. |
| `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` | 0.9.0 | Normative generic AI-assisted automation technique. |
| `GeurtsTechniques/GeurtsFolderStructureTechnique.md` | 0.10.0 | Normative explanatory folder authority, including companion-managed placement and strict non-managed boundaries. |
| `GeurtsTechniques/GeurtsFolderStructureDefinition.json` | 0.11.5 | Machine-readable folder-creation authority; definition v0.10.0. |
| `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` | 1.0.0 | Normative four-route companion replacement exception and separate preservation-based manual setup technique. |
| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` | 0.10.0 | Normative GDD discovery, byte-preservation, and companion no-access boundary technique. |
| `GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md` | 1.0.1 | Normative lifecycle for the independent Windows Editor-only UPM documentation companion; contract schema 1.0.0. |
| `GeurtsTechniques/GeurtsDocumentationCompanionContract.json` | 0.11.5 | Machine-readable companion contract; declares package version 0.11.5 and schema 1.0.0. |
| `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` | 2.0.0 | Frozen released-consumer compatibility technique; its schema-2.0.0 updater is superseded and non-applicable under package v0.11.5. |
| `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` | 2.0.0 | Non-normative compatibility redirect from the released legacy path; never selected as a second authority. |
| `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` | 1.0.0 | Normative approved project-root `.gitignore` payload. |
| `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` | 1.1 | Chat-only response technique; not an implementation standard. |
| `Ideas/GameForgeIntelligenceIdeas.md` | 0.11.0 | Non-normative historical idea register and product-work pointer, explicitly subordinate to the companion contract. |
| `Migrations/v0.11.0.md` | 0.11.0 | Non-normative transition guide for the independent companion and closed whole-file AI-route contract. |
| `Migrations/v0.10.0.md` | 0.10.0 | Non-normative transition guide for the explicit destructive manual-update model. |
| `Migrations/v0.9.0.md` | 0.9.0 | Non-normative historical note for the obsolete automatic transaction/recovery model. |
| `Migrations/v0.8.0.md` | 0.8.0 | Non-normative historical note for public access and custom `.gitignore` provisioning. |
| `Migrations/v0.7.0.md` | 0.7.0 | Non-normative historical note for v0.4-v0.6 integrations. |
| `Tools/CreateAIAgentInstructionFiles.bat` | 0.9.0 | Compatibility launcher for managed AI setup. |
| `Tools/ManageGeurtsAgentInstructions.ps1` | 0.11.5 | Optional manual native-entry migration and GDD scaffolding manager; never invoked by the companion. |
| `Tools/CreateGeurtsFolderStructure.bat` | 0.9.0 | Compatibility launcher for definition-driven folder creation. |
| `Tools/CreateGeurtsFolderStructure.ps1` | 0.11.5 | Definition-driven, create-only folder tool; never invoked by the companion. |
| `Tools/UpdateGameDesignManifest.ps1` | 0.10.0 | Deterministic GDD manifest maintainer. |
| `Tools/NativeEntryMigrationCatalog.json` | 1.0.0 | Native-entry exact-fingerprint migration catalog for the four v1.0.0 brick-aware route templates. |
| `Tools/ValidateGeurtsDocumentation.ps1` | 0.11.6 | Package, Unity-target/example, path, version, authority, companion-contract, lifecycle-boundary, and payload validator. |
| `Tools/AIAgentInstructionTemplates/AGENTS.md` | 1.0.0 | Managed Codex route requiring brick agents to read the installed documentation before planning or modifying code. |
| `Tools/AIAgentInstructionTemplates/copilot-instructions.md` | 1.0.0 | Managed Copilot route requiring brick agents to read the installed documentation before planning or modifying code. |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md` | 1.0.0 | Managed scoped Unity route requiring brick agents to use the installed documentation as source of truth. |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md` | 1.0.0 | Managed scoped game-design route requiring brick agents to use the installed documentation as source of truth. |
| `Tools/AIAgentInstructionTemplates/GameDesign/README.md` | 0.10.0 | Create-if-missing project GDD routing scaffold. |
| `Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md` | 0.7.0 | Create-if-missing deterministic GDD manifest scaffold. |
| `Tools/Tests/RunAutomationTests.ps1` | 0.11.6 | Temporary-project automation, Unity-target/example, and lifecycle-regression suite. |

<!-- GEURTS-PACKAGE-FILES:END -->

## 4. Owner Pointers

- The selected Documentation Companion Technique owns the independent Windows-only, Editor-only UPM lifecycle; its JSON Contract owns the exact source, managed destinations, validation entries, confirmation targets, and four route mappings. The manifest does not restate that lifecycle.
- The frozen Game Forge Intelligence 2.0 Technique may be selected only for released-consumer compatibility. It is not a Documentation Companion dependency and cannot own or authorize a second documentation check, setup, or Update lifecycle under package v0.11.5.
- The selected Folder, AI Agent Setup, GDD, Git Ignore, Technical, and Automation authorities own their respective generic tool and project-work rules.
