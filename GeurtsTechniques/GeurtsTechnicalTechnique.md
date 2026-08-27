# Geurts Technical Technique

**Unity Game Development - AI Instruction Manual**  
**Version:** 0.8.0
**Status:** Draft normative technique
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Required package path:** `GeurtsTechniques/GeurtsTechnicalTechnique.md`

> `GeurtsTechniqueManifest.md` selects this file and version from one validated package commit. This technique defines technical implementation only and does not establish an alternate reading or conflict order.

---

## Purpose

This document instructs AI coding agents, automated development systems, and human developers on how to create, edit, refactor, and maintain Unity game code for Geurts Game Forge.

It exists to ensure:

- Consistent coding style.
- Optimised runtime performance for gameplay and AI logic.
- Clear, machine-readable rules for automated coding.
- Predictable project structure and asset placement.
- Maintainable systems that can scale from solo development to larger teams.

This document is the technical implementation authority. Reusable automation interaction is split into `GeurtsGameForgeAutomationTechnique.md`, but every technical trade-off remains governed by the strict priority order in this document.

Interpret its requirements deterministically. Explicit rules, literal paths, stable terminology, and testable outcomes take precedence over stylistic elegance when the two conflict.

---

## Manifest Boundary

`GeurtsTechniqueManifest.md` is the single resolver for applicable documents, subject ownership, versions, read order, and cross-document conflicts. This technique owns technical implementation and technical trade-offs. When a task also concerns folders, native AI entries, game-design documents, automation behaviour, an integration lifecycle, or the approved `.gitignore` payload, follow the additional subject owner selected by the manifest.

---

## Technical Priority Order

The **Core Principles** are a strict priority order, not an unordered list of preferences.

When a decision requires a trade-off, apply this priority order:

1. **Extendibility** - Code must be modular and easy to expand.
2. **Efficiency** - Avoid unnecessary runtime cost; when efficiency genuinely conflicts with readability, runtime efficiency wins.
3. **Readability** - Code should remain clear to humans and AI agents without imposing avoidable runtime cost.
4. **Updated** - Follow current Unity and AI framework practices where practical.
5. **Documented** - Major components, public APIs, and serialized fields must be clear and documented.

These priorities are not equal. A higher priority wins over a lower priority within this technique's subject. A package change must be selected and versioned through the manifest rather than inferred from a stray copy.

### Multiplayer Exception

For multiplayer systems, **network efficiency overrides all other priorities**.

Cross-document applicability and conflicts defer to the manifest. This technique's priority order applies only to actual technical trade-offs within its assigned subject.

---

## Reusable Framework Compliance Header

GitHub Copilot, Codex, ChatGPT, and any other AI coding assistant must follow the manifest-selected Geurts techniques.

Insert the following comment only when the AI creates or materially edits a reusable Geurts Game Forge framework, library, or tooling component intended to be shared across games:

```csharp
// IMPORTANT: This script must comply with GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsTechnicalTechnique.md and folder placement rules in GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureTechnique.md.
```

Geurts Game Forge Bricks is a positive example of shared framework code. An ordinary game-specific implementation is excluded even when AI-generated; for example, a project-specific 2D map generator does not receive this header merely because an AI created it. AI authorship alone is insufficient. If intended ownership or reuse is unclear, ask before adding the header.

Never modify third-party packages, vendored code, generated code, read-only files, or a format/tooling surface that forbids the header merely to add compliance text.

All code suggestions, refactoring, and automated completions must comply with the requirements for modularity, readability, efficiency, documentation, AI integration, runtime debugging, project structure, and game design awareness described in the Geurts technique documents.

---

## Selectively Adapted Engineering Guidance

### Provenance and authority

Game Forge Intelligence `CODEX_ENGINEERING_RULES.md` v0.28.0 was reviewed as source material for this version. The reusable, non-conflicting guidance below is selectively adapted from that file and consolidated with existing Geurts rules. The source file is not a Geurts authority, and its broad catalogs or independent priority language do not override this technique.

The strict priorities and multiplayer exception defined above remain controlling. The source material did not add or reorder priorities.

### Understand, inspect, and reuse

Treat the user's request as the desired outcome, subject to explicit instructions and the Geurts hierarchy. Before implementation, inspect the relevant project structure, code, dependencies, APIs, assets, conventions, and affected systems. Search for suitable existing functionality and extend it where that best satisfies the strict priorities. Preserve working behaviour unless the requested outcome requires changing it.

When multiple methods are viable, choose a proportionate method by applying the five priorities in their declared order, the multiplayer exception when applicable, the project's actual constraints, and the more specific Geurts authorities. Do not create a separate competing list of engineering priorities or add architecture merely because it is available.

### Implement, integrate, and handle failure

