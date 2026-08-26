# Geurts Technical Technique

**Unity Game Development - AI Instruction Manual**  
**Version:** 0.7.0
**Status:** Draft master technique  
**Primary audience:** AI coding agents and automated development systems
**Secondary audience:** Human developers
**Canonical path:** `GeurtsTechniques/GeurtsTechnicalTechnique.md`

> **Version Selection Notice:** If multiple copies of this document are found during an AI agent build process, use the copy with the highest semantic version number. If two copies share the same version number, prefer the copy in the canonical path shown above.

---

## Purpose

This document instructs AI coding agents, automated development systems, and human developers on how to create, edit, refactor, and maintain Unity game code for Geurts Game Forge.

It exists to ensure:

- Consistent coding style.
- Optimised runtime performance for gameplay and AI logic.
- Clear, machine-readable rules for automated coding.
- Predictable project structure and asset placement.
- Maintainable systems that can scale from solo development to larger teams.

This document is currently the temporary master technical technique. Later, it may be split into specialised documents.

Interpret its requirements deterministically. Explicit rules, literal paths, stable terminology, and testable outcomes take precedence over stylistic elegance when the two conflict.

---

## Related Technique Documents

The following documents are part of the Geurts Game Forge technique set:

| Document | Purpose |
|---|---|
| `GeurtsTechniques/GeurtsTechnicalTechnique.md` | Main technical, coding, AI, debugging, performance, and priority standards. |
| `GeurtsTechniques/GeurtsFolderStructureTechnique.md` | Folder layout, asset placement, project structure, and naming rules. |
| `GeurtsTechniques/GeurtsFolderStructureDefinition.json` | Machine-readable authority for automated folder creation. |
| `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` | Native AI agent instruction setup for GitHub Copilot, Codex, and future coding agents. |
| `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` | How AI agents and developers should locate and use project game design documentation when a task depends on design intent. |
| `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` | Reusable contract for documentation synchronization, folder generation, native entries, and GDD automation. |
| `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` | Project-specific index read at initialization when it exists. |

AI systems and human developers must follow the latest valid versions of the relevant documents when generating, modifying, moving, or organising files.

When creating new files, scripts, scenes, assets, tools, or documentation, placement must follow `GeurtsTechniques/GeurtsFolderStructureTechnique.md`. Automation that creates folders must also follow `GeurtsTechniques/GeurtsFolderStructureDefinition.json`.

At session or project initialization, read `<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md` once when it exists and retain a version/hash/timestamp fingerprint. Re-read it when the fingerprint changes. When a task affects gameplay design, player-facing behaviour, balance, progression, narrative, levels, UX, or content intent, load every relevant current design document listed by that manifest before implementation. Do not load unrelated full design documents for a purely technical task.

---

## Authority and Conflict Resolution

The **Core Principles** are a strict priority order, not an unordered list of preferences.

When a decision requires a trade-off, apply this priority order:

1. **Extendibility** - Code must be modular and easy to expand.
2. **Efficiency** - Avoid unnecessary runtime cost; when efficiency genuinely conflicts with readability, runtime efficiency wins.
3. **Readability** - Code should remain clear to humans and AI agents without imposing avoidable runtime cost.
4. **Updated** - Follow current Unity and AI framework practices where practical.
5. **Documented** - Major components, public APIs, and serialized fields must be clear and documented.

These priorities are not equal. A higher priority wins over a lower priority unless a newer technique version explicitly says otherwise.

### Multiplayer Exception

For multiplayer systems, **network efficiency overrides all other priorities**.

### Document Authority

- Project-specific Geurts Game Forge rules override general Unity habits or AI defaults.
- `GeurtsTechniques/GeurtsTechnicalTechnique.md` is the authority for technical implementation.
- `GeurtsTechniques/GeurtsFolderStructureTechnique.md` is the authority for folder structure and asset placement.
- `GeurtsTechniques/GeurtsFolderStructureDefinition.json` is the authority for automated folder creation.
- `GeurtsTechniques/GeurtsAIAgentSetupTechnique.md` is the authority for AI agent instruction files.
- `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md` is the authority for locating and using design documentation.
- `GeurtsTechniques/GeurtsGameForgeIntelligenceIntegrationContract.md` is the reusable authority for compatible integration behaviour.
- Native AI instruction files such as `.github/copilot-instructions.md` and `AGENTS.md` are entry points that point agents back to the latest Geurts technique documents.
- If ambiguity remains, AI systems must state their assumption before generating or modifying code.

