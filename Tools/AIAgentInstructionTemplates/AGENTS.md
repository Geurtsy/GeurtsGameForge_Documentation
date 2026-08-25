# Geurts Game Forge - Codex Bootstrap

**Version:** 0.6.0  
**Canonical documentation repository:** `https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`  
**Canonical branch:** `main`

## Pre-Code Lock

Before creating, modifying, moving, renaming, or deleting project files:

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/BootstrapGeurtsInstructions.ps1`.
2. Confirm the script reports `SYNC OK`.
3. Read `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`.
4. Follow the reading order and task routing defined there.
5. Inspect the existing project implementation before creating replacements.
6. Only then plan and implement the requested change.

If synchronization fails, do not silently continue with stale instructions. Report the failure unless the user or package policy explicitly permits fallback use.

## Canonical Configuration

Repository settings are stored in:

`Tools/GeurtsRepository.json`

Do not hard-code a second canonical repository URL or project-local documentation path elsewhere in the Unity project.

## Synchronized Documentation

The bootstrap stores the canonical documentation at:

`GeurtsGameForgeDocumentation/`

The required visible layout is:

```text
GeurtsGameForgeDocumentation/
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
└── GeurtsTechniques/
```

Treat this directory as read-only reference material. Do not modify synchronized documentation as part of normal Unity implementation work.

Project-specific game design documents remain under:

`Docs/GameDesign/`

## Required Sequence

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

## Important Classification

`GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` is a chat-response technique, not a Unity coding standard, unless the current manifest explicitly reclassifies it.

## Validation

After implementation, perform relevant compilation/tests/checks, verify folder placement, review against the current Geurts Definition of Done, and report changed files plus unresolved issues.
