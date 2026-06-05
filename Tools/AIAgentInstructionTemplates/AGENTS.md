# AGENTS.md

Version: 0.4.0
Project: Geurts Game Forge
Purpose: Repository-level AI agent instructions for Codex and compatible coding agents.

## Primary Rule

Before doing technical work, read and follow the latest valid Geurts technique documents.

Use the highest semantic version if multiple copies exist. Prefer canonical paths when versions tie.

## Technique Sources

- Technical standards: `Docs/GeurtsTechnicalTechnique.md`
- Folder and asset placement: `Docs/GeurtsFolderStructureTechnique.md`
- AI setup rules: `Docs/GeurtsAIAgentSetupTechnique.md`
- Game design discovery: `Docs/GeurtsGameDesignDocumentationTechnique.md`
- Game design index, when present: `Docs/GameDesign/GameDesignManifest.md`

## Strict Technical Priority Order

1. Extendibility
2. Readability
3. Efficiency
4. Updated
5. Documented

For multiplayer systems, network efficiency overrides all other priorities.

## Unity Work Rules

- Treat this as a Unity project unless the repository clearly says otherwise.
- Put first-party Unity content under `Assets/_Project/` according to the folder structure technique.
- Add the required Geurts compliance header to every generated or modified Unity C# script.
- Route runtime debugging and commands through the project-approved console system when relevant.

## Game Design Context

When work changes gameplay, balance, UX, narrative, level flow, enemy behaviour, AI behaviour, progression, or player-facing content, consult `Docs/GameDesign/GameDesignManifest.md` and relevant design docs first.

If needed design docs are missing, state the assumption before implementation.
