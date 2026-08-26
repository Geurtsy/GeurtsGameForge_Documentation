# Geurts Technique Package Manifest

**Version:** 0.7.0
**Status:** Draft technique package  
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`  
**Canonical branch:** `main`
**Canonical path:** `GeurtsTechniqueManifest.md`

## AI Entry Point

AI agents arriving at this repository must begin with:

`AI_READ_FIRST.md`

The root `AGENTS.md` reinforces this requirement for Codex and compatible agents.

For synchronized Unity-project use, the only canonical native-entry route is:

`GeurtsGameForgeDocumentation/AI_READ_FIRST.md`

Documentation is AI-first: deterministic interpretation, stable terminology, literal paths, explicit conditions, machine-readable sections, and reliable validation take precedence when they conflict with elegant but ambiguous prose.

## Instruction Classification

### Mandatory before implementation

- `AI_READ_FIRST.md`
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`
- `GeurtsTechniques/GeurtsTechnicalTechnique.md`
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md`
- `GeurtsTechniques/GeurtsFolderStructureDefinition.json` when folders are created or validated

### Conditional when player-facing behaviour is affected

- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`
- `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`
- every relevant project-specific game-design document identified by that manifest

### Integration contract

- `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`

This contract governs Game Forge Intelligence and defines the reusable boundary for Geurts-compatible Unity AI integration packages.

### Chat-only

- `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md`

The response-control technique remains independently versioned at v1.1. It is chat-only and is not a Unity coding, architecture, engineering, folder, automation, or implementation standard.

### Non-normative

- `Ideas/GameForgeIntelligenceIdeas.md`

Ideas do not become mandatory merely because they are indexed by this manifest.

## Package File Registry

Every path between the markers is part of the v0.7.0 repository package and must exist. The Scope column determines whether a file is synchronized into Unity projects, used only in this canonical repository, used as a source template/tool, or used for validation.

<!-- GEURTS-PACKAGE-FILES:BEGIN -->

| Path | Version | Scope |
|---|---:|---|
| `README.md` | 0.7.0 | Repository overview and package changelog; repository-only. |
| `AI_READ_FIRST.md` | 0.7.0 | Canonical AI entry point; synchronized. |
| `AGENTS.md` | 0.7.0 | Canonical-repository Codex entry; repository-only. |
| `GeurtsTechniqueManifest.md` | 0.7.0 | Package/version index; synchronized. |
| `GeurtsTechniques/GeurtsTechnicalTechnique.md` | 0.7.0 | Normative technical implementation technique; synchronized. |
| `GeurtsTechniques/GeurtsFolderStructureTechnique.md` | 0.7.0 | Normative explanatory folder authority; synchronized. |
| `GeurtsTechniques/GeurtsFolderStructureDefinition.json` | 0.7.0 | Machine-readable folder-creation automation authority; synchronized. |
| `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` | 0.7.0 | Normative AI setup and managed-entry technique; synchronized. |
| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` | 0.7.0 | Normative GDD discovery and maintenance technique; synchronized. |
| `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` | 0.7.0 | Normative Game Forge Intelligence integration contract; synchronized. |
| `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` | 1.1 | Chat-only response technique; synchronized but not an implementation standard. |
| `Ideas/GameForgeIntelligenceIdeas.md` | 0.7.0 | Non-normative idea and open-decision register; repository-only. |
| `Migrations/v0.7.0.md` | 0.7.0 | Migration guide for v0.4-v0.6 integrations; repository-only. |
| `Tools/GeurtsRepository.json` | 0.7.0 | Repository, access, sparse-layout, and package configuration; tool source. |
| `Tools/BootstrapGeurtsInstructions.ps1` | 0.7.0 | Check/update/validate and atomic synchronization tool; tool source. |
| `Tools/CreateAIAgentInstructionFiles.bat` | 0.7.0 | Compatibility launcher for managed AI setup; tool source. |
| `Tools/ManageGeurtsAgentInstructions.ps1` | 0.7.0 | Native-entry migration and GDD scaffolding manager; tool source. |
| `Tools/CreateGeurtsFolderStructure.bat` | 0.7.0 | Compatibility launcher for definition-driven folder creation; tool source. |
| `Tools/CreateGeurtsFolderStructure.ps1` | 0.7.0 | Definition-driven, create-only folder tool; tool source. |
| `Tools/UpdateGameDesignManifest.ps1` | 0.7.0 | Deterministic GDD manifest maintainer; tool source. |
| `Tools/NativeEntryMigrationCatalog.json` | 0.7.0 | Historical v0.4-v0.6 native-entry fingerprint catalog; tool data. |
| `Tools/ValidateGeurtsDocumentation.ps1` | 0.7.0 | Package, path, version, and authority validator; validation tool. |
| `Tools/AIAgentInstructionTemplates/AGENTS.md` | 0.7.0 | Managed Codex bootstrap template; template source. |
| `Tools/AIAgentInstructionTemplates/copilot-instructions.md` | 0.7.0 | Managed Copilot bootstrap template; template source. |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md` | 0.7.0 | Managed scoped Unity template; template source. |
| `Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md` | 0.7.0 | Managed scoped game-design template; template source. |
| `Tools/AIAgentInstructionTemplates/GameDesign/README.md` | 0.7.0 | Create-if-missing project GDD scaffold; template source. |
| `Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md` | 0.7.0 | Create-if-missing deterministic GDD manifest scaffold; template source. |
| `Tools/Tests/RunAutomationTests.ps1` | 0.7.0 | Temporary-project automation and migration regression suite; validation test. |

