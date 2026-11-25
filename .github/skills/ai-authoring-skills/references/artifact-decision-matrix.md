# Artifact Decision Matrix (Knowledge Centre vs. Agent)

Single canonical reference for choosing the right AI customization artifact. All `ai-authoring-*` skills link here instead of maintaining duplicate tables.

## Architecture Boundary

- **Skills = Domain Knowledge Centres + Black-Box Scripts**: *What* to know and deterministic scripts to run, loaded on demand.
- **Agents = Workflows, Personas & Orchestration**: *Who* executes, *in what order*, and under what tool/model policy in an isolated context window.
- **Commands = Thin Entrypoints**: Parameterized `/name` shortcuts that invoke an agent or load a skill.
- **Rules & Hooks = Always-On Guardrails**: Rules (`AGENTS.md`, `*.instructions.md`) guide probabilistically via prompt context; Hooks (`hooks.json`, plugins) enforce deterministically via lifecycle code.
- **Prompt Patterns = Cognitive Craft**: System prompt structure, 5-layer stack, orchestration topologies, scheduled maintenance prompts, and Mermaid.js diagrams.

## Choosing the Right Artifact

| Requirement | Artifact | Typical Location / Mechanism | Authoring Skill |
|---|---|---|---|
| Domain knowledge hub, API/tool references, timeless pitfalls, and deterministic black-box scripts | **Skill** | `.github/skills/<name>/SKILL.md`, `references/`, `scripts/` | `ai-authoring-skills` |
| Workflows, role personas, multi-step orchestration, isolated context window & least-privilege tools | **Agent / Subagent** | `.github/agents/*.agent.md`, `.agents/agents/*.md`, `.claude/agents/*.md` | `ai-authoring-agents` |
| Thin user-invoked parameterized shortcut (`/name`) | **Command** | `.github/prompts/*.prompt.md`, `.claude/commands/*.md`, `.agents/workflows/*.md` | `ai-authoring-commands` |
| Always-on or path-scoped conventions & safety invariants | **Rule** | `AGENTS.md`, `*.instructions.md`, `.mdc`, `.claude/rules/` | `ai-authoring-rules` |
| Deterministic lifecycle gate, command blocker, auto-formatter, or dynamic rule simulator | **Hook** | `hooks.json`, `.github/hooks/*.json`, `.opencode/plugins/*.ts` | `ai-authoring-hooks` |
| Prompt body craft, 5-layer cognitive stack, scheduled maintenance prompts, Mermaid.js flows | **Prompt Pattern** | Inline body / `references/maintenance-agents.md` | `ai-authoring-prompts` |

## Placement & Boundary Rules

1. **Skills own knowledge and scripts; Agents own workflows and orchestration.** Do not embed multi-agent delegation JSON or step-by-step SOP checklists in `SKILL.md` when an Agent or Command belongs there.
2. **Keep Commands thin.** A command should bind parameters and route to an Agent or Skill rather than duplicating domain knowledge or long SOPs.
3. **Rules guide; Hooks enforce.** Use Rules for coding conventions and judgment defaults; pair them with Hooks whenever a hard binary gate (security, formatting, verification) is mandatory.
4. **Never accumulate war stories in `SKILL.md`.** Distill timeless API or tool gotchas into `references/*.md` and turn repeated multi-call shell sequences into `scripts/*`.
