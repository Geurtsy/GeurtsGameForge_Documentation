# Geurts Technique Package Manifest

**Version:** 0.5.0  
**Status:** Draft technique package  
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`  
**Canonical branch:** `main`

## AI Entry Point

AI agents arriving at this repository must begin with:

`AI_READ_FIRST.md`

The root `AGENTS.md` reinforces this requirement for Codex and compatible agents.

## Instruction Classification

### Mandatory before implementation

- `AI_READ_FIRST.md`
- `Docs/GeurtsAIAgentSetupTechnique.md`
- `Docs/GeurtsTechnicalTechnique.md`
- `Docs/GeurtsFolderStructureTechnique.md`

### Conditional when player-facing behaviour is affected

- `Docs/GeurtsGameDesignDocumentationTechnique.md`
- `Docs/GameDesign/GameDesignManifest.md`
- relevant game-design documents identified by that manifest

### Chat-only

- `GeurtsAIResponseControlTechnique_V1.1.md`

The chat-response technique is not a Unity coding, architecture, or engineering standard.

## Included Core Files

- `README.md` v0.5.0
- `AI_READ_FIRST.md` v0.5.0
- `AGENTS.md` v0.5.0
- `GeurtsAIResponseControlTechnique_V1.1.md` v1.1
- `Docs/GeurtsTechnicalTechnique.md` v0.4.0
- `Docs/GeurtsFolderStructureTechnique.md` v0.4.0
- `Docs/GeurtsAIAgentSetupTechnique.md` v0.5.0
- `Docs/GeurtsGameDesignDocumentationTechnique.md` v0.4.0
- `Tools/CreateGeurtsFolderStructure.bat` v0.4.0
- `Tools/CreateAIAgentInstructionFiles.bat` v0.4.0
- `Tools/AIAgentInstructionTemplates/AGENTS.md` v0.5.0

## Version Rule

If multiple copies of the same technique are found, use the highest semantic version. If versions tie, prefer the canonical repository path or canonical package path declared by the technique.

The GitHub repository is the canonical upstream authority for TripoCodexUnityPackage bootstrap use. Local synchronized copies are caches, not independent authorities.

## Required Agent Sequence

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

Do not modify target-project files before the applicable mandatory documents have been read.

## TripoCodexUnityPackage Contract

The package should:

1. Point to `https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`.
2. Synchronize branch `main` before Codex implementation work.
3. Store the synchronized documentation outside normal first-party Unity content.
4. Direct Codex to the synchronized `AI_READ_FIRST.md`.
5. Fail visibly rather than silently using stale instructions when synchronization is required but unsuccessful.