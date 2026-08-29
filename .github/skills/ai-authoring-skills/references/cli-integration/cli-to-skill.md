# CLI-to-Skill Workflow

Produce well-scoped, token-efficient agent skills from CLI commands and scripts. The output may be one skill or several, with optional wrapper scripts, depending on the CLI's complexity and decomposition decisions.

---

## Workflow Overview

```
Phase 1: Discovery      → Build a complete picture of what the CLI can do
Phase 2: Analysis       → Classify operations and find efficiency opportunities
Phase 3: Decomposition  → Decide: how many skills, read/write split, scripts
Phase 4: Authoring      → Write SKILL.md, wrapper scripts, reference files
```

Do not skip phases. Decomposition decisions made without completing discovery produce skills that miss useful flags or fail on edge cases.

---

## Phase 1: Discovery

Run every applicable step. Build a **CLI Profile** before moving to Phase 2.

### 1.1 Built-in Help

```bash
<cmd> --help          # standard long form
<cmd> -h              # short form (some CLIs only respond to this)
<cmd> help            # subcommand form (git, gh, docker, etc.)
```

If the top-level help lists **subcommands**, enumerate them, then run:

```bash
<cmd> <subcommand> --help        # for every subcommand listed
<cmd> <subcommand> <sub> --help  # if subcommands have their own subcommands
```

### 1.2 Man Page & Online Docs

```bash
man <cmd>
man <cmd>-<subcommand>
```

Search for official docs (official site manual, GitHub README, package manager docs). Fetch the index and primary subcommand pages.

### 1.3 Version

```bash
<cmd> --version
<cmd> -v
```

### 1.4 CLI Profile Template (complete before Phase 2)

```
CLI:          <name> <version>
Type:         simple (no subcommands) | compound (has subcommands)
Subcommands:  [list] | n/a
Help source:  --help | man | online | none found
Docs URL:     <url> | not found
Output formats available: json | plain | csv | other
Auth required: yes (<method>) | no
```

---

## Phase 2: Analysis

### 2.1 Classify Each Subcommand

For each subcommand (or operation mode), assign every dimension:

| Dimension | Values | Decision impact |
|---|---|---|
| **Domain** | e.g. `pull-request`, `issue`, `repo` | Determines skill split |
| **Operation type** | `read` / `write` / `both` | Drives read/write split |
| **Output format** | `json`, `plain`, `csv`, `none` | Token efficiency |
| **Bulk-capable** | `yes` / `no` | Script opportunity |
| **Destructive** | `yes` / `no` | Safety constraint in skill |

- **Read operations** (never mutate state): list, get, view, show, diff, status, log, search, inspect, describe, export  
- **Write operations** (mutate state): create, update, delete, edit, merge, close, reopen, push, assign, enable, disable

### 2.2 Find Machine-Readable Output Flags

Prefer machine-readable output in skills — it eliminates colour codes, table borders, and human-centric padding that waste tokens. Look for:

```bash
--json                  # gh, many modern CLIs
--format=json           # alternative style
--output json           # kubectl, azure cli
-o json                 # helm, kubectl shorthand
--quiet / -q            # suppress progress noise
--no-color / --plain    # strip ANSI codes when JSON unavailable
```

### 2.3 Identify Bulk-Action & Script Opportunities

A **wrapper script** is warranted when:
- The task requires ≥ 2 sequential invocations (collapses N tool calls into 1)
- Output must be filtered/reformatted before the LLM can use it
- Pagination must be handled (`--limit` loops or cursor traversal)
- Common composite pattern or bulk operation over N items exists

---

## Phase 3: Decomposition Decisions

> For detailed heuristics and worked examples, read [`decomposition.md`](file:///home/jase/src/dotfiles/.github/skills/ai-authoring-skills/references/cli-integration/decomposition.md).

### 3.1 How Many Skills?

- **Simple CLI (no subcommands)**: One skill.
- **Compound CLI**: Split by functional domain if activating a combined skill loads >40% irrelevant context for most tasks (e.g. `gh-pr`, `gh-issue`, `gh-repo`). Keep combined if total content fits under ~250 lines.

### 3.2 Read/Write Split

Split into separate `read` and `write` skills when:
- The workflow requires explicit read-only restriction (audit/triage agents)
- Write operations require human confirmation in the target environment
- If in doubt, keep combined and mark destructive operations with a `⚠ WRITE` tag.

---

## Phase 4: Authoring

1. Apply `ai-authoring-prompts` rules to all LLM-facing instructions.
2. Follow `templates/integration-tool.md` for skill layout.
3. For wrapper scripts, follow the header conventions and patterns in [`script-patterns.md`](file:///home/jase/src/dotfiles/.github/skills/ai-authoring-skills/references/cli-integration/script-patterns.md).
4. Run validation: `python3 scripts/validate.py <skill-dir>`.
