# Geurts AI Agent Setup Technique

**Native AI Instruction Setup - Copilot, Codex, and Future Agents**  
**Version:** 0.5.0  
**Status:** Draft supporting technique  
**Audience:** AI systems and human developers  
**Canonical path:** `Docs/GeurtsAIAgentSetupTechnique.md`  
**Canonical repository:** `Geurtsy/GeurtsGameForge_Documentation`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the canonical repository and path shown above.

---

## Purpose

This document defines how Geurts Game Forge exposes its development rules to Codex, GitHub Copilot, and compatible AI agents.

Native agent files must remain concise. Their job is to route agents into the canonical documentation system, not to duplicate every technique.

---

## Canonical GitHub Source

The authoritative upstream documentation repository is:

`https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`

Canonical branch:

`main`

For TripoCodexUnityPackage use, synchronize the canonical repository before implementation work and direct the agent to the synchronized `AI_READ_FIRST.md`.

A synchronized local copy is a cache of the canonical repository. It must not become a competing source of truth.

---

## AI Documentation Entry Point

All AI agents reaching the canonical documentation repository must begin with:

`AI_READ_FIRST.md`

That file owns the universal reading order, task routing, authority order, and pre-code lock.

---

## Codex

Codex should receive repository-level instructions from:

`AGENTS.md`

For a Unity project using TripoCodexUnityPackage, the generated project-root `AGENTS.md` should:

1. identify the canonical GitHub repository;
2. require the bootstrap/synchronization step before code changes;
3. point Codex to the synchronized `AI_READ_FIRST.md`;
4. prohibit project changes until required documentation has been read;
5. keep implementation standards in the canonical techniques rather than duplicating them locally.

---

## Required Pre-Code Sequence

Before creating, modifying, moving, renaming, or deleting target-project files, AI agents must follow:

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

### SYNC

Synchronize the canonical GitHub documentation when the host package provides a bootstrap mechanism.

If required synchronization fails, do not silently continue under stale instructions. Report the failure. A fallback may be used only when the package policy or user explicitly permits it.

### READ

Read:

1. `AI_READ_FIRST.md`.
2. `GeurtsTechniqueManifest.md`.
3. `Docs/GeurtsAIAgentSetupTechnique.md`.
4. `Docs/GeurtsTechnicalTechnique.md`.
5. `Docs/GeurtsFolderStructureTechnique.md`.
6. Design documentation when `AI_READ_FIRST.md` classifies the task as player-facing.

### INSPECT

Search the target repository for the existing implementation before creating a new system. Avoid duplicate systems and preserve working behaviour unless the task requires changing it.

### PLAN, IMPLEMENT, VALIDATE, REPORT

Choose the smallest maintainable change, implement it, run relevant validation, and report changed files and unresolved issues.

---

## GitHub Copilot

GitHub Copilot may continue to use:

`.github/copilot-instructions.md`

and path-specific files under:

`.github/instructions/*.instructions.md`

Those files should route back to the canonical Geurts documentation and remain concise.

---

## Chat-Only Classification

`GeurtsAIResponseControlTechnique_V1.1.md` controls chat-response behaviour.

It is not a Unity coding, software architecture, engineering, folder, or implementation standard unless a later manifest explicitly reclassifies it.

---

## Strict Priority Standards

The default technical priority order remains:

1. **Extendibility**
2. **Readability**
3. **Efficiency**
4. **Updated**
5. **Documented**

For multiplayer systems, **network efficiency overrides all other priorities**.

---

## Maintenance Rule

When canonical techniques change:

- update `GeurtsTechniqueManifest.md`;
- update `AI_READ_FIRST.md` if reading order or authority changes;
- review native AI instruction templates;
- preserve backward compatibility with package bootstrap consumers when practical;
- explicitly version breaking bootstrap changes.

Do not turn native instruction files into large duplicate manuals unless a specific AI tool requires it.