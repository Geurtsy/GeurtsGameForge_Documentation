# Geurts Game Forge Intelligence Technique

**Version:** 2.0.0
**Compatibility schema:** 2.0.0
**Status:** Draft normative technique
**Primary audience:** Game Forge Intelligence implementers and package maintainers
**Secondary audience:** AI coding agents and human developers
**Required package path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceTechnique.md`

## 1. Scope and Ownership

This technique defines only how Game Forge Intelligence fetches, replaces, and reads the Geurts documentation in a Unity project. `GeurtsTechniqueManifest.md` selects this technique when that integration boundary is involved and remains the sole resolver for package-file selection, versions, subject ownership, applicability, reading order, and cross-document conflicts.

`Geurtsy/GeurtsGameForge_Documentation` is the sole primary source and authority for all Geurts Game Forge documentation, including every generic and reusable technique. It alone sources, versions, and publishes that documentation. A Geurts documentation update is released from this repository and must not require a `com.gameforge.intelligence` Unity-package release.

The boundaries are distinct:

| Boundary | Owner and meaning |
|---|---|
| Authoritative source | This repository and its `main` branch own all Geurts Game Forge documentation. |
| Project-local fetched copy | `<ProjectRoot>/GeurtsGameForgeDocumentation/` is one detached, writable content snapshot fetched from this repository. It is not another source repository or authority. |
| Integration behaviour | The Game Forge Intelligence plugin owns its one notification-only startup metadata check, explicit Update action, acquisition implementation, warning UI, and use of the project-local fetched copy. |
| Plugin documentation | `<PluginPackageRoot>/Documentation~/` inside `com.gameforge.intelligence` may contain only plugin-specific operation, implementation, and maintenance documentation. It may reference this repository but must not embed, duplicate, redefine, or become authority for Geurts documentation or techniques. |
| Project-authored design | `<ProjectRoot>/Docs/GameDesign/` belongs to the Unity project and is never part of the fetched documentation copy or its Update lifecycle. |

The plugin package must not ship a bundled or fallback copy of Geurts documentation anywhere inside `com.gameforge.intelligence`, including `<PluginPackageRoot>/Documentation~/`. Plugin-specific documentation must link or route to the authoritative source or the fetched project-local copy instead of reproducing Geurts technique content.

## 2. Authoritative Source and Complete Snapshot

For compatibility schema 2.0.0, the production source is:

```text
Repository: https://github.com/Geurtsy/GeurtsGameForge_Documentation.git
Branch: main
```

When the user confirms an Update, Game Forge Intelligence resolves the current head of `main`, captures that authoritative selected commit ID, and obtains its complete Git-tracked source tree. The selected Git tree, rather than a visible-entry allowlist, defines the content set. The plugin materializes every supported tracked file and directory into exactly:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

This destination is a top-level Unity-project directory alongside `Assets/`, `Packages/`, and `ProjectSettings/`. It is the only project path this documentation Update may delete or replace.

The materialized directory is a detached, writable content snapshot:

- it contains no `.git` directory or file and no other Git metadata;
- it has no repository, worktree, branch, remote, or continuing connection to the acquisition source;
- acquisition-preserved read-only file or directory attributes must be cleared so the local content is writable; and
- users may edit the local copy, while accepting that the next confirmed Update unconditionally discards every local change inside it.

Preserve the tracked file bytes from the selected source tree. Reject unsafe paths, unsupported tracked object types, or an invalid package before deleting the existing project-local copy. Acquisition metadata and temporary extraction content remain outside the destination.

Project-authored game-design content remains under `<ProjectRoot>/Docs/GameDesign/`. Every file and byte there, and every other project file outside `<ProjectRoot>/GeurtsGameForgeDocumentation/`, must remain untouched by this Update.

## 3. Startup Metadata Check and Missing-Copy Behaviour

There is one live project-local Geurts documentation copy. On each normal Unity project launch or open, Game Forge Intelligence performs exactly one lightweight remote metadata check against the official repository's `main` branch. The check obtains the authoritative current `main` head commit ID and, when the same bounded lookup can provide it, the valid available package version.

Update availability is determined only by commit identity. When the exact destination directory exists, a current installed receipt contains a valid authoritative selected commit ID, and the remote `main` head commit ID differs, notify the user that an Update is available. When those commit IDs are identical, do not report an Update. Package-version ordering or inequality is display-only and must not determine availability. This rule remains deterministic if `main` is rewritten or its package version is unchanged.

The notification check must not download documentation, install or synchronize files, inspect or hash the project-local copy, mutate any project path, recover content, or run reintegration. A failed or unavailable metadata request is non-blocking and leaves the local copy usable. Ordinary AI/session initialization uses the existing local copy and performs no additional remote documentation check.

The current installed receipt belongs to the plugin outside `<ProjectRoot>/GeurtsGameForgeDocumentation/`. Every successful Update receipt records the authoritative selected commit ID and also records the authoritative package version when the selected package exposes a valid version. The commit ID is the comparison baseline; the package version is display metadata. This receipt is not a Git connection, repository, worktree, remote, local-drift ledger, backup, recovery gate, or documentation authority. It must never block local documentation use or an explicit Update.

When the remote head commit ID is unavailable, the exact destination is absent, or there is no current receipt with a valid installed commit ID, the startup comparison result is unknown: do not claim that an Update is available or that the installed copy is current by inspecting local files or comparing package versions. The explicit Update action remains available. A retained older receipt is historical only and must not supply the installed label or comparison baseline. The installed-version label still follows the exact destination and package-version rules below.

Local edits inside the detached writable copy do not affect update availability. The plugin must not inspect them or compare them with either remote content or the current installed receipt.

### 3.1 Geurts Documentation UI version labels

The Game Forge Intelligence Geurts Documentation UI must display these separately labelled values:

```text
Installed Geurts Documentation: <version | Not installed | Unknown>
GameForgeIntelligence Plugin: <version | Unknown>
```

`Installed Geurts Documentation` comes only from the valid package-version field in the current installed receipt recorded outside the fetched copy after complete Update success. Never derive, refresh, or override that displayed version by reading, parsing, or hashing mutable project-local documentation files. A local edit therefore does not change the installed-version label.

Use these documentation states:

- `Not installed` whenever the exact project-local destination is known to be missing, regardless of any receipt or retained history. The UI may check only whether that exact directory exists to classify this state; it must not inspect its contents as part of version or update-availability detection.
- `Unknown` when the directory exists but there is no current installed receipt, its package-version field is absent or invalid, or the new copy was not completed successfully.
- the recorded package version when the directory exists and the current installed receipt contains both a valid authoritative selected commit ID and a valid authoritative package version.

A separately retained historical receipt must never drive the installed label or availability comparison after the current receipt is invalidated.

`GameForgeIntelligence Plugin` comes only from the canonical installed Unity package metadata for `com.gameforge.intelligence`. Show `Unknown` if that canonical plugin version is unavailable or invalid. Do not derive the plugin version from plugin documentation, Geurts files, integration state, or duplicated configuration.

When commit-ID inequality detects an available documentation Update and the bounded authoritative lookup provides a valid package version, the notification must also show:

```text
Available Geurts Documentation: <version>
```

If the remote head commit differs but its package version is unavailable or invalid, show `Available Geurts Documentation: Update available (version unknown)` rather than substituting another version. The available package version is display-only and never changes the commit-identity result.

The Geurts package version, Game Forge Intelligence Technique version, compatibility schema version, and GameForgeIntelligence plugin version are distinct values. Never display one as another. If technique or schema versions appear in diagnostics, label them separately as `Integration Technique` and `Compatibility Schema`; they do not replace either primary UI version label.

If the project-local copy is missing, Game Forge Intelligence reports the documentation as unavailable. It must not install, reconstruct, recover, or fetch it automatically. The user restores or obtains it only by explicitly invoking the Update action described below.

The notification may offer the Update action, but it never invokes that action or begins acquisition automatically.

## 4. Explicit Manual Update

Game Forge Intelligence exposes exactly one documentation lifecycle action labelled:

```text
Update Geurts Game Forge Documentation
```

Selecting the action must first show a destructive confirmation whose safe default is Cancel. The warning must clearly communicate all of the following before any acquisition or project mutation begins:

```text
The project-local Geurts Game Forge documentation will be deleted and replaced
with the current complete documentation from the official repository's main branch.

