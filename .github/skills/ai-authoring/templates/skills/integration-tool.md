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

### Script-First Design (author before the command list)

**Gather first, then act.** A 1-to-1 wrapper per tool operation is the **floor**,
not the goal: it hands the orchestration burden back to the agent, which then
re-derives it at runtime — hundreds of calls, inconsistent, invisible to review.

Workflow shape: **GATHER (one script) → REASON (agent) → ACT (one confirmed call).**

**Gather contract** — the facts that must be established before any action:

| Fact needed to act safely | Retrieved by | Gap if unavailable |
|---|---|---|
| [identity: endpoint, resource ids, account] | | |
| [current state] | | |
| [verification: health, permissions, version] | | |

| Workflow step | Question it answers | Script | Output schema |
|---|---|---|---|
| 1. Gather | | `<skill-dir>/scripts/<name>.py --flags` | `{...}` |
| 2. Reason | *(agent judgement)* | — | — |
| 3. Act | | `<skill-dir>/scripts/<name>.py --apply` | `{...}` |

- Group operations by the single question they answer. ≥2 operations serving one
  question ⇒ one composite script (`-bundle` / `-rollup` / `-audit` suffix).
- Resolve shared parameters (owner, repo, ids, endpoints) **once** at the top.
- Fetch everything before deriving anything, so the agent cannot correlate two
  reads taken at different instants.
- Unretrievable facts become explicit gap fields — never a silent `{}`, `[]`, or
  `false` that reads as "nothing wrong here".
- Emit dense JSON to stdout; progress to stderr; large payloads to `--out <dir>`.
- Read-only by default. Mutations behind an explicit flag plus user approval.
- No shell loops, `jq` chains, or inline `python3 -c` in this file.

### Bundled Scripts

| Script | Purpose | Output | Run when |
|---|---|---|---|
| `@scripts/<name>.py` | [question] | [schema] | [condition] |

### Commands & Execution Rules

#### 1. Connection Check
```bash
[single script invocation that verifies connectivity — not the raw auth call]
```

#### 2. Actions
1. Run `<skill-dir>/scripts/<name>.py --<flag> <value>` → returns [schema].
2. Agent judgment only: [what needs reasoning].

### What NOT to Do
- No destructive/remote updates without explicit human confirmation — these
  are irreversible, so confirmation is the only undo.
- No plaintext secrets in files or logs — they outlive rotation and leak via
  backups.
- No hand-orchestrated call chains — if the agent needs more than one invocation
  per step, the bundle script is missing. See
  `@references/cli-integration/script-patterns.md` (Pattern 0).

### Error Handling
- Auth failures: [re-auth path]. Unreachable target: report and stop.
- Script errors name the failing sub-call; never swallow them. A bundle that
  reports success after a partial failure produces confident wrong answers.

### Exit Criteria
- Response `200 OK` / exit status `0`, or a documented failure.
- Exit code carries the verdict — the agent reads the code, it does not
  re-derive the outcome from raw output.
