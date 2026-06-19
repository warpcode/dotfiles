---
name: cli-to-skill
description: >
  Analyse a CLI command or script and produce one or more Claude skills for it.
  Use this skill whenever the user says things like "create a skill for X CLI",
  "turn this command into a skill", "skill-ify this tool", "I want Claude to use
  X", "document this CLI for an LLM", or hands you a CLI binary/script and
  asks how an agent should use it. Also trigger when designing any agent workflow
  that will shell out to an external CLI tool — even if the user does not use the
  word "skill". If you are figuring out how an LLM should invoke a command-line
  tool, this skill applies.
---

# CLI-to-Skill

> **Dependencies (load when you reach each phase):**
> - **Phase 4 (Authoring):** Load `/mnt/skills/user/prompt-engineering/SKILL.md` and apply all rules before writing any LLM-facing content.
> - **Phase 4 (Authoring):** Consult `/mnt/skills/examples/skill-creator/SKILL.md` for SKILL.md anatomy, progressive disclosure rules, and packaging.

Produce well-scoped, efficient Claude skills from CLI commands and scripts. The output may be one skill or several, with optional wrapper scripts, depending on the CLI's complexity and your decomposition decisions in Phase 3.

---

## Workflow

```
Phase 1: Discovery      → build a complete picture of what the CLI can do
Phase 2: Analysis       → classify operations and find efficiency opportunities
Phase 3: Decomposition  → decide: how many skills, read/write split, scripts
Phase 4: Authoring      → write SKILL.md(s), wrapper scripts, reference files
```

Do not skip phases. Decomposition decisions made without completing discovery produce skills that miss useful flags or fail on edge cases.

---

## Phase 1: Discovery

Run every applicable step. Build a **CLI Profile** as you go (template at end of this phase).

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

Do not assume you have seen all subcommands from the top-level list alone — some CLIs hide deprecated or advanced subcommands unless you explicitly run their `--help`.

### 1.2 Man Page

```bash
man <cmd>
man <cmd>-<subcommand>   # some CLIs (e.g. git-commit) have per-subcommand pages
```

If no local man page exists, check `<cmd> --help` for a `--man` flag or a documentation URL. Note whether the man page substantially duplicates `--help` or adds detail — if it adds detail, it is worth fetching.

### 1.3 Online Documentation

Search for the official docs. Prefer in order:
1. Official project site (e.g. `cli.github.com/manual`)
2. GitHub/GitLab README if the project is open source
3. Package-manager page (PyPI, npm, crates.io) for install + overview

Fetch the main reference page. If docs are paginated per subcommand, fetch the index and the most relevant section pages.

### 1.4 Version

```bash
<cmd> --version
<cmd> -v
<cmd> version       # subcommand form
```

Use the version to fetch version-specific documentation when docs are versioned.

### 1.5 CLI Profile (complete before Phase 2)

```
CLI:          <name> <version>
Type:         simple (no subcommands) | compound (has subcommands)
Subcommands:  [list] | n/a
Help source:  --help | man | online | none found
Docs URL:     <url> | not found
Output formats available: json | plain | csv | other
Auth required: yes (<method>) | no

Example compound breakdown:
  gh → pr · issue · repo · release · secret · run · workflow · ...
```

---

## Phase 2: Analysis

### 2.1 Classify Each Subcommand (or the CLI itself if simple)

For each subcommand (or operation mode), assign every dimension:

| Dimension | Values | Decision impact |
|---|---|---|
| **Domain** | e.g. `pull-request`, `issue`, `repo` | Determines skill split |
| **Operation type** | `read` / `write` / `both` | Drives read/write split |
| **Output format** | `json`, `plain`, `csv`, `none` | Token efficiency |
| **Bulk-capable** | `yes` / `no` | Script opportunity |
| **Destructive** | `yes` / `no` | Safety constraint in skill |

**Read operations** (never mutate state): list, get, view, show, diff, status, log, search, inspect, describe, export  
**Write operations** (mutate state): create, update, delete, edit, merge, close, reopen, push, assign, enable, disable

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

If the CLI has a `--json` flag with field selection (e.g. `gh pr list --json number,title,state`), document the available fields — this lets the skill instruct the LLM to request only the fields it needs.

### 2.3 Identify Bulk-Action Opportunities

A **bulk opportunity** exists when the agent would otherwise make N sequential tool calls to process N items. Look for:

- Flags that accept multiple IDs/names (`--ids 1,2,3` or repeating `--id`)
- Operations whose input is naturally a list (output of a prior `list` command)
- Operations amenable to `xargs` or shell loops

Document each opportunity as a candidate script. Examples:

```bash
# Bulk close stale issues — candidate for a wrapper script
gh issue list --label stale --json number | jq '.[].number' \
  | xargs -I{} gh issue close {}

# Bulk label PRs — candidate for a wrapper script
gh pr list --state open --json number | jq '.[].number' \
  | xargs -I{} gh pr edit {} --add-label "needs-review"
```

### 2.4 Identify Script Opportunities

A **wrapper script** is warranted when any of the following are true:

| Trigger | Rationale |
|---|---|
| Task requires ≥ 2 sequential invocations | Collapses N tool calls into 1 |
| Output must be filtered/reformatted before the LLM can use it | Avoids round-tripping raw text |
| Pagination must be handled | `--limit` loops or cursor traversal |
| Common composite pattern exists | Reusable, verifiable unit |
| Bulk operation over N items | Single tool call regardless of N |

