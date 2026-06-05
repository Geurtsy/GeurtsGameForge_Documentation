# Geurts Technique Package Manifest

**Version:** 0.4.0  
**Status:** Draft technique package

## Included Files

- `README.md` v0.4.0
- `GeurtsAIResponseControlTechnique_V1.1.md` v1.1
- `Docs/GeurtsTechnicalTechnique.md` v0.4.0
- `Docs/GeurtsFolderStructureTechnique.md` v0.4.0
- `Docs/GeurtsAIAgentSetupTechnique.md` v0.4.0
- `Docs/GeurtsGameDesignDocumentationTechnique.md` v0.4.0
- `Tools/CreateGeurtsFolderStructure.bat` v0.4.0
- `Tools/CreateAIAgentInstructionFiles.bat` v0.4.0
- `Tools/AIAgentInstructionTemplates/AGENTS.md` v0.4.0
- `Tools/AIAgentInstructionTemplates/copilot-instructions.md` v0.4.0
- `Tools/AIAgentInstructionTemplates/instructions/geurts-unity.instructions.md` v0.4.0
- `Tools/AIAgentInstructionTemplates/instructions/geurts-game-design.instructions.md` v0.4.0
- `Tools/AIAgentInstructionTemplates/GameDesign/README.md` v0.4.0
- `Tools/AIAgentInstructionTemplates/GameDesign/GameDesignManifest.md` v0.4.0

## Version Rule

If multiple copies are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version, prefer the copy in the canonical package path.

## Setup Rule

Run these from `ProjectRoot/Tools/`:

1. `CreateGeurtsFolderStructure.bat`
2. `CreateAIAgentInstructionFiles.bat`
