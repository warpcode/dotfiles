# Authoring Agent Lifecycle Hooks

Create, configure, and maintain deterministic lifecycle hooks, guardrails, and plugin hooks across Claude Code, GitHub Copilot / VS Code, Google Antigravity, OpenCode, ChatGPT/Codex, Cursor, and Hermes Agent.

Hooks provide **deterministic lifecycle gates, command blockers, auto-formatters, and dynamic context injectors**; consult [Artifact Decision Matrix](artifact-decision-matrix.md) before authoring.

**Rule vs Hook Principle**: Rules *guide* LLM behavior through prompt context; hooks *enforce* behavior through programmatic execution boundaries. Where security, formatting, or strict verification is required, pair rules with hooks.

## Platform Discovery & Matrix

| Platform | Hook Location | Primary Format | Event Model | Handler Types |
|---|---|---|---|---|
| **Claude Code** | `.claude/settings.json`, `~/.claude/settings.json`, plugin `hooks/hooks.json`, skill/agent frontmatter | JSON (`"hooks": { ... }`) | 30+ events (`SessionStart`, `PreToolUse`, `Stop`, etc.) | `command`, `http`, `mcp_tool`, `prompt`, `agent` |
| **Copilot / VS Code** | `.github/hooks/*.json`, `~/.copilot/hooks/`, `.agent.md` frontmatter, plugin `hooks.json` | JSON (`"hooks": { ... }`) | `SessionStart`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `Stop` | `command` (`windows`, `linux`, `osx` overrides) |
| **Antigravity** | `.agents/hooks.json`, `.agent/hooks.json`, `~/.gemini/config/hooks.json`, plugin `hooks.json` | JSON (named keys mapping to events) | `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop` | `command` (protojson stdin, JSON stdout) |
| **OpenCode** | `.opencode/plugins/*.ts`, `~/.config/opencode/plugins/`, `opencode.json` (`"plugin": [...]`) | JS/TS modules exporting async hook functions | `tool.execute.before`, `tool.execute.after`, `session.*`, `shell.env`, `tool` | JS/TS functions, shell via Bun `$` |
| **Codex** | `.codex/hooks.json`, `~/.codex/hooks.json`, `.codex/config.toml` (`[hooks]`) | JSON / TOML | `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `SessionEnd` | Shell scripts (`command`) |
| **Cursor** | `.cursor/hooks.json`, `~/.cursor/hooks.json` | JSON (`"version": 1, "hooks": { ... }`) | `sessionStart`, `beforeSubmitPrompt`, `stop`, tool events | Shell scripts (`command`) via stdin/stdout JSON |
| **Hermes Agent** | `~/.hermes/config.yaml`, `hermes/agent-hooks/` | YAML / Python plugins | `pre_llm_call`, `post_llm_call`, `pre_tool_call`, `post_tool_call`, `session_start`, `session_end` | Python (`register(ctx)`) or shell commands |

### Platform Reference Guides

- `hooks/platforms/claude-code.md`, `hooks/platforms/copilot-vscode.md`, `hooks/platforms/antigravity.md`, `hooks/platforms/opencode.md`, `hooks/platforms/codex.md`, `hooks/platforms/cursor.md`, `hooks/platforms/hermes.md`
- `hooks/simulating-rules.md`: Dynamic context injection and deterministic guardrails on platforms without native glob engines.

## Lifecycle Event Equivalence Map

| Intent | Claude Code | VS Code / Copilot | Antigravity | OpenCode | Codex | Cursor | Hermes |
|---|---|---|---|---|---|---|---|
| **Session Start** | `SessionStart` | `SessionStart` | — | `session.created` | `SessionStart` | `sessionStart` | `session_start` |
| **Pre User Prompt** | `UserPromptSubmit` | — | `PreInvocation` | `tui.prompt.append` | `UserPromptSubmit` | `beforeSubmitPrompt` | `pre_llm_call` |
| **Pre Tool Run** | `PreToolUse` | `PreToolUse` | `PreToolUse` | `tool.execute.before` | `PreToolUse` | `preToolUse` | `pre_tool_call` |
| **Post Tool Run** | `PostToolUse` | `PostToolUse` | `PostToolUse` | `tool.execute.after` | `PostToolUse` | `postToolUse` | `post_tool_call` |
| **Agent Stop/Finish** | `Stop` | `Stop` | `Stop` | `session.idle` | `SessionEnd` | `stop` | `session_end` |
| **Subagent Spawn/Stop** | `SubagentStart`/`Stop` | `SubagentStart`/`Stop` | — | — | — | — | — |

## Standard Hook Recipes & Templates

| Recipe | Lifecycle Event | Primary Purpose | Template |
|---|---|---|---|
| **Security Gate** | `PreToolUse` | Block destructive commands (`rm -rf`, `DROP TABLE`, secret exfiltration) | `templates/hooks/security-gate.json` |
| **Auto-Formatter / Linter** | `PostToolUse` | Run Prettier, Ruff, or Black on modified files | `templates/hooks/auto-formatter.json` |
| **Rule Simulator Hook** | `UserPromptSubmit` / `PreInvocation` | Dynamically inject path-scoped rules from git state | `templates/hooks/rule-simulator-hook.json` |
| **Rule Injector Script** | *(Helper script)* | Shell script that matches path globs and outputs context JSON | `templates/hooks/rule-injector.sh` |
| **Stop Verification Guard** | `Stop` | Run test suite before allowing task completion | `templates/hooks/stop-verifier.json` |
| **Audit Logger** | `PreToolUse` / `PostToolUse` | Append timestamped tool invocations to audit log | `templates/hooks/audit-logger.json` |
| **OpenCode Guard Plugin** | `tool.execute.before` | TypeScript plugin guarding file access and setting env | `templates/hooks/opencode-guard-plugin.ts` |

## Writing Principles & Validation

- Keep hooks fast (<1-2s), idempotent, and path-independent (`${CLAUDE_PROJECT_DIR}`, `$PROJECT_ROOT`).
- Exit `0` + empty stdout = pass-through; exit `2` = hard block with stderr; JSON stdout = structured decisions (`permissionDecision`, `additionalContext`).
- Default to fail-open for advisory linters/injectors and fail-closed (exit `2`) for security gates; always set timeouts (5-30s).

```bash
python3 <skill-dir>/scripts/validate_hooks.py --self-test
python3 <skill-dir>/scripts/validate_hooks.py .github/hooks/
```
