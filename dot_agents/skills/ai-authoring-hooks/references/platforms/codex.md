# ChatGPT / Codex Hook Reference

> **Official Documentation**:
> - [Agent Configuration & Rules](https://learn.chatgpt.com/docs/agent-configuration/rules)
> - [Codex Advanced Configuration & Hooks](https://learn.chatgpt.com/docs/build-skills)

The ChatGPT / Codex developer environment and agent harness support lifecycle hooks configured via `.codex/hooks.json` or inline tables in `config.toml`.

## Discovery Locations

| Scope | Location | Description |
|---|---|---|
| Project Local | `.codex/hooks.json` or `<repo>/.codex/config.toml` | Repository-level hooks |
| User Global | `~/.codex/hooks.json` or `~/.codex/config.toml` | Personal / machine-wide defaults |

## Configuration Schema

### `hooks.json` Format
```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "./scripts/init-session.sh"
      }
    ],
    "UserPromptSubmit": [
      {
        "type": "command",
        "command": "./scripts/inject-path-rules.sh"
      }
    ],
    "PreToolUse": [
      {
        "type": "command",
        "command": "./scripts/validate-sandbox.sh",
        "timeout": 10
      }
    ],
    "PostToolUse": [
      {
        "type": "command",
        "command": "./scripts/format.sh"
      }
    ],
    "SessionEnd": [
      {
        "type": "command",
        "command": "./scripts/cleanup.sh"
      }
    ]
  }
}
```

### `config.toml` Inline Format
```toml
[hooks]
session_start = "./scripts/init-session.sh"
pre_tool_use = "./scripts/validate-sandbox.sh"
user_prompt_submit = "./scripts/inject-path-rules.sh"
```

## Supported Lifecycle Events

- `SessionStart`: Runs at the beginning of an agent session. Used for environment inspection and initial context injection.
- `UserPromptSubmit`: Runs on every user prompt submission before sending to the model.
- `PreToolUse`: Intercepts tool/command execution before running inside or outside the sandbox.
- `PostToolUse`: Fires after a tool execution completes.
- `SessionEnd`: Cleanup and telemetry logging when the session completes.

## Input / Output Protocol

Hook scripts receive event context as a JSON string over `stdin` and write JSON decisions to `stdout`.

### PreToolUse Evaluation
- Exit code `0` with `{ "allow": true }` or empty output: Allows execution.
- Exit code `0` with `{ "allow": false, "reason": "..." }`: Denies execution with explanation.
- Exit code `2`: Hard blocks execution; `stderr` is passed back as model feedback.

## Simulating Rules in Codex

Codex natively reads `AGENTS.md` and `AGENTS.override.md`, but lacks dynamic glob-scoped rule engines. You can simulate full path-scoped and turn-specific rules using `UserPromptSubmit` or `SessionStart` hooks:

1. **Rule Discovery Script**: In `UserPromptSubmit`, run a script that executes `git status --porcelain` and `git diff --name-only` to find modified/staged files.
2. **Glob Matcher**: Match modified files against rules in `.agents/rules/` or `.github/instructions/`.
3. **Context Injection**: Emit matching rule markdown directly onto stdout to be appended to the session prompt context.
