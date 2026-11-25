# Authoring Prompts, Personas & Maintenance Agents

Universal guidelines, architectural design patterns, composite archetypes, and standalone scheduled maintenance agent prompts. See [Artifact Decision Matrix](artifact-decision-matrix.md) to choose the container artifact holding the prompt.

## Modern Prompt Principles (Goal Scoping vs Micromanagement)

1. **Define "Done", Not the Method**: Specify what a successful output looks like and the constraints it must satisfy.
2. **Eliminate Artificial Scaffolding**: Do NOT add manual "think step by step" instructions on reasoning models.
3. **Use Explicit Markdown Sections**: Organize with standard headers (`## Context`, `## Rules`, `## Task`, `## Output Contract`).
4. **Zero-Shot by Default**: Start zero-shot with crisp constraints; add few-shot examples only for fragile syntax or non-standard DSLs.

See `prompts/modern-prompt-principles.md`.

## Full-Stack Pattern Composition (5-Layer Stack)

| Layer | Component | Core Responsibility | Canonical Patterns |
|---|---|---|---|
| **Layer 1** | **Identity & Persona** | Operational role, privileges, and tone | `[P1.1]` Specialist, `[P1.2]` Auditor, `[P1.3]` Supervisor, `[P1.4]` Operator |
| **Layer 2** | **Structural Frame** | Section separation (`## Context`, `## Rules`) | `[P2.1]` Markdown Frame, `[P2.2]` Outline-First |
| **Layer 3** | **Boundaries & Guardrails** | Strict MUST / MUST NOT constraints | `[P3.1]` Negative Constraints, `[P3.2]` Clarify Gate, `[P3.3]` RFC 2119 |
| **Layer 4** | **Reasoning & State** | Grounding, citations, and persistence | `[P4.1]` Cite-or-Abstain, `[P4.2]` Confidence, `[P4.3]` State Tracker |
| **Layer 5** | **Output Contracts** | Machine-verifiable return schemas | `[P5.1]` Diff Contract, `[P5.2]` Rubric, `[P5.3]` Exemplars, `[P5.4]` Log |

### Ready-to-Use Archetypes & Pattern Library

| Goal / Archetype | Starter Template |
|---|---|
| **Surgical Code Implementer** | `templates/prompts/archetype-surgical-implementer.md` |
| **Fact-Based Technical Auditor** | `templates/prompts/archetype-fact-based-auditor.md` |
| **Autonomous Task Supervisor** | `templates/prompts/archetype-autonomous-supervisor.md` |
| **Deterministic SOP Runner** | `templates/prompts/archetype-sop-task-runner.md` |
| **Full Pattern Catalog (19 cards)** | `templates/prompts/pattern-library.md` |

Assembly matrix and precedence rules: `prompts/pattern-catalog-and-matrices.md`.

## Orchestration Topologies & Maintenance Agents

- **Topologies** (Supervisor/Workers, Sequential Pipeline, Router/Classifier, Evaluator-Optimizer, Fan-Out/Fan-In, Human Checkpoint): see `prompts/orchestration-and-topologies.md`.
- **Scheduled & Unattended Maintenance Agents** (`Bolt`, `Sentinel`, `Docs Auditor`, `Test Smith`, `Workflow Warden`, `Ratchet`, `Flake Hunter`, `Release Scribe`): see `prompts/maintenance-agents.md`, shared protocol `prompts/maintenance-agents/protocol.md`, and agent blocks in `prompts/maintenance-agents/agents/*.md`.

## Visual Diagrams (Mandatory Mermaid.js Standard)

NEVER use ASCII art, box-drawing characters, or text arrows. ALWAYS use Mermaid.js (`flowchart TD`/`LR`, `sequenceDiagram`, `stateDiagram-v2`, `erDiagram`) and quote labels with special characters. See `prompts/visual-diagrams.md`.

## Directives & Checklist

- Use RFC 2119 (`MUST` / `MUST NOT` / `SHOULD`), pre-emptive negative constraints, and the Pointer Pattern (`file:///path/to/file`).
- Verify: verifiable "done" criteria, no artificial thinking scaffolding, zero ASCII art, explicit negative constraints, <500 lines.
