# Script Standards & Authoring Rules

Standards for writing helper utilities bundled in skill `scripts/` directories.

---

## Core Invariants

These govern script *quality* — how a script must behave once it exists.

1. **Python as Primary Language**: Write executable scripts in Python targeting the standard library.
2. **Zero External Dependencies**: Standard library only. When dependencies are unavoidable, use `uvx <package>` for ephemeral execution without polluting host environments.
3. **Black Box Execution**: Agents must inspect `--help` to determine arguments and options, never reading script source code into context.
4. **Token-Efficient Output**: Return minimal, parseable output (clean tables, JSON, or direct values). Avoid decorative banners, verbose logs, or excessive padding.

---

## Coverage Invariants: How Much *Should* Be Scripted

These govern script *coverage* — whether the required scripts exist at all. A
package can satisfy all four quality invariants above with one trivial helper
and still force the agent into hundreds of tool calls. Coverage is the more
common failure.

6. **Gather Before Acting**: Every workflow establishes its facts before it acts
   on them, and the gathering is the largest single script in the package. The
   gather script runs first and returns everything the judgement needs; no
   mutation or recommendation is derived from a partially-gathered picture.
   Design every workflow in the shape **GATHER (one script) → REASON (agent) →
   ACT (one confirmed call)**.
7. **Gaps Are Reported, Never Inferred**: When a fact cannot be retrieved, the
   script emits it as an explicit gap field and the agent reports the gap. A
   missing check is not a passing check; an unreadable field is not an empty
   one. Silent defaults convert a retrieval failure into a wrong conclusion.
8. **Bundle, Don't Chain**: If answering one question requires ≥2 sequential
   tool invocations, that sequence belongs in **one** script. `SKILL.md` must
   document the script, not the individual calls it replaced. Agent-chained
   atomic scripts (`list_a.sh` → `list_b.sh` → `list_c.sh` in sequence) are a
   bundle that was never written.
9. **The Script Is the Unit of Work**: Emit one dense, self-contained JSON
   document per workflow step. The agent reads it and reasons; it never has to
   correlate N partial outputs to answer a single question.
10. **No Loops in Prose**: Shell `for`/`while` loops, `jq` pipelines, and inline
    `python3 -c` blocks do not belong in `SKILL.md`. They belong in a parameterised
    script. A loop in a skill body is a bug: agents re-derive it per run,
    inconsistently, and it is invisible to review.
11. **Report-Only by Default**: The default invocation must not mutate state.
    Destructive or mutating behaviour requires an explicit flag
    (`--delete-merged`, `--apply`, `--write`), and the skill must state that the
    user approved it.
12. **Verify Before Documenting**: A script's documented invocation must be
    executed successfully once before it is written into `SKILL.md`. Documented
    scripts that error are worse than the call-chain they replaced, because the
    agent trusts them and stops verifying.
13. **Deterministic and Side-Effect Free on Read**: A read bundle must not write
    outside a caller-specified output directory. Downloading an artefact to a
    fixed temp path races across concurrent runs.

### Worked example — the same PR audit, three ways

| Approach | Agent tool calls | Failure modes |
|---|---|---|
| Documented as prose steps | `gh pr view`, `gh pr checks`, `gh pr diff`, `gh issue view`, `git rev-parse`, … | the agent acts on whatever it read first; partial output correlated by hand; merge state read at a different instant than the checks; guessed `owner/repo` fails |
| Six atomic scripts chained | 6 invocations | same correlation problem, plus 6 chances to pick the wrong flag |
| **One gather bundle script** | **1 invocation** | single consistent snapshot; `--repo` resolved once; JSON correlates state, CI and diff by construction; retrieval gaps are explicit fields |

The third row is the default. If a proposed workflow cannot be written as a
single script invocation, either the grouping is wrong or the workflow is
genuinely two questions — in which case document two scripts, not one chain.

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

### Composite Script Naming

Bundles that gather several operations into one workflow step use a suffix on
the primary noun, so wildcard policies still group them correctly:

| Suffix | Meaning | Example |
|---|---|---|
| `-bundle` | Gathers a fixed set of resources for one question | `@scripts/pr_audit_bundle.sh` |
| `-rollup` | Aggregates N resources into one state summary | `@scripts/pr_state_rollup.py` |
| `-audit` | Read-only verification pass with a verdict | `@scripts/audit_repo_alerts.py` |

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

## Documenting Scripts in SKILL.md

A script the agent does not know about will not be run. Every bundled script
needs a routing table row with three fields:

| Field | Purpose |
|---|---|
| Script path | `@scripts/<name>` plus the full invocation syntax |
| Purpose | The single question it answers |
| Run when | The condition that makes it the right choice |

Phrase the third column as a condition, not a summary — the agent matches
against it. "Run when: reviewing a PR whose diff exceeds 500 lines" routes;
"Summary: reviews large diffs" does not.

Also state the output schema (fields and types), so the agent knows what it
will receive without inspecting the script.

---

## Script Implementation Checklist

### Coverage (does the right set of scripts exist?)

- [ ] **The workflow gathers before it acts**: one gather script returns every
      fact the judgement needs, and no mutation is documented ahead of it.
- [ ] **Unretrievable facts surface as explicit gap fields**, never as silent
      empty/false/passing defaults.
- [ ] **Every workflow step in `SKILL.md` is a single script invocation** — no
      step requires the agent to chain 2+ tool calls.
- [ ] **Composite work is bundled**: any question needing several underlying
      reads is answered by one script, not by an agent-run sequence.
- [ ] **No shell loops, `jq` chains, or inline `python3 -c` in `SKILL.md`.**
- [ ] **Tool-backed skills ship at least one bundled script.**
- [ ] **Every script has a routing-table row** with path, purpose, output
      schema, and a "run when" condition.

### Quality (does each script behave correctly?)

- [ ] **Accurate `--help`**: Implement standard `argparse` with clear option descriptions and usage examples.
- [ ] **Deterministic Exit Codes**: Exit `0` on success, `1` on error or invalid arguments. Reserve extra codes for gate failures (e.g. `2` = verification failed, nothing submitted).
- [ ] **Report-only by default**: Any mutation requires an explicit flag.
- [ ] **Self-Test / Demo Mode**: Include an assert-based self-test mode (`--self-test` or `-t`) for automated verification.
- [ ] **Syntax Compilation**: Ensure script compiles cleanly (`python3 -m py_compile`, `bash -n`, or `zsh -n`).
- [ ] **Documented Path Resolution**: Ensure `SKILL.md` specifies `<skill-dir>/scripts/<name>` invocation syntax.
- [ ] **Smoke-tested**: The documented invocation has been run successfully at
      least once, and its output parses as the documented schema.

