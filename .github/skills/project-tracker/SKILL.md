---
name: project-tracker
description: >
  Track project progress, audit code ground truth, detect scope creep and
  boundary violations, and reconcile documentation drift across external issue
  tracker dumps (Jira, Linear, GitHub Issues) and local git worktrees against
  project plans (docs/plans/) and architecture decisions (docs/adr/). Use when
  tracking project progress, verifying task completion in code, checking
  acceptance criteria against test suites, auditing Non-Goal (NG-*) violations,
  or reconciling issue tracker data with project documentation.
---

# Project Tracker

A service-agnostic tracking and compliance audit skill: reconciles external issue tracker data
(JSON, CSV, TSV, XML, Markdown tables, or plain text dumps) and repository code ground truth
against project specifications (`docs/plans/`) and architectural invariants (`docs/adr/`).

## 1. Principles of Ground-Truth Tracking

1. **Service-Agnostic**: Does not depend on any specific issue tracker API. Treats all tracker inputs
   as generic data dumps and normalizes them into canonical states.
2. **Code Ground Truth Over Claimed Status**: Never trust a "Closed" ticket or "Done" plan item
   without verifying target files, test assertions in code, and clickable evidence links.
3. **Three-Way State Reconciliation**:
   ```text
          [ Plan Document (docs/plans/) ]
                    ▲      ▲
                   /        \
                  ▼          ▼
   [ Issue Tracker Dump ] ◄──► [ Code Ground Truth ]
   ```
4. **Zero Tolerance for Boundary Breaches**: Work that violates an explicit Non-Goal (`NG-*`) or
   contradicts an accepted Architecture Decision Record (`ADR-NNNN`) is flagged immediately as a
   critical violation.

## 2. Ingestion & Status Normalization

Extract canonical fields from any provided issue tracker dump (see `references/progress-and-compliance.md`):
- `Identifier`, `Title`, `Status`, `Type`, `Estimate`, `Dependencies`, `Target Scope`, `PRs/Commits`.

Map tracker-specific workflows into four normalized states:
- **`OPEN`**: Backlog, To Do, Ready, Proposed, New, Triaged.
- **`IN_PROGRESS`**: In Dev, Doing, Started, WIP, In Review, Review.
- **`BLOCKED`**: On Hold, Waiting, Impeded, Paused.
- **`DONE`**: Closed, Resolved, Complete, Merged, Shipped, Fixed.

### Mapping to Plan Items
- Link external issues to plan items (`TSK-*`, `REQ-*`, `M-*`, `G-*`) by direct mention, provenance link, or affected files.
- Any issue or code addition with no link to an approved `REQ-*` or `G-*` is flagged as potential **Scope Creep**.

## 3. Audit Protocol

### Step 1: Verify Code Ground Truth
When a code path or worktree is available:
1. **Target Files**: Verify that paths named in `Target Files:` exist and were modified in the repository.
2. **Acceptance Criteria Traceability**: Trace each Given/When/Then AC in `REQ-*` to concrete implementation and test assertions in code.
3. **Fitness Functions**: Verify that automated fitness functions defined in `docs/adr/` exist and pass.

### Step 2: Violation & Guardrail Detection
Actively audit for four distinct classes of violations:
1. **Non-Goal (`NG-*`) Violations (Critical)**: Newly introduced code or tickets that implement explicitly excluded capabilities.
2. **Architectural Contradictions (`ADR-*`, `DT-*`, `REJ-*`)**: Code or tickets reviving rejected proposals or bypassing decision tree rules.
3. **Sequencing Violations**: Tasks marked `IN_PROGRESS` or `DONE` whose upstream prerequisites (`Depends On`) are not complete.
4. **Scope Creep / Phantom Work**: Unmapped tickets or untracked code changes lacking approved requirement coverage.

### Step 3: Governance Gates Check
1. **Unvalidated Assumptions (`ASM-*`)**: Flag active requirements whose underlying assumptions remain unvalidated.
2. **Open Blocking Questions (`Q-*`)**: Work must not proceed on requirements blocked by unanswered questions.
3. **Unmitigated High Risks (`RSK-*`)**: High-impact risks must have assigned mitigation tasks (`TSK-*`).

### Step 4: Automated Evidence Discovery (Zero Hunting)
Query Git and GitHub to discover all work linked to the plan slug without manual searching:
1. **Commits matching plan**: `git log --grep="<slug>" --format="%h %s"`
2. **PRs mentioning plan**: `gh pr list --search "<slug> in:body" --state all --json number,title,url,headRefName`
3. **Trailers**: Extract `Plan: <slug>:<TSK-xxx>` or `Ticket: <key>` trailers from commit bodies.

### Step 5: Reconcile & Report
1. **Generate Report**: Render audit findings using `templates/progress-report.md`.
2. **Review Discrepancies**: Present findings, progress percentages, and proposed fixes to the user via `ask_question` (recommended action first).
3. **Update Documentation**: Upon explicit user approval:
   - Update `TSK-*` statuses (`[Proposed]` $\to$ `[In Progress]` $\to$ `[Done]`) and backfill `- **Evidence**: [PR #...](url) · Commit `sha` · [Ticket ...](url)` (PRs and tickets formatted as clickable links; git SHAs as code literals).
   - Check off verified acceptance criteria (`- [x] Given...`).
   - Append an audit row with Evidence links to the plan's `## Revision Log`.

## 4. Definition of Done (Audit Gate)

Before declaring any task, milestone, or plan complete:
- [ ] Every completed task has verified target files present in the codebase.
- [ ] Acceptance criteria checked `[x]` only when implementation and test assertions are confirmed in code.
- [ ] Completed tasks have `- **Evidence**:` populated with verified PR/ticket links and commit SHAs.
- [ ] Zero unaddressed Non-Goal (`NG-*`) or Architecture (`ADR-*`/`REJ-*`) violations.
- [ ] No sequencing violations: all `Depends On` prerequisites completed before downstream work.
- [ ] Scope creep triaged (rejected, extracted into a new plan, or formally approved).
- [ ] Governance gates intact: no active work proceeding under unvalidated `ASM-*` or open blocking `Q-*`.
- [ ] Three-way reconciliation complete across tracker, plan, and code ground truth.
- [ ] Plan revision log updated with audit record, date, and Evidence links.

## 5. Templates & References

- `templates/progress-report.md` — Progress, ground truth, and compliance audit report
- `references/progress-and-compliance.md` — Ingestion heuristics, status normalization, and ground-truth code auditing