Every local edit anywhere inside GeurtsGameForgeDocumentation will be overwritten and lost.
Project-authored Docs/GameDesign content and every other project file will remain untouched.

This update has no rollback. If it fails or is interrupted after replacement begins,
GeurtsGameForgeDocumentation may be missing or incomplete.
```

Cancel must be the initially focused and default response. Dismissing the warning, pressing Escape, closing the window, or otherwise declining confirmation makes no filesystem or network change.

After affirmative confirmation, the plugin performs this simple operation:

1. Download or otherwise acquire the current complete Git-tracked tree from the official repository's `main` branch into an ephemeral location outside the live destination.
2. Perform proportionate validation before deletion, including source identity, safe relative paths, supported object types, the package entry chain, manifest readability, and compatibility schema support.
3. Immediately before the first destructive mutation of the live destination, invalidate or clear the current installed receipt. A separately retained historical receipt is diagnostic history only and must never drive the installed label or availability comparison after this point.
4. Delete the existing `<ProjectRoot>/GeurtsGameForgeDocumentation/` directory if it exists.
5. Materialize the validated complete tree at that same path as a detached writable snapshot, with no Git metadata or acquisition-preserved read-only attributes.
6. Verify that the complete copy succeeded. Only then write a new current installed receipt containing the authoritative selected commit ID plus the authoritative package version when valid, and report success only after that receipt is written.
7. Attempt to remove ephemeral acquisition residue on a best-effort basis.

Failure before receipt invalidation leaves the existing live copy and its current receipt unchanged. Failure or interruption after receipt invalidation must leave the current receipt absent or invalid: if the exact destination directory is absent, the UI shows `Not installed`; if any directory exists there but the new copy did not complete successfully, the UI shows `Unknown`. Do not restore or reuse a historical receipt to label either result. The user may explicitly run Update again; these display rules are not recovery state and never gate that action.

Cleanup failure or leftover ephemeral residue must never block a later `Update Geurts Game Forge Documentation` action. The ephemeral acquisition location is not an activation snapshot, backup, last-valid copy, recovery source, durable journal, or gate.

The Update is intentionally destructive inside the project-local fetched copy. It does not inspect, preserve, merge, back up, reconcile, or request an override for local drift there. Confirmation authorizes replacement of that directory only.

## 5. Discarded Lifecycle Machinery

Game Forge Intelligence must not create or require an automatic documentation downloader or installer, a startup check that downloads or inspects local documentation, an activation transaction, activation snapshot, rollback system, durable recovery journal, recovery gate, cleanup quarantine, reset-recovery flow, last-valid-copy mechanism, local-drift preservation or override flow, reintegration state machine, backup/recovery state that blocks an update, or plugin-managed legacy installer migration for this documentation lifecycle.

Do not recreate any of those mechanisms under different terminology. The one notification-only remote metadata check, current installed receipt, ephemeral download and extraction after confirmation, and proportionate pre-delete validation do not grant authority for a Git connection, local-file inspection, durable transaction, or recovery state. Receipt invalidation merely prevents stale installed-state reporting after destructive mutation; it is not a recovery journal or gate.

Legacy recovery evidence already present under `<ProjectRoot>/Library/GameForgeIntelligence/` is outside compatibility schema 2.0.0. Normal use and Update must not consult it, depend on it, or allow it to block documentation use or replacement. The Update leaves that legacy evidence untouched; any future cleanup requires a separate explicit operation and authority.

## 6. Runtime Read Boundary

Game Forge Intelligence begins internal package reading directly at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/AGENTS.md
```

