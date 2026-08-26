# Game Forge Intelligence Integration Contract

**Version:** 0.7.0
**Status:** Approved integration contract
**Primary audience:** Game Forge Intelligence, AI coding agents, and automated development systems
**Secondary audience:** Human developers and package maintainers
**Canonical path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`
**Concrete integration:** Game Forge Intelligence
**Reusable category:** Geurts-compatible Unity AI integration package

---

## 1. Purpose and Authority

This document defines the exact boundary between the Geurts Game Forge documentation package and Game Forge Intelligence. It is normative for integrations that claim v0.7.0 compatibility.

The primary audience is AI coding agents and automated development systems. Requirements use stable names, literal paths, explicit states, and deterministic failure behaviour. Human readability remains important but does not override machine precision.

Authority is divided as follows:

- This repository owns documentation, schemas, templates, and platform-neutral automation.
- `GeurtsTechniqueManifest.md` owns package versions and file classification.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` explains folder meaning and placement.
- `GeurtsTechniques/GeurtsFolderStructureDefinition.json` owns the literal folder-creation registry.
- Project-specific design authority remains under `<ProjectRoot>/Docs/GameDesign/`.
- The Game Forge Intelligence repository owns Unity Editor integration, UI, lifecycle hooks, credential UX, file watching, and package distribution.

Unity plugin source is not present in this documentation repository. Do not fabricate Unity implementation files here.

---

## 2. Canonical Repository and Distribution

### 2.1 Verified access facts

The canonical repository is:

```text
https://github.com/Geurtsy/GeurtsGameForge_Documentation.git
```

The canonical branch is:

```text
main
```

Repository access was verified during v0.7.0 preparation as **private and authenticated**. Anonymous Git access failed and unauthenticated GitHub API access returned `404`. An integration must not describe or treat this repository as anonymously cloneable unless the owner explicitly changes visibility and versions this contract.

### 2.2 v0.7.0 distribution strategy

The distribution strategy is:

```text
authenticated private canonical repository + validated local synchronized copy
```

Game Forge Intelligence must use the user's configured GitHub authentication provider without logging, copying, or persisting credentials itself. Authentication grants repository access; it does not change documentation authority.

There is no approved bundled fallback snapshot in v0.7.0. A future bundled fallback requires an explicit owner decision and must record its package version and commit, display that it may be stale, and remain lower authority than any newer successfully synchronized canonical copy.

The integration must not change repository visibility.

---

## 3. Local-First Operating Model

Normal AI prompts use the last validated local copy at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Game Forge Intelligence must not contact GitHub for every prompt.

At Unity launch, project open, or AI-session initialization, the integration performs one lightweight update check. The check compares the validated local commit with `refs/heads/main` from the authenticated canonical repository. It must not download the full repository when the remote commit is unchanged.

Successful mode output uses only these status strings:

| State | Required meaning |
|---|---|
| `CURRENT` | The validated local commit equals the available canonical commit. |
| `UPDATE_AVAILABLE` | A different canonical commit is available; current and available commit identifiers are shown. Package versions may also be shown when they are available without turning the lightweight check into a full download. |
| `NOT_INSTALLED` | No validated local synchronized copy is installed. |
| `UPDATED` | Update mode installed and validated the reported canonical commit. |
| `VALID` | Validate mode confirmed the installed local copy without contacting GitHub. |

The bootstrap supports exact modes `-Mode Check`, `-Mode Update`, and `-Mode Validate`. `Check` is non-mutating. `Update` synchronizes only when policy or user approval permits. `Validate` checks the current local copy without contacting GitHub. Failures use the stable exit codes below rather than a success status string. A failed check must not describe the installed copy as current.

The exact user-facing manual action name is:

```text
Update Geurts Game Forge Documentation
```

Package policy may allow automatic updates or require approval. The selected policy must be visible and auditable.

---

## 4. Synchronization Transaction

### 4.1 Required visible result

After successful synchronization, the synchronized directory has exactly these three visible entries:

```text
GeurtsGameForgeDocumentation/
├── AI_READ_FIRST.md
├── GeurtsTechniqueManifest.md
└── GeurtsTechniques/
```

No project-specific GDD file belongs in this directory. Repository support files such as `README.md`, `AGENTS.md`, `Tools/`, `Ideas/`, `Migrations/`, and `Tests/` are not part of the synchronized Unity-project copy.

### 4.2 Atomic update algorithm

Game Forge Intelligence or the platform-neutral bootstrap must:

1. Acquire a single-writer synchronization lock without deleting the current copy.
2. Resolve the authenticated remote `main` commit.
3. Create a staging checkout in a tool-owned temporary location outside the active synchronized directory.
4. Materialize only `AI_READ_FIRST.md`, `GeurtsTechniqueManifest.md`, and `GeurtsTechniques/`.
5. Validate the staged package, including manifest-listed synchronized files, versions, canonical paths, JSON definitions, and chat-only classification.
6. Record the exact candidate commit.
7. Preserve the last valid copy as rollback state.
8. Replace the active copy atomically, or use a rename sequence that restores the previous copy if any step fails.
9. Validate the active replacement again.
10. Remove staging and rollback state only according to retention policy after success.
11. Report the previous commit, synchronized commit, and validation outcome. Also report the package version after it is available from the validated local manifest.

A failed update must leave the previous valid copy usable. It must never erase the valid copy before the replacement passes validation. If an initial installation has no prior valid copy and post-promotion validation fails, remove the invalid promoted candidate and report that no valid local copy exists.

### 4.3 Stable failure categories

| Category | Exit code | Meaning and required action |
|---|---:|---|
| `SUCCESS` | `0` | The requested mode completed with its applicable success status. |
| `CONFIGURATION` | `10` | Required repository, branch, local path, sparse path, or mode configuration is missing or malformed. Do not attempt synchronization. |
| `DEPENDENCY` | `11` | A required executable or runtime dependency is unavailable. Identify the missing dependency. |
| `AUTHENTICATION` | `20` | GitHub rejected or could not obtain credentials. Tell the user the canonical repository is private, authenticated access is required, and how to sign in through the configured Git credential provider. Never print a secret. |
| `NETWORK` | `21` | DNS, transport, proxy, TLS, timeout, or GitHub availability prevented the operation. Preserve the last valid copy and distinguish this from authentication. |
| `REMOTE` | `22` | The authenticated remote, configured branch, or requested remote reference could not be resolved for a reason not classified as authentication or network failure. |
| `CHECKOUT` | `30` | Git could not materialize the configured commit. Preserve the last valid copy and report branch and repository identifiers. |
| `VALIDATION` | `31` | Staged or active content failed package validation. Reject the candidate, preserve the last valid copy, and report failed checks. |
| `CONFLICT` | `32` | Existing state cannot be updated safely without a user decision. Preserve all user content and identify the conflicted item. |
| `FILE_LOCK` | `33` | A file or directory could not be replaced because another process held it. Preserve both valid and staged data when practical and identify the locked path without exposing unrelated user paths. |
| `FILESYSTEM` | `34` | A filesystem operation failed for a reason other than a confirmed lock. Preserve recoverable state and identify the scoped operation. |
| `UNKNOWN` | `35` | An unclassified failure occurred. Preserve the last valid copy and include non-secret diagnostic context. |

`SYNC OK` may be emitted only after the active local copy has passed post-replacement validation.

---

## 5. AI Session and Game Design Discovery

At project or AI-session initialization, Game Forge Intelligence must check once for:

```text
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

When present, read it and record its version plus a timestamp or content hash. This is lightweight discovery, not permission to load every GDD document.

- Purely technical tasks may proceed without unrelated full design documents.
- Player-facing tasks must load every relevant design document identified by the manifest before implementation.
- Re-read the manifest when its recorded timestamp, hash, or version changes.
- Never treat synchronized files under `GeurtsGameForgeDocumentation/` as project design authority.
- If relevant design documentation is absent, the AI must state its assumption before changing player-facing behaviour.

### 5.1 Missing scaffolding

During explicit setup, create only missing items:

```text
<ProjectRoot>/Docs/GameDesign/
<ProjectRoot>/Docs/GameDesign/README.md
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

Use the controlled templates under `Tools/AIAgentInstructionTemplates/GameDesign/`. Never overwrite existing project-specific content and never fabricate mechanics, narrative, balance, progression, characters, or other design facts. Unknown fields remain explicitly unprovided. Report each item as created or already existing. Re-running setup must create nothing when all three items already exist.

---

## 6. Game Design Manifest Maintenance

### 6.1 Supported discovery set

For v0.7.0, the deterministic maintainer scans regular `*.md` files recursively under `Docs/GameDesign/`, includes `README.md`, and excludes `GameDesignManifest.md` from indexing itself. Hidden files, temporary files, backups, and tool lock files are excluded. Other extensions are detected and reported as unsupported; they are not silently indexed.

