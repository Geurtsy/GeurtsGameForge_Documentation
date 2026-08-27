# Geurts Game Forge AI Entry Point

**Version:** 0.9.0
**Purpose:** Second-stage package and session boundary after `AGENTS.md`, before manifest resolution.
**Required package path:** `AI_READ_FIRST.md`

## Entry Sequence

Read the applicable source or copied `AGENTS.md` first. Then read this file and immediately continue to:

```text
GeurtsTechniqueManifest.md
```

The manifest alone selects and orders applicable techniques, owns package version resolution and subject ownership, and resolves cross-document conflicts. This file does not provide an alternate reading order or task-routing table.

## Local Package Boundary

For an installed Unity project, the local documentation package is:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

Project-specific design documents remain separate under:

```text
<ProjectRoot>/Docs/GameDesign/
```

Package membership and any integration lifecycle are outside this router's subject. The manifest selects the applicable owner. Do not substitute files from outside the active package's single validated commit.

## Session Boundary

Before implementation, use one current source checkout or local package and record its commit when available. When a documentation integration is involved, follow the manifest-selected integration technique; a direct source-repository AI session or another host does not require Game Forge Intelligence. Do not inspect or select project GDD files here; the manifest first decides whether the GDD Technique applies.

## Pre-Code Lock

Do not create, modify, move, rename, or delete target-project files until:

1. the package entry files are available;
2. `AGENTS.md`, this file, and `GeurtsTechniqueManifest.md` have been read from the same active package; and
3. every technique selected by the manifest for the task has been read.

After those conditions are satisfied, follow the manifest-selected subject authorities.
