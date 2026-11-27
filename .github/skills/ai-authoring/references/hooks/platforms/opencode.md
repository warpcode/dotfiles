# OpenCode Plugin & Hook Reference

> **Official Documentation**:
> - [OpenCode Plugins Guide](https://opencode.ai/docs/plugins/)
> - [OpenCode Custom Rules](https://opencode.ai/docs/rules/)
> - [OpenCode Configuration Reference](https://opencode.ai/docs/config/)

OpenCode extends its agent loop through TypeScript and JavaScript plugin modules rather than static JSON hook files. Plugins can hook into events, modify tool inputs, intercept file access, inject environment variables, or register custom tools.

## Discovery Locations & Installation

| Scope | Location | Installation Method |
|---|---|---|
| Project Local | `.opencode/plugins/*.ts` or `.js` | Automatically loaded from folder at startup |
| Global Local | `~/.config/opencode/plugins/*.ts` or `.js` | Automatically loaded machine-wide |
| npm Packages | Listed in `opencode.json` (`"plugin": [...]`) | Auto-installed via Bun at startup into `~/.cache/opencode/node_modules/` |

### `opencode.json` Configuration
```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "opencode-wakatime",
    "@my-org/security-guard",
    "./custom-plugin.js"
  ]
}
```

## Plugin Architecture

A plugin is an exported async function receiving a context object (`{ project, client, $, directory, worktree }`) and returning an object mapping event names to handler functions.

```typescript
import { type Plugin, tool } from "@opencode-ai/plugin"

export const MyGuardPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // Guardrails and argument modifications
      if (input.tool === "bash" && output.args.command.includes("rm -rf")) {
        throw new Error("Destructive rm -rf command blocked by plugin guard")
      }
    },
    "shell.env": async (input, output) => {
      // Environment variable injection
      output.env.CI_MODE = "true"
      output.env.PROJECT_ROOT = directory
    }
  }
}
```

## Supported Lifecycle Events

### Tool Execution Events
- `tool.execute.before`: `async (input, output) => void`
  - `input`: `{ tool: string }`
  - `output.args`: Mutable object containing the tool arguments.
  - Can modify arguments directly (e.g. `output.args.command = ...`) or `throw new Error(...)` to abort the tool execution.
- `tool.execute.after`: `async (input, output) => void`
  - Fires after tool completion; inspects tool return value.

### Session Lifecycle Events
- `session.created`: Fires on session start.
- `session.idle`: Fires when the agent completes its work and goes idle.
- `session.error`: Fires when a session encounters an unhandled failure.
- `session.compacted`: Fires when conversation history is compacted.
- `session.updated`: Fires on turn state changes.

### Shell & Environment
- `shell.env`: `async (input, output) => void`
  - Injects environment variables into all bash/terminal invocations:
  ```typescript
  "shell.env": async (input, output) => {
    output.env.CUSTOM_VAR = "value"
  }
  ```

### Message & Prompt Events
- `tui.prompt.append`: Appends text to user prompts.
- `message.updated` / `message.part.updated`: Observes or mutates message parts.
- `permission.asked` / `permission.replied`: Monitors interactive user permission requests.

## Registering Custom Tools in Plugins

```typescript
export const ToolPlugin: Plugin = async (ctx) => {
  return {
    tool: {
      lintCode: tool({
        description: "Run linter and return errors",
        args: {
          path: tool.schema.string()
        },
        async execute(args, context) {
          const result = await ctx.$`eslint ${args.path} --format json`
          return result.text()
        }
      })
    }
  }
}
```

## Simulating Rules in OpenCode

OpenCode supports static `AGENTS.md` and `instructions:` globs in `opencode.json`, but does not natively evaluate frontmatter triggers. You can simulate dynamic rules using plugins:

1. **Path Protection Guard**: Use `tool.execute.before` to intercept `read` or `write` tools and throw errors if forbidden files (`.env`, credentials) are touched.
2. **Dynamic System Reminders**: Use `client.app.log()` or append guidance dynamically during `session.created` based on current git branch and active file inspection.
