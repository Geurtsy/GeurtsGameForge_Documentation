<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts Game Forge Brick Contract

**Version:** 1.4.0
**Required package path:** `GeurtsTechniques/GeurtsBrickContract.md`

This document owns the shared brick contract and catalogue schema. The manifest continues to own document selection and precedence. Catalogue entries become actionable only when their real installation sources are verified; appearance in this document alone does not publish a release.

## Use existing bricks

Before implementing game or software functionality in a Geurts Unity project, inspect the installed brick inventory and this package's `GeurtsTechniques/GeurtsBrickCatalogue.json`. Use a suitable available Geurts Game Forge brick instead of recreating its functionality. Explain a material incompatibility or missing capability when no suitable brick exists. Request installation as an explicit user action; do not silently install a dependency or treat a planned brick as available.

## Identity and dependencies

- Full display names start with **Geurts Game Forge**. The foundation is **Geurts Game Forge God**, package `com.geurts.gameforge.god`.
- God installs and opens without `com.geurts.gameforge.documentation`; Documentation is an optional companion, not a required package or assembly dependency. Other bricks directly declare God. The documentation companion stays independent of God to avoid a dependency cycle.
- Odin Inspector and Quantum Console are required for God and its dependent Unity bricks. These commercially distributed assets must be imported separately through their licensed distribution. Do not invent registry package identifiers, bundle their assets, or represent them as optional compile dependencies. Reference actual assemblies (`QFSW.QC` and installed Sirenix assemblies) and document setup. The independent Documentation Companion retains its zero-dependency contract; this documentation-only repository and its PowerShell tools are also excluded.
- Unity package manifests use semantic versions for required package dependencies. Git URLs belong in the consuming project's manifest. Install God first from its real Git source, then install the optional Documentation package through Game Forge God's catalogue interface when needed. Never place a Git URL into `package.json.dependencies`.
- God has no Disable action. Removal uses Unity's dependency graph: remove dependent bricks first. God does not recursively delete shared dependencies or embedded source folders.

## Registration and lifecycle

<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
Implement `IBrick` from God, apply `[Brick]` and Unity `[Preserve]`, and preserve the implementation in `link.xml` for stripped players. Supply a parameterless constructor, exact identity/version, required brick identities, and `Start(BrickContext)` / `Stop()`.

God discovers implementations once per Editor/runtime context, rejects duplicate identities, starts in dependency order and stops consumers before providers. Bricks with unsatisfied dependencies stay registered with an explanation. Constructors must not start functionality. `Start` acquires resources; `Stop` releases them and must tolerate a partially failed start. Do not retain unmanaged subscriptions, tasks, scene objects or callbacks after stop. Do not mutate Unity project assets as an automatic side effect of registration.

Use `BrickContext.Provide<T>`, `TryGet<T>`, `Subscribe<T>` and `Publish<T>` for optional cooperation. Contracts belong to God; provider implementations belong to their brick. God automatically withdraws owned capabilities and subscriptions on shutdown. Integrations requiring concrete APIs from two optional packages belong in a separate integration package.

Use `BrickContext.Own(IDisposable)` for scoped check, inspection, network and other registration tokens. Cleanup continues through individual disposal failures. God owns the logging/session contracts; Diagnostics is an optional provider with only God as its brick dependency. Do not add a reverse God-to-Diagnostics dependency. Follow the manifest-selected Diagnostics Technique for that service's application-history and gameplay-session lifetimes.

<!-- GEURTS-SECTION:END -->

Install is explicit. Update retains settings. Disable keeps the package and settings but stops all owned functionality; mandatory consumers wait until their provider resumes. Enable restarts with retained settings. Removal explains that both the package and its own saved settings are deleted and requires confirmation. Cancellation leaves both unchanged. Delete settings only after Unity confirms removal. Reinstallation receives fresh defaults. Settings owned by a removed brick must not be exported into later builds.

Migration, settings conversion, backup, rollback and recovery frameworks are excluded.

## Settings and player boundary

Use God's per-brick JSON settings store. Editor data lives at `ProjectSettings/GeurtsGameForge/<package-id>.json`. Only that identity's file may be deleted by its removal operation. Bricks must not store unrelated game data in this directory. Project defaults are exported into a generated Resources asset during a build; player overrides live below `Application.persistentDataPath/GeurtsGameForge`. Editor package removal does not erase files from previously distributed player installations.

God's package management and Odin dashboard belong in Editor-only assemblies. Runtime contracts, lifecycle and settings cannot reference UnityEditor. God's own Quantum Console logging and developer command work with Diagnostics absent. Console setup is explicit and uses the installed commercial prefab, all-build support, coordinated Unity-log capture/fallback, one persistent EventSystem and Input System focus coordination. With Diagnostics, Player and Developer tabs are freely available in release builds; neither is an authentication boundary. The separate testing override is restricted to Editor/designated internal builds and never bypasses host/server authority. The Diagnostics Technique owns detailed classification, filter and command policy.

