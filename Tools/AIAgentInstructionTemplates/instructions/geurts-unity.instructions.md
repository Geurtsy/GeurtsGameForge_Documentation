---
applyTo: "Assets/**/*.cs,Assets/**/*.asmdef,Assets/**/*.shader,Assets/**/*.shadergraph,Assets/**/*.uxml,Assets/**/*.uss,Packages/**/*.json,ProjectSettings/**/*"
---

# Geurts Unity Implementation Instructions

Version: 0.4.0

Follow the latest Geurts Technical Technique and Folder Structure Technique documents before editing Unity project files.

- Technical authority: `Docs/GeurtsTechnicalTechnique.md`
- Folder authority: `Docs/GeurtsFolderStructureTechnique.md`
- AI setup authority: `Docs/GeurtsAIAgentSetupTechnique.md`

Use this strict priority order for technical trade-offs:

1. Extendibility
2. Readability
3. Efficiency
4. Updated
5. Documented

For multiplayer code, network efficiency overrides all other priorities.

Every generated or modified Unity C# script must include the required Geurts compliance header from the technical technique document.
