# OpenCode Custom Commands Reference

Source: <https://opencode.ai/docs/commands/>

OpenCode custom commands are parameterized prompt templates invoked via `/name`. They automate workflows, enforce guidelines, and can delegate execution to isolated child subtasks.

---

## 1. Discovery Paths & Formats

### Markdown Commands
- **Project Scope**: `<project-root>/.opencode/commands/<name>.md`
- **Global / User Scope**: `~/.config/opencode/commands/<name>.md`
- **Precedence**: Project-level commands override global commands on name collisions.
- **Invocation**: Derived directly from the file stem (e.g. `audit.md` $\rightarrow$ `/audit`).

### JSON Configuration (`opencode.json` / `opencode.jsonc`)
Commands can also be defined in `opencode.json`:
```jsonc
{
  "command": {
    "test-runner": {
      "description": "Run tests with coverage and analyze errors",
      "template": "Run test suite and suggest fixes: $ARGUMENTS",
      "agent": "build",
      "model": "anthropic/claude-3-5-sonnet-20241022",
      "subtask": true
    }
  }
}
```

---

## 2. YAML Frontmatter Schema

```yaml
---
description: string                 # Command description shown in autocomplete menu
agent: string                       # Target agent (e.g. build, plan, or custom agent in .opencode/agents/)
model: string                       # Provider/model override (e.g. anthropic/claude-3-5-sonnet, google/gemini-2.5-flash)
subtask: boolean                    # If true, runs in an isolated child session context
---
```

Tool permissions are inherited from the assigned `agent` or the project configuration in `opencode.json`.

---

## 3. Argument Parsing & Substitution Rules

- **`$ARGUMENTS`**: Injects the complete unparsed argument string.
- **Positional Parameters (`$1`, `$2`, ..., `$n`)**: Whitespace-delimited positional arguments.
  - **Greedy Highest Parameter Rule**: The highest-numbered positional placeholder in the template consumes its position **and all remaining arguments**. (e.g. with `$1` and `$2`, `/cmd a b c d` sets `$1="a"` and `$2="b c d"`).
  - If only `$1` is present, it receives the entire argument list.
- **Fallback Appending**: If neither `$ARGUMENTS` nor `$1..$n` are found in the template, OpenCode automatically appends any user-supplied arguments to the end of the prompt.
- **Quoting**: Arguments wrapped in single or double quotes are treated as a single whitespace-preserving argument (quotes are automatically stripped).

---

## 4. Dynamic Context & Subtask Semantics

- **Shell Output (`!<cmd>`)**: Prefixing a command with `!` (e.g. `!git diff`, `!pytest`) executes the shell command in the project root and injects its stdout into the prompt before model evaluation.
- **File Mentions (`@<path>`)**: Fuzzy-resolves and inlines file contents (e.g. `@src/auth/jwt.ts`, `@package.json`).
- **`subtask: true` Execution**: Spawns an isolated subagent. Verbose tool outputs and intermediate turns stay inside the subtask; only the synthesized final report is returned to the main chat session.