## Catalogue schema 1

<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
The JSON contains data only: `schemaVersion`, `packageVersion`, optional `publishedUtc`, and `bricks`. Each entry has `id`, `name`, `description`, HTTPS `website`, `version`, `released`, `developmentOnly`, `sourceKind`, `source`, `minimumUnity`, `maximumUnity`, `requiredTools`, and `dependencies` (`id`, `minimumVersion`). Unity bounds are major/minor versions and describe the declared verified range.

<!-- GEURTS-SECTION:END -->

Only `released: true` entries with a real installable source receive installation actions. Production Git sources identify an immutable commit or released tag and may use Unity's `?path=/Packages/...` form. Registry sources use `id@version` and must exist in the project's configured registry. Controlled local tests may use absolute `file:...tgz` sources only with `sourceKind: tarball` and `developmentOnly: true`. Such archives are local fixtures, never public releases. Do not invent future brick URLs or publish fixtures as real versions.

God loads cached data immediately, combines it with Unity's installed package state, and refreshes online only when Game Forge God opens or Refresh is selected. It does not request the catalogue at every Unity startup. Offline/unavailable/malformed data must retain useful cache contents and display an explanation. Unknown availability must not be labelled up to date. Local folder and embedded packages are development sources. Developer Mode is for Geurts Game Forge package developers only; it uses selected local source folders and exposes controlled test catalogues. Show a fixed Developer Mode banner and a red outline around Game Forge God while enabled. Published versions can be checked without claiming that local files match Git. Turning the mode off only exposes release-update options. A subsequent confirmed Update may overwrite the exact named local package source folder with the verified published package, losing local edits and extra files without a backup; its warning must say this explicitly. Preserve Git metadata and every path outside that package folder. Use Unity package operations to switch the active installation and report overwrite failures honestly. Embedded source folders require a development workflow to move them out of Packages before switching installations.

## Operations and visibility

The user-facing package-management window and menu are named **Game Forge God**. This replaces the former Brick Manager name without changing package identities, stored settings, assembly names or asset GUIDs.

All existing and future brick Editor UI must follow the manifest-selected [Editor UI Theme Technique](GeurtsEditorUIThemeTechnique.md), including Game Forge God, Build Forge, Diagnostics, Documentation, settings and custom inspector presentation. The mandatory dark sci-fi palette, green accents, shared `ForgeEditorTheme` implementation, visible disabled explanations, semantic severity and visual review apply from a new brick's first Editor screen. The independent companion uses a generated, parity-checked theme copy and remains free of a God dependency. The theme does not change runtime/player UI, lifecycle, permission or settings contracts.

Each card shows identity, description, website, installed/available and lifecycle status, installed/available versions, dependencies, source and compatibility information. Show appropriate Install, Check for Updates, Update, Enable/Disable, Remove, Open Website and Retry actions. Shared actions include Refresh Catalogue, Install All, Check All for Updates and confirmed Update All, including God.

Game Forge God exposes Documentation package installation and package updates separately from **Update Geurts Game Forge Documentation**, which installs or replaces the actual project-local documentation content. Display the companion package version separately from the documentation content state; package installation or package update alone does not install or update the content. The content action delegates to the installed companion's public Editor integration and retains its exact cancel-default, four-target confirmation. Package Update All must not silently acquire or replace documentation content. Missing or incompatible optional companion APIs leave God usable and show an actionable install or update explanation; they must not cause a compile dependency or a duplicate documentation updater in God. Build Forge operations that need companion-owned helpers explain the missing capability and provide the same installation or update route.

Version conflicts or unverified compatibility produce a clear Continue/Cancel warning, not an automatic compatibility block. Missing required tools or an operation Unity cannot perform must be reported accurately. Never claim that package installation proves compilation succeeded.

<!-- GEURTS-SECTION:BEGIN FORGE-DEVELOPMENT-ONLY -->
Use Unity Package Manager APIs, serialize operations, prevent conflicting clicks, preserve intent and useful outcomes across script reloads, and verify the actual resolved identity/version/commit. Self-update uses the same real Unity operation. Self-removal holds assembly reload only until the confirmed result allows deleting God's exact settings file, then releases the reload. It removes no dependencies automatically. The operation record remains under `Library/GeurtsGameForge/operations.json` after the manager removes itself.

<!-- GEURTS-SECTION:END -->

Show current package, stage, clear success/cancellation/failure and Retry directly in the Odin manager. Use progress percentages only when measurable. `Client.Add` has no percentage, so use an activity indicator and explanatory stage text. Quantum Console output supplements the manager.

The outlined forge image is an activity indicator. While package operations, catalogue refresh, update checks, or companion documentation work are active, animate a repeating smoke puff and gentle vertical bounce; stop at a still resting frame when work completes or fails. A GIF asset and its supported Editor playback frames may supply the same animation. Keep truthful stage text visible, stop repaint work when idle or the window closes, and release animation resources on teardown. The animation never implies a measurable percentage or substitutes for a reported outcome.
