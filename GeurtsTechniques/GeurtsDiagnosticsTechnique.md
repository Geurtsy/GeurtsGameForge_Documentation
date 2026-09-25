<!-- GEURTS-AUDIENCE: AI-READ -->
# Geurts Diagnostics Technique

**Version:** 0.3.0
**Required package path:** `GeurtsTechniques/GeurtsDiagnosticsTechnique.md`
**Implementation baseline:** God 0.10.1 and Diagnostics 0.6.0, published at the immutable commits in the catalogue; verify the actual installed package. Diagnostics' minimum God dependency remains 0.9.0. The shared Editor theme is governed by the manifest-selected Editor UI Theme Technique.

The manifest selects this technique for Diagnostics integration, logging, console policy, runtime metrics, health checks, inspection and gameplay cheat-session hooks. Technical trade-offs remain owned by the Technical Technique; the Brick Contract owns general lifecycle/settings and the catalogue. This file does not authorize installing packages or replacing project design facts.

## Ownership and availability

Diagnostics is a standalone package, `com.geurts.gameforge.diagnostics`, whose only **brick** dependency is `com.geurts.gameforge.god`. God does not depend on Diagnostics. Licensed Odin Inspector and Quantum Console are required external libraries, not extra brick dependencies. Never redistribute their assets or replace the real Quantum Console with another command UI.

God owns shared contracts (`ForgeLog`, `IForgeLogCapture`, `ForgeDiagnostics`, `IForgeGameplaySession`, `IForgeNetworkContext`), lifecycle, settings and setup facts. Diagnostics owns capture, presentation, temporary history and its Windows sampler. A game/system owns its actual health checks, inspected values, gameplay state, scene transitions, saves and network authority. Diagnostics coordinates those providers; it does not invent their state or install a networking/save framework.

Only God starts/stops Diagnostics. Runtime uses one persistent service and the configured Quantum Console; Editor uses the same God-owned service with an Odin window. No scene manager may independently initialize a second logger. Startup failure must unwind acquired subscriptions/providers. Stop must drain all accepted records, including more than one normal per-frame batch, then release its callbacks and UI. Application history is closed only after services stop.

Command-policy ownership is registered separately from logging capture. While no policy owner is active, God's fallback gate permits only its exact verified read-only inventory command; disabling Diagnostics must not expose unchecked vendor mutations. A log-only provider must not silently disable that fallback gate.

## Shared logging contract

Project-controlled code registers topics before its first log and emits through `ForgeLog.Info`, `Warning`, `Error` or `Exception` in God. Multiple topics describe one record; case-insensitive duplicate registrations share one identity. A topic is game-defined, not a fixed package enumeration. Registration makes a topic available to filters before any record uses it.

```csharp
ForgeLog.RegisterTopics("Inventory", "Rewards");
ForgeLog.Info("Reward granted.", FORGE_AUDIENCE.PLAYER, item, "Inventory", "Rewards");
```

The same facade works when Diagnostics is physically absent, disabled, stopped, incompatible or not started. Preserve Unity output exactly once; external captures must not re-emit the original message to Unity. Capture external Unity messages with the supported threaded callback and retain exception/source details and supplied Unity context. A logger that does not flow through Unity needs a supported explicit adapter to `ForgeLog.CaptureExternal`; report any source lacking such an adapter. Do not edit vendor/generated code to achieve capture where callbacks suffice.

Capture is thread-safe; Unity object inspection and serialization occur on the main thread. Explicitly Player-classified logs may enter Player history. Unclassified Unity, third-party and direct Quantum Console output is Developer-classified, including ordinary logs emitted during a command. Never infer Player audience from a selected tab, a currently running task or an arbitrary call stack.

## Runtime console and filters

The full Diagnostics console is reachable with tilde/backquote in **all supported builds**, including release. Player and Developer tabs are freely switchable; this tab is not an authentication boundary. It is separate from God's package-development mode and from the restricted testing override. Do not expose secrets merely because a record or command is Developer-classified.

