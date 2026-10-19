---
name: project-planner
description: >
  Plan projects and features as dated, self-contained plan folders
  (docs/plans/YYYY-MM-DD-<slug>/ with SPEC.md, DECISIONS.md, REVISIONS.md),
  with mandatory scrutiny of every new idea against Goals, Non-Goals, ADRs,
  Decision Trees and Rejected Ideas, staged progression from problem framing
  to tasks, explicit risks, assumptions, open questions and acceptance
  criteria, service-agnostic progress tracking from issue tracking data dumps
  and code worktrees, ground-truth code verification, violation detection, and
  documentation reconciliation. Use when planning a project or feature,
  creating an ADR or PRD, breaking down tasks or estimating story points,
  scrutinizing a new idea, tracking progress, or auditing compliance and
  documentation accuracy against code.
---

# Project Planner

A procedure-only skill: plans are plain Markdown files edited directly. There is no CLI or service lock-in.
The instructions below guide human engineers and agents to plan, scrutinize, track progress, and audit
compliance against codebases and arbitrary issue tracking data.

## 1. Plans folder layout

Default root: `<repo>/docs/plans/`. Use another root only if the user names one.

```text
docs/plans/
├── README.md                              # Index of all plans (one row per plan)
├── 2026-10-19-plugin-sandbox/             # YYYY-MM-DD-<slug>
│   ├── SPEC.md                            # Charter, G, NG, REQ, RSK, ASM, Q, M, TSK
│   ├── DECISIONS.md                       # ADR, DT, REJ
│   ├── REVISIONS.md                       # Append-only change log
│   └── features/
│       └── 2026-11-02-network-policy/     # Same naming rule, same 3 files
│           ├── SPEC.md
│           ├── DECISIONS.md
│           └── REVISIONS.md
└── 2026-10-25-secrets-rotation/
```

