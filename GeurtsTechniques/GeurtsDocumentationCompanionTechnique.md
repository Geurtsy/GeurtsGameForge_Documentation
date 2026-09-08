# Geurts Documentation Companion Technique

**Version:** 1.0.1
**Contract schema:** 1.0.0
**Package version:** 0.11.1
**Status:** Draft normative technique
**Primary audience:** Geurts Documentation Companion implementers and package maintainers
**Secondary audience:** AI coding agents and human developers
**Required package path:** `GeurtsTechniques/GeurtsDocumentationCompanionTechnique.md`

## 1. Scope and Ownership

This technique defines the project-facing documentation lifecycle implemented by the Geurts Documentation Companion. `GeurtsTechniqueManifest.md` selects this technique and remains the sole resolver for package-file selection, versions, subject ownership, applicability, reading order, and cross-document conflicts.

The companion is a small, Windows-only, Editor-only Unity package installed into an existing Unity project through Unity Package Manager from its separate `Geurtsy/com.geurts.gameforge.documentation` Git repository. It has no dependency on any other Unity package, including Geurts Game Forge God, Odin Inspector, Quantum Console, or Game Forge Intelligence. Its package repository owns its Unity code, package metadata, Editor UI, and implementation-specific documentation.

`Geurtsy/GeurtsGameForge_Documentation` remains the sole source and authority for generic Geurts Game Forge documentation. This repository owns this technique and the closed machine-readable contract at:

```text
GeurtsTechniques/GeurtsDocumentationCompanionContract.json
```

This repository contains no Documentation Companion plugin code. A Geurts documentation release does not require a companion-package release unless the companion must add support for a changed contract schema.

There is no external installer, Windows bootstrap, batch-driven setup, or separate companion setup action. Installing the Editor package through Unity Package Manager is the only companion installation route defined here.

## 2. Closed Data Contract

`GeurtsDocumentationCompanionContract.json` is the smallest closed data contract for this lifecycle. It names only:

- the official source and exact archive selection;
- the one project-local documentation destination;
- the entries required during basic candidate validation;
- the Update action and confirmation targets; and
- the four exact documentation-template-to-project-target mappings.

It is not a general setup-plan format, script manifest, extensible task engine, or permission catalogue. An implementation must reject an unsupported schema, a missing or unknown field, a duplicate mapping or target, an unsafe validation path, or any source, destination, template, target, action label, or confirmation behavior that differs from the supported schema contract. It must not discover additional work from repository contents.

Because the confirmation occurs before archive acquisition, a schema-1.0.0 companion must carry this exact supported destination, five-target list, and four template-to-target mappings for the dialog and mutation boundary. After confirmation and download, it must parse the archive's contract and require the pre-approved source selection, destination, action, confirmation behavior, target paths and effects, template paths, target paths, and mapping order before the first project mutation. The earlier approval does not authorize a changed or expanded managed target set. `packageVersion` and `validationEntries` follow the forward-compatible rules in the next paragraph rather than being pinned to the initial v0.11.0 values.

`packageVersion` is source-release metadata, not a companion compatibility gate: it must be a valid version and exactly match the package manifest in the same archive, but a later package version alone must not require a companion release while schema 1.0.0 remains supported. `validationEntries` is the archive's closed current completeness list; a schema-1.0.0 consumer may read a later list rather than pinning v0.11.0, but every entry must be unique, safe, readable, and archive-root-relative before mutation. Validation entries grant no project-read or project-write authority. Mapping `template` values are also archive-root-relative; `destination.projectRelativePath`, confirmation `path` values, and mapping `target` values are Unity-project-root-relative. All contract paths use `/` separators and contain no rooted path, empty segment, `.` segment, or `..` segment.

## 3. Project and Source Boundaries

The production source is:

```text
Repository: https://github.com/Geurtsy/GeurtsGameForge_Documentation.git
Branch: main
Selection: archive of the exact resolved main-head commit
```

The managed project-local documentation destination is exactly:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

The companion treats that destination as logically read-only managed content. Logical read-only status is a usage and ownership rule, not permission to set Windows read-only attributes. Users and automated tools should not maintain local changes there. A confirmed Update discards every local addition, deletion, and edit inside the destination without inspecting or preserving drift.

