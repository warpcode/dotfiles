# CLI-to-Skill Workflow

Produce well-scoped, token-efficient agent skills from CLI commands and scripts. The output may be one skill or several, with optional wrapper scripts, depending on the CLI's complexity and decomposition decisions.

---

## Workflow Overview

```
Phase 1: Discovery      → Build a complete picture of what the CLI can do
Phase 2: Analysis       → Classify operations; pass the scriptability gate
Phase 3: Decomposition  → Decide: how many skills, read/write split, scripts
Phase 4: Authoring      → Write scripts first, then SKILL.md that routes to them
Phase 5: Efficiency     → Count tool calls; confirm no loop lives in prose
```

Do not skip phases. Decomposition decisions made without completing discovery produce skills that miss useful flags or fail on edge cases.

**The organising principle:** atomic wrappers are the floor, bundling is the
target. A skill of thin `get-`/`list-` wrappers shifts the orchestration burden
onto the agent, which then re-derives it at runtime — inconsistently, expensively,
and invisibly to review. Bundle whole procedures instead.

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

### 2.3 Scriptability Gate

**This is a gate, not a consideration.** Do not proceed to Phase 3 until every
item below is answered.

Enumerate every tool invocation the typical workflow needs, then apply the
**scriptability test** to each:

> Would a competent human doing this task by hand run this command? If yes, it
> is scriptable — the script encodes a procedure, not just a single call.

A **script is warranted — in fact required —** when any of these hold:

| Trigger | Why it must be scripted |
|---|---|
| The task requires ≥2 sequential invocations to answer one question | N tool calls collapse to 1; the agent stops correlating partial output |
| Output must be filtered/reformatted before the agent can use it | Pre-filtering server- or script-side removes tokens the agent would otherwise pay to discard |
| Pagination must be handled | A `--limit` loop or cursor traversal in a script is invisible; hand-rolled in an agent it is skipped |
| A composite or bulk pattern over N items exists | Bulk loops belong in code, not in a chat transcript |
| **The same sub-command sequence recurs across tasks** | That is a procedure; procedures live in scripts |
| **The reasoning is mechanical** (diff, compare, classify, tally) | Mechanical logic re-derived per run is unreliable and burns context |

The last two matter most and are most often missed. They are what separate a
1-to-1 CLI wrapper from a genuinely useful skill: **atomic wrappers are the
floor, bundling is the target.**

#### Gather-first: the workflow's first obligation

Before grouping anything else, establish what the workflow **must know before it
may act**. This is the gather step, and it is the largest script in the package.

```
Gather contract — written before any other script is designed
  Facts needed to judge this workflow safely:
    - which resource (resolved owner/repo, ids, current branch/head SHA)
    - current state      (status, decisions, mergeability, open threads)
    - verification       (CI conclusions, dependency shipped, base comparison)
    - requirements       (source issue, acceptance criteria)
  Gaps: anything the tooling cannot establish is listed here as a NAMED gap,
        not filled with a default.
```

Then: **GATHER (one script) → REASON (the agent) → ACT (one confirmed call).**

The gather script must:

- **Resolve identity once.** Owner, repo, ids, and refs at the top. A
  twice-resolved or guessed `owner/repo` is a top cause of `Could not resolve to
  a Repository`.
- **Capture one consistent snapshot.** Fetch everything before deriving anything,
  so the agent cannot correlate two reads taken minutes apart.
- **Emit explicit gap fields.** `{"checks": null, "gap": "no CI workflow found"}`
  is honest; `{"checks": []}` reads as "CI passed with no checks", which is the
  opposite claim.
- **Derive verdicts in code.** Booleans and reason lists travel better than data
  requiring the agent to do arithmetic or classify.
- **Write large payloads to `--out <dir>`** and print a summary. Agents truncate
  long stdout, and a partial read produces a confident, wrong conclusion.

#### Record the decision

Write the enumeration into the skill's design notes before authoring. For each
group, state the question it answers, then decide bundle vs. split:

```
Question: "Is this PR safe to merge?"
  → gh pr view (state, draft, mergeability)
  → gh pr checks (CI conclusions)
  → gh api review threads (unresolved blockers)
  All three answer ONE question. ⇒ single `pr_ready_to_merge.sh --repo O/R --pr N`
  All three are needed BEFORE any judgement. ⇒ this is the gather step.

Question: "What is in this PR's diff?"
  → gh pr diff
  ⇒ single `get_diff.sh`, OR fold into the gather bundle if always needed together
```

If you cannot state the question a script answers, you do not yet understand
the workflow well enough to script it.

---

## Phase 3: Decomposition Decisions

> For detailed heuristics and worked examples, read [`decomposition.md`](@references/cli-integration/decomposition.md).

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

1. **Write the scripts first.** Author and smoke-test each script from the Phase
   2 enumeration, then write the `SKILL.md` that routes to them. Inverting this
   order — prose first, scripts never — is how skills end up documenting call
   chains instead of procedures.
2. Apply `ai-authoring-prompts` rules to all LLM-facing instructions.
3. Follow `templates/integration-tool.md` for skill layout.
4. For wrapper scripts, follow the header conventions and patterns in [`script-patterns.md`](@references/cli-integration/script-patterns.md).
5. Run validation: `python3 scripts/validate.py <skill-dir>`, including the
   `workflow-scriptability` check.

---

## Phase 5: Post-Authoring Efficiency Check

Answer these before declaring the skill done. Any "no" is a blocker.

1. **Count the tool calls.** Walk the skill's documented workflow and count the
   invocations an agent would make. More than ~3 for a single workflow step means
   a script is missing.
2. **Find any loop in prose.** Any `for`/`while`, `jq` pipeline, or inline
   `python3 -c` in `SKILL.md` is an unwritten script.
3. **Check the bundle question.** If the skill ships only atomic
   `get-`/`list-` wrappers, ask whether the agent must chain several to answer
   one question. If so, write the bundle.
4. **Verify the payload.** Would the workflow fail if any single underlying
   call returned stale or partial data? A bundle captures one consistent
   snapshot; a chain does not. Chains carry a correctness cost, not just a cost.
5. **Confirm gather-then-act.** Every mutation in the skill is preceded by a
   gather step that establishes the facts it depends on, in one call. No skill
   documents "post the comment" without first establishing that the comment is
   wanted and correctly targeted.
6. **Check for silent defaults.** Grep the scripts for `or {}`, `or []`,
   `or False`, `get(..., default)` on remote fields. A missing check rendered as
   an empty list is an inverted verdict; emit a gap field instead.
7. **Check for act-before-gather guidance.** Any instruction that tells the agent
   to inspect one thing and act on it, without establishing the rest of the
   picture first, is a defect — even if each individual step looks reasonable.
