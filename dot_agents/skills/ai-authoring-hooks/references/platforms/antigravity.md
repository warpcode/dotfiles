# Google Antigravity Hook Reference

> **Official Documentation**:
> - [Antigravity Lifecycle Hooks Guide](https://antigravity.google/docs/hooks/)
> - [Antigravity Customization System](https://antigravity.google/docs/skills/)

Google Antigravity provides lifecycle hooks via `hooks.json` files for gating tool calls, modifying step arguments, injecting ephemeral model instructions, and controlling loop continuation.

## Discovery Locations & Precedence

| Scope | Location | Description |
|---|---|---|
| Workspace Project | `.agents/hooks.json` or `.agent/hooks.json` | Project-specific hooks checked into VCS |
| Global Configuration | `~/.gemini/config/hooks.json` | Machine-wide hooks for all Antigravity workspaces |
| Plugin Customization | `plugins/<name>/hooks.json` | Bundled alongside plugin skills/rules |

Multiple named hooks configured across scopes merge and execute sequentially.

## Configuration Schema

Antigravity structures `hooks.json` with named hook objects as top-level keys:

```json
{
  "safety-gate": {
    "enabled": true,
    "PreToolUse": [
      {
        "matcher": "run_command|write_to_file",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/safety-check.sh",
            "timeout": 15
          }
        ]
      }
    ]
  },
  "context-injector": {
    "PreInvocation": [
      {
        "type": "command",
        "command": "./scripts/inject-rules.sh"
      }
    ]
  },
  "stop-verifier": {
    "Stop": [
      {
        "type": "command",
        "command": "./scripts/verify-tests.sh"
      }
    ]
  }
}
```

## Supported Lifecycle Events

| Event | Matcher Target | Format Structure | Purpose |
|---|---|---|---|
| `PreToolUse` | Tool name (e.g. `run_command`, `*`) | Grouped (`matcher` + `hooks`) | Gate, block, ask user, or overwrite arguments |
| `PostToolUse` | Tool name | Grouped (`matcher` + `hooks`) | Post-execution auto-fix or diagnostics |
| `PreInvocation` | None (fires every turn) | Flat list of handlers | Inject steps/ephemeral messages into model context |
| `PostInvocation` | None (after turn tools finish) | Flat list of handlers | Force continuation or terminate loop |
| `Stop` | None (on termination) | Flat list of handlers | Prevent premature stop if goals/tests incomplete |

## Tool Matchers

- `"matcher": "*"` or `""`: All tools.
- `"matcher": "run_command"`: Exactly `run_command`.
- `"matcher": "run_command|write_to_file|replace_file_content"`: Multiple tools.
- `"matcher": "browser_.*"`: Regex prefix match.

## Input / Output JSON Contracts

Payloads use camelCase naming (protojson format). Common input fields on stdin:
```json
{
  "conversationId": "ec33ebf9-0cba-4100-8142-c61503f6c587",
  "workspacePaths": ["/home/user/src/repo"],
  "transcriptPath": "/home/user/.gemini/antigravity/transcript.jsonl",
  "artifactDirectoryPath": "/home/user/.gemini/antigravity/artifacts",
  "modelName": "auto"
}
```

### 1. `PreToolUse` Contract
**Input (stdin)**:
```json
{
  "toolCall": {
    "name": "run_command",
    "args": {
      "CommandLine": "rm -rf node_modules"
    }
  },
  "stepIdx": 14,
  ...
}
```

**Output (stdout)**:
```json
{
  "decision": "deny",
  "reason": "Destructive deletion blocked by safety hook.",
  "overwrite": {
    "CommandLine": "npm run clean"
  }
}
```
- `decision`: `"allow"`, `"deny"`, `"ask"`, `"force_ask"`.
- `overwrite`: Top-level dictionary shallow-merged into tool arguments before execution.

### 2. `PreInvocation` Contract (Rule / Reminder Injection)
**Output (stdout)**:
```json
{
  "injectSteps": [
    {
      "ephemeralMessage": "Remember to run `pytest` and verify linting before proposing changes."
    }
  ]
}
```
Supported `injectSteps` items:
- `{"ephemeralMessage": "..."}`: Transient system reminder seen only on the upcoming model turn.
- `{"userMessage": "..."}`: Injected user turn.
- `{"toolCall": {"name": "...", "args": {...}}}`: Pre-emptively queued tool step.

### 3. `Stop` Contract
**Output (stdout)**:
```json
{
  "decision": "continue",
  "reason": "Tests are still failing. Fix them before stopping."
}
```
- `decision: "continue"`: Re-enters the execution loop with `reason` injected.