The four managed project AI targets are exactly:

```text
<ProjectRoot>/AGENTS.md
<ProjectRoot>/.github/copilot-instructions.md
<ProjectRoot>/.github/instructions/geurts-unity.instructions.md
<ProjectRoot>/.github/instructions/geurts-game-design.instructions.md
```

Within the companion Update, this technique owns complete replacement of those four files from the exact template mappings in the selected contract. The action does not merge managed regions, preserve content in those files, honor a native-entry opt-out, migrate legacy content, or invoke `ManageGeurtsAgentInstructions.ps1`. If `.github/` or `.github/instructions/` is absent, the companion may create only the missing parent directories required to materialize the listed targets. It must preserve every unlisted file and directory within those parents.

Every other project path is outside the lifecycle. In particular, the companion must not enumerate, inspect, create, validate, hash, modify, or delete anything under:

```text
<ProjectRoot>/Docs/GameDesign/
```

Merely copying the scoped game-design instruction template to its listed target does not authorize access to any path matched by that template.

## 4. Unity-Open Metadata Check

On each normal Unity project launch or open, the companion may perform at most one lightweight metadata-only request for the official repository's current `main` head commit. If it does, it compares that remote commit ID with one persistent companion-owned last-successful-installed commit value for this Unity project, held outside the Unity project filesystem and outside the installed UPM package, for example in host or Editor preference storage. The value must be keyed by a Unity-provided project identity or normalized project-root path derived without reading project content; a value for one project must never suppress availability in another. The companion must not create a project file or project path for this value. The check must not download an archive, inspect the managed documentation copy, inspect any AI target, mutate a managed project target, execute setup work, or synchronize content. A skipped, failed, or unavailable request is non-blocking.

An Update is available when the last-successful-installed commit value is missing or differs from the remote `main` head commit. Matching values mean only that the authoritative source has not advanced since the last fully successful companion Update; they do not validate or certify mutable local files. When the remote commit is unavailable, availability is unknown. The explicit Update action remains available in every state.

Ordinary AI-session initialization performs no additional remote check.

The last-successful-installed value contains only the exact commit ID selected by the most recent Update that completed and verified all five managed targets. It is comparison-only, non-authoritative, and non-blocking. It is not a receipt, package-version record, compatibility state, local-integrity assertion, drift record, backup pointer, rollback marker, recovery metadata, journal, or state-machine gate. Its write is attempted only after full managed-target success and never authorizes, blocks, repairs, or expands project mutation. If persistence fails, the managed-target Update remains successful, the companion reports a comparison-state warning, and a later open may offer the same Update again. An implementation must not claim that mutable local files are certified current merely from this value or from package-version ordering.

## 5. Explicit In-Editor Update

The companion exposes exactly one lifecycle action:

```text
Update Geurts Game Forge Documentation
```

Selecting it immediately shows one confirmation dialog. There is no earlier preview, dry run, check phase, setup screen, or second confirmation. Cancel is the initially focused and default response. Closing or dismissing the dialog, pressing Escape, or otherwise declining must cause no network or filesystem change from the Update action.

The confirmation must identify all five destructive targets and no implied broader scope:

```text
GeurtsGameForgeDocumentation/                                                     entire folder replaced
AGENTS.md                                                                         entire file replaced
.github/copilot-instructions.md                                                   entire file replaced
.github/instructions/geurts-unity.instructions.md                                 entire file replaced
.github/instructions/geurts-game-design.instructions.md                           entire file replaced
```

It must state that every local change in those targets will be overwritten and lost, that there is no backup or rollback, and that `Docs/GameDesign/` and every unlisted project path will not be accessed or changed.

No archive acquisition or project mutation may begin before affirmative confirmation.

## 6. Confirmed Update Sequence

After affirmative confirmation, the companion performs this bounded sequence:

