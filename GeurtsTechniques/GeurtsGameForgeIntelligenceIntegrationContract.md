# Game Forge Intelligence Integration Contract

**Version:** 0.9.0
**Status:** Approved integration contract
**Primary audience:** Game Forge Intelligence, AI coding agents, and automated development systems
**Secondary audience:** Human developers and package maintainers
**Canonical path:** `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`
**Concrete integration:** Game Forge Intelligence
**Reusable category:** Geurts-compatible Unity AI integration package

---

## 1. Purpose and Authority

This document defines the exact boundary between the Geurts Game Forge documentation package and Game Forge Intelligence. It is normative for integrations that claim v0.9.0 compatibility.

The primary audience is AI coding agents and automated development systems. Requirements use stable names, literal paths, explicit states, and deterministic failure behaviour. Human readability remains important but does not override machine precision.

Authority is divided as follows:

- This repository owns documentation, schemas, templates, contracts, and platform-neutral automation.
- `GeurtsTechniqueManifest.md` owns package versions and file classification.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` explains folder meaning and placement.
- `GeurtsTechniques/GeurtsFolderStructureDefinition.json` owns the literal folder-creation registry.
- Project-specific design authority remains under `<ProjectRoot>/Docs/GameDesign/`.
- The Game Forge Intelligence repository owns Unity Editor integration, UI, lifecycle hooks, public-repository access, local synchronization, file watching, contract reconciliation, and plugin distribution.

Versions owned by the technique manifest, folder definition, GDD managed-region format, templates, and other referenced files remain the versions declared by those authorities. Updating this contract does not silently change those independent versions.

### 1.1 Documentation immutability boundary

Game Forge Intelligence consumes and enforces the documentation; it does not author, rewrite, or reinterpret the documentation as plugin-owned content.

The plugin must treat both of these documentation domains as read-only content:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
<ProjectRoot>/Docs/GameDesign/
```

The only permitted write inside `GeurtsGameForgeDocumentation/` is the atomic replacement of the complete synchronized copy with exact files obtained from the validated canonical repository. Synchronization is a transport operation, not permission to patch, reformat, regenerate, or selectively rewrite documentation files.

Game Forge Intelligence must not create, modify, move, rename, or delete project-specific GDD files or `GameDesignManifest.md`. It may discover them, read them, detect drift, report missing scaffolding, and hand a user-approved authoring task to a developer or AI coding agent outside the plugin's automatic lifecycle.

Plugin-owned configuration, cache data, rollback state, fingerprints, and audit records must remain outside both documentation domains. The limited folder-creation permissions in Section 7, managed native-entry permissions in Section 8, and project-root `.gitignore` permissions in Section 9 apply only to their explicitly declared integration surfaces; they do not grant permission to edit documentation content.

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

Repository visibility was verified during v0.9.0 preparation as **public**. Game Forge Intelligence must treat anonymous read-only access as the default and must not require a GitHub sign-in merely to check, clone, or synchronize the canonical documentation.

### 2.2 v0.9.0 distribution strategy

The distribution strategy is:

```text
public canonical repository + validated local synchronized copy
```

No credential is required for normal read-only synchronization. If a user has optionally configured a GitHub authentication provider, Game Forge Intelligence may use it for applicable GitHub operations, but it must not log, copy, or persist credentials itself. Failure of optional authentication must not prevent an anonymous read-only attempt against the public canonical repository when that fallback is safe and permitted by policy.

There is no approved bundled fallback snapshot in v0.9.0. A future bundled fallback requires an explicit owner decision and must record its package version and commit, display that it may be stale, and remain lower authority than any newer successfully synchronized canonical copy.

The integration must not change repository visibility.

---

## 3. Local-First Operating Model

Normal AI prompts use the last validated local copy at:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Game Forge Intelligence must not contact GitHub for every prompt.

At Unity launch, project open, AI-session initialization, and the first project open after the installed plugin version changes, the integration performs one lightweight documentation and compatibility check. The documentation check compares the validated local commit with `refs/heads/main` from the public canonical repository. It must not download the full repository when the remote commit is unchanged.

Successful synchronization-mode output uses only these status strings:

