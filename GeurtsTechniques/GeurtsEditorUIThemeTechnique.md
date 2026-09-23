<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts Editor UI Theme Technique

**Version:** 1.0.0
**Status:** Normative mandatory standard
**Primary audience:** Geurts Game Forge brick and Editor-tool maintainers
**Secondary audience:** AI coding agents and human developers
**Required package path:** `GeurtsTechniques/GeurtsEditorUIThemeTechnique.md`

## Scope and authority

The dark sci-fi interface with green accents established by Forge Diagnostics is the mandatory visual standard for **all existing and future Geurts Game Forge bricks and Forge-owned Editor tools**. Apply it to Forge-owned windows, dashboards, setup pages, settings pages, custom inspector presentation, cards, navigation, status messages and controls. A new brick is not exempt because it has no previous visual design. An existing brick is not exempt because it uses IMGUI, Odin Inspector or a different earlier palette.

`GeurtsTechniqueManifest.md` selects this technique and owns applicability, reading order, versions and cross-document conflict resolution. This technique owns Forge Editor visual presentation and its conformance requirements. The Technical Technique continues to own implementation priorities, the UI Toolkit baseline and required Odin usage. The Brick Contract owns dependencies, lifecycle, settings and package operations. Diagnostics owns diagnostic meaning and runtime console behavior. The Documentation Companion Technique owns the independent companion's dependency and project-access boundaries.

This standard is **Editor-only**. It does not select or redesign player-facing game UI, runtime Diagnostics or Quantum Console presentation, game art, scenes, game design documents, third-party inspectors or Unity's global skin. Do not access `Docs/GameDesign/` or change game design to apply this theme. Forge-owned Editor controls embedded in an existing Inspector remain in scope; preserve the behavior and readability of their host and neighboring controls.

## Required visual tokens

Use these shared tokens consistently. A brick must not substitute its own brand palette or silently derive unrelated colors from the current Unity skin.

| Token | Exact color | Use |
|---|---|---|
| Background | `#0A1012` | Main Forge content surface. |
| Panel | `#121C1E` | Section cards and grouped content. |
| Raised | `#172425` | Controls and raised or emphasized surfaces. |
| Border | `#2B433F` | Quiet section boundaries and separators. |
| Accent | `#6EF29D` | Selected navigation, primary emphasis and interactive focus. |
| Text | `#DEECE7` | Main labels, values and body text. |
| Muted | `#8FA8A1` | Secondary descriptions and supporting metadata. |
| Info | `#FFFFFF` | Informational severity. |
| Warning | `#FFE66D` | Warning severity and caution. |
| Error | `#FF6B6B` | Error severity, destructive emphasis and Developer Mode warning. |

Dark layered panels, restrained borders and green accents provide the sci-fi character. Keep meaningful content dominant. Do not add scanline overlays, glow, tiny decorative labels, excessive all-capital text, flashing effects or invented telemetry that obstruct reading or imply nonexistent functionality. Derived hover, pressed, disabled and selected treatments must come from the shared theme and retain readable labels.

Severity colors remain semantic: Info is white, Warning is yellow and Error is red. Green branding must never turn an error, warning or Developer Mode indicator green. Topic colors and other data-defined colors remain independently meaningful where the owning feature requires them; use the shared surfaces around them and retain readable text.

## Layout and interaction

- Give each window a clear title and short purpose. Group related work into consistently padded section cards with descriptive headings, and place the most relevant action beside its context.
- Use a deliberate hierarchy of title, section heading, body and supporting text. Use readable Editor fonts and the shared typography definitions; decorative sci-fi fonts must not replace ordinary controls or diagnostic content. Long values, paths and messages must wrap, scroll or expose their complete value.
- Use shared spacing and control dimensions. Align related labels and buttons; keep card padding, section gaps and navigation consistent across bricks. Do not create one-off spacing systems for each window.
- Show selected navigation, hover, pressed and keyboard-focus states distinctly. Keyboard focus must remain visible on enabled controls and must not be communicated through a color change alone. Preserve normal keyboard activation, text selection, copy, tab navigation and host interactions.
- Use a visible label or message for every material state. Pair severity or status color with text such as **Warning**, **Failed**, **Unavailable**, **Running** or **Complete**; use an icon or shape as a supplementary cue when useful. Color alone is insufficient.
- Explain unavailable actions visibly with the actual reason and an actionable next step. Tooltips may repeat or expand that explanation, but a tooltip alone is insufficient for an important disabled action. Preserve the same eligibility rule for the enabled state and its explanation so they cannot contradict each other.
- Distinguish destructive actions from ordinary actions using precise labels and error emphasis. Preserve the existing subject owner's confirmation, cancellation and scope rules; styling must not add, remove or bypass authorization.
- Keep all labels and input content readable against the surfaces actually drawn. Restore temporary GUI colors, styles and state after drawing so a Forge panel cannot change unrelated Unity or third-party UI.

## Truthful status and animation

Display actual operation state, current stage, useful results and failure details. An unknown or unchecked condition must remain **Unknown**, **Not checked** or **Unavailable**, as appropriate; theme colors must not imply success. A queued or ongoing package operation must not look complete before the actual operation and required verification have succeeded.

Show a numeric percentage only when the operation supplies measurable progress. A Unity package request without a percentage uses an activity indicator and stage text. Decorative animation, including the Game Forge God furnace, may indicate activity or identity but must never be presented as a measured progress value, proof of successful setup or evidence of a running service. Keep animation unobtrusive and release its repaint/update work when the owning UI is no longer active.

