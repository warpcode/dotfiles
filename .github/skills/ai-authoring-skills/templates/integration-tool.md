---
name: <tool>-<domain>
description: >
  Executable patterns to control/query [Tool/Service]. Use when interacting
  with [API/protocol/CLI].
---

# Integration / tool-bound template

Use for wrapping an external CLI/API/MCP server.
Scripts are black boxes: run `--help` first; never read source to guess flags.

### Pre-Execution Requirements
- Required env: [VARS] — resolve via the secrets mechanism; never hardcode.
- Discovery first: inspect available operations before acting (prevents
  guessing endpoint/command names).

### Commands & Execution Rules

#### 1. Connection Check
```bash
[verify connectivity command]
```

#### 2. Actions
1. Construct payload ([format]).
2. Execute via `[exact command syntax]`.

### What NOT to Do
- No destructive/remote updates without explicit human confirmation — these
  are irreversible, so confirmation is the only undo.
- No plaintext secrets in files or logs — they outlive rotation and leak via
  backups.

### Error Handling
- Auth failures: [re-auth path]. Unreachable target: report and stop.

### Exit Criteria
- Response `200 OK` / exit status `0`, or a documented failure.