---

## GitHub Copilot, Codex, and AI Compliance

GitHub Copilot, Codex, ChatGPT, and any other AI coding assistant must follow the standards specified in the latest valid Geurts technique documents.

The native AI instruction files for a target project are safely managed by:

```text
Tools/ManageGeurtsAgentInstructions.ps1
```

The managed updater creates missing entries, refreshes Geurts-owned sections when their template version changes, preserves user-owned content, backs up legacy files before replacement, and reports created, updated, preserved, skipped, and conflicted results:

```text
ProjectRoot/
├── AGENTS.md
└── .github/
    ├── copilot-instructions.md
    └── instructions/
        ├── geurts-unity.instructions.md
        └── geurts-game-design.instructions.md
```

These files must remain short and must point agents back to the Geurts technique documents instead of duplicating every rule.

Every native entry must route through `GeurtsGameForgeDocumentation/AI_READ_FIRST.md`. A required documentation update or synchronization failure blocks project modification unless an explicit fallback policy permits use of the last valid copy.

AI systems must insert the following comment at the beginning of every Unity C# script they generate or modify:

```csharp
// IMPORTANT: This script must comply with GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsTechnicalTechnique.md and folder placement rules in GeurtsGameForgeDocumentation/GeurtsTechniques/GeurtsFolderStructureTechnique.md.
```

All code suggestions, refactoring, and automated completions must comply with the requirements for modularity, readability, efficiency, documentation, AI integration, runtime debugging, project structure, and game design awareness described in the Geurts technique documents.

In case of ambiguity or conflict, the rules in `GeurtsTechniques/GeurtsTechnicalTechnique.md` take precedence unless the matter is specifically about folder structure, AI agent setup, or game design document discovery.

Copilot, Codex, and other AI instruction files should be reviewed regularly to ensure ongoing compliance with the latest technique documents.

---

## Core Principles

The following principles are listed in strict priority order:

1. **Extendibility** - Code must be modular and easy to expand.
2. **Efficiency** - Prioritise runtime performance and avoid unnecessary runtime cost.
3. **Readability** - Use descriptive names, clear structure, and comments when they do not impose avoidable runtime cost.
4. **Updated** - Follow current Unity and AI framework practices where practical.
5. **Documented** - Every major component must include appropriate comments and tooltips.

When these principles conflict, the lower-numbered principle wins.

Exception: For multiplayer systems, network efficiency overrides all other priorities.

---

## Folder Structure and Asset Placement

Folder placement is explained by `GeurtsTechniques/GeurtsFolderStructureTechnique.md`. Automated folder creation is governed by `GeurtsTechniques/GeurtsFolderStructureDefinition.json`. A contradiction between them is a validation failure; automation must stop rather than guess.

AI systems must check the folder structure technique before creating:

- Scripts.
- Scenes.
- Prefabs.
- ScriptableObjects.
- Art assets.
- Audio assets.
- UI assets.
- Tools.
- Generated files.
- Documentation.
- External or third-party content.

The project folder structure can be generated from the definition using:

```text
Tools/CreateGeurtsFolderStructure.ps1
```

The tool may create only definition entries that permit automation creation. It must not delete project content, including when a path disappears from a later definition.

---

## Game Design Documentation Awareness

Technical implementation must respect current game design intent when the task depends on player-facing behaviour.

AI agents and human developers should consult game design documentation when working on:

- Mechanics.
- Player abilities.
- Enemy behaviour.
- AI behaviour that affects gameplay feel.
- Balance and progression.
- Quests, objectives, or narrative content.
- Level design.
- UI and UX flow.
- Accessibility decisions.
- Player-facing debug, cheat, or tuning tools.

The target Unity project’s default design documentation location is:

```text
<ProjectRoot>/Docs/GameDesign/
```

The target Unity project’s design index, when present, is:

```text
<ProjectRoot>/Docs/GameDesign/GameDesignManifest.md
```

