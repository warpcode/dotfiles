# Claude Code Subagent Reference

Source: <https://code.claude.com/docs/en/sub-agents>

## Locations & Discovery

- Project-level: `.claude/agents/<name>.md`
- User/Global-level: `~/.claude/agents/<name>.md`
- Plugin-shipped: `<plugin>/agents/<name>.md`

In Claude Code, the agent identifier is the filename without `.md` (e.g. `code-reviewer.md` -> `code-reviewer`).

## Recognized Frontmatter Options

| Key | Type | Default | Description |
|---|---|---|---|
| `name` | string | filename | Optional display name for the agent |
| `description` | string | **Required** | Summary of role and trigger conditions for subagent delegation |
| `tools` | list / string | all inherited | Allowlist of tool names permitted for the subagent (e.g. `[Bash, FileEdit, GlobTool]`) |
| `disallowedTools` | list / string | none | Tools explicitly stripped from the subagent's toolset |
| `model` | string | `inherit` | Model alias (`sonnet`, `opus`, `haiku`, `inherit`) or full model identifier |
| `effort` | string | platform default | Reasoning/thinking effort level (`low`, `medium`, `high`, `max`) |
| `maxTurns` | integer | unlimited | Turn execution cap for cost and runaway loop protection |
| `memory` | string / object | none | Persistent memory configuration for the agent |
| `isolation` | string | none | Set to `"worktree"` to run in an isolated Git worktree |
| `background` | boolean | `false` | `true` executes the subagent asynchronously in the background |
| `permissionMode` | string | caller's mode | Permission prompt handling mode (e.g. `interactive`, `bypass`) |
| `hooks` | object | none | Lifecycle hooks (e.g. `PreToolUse`, `PostToolUse`) |
| `skills` | list | all | Allowlist of skills the subagent is permitted to load |

> [!NOTE]
> Plugin-shipped agents support standard keys (`name`, `description`, `tools`, `disallowedTools`, `model`, `effort`, `maxTurns`, `isolation`, `background`) but restrict `hooks`, `permissionMode`, and dynamic MCP registration.

## Example Frontmatter

### 1. Read-Only Code Reviewer (Low Token Tier)
```yaml
---
name: Code Reviewer
description: Reviews pull requests, diffs, and codebase changes for quality and security without modifying files.
tools:
  - GlobTool
  - FileRead
  - Bash(git status)
  - Bash(git diff *)
disallowedTools:
  - FileEdit
  - FileCreate
model: haiku
effort: low
maxTurns: 15
---
```

### 2. Isolated Refactoring Agent (Worktree Sandboxed)
```yaml
---
name: Refactoring Specialist
description: Performs large-scale refactors and test migrations within an isolated git worktree.
tools:
  - FileEdit
  - FileCreate
  - GlobTool
  - FileRead
  - Bash
isolation: worktree
model: sonnet
effort: high
maxTurns: 30
---
```

## System Prompt Body

The markdown body following the closing `---` constitutes the agent's full system prompt. It must be self-contained:
- Claude Code subagents do **not** inherit the parent's conversational history.
- Specify input parameters, output schemas, step-by-step procedures, and domain constraints explicitly in the body.
