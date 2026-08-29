# Antigravity CLI (`agy`) Complete Flag Reference

Complete catalog of command-line flags and parameters for `agy` (Antigravity CLI).

---

## 1. Headless & Prompt Execution

| Flag | Short | Default | Description |
|---|---|---|---|
| `--print` / `--prompt` | `-p` | `false` | Run single prompt non-interactively and print response to stdout. |
| `--output-format` | | `text` | Output format for print mode: `text`, `json`, or `stream-json`. |
| `--input-format` | | `text` | Input format for print mode: `text` or `stream-json` (NDJSON per line). |
| `--json-schema` | | `""` | JSON schema string or file path to enforce structured JSON output. |
| `--model` | | configured default | Model alias for the session (e.g. `gemini-3.7-flash-high`, `gemini-3.5-flash-low`). |
| `--effort` | | `high` | Reasoning effort level: `low`, `medium`, `high`. |
| `--mode` | | `default` | Agent execution mode: `accept-edits` (auto file modifications) or `plan` (planning mode). |
| `--agent` | | `default` | Name of custom agent to route execution through. |
| `--print-timeout` | | `5m0s` | Maximum duration to wait for headless prompt completion before aborting. |
| `--dangerously-skip-permissions` | | `false` | Auto-approve all tool permission requests without interactive confirmation prompts. |
| `--disable-slash-commands` | | `false` | Disable slash command and skill expansion during print mode. |

---

## 2. Workspace & Environment

| Flag | Short | Default | Description |
|---|---|---|---|
| `--add-dir` | | `[]` | Add additional directory to workspace context (repeatable). |
| `--sandbox` | | `false` | Run in sandbox mode with restricted terminal and filesystem capabilities. |
| `--log-file` | | default log path | Override CLI log file path. |
| `--new-project` | | `false` | Initialize a new isolated project for the session. |
| `--project` | | `""` | Project ID or project name to associate the session with. |

---

## 3. Session Resumption & Interactive Mode

| Flag | Short | Default | Description |
|---|---|---|---|
| `--continue` | `-c` | `false` | Resume the most recent conversation session. |
| `--conversation` | | `""` | Resume an existing conversation by its UUID. |
| `--prompt-interactive` | `-i` | `false` | Execute initial prompt interactively and keep session open in TUI. |

---

## 4. Environment Variables

| Variable | Description |
|---|---|
| `AGY_CLI_HIDE_LOGO` | Set to `1` or `true` to suppress ASCII banner logo in narrow terminals and logs. |
| `AGY_CLI_DISABLE_ESCAPE_SEQUENCE_OPTIMIZATIONS` | Disables terminal dirty-rectangle and diffing optimizations. |
| `GEMINI_API_KEY` | Direct API key authentication fallback for Google Gemini endpoints. |