That file routes to its sibling `AI_READ_FIRST.md`, which routes to `GeurtsTechniqueManifest.md`. Follow the manifest-selected order from there. Every selected file used by a session comes from the same project-local snapshot.

Game Forge Intelligence bypasses project-root discovery shims. The separate `<ProjectRoot>/AGENTS.md` remains user-owned except for an explicitly managed concise routing region and is not the plugin startup entry.

## 7. Generic Subject Boundaries

Generic implementation, automation, folders, native AI entries, project GDD, and `.gitignore` behaviour defer unconditionally to the subject owners selected by `GeurtsTechniqueManifest.md`.

The documentation Update changes only `<ProjectRoot>/GeurtsGameForgeDocumentation/`. It must not invoke native-entry setup, GDD scaffolding, GDD manifest maintenance, folder creation, or `.gitignore` provisioning. Those are independent operations with their own authorization and preservation rules.

In particular, generic tools and Game Forge Intelligence must not invent project-specific GDD facts, overwrite project-authored GDD, silently overwrite user-authored native entries, or alter a differing project-root `.gitignore`. The separately authorized GDD maintainer may update only the bounded managed manifest index defined by the Game Design Documentation Technique.

## 8. Downstream Game Forge Intelligence Work

The separate Game Forge Intelligence repository implements this contract. It must:

