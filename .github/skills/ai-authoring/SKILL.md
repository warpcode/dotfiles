---
name: ai-authoring
description: >
  Unified Knowledge Centre for authoring, auditing, and validating AI artifacts
  across Claude, Copilot, Cursor, Antigravity, Codex, OpenCode, and Hermes:
  skills (SKILL.md, scripts, evals), agents and subagents, slash commands and
  workflows, persistent rules (AGENTS.md, CLAUDE.md, .mdc, .instructions.md),
  lifecycle hooks (PreToolUse, PostToolUse), system prompts, and scheduled
  maintenance agents (Bolt, Sentinel, janitor agents). Use when creating,
  updating, converting, or validating any AI customization artifact.
---

# AI Authoring Knowledge Centre

Unified reference hub and validator suite for authoring AI customization artifacts across platforms.

## Architecture: Knowledge Centre vs. Agent

Skills are **Domain Knowledge Centres + Black-Box Scripts**; Agents own **Workflows, Personas & Orchestration**. See `@references/artifact-decision-matrix.md` for the canonical decision matrix across all artifact types:

| Artifact | Owns | Authoring Guide |
|---|---|---|
| **Skill** (`SKILL.md`, `references/`, `scripts/`) | Domain knowledge, timeless gotchas, routing hubs, deterministic scripts | `@references/skills.md` |
| **Agent / Subagent** (`*.agent.md`, `*.md`) | Role personas, step ordering, multi-step orchestration, isolated contexts | `@references/agents.md` |
| **Command** (`/name`, `*.prompt.md`) | Thin user-invoked entrypoints & parameter binding | `@references/commands.md` |
| **Rule** (`AGENTS.md`, `*.instructions.md`, `.mdc`) | Persistent always-on, path-scoped, or model-decision guardrails | `@references/rules.md` |
| **Hook** (`hooks.json`, `.github/hooks/`, plugins) | Deterministic lifecycle gates, blockers, formatters, rule simulation | `@references/hooks.md` |
| **Prompt Pattern** (5-layer stack, topologies) | Prompt body craft, Mermaid.js diagrams, scheduled maintenance prompts | `@references/prompts.md` |

### Hard Prohibitions for `SKILL.md`

- **No subagent JSON orchestration or delegation protocols in `SKILL.md`** — multi-agent orchestration belongs in `.github/agents/*.agent.md` or `.github/prompts/*.prompt.md`.
- **No dated war stories or chronological post-mortems in `SKILL.md`** — distill timeless gotchas into `@references/` and turn repeated commands into `@scripts/`.
- **No shell loops, `jq` chains, or inline `python3 -c` in `SKILL.md`** — put deterministic logic behind `--help` in `@scripts/`.

## Domain Routing Hub

| Need | Reference | Key Templates |
|---|---|---|
| Choosing Skill vs. Agent vs. Command vs. Rule vs. Hook | `@references/artifact-decision-matrix.md` | `templates/knowledge-centre.md` |
| Creating or auditing a Skill package | `@references/skills.md` | `templates/knowledge-centre.md`, `templates/skills/` |
| Creating or auditing an Agent / Subagent | `@references/agents.md` | `templates/agents/` |
| Creating or auditing a Slash Command / Workflow | `@references/commands.md` | `templates/commands/` |
| Creating or transpiling Rules / `AGENTS.md` | `@references/rules.md` | `templates/rules/` |
| Creating or debugging Lifecycle Hooks | `@references/hooks.md` | `templates/hooks/` |
| Designing system prompts, topologies, or Mermaid diagrams | `@references/prompts.md` | `templates/prompts/` |
| Scheduled repo-maintenance prompts (`Bolt`, `Sentinel`, etc.) | `@references/prompts/maintenance-agents.md` | `references/prompts/maintenance-agents/protocol.md` |

## Black-Box Validators & Scripts

Run scripts relative to `<skill-dir>/scripts/` (pass `--self-test` or `--help` as needed):

| Script | Purpose |
|---|---|
| `@scripts/validate.py` | Validate skill packages (`SKILL.md`, frontmatter, paths, script compile, tests, scriptability) |
| `@scripts/audit_bundled_scripts.py` | Audit empirical bundled script usage across recent sessions |
| `@scripts/validate_agents.py` | Validate cross-platform subagent definitions |
| `@scripts/validate_antigravity.py` | Strict validator for Google Antigravity subagent frontmatter & tools |
| `@scripts/validate_commands.py` | Validate slash commands, frontmatter, placeholders, and shell pre-exec safety |
| `@scripts/validate_rules.py` | Validate rules/instructions syntax, dialects, globs, and token budgets |
| `@scripts/validate_hooks.py` | Validate lifecycle hook configs, matchers, events, and handler executables |