| State | Required meaning |
|---|---|
| `CURRENT` | The validated local commit equals the available canonical commit. |
| `UPDATE_AVAILABLE` | A different canonical commit is available; current and available commit identifiers are shown. Package versions may also be shown when they are available without turning the lightweight check into a full download. |
| `NOT_INSTALLED` | No validated local synchronized copy is installed. |
| `UPDATED` | Update mode installed and validated the reported canonical commit. |
| `VALID` | Validate mode confirmed the installed local copy without contacting GitHub. |

Contract reconciliation uses a separate result so documentation synchronization and plugin integration are never confused:

| Result | Required meaning |
|---|---|
| `CONTRACT_UNCHANGED` | The validated contract version and content fingerprint equal the last successfully applied contract. |
| `REINTEGRATED` | The validated contract was new or a manual reapply was requested, and the plugin successfully reconciled every supported integration surface. |
| `PLUGIN_UPDATE_REQUIRED` | The contract requires behaviour that the installed plugin cannot faithfully provide without source or binary changes. The candidate documentation must not become active for AI use. |
| `REINTEGRATION_FAILED` | The installed plugin claimed support but failed while applying the contract. Restore the previous valid documentation and integration state. |

The bootstrap supports exact modes `-Mode Check`, `-Mode Update`, and `-Mode Validate`. `Check` is non-mutating. `Update` synchronizes only when policy or user approval permits. `Validate` checks the current local copy without contacting GitHub. Failures use the stable exit codes below rather than a success status string. A failed check must not describe the installed copy as current.

The exact user-facing manual action name is:

```text
Update Geurts Game Forge Documentation
```

This action must always remain available. When invoked, it must:

1. resolve the current public `main` commit;
2. synchronize when the commit differs, or validate the existing local copy when it does not;
3. read and validate `GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md`;
4. compare the contract version and normalized content fingerprint with the last successfully applied contract;
5. re-run contract reconciliation even when the documentation commit is unchanged, because the user explicitly requested a full refresh; and
6. report the documentation result and contract-reintegration result separately.

A changed contract must be processed before the candidate documentation becomes active for AI use. When the change is within the installed plugin's declared data-driven capabilities, Game Forge Intelligence must reapply its plugin-owned configuration, routing, watchers, folder-definition consumers, managed native entries, project-root `.gitignore` setup state, validation rules, and audit presentation from the updated contract.

When a changed contract requires plugin source or binary changes, Game Forge Intelligence must not edit its own source, silently execute arbitrary instructions from Markdown, or falsely claim reintegration. It must either initiate a user-approved reintegration task for the configured AI coding agent against the Game Forge Intelligence repository, or report `PLUGIN_UPDATE_REQUIRED` with the unsupported requirements. Until a compatible plugin is installed, preserve the previous valid documentation and integration state for AI use.

Package policy may allow automatic documentation updates or require approval. The selected policy must be visible and auditable. Contract-driven source changes always require explicit user approval.

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

Every synchronized file must remain an exact canonical file after defined transport newline handling. Game Forge Intelligence must not patch, reformat, merge, or regenerate documentation content during synchronization or reintegration.

### 4.2 Atomic update and reintegration algorithm

Game Forge Intelligence or the platform-neutral bootstrap must:

1. Acquire a single-writer synchronization lock without deleting the current copy.
2. Resolve the public remote `main` commit.
3. Create a staging checkout in a tool-owned temporary location outside the active synchronized directory.
4. Materialize only `AI_READ_FIRST.md`, `GeurtsTechniqueManifest.md`, and `GeurtsTechniques/` without changing their content.
5. Validate the staged package, including manifest-listed synchronized files, versions, canonical paths, JSON definitions, chat-only classification, and the integration contract.
6. Record the exact candidate commit, package version, contract version, and normalized contract fingerprint.
7. Compare the staged contract with the last successfully applied contract and perform a compatibility preflight against the installed plugin.
8. If the contract requires unsupported plugin changes, reject the candidate before promotion and report `PLUGIN_UPDATE_REQUIRED`.
9. Preserve the last valid synchronized copy and last successfully applied integration state as rollback state.
10. Replace the active synchronized copy atomically, or use a rename sequence that restores the previous copy if any step fails.
11. Validate the active replacement again.
12. Reconcile the plugin-owned integration state against the active validated contract.
13. If reintegration fails, restore both the previous valid synchronized copy and the previous integration state.
14. Remove staging and rollback state only according to retention policy after complete success.
15. Report the previous commit, synchronized commit, package version, contract version and fingerprint, validation outcome, and reintegration outcome.