**Developer Mode must retain a fixed, explicitly labelled warning and a red outline around Game Forge God while enabled.** The green base theme does not replace or weaken this warning. It remains separate from Diagnostics' Player/Developer tabs and any restricted testing override.

<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
## Shared implementation and dependency boundary

God's Editor assembly owns the canonical public **`ForgeEditorTheme`** API and **`ForgeEditorTheme.uss`** stylesheet. All bricks that depend on God must reuse those shared tokens, styles and components for their Forge-owned Editor presentation. Extend that shared implementation when a reusable state or control is missing instead of copying a palette, recreating a private theme class or adding a second shared theme package. Keep Editor-only dependencies out of runtime assemblies and player builds.

The canonical files are `Editor/ForgeEditorTheme.cs` and `Editor/ForgeEditorTheme.uss` in the God package; the API namespace is `Geurts.GameForge.God.Editor`. Use a cached `ForgeEditorTheme` instance's `Scope()` around existing IMGUI/Odin drawing and static `ForgeEditorTheme.ApplyToolkit(root)` for a Forge-owned UI Toolkit root. God 0.9.0 introduces this public shared theme; a dependent package that adopts it must declare the corresponding compatible God minimum instead of compiling against an older release without the API. Verify actual release availability through the catalogue before installation.

God's public `ForgeThemedEditor` is the shared `OdinEditor` base for Forge-owned custom inspectors. It applies the theme while preserving Odin's property tree, serialized configuration and validation. Retain base drawing and cleanup when extending it. Theme instances belong to the window or inspector, are initialized within an active IMGUI draw context, and are disposed when their owner disables or closes.

The independent optional Documentation Companion must remain usable without God and must not gain a God dependency for styling. It retains its separately installed licensed Odin Inspector and Quantum Console assemblies; the generated theme adds no new dependency. It consumes a **generator-produced, namespaced copy** of the same canonical theme source and stylesheet. The generator and parity validator belong to source-maintenance tooling; they are not a Unity-open or Documentation Update action. Record the generation provenance, preserve required namespace/asset-path adaptation and reject source or stylesheet drift with the parity validator. Do not maintain its visual tokens manually or execute copied documentation tools to regenerate it in a user's project.

God's `Tools~/SyncEditorTheme.ps1` generates the companion copy; its `-Check` mode validates source and stylesheet parity. Run it from the owning source-maintenance workflow with the intended companion checkout explicitly selected. The namespaced generated C# source and identical USS are companion implementation assets; no Unity implementation files belong in this documentation repository.

Keep the theme's IMGUI/Odin and UI Toolkit representations consistent. Use the shared USS and supported UI Toolkit controls for new custom Editor UI, as required by the Technical Technique. Preserve meaningful Odin configuration, grouping, validation, serialized fields and existing inspector workflows. Existing Odin or IMGUI windows may adopt the shared theme without a forced framework conversion; do not replace working Odin configuration with bespoke controls merely to restyle it.

Theme assets, cached styles and generated textures must have deliberate ownership and cleanup. Avoid allocating textures, reading assets or rebuilding the complete style set on every repaint. Do not leak callbacks across window closure, assembly reload or play-mode transitions. Scope styling to Forge-owned visual roots and restore temporary IMGUI state even when drawing fails.

## Required validation before publication

An Editor UI change is conforming only when the following evidence is recorded for the affected surfaces:

1. The shared API/stylesheet is reused; canonical tokens match this technique. For a canonical theme change, regenerate the companion copy and pass its parity validator before publication.
2. Compile and run relevant focused Editor checks in the exact Unity version required by the Technical Technique. No runtime assembly may acquire a theme or `UnityEditor` dependency.
3. Inspect the actual UI at its normal size and a narrow docked size, and check floating/docked behavior, scrolling, long labels and expanded messages. Controls and explanations must remain reachable without clipping or overlapping content.
4. Check readability with Unity's light and dark host skins and at normal and high display scaling. The Forge content remains dark in both skins; neighboring native/Odin controls remain legible. Record unavailable visual environments instead of claiming they passed.
5. Exercise the affected enabled, disabled, selected, hover, keyboard-focus, busy, success, warning and failure states. Verify the visible disabled reason and next step, semantic severity labels and Developer Mode warning wherever applicable.
6. Confirm the real actions, settings persistence, Undo/serialized authoring behavior, cancellation, operation reporting and existing animation still work where touched. A visual change must not fabricate results, hide a failure, change package lifecycle or overwrite an open scene.
7. Preserve representative visual evidence and report any unchecked surface honestly. Source review or a passing compilation is not evidence that the rendered layout passed visual inspection.

The owning package version must increase before publication, and all affected package metadata, runtime-reported versions, changelogs and catalogue data must remain consistent under the entry point's versioning rules. Changes to this standard also advance the technique version and documentation package version.

## New-brick and review gate

Every new brick with Editor UI must select this technique through the manifest, use the shared implementation from its first Editor screen, and include theme conformance in its implementation review. Every modification to existing Forge-owned Editor UI must preserve or establish conformance for the affected surface. A visual review must reject local palette forks, color-only status, unexplained important disabled controls, unreadable host integration and falsely reported progress.

This documentation standard is mandatory for participating maintainers and agents; it is not a claim of universal automatic enforcement. Native AI routing can direct supported tools to the entry point, but a tool that ignores those routes or the selected techniques may still produce nonconforming code. Validators, focused behavior checks and actual visual review provide evidence within their tested scope; they do not prove that every future agent or every rendered state will comply automatically.
<!-- GEURTS-SECTION:END -->
