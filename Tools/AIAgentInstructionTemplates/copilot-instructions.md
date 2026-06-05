# Geurts Game Forge Copilot Instructions

Version: 0.4.0

This repository follows the Geurts Game Forge technique set. Before generating, modifying, reviewing, or moving code, follow the latest valid versions of these files:

- `Docs/GeurtsTechnicalTechnique.md`
- `Docs/GeurtsFolderStructureTechnique.md`
- `Docs/GeurtsAIAgentSetupTechnique.md`
- `Docs/GeurtsGameDesignDocumentationTechnique.md`

Use the highest semantic version if duplicates exist. Prefer canonical paths when versions tie.

Strict technical priority order:

1. Extendibility
2. Readability
3. Efficiency
4. Updated
5. Documented

For multiplayer systems, network efficiency overrides all other priorities.

Unity C# scripts generated or modified by AI must begin with:

```csharp
// IMPORTANT: This script must comply with Docs/GeurtsTechnicalTechnique.md and folder placement rules in Docs/GeurtsFolderStructureTechnique.md.
```

For gameplay, balance, UX, narrative, level, enemy, progression, or player-facing behaviour changes, consult `Docs/GameDesign/GameDesignManifest.md` and relevant docs under `Docs/GameDesign/` when present.

If required context is missing, state the assumption before implementing.