1. Resolve the official repository's current `main` head commit and capture its exact commit ID.
2. Download an archive pinned to that exact commit into a temporary location outside the Unity project.
3. Perform basic pre-mutation validation: confirm the configured official source, the selected exact commit, safe relative archive paths, supported regular-file and directory entries, absence of Git metadata, readability of every contract-listed validation entry, readable entry routing through `AGENTS.md`, `AI_READ_FIRST.md`, and `GeurtsTechniqueManifest.md`, support for contract schema 1.0.0, and equality between the contract and manifest package versions.
4. Delete any existing `<ProjectRoot>/GeurtsGameForgeDocumentation/` and directly materialize the complete validated archive tree at that exact destination. The result contains no `.git` metadata or continuing repository, worktree, branch, remote, or synchronization connection.
5. Directly replace each of the four AI target files with the bytes of its mapped template from the same validated candidate. Create only a missing `.github/` or `.github/instructions/` parent needed for those exact files.
6. Verify that the complete documentation destination and all four mapped target files were written successfully.
7. After every managed-target verification passes, report the content Update as successful and attempt to write the selected exact commit ID as the companion-owned last-successful-installed value. If that comparison-state write fails, report a warning and allow a later open to offer the Update again; do not reclassify, undo, or repair the successful five-target replacement.
8. Remove temporary acquisition content on a best-effort basis. It is never a backup, rollback source, quarantine, journal, recovery state, or prerequisite for a later Update.

Validation must finish before the first destructive project mutation. After mutation begins, any failure or interruption may leave the documentation destination or one or more AI targets missing, incomplete, or from different attempts. The companion reports failure plainly and never reports partial completion as success. The only retry is another user-invoked Update with the same confirmation; there is no automatic repair or recovery flow.

## 7. Forbidden Behavior

The companion must not:

- automatically download, install, replace, repair, or synchronize documentation or AI routes on Unity open;
- scan for or execute `.bat`, `.cmd`, `.ps1`, or any other script from either the documentation package or the Unity project;
- run folder creation, GDD scaffolding, GDD manifest maintenance, `.gitignore` provisioning, native-entry management, migration, or any other setup action;
- inspect or preserve local drift in the documentation destination or four managed AI targets;
- create a preview, dry run, backup, snapshot, rollback, quarantine, journal, recovery gate, last-valid copy, merge, opt-out, or migration path for this Update;
- modify any project file beyond the documentation destination and four mapped AI files; or
- treat a newly discovered repository file, script, manifest entry, or directory as executable work.

The complete documentation tree is copied as inert content. The presence of tools within that tree does not authorize their execution.

## 8. AI Routing Limitation

The four managed AI files route supported tools to `GeurtsGameForgeDocumentation/AGENTS.md`, which continues through `AI_READ_FIRST.md` to the manifest-selected package chain. They do not make every AI product obey the documentation automatically.

Each source template explicitly tells an agent to read that installed entry before planning or modifying any Geurts Game Forge brick code and to treat the installed, manifest-selected documentation as the source of truth for the work. The companion copies that instruction only through the four declared mappings and does not discover or alter any other agent configuration.

An AI tool must support the applicable native instruction file or be explicitly instructed to read and follow `AGENTS.md`. Tools that ignore those instruction surfaces may not discover or follow the Geurts documentation. The companion must present this limitation accurately and must not claim universal AI control or compliance.

## 9. Conformance

A conforming companion:

- is an independent Windows-only, Editor-only UPM package implemented outside this repository, with no dependency on God, Odin Inspector, Quantum Console, Game Forge Intelligence, or any other Unity package;
- performs at most one metadata-only official-`main` check per Unity open and never mutates during that check;
- reports an Update available when its comparison-only last-successful-installed commit value is missing or differs from the remote head, and attempts to write that value only after all five managed targets verify successfully;
- exposes the one exact in-Editor Update action and one cancel-default confirmation listing the documentation folder and four AI files;
- acquires and validates one exact-commit archive only after confirmation;
- directly replaces the complete documentation destination followed by the four exact contract-mapped AI files;
- reports success only when the documentation copy and all four route targets are complete;
- treats the managed documentation copy as logically read-only and discards local edits on confirmed Update;
- never accesses `Docs/GameDesign/`, executes scripts, performs setup, or changes any unlisted project file; and
- explains the native AI routing limitation without promising universal enforcement.