A failed update or reintegration must leave the previous valid documentation and integration state usable. It must never erase the valid copy before the replacement and reintegration pass validation. If an initial installation has no prior valid copy and post-promotion validation or reintegration fails, remove the invalid promoted candidate and report that no valid local copy exists.

When the manual action is invoked and the remote commit is unchanged, the integration may skip staging and replacement, but it must still validate the active copy, re-read the contract, and re-run reconciliation.

### 4.3 Stable failure categories

| Category | Exit code | Meaning and required action |
|---|---:|---|
| `SUCCESS` | `0` | The requested mode completed with its applicable success status. |
| `CONFIGURATION` | `10` | Required repository, branch, local path, sparse path, or mode configuration is missing or malformed. Do not attempt synchronization. |
| `DEPENDENCY` | `11` | A required executable or runtime dependency is unavailable. Identify the missing dependency. |
| `COMPATIBILITY` | `12` | The validated contract requires behaviour outside the installed plugin's declared capabilities. Preserve the previous valid documentation and integration state and report `PLUGIN_UPDATE_REQUIRED`. |
| `AUTHENTICATION` | `20` | An optionally configured GitHub authentication provider failed. Never print a secret. Because the canonical repository is public, retry anonymous read-only access when safe and permitted; do not tell the user authentication is required for normal synchronization. |
| `NETWORK` | `21` | DNS, transport, proxy, TLS, timeout, or GitHub availability prevented the operation. Preserve the last valid copy and distinguish this from optional-authentication failure. |
| `REMOTE` | `22` | The public remote, configured branch, or requested remote reference could not be resolved for a reason not classified as authentication or network failure. |
| `CHECKOUT` | `30` | Git could not materialize the configured commit. Preserve the last valid copy and report branch and repository identifiers. |
| `VALIDATION` | `31` | Staged or active content failed package validation. Reject the candidate, preserve the last valid copy, and report failed checks. |
| `CONFLICT` | `32` | Existing state cannot be updated safely without a user decision. Preserve all user content and identify the conflicted item. |
| `FILE_LOCK` | `33` | A file or directory could not be replaced because another process held it. Preserve both valid and staged data when practical and identify the locked path without exposing unrelated user paths. |
| `FILESYSTEM` | `34` | A filesystem operation failed for a reason other than a confirmed lock. Preserve recoverable state and identify the scoped operation. |
| `UNKNOWN` | `35` | An unclassified failure occurred. Preserve the last valid copy and include non-secret diagnostic context. |
| `REINTEGRATION` | `36` | A contract-compatible reintegration failed after promotion or during a forced reapply. Restore the previous valid documentation and integration state and report the failed integration steps. |

`SYNC OK` may be emitted only after the active local copy has passed post-replacement validation. `REINTEGRATION OK` may be emitted only after the plugin-owned integration state has passed reconciliation validation. The manual update action is complete only when both applicable results have succeeded.

---

## 5. AI Session and Game Design Discovery

At project or AI-session initialization, Game Forge Intelligence must check once for:

```text
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

When present, read it and record its version plus a timestamp or content hash. This is lightweight, read-only discovery, not permission to load every GDD document or modify the manifest.

- Purely technical tasks may proceed without unrelated full design documents.
- Player-facing tasks must load every relevant design document identified by the manifest before implementation.
- Re-read the manifest when its recorded timestamp, hash, or version changes.
- Never treat synchronized files under `GeurtsGameForgeDocumentation/` as project design authority.
- If relevant design documentation is absent, the AI must state its assumption before changing player-facing behaviour.
- Never modify a GDD document or the manifest as part of project initialization, documentation synchronization, contract reintegration, or normal AI-session operation.

### 5.1 Missing scaffolding

Game Forge Intelligence must detect and report whether these expected items are missing:

```text
<ProjectRoot>/Docs/GameDesign/
<ProjectRoot>/Docs/GameDesign/README.md
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

