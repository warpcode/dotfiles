# Claude Code skill reference

Source: <https://code.claude.com/docs/en/skills>

## Locations & discovery

- Personal: `~/.claude/skills/<name>/SKILL.md`
- Project: `.claude/skills/<name>/SKILL.md`
- Plugin: `<plugin>/skills/<name>/SKILL.md`

In Claude Code, the command name defaults to the directory name; `name` serves as the display title.

## Recognized frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `when_to_use` | No | Additional trigger phrases appended to the activation index |
| `argument-hint` | No | Autocomplete hint string shown in chat input (e.g. `[issue-number] [flags]`) |
| `arguments` | No | Array of named argument specs or schema definition for `$name` substitutions |
| `disable-model-invocation` | No | `true` = explicit manual slash invocation only (`/name`), hidden from automatic model activation |
| `user-invocable` | No | `false` = hidden from `/` autocomplete menu (model auto-activation only) |
| `allowed-tools` | No | Turn-scoped pre-approved tool grants (e.g. `Bash(git *)`, `FileEdit`, `GlobTool`) |
| `disallowed-tools` | No | Tools removed/blocked from the tool pool while the skill is active |
| `model` | No | Model override while the skill is executing (e.g. `claude-3-5-sonnet-20241022`, `fast`, `sonnet`, `opus`) |
| `effort` | No | Reasoning/thinking effort level override (`low`, `medium`, `high`, `max` or numeric budget) |
| `context` | No | Set to `fork` to execute the skill in an isolated subagent context |
| `agent` | No | Custom subagent type/name to execute the skill when `context: fork` is set |
| `background` | No | `true` = run the forked skill asynchronously in the background |
| `hooks` | No | Lifecycle hooks registered on invocation (e.g. `PreToolUse`, `PostToolUse`) |
| `paths` | No | Glob pattern or list of patterns gating automatic activation to matching files |
| `shell` | No | Shell environment for injected commands: `bash` (default) or `powershell` |
| `license` | No | License identifier (agentskills.io open standard) |
| `compatibility` | No | Environment, runtime, and OS prerequisites (max 500 chars) |
| `metadata` | No | Arbitrary string-to-string map for versioning, tags, or author |

### Frontmatter examples

**Workflow with tool grants, model override, and argument hints:**

```yaml
---
argument-hint: "[branch-name] [--dry-run]"
arguments:
  - name: branch
    description: Target release branch
    required: true
allowed-tools:
  - "Bash(git *)"
  - "Bash(gh pr *)"
  - FileEdit
disallowed-tools:
  - Bash(rm *)
model: claude-3-5-sonnet-20241022
effort: high
paths:
  - "src/**/*.ts"
  - "package.json"
license: MIT
compatibility: "requires gh CLI >= 2.40"
metadata:
  author: dev-infra
  version: "2.1.0"
  category: git-workflow
---
```

**Subagent execution (isolated context):**

```yaml
---
context: fork
agent: code-reviewer
background: true
disable-model-invocation: true
user-invocable: true
shell: bash
metadata:
  author: qa-team
  version: "1.0.0"
---
```

## Body features & substitutions

- **Dynamic context injection**: `` !`command` `` executes the command in the shell and injects stdout into the prompt before the turn runs.
- **Argument substitutions**: `$ARGUMENTS` (full argument string), `$1`, `$2`, `$N` (positional arguments), `$@` (all positional arguments).
- **Path substitutions**: `${CLAUDE_SKILL_DIR}` (directory containing the skill), `${CLAUDE_PROJECT_DIR}` (project root directory), `${CLAUDE_SESSION_ID}`.

## Portability

Only standard fields (`license`, `compatibility`, `metadata`, `allowed-tools`) survive outside Claude Code on generic agentskills.io runners; proprietary Claude Code keys may cause warnings or fail strict packaging on other platforms.

