# Authoring Subagent Definitions

Create, configure, and maintain custom agent and subagent definitions across Claude Code, GitHub Copilot/VS Code, OpenCode, Google Antigravity, ChatGPT/Codex, Cursor, and Hermes Agent.

A subagent definition is a single markdown or YAML file combining structured frontmatter (metadata, tool policies, model routing, isolation) with a self-contained system prompt body.

## Choosing the Right Artifact

Agents own **role personas, multi-step workflows, orchestration, isolated context windows, and least-privilege tool policies**; domain knowledge and black-box scripts belong in Skills. See [Artifact Decision Matrix](artifact-decision-matrix.md).

**House Delegation Heuristic**: High-noise exploration (broad codebase grepping, large logs, multi-file surveys) belongs in a subagent so the coordinator's context remains clean and focused.

## Platform Matrix

| Platform | Workspace Path | Global / User Path | Filename Pattern | Official Documentation |
|---|---|---|---|---|
| Claude Code | `.claude/agents/` | `~/.claude/agents/` | `<name>.md` | [Claude Code Subagents](https://code.claude.com/docs/en/sub-agents) |
| GitHub Copilot / VS Code | `.github/agents/` | `~/.copilot/agents/` | `<name>.agent.md` | [VS Code Custom Agents](https://code.visualstudio.com/docs/agent-customization/custom-agents) |
| OpenCode | `.opencode/agents/` | `~/.config/opencode/agents/` | `<name>.md` | [OpenCode Agents](https://opencode.ai/docs/agents/) |
| Google Antigravity | `.agents/agents/` | `~/.gemini/config/agents/` | `<name>.md` or `<name>/agent.md` | [Antigravity Subagents](https://antigravity.google/docs/subagents/) |
| ChatGPT / Codex | `.codex/agents/` | `~/.codex/config.toml` | `<name>.md` | [ChatGPT Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) |
| Cursor | `.cursor/agents/` | `~/.cursor/agents/` | `<name>.md` | [Cursor Custom Agents](https://cursor.com/docs/agent-customization) |
| Hermes Agent | `.hermes/agents/` | `~/.hermes/agents/` | `<name>.yaml` | [Hermes Agent Blueprints](https://hermes-agent.nousresearch.com/docs/developer-guide/creating-agents) |

## Portable Concepts, Platform Schemas

Keep the agent's purpose portable, but author and validate each platform's configuration independently. Frontmatter fields, file locations, tool names, and permission models do not transfer verbatim across platforms.

> **Warning**: Google Antigravity can hang on an unmapped or misspelled tool name. Use only documented keys and exact tool names from `agents/platforms/antigravity.md`.

### Platform Reference Guides

- `agents/platforms/claude-code.md`: `tools`, `disallowedTools`, `effort`, `maxTurns`, `isolation: worktree`, `background`.
- `agents/platforms/copilot-vscode.md`: `name`, `description`, fallback `model` arrays, `tools` allowlists, `user-invocable`, `handoffs`.
- `agents/platforms/opencode.md`: `mode`, `model`, `temperature`, `permission` object (`allow`/`ask`/`deny`), `steps`, `hidden`.
- `agents/platforms/antigravity.md`: `name`, `description`, `tools`, `mainAgent`, `subagent`, `model` (`inherit`/`flash`/`pro`), `commandExecutionPolicy`, `mcpServers`, `skills`/`plugins`.
- `agents/platforms/codex.md`: `.codex/config.toml` `[agents]` section, `AGENTS.md` subagent routing.
- `agents/platforms/cursor.md`: `paths` scoping, custom agent models.
- `agents/platforms/hermes.md`: `.hermes/agents/*.yaml` blueprint schema.

## Role Archetypes & Templates

| Role Archetype | Primary Focus | Recommended Permissions / Model | Template |
|---|---|---|---|
| **Specialist Implementer** | Domain code generation (frontend, backend, DB) | `read: allow, edit: allow, bash: safe`<br>Flagship model (`sonnet`, `pro`, `gpt-4o`) | `templates/agents/specialist-implementer.md` |
| **Auditor / Reviewer** | Read-only security, quality, diff review | `read: allow, edit: deny, bash: deny`<br>Strict temp (0.1) | `templates/agents/auditor-reviewer.md` |
| **Researcher / Explorer** | Broad codebase grepping, web doc searches | `read: allow, edit: deny, websearch: allow`<br>Fast cheap flash model (`gemini-3.5-flash`, `haiku`) | `templates/agents/researcher-explorer.md` |
| **Maintenance Janitor** | Tech debt cleanup, dead code purge | `read: allow, edit: allow, bash: test/lint`<br>Worktree isolation | `templates/agents/maintenance-janitor.md` |
| **Coordinator Orchestrator** | Subagent dispatching, multi-stage supervisor | `Agent` tool / `invoke_subagent`<br>Top-tier reasoning model | `templates/agents/coordinator-orchestrator.md` |

See `agents/best-practices.md` and `agents/code-review.md` for architectural guidelines and reference examples.

## System Prompt Body & Cognitive Architecture

Subagent prompt bodies should assemble the **5-Layer Cognitive Stack** from [Authoring Prompts](prompts.md):
1. **Layer 1: Identity & Persona** (`[P1.1]`–`[P1.4]`)
2. **Layer 2: Structural Frame** (`## Context`, `## Rules`, `## Task`, `## Output Contract`)
3. **Layer 3: Operational Boundaries** (`[P3.1]` Negative Constraints, `[P3.2]` Clarify Gate)
4. **Layer 4: Reasoning & State Scaffolding** (`[P4.1]` Cite-or-Abstain, `[P4.3]` State Tracker)
5. **Layer 5: Output Contracts** (`[P5.1]`–`[P5.4]`)

## House Rules & Guardrails

1. **Model Routing for Cheap Exploration**: Subagents performing high-noise grep/read tasks must NOT run on the master model. Pin an explicit cheap model (`gemini-3.5-flash`, Antigravity `model: flash`).
2. **Least Privilege by Default**: Reviewers/analysts get `edit: deny`; read-only explorers deny bash writes.
3. **Context Completeness**: Subagents cannot inspect conversational history. Prompts must contain all required paths, diffs, and parameter specs.
4. **No Evals for Pure Agents**: Validate agents via schema correctness, least-privilege tool inspection, trigger clarity, and manual invocation.

## Workflows

### Creation & Validation

1. Identify the agent's role archetype and target platform directory.
2. Copy the matching template from `templates/agents/`, keep only the target platform's frontmatter block, and tighten tool allowlists and model tier.
3. Write a concise, third-person `description` stating exact delegation triggers.
4. Validate using:
   - `python3 <skill-dir>/scripts/validate_agents.py <path-to-agent-or-dir>`
   - Antigravity strict check: `python3 <skill-dir>/scripts/validate_antigravity.py <path>`
