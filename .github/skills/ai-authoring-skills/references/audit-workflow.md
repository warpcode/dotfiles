# Skill Audit & Improvement SOP

Standard Operating Procedure for auditing triggering reliability, structural health, and prompt performance across skill packages.

---

## Audit Execution Steps

1. **Structural Validation**: Execute `python3 scripts/validate.py <skill-path>` to catch syntax, frontmatter, and missing resource errors.
2. **Triggering Review**:
   - Inspect frontmatter `description` for literal user trigger phrases.
   - Verify length is under 1024 characters.
   - Address undertriggering or overtriggering using evaluation protocols in `@references/evals.md`.
3. **Progressive Disclosure Audit**:
   - Verify `SKILL.md` body is concise (<500 lines, target ~60-80 lines).
   - Ensure deep domain knowledge is deferred to `@references/`.
   - Verify helper scripts in `scripts/` follow `@references/script-standards.md`.
4. **Gather-Before-Act Audit**:
   - [ ] **Every mutation is preceded by a single gather step** that establishes
         the facts it depends on, in one call.
   - [ ] **Gather is the largest script in the package**, not an afterthought.
   - [ ] **Identity is resolved once** at the top of the gather script (owner,
         repo, ids, ref/SHA) — not re-guessed per call.
   - [ ] **Gaps are explicit fields.** Grep for `or {}`, `or []`, `or False`,
         `get(..., default)` on remote data. A missing check rendered as an empty
         list inverts the verdict: it reads as "passed, no checks".
   - [ ] **Nothing acts on a partial picture.** No instruction tells the agent to
         inspect one thing and act without establishing the rest.
5. **Scripting Efficiency Audit** (highest-value step — run it before reporting):
   Walk the documented workflow and count the tool calls an agent would actually
   make. For each workflow step, the number of documented invocations is the
   defect count.
   - [ ] **Count tool calls per workflow step.** >3 for one step = missing bundle script.
   - [ ] **No loops in prose.** Any shell `for`/`while`, `jq` pipeline, or inline
         `python3 -c` in `SKILL.md` or a reference file is an unwritten script.
   - [ ] **No chains of atomic scripts.** If the agent must call several
         `get-`/`list-` scripts in sequence to answer one question, that is a
         `*-bundle` script.
   - [ ] **Tool-backed skills ship at least one script.** A workflow skill with
         zero scripts forces the agent to hand-roll the orchestration.
   - [ ] **Verdicts derived in code, not in context.** Instructions to "compare",
         "correlate", "classify", or "tally" across multiple outputs are logic
         that belongs in a script.
   - [ ] **Scripts are reachable.** A bundled script the agent doesn't know about
         will not be run — check it appears in a routing table with a "run when"
         condition, not buried in a reference.
   - [ ] **Large payloads write to `--out`, not stdout.** Agents truncate long
         stdout and silently conclude from partial data.
6. **Empirical Script Usage Audit** (check bundled scripts against conversation transcripts):
   Run `python3 scripts/audit_bundled_scripts.py <skill-path> --sessions 200`
   (or `validate.py --audit-script-usage <skill-path>`).
   Queries `ai-conversation-review`'s `search_tools.py` over conversation transcripts
   (default 200 sessions, configurable with `--sessions <N>` or `--all`).
   - Categorizes bundled scripts:
     - **ACTIVE** (≥5 invocations): frequently executed; keep and prioritize.
     - **LOW_USAGE** (1-4 invocations): rarely executed; evaluate combining into a composite script with other commands in a chain.
     - **NEVER_USED** (0 invocations, documented): candidate for deprecation/removal if obsolete.
     - **ORPHAN** (0 invocations, undocumented): dead code candidate for removal.
   - If a bundled script has "never" or very low usage that could be added to a script with other commands in a chain, raise it as obsolete for removal or consolidation.
7. **Generalization Check**:
   - Eliminate hardcoded paths or over-fitting to single chat examples.
   - Replace MUST-stacking with clear operational rationales and boundaries.

### Estimating the Cost of a Skill

To rank audit findings, convert the workflow into a rough call count:

| Metric | Formula | Bad | Good |
|---|---|---|---|
| Tool calls per workflow | count of documented invocations | >20 | ≤5 |
| Calls per step | invocations ÷ steps | >3 | 1 |
| Script-to-instruction ratio | scripts ÷ documented steps | 0 | ≥1 bundle per multi-call step |
| Correlation risk | steps reading the same resource twice | >0 | 0 (one snapshot) |
| Gather coverage | facts needed to act ÷ facts gathered first | <1 | 1 |
| Undeclared gaps | retrieval failures the script reports as defaults | >0 | 0 |

Correlation risk and gather coverage are the correctness arguments, not just the
cost arguments. A chain that reads `PR state` then `CI status` in two calls can
report them as simultaneous when they are not; a workflow that acts before
gathering can act on a picture that was never complete. A bundle prevents the
first. Only gather-then-act prevents the second.

---

## Audit Report Contract

When performing a formal skill audit, structure findings using this exact format:

```markdown
# [Skill Name] Audit Report

## 1. Trigger Check
- **Description Quality**: [Evaluation of keywords, length, and trigger phrases]
- **Routing Reliability**: [Assessment of undertrigger / overtrigger risks]

## 2. Structure & Compliance Findings
- **Frontmatter & Layout**: [PASS/FAIL against standard]
- **Progressive Disclosure**: [Context budget and reference offloading analysis]
- **Script Hygiene**: [Verification of `--help`, compilation, and zero-deps]

## 3. Gather-Before-Act
- **Gather Step**: [The single call that establishes state, or "none"]
- **Coverage**: [Facts needed to act safely ÷ facts gathered first]
- **Mutations Without Prior Gather**: [Any, with line references]
- **Silent Defaults**: [Retrieval failures rendered as empty/false/passing values]
- **Identity Resolution**: [Resolved once, or re-guessed per call]

## 4. Scripting Efficiency
- **Tool Calls Per Step**: [N — what the agent must invoke to complete one workflow step]
- **Loops In Prose**: [Locations, if any]
- **Atomic Chains**: [Sequences the agent must stitch, if any]
- **Correlation Risk**: [Resources read more than once, and whether staleness can mislead]
- **Verdict**: [Script-first / partially scripted / narration-only]

## 5. Empirical Script Usage (default: 200 sessions)
- **Scanned Sessions**: [N]
- **Active Scripts**: [List with call counts]
- **Low Usage / Consolidation Candidates**: [List with call counts and proposed parent script]
- **Never Used / Obsolete Scripts**: [List flagged for removal]

## 6. Recommended Actions
1. [Action item 1 — a single gather script first; it fixes cost and correctness]
2. [Action item 2]
```

### Reporting the Efficiency Finding

State the mechanical saving, not just "could be more efficient":

> The documented workflow makes the agent ~14 tool calls (4 `gh pr view`
> variants, 3 `gh pr checks`, 4 `gh api` review-thread calls, 3 diff reads). A
> single `pr_audit_bundle.sh --repo O/R --pr N` returning pre-correlated JSON
> covers all 14. Additionally, `gh pr diff` output is truncated by the tool, so
> the current steps 10-12 conclude from a partial diff — the bundle writing to
> `--out` removes that correctness risk as well as the call overhead.

If the audit only reports prose-level findings, it has missed the finding with
the largest impact.

