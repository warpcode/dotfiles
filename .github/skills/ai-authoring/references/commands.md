# Authoring Commands & Workflows

Commands and workflows are thin user- or agent-invocable prompt artifacts (`/name`) that bind parameters and dispatch to an Agent or Skill.

- **Command**: A parameterized, single-turn instruction template (`/name [args]`).
- **Workflow**: A multi-step structured procedure (sequential checkpoints or scripted subagent fan-outs).

## Choosing the Artifact

Consult the canonical [Artifact Decision Matrix](artifact-decision-matrix.md) before authoring to confirm a Command/Workflow fits better than a Skill, Agent, Rule, or Hook.

## Platform Discovery & Location Matrix

| Platform | Workspace / Project Scope | Personal / Global Scope | Invocation |
|---|---|---|---|
| **Claude Code** | `<root>/.claude/commands/<name>.md`<br>`<root>/.claude/workflows/<name>.js` | `~/.claude/commands/<name>.md`<br>`~/.claude/workflows/<name>.js` | `/<name>`<br>`/workflows` |
| **Google Antigravity** | `<root>/.agents/workflows/<name>.md`<br>`<root>/.agents/commands/<name>.md` | `~/.gemini/antigravity/global_workflows/<name>.md`<br>`~/.gemini/config/workflows/<name>.md` | `/<name>` |
| **OpenCode** | `<root>/.opencode/commands/<name>.md`<br>`opencode.json` (`command` map) | `~/.config/opencode/commands/<name>.md` | `/<name>` |
| **VS Code / Copilot** | `<root>/.github/prompts/<name>.prompt.md`<br>`<root>/.vscode/prompts/<name>.prompt.md` | `~/.config/Code/User/prompts/<name>.prompt.md` | `/<name>` |
| **Cursor** | `<root>/.cursor/commands/<name>.md`<br>`plugin.json` (`commands` path) | `~/.cursor/commands/<name>.md` | `/<name>` |
| **OpenAI Codex** | `<root>/.codex/prompts/<name>.md` | `~/.codex/prompts/<name>.md` | `/<name>` |
| **Nous Hermes** | `skills/<name>/SKILL.md` | `~/.hermes/skills/<name>/SKILL.md` | `/<skill-name>` |
| **Gemini CLI** | `<root>/.gemini/commands/<name>.toml` | `~/.gemini/commands/<name>.toml` | `/<name>` |

## Platform-Specific Frontmatter References

Command metadata is not portable (most platforms use YAML frontmatter; Gemini CLI uses TOML). Consult the dedicated platform reference before authoring:

| Platform | Reference File | Key Platform Capabilities |
|---|---|---|
| **Google Antigravity** | `commands/platforms/antigravity.md` | `capabilities.allowed_tools`, `allowed_bash_commands`, `max_turns`, 12k char cap |
| **Claude Code** | `commands/platforms/claude-code.md` | `context: fork`, `effort`, `disable-model-invocation`, scripted JS `agent()` / `pipeline()` |
| **VS Code / Copilot** | `commands/platforms/copilot-vscode.md` | `${input:var:placeholder}`, `${selection}`, `${file}`, `handoffs: []` |
| **OpenCode** | `commands/platforms/opencode.md` | `agent:`, `subtask: true`, greedy positional parameters, `opencode.json` |
| **Cursor** | `commands/platforms/cursor.md` | `user-invocable: false`, `@Codebase`, `@Git`, `@Terminal`, plugin variables `${VAR}` |
| **OpenAI Codex** | `commands/platforms/codex.md` | `$ARGUMENTS`, `$UPPERCASE_NAME`, `allowed-tools` |
| **Nous Hermes** | `commands/platforms/hermes.md` | `metadata.hermes.blueprint` (`schedule`, `deliver`), slot-filling, `${HERMES_SKILL_DIR}` |
| **Gemini CLI** | `commands/platforms/gemini-cli.md` | TOML format (`description`, `prompt`), `{{args}}` |

## Parameter & Context Interpolation Standard

- **Full Arguments (`$ARGUMENTS` or `{{args}}`)**: Injects all arguments passed after the command name.
- **Positional Arguments (`$1`, `$2`, ..., `$n`)**: Whitespace-delimited arguments by index (in OpenCode, the highest index greedily consumes trailing arguments). Use `${1:-default_value}` where supported.
- **Interactive Inputs (`${input:variableName:placeholder}`)**: VS Code / Copilot interactive prompt.
- **Pre-Execution Shell Injections (`` !`command` `` or `!<cmd>`)**: MUST be strictly read-only inspection commands (e.g. `` !`git diff --staged` ``).
- **File Inclusions (`@path` / `@file`)**: Embeds target file contents into prompt context.

## Command Prompt Body & Starter Templates

Apply [Authoring Prompts](prompts.md) principles (RFC 2119 directives, explicit approval gates before destructive actions, negative constraints, structured output contracts).

| Pattern | Template Path | Best For |
|---|---|---|
| **Review Checklist** | `templates/commands/review-checklist.md` | Rigorous git/PR review with diff injection & severity report |
| **Parameterized Directive** | `templates/commands/parameterized-directive.md` | Multi-argument scaffolding, refactoring, or code generation |
| **Isolated Subtask** | `templates/commands/isolated-subtask.md` | Deep audits and research running in a child subagent context |
| **Sequential Workflow** | `templates/commands/sequential-workflow.md` | Multi-phase procedures with human approval checkpoints |
| **Scripted Workflow** | `templates/commands/scripted-workflow.js` | Claude Code JavaScript workflows with subagent fan-out & schemas |

## Validation

Run the command validator relative to `<skill-dir>/scripts/`:

```bash
python3 <skill-dir>/scripts/validate_commands.py <path-to-command>
python3 <skill-dir>/scripts/validate_commands.py --self-test
```