Use `Tools/UpdateGameDesignManifest.ps1` for deterministic manifest maintenance under `GeurtsTechniques/GeurtsGameDesignDocumentationTechnique.md`. If a task requires design intent and no relevant design document exists, the AI agent must state the assumption it is making before implementation. It must not invent mechanics, narrative, balance values, progression, characters, or other game-design facts.


Do not create vague folders such as:

- `Misc/`
- `New Folder/`
- `Temp/`
- mixed folders containing unrelated scripts, prefabs, textures, and data.

When unsure, place first-party Unity content under the closest matching domain inside:

```text
Assets/_Project/
```

---

## AI Integration Technique

- **Modular AI Components:** Implement behaviours as separate scripts.
- **Data-Driven Design:** Use ScriptableObjects for AI configuration.
- **Validation:** Apply validation attributes such as `[ValidateInput]` where safe parameter ranges are required.
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

Use Unity's new UI system unless a specific technical reason requires otherwise.

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

- Group related variables with `[BoxGroup]`.
- Organise major sections using `[TabGroup]` and subsections with `[FoldoutGroup]`.
- Use `[Button]` for safe editor actions.
- Apply `[OdinSerialize]` for non-Unity serialisable types.
- Document every group, tab, and button with comments.

Editor buttons should be safe to run and should avoid destructive actions unless clearly labelled and guarded.

---

## Testing and Validation

### Objective

Runtime debugging and logging must be comprehensive, filterable, and accessible to both AI systems and players, with clear rules for sensitive commands.

---

## Quantum Console Integration

### Mandatory Use

Quantum Console must be integrated for all runtime debugging and command execution.

### Accessibility

- The console must be available at runtime for developers and players.
- Players can access all logs by default.

### Modes

#### Developer Mode

Default filters show all categories:

- AI
- Performance
- Multiplayer
- Errors
- Warnings
- Info

#### Player Mode

Default filters show essential categories:

- Performance
- Errors
- Bug Reports

Players can toggle filters freely. The UI must indicate active filters.

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

Most commands are not sensitive. Commands that function as cheats should usually remain visible to players unless they expose private data.

Sensitive commands appear in help listings only in Developer Mode.

Example:

```text
AI.SetState (Sensitive)
```

### Cheat Commands

Commands that alter the game state must be flagged as `Cheat`.

---

## Logging Standards

All logs must be routed through Quantum Console.

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

Provide players with real-time performance metrics in a small GUI overlay.

### Requirements

Always track:

- FPS
- RAM usage
- Network ping
- Packet loss
- Upload rate
- Download rate

Each setting should have a display toggle.

The GUI overlay must be enabled by default and toggleable through Quantum Console.

### Overlay Design

- Minimalistic.
- Semi-transparent background.
- Position options:
  - TopLeft
  - TopRight
  - BottomLeft
  - BottomRight

### Quantum Console Commands

```text
Performance.ToggleStats
Performance.SetPosition [TopLeft|TopRight|BottomLeft|BottomRight]
```

---

## Performance Priorities

- FPS is more important than loading times.
- Runtime performance is preferred over editor convenience when gameplay experience is affected.
- For multiplayer, network efficiency is first priority.

---

## Multiplayer Efficiency Rule

- Always use Unity Netcode for GameObjects unless the project explicitly changes networking framework.
- Minimise RPC calls.
- Batch updates where possible.
- Sync only the data required for gameplay correctness.
- Do not sacrifice network efficiency for local code convenience.

---

## Definition of Done for AI-Generated Scripts

A generated or modified Unity C# script is complete only when it:

- Includes the required compliance comment at the top.
- Uses the correct folder location according to `GeurtsTechniques/GeurtsFolderStructureTechnique.md`.
- Follows naming conventions.
- Includes tooltips for all `[SerializeField]` fields.
- Includes XML summaries for public methods.
- Avoids unnecessary per-frame allocations.
- Avoids expensive logic inside `Update()` unless justified.
- Routes runtime debug output through Quantum Console where relevant.
- Preserves multiplayer network efficiency where relevant.
- Loaded every relevant project-specific design document before changing player-facing behaviour, or explicitly stated the missing-design assumption.
- Used a valid local documentation copy and recorded the synchronized commit/version when the host integration supplies it.
