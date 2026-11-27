---
name: project-tracker
description: >
  Track epic and issue progress across external trackers (GitHub Issues, Jira,
  Redmine, Kanban), branch/PR stack trees, and codebase ground truth. Reconciles
  three-way state, verifies criterion-level source evidence, and flags
  sequencing breaches, stub/unwired code, and non-goal violations. Use when
  auditing epic or issue progress, verifying criteria in code, or checking
  dependency compliance.
user-invocable: false
---

# Project Tracker

A service-agnostic tracking, ground-truth verification, and compliance knowledge
centre. Reconciles external issue tracker state (GitHub Issues, Jira, Redmine,
Linear, Kanban, or plain text dumps) against **Branch / PR Stack Trees** and
**Codebase Ground Truth**, with optional `docs/plans/` and `docs/adr/` specs.

## 1. Principles of Ground-Truth Tracking

1. **Tracker-Agnostic Ingestion**: Consumes GitHub Issues, Jira, or arbitrary
   JSON/CSV/Markdown dumps by normalizing fields into canonical states (`OPEN`,
   `IN_PROGRESS`, `BLOCKED`, `DONE`).
2. **Three-Way Reconciliation**: Truth lives across `Tracker State <-> Branch / PR Stack Tree <-> Codebase Ground Truth` (with `docs/plans/` SPEC as an optional fourth source when present).
3. **Code Ground Truth Over Claimed Status**: Never trust a `Closed`/`Done`
   ticket, merged PR, or comment without verifying target files, call-site
   wiring, and acceptance criteria in pinned source.
4. **DAG & Sequencing Integrity**: Evaluate every active or closed item against
   its upstream `Depends on` / `Blocked by` prerequisites and branch base
   ancestry.
5. **Isolated Read-Only Inspection**: Code sweeps may be delegated to an
   isolated read-only inspector; the inspector must return exact `file:line`
   references, commit SHAs, and pinned revision identifiers (`headRefOid`).

## 2. Ingestion & Status Normalization

Extract canonical fields (`Identifier`, `Title`, `Status`, `Type`, `Estimate`,
`Parent`, `Dependencies`, `Target Scope`, `PRs / Branches / Commits`) and map
tracker workflows into four states (see `references/progress-and-compliance.md`):
- **`OPEN`**: Backlog, To Do, Ready, Proposed, New, Triaged.
- **`IN_PROGRESS`**: In Dev, Doing, Started, WIP, In Review, Review.
- **`BLOCKED`**: On Hold, Waiting, Impeded, Paused.
- **`DONE`**: Closed, Resolved, Complete, Merged, Shipped, Fixed.

## 3. Three-Way Reconciliation & Audit Protocol

### Step 1: Discover Linked Branches, PRs & Commits
Discover work across the repository using whichever linkage convention it uses
(GitHub issue refs `Closes #N`, Jira keys `PROJ-123` in branch/PR/commit text,
or optional `Plan: <slug>:<TSK-xxx>` trailers):
```bash
git log --grep="<issue-key-or-slug>" --format="%h %s"
gh pr list --search "<issue-key-or-slug>" --state all --json number,title,url,state,baseRefName,headRefName,headRefOid,mergedAt
git merge-base --is-ancestor <upstream-sha> <downstream-head>
```

### Step 2: Three-Way State Reconciliation
Compare **Tracker State**, **Branch / PR Stack Tree**, and **Codebase Ground Truth**
(plus optional `SPEC.md`):

| Discrepancy Pattern | Classification | Meaning |
|---|---|---|
| Tracker `DONE` / PR open or unmerged | **Premature Closure** | Ticket closed before code landed on target base. |
| PR merged / Tracker `OPEN` or `IN_PROGRESS` | **Stale Tracker** | Code landed, but tracker state was never transitioned. |
| PR merged / Code missing or stubbed | **Phantom / Unwired Completion** | PR merged without satisfying criterion or wiring into runtime path. |
| Code present / No tracker item | **Scope Creep / Untracked Work** | Repository changes lack an owning issue or requirement. |
| Branch or PR exists / No tracker item | **Orphaned Branch** | Active branch/PR has no linked epic, issue, or plan task. |

### Step 3: Criterion-to-Code Ground-Truth Verification
Apply `references/criterion-evidence-verification.md` to build an evidence
packet and a 1:1 criterion matrix (one issue key + one testable requirement per
row). Classify each criterion as `Visible`, `Partially visible`, `Not visible`,
or `External`, citing exact `file:line` locations and pinned PR/commit SHAs.

### Step 4: Violation & Sequencing-Breach Detection
Audit for five violation classes:
1. **Non-Goal (`NG-*`) Violations (Critical)**: Code or issues implementing
   explicitly excluded capabilities.
2. **Architectural Contradictions (`ADR-*`, `REJ-*`)**: Code violating accepted
   ADRs, fitness functions, or reviving rejected alternatives.
3. **Sequencing & Dependency Breaches**:
   - Downstream issue marked `IN_PROGRESS` or `DONE` while upstream dependency is not merged.
   - Downstream PR targets `main`/`master` while an upstream dependency PR is unmerged.
   - Downstream PR `baseRefName` does not match its DAG upstream dependency branch.
   - Stacked PR merged before its upstream parent PR.
   - Dependency cycle present in the DAG (`A -> ... -> A`).
4. **Stub / Unwired Code**: Functions, modules, or flags exist in files but are
   never called, registered, exported, or covered by assertions.
5. **Scope Creep**: Unmapped issues, branches, or code additions lacking goal/issue coverage.

### Step 5: Governance Gates Check (When Applicable)
1. **Unvalidated Assumptions (`ASM-*`)**: Flag active requirements relying on unvalidated assumptions.
2. **Open Blocking Questions (`Q-*`)**: Flag active work proceeding under unanswered blocking questions.
3. **Unmitigated High Risks (`RSK-*`)**: Flag high-impact risks lacking assigned mitigation tasks.

### Step 6: Report & Reconcile
Render findings using `templates/progress-report.md` and present discrepancies,
sequencing breaches, and proposed status/base corrections (recommended action
first). Update tracker items or optional `SPEC.md` only upon explicit approval.

## 4. Definition of Done (Audit Gate)

Before declaring an epic, milestone, or plan complete:
- [ ] Three-way reconciliation complete across `Tracker <-> Branch/PR Stack Tree <-> Code` (and optional `SPEC.md`).
- [ ] Every criterion in the matrix has verified `file:line` source evidence (`Visible` vs. explicit gap).
- [ ] Completed items have `- **Evidence**:` / link provenance (PR URL, ticket link, commit SHA).
- [ ] Zero dependency or sequencing breaches (no unmerged upstreams, mismatched PR bases, out-of-order merges, or DAG cycles).
- [ ] Zero stub/unwired implementations on closed items.
- [ ] Zero unaddressed Non-Goal (`NG-*`) or Architecture (`ADR-*`/`REJ-*`) violations.
- [ ] Scope creep and governance gates (`ASM-*`, `Q-*`, `RSK-*`) triaged.

## 5. Templates & References

- `templates/progress-report.md` — Three-way progress, branch/PR stack tree, and compliance audit report
- `references/criterion-evidence-verification.md` — Scoping, evidence packets, 1:1 criterion matrix, visibility classification, and completeness gate
- `references/progress-and-compliance.md` — Ingestion heuristics, status normalization, violation taxonomy, and reconciliation protocol
