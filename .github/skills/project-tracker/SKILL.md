---
name: project-tracker
description: >
  Track epic and issue progress across external trackers (Jira, GitHub Issues,
  Redmine, Kanban) and code ground truth. Delegates code inspections to
  subagents, gathers evidence from comments and commits, evaluates criteria in
  the context of the entire epic, and audits non-goals. Use when tracking
  project or epic progress, verifying ticket criteria in code, auditing ground
  truth, or reconciling external tracker status.
user-invocable: false
---

# Project Tracker

A service-agnostic tracking and compliance audit skill: reconciles external issue tracker data
(Jira, GitHub Issues, Redmine, Kanban boards, Linear, or plain text dumps) and repository code
ground truth against project specifications (`docs/plans/`) and architectural invariants (`docs/adr/`).

## 1. Principles of Ground-Truth Tracking

1. **Service-Agnostic Ingestion**: Does not care how tracker data is retrieved. If issue data is
   missing or outdated, the agent prompts the user for the necessary dump (JSON, CSV, markdown, or comments).
2. **Subagent Code Inspection**: Delegates deep code sweeps and file inspections to an isolated subagent
   (`invoke_subagent`) to gather ground-truth evidence without bloating the tracking context.
3. **Contextual Epic Evaluation**: Evaluates ticket criteria in the context of the entire epic:
   identifying blocked dependencies, tracking overall epic completion, and detecting orphaned work.
4. **Code Ground Truth Over Claimed Status**: Never trust a "Closed" ticket without verifying
   target files, test assertions in code, and clickable evidence links.
5. **Zero Tolerance for Boundary Breaches**: Work that violates an explicit Non-Goal (`NG-*`) or
   contradicts an accepted Architecture Decision Record (`ADR-NNNN`) is flagged immediately.

## 2. Ingestion & Information Request

### Requesting Missing Tracker Data
If external issue tracker data is not already provided, request the necessary information:
> *"To audit progress on Epic `<slug>`, please provide the latest ticket list, status updates, or comments (pasted JSON, CSV, Markdown table, Jira/Redmine dump, or issue links)."*

Extract canonical fields (see `references/progress-and-compliance.md`):
- `Identifier`, `Title`, `Status`, `Type`, `Estimate`, `Dependencies`, `Target Scope`, `PRs/Commits`, `Comments/Updates`.

Map tracker-specific workflows into four normalized states:
- **`OPEN`**: Backlog, To Do, Ready, Proposed, New, Triaged.
- **`IN_PROGRESS`**: In Dev, Doing, Started, WIP, In Review, Review.
- **`BLOCKED`**: On Hold, Waiting, Impeded, Paused.
- **`DONE`**: Closed, Resolved, Complete, Merged, Shipped, Fixed.

## 3. Audit Protocol & Subagent Code Inspection

### Step 1: Delegate Code Inspection to Subagent
To preserve token context and ensure rigorous verification, invoke a specialized subagent:
```json
{
  "Subagents": [{
    "TypeName": "research",
    "Role": "Code Ground-Truth Inspector",
    "Prompt": "Inspect repository for evidence satisfying acceptance criteria for Epic <slug> / Ticket <id>. Check target files <paths>, search git history for 'Plan: <slug>:<id>', verify exact file:line references for implementation, and confirm test assertions pass. Return a concise JSON summary of verified criteria and evidence."
  }]
}
```
The subagent inspects the repository read-only and returns verified `file:line` references, commit SHAs, and test outcomes.

### Step 2: Contextual Epic Evaluation
Evaluate each ticket in the context of the entire epic:
1. **Criteria Accounting**: For every child ticket, compare claimed status against subagent-verified code evidence.
2. **Epic Completion Percentage**: Calculate the proportion of total epic acceptance criteria provably satisfied in code.
3. **Blockers & Sequencing**: Identify tickets blocked by incomplete upstream dependencies or unmerged PRs.

### Step 3: Violation & Guardrail Detection
Actively audit for four distinct classes of violations:
1. **Non-Goal (`NG-*`) Violations (Critical)**: Code or tickets implementing explicitly excluded capabilities.
2. **Architectural Contradictions (`ADR-*`, `REJ-*`)**: Code violating accepted ADRs or reviving rejected patterns.
3. **Sequencing Violations**: Tasks marked `DONE` whose upstream prerequisites are not complete.
4. **Scope Creep / Phantom Work**: Code changes or tickets lacking approved requirement coverage.


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
