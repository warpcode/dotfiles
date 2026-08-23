# Claude Code Hook Reference

> **Official Documentation**:
> - [Hooks Reference](https://code.claude.com/docs/en/hooks#hooks-reference)
> - [Automate Actions with Hooks](https://code.claude.com/docs/en/hooks-guide)
> - [Permissions & Deny Rules](https://code.claude.com/docs/en/permissions)

Claude Code provides the most extensive lifecycle hook system among AI agent platforms, supporting over 30 lifecycle events, fine-grained permission syntax, multiple handler execution types, and decision control.

## Discovery Locations & Precedence

| Scope | Location | Git Tracked | Notes |
|---|---|---|---|
| User / Global | `~/.claude/settings.json` | No | Machine-wide hooks across all projects |
| Project Shared | `.claude/settings.json` | Yes | Committed to repository; shared with team |
| Project Local | `.claude/settings.local.json` | No | Gitignored override for personal project hooks |
| Plugin Bundled | `<plugin-root>/hooks/hooks.json` | Yes | Active whenever the plugin is enabled |
| Skill Frontmatter | `SKILL.md` (frontmatter `hooks:` key) | Yes | Active for session duration once skill is loaded |
| Subagent Frontmatter | `.claude/agents/*.md` (`hooks:` key) | Yes | Active only while subagent is running |

Hooks from multiple sources merge rather than replace each other.

## Configuration Schema

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "Bash|Edit",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(rm *)",
            "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh",
            "args": [],
            "timeout": 15,
            "async": false
          }
        ]
      }
    ]
  }
}
```

## Supported Event Types

### Per-Session Events
- `SessionStart`: Fires when a session begins or resumes (`startup`, `resume`, `clear`, `compact`, `fork`). Can inject `additionalContext` or `initialUserMessage`.
- `Setup`: Fires with `--init-only`, `--init`, or `--maintenance` in `-p` mode (`init`, `maintenance`).
- `SessionEnd`: Fires when a session terminates (`clear`, `resume`, `logout`, `prompt_input_exit`, `other`).

### Per-Turn Events
- `UserPromptSubmit`: Fires when user submits a prompt before Claude processes it.
- `UserPromptExpansion`: Fires when a user-typed command (`/command` or skill) expands into a prompt. Can block expansion.
- `Stop`: Fires when Claude finishes turn response. Can return `decision: "block"` or `additionalContext` to force continuation (up to 8 times).
- `StopFailure`: Fires when turn ends due to an API error (`rate_limit`, `overloaded`, `authentication_failed`, etc.).

### Tool Execution Loop Events
- `PreToolUse`: Fires before any tool execution (except `EndConversation`). Matcher filters on tool name (`Bash`, `Edit`, `Write`, `mcp__<server>__<tool>`). Can block or defer.
- `PermissionRequest`: Fires when Claude Code is about to ask the user for permission.
- `PermissionDenied`: Fires when auto mode denies a tool call. Can set `retry: true`.
- `PostToolUse`: Fires after a tool call completes successfully.
- `PostToolUseFailure`: Fires after a tool call errors or fails.
- `PostToolBatch`: Fires after a full parallel batch of tool calls resolves.

### Agent & Team Events
- `SubagentStart`: Fires when a subagent is spawned (matcher filters by subagent name).
- `SubagentStop`: Fires when a subagent finishes. Can force continuation with `additionalContext`.
- `TeammateIdle`: Fires when an agent team teammate is about to go idle.
- `TaskCreated`: Fires when a task is created via `TaskCreate`.
- `TaskCompleted`: Fires when a task is marked complete.

### Environment & Context Events
- `InstructionsLoaded`: Fires when `CLAUDE.md` or `.claude/rules/*.md` is loaded.
- `ConfigChange`: Fires when configuration changes during a session.
- `CwdChanged`: Fires when working directory changes (e.g. after `cd`).
- `DirectoryAdded`: Fires when directory added via `/add-dir`.
- `FileChanged`: Fires when watched file changes on disk (`matcher: ".envrc|.env"`).
- `WorktreeCreate` / `WorktreeRemove`: Custom git worktree creation/cleanup handlers.
- `PreCompact` / `PostCompact`: Context compaction lifecycle hooks.
- `Elicitation` / `ElicitationResult`: MCP user input elicitation hooks.
- `Notification`: Fires on desktop/system notification events.
- `MessageDisplay`: Fires while streaming assistant message text.

## Matcher & `if` Syntax

### Event Matchers
- `""` or `"*"`: Match all.
- `Bash|Edit`: Match either tool.
- `mcp__memory__.*`: Regex match for all tools from MCP `memory` server.
- `^custom-agent$`: Exact subagent match.

### Handler `if` Conditions (Permission Syntax)
Narrows execution without process spawning:
- `"if": "Bash(rm *)"`: Only spawns if bash command starts with `rm `.
- `"if": "Edit(*.ts)"`: Only spawns for TypeScript file edits.
- `"if": "Write(src/**)"`: Only spawns for files inside `src/`.

## Handler Types

### 1. `command`
- **Shell form** (no `args`): `"command": "node \"${CLAUDE_PROJECT_DIR}\"/scripts/lint.js"`
- **Exec form** (with `args` array): `"command": "node", "args": ["${CLAUDE_PROJECT_DIR}/scripts/lint.js"]`
- Environment variables exported: `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_ROOT`, `CLAUDE_PLUGIN_DATA`.

### 2. `http`
```json
{
  "type": "http",
  "url": "https://api.internal.net/hooks/pre-tool",
  "headers": { "Authorization": "Bearer $TOKEN" },
  "allowedEnvVars": ["TOKEN"]
}
```

### 3. `mcp_tool`
```json
{
  "type": "mcp_tool",
  "server": "security_scanner",
  "tool": "scan_file",
  "input": { "path": "${tool_input.file_path}" }
}
```

### 4. `prompt` and `agent`
```json
{
  "type": "prompt",
  "prompt": "Evaluate whether this command is safe: $ARGUMENTS",
  "model": "fast"
}
```

## JSON Input / Output Contract

### Input JSON (via stdin / POST body)
```json
{
  "session_id": "abc-123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/path/to/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf build/"
  }
}
```

### Output JSON (via stdout)
```json
{
  "decision": "block",
  "reason": "Destructive command rejected by policy.",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Cannot remove build directory",
    "additionalContext": "Use `npm run clean` instead."
  }
}
```

- **Exit code 0**: Allow/pass. If JSON returned, `hookSpecificOutput` is applied.
- **Exit code 2**: Hard block. The hook's `stderr` is fed directly to the model as context.
