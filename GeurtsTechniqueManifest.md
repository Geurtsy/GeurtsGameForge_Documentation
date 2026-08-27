# Geurts Technique Package Manifest

**Version:** 0.9.0
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
4. Read the selected Game Forge Intelligence package technique when that integration boundary is involved.
5. Read other selected generic subject techniques in this order when applicable: Technical; Game Forge Automation; Folder Structure and then its Definition; AI Agent Setup; Game Design Documentation; Git Ignore; chat-only Response Control.
6. Read applicable project-specific game-design facts selected through the Game Design Documentation Technique before player-facing implementation.
7. Apply relevant product- or plugin-owned conditional policy last. Such policy remains subordinate within the Geurts package's subjects.

For an installed Unity-project package, steps 1 through 3 use:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/AGENTS.md
<ProjectRoot>/GeurtsGameForgeDocumentation/AI_READ_FIRST.md
<ProjectRoot>/GeurtsGameForgeDocumentation/GeurtsTechniqueManifest.md
```

Every selected package file must come from the same validated package commit. A higher version elsewhere signals an available update; it is not permission to mix files from different commits. The numbered sequence above is the normative post-entry read order. Applicability comes only from the table below. When two selected documents discuss the same action, the table's assigned subject owner controls that subject; if the assignment does not determine a material conflict, surface it to the current user instead of inventing precedence.

The separate `<ProjectRoot>/AGENTS.md` remains user-owned except for an explicitly managed Geurts region. That managed region is only a concise external-tool discovery shim to `GeurtsGameForgeDocumentation/AGENTS.md`; it is not a competing authority or an integration startup entry.

## 2. Subject Ownership and Applicability

| Subject | Manifest-selected owner | When selected |
|---|---|---|
| Technical implementation and technical trade-offs | `GeurtsTechniques/GeurtsTechnicalTechnique.md` | Before implementation or technical planning. This technique is the sole package owner of the five technical priorities and multiplayer override. |
| Generic AI-assisted automation and project-aware operational behaviour | `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` | When an agent or automation plans, changes, validates, or reports project work. |
| Folder meaning, placement, and ownership | `GeurtsTechniques/GeurtsFolderStructureTechnique.md` | When creating, moving, renaming, or placing any file, script, asset, scene, document, or folder, and when inspecting or validating project structure. |
| Exact folder-creation registry | `GeurtsTechniques/GeurtsFolderStructureDefinition.json` | When a tool creates or validates managed folders. |
| Native AI entries, managed regions, and setup tooling | `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` | When creating, migrating, validating, or explaining native AI entry files or GDD scaffolds. |
| Project-specific design-document discovery and maintenance boundary | `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` | Before player-facing work, when design facts are needed, or when GDD discovery/manifest maintenance is requested. Relevant project GDD files selected by `Docs/GameDesign/GameDesignManifest.md` are mandatory design facts. |
| Game Forge Intelligence documentation-consumption and compatibility boundary | `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` | Only when Game Forge Intelligence consumes this package or reports its compatibility. |
| Approved project-root `.gitignore` payload | `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` | When validating or provisioning that exact payload. |
| Chat-only response style and scope | `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` | Only when a compatible chat interface explicitly selects it. It is never a coding or architecture standard. |

`Ideas/GameForgeIntelligenceIdeas.md` is non-normative. Files under `Migrations/` describe historical or version-transition behaviour and do not override the active package.

### 2.1 Conflict resolution

- Apply the current user's explicit instruction when it is applicable to the requested work. It supplies task authority and context but is not a package file or an alternate file-read entry.
- Use the manifest-selected subject owner; a technique must not declare a competing cross-document order.
- Apply project-specific design facts in their scope. If a missing choice would establish or change design intent, ask the user instead of inventing it. Assumptions are limited to reversible technical details that do not create or overwrite design facts.
- When project design documents conflict, use explicit authority or precedence recorded in `Docs/GameDesign/GameDesignManifest.md`. If the index does not resolve a material conflict, surface it and ask when resolution would establish design intent; do not select a stray document by version or date alone.
- Applicable user-authored project instructions remain project authority within their scope. Preserve them, and surface any material conflict to the current user instead of silently discarding either instruction.
- The managed project-root shim has no substantive authority of its own.
- Product-specific or plugin-owned conditional material may narrow its own feature behaviour, but it cannot replace or silently override the selected generic Geurts subject owner.
- For an actual technical trade-off, apply the priorities owned by `GeurtsTechnicalTechnique.md`; do not reproduce or reorder them elsewhere.

## 3. Package File Registry

Every path between the markers is part of the v0.9.0 repository package and must exist. The Role column describes package use only; installation behaviour belongs to the applicable manifest-selected integration technique.

<!-- GEURTS-PACKAGE-FILES:BEGIN -->

| Path | Version | Role |
|---|---:|---|
| `AGENTS.md` | 0.9.0 | First repository entry; routes to `AI_READ_FIRST.md`. |
| `AI_READ_FIRST.md` | 0.9.0 | Second-stage local-package and session router from `AGENTS.md` to this manifest. |
| `GeurtsTechniqueManifest.md` | 0.9.0 | Package index and single resolver for selection, versions, applicability, subject ownership, order, and conflicts. |
| `README.md` | 0.9.0 | Repository overview and package changelog. |
| `GeurtsTechniques/GeurtsTechnicalTechnique.md` | 0.8.0 | Normative technical implementation technique and strict-priority owner. |
| `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md` | 0.9.0 | Normative generic AI-assisted automation technique. |
| `GeurtsTechniques/GeurtsFolderStructureTechnique.md` | 0.8.0 | Normative explanatory folder authority. |
| `GeurtsTechniques/GeurtsFolderStructureDefinition.json` | 0.9.0 | Machine-readable folder-creation authority; definition v0.8.0. |
| `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` | 0.9.0 | Normative native-entry and setup technique. |
| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` | 0.8.0 | Normative GDD discovery and maintenance-boundary technique. |
| `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md` | 1.0.0 | Normative Game Forge Intelligence documentation-consumption boundary; compatibility schema 1.0.0. |
| `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` | 1.0.0 | Non-normative compatibility redirect from the released legacy path; never selected as a second authority. |
| `GeurtsTechniques/GeurtsGitIgnoreTechnique.md` | 1.0.0 | Normative approved project-root `.gitignore` payload. |
| `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` | 1.1 | Chat-only response technique; not an implementation standard. |
| `Ideas/GameForgeIntelligenceIdeas.md` | 0.8.0 | Non-normative historical idea register and product-work pointer. |
| `Migrations/v0.9.0.md` | 0.9.0 | Non-normative transition checklist and target-release snapshot. |
| `Migrations/v0.8.0.md` | 0.8.0 | Non-normative historical note for public access and custom `.gitignore` provisioning. |
| `Migrations/v0.7.0.md` | 0.7.0 | Non-normative historical note for v0.4-v0.6 integrations. |
| `Tools/CreateAIAgentInstructionFiles.bat` | 0.9.0 | Compatibility launcher for managed AI setup. |
| `Tools/ManageGeurtsAgentInstructions.ps1` | 0.9.0 | Native-entry migration and GDD scaffolding manager. |
| `Tools/CreateGeurtsFolderStructure.bat` | 0.9.0 | Compatibility launcher for definition-driven folder creation. |
| `Tools/CreateGeurtsFolderStructure.ps1` | 0.9.0 | Definition-driven, create-only folder tool. |
| `Tools/UpdateGameDesignManifest.ps1` | 0.9.0 | Deterministic GDD manifest maintainer. |
| `Tools/NativeEntryMigrationCatalog.json` | 0.9.0 | Native-entry exact-fingerprint migration catalog. |
| `Tools/ValidateGeurtsDocumentation.ps1` | 0.9.0 | Package, path, version, authority, and payload validator. |
| `Tools/AIAgentInstructionTemplates/AGENTS.md` | 0.9.0 | Managed Codex discovery-shim template. |
| `Tools/AIAgentInstructionTemplates/copilot-instructions.md` | 0.9.0 | Managed Copilot discovery-shim template. |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md` | 0.9.0 | Managed scoped Unity discovery-shim template. |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md` | 0.9.0 | Managed scoped game-design discovery-shim template. |
| `Tools/AIAgentInstructionTemplates/GameDesign/README.md` | 0.9.0 | Create-if-missing project GDD routing scaffold. |
| `Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md` | 0.7.0 | Create-if-missing deterministic GDD manifest scaffold. |
| `Tools/Tests/RunAutomationTests.ps1` | 0.9.0 | Temporary-project automation and migration regression suite. |

<!-- GEURTS-PACKAGE-FILES:END -->

## 4. Owner Pointers

- The selected Game Forge Intelligence Technique owns its documentation-consumption and compatibility boundary. The manifest does not restate that lifecycle.
- The selected Folder, AI Agent Setup, GDD, Git Ignore, Technical, and Automation authorities own their respective tool and project-work rules.
