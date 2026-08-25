# TripoCodexUnityPackage - Codex Bootstrap

**Version:** 0.5.0  
**Canonical documentation repository:** `https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`  
**Canonical branch:** `main`

## Pre-Code Lock

Before creating, modifying, moving, renaming, or deleting project files:

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File Tools/BootstrapGeurtsInstructions.ps1`.
2. Confirm the script reports `SYNC OK`.
3. Read `.geurts/upstream/AI_READ_FIRST.md`.
4. Follow the reading order and task routing defined there.
5. Inspect the existing project implementation before creating replacements.
6. Only then plan and implement the requested change.

If synchronization fails, do not silently continue with stale instructions. Report the failure unless the user or package policy explicitly permits fallback use.

## Canonical Configuration

Repository settings are stored in:

`Tools/GeurtsRepository.json`

Do not hard-code a second canonical repository URL elsewhere in the Unity project.

## Synced Documentation

The bootstrap stores the upstream documentation at:

`.geurts/upstream/`

Treat this as read-only reference material. Do not modify synchronized documentation as part of normal Unity implementation work.

## Required Sequence

`SYNC -> READ -> INSPECT -> PLAN -> IMPLEMENT -> VALIDATE -> REPORT`

## Important Classification

`GeurtsAIResponseControlTechnique_V1.1.md` is a chat-response technique, not a Unity coding standard, unless the current upstream manifest explicitly reclassifies it.

## Validation

After implementation, perform relevant compilation/tests/checks, verify folder placement, review against the current Geurts Definition of Done, and report changed files plus unresolved issues.