The plugin must not create them. It may show the exact missing paths, identify the controlled templates under `Tools/AIAgentInstructionTemplates/GameDesign/`, and offer to create a separate user-approved authoring task for a developer or AI coding agent.

A separately invoked authoring workflow may create only missing items from the controlled templates. It must never overwrite existing project-specific content and must never fabricate mechanics, narrative, balance, progression, characters, or other design facts. Unknown fields remain explicitly unprovided. The workflow reports each item as created or already existing. Re-running it must create nothing when all three items already exist.

---

## 6. Game Design Manifest Maintenance

This section defines the deterministic behaviour of the external maintainer supplied by the documentation repository, including `Tools/UpdateGameDesignManifest.ps1`. It does not grant Game Forge Intelligence permission to write `GameDesignManifest.md` or any other GDD file. The plugin may discover files, read the manifest, detect drift, and offer a user-approved handoff to the external maintainer. It must not invoke that maintainer automatically during launch, synchronization, reintegration, or file-watcher events.

### 6.1 Supported discovery set

For the current v0.7.0 managed-region format, the deterministic maintainer scans regular `*.md` files recursively under `Docs/GameDesign/`, includes `README.md`, and excludes `GameDesignManifest.md` from indexing itself. Hidden files, temporary files, backups, and tool lock files are excluded. Other extensions are detected and reported as unsupported; they are not silently indexed.

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

The externally invoked maintainer must:

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

Import is a separate, explicit user or authoring-agent action. Game Forge Intelligence may provide a handoff UI, but it must not itself copy, move, rename, overwrite, or delete a GDD file. Filename collisions, duplicate identifiers, and ambiguous duplicates are conflicts that require user resolution.

When an external importer invokes `Tools/UpdateGameDesignManifest.ps1`, it passes each imported project-relative path through `-ImportedPath`. A scan without that explicit signal reports an unmatched file as `Added`; it must not guess that the file was imported.

A Unity file watcher must debounce and coalesce event bursts, wait for writes to settle, ignore plugin-owned cache and lock events, invalidate cached discovery data, and report that the manifest may require maintenance. It must not write the manifest or invoke the external maintainer automatically. Recursive self-triggering is a defect.

---

## 7. Folder Definition Consumption

Game Forge Intelligence must load:

```text
GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureDefinition.json
```

It must validate the schema, versions, counts, unique normalized paths, allowed content categories, parent relationships, automation owner, and creation profiles before use.

The calling operation may create only entries for its declared profile and only when `automation.mayCreate` is `true`. It must create parents before children and report created, existing, skipped, invalid, and conflicted paths.

Every v0.7.0 entry has `automation.mayRemove: false`. Game Forge Intelligence must not remove a folder or its contents because a path disappears from a newer definition. Such paths may be reported for manual review only.

Folder creation is project-structure enforcement, not permission to create or edit documentation files. Entries under either documentation domain remain subject to the read-only boundary in Section 1.1.

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

These files are native AI routing and integration entry points, not the authoritative Geurts documentation or project-specific GDD content. The limited mutation rules in this section do not permit any write inside `GeurtsGameForgeDocumentation/` or `Docs/GameDesign/`.

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

Every contract reconciliation must reclassify these targets and apply only the mutations permitted above. It must never modify user-owned content or treat resemblance to a template as ownership.

---

## 9. Project-Root `.gitignore` Provisioning

The canonical custom Unity project `.gitignore` payload is owned by:

```text
GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsGitIgnoreTechnique.md
```

The only automatic target is:

```text
<ProjectRoot>/.gitignore
```

Game Forge Intelligence must run this setup surface during explicit plugin setup and keep it available as a separately rerunnable project-setup action. Contract reconciliation must also re-evaluate the source and target while applying the same preservation rules below.

### 9.1 Custom-source extraction and validation

The plugin must read the technique from the last validated synchronized documentation copy as valid UTF-8. A byte-order mark is permitted only at the beginning of the Markdown document and is removed before parsing. The plugin must extract only the single `gitignore` fenced payload immediately enclosed by these marker forms:

```text
<!-- GEURTS-GITIGNORE-BEGIN version="<version>" target=".gitignore" sha256="<sha256>" -->
<!-- GEURTS-GITIGNORE-END -->
```