- perform exactly one lightweight notification-only remote metadata check per launch/open, with no local-file inspection or lifecycle action, and determine availability only by remote-head commit inequality;
- keep the current installed receipt outside the fetched copy, always record the successful selected commit ID plus a valid package version when available, and keep the receipt non-authoritative, non-blocking, and unrelated to local edits;
- invalidate the current receipt immediately before destructive live mutation, never let historical receipts drive installed state, and write a replacement receipt only after complete success;
- remove automatic documentation download, synchronization, and missing-copy installation;
- expose the one exact Update action and cancel-default warning;
- fetch this external repository's current `main` tree rather than embedding Geurts documentation in the Unity package;
- replace only the project-local fetched copy after confirmation;
- materialize a detached writable snapshot without `.git`, remote/worktree connection, or read-only acquisition attributes;
- remove documentation-specific snapshot, rollback, journal, quarantine, reset, last-valid, drift-override, reintegration, and legacy-installer flows;
- leave legacy Library recovery evidence untouched and non-blocking;
- keep `Documentation~` limited to plugin-specific documentation that references rather than duplicates generic Geurts material; and
- preserve every project path outside `GeurtsGameForgeDocumentation`, especially `Docs/GameDesign`.

No Unity plugin source is changed by this documentation-repository release. Once the plugin implements compatibility schema 2.0.0, later generic Geurts documentation releases and updates remain independently versioned and do not require a plugin release.

## 9. Conformance

A conforming integration:

- recognizes this repository as the sole Geurts documentation source and authority;
- keeps plugin-only documentation separate and non-duplicative;
- performs one notification-only remote metadata check during launch/open, determines availability only by installed-versus-remote commit identity, and performs no automatic documentation lifecycle work or additional AI/session check;
- requires the exact explicit action and cancel-default destructive warning;
- replaces only `GeurtsGameForgeDocumentation` with the current complete `main` tree;
- produces one detached writable snapshot and discards its local drift on the next confirmed Update;
- leaves `Docs/GameDesign` and every other project path untouched;
- clears installed status at the destructive boundary, writes a new receipt only after complete success, has no rollback or blocking recovery state, and reports a missing or incomplete result honestly after failure; and
- follows the copied-`AGENTS.md` same-snapshot entry chain.