All recorded document paths are project-root-relative, use `/`, and remain inside `Docs/GameDesign/` after path resolution.

### 6.2 Required manifest fields

Every document record supports:

- stable identifier;
- document path;
- purpose or design domain;
- status;
- document version when explicitly available;
- authority or precedence when explicitly available;
- optional tags or task categories.

When purpose, version, authority, or tags cannot be determined from explicit document metadata or preserved manifest metadata, use an explicit unprovided or requires-classification value. Do not infer purpose from a filename.

The deterministic table region is delimited exactly by:

```text
<!-- GEURTS-GDD-MANIFEST-BEGIN version="0.7.0" -->
<!-- GEURTS-GDD-MANIFEST-END -->
```

Content outside that region is manually owned and must be preserved.

### 6.3 Deterministic reconciliation

The only valid manifest location is `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md`, including when `-ManifestPath` is supplied. Before reading it, reject any junction, symbolic link, or other reparse point that could redirect discovery or writes outside the project, then acquire the single-writer lock. Only the operation that acquired the lock may remove its lock file. An unsupported future managed-region version is a conflict and must be preserved without downgrade.

The maintainer must:

1. Acquire a single-writer lock and suppress reactions to its own temporary and final writes.
2. Enumerate supported files and normalize paths.
3. Sort by normalized path using one documented ordinal comparison.
4. Parse the current managed manifest region and preserve valid manually authored metadata.
5. Match unchanged files by normalized path.
6. Detect a rename or move only when a unique previous record can be matched by stable identifier or content hash; preserve its metadata and update its path.
7. Add unmatched files with deterministic non-semantic identifiers and explicit requires-classification metadata.
8. Remove records whose documents no longer exist while reporting each removal.
9. Reject duplicate identifiers, duplicate normalized paths, ambiguous rename matches, paths outside the GDD root, or malformed records before writing.
10. Render the managed region in one canonical order and format.
11. Skip the write when rendered content is byte-equivalent after defined newline normalization.
12. Otherwise write a temporary file, validate it, and atomically replace the manifest.
13. Report added, removed, renamed, moved, imported, unchanged, unsupported, and conflicted documents.

The same inputs and preserved metadata must produce the same manifest. A second run without external changes must produce no file change.

### 6.4 Import and watcher behaviour

Import is an explicit user or package action. It must never move or overwrite an existing GDD file silently. Filename collisions, duplicate identifiers, and ambiguous duplicates are conflicts that require user resolution.

When an importer invokes `Tools/UpdateGameDesignManifest.ps1`, it passes each imported project-relative path through `-ImportedPath`. A scan without that explicit signal reports an unmatched file as `Added`; it must not guess that the file was imported.

A Unity file watcher must debounce/coalesce event bursts, wait for writes to settle, ignore its own lock/temp/output events, and run the same deterministic maintainer rather than maintaining a second algorithm. Recursive self-triggering is a defect.

---

## 7. Folder Definition Consumption

Game Forge Intelligence must load:

```text
GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureDefinition.json
```

It must validate the schema, versions, counts, unique normalized paths, allowed content categories, parent relationships, automation owner, and creation profiles before use.

The calling operation may create only entries for its declared profile and only when `automation.mayCreate` is `true`. It must create parents before children and report created, existing, skipped, invalid, and conflicted paths.

Every v0.7.0 entry has `automation.mayRemove: false`. Game Forge Intelligence must not remove a folder or its contents because a path disappears from a newer definition. Such paths may be reported for manual review only.

The Markdown technique remains the explanatory authority. The JSON definition is the automation authority. A mismatch is category `VALIDATION`, exit code `31`.

---

## 8. Managed Native AI Entries

The managed native entry set is:

```text
AGENTS.md
.github/copilot-instructions.md
.github/instructions/geurts-unity.instructions.md
.github/instructions/geurts-game-design.instructions.md
```

Every managed Geurts route must ultimately point to:

```text
GeurtsGameForgeDocumentation/AI_READ_FIRST.md
```

The manager must classify each target before mutation:

| Classification | Required behaviour |
|---|---|
| `fully-managed` | Refresh from the current template when its managed version changes. Preserve a recoverable backup before a destructive migration. |
| `partially-managed` | Replace only the explicit managed region. Preserve all content outside the markers byte-for-byte where practical. Missing or malformed markers are a conflict. |
| `user-owned` | Do not overwrite. Report preserved/skipped. |
| `legacy-exact` | If content exactly matches a known v0.4, v0.5, or v0.6 catalog entry, back it up and migrate it deterministically. |
| `legacy-modified` | Preserve it, create a backup if proposing replacement, and report a conflict requiring user resolution. |