<!-- GEURTS-PACKAGE-FILES:END -->

## Synchronized Unity-Project Package

The synchronization configuration materializes exactly these three visible entries:

```text
GeurtsGameForgeDocumentation/
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
└── GeurtsTechniques/
```

Files marked repository-only, tool source, tool data, template source, or validation test remain in the canonical repository/package distribution and are not part of the synchronized sparse documentation copy.

## Version Rule

If multiple copies of the same technique are found, use the highest semantic version. If versions tie, prefer the canonical repository path or synchronized canonical package path declared by the technique.

The authenticated private GitHub repository is the canonical documentation authority. A validated copy synchronized into `GeurtsGameForgeDocumentation/` is the normal local read-only source for AI prompts, not an independent authority.

No bundled fallback snapshot is approved for v0.7.0. A future fallback must be explicitly authorized, versioned by package and commit, visibly identified as potentially stale, and subordinate to a newer successfully synchronized canonical copy.

## Strict Technical Priority

Apply this order when technical principles genuinely conflict:

1. **Extendibility**
2. **Efficiency**
3. **Readability**
4. **Updated**
5. **Documented**

Higher-numbered principles must not silently override lower-numbered principles.

For multiplayer systems, **network efficiency overrides every other priority**.

## Required Agent Sequence

`CHECK LOCAL DOCS -> UPDATE WHEN REQUIRED -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

Do not modify target-project files before the applicable mandatory documents have been read. Session initialization reads `Docs/GameDesign/GameDesignManifest.md` once when present; full project-specific GDD documents are loaded only when relevant, and every relevant document is mandatory before player-facing implementation.

## Game Forge Intelligence Contract Summary

Game Forge Intelligence must:

1. Use authenticated access to the private canonical repository and branch `main`.
2. Use the validated local synchronized copy during normal prompts.
3. Support `Check`, `Update`, and `Validate` operations plus the manual action `Update Geurts Game Forge Documentation`.
4. Stage and validate candidate documentation before atomically replacing the previous valid copy.
5. Report exact commits and distinct categorized failures without exposing credentials.
6. Consume the folder JSON for creation, respect profile ownership, and never automatically delete managed folders.
7. Create only missing GDD scaffolding and maintain the GDD manifest deterministically.
8. Safely classify and migrate native AI entries while preserving user-authored content.
9. Keep synchronized documentation and project-specific GDD authority domains separate.
10. Record the exact documentation commit used by each AI session.

Unity-specific implementation belongs in the Game Forge Intelligence repository. Platform-neutral documentation, schemas, templates, scripts, catalog data, and tests belong here.