Use the existing Quantum Console canvas, input, parser, execution, history suggestions and lifecycle. Embed Diagnostics controls and its paged/virtualized log presentation into that console. The scoped extension of QC's existing uGUI is intentional; it is not a new competing runtime UI framework. Keep exactly one console and one Input System EventSystem across scene changes. Opening the console suspends configured gameplay action maps but does not pause simulation. Closing it restores only the input maps that this integration suspended.

Present the runtime controls as visibly separate groups with readable labels:

- **Channel** contains only **Player** and **Developer**, the audience tabs that filter record visibility and available classified commands. Changing channels never reclassifies a record or command. Identify the current channel through a visible selected treatment as well as green emphasis.
- **Window controls** contains **Fullscreen** / **Restore**, separate from audience selection. These change only the existing console's layout, not the application's display mode or command permissions.
- **Views** contains **Logs**, **Filters**, **Health**, **Inspect**, **Metrics**, **History** and **Session**. **Filters** is the visible label for the former Topics view; **Metrics** is the visible label for the former Overlay view. These navigate diagnostic content within the current channel; selecting a view never changes audience classification or grants command permission. Session retains the existing gameplay status, cheat controls and simulation-pause policy.
- **Logs** contains the log actions **Pause logs** / **Resume logs**, **Older**, **Newer**, **Latest**, **Help** and **Select text** / **Exit selection**. Keep these distinct from channel, window and view navigation, and make their current state and applicability clear. Log display pause is never labelled or presented as gameplay pause. Help uses the existing classified command route.

Use dark layered surfaces and green accents for the Diagnostics runtime controls, including selected, hover and keyboard-focus states. Scope the treatment to the existing Quantum Console integration and retain readable labels, command input, log text, scrolling and navigation when the console is resized. Preserve Info white, Warning yellow, Error red and each topic's assigned color; green branding is not a replacement for severity or classification. This runtime presentation belongs to Diagnostics and does not extend the Editor-only theme standard into game-authored UI or introduce an Editor dependency into runtime code.

Fullscreen fits the existing console container within its canvas, reserving 52 canvas units above it for Quantum Console's native zoom tab and 8-unit side and bottom margins, bounded by the available display. Native zoom remains active while fullscreen; native dragging and drag-resizing are temporarily suspended. Restore reinstates the previous window geometry and prior interaction states, shrinking or moving the window only when needed to keep it reachable after the display becomes smaller. The native diagonal resize grip remains a drag-resize control in windowed mode, not a fullscreen button.

While the console is open fullscreen, draw the existing metrics overlay behind it so the overlay cannot obscure Channel or Restore controls. Return the overlay to the foreground when the console closes or restores, without changing its saved size or position.

At narrow sizes, allow the grouped controls to wrap, maintain a 480-unit logical minimum width bounded by the available canvas, and grow the runtime console height when the header would leave too little history space. Re-evaluate this fit when native zoom changes so labels, command input and a usable log area remain reachable within the current canvas bounds. Do not edit licensed vendor assets, vendor resize settings or saved Diagnostics preferences to achieve the fit. Presentation and layout changes never alter command permissions or gameplay authority.

Player shows only explicitly Player records. Developer shows both audiences. Each tab retains independent topic selections and severity overrides. The match rule is:

1. Enforce audience classification.
2. Always show an allowed command response, independent of topics or display pause.
3. Show a record matching an enabled severity override **or any selected topic**.

First launch selects Player with no selected topics. Info override is off; Warning and Error overrides are on. Persist the last selected tab and both sets of filters. An override never reveals a Developer record in Player.

Each topic receives a readable, distinct-as-practical random colour on first registration. Persist its assigned colour and any user customization across restarts; Reset restores its assigned colour. Both tabs share topic colours. Display timestamp, coloured topic tags, severity and message; information is white, warnings yellow and errors red. Source, context and exception details expand on demand.

Log display pause freezes incoming ordinary records in the view while capture continues. Responses and the resume control remain available. Gameplay pause is a different, cheat-gated action and must not be confused with display pause.

Allowed responses return runtime presentation to latest Logs even from another view or older history; hidden Developer responses do not navigate Player presentation. Ending a gameplay session restores only the simulation pause owned by Diagnostics, so a subsequent clean session is not stranded paused.

## Console text selection and clipboard

