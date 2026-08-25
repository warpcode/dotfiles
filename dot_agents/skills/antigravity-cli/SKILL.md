---
name: antigravity-cli
description: >
  Execute tasks, orchestrate subagents, extract structured JSON, query models, and
  manage MCP servers or plugins using the Google Antigravity CLI (`agy`). Use this
  skill when the user says "run with agy", "execute prompt with antigravity",
  "agy headless", "agy models", "agy agents", "agy mcp", "agy plugins", "agy print mode",
  wants to run a prompt using a specific model/effort via the agy CLI, extract schema-enforced
  JSON output, or automate multi-turn headless agent pipelines with Antigravity.
---

# Antigravity CLI (`agy`) Execution & Automation

Use `agy` to execute prompts non-interactively, route tasks to specific AI models and subagents, enforce structured JSON schemas, and manage MCP servers and plugins.

---

## ⛔ CRITICAL RULE: NO INTERACTIVE TUI

**NEVER run `agy` without `-p` / `--print` or a non-interactive subcommand.**
Bare `agy` launches an interactive Terminal User Interface (TUI) that blocks automated execution waiting for user keystrokes.

- ❌ `agy` (PROHIBITED: Launches interactive TUI)
- ✅ `agy -p "prompt"` (Headless single-shot execution)
- ✅ `agy models` (Non-interactive subcommand)
- ✅ `agy mcp list` (Non-interactive subcommand)

---

## Pre-Execution & Discovery

Run discovery commands before executing prompts to inspect configured models, active agents, and MCP servers:

```bash
# List available model aliases (e.g. gemini-3.7-flash-high, gemini-3.5-flash-low)
agy models

# List available custom agents
agy agents

# List configured MCP servers
python3 scripts/list-mcp-servers.py
# Or raw CLI: agy mcp list
```

For the complete list of flags and environment variables, read [references/flags.md](references/flags.md).

---

## Core Execution Commands

### 1. Headless Single-Shot Execution

Execute a prompt non-interactively using the target model and reasoning effort:

```bash
agy --model "<model-alias>" --effort <low|medium|high> -p "<prompt>"
```

**Common Flags for Automation:**
- `--dangerously-skip-permissions`: Auto-approve tool execution for headless scripts and CI/CD pipelines.
- `--mode accept-edits`: Allow the agent to make file changes directly without confirmation pauses.
- `--add-dir <path>`: Mount additional directory context into the workspace.
- `--disable-slash-commands`: Prevent accidental slash-command expansion in raw input text.

### 2. Structured JSON Output Extraction

To enforce structured output conforming to a JSON Schema, pass `--json-schema` and `--output-format json`:

```bash
agy --output-format json \
    --json-schema '{"type":"object","properties":{"summary":{"type":"string"},"items":{"type":"array","items":{"type":"string"}}},"required":["summary","items"]}' \
    -p "<prompt>"
```

**Output Envelope Schema (`--output-format json`):**
```json
{
  "conversation_id": "UUID string",
  "status": "SUCCESS | ERROR",
  "response": "Model response string",
  "structured_output": { /* conforms to requested schema */ },
  "duration_seconds": 2.45,
  "num_turns": 1,
  "usage": {
    "input_tokens": 12000,
    "output_tokens": 85,
    "thinking_tokens": 40,
    "total_tokens": 12085
  }
}
```

To extract `.structured_output` directly without manual `jq` parsing, use the bundled helper:
```bash
./scripts/get-structured-output.sh --schema '{"type":"object","properties":{"score":{"type":"number"}},"required":["score"]}' --prompt "Rate code quality 1-10"
```

### 3. Routing to Custom Subagents

Route prompt execution to a specific defined agent:

```bash
agy --agent <agent-name> --dangerously-skip-permissions -p "<prompt>"
```

### 4. Resuming Existing Conversations

```bash
# Continue the most recent session
agy -c -p "<follow-up prompt>"

# Resume a specific conversation ID
agy --conversation "<UUID>" -p "<follow-up prompt>"
```

---

## MCP Server Administration (`agy mcp`)

Manage Model Context Protocol servers in user configuration:

```bash
# List servers as JSON
./scripts/list-mcp-servers.py

# Add stdio server
agy mcp add <name> <command> [args...]

# Add HTTP server with authentication
agy mcp add --header "Authorization: Bearer <token>" <name> <url>

# Enable / Disable server
agy mcp enable <name>
agy mcp disable <name>

# ⚠ WRITE: Permanently remove server configuration
agy mcp remove <name>
```

For detailed argument syntax, environment variable passing (`--env`), and containerized server examples, read [references/mcp-and-plugins.md](references/mcp-and-plugins.md).

---

## Plugin Administration (`agy plugin`)

```bash
# List installed plugins
agy plugin list

# Validate plugin definition before installing
agy plugin validate /path/to/plugin-dir

# Install plugin
agy plugin install /path/to/plugin-dir

# Enable / Disable plugin
agy plugin enable <name>
agy plugin disable <name>

# ⚠ WRITE: Uninstall plugin
agy plugin uninstall <name>
```

---

## Common Patterns

### Pattern 1: Fast Extraction with Flash Model
**Input:** Parse a log file and extract error counts using `gemini-3.5-flash-low`.
```bash
agy --model "gemini-3.5-flash-low" --effort low \
    --output-format json \
    --json-schema '{"type":"object","properties":{"error_count":{"type":"integer"},"errors":{"type":"array","items":{"type":"string"}}},"required":["error_count","errors"]}' \
    -p "Analyze syslog and count errors: $(head -n 50 /var/log/syslog)" \
    | jq '.structured_output'
```

### Pattern 2: Headless Code Modification with Tool Permissions
**Input:** Run an agent to fix TypeScript lint errors automatically in the workspace.
```bash
agy --model "gemini-3.7-flash-high" \
    --mode accept-edits \
    --dangerously-skip-permissions \
    -p "Run eslint and fix all auto-fixable lint errors in src/"
```

### Pattern 3: Multi-Turn NDJSON Streaming
For streaming real-time event updates and multi-turn piping via standard I/O, read [references/stream-json.md](references/stream-json.md).

---

## Bundled Scripts

Scripts are executable black boxes. Run `--help` on any script to view options rather than reading source code.

| Script | Purpose |
|---|---|
| `scripts/list-mcp-servers.py` | Query and parse `agy mcp list` into structured JSON (`--enabled-only`, `--disabled-only`). |
| `scripts/get-structured-output.sh` | Execute prompt with schema enforcement and return extracted JSON (`--schema`, `--prompt`, `--model`, `--effort`, `--agent`, `--skip-permissions`). |

---

## What NOT to Do

- **MUST NOT invoke bare `agy`**: It launches an interactive TUI which hangs automated scripts; use `agy -p` or subcommands instead.
- **MUST NOT guess model aliases**: Run `agy models` first to verify valid model identifiers.
- **MUST NOT remove MCP servers or uninstall plugins without user approval**: `mcp remove` and `plugin uninstall` are irreversible mutations marked `⚠ WRITE`.
- **MUST NOT omit `--dangerously-skip-permissions` in non-interactive tool workflows**: Without this flag, tool use halts waiting for stdin confirmation in headless mode.

---

## Exit Criteria & Verification

- Non-interactive commands exit with status `0` on successful completion.
- JSON output includes `"status": "SUCCESS"`.
- On non-zero exit codes, inspect stderr or run `agy --output-format text -p "<prompt>"` to diagnose errors.