Use clear responsibilities, focused code, minimal harmful duplication, predictable behaviour, useful diagnostics, correct cleanup, and explicit failure handling. Do not present placeholders as complete, invent APIs or package capabilities, expose secrets, silently swallow failures, or leave an avoidable partial state.

Implement the complete requested change when authorized. Update required registration, initialization, configuration, references, assets, tests, and documentation rather than stopping after the primary class or file exists.

### Verify, test, and preserve compatibility

Review the result for compilation and type errors, incorrect references or paths, lifecycle defects, regressions, incomplete integration, unnecessary complexity, and relevant performance or security risks. Test the normal path, meaningful failure paths, edge cases, repeated operation, and surrounding functionality in proportion to the change.

Refactor nearby code only when it prevents defects, removes harmful duplication, or materially improves the requested integration. Do not rewrite unrelated working systems for style. Before changing a public API, serialized field, file format, prefab, or scene contract, identify consumers and preserve compatibility when practical; when a break is necessary, version it and update affected references together.

### Technical evidence for reporting

Generic questioning and report behaviour is owned by the manifest-selected Game Forge Automation Technique. For this technique's subject, provide that owner with concrete technical evidence: changed implementation surfaces, validation performed, compatibility effects, technical assumptions, and unresolved technical limitations.

---

## Boundaries with Other Subjects

Folder placement, automated folder creation, design-document discovery, and missing-design decisions are governed by their manifest-selected techniques. Technical implementation must consume those decisions but must not restate or replace them here.

---

## AI Integration Technique

- **Modular AI Components:** Implement behaviours as separate scripts.
- **Data-Driven Design:** Use ScriptableObjects for AI configuration.
- **Validation:** Validate serialized inputs and safe parameter ranges through project-supported Unity or framework mechanisms. Odin-specific attributes apply only under the conditional Odin section below.
- **Explainability:** Add tooltips and comments for all AI-related fields.
- **Performance:** Optimise AI decision-making for FPS.

AI decision logic should be inspectable, testable, and separated from presentation or unrelated gameplay code where practical.

---

## Coding Standards

### Variables

- Class-level private fields must use an underscore prefix.

```csharp
private float _health;
```

- Method-level variables must not use an underscore prefix.

```csharp
float damageAmount = 10f;
```

- All `[SerializeField]` fields must include a `[Tooltip]`.

```csharp
[SerializeField, Tooltip("The maximum health value this entity can have.")]
private float _maxHealth = 100f;
```

### Enums

Enums must use all caps with underscores.

```csharp
public enum AI_STATE
{
    STATE_IDLE,
    STATE_PATROL,
    STATE_ATTACK
}
```

### UI

Use UI Toolkit for new Geurts UI work. Inspect the existing UI before changing it, and never silently replace or overwrite working user content. When a project already uses another UI system, follow explicit user/project requirements for a scoped integration or migration; do not perform a destructive automatic conversion.

---

## Code Documentation Standards

### Purpose

This section defines standards for documenting C# code to ensure clarity, maintainability, and ease of collaboration.

### Public Methods

Every publicly accessible method must include an XML `/// <summary>` comment.

The summary must clearly and succinctly describe:

- The method's purpose.
- Expected behaviour.
- Important side effects.

Use `/// <param>` and `/// <returns>` tags for parameters and return values.

```csharp
/// <summary>
/// Applies damage to this entity and triggers death handling if health reaches zero.
/// </summary>
/// <param name="damageAmount">The amount of damage to apply.</param>
public void ApplyDamage(float damageAmount)
{
    _health -= damageAmount;
}
```

### Private Methods

Private methods should have a brief comment above the method declaration when their intent or logic is not obvious.

XML documentation is not required for private methods.

Do not comment every line. Focus on intent, usage, and non-obvious logic.

Comments must be updated when behaviour changes.

---

## Odin Inspector Usage

Apply this section only when Odin Inspector is already installed in the project or the current user/project has explicitly selected it. This documentation does not require or authorize installing Odin. Otherwise use the project's selected inspector and serialization equivalents.

- Group related variables with `[BoxGroup]`.
- Organise major sections using `[TabGroup]` and subsections with `[FoldoutGroup]`.
- Use `[Button]` for safe editor actions.
- Apply `[OdinSerialize]` for non-Unity serialisable types.
- Document every group, tab, and button with comments.

Editor buttons should be safe to run and should avoid destructive actions unless clearly labelled and guarded.

---

## Runtime Debugging and Logging

### Objective

Runtime debugging and logging should be comprehensive, filterable, and accessible to developers. Player-facing console, log, command, or overlay access is disabled unless current project GDD or the current user explicitly selects it.

---

## Runtime Console Integration

### Conditional Quantum Console Use