For each candidate, note: name, purpose, inputs, outputs. Do not write the scripts yet — that is Phase 4.

---

## Phase 3: Decomposition Decisions

> For detailed heuristics and worked examples, read `references/decomposition.md`.

### 3.1 How Many Skills?

```
Is this a simple CLI (no subcommands)?
  YES → One skill.

Is this a compound CLI (has subcommands)?
  → Do the subcommands cluster into distinct functional domains?
      (Test: would activating the combined skill load irrelevant context
       for most real tasks?)
    NO  → One skill with subcommand sections.
    YES → One skill per domain.
          IF total content for all domains fits under 250 lines combined
          THEN consider keeping them together with clear section headers.
```

**When to split by domain (example — GitHub CLI):**

| Combined | Split |
|---|---|
| One `gh` skill | `gh-pr` · `gh-issue` · `gh-repo` |
| Every task loads all subcommands | Each task loads only its domain |
| 400+ lines of content | ~100 lines per skill |

Separate skills that address different domains can be **activated together** — there is no penalty for activating both `gh-pr` and `gh-issue` in the same agent session. Overlap is acceptable; redundancy is not.

### 3.2 Read/Write Split

Split into separate `read` and `write` skills when **any** of the following apply:

- The agent workflow should be explicitly restricted to read-only (investigation, audit, summarisation agents)
- Write operations require human confirmation in your workflow but reads do not
- The read and write operation sets have no shared flags or conceptual overlap

If in doubt, keep combined. Mark destructive operations with a `⚠ WRITE` tag in the skill so the constraint is visible.

### 3.3 Script vs Direct Invocation

| Situation | Recommendation |
|---|---|
| Single command, no post-processing | Direct invocation, document in skill |
| Common multi-step composite | Wrapper script in `scripts/` |
| Bulk operation over N items | Loop script in `scripts/` |
| Pagination required | Pagination script in `scripts/` |
| Output needs JSON field filtering | `jq` inline in skill example or in script |
| Format conversion before LLM sees output | Script with explicit output schema |

> See `references/script-patterns.md` for script templates and header conventions.

### 3.4 Decomposition Output — Skill Map

Produce a **Skill Map** before authoring. Get confirmation from the user if the map is non-trivial.

```
Skill: gh-pr
  Domain: pull requests
  Operations: read (list, view, diff, checks) + write (create, edit, merge, close)
  Output flag: --json <fields>
  Scripts:
    scripts/list-my-prs.sh    → open PRs assigned to me, JSON, filtered by state
    scripts/bulk-merge.sh     → merge a list of PR numbers (input: newline-separated)

Skill: gh-issue
  Domain: issues
  Operations: read (list, view, search) + write (create, edit, close, assign)
  Output flag: --json <fields>
  Scripts:
    scripts/list-open-bugs.sh → open issues labelled 'bug', JSON output
```

---

## Phase 4: Authoring

> **Dependency:** Load `/mnt/skills/user/prompt-engineering/SKILL.md` now. Apply all its rules to every piece of LLM-facing text written below. Do not inline its rules here.

> **Dependency:** Consult `/mnt/skills/examples/skill-creator/SKILL.md` for SKILL.md anatomy (frontmatter, progressive disclosure, bundled resources layout, writing patterns).

### 4.1 For Each Skill in the Skill Map

Write a `SKILL.md` containing:

1. **YAML frontmatter** — `name`, `description` (trigger-focused; be specific about subcommands/domain covered)
2. **Invocation reference** — exact commands the LLM will run, with recommended flags
3. **Output format** — what the LLM should expect; JSON field schema where available
4. **Common patterns** — 3–5 concrete use cases as `input → command → output` examples
5. **Constraints** — MUST / MUST NOT rules; always flag destructive operations
6. **Edge cases** — auth failures, resource-not-found, rate limits, empty results

Pull key excerpts from man pages or online docs into `references/<topic>.md` and reference them from SKILL.md. Only pull content that is meaningfully denser than `--help` output.

### 4.2 Wrapper Scripts

For each script identified in Phase 3:

- Use Bash unless the CLI is Python-native
- Include a standard header block (see `references/script-patterns.md`)
- Prefer `--json` + `jq` over text parsing
- Make scripts idempotent where possible (safe to re-run)
- Document in SKILL.md: path, one-line purpose, inputs, expected output

### 4.3 Final Authoring Checklist

- [ ] `--help` and subcommand help reviewed for all relevant subcommands
- [ ] Man page checked; online docs fetched if they add meaningful detail
- [ ] CLI Profile completed (Phase 1)
- [ ] All subcommands classified: domain, read/write, output format, bulk/script flags (Phase 2)
- [ ] Machine-readable output flags identified and documented (Phase 2)
- [ ] Bulk and script opportunities addressed (Phase 2)
- [ ] Skill Map produced and confirmed (Phase 3)
- [ ] `prompt-engineering` rules applied to all LLM-facing text
- [ ] `skill-creator` anatomy followed for every SKILL.md
- [ ] Wrapper scripts written, headered, and referenced from SKILL.md
- [ ] Destructive operations flagged `⚠ WRITE` in each skill
- [ ] Reference files added for doc sections denser than --help
