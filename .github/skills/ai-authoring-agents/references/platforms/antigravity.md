# Google Antigravity Agent Reference

Source: <https://antigravity.google/docs/subagents/>

## Locations & Discovery

- Workspace-scoped: `.agents/agents/<name>.md` or `.agents/agents/<name>/agent.md`
- Global-scoped: `~/.gemini/config/agents/<name>.md` or `~/.gemini/config/agents/<name>/agent.md`
- Plugin-shipped: `plugins/<plugin-name>/agents/`

Antigravity automatically discovers custom subagent `.md` files in these locations.

## Declarative Agent Format (`.md`)

Declarative agents use YAML frontmatter followed by a system prompt body.

### Frontmatter Options

Source: [Frontmatter Configuration (YAML)](https://antigravity.google/docs/subagents/#frontmatter-configuration-yaml)

| Key | Type | Default | Description |
|---|---|---|---|
| `name` | string | **Required** | Unique identifier for the custom agent |
| `description` | string | **Required** | Used by the planner to decide when to delegate to this agent |
| `tools` | string[] | `[]` | Explicit allowlist of permitted tools (e.g. `view_file`, `replace_file_content`, `grep_search`, `run_command`) |
| `mainAgent` | boolean | `true` | Allows selection as the primary agent in chat interfaces |
| `subagent` | boolean | `true` | Allows invocation via the `invoke_subagent` tool |
| `model` | string | `inherit` | Model tier used when invoked: `inherit`, `flash`, or `pro` |
| `commandExecutionPolicy` | string | `sandbox` | Shell auto-execution policy: `off`, `auto`, `eager`, `sandbox` |
| `mcpServers` | object[] | `[]` | Custom MCP servers configured for this subagent |
| `skills` / `plugins` | string[] | `[]` | Skill paths (e.g. `skills/my-helper-skill`) or plugin dependencies |

> **Known Issue (Tool Validation)**: An unmapped or misspelled tool name in
> `tools` may hang the subagent process during execution. Double-check exact
> tool names when configuring custom subagents.

### Example Frontmatter

From the official docs (`code-auditor.md`):

```yaml
---
name: code-auditor
description: Specialized subagent for security audits, static analysis, and code quality reviews.
tools:
  - view_file
  - grep_search
  - run_command
subagent: true
mainAgent: false
model: pro
commandExecutionPolicy: sandbox
skills:
  - skills/security-checklist
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
