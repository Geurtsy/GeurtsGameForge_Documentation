# Geurts Game Forge Documentation Repository Instructions

**Version:** 0.7.0

This repository is the canonical Geurts Game Forge documentation authority.

Before making changes, read `AI_READ_FIRST.md` and then follow the reading order it defines.

## Mandatory rules

- Treat `GeurtsTechniqueManifest.md` as the version and package index.
- Treat `GeurtsTechniques/` as the canonical directory for Geurts implementation techniques.
- Treat `AI_READ_FIRST.md` as the authority for AI-first interpretation, session initialization, task routing, and the pre-code lock.
- Treat `GeurtsTechniques/GeurtsFolderStructureTechnique.md` as the explanatory folder authority and `GeurtsTechniques/GeurtsFolderStructureDefinition.json` as the folder-creation automation authority.
- Keep native AI instruction files concise. They should route agents to authoritative documentation instead of duplicating entire techniques.
- Preserve semantic versioning and canonical paths.
- Do not treat `GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` as a coding standard.
- When changing a technique, update the manifest and any affected entry-point references in the same change.
- When changing Game Forge Intelligence or instructions consumed by another Geurts-compatible Unity AI integration package, follow `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` and clearly version breaking changes.
- Preserve the boundary between synchronized documentation under `GeurtsGameForgeDocumentation/` and project-specific design documents under `Docs/GameDesign/`.

## Workflow

Use: `READ -> INSPECT -> PLAN -> MODIFY -> VALIDATE -> REPORT`.

Prefer the smallest coherent documentation change that keeps all pointers correct.
