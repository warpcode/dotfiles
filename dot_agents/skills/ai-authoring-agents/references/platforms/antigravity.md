# Google Antigravity Agent Reference

Source: <https://antigravity.google/docs/subagents/>

## Locations & Discovery

- Workspace-scoped: `.agents/<name>.md` or `.gemini/agents/<name>.md`
- Global-scoped: `~/.gemini/config/agents/<name>.md`
- Plugin-shipped: `plugins/<plugin-name>/agents/<agent-name>/agent.json` (or `agent.md`)

Antigravity natively discovers custom agents and subagents across workspace and configuration paths.

## Declarative Agent Format (`.md`)

Declarative agents use YAML frontmatter followed by a system prompt body.

### Frontmatter Options

| Key | Type | Default | Description |
|---|---|---|---|
| `name` | string | filename | Agent identifier |
| `description` | string | **Required** | Summary of role and capabilities |
| `kind` | string | `local` | Agent execution type (`local` or `remote`) |
| `model` | string | `gemini-3.5-flash` | Model identifier (e.g. `gemini-3.5-flash`, `gemini-3.5-pro`) |
| `temperature` | float | provider default | Sampling temperature (0.0 to 1.0) |
| `max_turns` | integer | unlimited | Maximum conversational turns |
| `subagent` | boolean | `true` | When `true`, enables invocation via `invoke_subagent` from coordinator agents |
| `inheritCustomizations` | boolean | `false` | When `true`, inherits skills, rules, and subagents from parent environment |
| `capabilities` | object | all tools | Strict capability sandbox restricting tools, skills, MCP servers, and bash commands |

### Capabilities Block Syntax

```yaml
capabilities:
  allowed_tools:
    - view_file
    - grep_search
    - list_dir
  allowed_skills:
    - technical-review-guidelines
  allowed_mcp_servers:
    - github
  allowed_bash_commands:
    - git status
    - git diff
```

### Example Frontmatter

```yaml
---
name: security-auditor
description: Specialized in finding security vulnerabilities, hardcoded credentials, and unsafe calls in source files.
kind: local
model: gemini-3.5-flash
temperature: 0.1
max_turns: 15
subagent: true
capabilities:
  allowed_tools:
    - view_file
    - grep_search
    - list_dir
  allowed_skills:
    - vulnerable-patterns
    - technical-review-guidelines
  allowed_bash_commands:
    - git status
    - git diff
---
```

## Plugin JSON Format (`agent.json`)

When packaging agents as part of an Antigravity plugin:

```json
{
  "name": "weather-agent",
  "description": "Searches the web for current weather forecasts.",
  "model": "gemini-3.5-flash",
  "options": {
    "thinking_level": "low"
  },
  "config": {
    "customAgent": {
      "systemPromptSections": [
        {
          "title": "Agent System Instructions",
          "content": "You are a Weather Agent..."
        }
      ],
      "toolNames": [
        "google_web_search",
        "web_fetch"
      ],
      "systemPromptConfig": {
        "includeSections": [
          "user_information",
          "skills",
          "messaging",
          "artifacts",
          "user_rules"
        ]
      }
    }
  }
}
```

## Execution Modes & Sandboxing

1. **Coordinator Subagent Spawning (`invoke_subagent`)**: Fully sandboxed subagent session executed asynchronously in background with its own context.
2. **OS Sandbox**: Enforces terminal process isolation via `--sandbox` or `settings.json`.
3. **Programmatic Python SDK**: `CapabilitiesConfig` and `LocalAgentConfig` strip tools at API runtime.