The begin marker must be a complete line with the exact attribute order shown. Its immediately following line must consist of three backticks followed by `gitignore`. The payload begins after that line's newline. A line consisting of exactly three backticks must immediately follow the payload's terminal newline, and the exact end marker must immediately follow the closing fence. Reject indentation, extra attributes, extra in-region prose or blank lines, reversed or duplicate markers, any additional in-region fence, or any other grammar.

Normalize the extracted payload to UTF-8 without a byte-order mark, LF newlines, and exactly one terminal LF. The payload itself must not begin with a byte-order mark. The normalized SHA-256 must equal the lowercase 64-hex marker value. The marker version must equal the technique metadata version and the manifest registry version and must be supported by the plugin. The target must equal `.gitignore` using ordinal comparison. Prose, examples, or code outside that marked payload are not ignore rules.

The v1.0.0 custom payload has normalized SHA-256:

```text
7223a9449718942d3a5cad00cf4d4e0dee9c89eb64951541fa4ebfb803acb45b
```

If the custom technique is unavailable, unreadable, unsupported, malformed, or fails its hash check, the plugin must select its installed, versioned Unity `.gitignore` default and report `DEFAULT_FALLBACK`. A valid documentation payload is reported as `CUSTOM_DOCUMENTATION`. The installed default is a plugin-owned template asset, not a bundled Geurts documentation fallback snapshot. It must independently declare a version and normalized SHA-256 and use the same UTF-8, newline, and terminal-newline contract. If both sources are unavailable or invalid, do not write the target and report source result `SOURCE_FAILED` with category `VALIDATION` or `CONFIGURATION` as applicable.

Use of the default does not make an incomplete or malformed v0.9.0 synchronized documentation candidate valid; documentation synchronization validation and project `.gitignore` source selection remain separate results.

### 9.2 Target preservation and write behaviour

The setup operation must:

1. Resolve `<ProjectRoot>/.gitignore` without following any symbolic link, junction, or other reparse point. A target that is a directory, reparse point, non-regular file, or path outside the project root is a conflict.
2. Select and validate the custom documentation payload, or select the versioned default fallback as defined above.
3. If the target is missing, write the selected payload through a project-scoped temporary file using create-new semantics, validate it, recheck that the target is absent, and atomically create the target without replacement with result `CREATED`. If another process creates the target first, never overwrite it; classify the new target through the remaining steps.
4. If an existing regular target is valid UTF-8, with or without a leading byte-order mark, and is normalized-text-equivalent to the selected payload, leave its bytes and timestamp unchanged with result `UNCHANGED`.
5. If the existing target differs or is not valid UTF-8 text, preserve its bytes and timestamp with result `PRESERVED` and identify that user-authored ignore rules were not overwritten.
6. If the target cannot be handled safely, leave it untouched and report `CONFLICT` or the applicable filesystem failure category.

The setup must never append, merge, replace, or reformat a differing existing `.gitignore`; any merge or replacement is a separate user-owned editing task outside this automatic integration surface. A later custom-template version never updates a pre-existing target. The setup must not run Git commands that track, untrack, stage, commit, or remove files, because `.gitignore` does not change files already tracked by Git.

The source technique remains read-only synchronized documentation. The target `.gitignore` is project-owned after creation and is never part of `GeurtsGameForgeDocumentation/`.

---

## 10. Audit Record Contract

Game Forge Intelligence must retain a machine-readable audit record for documentation checks, synchronization, validation, contract compatibility, reintegration, folder creation, native-entry migration, project-root `.gitignore` setup, GDD discovery and drift detection, external-maintainer handoff, and AI-session initialization.

Each record contains:

- audit schema version;
- UTC timestamp and unique event identifier;
- operation and result state;
- canonical repository and branch;
- public access mode and whether optional authentication was attempted, without credentials;
- installed plugin version and declared supported contract range;
- previous, available, synchronized, and AI-used commit identifiers when applicable;
- package, contract, definition, and managed-region versions when applicable;
- previous and active contract fingerprints when applicable;
- contract reconciliation result and affected plugin-owned integration surfaces;
- `.gitignore` source selection, source path, template version, normalized hash, target result, and fallback version when applicable;
- whether any fallback was used;
- validation check identifiers and outcomes;
- stable failure category when unsuccessful;
- created, added, imported, renamed, moved, updated, unchanged, existing, preserved, skipped, removed, unsupported, and conflicted item lists as applicable.

