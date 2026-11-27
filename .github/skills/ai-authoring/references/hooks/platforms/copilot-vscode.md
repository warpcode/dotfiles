# VS Code / GitHub Copilot Agent Hook Reference

> **Official Documentation**:
> - [Agent Hooks in Visual Studio Code](https://code.visualstudio.com/docs/agent-customization/hooks)
> - [Hooks Reference Guide](https://code.visualstudio.com/docs/agents/reference/hooks-reference)
> - [Agent Plugins & Hooks](https://code.visualstudio.com/docs/agent-customization/agent-plugins)

VS Code Agent Customization supports lifecycle hooks configured in JSON files or directly within custom agent frontmatter (`.agent.md`). The format is designed for cross-compatibility with Claude Code.

## Discovery Locations & Settings

| Location | Scope | Description |
|---|---|---|
| `.github/hooks/*.json` | Workspace | Any `.json` file in `.github/hooks/` (e.g. `security.json`, `format.json`) |
| `.claude/settings.json` | Workspace | Read automatically for compatibility |
| `.claude/settings.local.json` | Workspace | Local override |
| `~/.copilot/hooks/` | User Global | Machine-wide hooks |
| `~/.claude/settings.json` | User Global | User-level global compatibility |
| Custom Agent (`*.agent.md`) | Agent Scoped | Frontmatter `hooks:` key (requires `chat.useCustomAgentHooks: true`) |
| Plugin `hooks.json` | Plugin | Bundled inside an Agent Plugin |

### Customizing Discovery Locations
In VS Code `settings.json`:
```json
{
  "chat.hookFilesLocations": {
    ".github/hooks": true,
    "custom/hooks": true,
    "~/my-hooks/security.json": true,
    ".claude/settings.json": false
  },
  "chat.useCustomAgentHooks": true
}
```

## Hook File Structure

Each JSON file contains a root `hooks` object mapping event names to arrays of handler definitions:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": "./scripts/block-dangerous.sh",
        "windows": "powershell -File scripts\\block-dangerous.ps1",
        "linux": "./scripts/block-dangerous.sh",
        "osx": "./scripts/block-dangerous.sh",
        "timeout": 15,
        "env": {
          "POLICY_LEVEL": "strict"
        }
      }
    ],
    "PostToolUse": [
      {
        "type": "command",
        "command": "npx prettier --write ."
      }
    ]
  }
}
```

## Supported Events

| Event | When It Fires | Best For |
|---|---|---|
| `SessionStart` | When a chat session begins | Injecting project environment context, branch info, dynamic rules |
| `PreToolUse` | Before a tool step executes | Security gating, command validation, manual approval triggers |
| `PostToolUse` | After a tool completes | Formatting modified files, running linters, auto-fixing syntax |
| `PreCompact` | Before context window compaction | Archiving critical summary points before truncation |
| `SubagentStart` | When a subagent is invoked | Initializing subagent state or logging dispatch |
| `SubagentStop` | When a subagent finishes | Validating subagent deliverables |
| `Stop` | When the agent completes the turn | Running test suite before allowing completion |

## Command Properties

- `type`: `"command"` (required).
- `command`: Fallback shell command string.
- `windows`: Windows-specific command override (e.g. PowerShell invocation).
- `linux`: Linux-specific command override.
- `osx`: macOS-specific command override.
- `cwd`: Working directory (defaults to workspace root).
- `timeout` or `timeoutSec`: Max execution time in seconds (default `30`).
- `env`: Key-value map of environment variables passed to the child process.

## Input / Output JSON Contract

### Stdin (Input)
```json
{
  "timestamp": "2026-08-23T20:00:00Z",
  "cwd": "/workspace/repo",
  "session_id": "copilot-sess-456",
  "hook_event_name": "PreToolUse",
  "tool_name": "runTerminalCommand",
  "tool_input": {
    "command": "npm test"
  },
  "transcript_path": "/path/to/transcript.jsonl"
}
```

### Stdout (Output Decisions)
Hooks have three control channels:
1. **Exit Codes**:
   - `0`: Success / pass.
   - `2`: Block tool or operation. The hook's `stderr` is passed back to the model as context.
2. **Top-Level JSON**:
   ```json
   {
     "continue": false,
     "stopReason": "Security violation",
     "systemMessage": "Warning: unverified dependencies detected."
   }
   ```
3. **Hook-Specific Output (`hookSpecificOutput`)**:
   ```json
   {
     "hookSpecificOutput": {
       "hookEventName": "PreToolUse",
       "permissionDecision": "deny",
       "permissionDecisionReason": "Destructive shell command blocked.",
       "additionalContext": "Please review repository guidelines."
     }
   }
   ```

Values for `permissionDecision`:
- `"allow"`: Auto-approves the tool execution.
- `"deny"`: Hard blocks the tool execution without stopping the overall session.
- `"ask"`: Forces a confirmation prompt in the VS Code UI.

## Agent-Scoped Hooks Example (`.agent.md`)

```markdown
---
name: strict-formatter
description: Agent that enforces automated code formatting on all edits
hooks:
  PostToolUse:
    - type: command
      command: "./scripts/format-changed-files.sh"
---

You are a precise code editing assistant. All file edits are automatically formatted.
```