Both the runtime Quantum Console integration and the Forge Diagnostics Editor console expose an explicit **Select text** / **Exit selection** toggle for Logs. Select text creates a stable, read-only text snapshot of the current filtered, loaded log page. Allow native pointer selection and Shift-based keyboard selection across record boundaries, **Ctrl+A** for that snapshot and **Ctrl+C** to copy the selected text. Do not reread the complete application history or imply that selecting the loaded page selects every retained record. Never silently truncate the snapshot.

The runtime TextMeshPro selection control rejects a snapshot that would exceed **12,000 rendered visual lines**. Keep a persistent, actionable explanation that tells the user to reduce the **History** loaded limit or collapse expanded records, and recheck the capacity when the selection control's width changes. This is a runtime renderer capacity guard, not an Editor selection limit or a limit on retained history.

Copy the displayed log content as plain text. Preserve literal message characters, including text that resembles rich-text markup; presentation-only color tags must not become clipboard content. Include source, context and exception details only for records whose details were expanded when the snapshot was created. The snapshot follows the existing audience, topic/severity, grouping and page selection; it never reveals hidden Developer content in Player.

Selection freezes only its own text snapshot. Incoming ordinary records continue to be captured and retained without rewriting the text under an active selection. Entering or leaving selection must not change **Pause logs** / **Resume logs** state or gameplay pause. An allowed command response exits selection before the usual latest-Logs presentation so responses remain visible; hidden Developer responses do not navigate Player.

Exit selection and clear the displayed snapshot when the channel, view, page, filters or display settings change, when the service stops or is replaced, and when the owning console/window closes. A Developer snapshot must not remain visible or selectable after switching to Player. Release selection-owned state and focus through normal UI lifecycle cleanup; never change the user's system clipboard merely because selection ends or its scope changes.

The snapshot is read-only: typing, cut or paste cannot alter output or stored records. At runtime, **Ctrl+V** remains available in Quantum Console's existing editable command input; pasting inserts text and never executes a command automatically. In the Editor, copied text can be pasted into an existing editable field or another application through the normal clipboard. Do not add a parallel Editor command executor or bypass Quantum Console's existing parser, audience classification, cheat checks or host/server authority to support clipboard use. Keyboard shortcuts act on the focused control.

## Application-session history

Retain every captured original occurrence for the entire application launch, across scenes, explicit gameplay sessions and Diagnostics disable/enable. Keep record bodies in a uniquely owned temporary on-disk file, not an unbounded list of live objects. Close/remove that exact temporary file at application-context exit. Do not recover, merge or export earlier launches as part of this feature.

The default **loaded** limit is 1,000 original records. Users can choose a positive count or unlimited (`-1`) in runtime controls/commands or Editor preferences. Unlimited must display an explicit memory/performance warning. Changing the loaded limit never truncates retained history. Scrolling at section boundaries and Older/Newer/Latest controls fetch history sections without retaining every page in memory.

Consecutive grouping changes presentation only. Every original occurrence remains stored and individually available when grouping is disabled. Records separated in original sequence must not become a repeat group merely because filtering hides the intervening record.

Sparse audience/topic/severity block indices must avoid repeatedly deserializing the full launch history when a filter finds no matches. Validate long-running, mostly nonmatching traffic as well as unfiltered pages.

## Commands and extensibility

Define actual QC commands with full names and descriptions and add God's `[ForgeCommand(FORGE_AUDIENCE.PLAYER)]` or `[ForgeCommand(FORGE_AUDIENCE.DEVELOPER)]`. `Cheat = true` is an independent flag. It denotes bypass/tuning/test mutations that require an enabled gameplay cheat session; ordinary explicitly designed player actions are not automatically cheats.

The classification must govern real QC help, autocomplete and execution. A manually typed Developer command in Player is denied with an instruction to switch tabs. Unclassified commands are denied until their owner supplies an explicit adapter/classification. Do not rely on hiding suggestions alone. Help must explain permitted signatures, parameters and cheat requirements.

`Help` must render each command as a separate block. The command name is the only content on its first line. Put its permitted signatures, audience classification, cheat requirement and description on subsequent indented lines. Never place two command names on one line or append metadata or descriptive text to the command-name line.

