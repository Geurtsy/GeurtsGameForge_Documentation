<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts AGENTS.md Technique

**Version:** 1.0.0
**Required package path:** `GeurtsTechniques/GeurtsAgentTechnique.md`

## Purpose and ownership

This technique owns the only Codex guide template. The manifest selects it when installing, validating or explaining a Codex guide. The documentation entry point is `AI_READ_FIRST.md`, which routes to `GeurtsTechniqueManifest.md`; there is no intermediate documentation `AGENTS.md`.

## Install Codex guide

The independent Unity documentation companion exposes **Install Codex guide**. The user chooses the destination through a folder picker. The installer creates `AGENTS.md`, the filename Codex automatically discovers in the project instruction chain. Do not edit Codex configuration automatically or claim that any location affects every Codex task.

Read the installed, manifest-registered technique and verify that the installed entry point exists before writing. Render the placeholder below as the absolute path to that Unity project's `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`, using forward slashes. A guide outside the project must still point to that exact project copy. Moving the project requires reinstalling the guide.

Show the exact destination and entry point before installation. Warn that installing will overwrite the selected existing guide and lose its local contents. Cancel is the default; Enter, Escape, closing either dialog and cancelling the folder picker must cause no write. Validate the source and selected destination, reject linked paths and directories in place of the file, and verify the final bytes. Use only the selected guide path. Never write inside the managed documentation copy or `Docs/GameDesign/`.

Documentation Update and the legacy native-entry manager must not create, overwrite or delete project-root `AGENT.md` or `AGENTS.md`. The separate installer may write AGENTS.md at the project root only when the user selects it explicitly. Existing user guides elsewhere remain user-owned. Old root guides can be replaced at their selected location with this installer; old guides are not silently removed.

Do not keep a standalone AGENTS.md template in the documentation package. The following marked block is the single template. Its version, manifest registry entry, installer validation and tests must change together if the format changes.

## Template

<!-- GEURTS-CODEX-GUIDE-BEGIN version="1.0.0" -->
```markdown
# Geurts Game Forge AI guide

Before planning or changing any part of Geurts Game Forge, read this exact documentation entry point:

`{{GEURTS_DOCUMENTATION_ENTRY_POINT}}`

Continue to the sibling GeurtsTechniqueManifest.md and read every technique selected for the task from that same documentation copy. Treat the selected documentation as the source of truth. Do not substitute remembered rules or another checkout. If the entry point cannot be read, report its exact missing path and ask for the guide to be reinstalled before making changes.

Every update, however small, must bump the owning package or documentation version before publication. Follow the versioning and validation rules in AI_READ_FIRST.md.

Keep project-authored game design separate; access Docs/GameDesign only when the manifest-selected Game Design Documentation Technique and the user's task authorize it.
```
<!-- GEURTS-CODEX-GUIDE-END -->

## Codex discovery reference

[Official Codex instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md) describes AGENTS.md discovery, directory scope and optional fallback filenames.