Apply the Quantum Console-specific rules below only when Quantum Console is already installed or explicitly selected by the current user/project. This documentation does not require or authorize installing it. Otherwise use the project's selected logging and command equivalents.

### Accessibility

- The selected console should be available to developers at runtime when appropriate.
- Player access is off by default and requires explicit project GDD or current-user selection.

### Modes

#### Developer Mode

Default filters show all categories:

- AI
- Performance
- Multiplayer
- Errors
- Warnings
- Info

#### Player Mode, When Explicitly Selected

Default filters show essential categories:

- Performance
- Errors
- Bug Reports

When a player-facing console is explicitly selected, its permitted filters and active-filter indicator must follow project GDD and privacy requirements.

---

## Command Rules

### Full Names Only

Commands must use complete words. Do not use abbreviations.

Use:

```text
AI.GetState
Performance.ShowFPS
```

Do not use:

```text
AI.GS
Perf.FPS
```

### Naming Convention

- Use PascalCase.
- Prefix commands with a category.

Examples:

```text
AI.GetState
Performance.ToggleStats
Multiplayer.ShowNetworkStats
```

### Help Commands

Global help command:

```text
Help
```

Example output:

```text
Available Categories:
AI.Help
Performance.Help
Multiplayer.Help
```

Category-specific help command:

```text
AI.Help
```

Example output:

```text
AI Commands:
AI.GetState
AI.SetState
```

### Sensitive Commands

Commands that expose private data must be flagged as `Sensitive`.

Do not expose any command to players by default. When player command access is explicitly selected, project policy decides which non-sensitive commands are visible; sensitive commands remain developer-only.

Sensitive commands appear in help listings only in Developer Mode.

Example:

```text
AI.SetState (Sensitive)
```

### Cheat Commands

Commands that alter the game state must be flagged as `Cheat`.

---

## Logging Standards

Route runtime logs through the project-selected logging system. When Quantum Console is the selected system, use its categories and filters consistently.

Severity colours:

| Severity | Colour |
|---|---|
| Info | White |
| Warning | Yellow |
| Error | Red |

Logs should use clear categories such as:

- AI
- Performance
- Multiplayer
- Errors
- Warnings
- Info

---

## Performance Monitoring

### Objective

Provide a runtime performance overlay only when current project GDD or the current user explicitly selects one. It is off by default for players.

### Requirements

When monitoring is selected and supported, track the relevant available metrics:

- FPS
- RAM usage
- Network ping
- Packet loss
- Upload rate
- Download rate

Each setting should have a display toggle.

The overlay must be disabled for players by default. If explicitly selected, expose it through the project-selected runtime console or equivalent control.

### Overlay Design

- Minimalistic.
- Semi-transparent background.
- Position options:
  - TopLeft
  - TopRight
  - BottomLeft
  - BottomRight

### Example Commands When Quantum Console Is Selected

```text
Performance.ToggleStats
Performance.SetPosition [TopLeft|TopRight|BottomLeft|BottomRight]
```

---

## Performance Trade-Off Guidance Under Efficiency

Apply this guidance only within the five-priority order defined above and the applicable project GDD. It is not a second priority list.

- Prefer frame-rate stability over shorter loading times when the applicable design facts do not require a different player-facing trade-off.
- Prefer runtime performance over editor convenience when gameplay experience is materially affected.
- For multiplayer work, apply the network-efficiency override defined in **Multiplayer Exception** above.

---

## Multiplayer Efficiency Rule

- Use Unity Netcode for GameObjects only when it is already installed or selected as the project's networking framework. Do not introduce or install it merely because this technique mentions it; inspect the project and use the selected networking equivalent.
- Minimise RPC calls.
- Batch updates where possible.
- Sync only the data required for gameplay correctness.
- Do not sacrifice network efficiency for local code convenience.

The multiplayer network-efficiency override applies regardless of the selected networking framework.

---

## Definition of Done for AI-Created or Modified Scripts

A generated or modified Unity C# script is complete only when it:

- Includes the compliance header only when it is a reusable cross-game Geurts Game Forge framework, library, or tooling component under the scope above.
- Uses the correct folder location according to `GeurtsTechniques/GeurtsFolderStructureTechnique.md`.
- Follows naming conventions.
- Includes tooltips for all `[SerializeField]` fields.
- Includes XML summaries for public methods.
- Avoids unnecessary per-frame allocations.
- Avoids expensive logic inside `Update()` unless justified.
- Routes runtime debug output through the project-selected logging or console system where relevant; applies Quantum Console-specific rules only when that package is installed or selected.
- Preserves multiplayer network efficiency where relevant.
- Satisfies every applicable GDD requirement selected by the manifest before changing player-facing behaviour.
