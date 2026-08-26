<!-- GEURTS-MANAGED-BEGIN id="agents-body" version="0.7.0" sha256="4226bad26176eea2b0187cb4d7d1e3439255840aeb1ce6f9f26e09a01081a0dc" -->
# Geurts Game Forge - Codex Entry

**Version:** 0.7.0
**Canonical documentation repository:** `https://github.com/Geurtsy/GeurtsGameForge_Documentation.git`  
**Canonical branch:** `main`

At AI-session initialization, run the lightweight documentation check:

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools/BootstrapGeurtsInstructions.ps1 -Mode Check`

If an update is available, notify the user and follow package policy or the manual **Update Geurts Game Forge Documentation** action. Do not contact GitHub again for every prompt.

Before creating, modifying, moving, renaming, or deleting project files:

1. Confirm a valid synchronized copy exists at `GeurtsGameForgeDocumentation/`.
2. Read `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`.
3. Follow its reading order, authority rules, task routing, path boundary, and pre-code lock.
4. At session initialization, read `Docs/GameDesign/GameDesignManifest.md` once when it exists; re-read it only when its timestamp, hash, or version changes.
5. Load complete project-specific design documents only when relevant to a player-facing task.

If required synchronization fails, do not modify project code unless an explicit fallback policy permits the last valid copy. Project-specific GDD files remain under `Docs/GameDesign/`; synchronized techniques remain under `GeurtsGameForgeDocumentation/GeurtsTechniques/`.

`GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsAIResponseControlTechnique_V1.1.md` is chat-only unless the current manifest explicitly reclassifies it.
<!-- GEURTS-MANAGED-END id="agents-body" -->
