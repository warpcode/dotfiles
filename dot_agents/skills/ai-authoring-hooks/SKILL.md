---
name: ai-authoring-hooks
description: >
  Create, modify, configure, or debug custom lifecycle hooks, guardrails, and
  plugin hooks across Claude Code (.claude/settings.json, hooks/hooks.json),
  GitHub Copilot / VS Code (.github/hooks/*.json, .agent.md), Google Antigravity
  (.agents/hooks.json), OpenCode (.opencode/plugins/*.ts, opencode.json),
  ChatGPT/Codex (.codex/hooks.json, config.toml), Cursor (.cursor/hooks.json),
  and Hermes Agent (~/.hermes/config.yaml, agent-hooks/). Use when the user says
  "create a hook", "add a PreToolUse hook", "block dangerous commands", "run linter
  after edits", "simulate rules with hooks", asks about hook events, matchers,
  exit codes, JSON input/output schemas, additionalContext injection, or wants to
  enforce deterministic safety policies.
---

# Authoring Agent Lifecycle Hooks

Create, configure, and maintain deterministic lifecycle hooks, guardrails, and
plugin hooks across Claude Code, GitHub Copilot / VS Code, Google Antigravity,
OpenCode, ChatGPT/Codex, Cursor, and Hermes Agent.

Hooks are executable shell scripts, HTTP endpoints, LLM prompts, or TypeScript
plugins that fire synchronously or asynchronously at defined lifecycle points in
an agent's execution loop. Unlike prompt-based rules (which provide probabilistic
guidance), hooks provide **hard, deterministic boundaries**, automated fixes,
audit logging, and dynamic context injection.

## When to use

- The user says "create a hook", "add a pre-tool hook", "make a hook for X",
  "block dangerous commands", or "run linter after every edit".
- They want to configure hook events (`PreToolUse`, `PostToolUse`, `SessionStart`,
  `Stop`, `PreInvocation`, etc.).
- They want to enforce security guardrails (e.g. deny `rm -rf`, `DROP TABLE`, or
  protect `.env` files).
- They want to simulate path-scoped or dynamic rules on platforms lacking native
  rule engines (e.g. Codex, OpenCode).
- They need to configure event matchers, `if` filter syntax, exit codes, or JSON
  stdin/stdout contracts.
- They want to inject dynamic runtime context into the model via `additionalContext`
  or `ephemeralMessage`.
- They are debugging why a hook is failing, timing out, or not activating.

## Decision Matrix: Hooks vs Other Artifacts

| Requirement | Artifact | Primary Skill |
|---|---|---|
| Reusable multi-step SOP, runbook, or CLI tool guide | **Skill** (`SKILL.md`) | `ai-authoring-skills` |
| Interactive user shortcut or parameterized slash command | **Command** (`/name`) | `ai-authoring-commands` |
| Persistent behavioral prompt instructions & style guidance | **Rule** (`rules/`, `AGENTS.md`) | `ai-authoring-rules` |
| Delegated persona in isolated context with dedicated tools | **Subagent** (`.agent.md`, `<name>.md`) | `ai-authoring-agents` |
| **Deterministic gate, command blocker, auto-formatter, or dynamic context injector** | **Hook** (`hooks.json`, `.github/hooks/`, plugins) | `ai-authoring-hooks` |

**Rule vs Hook Principle**: Rules *guide* LLM behavior through prompt context;
hooks *enforce* behavior through programmatic execution boundaries. Where security,
formatting, or strict verification is required, pair rules with hooks.

## Platform Discovery & Matrix

| Platform | Hook Location | Primary Format | Event Model | Handler Types |
|---|---|---|---|---|
| **Claude Code** | `.claude/settings.json`, `~/.claude/settings.json`, plugin `hooks/hooks.json`, skill/agent frontmatter | JSON (`"hooks": { ... }`) | 30+ events (`SessionStart`, `PreToolUse`, `Stop`, etc.) | `command` (shell/exec), `http`, `mcp_tool`, `prompt`, `agent` |
| **Copilot / VS Code** | `.github/hooks/*.json`, `~/.copilot/hooks/`, `.agent.md` frontmatter, plugin `hooks.json` | JSON (`"hooks": { ... }`) | `SessionStart`, `PreToolUse`, `PostToolUse`, `PreCompact`, `SubagentStart`, `Stop` | `command` (with `windows`, `linux`, `osx` overrides) |
| **Antigravity** | `.agents/hooks.json`, `.agent/hooks.json`, `~/.gemini/config/hooks.json`, plugin `hooks.json` | JSON (named keys mapping to events) | `PreToolUse`, `PostToolUse`, `PreInvocation`, `PostInvocation`, `Stop` | `command` (receives protojson stdin, returns JSON stdout) |
| **OpenCode** | `.opencode/plugins/*.ts`, `~/.config/opencode/plugins/`, `opencode.json` (`"plugin": [...]`) | JS/TS modules exporting async hook functions | `tool.execute.before`, `tool.execute.after`, `session.*`, `shell.env`, `tool` | JS/TS functions, shell via Bun `$` |
| **Codex** | `.codex/hooks.json`, `~/.codex/hooks.json`, `.codex/config.toml` (`[hooks]`) | JSON / TOML | `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `SessionEnd` | Shell scripts (`command`) |
| **Cursor** | `.cursor/hooks.json`, `~/.cursor/hooks.json` | JSON (`"version": 1, "hooks": { ... }`) | `sessionStart`, `beforeSubmitPrompt`, `stop`, tool events | Shell scripts (`command`) via stdin/stdout JSON |
| **Hermes Agent** | `~/.hermes/config.yaml`, `hermes/agent-hooks/` | YAML / Python plugins | `pre_llm_call`, `post_llm_call`, `pre_tool_call`, `post_tool_call`, `session_start`, `session_end` | Python (`register(ctx)`) or shell commands in config |

### Platform Reference Guides

For exhaustive schema, input/output structures, and platform nuances, consult the local references and upstream documentation:

- [Claude Code Reference](references/platforms/claude-code.md) — Upstream: [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks#hooks-reference)
- [Copilot / VS Code Reference](references/platforms/copilot-vscode.md) — Upstream: [VS Code Agent Hooks](https://code.visualstudio.com/docs/agent-customization/hooks)
- [Google Antigravity Reference](references/platforms/antigravity.md) — Upstream: [Antigravity Hooks Guide](https://antigravity.google/docs/hooks/)
- [OpenCode Reference](references/platforms/opencode.md) — Upstream: [OpenCode Plugins Guide](https://opencode.ai/docs/plugins/)
- [ChatGPT / Codex Reference](references/platforms/codex.md) — Upstream: [ChatGPT Agent Configuration](https://learn.chatgpt.com/docs/agent-configuration/rules)
- [Cursor Reference](references/platforms/cursor.md) — Upstream: [Cursor Agent Hooks](https://cursor.com/docs/agent-customization/hooks)
- [Hermes Agent Reference](references/platforms/hermes.md) — Upstream: [Hermes Lifecycle Hooks](https://hermes-agent.nousresearch.com/docs/developer-guide/lifecycle-hooks)

## Lifecycle Event Equivalence Map

| Intent | Claude Code | VS Code / Copilot | Antigravity | OpenCode | Codex | Cursor | Hermes |
|---|---|---|---|---|---|---|---|
| **Session Start** | `SessionStart` | `SessionStart` | — | `session.created` | `SessionStart` | `sessionStart` | `session_start` |
| **Pre User Prompt** | `UserPromptSubmit` | — | `PreInvocation` | `tui.prompt.append` | `UserPromptSubmit` | `beforeSubmitPrompt` | `pre_llm_call` |
| **Pre Tool Run** | `PreToolUse` | `PreToolUse` | `PreToolUse` | `tool.execute.before` | `PreToolUse` | `preToolUse` | `pre_tool_call` |
| **Post Tool Run** | `PostToolUse` | `PostToolUse` | `PostToolUse` | `tool.execute.after` | `PostToolUse` | `postToolUse` | `post_tool_call` |
| **Agent Stop/Finish** | `Stop` | `Stop` | `Stop` | `session.idle` | `SessionEnd` | `stop` | `session_end` |
| **Subagent Spawn** | `SubagentStart` | `SubagentStart` | — | — | — | — | — |
| **Subagent Finish** | `SubagentStop` | `SubagentStop` | — | — | — | — | — |

## Simulating Rules with Hooks

Platforms such as OpenAI Codex and OpenCode support static instructions (`AGENTS.md`)
or static file arrays, but lack native runtime path-scoped or model-decided rule
activation engines. Hooks solve this by providing dynamic rule simulation.

See [Simulating Rules Guide](references/simulating-rules.md) for full architectural patterns:

1. **Dynamic Context Injection (Soft Rules)**:
   - Trigger at `UserPromptSubmit` / `SessionStart` / `PreInvocation` / `pre_llm_call`.
   - Hook script inspects active files, current git diff, or prompt content.
   - Script scans `.github/instructions/` or `.agents/rules/` for matching globs.
   - Injects rule markdown into model context via `additionalContext` (Claude/VS Code) or `ephemeralMessage` (Antigravity).
2. **Deterministic Guardrails (Hard Rules)**:
   - Trigger at `PreToolUse` / `tool.execute.before` / `pre_tool_call`.
   - Script intercepts command lines or file paths before execution.
   - Evaluates forbidden actions (e.g. modifying protected branches, reading secrets).
   - Hard blocks with `deny` decision or throws error with explicit guidance.

## Standard Hook Recipes & Templates

Select the closest recipe template from `templates/`:

| Recipe | Lifecycle Event | Primary Purpose | Template |
|---|---|---|---|
| **Security Gate** | `PreToolUse` | Block destructive commands (`rm -rf`, `DROP TABLE`, secret exfiltration) | `templates/security-gate.json` |
| **Auto-Formatter / Linter** | `PostToolUse` | Run Prettier, Ruff, or Black on modified files | `templates/auto-formatter.json` |
| **Rule Simulator Hook** | `UserPromptSubmit` / `PreInvocation` | Dynamically inject path-scoped rules from git state | `templates/rule-simulator-hook.json` |
| **Rule Injector Script** | (Helper script) | Shell script that matches path globs and outputs context JSON | `templates/rule-injector.sh` |
| **Stop Verification Guard** | `Stop` | Run test suite before allowing task completion | `templates/stop-verifier.json` |
| **Audit Logger** | `PreToolUse` / `PostToolUse` | Append timestamped tool invocations to audit log | `templates/audit-logger.json` |
| **OpenCode Guard Plugin** | `tool.execute.before` | TypeScript plugin guarding file access and setting env | `templates/opencode-guard-plugin.ts` |

## Writing & Design Principles

1. **Fast and Lightweight**: Hooks execute synchronously in the critical path. Keep
   checks fast (<1-2s). Heavy processes (e.g. full integration test suites) belong
   in `Stop` hooks or background tasks, not on every tool call.
2. **Deterministic Exit Codes & JSON**:
   - Exit code `0` + empty output = Neutral pass-through (normal execution continues).
   - Exit code `2` = Hard block with stderr context delivered to the model.
   - JSON output = Structured decisions (`permissionDecision`, `additionalContext`, `stopReason`).
3. **Idempotent Handlers**: Tool hooks may fire multiple times per turn. Ensure
   formatters and scripts are idempotent and do not corrupt partial edits.
4. **Token Preservation**: Summarize feedback. When a hook injects context or reports
   a linter failure, pass concise line references and errors rather than full logs.
5. **Path Independence**: Use standard root placeholders (`${CLAUDE_PROJECT_DIR}`,
   `$PROJECT_ROOT`, or relative project paths) instead of hardcoding absolute home paths.

## Workflows

### 1. Creation Workflow

1. Identify the goal: Gating, auto-formatting, rule simulation, verification, or logging.
2. Select the target platform(s) and determine file location (`.github/hooks/*.json`,
   `.claude/settings.json`, `.agents/hooks.json`, `.opencode/plugins/`, etc.).
3. Choose the appropriate lifecycle event from the Equivalence Map.
4. Select and copy a template from `templates/`.
5. Implement matcher filters (`matcher`, `if` conditions) to avoid unnecessary spawns.
6. Write or configure the handler script in `scripts/` or project hooks dir.
7. Validate using `python3 scripts/validate.py <path-to-hook-file-or-dir>`.
8. Test by triggering the agent in a test session and observing behavior.

### 2. Validation Workflow

Validate all hook configuration files before deployment:

```bash
# Self-test validator
python3 scripts/validate.py --self-test

# Validate specific hook config or directory
python3 scripts/validate.py .github/hooks/
python3 scripts/validate.py .agents/hooks.json
python3 scripts/validate.py .claude/settings.json
```

The validator checks:
- Valid JSON / YAML syntax.
- Valid platform-specific event names and structure.
- Matcher syntax and regex validity.
- Referenced script paths exist and have executable permissions.
- Handler properties (`type: "command"`, `timeout`, OS overrides).
