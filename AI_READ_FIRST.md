# Geurts Game Forge AI Entry Point

**Version:** 0.11.0
**Purpose:** Second-stage package and session boundary after `AGENTS.md`, before manifest resolution.
**Required package path:** `AI_READ_FIRST.md`

## Entry Sequence

Read the applicable source or copied `AGENTS.md` first. Then read this file and immediately continue to:

```text
GeurtsTechniqueManifest.md
```

The manifest alone selects and orders applicable techniques, owns package version resolution and subject ownership, and resolves cross-document conflicts. This file does not provide an alternate reading order or task-routing table.

## Local Package Boundary

`Geurtsy/GeurtsGameForge_Documentation` is the sole source and authority for all generic Geurts Game Forge documentation. The independent Unity Editor documentation companion may fetch an archive-based, project-local snapshot into:

```text
<ProjectRoot>/GeurtsGameForgeDocumentation/
```

The Windows-only companion is installed from Git through Unity Package Manager, has no Geurts Game Forge God, Game Forge Intelligence, Odin Inspector, or Quantum Console dependency, and lives in a separate repository. No companion implementation belongs in this documentation repository. Any `<PluginPackageRoot>/Documentation~/` contains companion-specific documentation only; it is not a source or duplicate of this package. Project-specific design documents remain separate under:

```text
<ProjectRoot>/Docs/GameDesign/
```

Package membership and any integration lifecycle are outside this router's subject. The manifest selects the applicable owner. Do not substitute files from outside the active package's single validated commit. A confirmed companion Update may replace the complete project-local documentation folder above and the contract's exact closed set of four project AI-routing files. Every non-listed path remains outside that authority; in particular, the companion must not inspect or change `Docs/GameDesign/`.

## Session Boundary

Before implementation, use one current source checkout or project-local fetched copy and record its commit when available. On Unity launch/open, the independent companion may perform its one remote metadata-only update check. That check must not download documentation, inspect project files, or mutate the project. Ordinary AI/session initialization reads the existing local copy and performs no additional remote check or update. The companion performs replacement only after the user selects Update and accepts one confirmation, with Cancel as the default, covering the exact managed documentation and AI-route targets listed by its contract. There is no earlier preview or dry run and no second confirmation. When a documentation integration is involved, follow the manifest-selected integration technique; a direct source-repository AI session or another host does not require the companion. Do not inspect or select project GDD files here; the manifest first decides whether the GDD Technique applies.

## Pre-Code Lock

Do not create, modify, move, rename, or delete target-project files until:

1. the package entry files are available;
2. `AGENTS.md`, this file, and `GeurtsTechniqueManifest.md` have been read from the same active package; and
3. every technique selected by the manifest for the task has been read.

After those conditions are satisfied, follow the manifest-selected subject authorities.
