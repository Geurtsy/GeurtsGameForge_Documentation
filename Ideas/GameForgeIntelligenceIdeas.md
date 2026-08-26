# Game Forge Intelligence Ideas

**Version:** 0.7.0
**Status:** Non-normative product and implementation idea register
**Primary audience:** Game Forge Intelligence product owners, AI coding agents, and automated development systems
**Secondary audience:** Human developers
**Canonical path:** `Ideas/GameForgeIntelligenceIdeas.md`

This document records concepts that should not silently become Geurts implementation standards. Approved requirements are summarized for context and link back to their normative authorities. Proposed ideas, open decisions, and deferred work remain non-mandatory until explicitly approved and moved into an authoritative technique or contract.

---

## Approved Requirements

The following requirements are approved for v0.7.0. Their normative wording is in `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` and the applicable techniques.

- Use the authenticated private canonical repository and a validated local synchronized copy.
- Use local documentation during normal prompts; perform one lightweight update check at Unity, project, or AI-session initialization.
- Provide `Check`, `Update`, and `Validate` documentation modes.
- Provide a manual action named `Update Geurts Game Forge Documentation`.
- Preserve the last valid synchronized copy until a candidate update passes validation.
- Produce exactly `AI_READ_FIRST.md`, `GeurtsTechniqueManifest.md`, and `GeurtsTechniques/` as visible synchronized entries.
- Read the project GDD manifest once during initialization when it exists and lazily load relevant design documents.
- Create missing GDD scaffolding from controlled templates without overwriting or inventing project design facts.
- Maintain `Docs/GameDesign/GameDesignManifest.md` deterministically and idempotently.
- Create folders from `GeurtsFolderStructureDefinition.json`; never automatically delete project content.
- Upgrade Geurts-managed native AI entries without silently overwriting user-authored content.
- Report authentication, network, remote, checkout, validation, conflict, file-lock, filesystem, and unknown failures distinctly.
- Record the exact documentation commit used by each AI session.

---

## Proposed Ideas

These ideas are candidates for product design or later contract versions. They are not approved implementation requirements merely because they appear here.

### Unity-launch documentation update checking

- Run the lightweight commit check after the project becomes stable rather than blocking the earliest Unity splash/loading phase.
- Cache a successful check for the current Unity launch to avoid duplicate network calls from multiple editor windows.
- Offer a non-modal status indicator for `CURRENT`, `UPDATE_AVAILABLE`, or a categorized check failure.

### Manual documentation update action

- Add the approved action to a `Game Forge Intelligence` Unity menu.
- Offer a pre-update summary showing current commit, available commit, package versions, and local validation state.
- Add an optional preview of package changelog and migration guidance before approval.

### Local cache behaviour

- Retain one or more validated rollback snapshots in a plugin-owned cache outside `Assets/`, synchronized documentation, and project GDD files.
- Deduplicate cache objects by commit identifier.
- Provide age- or size-based cleanup that never touches the active synchronized copy.

### Folder creation from the machine-readable definition

- Present creation profiles and missing paths in an Editor window before creation.
- Show category, purpose, requirement, and automation owner from the JSON definition.
- Offer validation-only and repair-missing-folders actions while keeping deletion unavailable.

### Automatic GDD manifest maintenance

- Run the platform-neutral deterministic maintainer from Unity rather than reimplementing its algorithm in C#.
- Display added, removed, renamed, moved, unclassified, unsupported, and conflicted results.
- Provide a focused classification workflow for records marked as requiring classification.

### Importing GDD files

- Support drag-and-drop import into `Docs/GameDesign/` with an explicit destination preview.
- Preserve source files by copying unless the user explicitly chooses a move.
- Offer format conversion as a separate action so import never silently changes content.

### GDD file watcher behaviour

- Debounce event bursts and wait until files are readable and stable.
- Pause the watcher during package-driven imports and manifest writes.
- Surface watcher conflicts without blocking unrelated Unity asset imports.

### Conflict and duplicate handling

- Provide side-by-side metadata comparison for duplicate identifiers or ambiguous rename matches.
- Offer deterministic choices such as keep existing identifier, assign a new identifier, merge metadata, or exclude a file.
- Write a resolution receipt to the audit log.

### Managed AI-entry upgrades

- Preview managed-region changes and preserved user regions before applying them.
- Provide one-click restore from the backup created for a legacy migration.
- Show why a file was classified as fully managed, partially managed, user-owned, or legacy.

### Authentication and private/public distribution options

- Add guided Git Credential Manager sign-in for the authenticated private strategy.
- Investigate versioned public documentation releases for consumers who should not receive repository access.
- Investigate organization-managed credentials for build machines without embedding secrets in projects.

### Update notifications

- Let users choose non-modal, modal, or silent-policy-approved notifications.
- Distinguish package version changes from commit-only documentation corrections.
- Link a notification to the relevant migration guide when a breaking path or bootstrap contract changes.

### Offline fallback behaviour

- Evaluate an explicitly versioned bundled snapshot for first-run offline use.
- Show a persistent stale warning until canonical access succeeds.
- Never let fallback content outrank a newer validated local or canonical copy.

### Validation and repair tools

- Add an Editor dashboard that runs repository, synchronized-layout, folder-definition, GDD-manifest, and native-entry validation.
- Separate safe automatic repair from actions requiring user confirmation.
- Export a support bundle that excludes credentials and project design contents.

### Potential Unity Editor UI

- Combine documentation status, GDD status, folder health, native-entry state, and recent audit events in one window.
- Keep advanced details expandable so routine status remains concise.
- Support command-palette and console equivalents for automation and accessibility.

### Audit logs showing which documentation version an AI used

- Attach the documentation commit and package version to each AI task or generated-change record.
- Provide filters by project, operation, result, and commit.
- Offer a copyable audit summary for bug reports and pull-request descriptions.

---

## Open Decisions

These decisions require explicit product-owner direction:

1. Whether to remain authenticated-private only or also publish versioned public documentation releases.
2. Whether Game Forge Intelligence may bundle an offline fallback snapshot, and who owns its release and retirement process.
3. Whether updates are automatic by default, approval-required by default, or controlled by organization policy.
4. How long validated rollback snapshots and audit records are retained.
5. Which GitHub authentication experiences must be supported beyond the configured Git credential provider.
6. Which source formats, if any beyond Markdown, the GDD importer may accept or convert.
7. Whether GDD manifest changes should be committed automatically, proposed as a change set, or left for normal source-control workflows.
8. Whether watcher conflicts block only manifest maintenance or also player-facing AI work that depends on the affected documents.
9. Which native AI entry files should default to fully managed versus partially managed installation.
10. Whether audit records remain local only or may be exported to an organization service under an explicit privacy policy.

---

## Deferred Implementation

The following work belongs in the Game Forge Intelligence repository and is deferred from this documentation repository:

- Unity Editor lifecycle hooks for launch, project-open, and AI-session initialization.
- Unity menu/command implementation for `Update Geurts Game Forge Documentation`.
- Credential setup UI and authenticated-private repository access UX.
- Update approval, notification, rollback, and cache-retention UI.
- Folder-definition Editor tooling and repair preview.
- GDD import UI, filesystem watcher, debounce, and conflict-resolution UI.
- Native-entry migration preview, backup restore, and opt-out controls.
- Validation dashboard and repair workflows.
- Audit-log persistence and visualization.
- Any bundled fallback artifact and its release pipeline after owner approval.

Platform-neutral schemas, templates, scripts, migration catalogs, and tests remain appropriate work for this documentation repository. Deferred Unity implementation must consume those authorities rather than duplicate them.
