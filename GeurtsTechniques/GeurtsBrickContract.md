# Geurts Game Forge Brick Contract

**Version:** 1.1.0
**Required package path:** `GeurtsTechniques/GeurtsBrickContract.md`

This document owns the shared brick contract and catalogue schema. The manifest continues to own document selection and precedence. Catalogue entries become actionable only when their real installation sources are verified; appearance in this document alone does not publish a release.

## Use existing bricks

Before implementing game or software functionality in a Geurts Unity project, inspect the installed brick inventory and this package's `GeurtsTechniques/GeurtsBrickCatalogue.json`. Use a suitable available Geurts Game Forge brick instead of recreating its functionality. Explain a material incompatibility or missing capability when no suitable brick exists. Request installation as an explicit user action; do not silently install a dependency or treat a planned brick as available.

## Identity and dependencies

- Full display names start with **Geurts Game Forge**. The foundation is **Geurts Game Forge God**, package `com.geurts.gameforge.god`.
- God directly declares `com.geurts.gameforge.documentation`. Other bricks directly declare God. The documentation companion stays independent of God to avoid a dependency cycle.
- The current user requirement for all Geurts Unity packages is Odin Inspector and Quantum Console. These commercially distributed assets must be imported separately through their licensed distribution. Do not invent registry package identifiers, bundle their assets, or represent them as optional compile dependencies. Reference actual assemblies (`QFSW.QC` and installed Sirenix assemblies) and document setup. This supersedes older optional-tool and zero-tool assumptions for the Unity companion; it does not add these dependencies to this documentation-only repository or its PowerShell tools.
- Unity package manifests use semantic versions for package dependencies. Git URLs belong in the consuming project's manifest; install the Documentation package explicitly from its real Git source before God. A project-level Git/local dependency can satisfy God's declared dependency. Never place a Git URL into `package.json.dependencies`.
- God has no Disable action. Removal uses Unity's dependency graph: remove dependent bricks first. God does not recursively delete shared dependencies or embedded source folders.

## Registration and lifecycle

Implement `IBrick` from God, apply `[Brick]` and Unity `[Preserve]`, and preserve the implementation in `link.xml` for stripped players. Supply a parameterless constructor, exact identity/version, required brick identities, and `Start(BrickContext)` / `Stop()`.

God discovers implementations once per Editor/runtime context, rejects duplicate identities, starts in dependency order and stops consumers before providers. Bricks with unsatisfied dependencies stay registered with an explanation. Constructors must not start functionality. `Start` acquires resources; `Stop` releases them and must tolerate a partially failed start. Do not retain unmanaged subscriptions, tasks, scene objects or callbacks after stop. Do not mutate Unity project assets as an automatic side effect of registration.

Use `BrickContext.Provide<T>`, `TryGet<T>`, `Subscribe<T>` and `Publish<T>` for optional cooperation. Contracts belong to God; provider implementations belong to their brick. God automatically withdraws owned capabilities and subscriptions on shutdown. Integrations requiring concrete APIs from two optional packages belong in a separate integration package.

Install is explicit. Update retains settings. Disable keeps the package and settings but stops all owned functionality; mandatory consumers wait until their provider resumes. Enable restarts with retained settings. Removal explains that both the package and its own saved settings are deleted and requires confirmation. Cancellation leaves both unchanged. Delete settings only after Unity confirms removal. Reinstallation receives fresh defaults. Settings owned by a removed brick must not be exported into later builds.

Migration, settings conversion, backup, rollback and recovery frameworks are excluded.

## Settings and player boundary

Use God's per-brick JSON settings store. Editor data lives at `ProjectSettings/GeurtsGameForge/<package-id>.json`. Only that identity's file may be deleted by its removal operation. Bricks must not store unrelated game data in this directory. Project defaults are exported into a generated Resources asset during a build; player overrides live below `Application.persistentDataPath/GeurtsGameForge`. Editor package removal does not erase files from previously distributed player installations.

God's package management and Odin dashboard belong in Editor-only assemblies. Runtime contracts, lifecycle and settings cannot reference UnityEditor. God's own Quantum Console logging and developer command work with Diagnostics absent. Developer Console setup is explicit and uses the installed commercial prefab, developer-only support, Unity-log interception, an EventSystem and Input System focus coordination. Player-facing console access remains off.

## Catalogue schema 1

The JSON contains data only: `schemaVersion`, `packageVersion`, optional `publishedUtc`, and `bricks`. Each entry has `id`, `name`, `description`, HTTPS `website`, `version`, `released`, `developmentOnly`, `sourceKind`, `source`, `minimumUnity`, `maximumUnity`, `requiredTools`, and `dependencies` (`id`, `minimumVersion`). Unity bounds are major/minor versions and describe the declared verified range.

Only `released: true` entries with a real installable source receive installation actions. Production Git sources identify an immutable commit or released tag and may use Unity's `?path=/Packages/...` form. Registry sources use `id@version` and must exist in the project's configured registry. Controlled local tests may use absolute `file:...tgz` sources only with `sourceKind: tarball` and `developmentOnly: true`. Such archives are local fixtures, never public releases. Do not invent future brick URLs or publish fixtures as real versions.

God loads cached data immediately, combines it with Unity's installed package state, and refreshes online only when the Brick Manager opens or Refresh is selected. It does not request the catalogue at every Unity startup. Offline/unavailable/malformed data must retain useful cache contents and display an explanation. Unknown availability must not be labelled up to date. Local folder and embedded packages are development sources. Developer Mode is for Geurts Game Forge package developers only; it uses selected local source folders and exposes controlled test catalogues. Show a fixed Developer Mode banner and a red outline around the Brick Manager while enabled. Published versions can be checked without claiming that local files match Git. Turning the mode off only exposes release-update options. A subsequent confirmed Update may overwrite the exact named local package source folder with the verified published package, losing local edits and extra files without a backup; its warning must say this explicitly. Preserve Git metadata and every path outside that package folder. Use Unity package operations to switch the active installation and report overwrite failures honestly. Embedded source folders require a development workflow to move them out of Packages before switching installations.

## Operations and visibility

Each card shows identity, description, website, installed/available and lifecycle status, installed/available versions, dependencies, source and compatibility information. Show appropriate Install, Check for Updates, Update, Enable/Disable, Remove, Open Website and Retry actions. Shared actions include Refresh Catalogue, Install All, Check All for Updates and confirmed Update All, including God.

Version conflicts or unverified compatibility produce a clear Continue/Cancel warning, not an automatic compatibility block. Missing required tools or an operation Unity cannot perform must be reported accurately. Never claim that package installation proves compilation succeeded.

Use Unity Package Manager APIs, serialize operations, prevent conflicting clicks, preserve intent and useful outcomes across script reloads, and verify the actual resolved identity/version/commit. Self-update uses the same real Unity operation. Self-removal holds assembly reload only until the confirmed result allows deleting God's exact settings file, then releases the reload. It removes no dependencies automatically. The operation record remains under `Library/GeurtsGameForge/operations.json` after the manager removes itself.

Show current package, stage, clear success/cancellation/failure and Retry directly in the Odin manager. Use progress percentages only when measurable. `Client.Add` has no percentage, so use an activity indicator and explanatory stage text. Quantum Console output supplements the manager.