The current adapter uses QC preprocessors, a one-use invocation ticket and the real QC processor. This retains the original audience through parsing/permission failures and output. It emits an explicit response and does not expose the internal dispatcher as a callable user command. Direct `QuantumConsoleProcessor.InvokeCommand` is a console presentation route while Diagnostics runs; integrations needing a programmatic return value use `DiagnosticsCommandRouter.InvokeForResult` within the optional Diagnostics integration boundary.

Nested expression commands are rejected at QC's normalized grammar boundary, including parenthesized/recursive argument forms, so arguments cannot change policy after an outer command is checked. Invoke classified commands separately. Supported read-only QC utilities are allowlisted by real assembly/type/method/signature, never alias alone; getter approval must not approve a setter. Generic exec/reflection/file/network/scene-mutation utilities remain excluded unless deliberately integrated.

Ordinary synchronous methods/properties/fields can carry policy. Delegate fields, async-void, native task/action command return forms and ambiguous object-return commands require explicit method/response adapters. Deferred owners capture invocation audience, send completion through thread-safe `ForgeLog.CommandResponse`, and recheck session/host permission **immediately before** any delayed mutation. Ordinary asynchronous logs remain Developer unless the caller explicitly classifies them. Do not infer task results from uncorrelated QC log callbacks.

## Health and live read-only inspection

Register `ForgeHealthCheck` and `ForgeInspection` through `ForgeDiagnostics`, retaining their disposal tokens with the owning brick's `BrickContext.Own`. Registration must not execute a check. Inspectors are read-only delegates; a failing getter must not break the console. Player sees only Player inspection registrations; Developer sees both. Editor and runtime consume the same registrations.

Health checks run only on explicit request, overall or by owner, and show actual stages, results and actionable next steps. No fabricated percentages. God owns dependency/startup/settings/bootstrap/build-scene/console-setup facts. Domain checks live in the relevant game/system brick, not in Diagnostics.

Deep checks are explicitly requested. Every gameplay-changing check is excluded from ordinary health requests and requires cheat/session/host permission immediately before running. Read-only deep checks need not start a cheat session. A check must report actual tested behavior, not unconditional success. Outside Play Mode, the Odin window can run relevant project checks without modifying scenes; runtime-only checks report that they require Play Mode.

## Gameplay sessions, zones and saves

Application lifetime and gameplay-session lifetime are different. The game explicitly calls `Begin` and `End`; scene loading, closing a console or disabling Diagnostics never clears cheat provenance.

The game's session policy is `FORBIDDEN`, `REQUIRED` or `PLAYER_CHOICE`. Cheats can be enabled only when policy and authority permit. Once enabled, the flag is sticky until that gameplay session ends. There is no ordinary disable/undo operation that makes the same run clean again.

Before preparing a destination, call the pure `TryEnter(destination, noCheats, out reason)` preflight. A cancelled/failed transition must leave the current zone's policy unchanged. After successful preparation, call `CommitEntry` to revalidate and commit policy before enabling destination gameplay. A cheating session cannot ordinarily enter no-cheats content; end it and start a separate clean session instead.

The save owner includes `CaptureSave()` flags in its real save payload and uses `Restore` when starting a new session from that save. A cheat-enabled save remains cheat-enabled. The owner remains responsible for save integrity, authoritative multiplayer validation and actual state disposal on `End`. Ending a temporary/demo session permits a new clean run; it does not retroactively clean that session's save.

Testing override is compiled only for Unity Editor or designated `GGF_INTERNAL_TESTS` builds. It is visibly labelled, distinct from the freely available Developer tab, and may allow restricted-content testing. It must **never** bypass multiplayer host/server authority. A Development Build flag alone does not grant it. Multiplayer permission and current server ping come from the game's real `IForgeNetworkContext`; lack of a provider must not be treated as host authority.

## Six independent overlay metrics

Expose exactly these initial toggles, independently and persistently, in runtime controls/commands and Editor preferences:

