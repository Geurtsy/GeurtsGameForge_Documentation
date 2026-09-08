<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts Game Forge Automation Technique

**Version:** 0.9.0
**Status:** Draft normative technique
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers and compatible Unity integrations
**Required package path:** `GeurtsTechniques/GeurtsGameForgeAutomationTechnique.md`

## Purpose

This technique defines concise, reusable operational behaviour for AI-assisted game development. It does not define a document resolver, technical priority system, integration lifecycle, or product feature. `GeurtsTechniqueManifest.md` alone decides when this technique applies, where it is read, and which subject owner resolves a conflict.

<!-- GEURTS-SECTION:BEGIN HUMAN-ONLY -->
### Provenance

Reusable operational guidance was selectively adapted from the supplied Game Forge Intelligence generated-project `AGENTS.md`. The adaptation is governed by the existing Geurts hierarchy and technical priorities. Product-specific policy was deliberately excluded, and the supplied file is not an authority for this package.

<!-- GEURTS-SECTION:END -->

## Active Request

The current explicit user instruction is the active request whether it arrives through an embedded game-development interface or a direct coding-agent prompt. The interface does not change its authority.

Use a host-provided pending automation objective only after the user explicitly asks to start or continue that pending work. A pending artifact does not silently override a newer direct request, the manifest-selected subject owners, project-specific design facts, or safety boundaries.

## Operational Behaviour

- Implement requested project changes when implementation is authorized; answer informational questions without unrelated mutation.
- Inspect the relevant project files and documentation before creating replacements.
- Reuse or extend suitable project systems and established folder conventions when doing so fits the project evidence.
- Work in small, reversible increments and validate after meaningful changes.
- Repair recoverable failures within scope, preserve working systems, and automate routine safe work the available environment can perform.
- Keep the user informed of genuine blockers, consequential decisions, validation results, material limitations, and any action only they can take.

## Approach and Questions

Choose a reasonable implementation by applying project evidence and the manifest-selected Technical Technique. Do not add a separate decision framework or require a multi-option comparison for routine work.

Ask the user only when alternatives materially change gameplay, architecture, scope, safety, cost, or another genuinely consequential outcome, when a manifest-selected subject owner requires an answer, or when new authority is required. Otherwise proceed with reversible routine details that can be inferred safely.

## Unity-Owned Serialization

Prefer validated Unity Editor APIs for scenes, prefabs, assets, serialized references, and other Unity-owned data. Do not directly rewrite Unity YAML when an appropriate Editor API is available. If correct serialization requires unavailable Editor access, report the blocker rather than inventing unsafe file mutations.

This principle does not prescribe a plugin bridge, request schema, UI, runtime, or storage path. Those implementation details remain outside this generic technique.

## Product Boundary

Product-specific modes, services, APIs, credentials, feature policy, runtime settings, user-interface behaviour, and storage formats are not Geurts rules. A compatible product may apply its relevant conditional material only at the manifest-defined position and within that feature's scope.

## Definition of Done

Automation is complete when the active request is resolved within scope, relevant project evidence and manifest-selected authorities were used, safe routine work was completed, consequential uncertainty was surfaced, relevant validation passed, and the result reports the change and a practical verification path.
