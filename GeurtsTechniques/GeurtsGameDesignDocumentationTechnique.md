# Geurts Game Design Documentation Technique

**Game Design Documentation Discovery - AI and Human Developer Reference**  
**Version:** 0.5.0  
**Status:** Draft supporting technique  
**Audience:** AI systems and human developers  
**Canonical path:** `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the canonical path shown above.

---

## Purpose

This document defines how AI agents and human developers should find and use project-specific game design documentation when a technical task depends on design intent.

The Technical Technique defines how to build systems. Project-specific game design documentation defines what those systems should feel like, support, or express to the player.

---

## Documentation Boundary

Synchronized Geurts Game Forge techniques belong at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Project-specific game design documentation belongs at:

```text
<ProjectRoot>/Docs/GameDesign/
```

Never use a template or example inside `GeurtsGameForgeDocumentation/` as the target game's design authority.

---

## Canonical Game Design Directory

Use this target-project directory for project-specific game design documentation:

```text
<ProjectRoot>/Docs/GameDesign/
```

Use this manifest as the design index when it exists:

```text
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

---

## When AI Agents Must Consult Game Design Docs

AI agents must check the project-specific game design documentation when a task affects:

- Core mechanics.
- Player abilities.
- Enemy behaviour.
- AI behaviour that affects gameplay feel.
- Combat tuning.
- Progression, economy, rewards, or unlocks.
- Quests, objectives, or narrative content.
- Level design or encounter pacing.
- UI and UX flow.
- Accessibility or player-facing options.
- Player-visible debugging, cheats, or tuning tools.

---

## Recommended Design Document Set

These files are optional starting points. Create only what the project actually needs.

```text
<ProjectRoot>/Docs/GameDesign/
├── GameDesignManifest.md
├── GameDesignOverview.md
├── GameplayPillars.md
├── CoreMechanics.md
├── PlayerAbilities.md
├── EnemyAndAIDesign.md
├── ProgressionAndBalance.md
├── LevelDesign.md
├── UIUXDesign.md
├── NarrativeAndWorld.md
└── AccessibilityDesign.md
```

---

## Manifest Rules

`<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` should list the current project-specific design documents and explain when each one matters.

If multiple design documents conflict, AI agents should prefer:

1. The highest semantic version.
2. The most specific relevant document.
3. The document listed as authoritative in `GameDesignManifest.md`.
4. The newest dated design decision note if versions are unavailable.

If ambiguity remains, the AI agent must state the assumption before implementation.

---

## Relationship to Other Techniques

- `GeurtsTechnicalTechnique.md` defines implementation standards.
- Project-specific game design docs define player-facing intent.
- `GeurtsFolderStructureTechnique.md` defines where files belong.
- `GeurtsAIAgentSetupTechnique.md` defines how agents discover and synchronize the documentation.

Game design documents should not silently override technical safety, performance, or multiplayer network-efficiency requirements. If design intent conflicts with technical standards, the AI agent must state the conflict.
