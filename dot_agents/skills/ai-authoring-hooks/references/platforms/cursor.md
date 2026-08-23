# Cursor Hook Reference

> **Official Documentation**:
> - [Cursor Agent Hooks Guide](https://cursor.com/docs/agent-customization/hooks)
> - [Cursor Rules & Customization](https://cursor.com/docs/skills)

Cursor Agent supports reactive lifecycle hooks defined in a `hooks.json` configuration file at the workspace or global level.

## Discovery Locations

| Scope | Location | Description |
|---|---|---|
| Project Local | `.cursor/hooks.json` | Project-scoped hooks |
| Global / User | `~/.cursor/hooks.json` | Global hooks across all projects |

## Configuration Schema (Version 1)

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "bun run .cursor/hooks/init.ts"
      }
    ],
    "beforeSubmitPrompt": [
      {
        "command": "python3 .cursor/hooks/check-prompt.py"
      }
    ],
    "preToolUse": [
      {
        "command": "./scripts/safety-gate.sh"
      }
    ],
    "postToolUse": [
      {
        "command": "./scripts/format.sh"
      }
    ],
    "stop": [
      {
        "command": "bun run .cursor/hooks/verify-tests.ts"
      }
    ]
  }
}
```

## Supported Events

- `sessionStart`: Triggered once when a new composer or agent session initializes.
- `beforeSubmitPrompt`: Triggered before a user's prompt is processed by the agent.
- `preToolUse`: Triggered prior to executing tool calls (terminal commands, file edits).
- `postToolUse`: Triggered immediately after a tool call completes.
- `stop`: Triggered when the agent finishes its work and attempts to stop.

## Execution Model

- Hook processes run as child processes communicating over `stdin` (receiving event JSON) and `stdout` (returning structured response).
- A non-zero exit code or `decision: "block"` in the `stop` event keeps the agent active to resolve remaining issues (e.g. failing tests or lint errors).
- Exit code 2 feeds `stderr` directly into the agent's context window.