Naming rules (apply to plans and features alike):
1. **Prefix** = the date the plan is *created*, in `YYYY-MM-DD` format (local date, from the
   session's current time — never guessed). The prefix never changes, even if the plan is renamed or
   finished later.
2. **Slug** = lowercase kebab-case, 2–5 words, `[a-z0-9-]` only, describing the outcome
   (`plugin-sandbox`, not `jira-142` or `new-stuff`).
3. **Before creating**, list the root and search existing slugs for the same topic. If a plan for
   the same topic already exists, extend it (or add a `features/` child) instead of creating a
   duplicate. If the exact `YYYY-MM-DD-<slug>` already exists, pick a more specific slug.
4. A feature lives under `features/` only when it needs its own goals/requirements/tasks.
   Small additions are just `REQ-*` items in the parent `SPEC.md`.
5. Never delete a plan folder. Mark it `Done`, `Abandoned` or `Superseded` in its SPEC header and in
   `README.md`.

`README.md` index format (keep sorted by folder name, newest last):

```markdown
| Plan | Status | Summary |
|---|---|---|
| [2026-10-19-plugin-sandbox](2026-10-19-plugin-sandbox/SPEC.md) | Active | Isolate plugin execution |
```

Status values: `Draft`, `Active`, `Done`, `Abandoned`, `Superseded`.

## 2. Item IDs

| Kind | Meaning | File |
|---|---|---|
| `G-*` | Goal (with a measurable success metric) | SPEC.md |
| `NG-*` | Non-Goal (explicitly out of scope) | SPEC.md |
| `REQ-*` | Requirement (EARS statement + acceptance criteria + priority) | SPEC.md |
| `RSK-*` | Risk (likelihood, impact, mitigation, owner) | SPEC.md |
| `ASM-*` | Assumption (and how it will be validated) | SPEC.md |
| `Q-*` | Open question (blocking or non-blocking) | SPEC.md |
| `M-*` | Milestone (deliverables + exit criteria) | SPEC.md |
| `TSK-*` | Task (context-free, see `templates/ticket-task.md`) | SPEC.md |
| `ADR-*` | Architecture decision | DECISIONS.md |
| `DT-*` | Decision tree / classification rule | DECISIONS.md |
| `REJ-*` | Rejected proposal | DECISIONS.md |

ID rules:
- IDs are numbered per plan folder, zero-padded (`REQ-001`), and **never reused or renumbered**.
  The next ID = highest existing number for that kind + 1, including superseded items.
- Refer to items in a parent plan by qualified ID: `2026-10-19-plugin-sandbox:NG-002`.
- Every item has a `Status`: `Proposed`, `Accepted`, `Done`, `Superseded by <ID>`, `Deprecated`,
  or `Rejected`. Only `Accepted`/`Done` items count as binding.
- `Depends On` may only reference `Accepted`/`Done` items. Never link to a superseded item.

## 3. Procedure

### Workflow A — New plan
1. Get today's date from the session time, choose the slug (§1 rules), and confirm both with the user.
2. Create the folder from `templates/SPEC.md`, `templates/DECISIONS.md`, `templates/REVISIONS.md`;
   add the row to `docs/plans/README.md` (create it if missing).
3. Work through the stages in §4 in order. Do not draft later-stage items early.

### Workflow B — Scrutinize every new idea or change (mandatory)
Before agreeing to any new idea, refinement or pivot:
1. **Read** the plan's `SPEC.md` and `DECISIONS.md`, plus every ancestor plan's (feature → parent).
   Search `REJ-*` and each ADR's *Rejected* field for the idea's keywords.
2. **Report an Impact & Contradiction Check** to the user covering:
   - **Premise** — which `G-*`/`REQ-*` gap does this close? If none, it is scope creep.
   - **Contradictions** — any inherited `NG-*`, `ADR-*` or `DT-*` it violates.
   - **Prior art** — was it already rejected (`REJ-*`, ADR *Rejected* field)? Re-opening needs
     *new evidence*, stated explicitly.
   - **Blast radius** — every item (in this plan, sibling features and the parent) whose
     `Depends On` chain includes what changes, transitively.
   - **Alternatives** — the cheapest option and "do nothing"; why they are insufficient.
   - **Failure modes** — a one-line pre-mortem: "This failed because…".
   - **Reversibility** — one-way or two-way door; one-way doors need an ADR.
3. **Ask for explicit approval** (`ask_question`, recommended option first). No edits before approval.
4. **Record the outcome**:
   - Approved, new → add the item with the next ID.
   - Approved, changes an existing item → mark the old item `Superseded by <new-ID>`, add the new item,
     then mark every dependent from step 2 `Needs Review` until re-checked.
   - Rejected → add a `REJ-*` with *Conflicts With* IDs and the rationale.
   - Always append a `REVISIONS.md` row (date, action, IDs, rationale).

### Workflow C — Retrospective documentation of existing work
1. Gather context with the matching provider skill (`jira-api`, `github-cli`, `git-expert`, or by
   reading local docs). See `references/retrospective-context.md` for what to extract.
2. Use the date of the **earliest evidence** (first commit, ticket or doc) as the folder prefix,
   and say in the SPEC header that it was documented retrospectively, with today's date.
3. Present the proposed items to the user grouped by kind, each with `Source` provenance.
   After approval, write them with Status `Accepted (Retrospective)`. Stage gates apply to new work
   only, but list the gaps (missing NG, AC, risks) as `Q-*` items.

### Workflow D — Track progress, audit compliance & reconcile documentation (In-flight / Review)
Use when provided an issue tracker data dump (in any format: JSON, CSV, TSV, XML, markdown tables, or plain text) and/or a project code path (such as a git worktree or repository checkout). This workflow is service-agnostic and relies on instructional heuristics rather than service APIs.

1. **Ingest & Normalize Context** (see `references/progress-and-compliance.md`):
   - Extract core fields regardless of format: unique ID, title/summary, status (normalize to `OPEN`, `IN_PROGRESS`, `BLOCKED`, `DONE`), story points/estimate, dependencies, linked PRs/commits, and target paths.
   - Map external issues to plan items (`TSK-*`, `REQ-*`, `M-*`, `G-*`). Flag unmapped external issues as potential **Scope Creep**.
2. **Audit Code Ground Truth** (when code path / worktree is available):
   - **Target Files**: Verify whether paths named in each `TSK-*` `Target Files:` actually exist and were modified in the repository.
   - **Done Command**: Inspect and verify deterministic done commands (`Done Command:`). Run safe commands (`./validate.sh`, tests) if permitted, or verify script/assertion existence statically.
   - **Acceptance Criteria**: Trace each Given/When/Then AC in `REQ-*` against implementation and test assertions in the codebase.
   - **Fitness Functions**: Confirm automated fitness functions in `ADR-*` exist and pass.
3. **Audit for Violations & Invariants**:
   - **Non-Goal (`NG-*`) Violations**: Cross-reference issue titles, descriptions, and code changes against all active and inherited `NG-*` items.
   - **Architecture & Decision Violations**: Check if code or issues revive rejected proposals (`REJ-*` or ADR *Rejected* fields) or contradict `DT-*` decision trees.
   - **Sequencing Violations**: Verify whether tasks marked `IN_PROGRESS` or `DONE` have unfinished upstream prerequisites (`Depends On:`).
   - **Scope Creep**: Review unmapped issues or untracked codebase changes that lack an approved `G-*` or `REQ-*`.
4. **Audit Governance Gates & Documentation Drift**:
   - Check for discrepancies between the tracker status, plan document status (`SPEC.md`), and actual code ground truth.
   - Verify that no active requirement has unvalidated assumptions (`ASM-*`), open blocking questions (`Q-*`), or unmitigated high risks (`RSK-*`).
   - Check plan integrity (no cycles, no links to superseded items).
5. **Report & Reconcile**:
   - Format the audit findings using `templates/progress-report.md`.
   - Present findings, discrepancies, and recommended reconciliation actions to the user via `ask_question` (recommended option first).
   - Upon explicit approval, update `SPEC.md` (task statuses, AC checkboxes `[x]`), `DECISIONS.md`, and append an audit row to `REVISIONS.md`.

## 4. Stage gates (self-enforced)

Do not move to a stage until the previous gate passes. State the gate result when moving on.

| Stage | Gate to exit |
|---|---|
| 1. Problem framing | Charter (problem, who is affected, why now) · ≥1 `G-*` with a success metric · ≥1 `NG-*` · key `ASM-*` listed |
| 2. Requirements | Every `REQ-*` depends on a `G-*`, has an EARS statement, a priority (P0/P1/P2) and ≥1 Given/When/Then AC · NFR checklist (§5) answered · every `G-*` covered by ≥1 `REQ-*` |
| 3. Architecture & risk | One-way-door choices have an `ADR-*` with rejected alternatives · `RSK-*` recorded for each P0 `REQ-*` (or "none identified" stated) · no blocking `Q-*` open |
| 4. Milestones & tasks | `M-*` with exit criteria · every P0/P1 `REQ-*` covered by ≥1 `TSK-*` · every `TSK-*` sized ≤3 pts (split anything larger into a spike + tasks), names target files and a done-command |

Features also pass Stage 1 on their own: a feature needs its own charter and at least one
feature-specific `NG-*`. Inheriting the parent's is not enough.

## 5. NFR checklist (Stage 2)

For each item, record a `REQ-*`, an `NG-*`, or "N/A — reason" in SPEC.md:
security & authz · privacy/secrets handling · performance & scale limits · reliability & failure
handling · observability (logs/metrics) · migration, backward compatibility & rollback ·
accessibility · cross-platform (Linux/macOS) · docs & user communication · testing strategy.

## 6. Completeness checks

### 6.1 Pre-execution completeness check (Stage 4 Exit)
Before declaring a plan ready to execute, check and report each item:
- [ ] Every `G-*` → ≥1 `REQ-*`; every P0/P1 `REQ-*` → ≥1 `TSK-*`
- [ ] Every `REQ-*` has AC; every `TSK-*` has a done-command
- [ ] No `Depends On` points at a superseded/rejected item; no dependency cycles
- [ ] No item left `Needs Review`; no blocking `Q-*` open; every high-impact `RSK-*` has a mitigation
- [ ] Unvalidated `ASM-*` each have a validation task or spike
- [ ] `README.md` index row and SPEC status are current; `REVISIONS.md` has the latest change

### 6.2 In-flight progress & compliance audit check (Workflow D)
Before declaring an audit complete or updating documentation status:
- [ ] Every task marked `Done` has verified `Target Files` present in the codebase
- [ ] Acceptance criteria checked `[x]` only when implementation and test assertions are verified in code
- [ ] Done commands executed or statically verified; no failing exit codes
- [ ] Zero unaddressed Non-Goal (`NG-*`) or Architecture (`ADR-*`/`REJ-*`) violations
- [ ] No sequencing violations: all `Depends On` prerequisites are completed before downstream work
- [ ] Scope creep identified: all unmapped issues/files triaged (rejected, extracted, or approved via Workflow B)
- [ ] Governance gates intact: no active work proceeding under unvalidated `ASM-*` or open blocking `Q-*`
- [ ] Three-way reconciliation complete: discrepancies between tracker, `SPEC.md`, and code resolved
- [ ] `REVISIONS.md` updated with audit record and rationale

## 7. Templates & references

- Plan files: `templates/SPEC.md`, `templates/DECISIONS.md`, `templates/REVISIONS.md`
- Standalone exports: `templates/prd-full.md`, `templates/prd-lightweight.md`,
  `templates/adr-madr.md`, `templates/adr-nygard.md`, `templates/ticket-task.md`,
  `templates/progress-report.md`
- `references/prd-and-requirements.md` — EARS, MoSCoW, Non-Goals
- `references/adr-and-decisions.md` — ADR wording, decision trees, supersession
- `references/task-and-lifecycle.md` — task slicing, sizing, lifecycle
- `references/retrospective-context.md` — what to extract for retrospective documentation
- `references/progress-and-compliance.md` — service-agnostic tracking, ground-truth code auditing, violations, drift reconciliation
