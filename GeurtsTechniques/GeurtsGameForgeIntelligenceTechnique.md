# Geurts Game Forge Intelligence Technique

**Version:** 1.0.0
**Compatibility schema:** 1.0.0
**Status:** Draft normative technique
**Primary audience:** Game Forge Intelligence implementers and package maintainers
**Secondary audience:** AI coding agents and human developers
**Required package path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md`

## 1. Scope

This technique defines only the boundary by which Game Forge Intelligence obtains, validates, activates, and reads the Geurts documentation package. `GeurtsTechniqueManifest.md` selects this technique when that integration boundary is involved and remains the sole resolver for file selection, versions, subject ownership, applicability, reading order, and cross-document conflicts.

The Unity plugin implementation, source configuration, candidate transport, compatibility state, audit records, rollback data, UI, feature modes, runtime settings, and product-specific policy are plugin-owned and remain in the separate Game Forge Intelligence repository.

## 2. Source and Complete-Copy Requirement

Before the first download, the plugin must carry its own configured documentation source. For compatibility schema 1.0.0 the required production source is:

```text
Repository: https://github.com/Geurtsy/GeurtsGameForge_Documentation.git
Branch: main
```

The source is public and supports anonymous read-only access. Optional credentials must not be logged or stored in the copied documentation. If an optional authenticated attempt fails, the plugin must attempt a safe anonymous public read. Only an explicit environment policy that forbids anonymous access may stop that attempt; in that case report acquisition failure and retain the last valid compatible copy when one exists. No bundled documentation fallback is approved.

At each selected commit, Game Forge Intelligence must materialize every Git-tracked source path into exactly:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

This is a top-level Unity-project directory alongside `Assets/`, `Packages/`, and `ProjectSettings/`, never under `Assets/`. It is the complete content container for every Git-tracked path in the selected commit. The selected Git tree, not a role table or visible-entry allowlist, defines that set. Current tracked top-level entries are `AGENTS.md`, `AI_READ_FIRST.md`, `GeurtsTechniqueManifest.md`, `GeurtsTechniques/`, `Ideas/`, `Migrations/`, `README.md`, and `Tools/`.

The current source has zero Git-tracked hidden paths and only regular tracked files. Future hidden paths are included naturally when tracked. Preserve exact tracked bytes. Reject and report an unsupported object type or unsafe path instead of omitting, dereferencing, flattening, or replacing it silently. Clone-internal `.git/` metadata and every transport- or integration-owned artifact remain outside the documentation container.

Project-specific GDD content remains separate under `<ProjectRoot>/Docs/GameDesign/`. The documentation package must never contain or replace it.

A recognized prior package version may be migrated only through the plugin-owned transaction defined below. Before replacing an existing documentation container, detect unexpected local drift and unrecognized or user-authored content. Preserve that content exactly, report a conflict, retain the validated candidate and last-valid evidence in plugin-owned state, and do not treat or activate the drifted tree as documentation-source authority until it is safely reconciled or the user explicitly authorizes the required resolution.

## 3. Plugin-Owned Startup and Activation

Game Forge Intelligence performs exactly one routine remote documentation check per Unity project launch or open, including first installation. It must acquire a missing copy or evaluate an available changed commit, then complete compatibility activation before plugin AI use. When the selected commit is unchanged, it still validates the compatible local copy. Ordinary AI-session initialization uses and locally validates that already-local copy and must not make a second routine network check.

An explicit user-requested refresh capability is separate from the launch check. Its UI label is plugin-owned. A refresh must rerun integration reconciliation even when the selected commit is unchanged.

The plugin owns the complete operation:

1. acquire and stage an exact complete-tree candidate outside the live documentation container;
2. validate package integrity and preflight compatibility schema, selected technique path, technique version, and exact technique SHA-256 before promotion;
3. snapshot the previous documentation, managed native and recognized legacy entries, and plugin state;
4. promote the candidate atomically;
5. migrate only exact recognized managed entries, reconcile plugin state, and validate the integrated result;
6. activate prompt/read use and clean up operation artifacts only after every step succeeds; and
7. on failure, restore the previous documentation, native/legacy entries, and plugin state as one combined rollback outcome.

All Game Forge Intelligence technique metadata, fingerprints, audit data, candidate staging, snapshots, rollback data, and integration state belong under the plugin-owned location:

```text
<ProjectRoot>/Library/GameForgeIntelligence/
```

They must not appear inside `GeurtsGameForgeDocumentation/`. The stable serialized tuple `contractPath`, `contractVersion`, and `contractFingerprint` identifies the manifest-selected Game Forge Intelligence Technique path, version, and exact content fingerprint; it is plugin-owned compatibility metadata, not generic documentation configuration. `contractFingerprint` is the lowercase 64-hex SHA-256 of the technique file's exact raw bytes in the active validated commit, with no text, encoding, or newline normalization.

An unsupported requirement produces `category=COMPATIBILITY` with `status/action=PLUGIN_UPDATE_REQUIRED`. A failure after successful compatibility preflight produces `category/status=REINTEGRATION`. In either case, keep or restore the last valid compatible state and do not expose a partial candidate to AI use. If no valid compatible state exists, report documentation unavailable.

## 4. Runtime Read Boundary

Game Forge Intelligence begins internal package reading directly at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/AGENTS.md
```

