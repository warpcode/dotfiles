# Script Standards & Authoring Rules

Standards for writing helper utilities bundled in skill `scripts/` directories.

---

## Core Invariants

1. **Python as Primary Language**: Write executable scripts in Python targeting the standard library.
2. **Zero External Dependencies**: Standard library only. When dependencies are unavoidable, use `uvx <package>` for ephemeral execution without polluting host environments.
3. **Black Box Execution**: Agents must inspect `--help` to determine arguments and options, never reading script source code into context.
4. **Token-Efficient Output**: Return minimal, parseable output (clean tables, JSON, or direct values). Avoid decorative banners, verbose logs, or excessive padding.

---

## CRUD-Prefixed Naming Taxonomy

Prefix helper scripts with standard CRUD operations to enable clean wildcard permission policies:

| Prefix | Operation Type | Example | Behavior |
|---|---|---|---|
| `get-` | Read single resource | `@scripts/get-profile.py` | Fetches specific resource by ID or key |
| `list-` | Read collection | `@scripts/list-configs.py` | Lists known entities with compact output |
| `search-` | Query / filter | `@scripts/search-logs.py` | Executes targeted search query |
| `create-` | Mutate / create | `@scripts/create-item.py` | Provisions a new resource |
| `update-` | Mutate / edit | `@scripts/update-state.py` | Modifies existing resource |
| `delete-` | Destructive mutate | `@scripts/delete-stack.py` | Deletes resource (requires confirmation) |
| `validate.py` | Self-contained validation | `@scripts/validate.py` | Validates package integrity and compiles assets |

---

## Path Resolution Protocol for Agents

Agents execute shell commands from the workspace root (`CWD`). Never assume `./scripts/` exists at the project root:

1. **Explicit Skill-Directory Path**: Always invoke scripts using the full or relative path to the skill directory:
   ```bash
   python3 <skill-dir>/scripts/<script-name>.py [args]
   # Example: python3 .github/skills/ai-authoring-skills/scripts/validate.py .
   ```
2. **`@scripts/` Notation**: In markdown documentation and skill instruction tables, mark bundled helper scripts as `@scripts/<name>` to signal that they reside inside the skill folder.
3. **No Verbatim Bare Paths in Code Blocks**: In `SKILL.md` usage examples, write `<skill-dir>/scripts/<script-name>` instead of bare `scripts/<script-name>` so LLMs do not copy-paste broken relative paths.

---

## Script Implementation Checklist

- [ ] **Accurate `--help`**: Implement standard `argparse` with clear option descriptions and usage examples.
- [ ] **Deterministic Exit Codes**: Exit `0` on success, `1` on error or invalid arguments.
- [ ] **Self-Test / Demo Mode**: Include an assert-based self-test mode (`--self-test` or `-t`) for automated verification.
- [ ] **Syntax Compilation**: Ensure script compiles cleanly (`python3 -m py_compile`, `bash -n`, or `zsh -n`).
- [ ] **Documented Path Resolution**: Ensure `SKILL.md` specifies `<skill-dir>/scripts/<name>` invocation syntax.