| Metric | Meaning |
|---|---|
| FPS | Frames per real elapsed second. |
| Game RAM | Current process working set. |
| PC RAM | Physical memory used / physical memory total. |
| GPU utilization | Actual Windows PC-wide busiest physical GPU engine utilization. Not a frame-time estimate. |
| Graphics memory | Actual PC adapter dedicated and shared usage, labelled separately. Dedicated memory is not universally discrete VRAM. |
| Ping | Current registered server's measured latency; **0 ms when disconnected**. |

Do not add frame-time or error-count overlays. Sample native Windows metrics away from Unity's main thread, bound shutdown waiting, keep independent healthy metrics available when another counter fails, and label unavailable/stale data truthfully. Never substitute made-up utilization or a simulated ping for a missing provider. The sample network provider used by tests is evidence of adapter behavior, not a real network connection.

The performance overlay automatically fits its current enabled metric content and refits when that content or its canvas dimensions change. It exposes a visible drag strip for runtime positioning and a resize grip for manual sizing. Beginning a manual resize disables automatic sizing; manual size and top-right-relative position persist through the shared brick settings. Clamp both dimensions and position so the controls remain reachable inside the current canvas. Runtime controls and Odin preferences expose the auto-fit setting, and runtime controls provide one reset action that restores automatic sizing and the default top-right position.

The runtime **Metrics** view exposes a **Background transparency** slider with a visible percentage: **0% is solid** and **100% is clear**. The default is **12%**, preserving the earlier background alpha of **0.88**. Change only the performance overlay background; metric text, the drag strip and the resize grip retain their existing opacity and remain usable. Expose the same persisted preference in the Editor's Odin settings and use the shared brick settings store across sessions. The layout reset continues to reset only sizing and position; it must not reset background transparency.

## Validation and migration

The package's importable Basic Diagnostics Setup sample demonstrates actual game-owned coins, inspection, health checks, three session policies, failed/committed zone transitions and saved cheat provenance. It does not automatically start gameplay or install a framework. Legacy `GeurtsDiagnosticsManager`, `GeurtsLogger` and sink APIs are compatibility surfaces only; the old manager cannot start/stop the shared service. Legacy settings assets retain serialized data but no longer control active behavior.

Validate exact-once logging/fallback, exceptions/context, worker bursts larger than a frame budget, malformed preferences, repeated enable/disable, domain-reload modes, real QC help/autocomplete/denials, Player responses while paused, scene/EventSystem/input persistence, large filtered history, save/zone/authority hooks and actual Windows counters. Exercise release builds and relevant scripting backends, recording unavailable modules honestly. Compilation alone is not behavioral, visual or player validation.

For runtime control presentation, inspect Channel, Window controls, Views and Logs actions at normal and reduced console sizes. Verify visible selection and focus, readable green accents and semantic log colors, access to the command input, audience/filter persistence, pause/resume and history navigation. Exercise Fullscreen/Restore, native zoom, windowed dragging and the diagonal resize grip, display shrink while fullscreen, minimum width and automatic height growth, and a large metrics overlay that returns to the foreground without covering fullscreen controls. Changing presentation must preserve actual help, autocomplete, execution denial and cheat/host checks.

For overlay transparency, verify 0%, 12% and 100%, the visible percentage and persisted runtime/Odin preference, unchanged text and handle opacity, and layout reset preserving the chosen transparency. Confirm that moving and resizing the overlay still work at both slider endpoints.

For text selection, verify multi-record pointer/Shift selection, Ctrl+A/C, exact plain text including literal markup, expanded-only details, a stable snapshot while new logs arrive, unchanged log-pause state, allowed responses, and snapshot removal after every scope/lifecycle change. Specifically switch Developer to Player during selection and confirm no Developer snapshot remains. Verify that typing/cut/paste cannot mutate output and that Ctrl+V in the existing command input never executes on its own. Check the runtime 12,000-rendered-line capacity boundary, the persistent recovery explanation, and a width change that makes a previously valid snapshot exceed capacity; there must be no silent truncation or corresponding Editor limit. Exercise the runtime and Editor clipboard paths separately; source review and synthetic input tests must not be reported as verified native clipboard interaction.

No diagnostic report-export feature is part of this scope. User-selected clipboard copy of the loaded log page is not a retained-history export or a file-writing feature. Build/test evidence belongs to development tooling, not a runtime export command.
