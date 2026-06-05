# Geurts AI Agent Setup Technique

**Native AI Instruction Setup - Copilot, Codex, and Future Agents**  
**Version:** 0.4.0  
**Status:** Draft supporting technique  
**Audience:** AI systems and human developers  
**Canonical path:** `Docs/GeurtsAIAgentSetupTechnique.md`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the copy in the canonical path shown above.

---

## Purpose

This document defines how Geurts Game Forge exposes its project rules to AI coding agents in the native formats those agents already know how to find.

The native files must stay short. Their job is to point AI agents to the latest Geurts technique documents, not to duplicate every standard.

---

## Native Instruction Files

Create the native instruction files with:

```text
Tools/CreateAIAgentInstructionFiles.bat
```

The script expects to live here:

```text
ProjectRoot/Tools/CreateAIAgentInstructionFiles.bat
```

It creates missing files only and must not overwrite existing project-specific instruction files.

---

## Files Created

```text
ProjectRoot/
├── AGENTS.md
├── .github/
│   ├── copilot-instructions.md
│   └── instructions/
│       ├── geurts-unity.instructions.md
│       └── geurts-game-design.instructions.md
└── Docs/
    └── GameDesign/
        ├── README.md
        └── GameDesignManifest.md
```

---

## GitHub Copilot

GitHub Copilot should receive repository-wide instructions from:

```text
.github/copilot-instructions.md
```

Path-specific Copilot instructions should live in:

```text
.github/instructions/*.instructions.md
```

The Geurts setup uses path-specific files so Unity code and game-design-related work can receive additional context without stuffing every detail into the repository-wide file.

---

## Codex

Codex should receive repository-level instructions from:

```text
AGENTS.md
```

The root `AGENTS.md` must point Codex to the latest Geurts technique documents and the current game design manifest when design context is needed.

---

## Required Agent Behaviour

Before generating, modifying, moving, or organising files, AI agents must:

1. Locate the latest valid Geurts technique documents.
2. Use the highest semantic version if multiple copies exist.
3. Follow `Docs/GeurtsTechnicalTechnique.md` for technical implementation.
4. Follow `Docs/GeurtsFolderStructureTechnique.md` for file and asset placement.
5. Follow `Docs/GeurtsGameDesignDocumentationTechnique.md` when gameplay design context is needed.
6. Consult `Docs/GameDesign/GameDesignManifest.md` when it exists and the task depends on design intent.
7. State assumptions before acting if needed context is missing.

---

## Strict Priority Standards

The default technical priority order is:

1. **Extendibility**
2. **Readability**
3. **Efficiency**
4. **Updated**
5. **Documented**

For multiplayer systems, **network efficiency overrides all other priorities**.

---

## Maintenance Rule

When the Geurts technique documents change, review the native AI instruction files. They should remain concise pointers to the technique set.

Do not turn native instruction files into large duplicate manuals unless a specific AI tool requires it.
