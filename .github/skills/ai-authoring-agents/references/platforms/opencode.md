# OpenCode Agent Reference

Source: <https://opencode.ai/docs/agents/>

## Locations & Discovery

- Project-scoped: `.opencode/agents/<name>.md` or `.opencode/agent/<name>.md`
- Global/User-scoped: `~/.config/opencode/agents/<name>.md`

OpenCode discovers `.md` files in these locations and derives the agent name from the file stem.

## Recognized Frontmatter Options

| Key | Type | Default | Description |
|---|---|---|---|
| `description` | string | **Required** | Summary of agent capabilities and trigger conditions |
| `mode` | string | `all` | Execution mode: `primary` (main session only), `subagent` (delegated background execution only), or `all` (both) |
| `model` | string | caller's model | Full provider/model string (e.g. `anthropic/claude-3-5-sonnet`, `google/gemini-2.5-flash`, `ollama/qwen2.5-coder`) |
| `temperature` | float | provider default | Sampling temperature (0.0–0.2 for strict analysis, 0.3–0.5 for coding, >0.6 for brainstorming) |
| `permissions` | object | inherited | Granular per-capability permission map (`allow`, `ask`, `deny`). Replaces legacy `tools` key. |
| `steps` | integer | unlimited | Hard cap on agentic iterations / tool-call loops for cost control |
| `hidden` | boolean | `false` | `true` hides the agent from interactive `@` typeahead menus |
| `color` | string | none | UI badge color (e.g. `#4A90E2` or standard color string) |

## Permissions Map Syntax

The `permissions` block supports both simple permission levels and fine-grained command patterns:

```yaml
permissions:
  read: allow
  edit: deny
  websearch: allow
  bash:
    "git status": allow
    "git diff*": allow
    "npm test*": allow
    "*": ask
```

Standard capabilities controlled by permissions:
- `read`: File and directory reads
- `edit`: File creation, modification, and deletion
- `bash`: Terminal command execution (can be string `allow`/`ask`/`deny` or pattern map)
- `websearch` / `webfetch`: Remote internet exploration

## Example Frontmatter

### 1. Read-Only Code Auditor (Subagent Mode)
```yaml
---
description: Audits code for security vulnerabilities, memory leaks, and anti-patterns without modifying files.
mode: subagent
model: google/gemini-2.5-flash
temperature: 0.1
steps: 20
permissions:
  read: allow
  edit: deny
  websearch: deny
  bash:
    "git diff*": allow
    "git log*": allow
    "*": deny
---
```

### 2. Full-Stack Implementer (Primary or Subagent)
```yaml
---
description: Implements backend APIs and database migrations with full terminal and editing access.
mode: all
model: anthropic/claude-3-5-sonnet
temperature: 0.2
color: "#34D399"
permissions:
  read: allow
  edit: allow
  websearch: allow
  bash: allow
---
```

## System Prompt Body

The markdown body contains the agent's instructions, role persona, and execution workflow.