That file routes to its sibling `AI_READ_FIRST.md`, which routes to `GeurtsTechniqueManifest.md`. Follow the manifest-selected order from there. Every selected package file used by the session must come from the same active validated commit.

Game Forge Intelligence bypasses project-root discovery shims. The separate `<ProjectRoot>/AGENTS.md` remains user-owned except for an explicitly managed concise routing region and is not the plugin startup entry. Preserved legacy or user-authored files must not be loaded as competing Geurts package policy.

The generic documentation manager owns only Geurts-managed entries. Product-owned or unrecognized legacy material is preserved and reported outside that generic workflow. Any plugin-owned legacy-entry migration must be narrowly recognized, preserve surrounding and user-authored content, and must not leave a competing Geurts runtime authority.

## 5. Generic Subject Boundaries

Generic implementation, automation, folders, native AI entries, project GDD, and `.gitignore` behaviour defer unconditionally to the subject owners selected by `GeurtsTechniqueManifest.md`. Game Forge Intelligence must not silently overwrite user-authored project files, native-entry content, or GDD content; invent project design facts; or alter a differing project-root `.gitignore`. The separately authorized GDD maintainer may update only the bounded managed manifest index defined by the Game Design Documentation Technique.

The four supported native entries may be reconciled automatically as part of the plugin-owned transaction only through the exact-fingerprint, preservation, narrow per-file safety-backup, conflict, and opt-out rules in the AI Agent Setup Technique. GDD scaffolding and GDD manifest maintenance remain separate explicit user opt-ins.

## 6. Downstream Game Forge Intelligence Work

The separate Game Forge Intelligence repository must implement this compatibility schema and lifecycle. Required downstream work includes:

- carry the production source URL and branch before first download;
- replace selective or three-entry materialization with exact complete-tree synchronization;
- store plugin compatibility, audit, staging, rollback, and integration state under `<ProjectRoot>/Library/GameForgeIntelligence/`;
- perform one remote check per Unity launch/open and keep ordinary AI-session initialization local-only;
- load copied `AGENTS.md` directly and follow the manifest-controlled chain from one validated commit;
- retain the stable serialized compatibility keys while mapping them to the manifest-selected technique path/version/hash;
- implement the normalized `COMPATIBILITY`/`PLUGIN_UPDATE_REQUIRED` and `REINTEGRATION` outcomes;
- rerun reconciliation after user-requested refresh even when the commit is unchanged;
- update the four generic native entries through the Setup Technique's safe managed-entry workflow; and
- own any narrowly recognized product legacy-entry migration while preserving unknown and user-authored content.

No Unity plugin source is changed by this documentation-package release.

## 7. Conformance

A conforming Game Forge Intelligence integration:

- synchronizes exactly one complete selected Git tree to the required top-level destination;
- keeps `.git/` and every plugin-owned artifact outside that destination;
- preserves exact tracked content and visibly rejects unsupported object types;
- completes compatibility preflight before promotion and combined rollback on later failure;
- never silently replaces unrecognized or user-authored content;
- follows the copied-`AGENTS.md` same-commit entry chain; and
- delegates generic subjects to the manifest-selected owners.
