# Geurts Technique Package Manifest

**Version:** 0.6.0  
**Status:** Draft technique package  
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`  
**Canonical branch:** `main`

## AI Entry Point

AI agents arriving at this repository must begin with:

`AI_READ_FIRST.md`

The root `AGENTS.md` reinforces this requirement for Codex and compatible agents.

For synchronized Unity-project use, the entry point is:

`GeurtsGameForgeDocumentation/AI_READ_FIRST.md`

## Instruction Classification

### Mandatory before implementation

- `AI_READ_FIRST.md`
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md`
- `GeurtsTechniques/GeurtsTechnicalTechnique.md`
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md`

### Conditional when player-facing behaviour is affected

- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`
- `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`
- relevant project-specific game-design documents identified by that manifest

### Chat-only

- `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md`

The chat-response technique is not a Unity coding, architecture, or engineering standard.

## Included Core Files

- `README.md` v0.6.0
- `AI_READ_FIRST.md` v0.6.0
- `AGENTS.md` v0.6.0
- `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` v1.1
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` v0.5.0
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` v0.5.0
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` v0.6.0
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` v0.5.0
- `Tools/CreateGeurtsFolderStructure.bat` v0.4.0
- `Tools/CreateAIAgentInstructionFiles.bat` v0.6.0
- `Tools/BootstrapGeurtsInstructions.ps1` v0.6.0
- `Tools/AIAgentInstructionTemplates/AGENTS.md` v0.6.0

## Version Rule

If multiple copies of the same technique are found, use the highest semantic version. If versions tie, prefer the canonical repository path or canonical package path declared by the technique.

The GitHub repository is the canonical documentation authority. A copy synchronized into `GeurtsGameForgeDocumentation/` is a local read-only cache, not an independent authority.

## Required Agent Sequence

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

Do not modify target-project files before the applicable mandatory documents have been read.

## Unity Integration Contract

A compatible Unity integration package should:

1. Point to `https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`.
2. Synchronize branch `main` before AI implementation work.
3. Store the synchronized documentation at `<ProjectRoot>/GeurtsGameForgeDocumentation/`.
4. Direct the AI agent to `<ProjectRoot>/GeurtsGameForgeDocumentation/AI_READ_FIRST.md`.
5. Validate that `<ProjectRoot>/GeurtsGameForgeDocumentation/GeurtsTechniques/` exists.
6. Fail visibly rather than silently using stale instructions when synchronization is required but unsuccessful.
