# Geurts Game Forge Documentation Repository Instructions

This repository is the canonical Geurts Game Forge documentation authority.

Before making changes, read `AI_READ_FIRST.md` and then follow the reading order it defines.

## Mandatory rules

- Treat `GeurtsTechniqueManifest.md` as the version and package index.
- Keep native AI instruction files concise. They should route agents to authoritative documentation instead of duplicating entire techniques.
- Preserve semantic versioning and canonical paths.
- Do not treat `GeurtsAIResponseControlTechnique_V1.1.md` as a coding standard.
- When changing a technique, update the manifest and any affected entry-point references in the same change.
- When changing instructions consumed by TripoCodexUnityPackage, keep the bootstrap contract documented in `AI_READ_FIRST.md` compatible or clearly version the breaking change.

## Workflow

Use: `READ -> INSPECT -> PLAN -> MODIFY -> VALIDATE -> REPORT`.

Prefer the smallest coherent documentation change that keeps all pointers correct.