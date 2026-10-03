# Replacement Session Prompt Template

Template for the **prompt** of a `create-session` handoff in Workflow 6 (Wedged PR Recovery)
of the `google-jules-triage` skill.

**Use this when** a session's branch is wedged (empty-commit cascade, self-reverted
refactor, unresolvable conflict) and you have already rebuilt the diff onto a
`tidy/pr-<n>-<slug>` branch. The new session inherits that branch and must finish the work.

**Do not use this for** a first-time task. A normal `create-session` needs only the goal
and constraints.

---

## Placeholder Legend

| Placeholder | Fill with |
|---|---|
| `{{TITLE}}` | Conventional Commits title, e.g. `fix(provider): compose mapping with field filtering` |
| `{{GOAL}}` | The original issue's stated goal, quoted or tightly paraphrased |
| `{{EXAMPLE}}` | Concrete input→output example from the issue (e.g. `env:FOO -> FOO`) |
| `{{CONFIG_SHAPE}}` | The YAML/config snippet from the issue |
| `{{PRIOR_ISSUE}}` | Prior merged issue this depends on, e.g. `#162` — state that its behaviour must not regress |
| `{{OLD_SESSION_ID}}` | The wedged session's ID |
| `{{WHAT_FAILED}}` | One or two sentences on how the prior attempt failed (looped, or never delivered) |
| `{{TIDY_BRANCH}}` | The rebuilt branch, e.g. `tidy/pr-210-regex-key-mapping` |
| `{{TIDY_STAT}}` | e.g. `single squashed commit (8 files, +760/-2)` |
| `{{DONE_HEADER}}` | Short lead-in, then bullet list |
| `{{DONE_ITEM}}` | One already-complete unit of work, specific enough that the agent will not redo it |
| {{FINDING}} | One unresolved review finding, reproduced below with full structure |
| {{VERIFY_CMD}} | The repo's verification command list |
| {{LINT_CMD}} | The repo's lint command, or `N/A` |
| {{CUSTOM_CONSTRAINT}} | A repo-specific guardrail from `AGENTS.md` (scope creep, forbidden files, secret hygiene) |

---

## Template

```markdown
{{TITLE}}

## Original goal ({{ISSUE_NUMBER}})

{{GOAL}}

Example:
{{EXAMPLE}}

Config shape:
{{CONFIG_SHAPE}}

This issue depends on {{PRIOR_ISSUE}}, which is already merged. Do NOT weaken, remove,
or re-implement {{PRIOR_ISSUE}}'s behaviour.

## A previous attempt claimed work it did not deliver

Session {{OLD_SESSION_ID}} wrote the implementation, ran the test suite, and reported
success — then {{WHAT_FAILED}}. The branch it owned is unmergeable and has been discarded.
Do not trust any claim that this work is already correct.

You are starting from branch `{{TIDY_BRANCH}}`, which is `main` plus a {{TIDY_STAT}}
containing that earlier attempt's code.

## What is ALREADY DONE — do not redo

{{DONE_HEADER}}

{{DONE_ITEM}}

{{VERIFY_CMD}} all pass on this branch as-is.

## What REMAINS — these are unresolved review findings

Findings {{N}} and {{N+1}} are {{SEVERITY_CLASS}}. Treat them as merge blockers.

{{FINDING}}

## Constraints — read carefully

{{CUSTOM_CONSTRAINT}}

## Acceptance criteria

- [ ] Every finding above is fixed and covered by a test that FAILS on the pre-fix code.
- [ ] {{VERIFY_CMD}} passes.
- [ ] {{LINT_CMD}} is clean.
- [ ] The PR body explains what changed, why, and how to test it.

## Delivery — mandatory, do not skip

You MUST `git push -u origin HEAD` and then `gh pr create` against `main`. Do not finish
without both. If the harness offers to submit a patch artifact INSTEAD of pushing, decline
it and push to the remote. A PR that exists only inside this session is not a deliverable.

Before pushing, confirm your diff is non-empty and contains no CI-gate bypass filler (no
`dummy.txt`, no `.diff`/`.sh` helper scripts, no placeholder comments added purely to
satisfy the `Reject empty commit` check). Every commit you push must change at least one
file — the workflow gate fails the PR otherwise.
```

---

## {{FINDING}} — Full Structure

Reproduce every finding at this granularity. A bare "fix the filter bypass" is a
guaranteed round-trip.

```markdown
{{N}}. **{{SEVERITY}} — {{SHORT_TITLE}}** (`{{FILE}}:{{LINE}}`).
   {{DESCRIPTION — the exact mechanism, quoting the offending expression.}}
   **Impact:** {{CONSEQUENCE — which guarantee breaks, citing the prior issue.}}
   **Solution:** {{DIRECTION — enough to act on, without prescribing the whole design.}}
```

Severity vocabulary, in this order, so the agent knows what blocks:

| Severity | Meaning |
|---|---|
| **Critical** | Secret leakage, data loss, or an auth/filter bypass |
| **High** | Correctness or security regression against a merged guarantee |
| **Medium** | Nondeterminism, surprising behaviour, or a missing guard |
| **Low** | Swallowed errors, missing coverage, style deviation |

---

## The Delivery Section — Why It Is Worded This Way

Every clause targets a failure observed in practice on `warpcode/cloakenv`. Do not trim it.

| Clause | Failure it prevents | Observed |
|---|---|---|
| "You MUST `git push -u origin HEAD` and then `gh pr create`" | Session reaches `COMPLETED`, writes code, passes its own review, pushes nothing | Sessions `940024975768340826`, `10856745711762183052` |
| "against `main`" | PR targets the tidy branch and never merges | — |
| "Do not finish without both" | Treated as advisory | #186, #210 |
| "decline [the patch artifact] and push to the remote" | Harness offers artifact submission as a substitute for delivery; artifact is 404 via API and unrecoverable | Both sessions above |
| "A PR that exists only inside this session is not a deliverable" | Restates the rule in the agent's own framing | Both sessions above |
| "confirm your diff is non-empty" | Silent no-op after a "fix" | #210 |
| "no `dummy.txt`, no `.diff`/`.sh` helper scripts, no placeholder comments" | CI-gate bypass filler converts a rejected empty commit into an accepted one | #191 (`dummy.txt` containing `Trigger rebuild`) |
| "Every commit you push must change at least one file" | The `Reject empty commit` gate fails the whole PR on one empty commit | #210 (4 stacked empties), #193 (5), #191 |
| The warnings in "A previous attempt claimed work it did not deliver" | Agent reads its predecessor's self-report as fact | #186 (message claimed fixes absent from the diff) |

The non-empty-diff and filler-file clauses are also what stop the agent from *repeating*
the loop that created the tidy branch in the first place.

---

## Notes on the Other Sections

- **"What is ALREADY DONE"** must be specific enough that the agent will not redo it.
  Naming files and symbols, not just features. A vague list causes a full rewrite, which
  reads as an unrequested refactor.
- **"What REMAINS"** carries the review findings forward. The replacement agent never
  sees the original PR thread, so anything not restated here is lost.
- **"Constraints"** should carry the repo's scope-creep guardrails. Jules has a documented
  pattern of smuggling unrequested refactors into unrelated feature work (#193,
  `regexCache sync.Map`; #203, a `.jules/bolt.md` file invented from a fabricated premise).
  State the forbidden changes explicitly rather than hoping the agent respects scope.
- **Acceptance criteria** restate the findings as checkboxes so the agent self-audits
  against a list rather than a narrative.