Audit storage is plugin-owned and must not be placed inside `GeurtsGameForgeDocumentation/` or `Docs/GameDesign/`. Logs must not contain credentials, access tokens, document contents, or unrelated absolute user paths. Game Forge Intelligence must expose the exact documentation commit, package version, contract version, and contract fingerprint used by each AI session.

---

## 11. Repository Responsibility Boundary

### Implemented in this documentation repository

- Canonical techniques, manifest, JSON folder definition, templates, contracts, and migration guidance.
- Platform-neutral PowerShell tools for check/update/validate, folder creation, native-entry management, externally invoked GDD manifest maintenance, and documentation validation.
- Temporary-repository automation tests and historical native-entry migration catalog.

### Must be implemented in the Game Forge Intelligence repository

- Unity launch, project-open, AI-session, and plugin-version-change hooks.
- The menu, button, command, or console action named `Update Geurts Game Forge Documentation`.
- Public anonymous repository access for normal read-only checks and synchronization.
- Update notifications, approval policy UI, and current/available version presentation.
- Atomic synchronization orchestration and lock UX when not delegated to the platform-neutral bootstrap.
- Integration-contract loading, validation, version and fingerprint comparison, compatibility preflight, reconciliation, rollback, and reporting.
- A user-approved AI coding-agent handoff for contract changes that require Game Forge Intelligence source changes, or an explicit `PLUGIN_UPDATE_REQUIRED` result when no such handoff is available.
- Folder creation UI driven by the synchronized JSON definition.
- Project-root `.gitignore` setup and rerunnable action driven by the synchronized custom payload, with a versioned default fallback.
- Read-only GDD discovery, manifest drift detection, and optional handoff to the external authoring or maintenance workflow.
- Duplicate/conflict resolution UI for plugin-owned integration surfaces.
- Managed native-entry upgrade UI and opt-out controls.
- Local cache and rollback retention policy.
- Validation/repair UI and audit-log presentation.
- Any approved offline fallback packaging.

The plugin should invoke or faithfully implement the applicable platform-neutral contracts. It must not maintain an independent hard-coded copy of the complete folder hierarchy, native templates, GDD reconciliation algorithm, or integration contract.

The plugin must not automatically invoke documentation-authoring or GDD-maintenance tools. It must never claim that enforcement grants ownership of documentation content. Contract reintegration may alter only plugin-owned state, allowed project folders, explicitly managed native AI-entry regions, and a missing project-root `.gitignore` under Section 9.

---

## 12. Conformance Conditions

Game Forge Intelligence is v0.9.0-compatible only when it:

- uses anonymous read-only access to the public canonical repository by default;
- uses local validated documentation for normal prompts;
- performs a lightweight update and compatibility check at initialization and after a plugin-version change;
- keeps the exact manual action `Update Geurts Game Forge Documentation` available;
- distinguishes check, update, validate, and contract-reintegration results;
- reads, versions, fingerprints, and validates the integration contract during every update or forced manual refresh;
- automatically reapplies supported plugin-owned integration state when the contract changes;
- initiates a user-approved AI coding-agent handoff or reports `PLUGIN_UPDATE_REQUIRED` when a contract change requires plugin source changes;
- preserves the last valid synchronized copy and integration state on every failed update, compatibility preflight, or reintegration;
- produces exactly the three required visible synchronized entries without rewriting their content;
- treats `GeurtsGameForgeDocumentation/` and `Docs/GameDesign/` as read-only documentation domains;
- reads the GDD manifest once at initialization and lazily loads relevant documents;
- reports missing GDD scaffolding without creating or overwriting it;
- detects GDD manifest drift without automatically writing the manifest or invoking the external maintainer;
- consumes the folder JSON and never automatically deletes managed folders;
- safely classifies and migrates native AI entry files while preserving user-owned content;
- provisions a missing project-root `.gitignore` from the validated custom documentation payload, uses and reports its versioned default when that payload cannot be used, and preserves every differing existing target;
- records the exact documentation commit, package version, contract version, and contract fingerprint used by AI; and
- keeps project GDD files, synchronized Geurts documentation, and plugin-owned state in separate domains.
