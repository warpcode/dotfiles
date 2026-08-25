---
name: ai-authoring-agents
description: >
  Create, modify, update, configure, or debug custom subagent definitions
  across Claude Code (.claude/agents/*.md), GitHub Copilot and VS Code
  (.github/agents/*.agent.md), OpenCode (.opencode/agents/*.md), Google
  Antigravity (.agents/*.md), ChatGPT/Codex (.codex/config.toml, AGENTS.md),
  Cursor (.cursor/agents/*.md), and Hermes Agent (.hermes/agents/*.yaml). Use
  when the user says "create an agent", "add a subagent", "make a subagent for
  X", "agent frontmatter", asks about agent fields (tools, permissions, mode,
  model routing, isolation, background), wants an agent made read-only, or is
  deciding whether a task needs a subagent versus a skill, command, or rule.
---

# Authoring Subagent Definitions

Create, configure, and maintain custom agent and subagent definitions across
Claude Code, GitHub Copilot/VS Code, OpenCode, Google Antigravity, ChatGPT/Codex,
Cursor, and Hermes Agent.

A subagent definition is a single markdown or YAML file combining structured
frontmatter (metadata, tool policies, model routing, isolation) with a
self-contained system prompt body.

## When to use

- The user says "create an agent", "add a subagent", "make a subagent for X",
  or "turn this persona into an agent".
- They want to configure frontmatter fields: tools allowlist, permissions map,
  model tiering, thinking effort, turn caps, or execution sandboxing.
- They need to make an agent read-only or apply least-privilege constraints.
- They are debugging why an agent is not being discovered or picked up.
- They need to decide whether a problem requires a subagent, skill, command, or rule.

## Decision Matrix: Subagent vs Alternatives

| Requirement | Artifact | Skill to load |
|---|---|---|
| Prompt bodies, personas, orchestration patterns & Mermaid.js | **Prompt Pattern** | `ai-authoring-prompts` |
| Reusable SOP, guidelines, or tool integration loaded on demand | **Skill** (`SKILL.md`) | `ai-authoring-skills` |
| Interactive user shortcut or parameterized slash command | **Command** (`/name`) | `ai-authoring-commands` |
| Persistent instructions/memory always or conditionally injected | **Rule** (`rules/`, `AGENTS.md`) | `ai-authoring-rules` |
| Delegated task running in an **isolated context window** with dedicated tool policy & model tier | **Subagent** (`<name>.md` / `.agent.md`) | `ai-authoring-agents` |
| Deterministic lifecycle gate, command blocker, or auto-formatter | **Hook** (`hooks.json`, `.github/hooks/`, plugins) | `ai-authoring-hooks` |

**House Delegation Heuristic**: High-noise exploration (broad codebase grepping,
large logs, multi-file surveys) belongs in a subagent so the coordinator's
context remains clean and focused.

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

## Universal Superset Schema

Write definitions against this unified schema concept, then map or trim fields
per platform target.

**Portable core — compatible with every platform**, including strict parsers:

```yaml
---
name: code-auditor
description: Performs read-only analysis of pull requests, diffs, and security patterns.
model: anthropic/claude-3-5-sonnet # or fallback array on Copilot
---
```

**Extended superset — every platform except Google Antigravity.** Claude Code,
Copilot/VS Code, OpenCode, ChatGPT/Codex, Cursor, and Hermes tolerate these
additional keys:

```yaml
---
mode: subagent                  # OpenCode: primary | subagent | all
temperature: 0.1
maxTurns: 20                    # Antigravity equivalent: max_turns (snake_case); OpenCode: steps
tools:                          # Claude Code / Copilot allowlist
  - FileRead
  - GlobTool
permissions:                    # OpenCode fine-grained permissions
  read: allow
  edit: deny
  bash:
    "git diff*": allow
    "*": deny
user-invocable: true            # Copilot / Claude UI autocomplete visibility
isolation: worktree             # Claude Code worktree sandboxing
---
```

> **Warning**: Google Antigravity rejects undocumented frontmatter keys, and a
> misspelled `tools` entry can hang the subagent (known issue). Never ship either
> block above to `.agents/agents/` — emit only the keys documented in the
> [Antigravity Reference](references/platforms/antigravity.md): `name`,
> `description`, `tools`, `mainAgent`, `subagent`, `model` (`inherit`/`flash`/`pro`),
> `commandExecutionPolicy`, `mcpServers`, `skills`/`plugins`.

### Platform Reference Guides

For exhaustive options, see platform references in `references/platforms/`:

- [Claude Code Reference](references/platforms/claude-code.md): `tools`, `disallowedTools`, `effort`, `maxTurns`, `isolation: worktree`, `background`. ([Source](https://code.claude.com/docs/en/sub-agents))
- [Copilot / VS Code Reference](references/platforms/copilot-vscode.md): `name`, `description`, fallback `model` arrays, `tools` allowlists, `user-invocable`, `handoffs`. ([Source](https://code.visualstudio.com/docs/agent-customization/custom-agents))
- [OpenCode Reference](references/platforms/opencode.md): `mode`, `model`, `temperature`, `permissions` object (`allow`/`ask`/`deny`), `steps`, `hidden`. ([Source](https://opencode.ai/docs/agents/))
- [Antigravity Reference](references/platforms/antigravity.md): `name`, `description`, `tools`, `mainAgent`, `subagent`, `model` (`inherit`/`flash`/`pro`), `commandExecutionPolicy`, `mcpServers`, `skills`/`plugins`. Undocumented keys break config; misspelled tool names hang execution. ([Source](https://antigravity.google/docs/subagents/))
- [ChatGPT / Codex Reference](references/platforms/codex.md): `.codex/config.toml` `[agents]` section, `AGENTS.md` subagent routing. ([Source](https://learn.chatgpt.com/docs/agent-configuration/subagents))
- [Cursor Reference](references/platforms/cursor.md): `paths` scoping, custom agent models. ([Source](https://cursor.com/docs/agent-customization))
- [Hermes Agent Reference](references/platforms/hermes.md): `.hermes/agents/*.yaml` blueprint schema. ([Source](https://hermes-agent.nousresearch.com/docs/developer-guide/creating-agents))

## Role Archetypes & Templates

Subagents are **role personas**. Select the closest template from `templates/`:

| Role Archetype | Primary Focus | Recommended Permissions / Model | Template |
|---|---|---|---|
| **Specialist Implementer** | Domain code generation (frontend, backend, DB) | `read: allow, edit: allow, bash: safe`<br>Flagship model (`sonnet`, `pro`, `gpt-4o`) | `templates/specialist-implementer.md` |
| **Auditor / Reviewer** | Read-only security, quality, diff review | `read: allow, edit: deny, bash: deny`<br>Strict temp (0.1) | `templates/auditor-reviewer.md` |
| **Researcher / Explorer** | Broad codebase grepping, web doc searches | `read: allow, edit: deny, websearch: allow`<br>Fast cheap flash model (`gemini-3.5-flash`, `haiku`) | `templates/researcher-explorer.md` |
| **Maintenance Janitor** | Tech debt cleanup, dead code purge | `read: allow, edit: allow, bash: test/lint`<br>Worktree isolation | `templates/maintenance-janitor.md` |
| **Coordinator Orchestrator** | Subagent dispatching, multi-stage supervisor | `Agent` tool / `invoke_subagent`<br>Top-tier reasoning model | `templates/coordinator-orchestrator.md` |

### Reference Agent Architectures

For structural patterns and real-world examples:
- [Anthropic Skill-Creator Analyzer](https://github.com/anthropics/skills/blob/main/skills/skill-creator/agents/analyzer.md): Post-hoc analysis and comparative evaluation agent.
- [AEM Front-End Specialist](https://github.com/github/awesome-copilot/blob/main/agents/aem-frontend-specialist.agent.md): Specialized domain implementation with Figma MCP integration.
- [AWS Cloud Expert](https://github.com/github/awesome-copilot/blob/main/agents/aws-cloud-expert.agent.md): Cloud infrastructure and architecture specialist.
- [GEM Browser Tester](https://github.com/github/awesome-copilot/blob/main/agents/gem-browser-tester.agent.md): Web and browser testing agent.
- [Universal Janitor](https://github.com/github/awesome-copilot/blob/main/agents/janitor.agent.md): Codebase debt removal and cleanup specialist.
- [Python Performance Expert](https://github.com/vijaythecoder/awesome-claude-agents/blob/main/agents/specialized/python/performance-expert.md): Profiling, optimization, and concurrent programming advisor.

See `references/best-practices.md` for architectural guidelines on cognitive boundaries and least privilege.

## System Prompt Authoring Patterns

The markdown body following the frontmatter is the subagent's system prompt.
Structure it with these core sections:

1. **Role & Identity**: State persona, domain mastery, and operational purpose.
2. **Core Directives**: Fundamental rules and constraints (e.g. "Read-only: NEVER edit files").
3. **Execution Workflow**: Ordered steps the agent must follow from input to output.
4. **Domain Standards**: Project-specific conventions, typing requirements, and libraries.
5. **Structured Output Contract**: Fixed Markdown or JSON schema for returned results so the coordinator can synthesize easily.

## House Rules & Guardrails

1. **Model Routing for Cheap Exploration**: Subagents performing high-noise grep/read tasks must NOT run on the master model. Pin an explicit cheap model (house default `gemini-3.5-flash`, non-inheriting; Antigravity tier: `model: flash`).
2. **Least Privilege by Default**: Reviewers/analysts get `edit: deny`; read-only explorers deny bash writes. Only grant write access when the role explicitly mutates code.
3. **Context Completeness**: Subagents cannot inspect conversational history. Prompts sent to subagents must contain all required paths, diffs, and parameter specs.
4. **No Evals for Pure Agents**: Unlike skills (which require test benches and pass-rate evals), agents are role personas validated via schema correctness, least-privilege tool inspection, trigger clarity in descriptions, and manual invocation.

## Workflows

### 1. Creation Workflow

1. Identify the agent's specific role archetype (table above).
2. Choose target platform directory (`.github/agents/`, `.claude/agents/`, `.opencode/agents/`, etc.).
3. Copy the appropriate template from `templates/`.
4. Keep the frontmatter variant matching your target platform — each template's
   frontmatter comments carry complete, copy-paste-ready blocks for OpenCode,
   Copilot/VS Code, Claude Code, and Antigravity — then tighten tool allowlists
   and model tier.
5. Write a concise, third-person `description` stating exact delegation triggers.
6. Customize the system prompt body with domain rules and structured output schemas.
7. Validate using `python3 scripts/validate.py <path-to-agent>` (Antigravity targets: `python3 scripts/validate_antigravity.py <path>`).
8. Test invocation with a targeted task.

### 2. Validation Workflow

Run the automated validator to ensure structural and platform conformance:

```bash
# Validate a specific agent definition
python3 scripts/validate.py .github/agents/my-agent.agent.md

# Validate all agents in a directory
python3 scripts/validate.py .github/agents/

# Strict validation for Google Antigravity agents (documented keys only,
# model/exec-policy values, tool-name hang check)
python3 scripts/validate_antigravity.py .agents/agents/
```

Manual checks:
- [ ] Description states when the coordinator should delegate to this agent.
- [ ] Permissions follow least privilege (`edit: deny` for review/exploration).
- [ ] Model tier matches task complexity (cheap flash model for broad searches).
- [ ] Filename conforms to lowercase hyphen-separated identifier (`<name>.md` or `<name>.agent.md`).