Markdown managed regions use these exact marker forms:

```text
<!-- GEURTS-MANAGED-BEGIN id="<id>" version="<version>" sha256="<sha256>" -->
<!-- GEURTS-MANAGED-END id="<id>" -->
```

Inside YAML frontmatter, scoped instruction templates use the same tokens as `#` YAML comments. These markers must remain between the opening and closing `---` delimiters. The `id` values must be unique within the file and match their region ends, the version must identify the installed template, and `sha256` must describe the normalized managed payload according to the native-entry migration catalog. HTML markers require complete `<!-- ... -->` comments. Unsupported newer managed versions must be preserved and reported as conflicts, never downgraded.

```text
# GEURTS-MANAGED-BEGIN id="<id>" version="<version>" sha256="<sha256>"
# GEURTS-MANAGED-END id="<id>"
```

The historical catalog must cover the v0.4 direct-`Docs` style, the v0.5 mixed style including the historical hidden synchronization route, and the v0.6 visible-route style. User-authored changes may never be inferred absent merely because a file resembles a catalog entry.

The exact opt-out signal is `GEURTS-MANAGED-OPT-OUT`. When present according to the manager's parser, the file is preserved and reported skipped. The manager must operate idempotently and report created, updated, preserved, skipped, and conflicted files. A backup failure must prevent the corresponding destructive replacement.

---

## 9. Audit Record Contract

Game Forge Intelligence must retain a machine-readable audit record for documentation checks, synchronization, validation, folder creation, native-entry migration, GDD maintenance, and AI-session initialization.

Each record contains:

- audit schema version;
- UTC timestamp and unique event identifier;
- operation and result state;
- canonical repository and branch;
- authenticated-private access mode without credentials;
- previous, available, synchronized, and AI-used commit identifiers when applicable;
- package and definition versions when applicable;
- whether any fallback was used;
- validation check identifiers and outcomes;
- stable failure category when unsuccessful;
- created, added, imported, renamed, moved, updated, unchanged, existing, preserved, skipped, removed, unsupported, and conflicted item lists as applicable.

Audit storage is plugin-owned and must not be placed inside `GeurtsGameForgeDocumentation/` or `Docs/GameDesign/`. Logs must not contain credentials, access tokens, document contents, or unrelated absolute user paths. Game Forge Intelligence must expose the exact documentation commit used by each AI session.

---

## 10. Repository Responsibility Boundary

### Implemented in this documentation repository

- Canonical techniques, manifest, JSON folder definition, templates, contracts, and migration guidance.
- Platform-neutral PowerShell tools for check/update/validate, folder creation, native-entry management, GDD manifest maintenance, and documentation validation.
- Temporary-repository automation tests and historical native-entry migration catalog.

### Must be implemented in the Game Forge Intelligence repository

- Unity launch and project-open hooks.
- The menu, command, or console action named `Update Geurts Game Forge Documentation`.
- User-facing authentication setup and credential-provider integration.
- Update notifications, approval policy UI, and current/available version presentation.
- Atomic synchronization orchestration and lock UX when not delegated to the platform-neutral bootstrap.
- Folder creation UI driven by the synchronized JSON definition.
- GDD import UI and Unity file watcher integration.
- Duplicate/conflict resolution UI.
- Managed native-entry upgrade UI and opt-out controls.
- Local cache and rollback retention policy.
- Validation/repair UI and audit-log presentation.
- Any approved offline fallback packaging.

The plugin should invoke or faithfully implement the platform-neutral contracts. It must not maintain an independent hard-coded copy of the complete folder hierarchy, native templates, or GDD reconciliation algorithm.

---

## 11. Conformance Conditions

Game Forge Intelligence is v0.7.0-compatible only when it:

- uses authenticated access to the private canonical repository;
- uses local validated documentation for normal prompts;
- distinguishes check, update, and validate operations;
- preserves the last valid synchronized copy on every failed update;
- produces exactly the three required visible synchronized entries;
- reads the GDD manifest once at initialization and lazily loads relevant documents;
- creates missing GDD scaffolding without overwriting or inventing design facts;
- maintains the GDD manifest deterministically without recursive watcher events;
- consumes the folder JSON and never automatically deletes managed folders;
- safely classifies and migrates native entry files while preserving user content;
- records the exact documentation commit used by AI;
- keeps project GDD files and synchronized Geurts documentation in separate domains.
