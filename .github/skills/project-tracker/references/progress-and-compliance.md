# Progress Tracking, Ground-Truth Code Auditing & Compliance Guide

Guidelines for service-agnostic progress tracking, code ground-truth verification, violation detection, and documentation reconciliation.

---

## 1. Principles of Service-Agnostic Tracking

`project-tracker` is service-blind. It does not integrate with or assume the API, schema, or quirks of any specific issue tracker (Jira, Linear, GitHub Issues, GitLab, Asana, Bugzilla, etc.). Instead, it treats all external issue information as a **generic data dump** and reconciles it against the project plans (`docs/plans/`), architectural invariants (`docs/adr/`), and the **code ground truth** in the project directory or worktree.

### Input Sources

When tracking progress or auditing compliance, you may be provided:
1. **An Issue Tracker Data Dump**: In any format — JSON, CSV, TSV, XML, Markdown tables, or unstructured text exports.
2. **A Path to Project Code**: A local directory, git worktree, or repository checkout.
3. **Both** (ideal for complete three-way reconciliation).

---

## 2. Ingesting & Normalizing Arbitrary Issue Dumps

Because dumps come in wildly varying shapes, extract and normalize the following core fields from whatever structure is provided:

| Canonical Field | Synonyms / Common Keys | Target Meaning |
|---|---|---|
| **`Identifier`** | `id`, `key`, `issue_key`, `number`, `slug`, `ticket` | Unique external tracker ID (e.g. `PROJ-123`, `#45`) |
| **`Title`** | `title`, `summary`, `name`, `subject`, `headline` | Concise statement of the work |
| **`Status`** | `status`, `state`, `stage`, `column`, `resolution` | Current lifecycle state in the tracker |
| **`Type`** | `type`, `issue_type`, `kind`, `category` | Task, Story, Bug, Spike, Epic |
| **`Estimate`** | `points`, `story_points`, `estimate`, `size`, `hours` | Work sizing (map to story points) |
| **`Dependencies`** | `depends_on`, `blocked_by`, `issuelinks`, `links`, `prerequisites` | Preceding or blocking items |
| **`Target Scope`** | `files`, `paths`, `target_files`, `changed_files`, `components` | Code paths touched or planned |
| **`Links / PRs`** | `pr`, `prs`, `pull_request`, `commits`, `branches` | Code changes linked to this item |

### Status Normalization Matrix

Map any tracker-specific workflow status to one of four canonical states:

```text
[Tracker Status] ──────────────────────────────────────────► [Normalized Plan State]
Open, Backlog, To Do, Ready, Proposed, New, Triaged        ► OPEN
In Progress, In Dev, Doing, Started, WIP, In Review, Review ► IN_PROGRESS
Blocked, On Hold, Waiting, Impeded, Paused                  ► BLOCKED
Done, Closed, Resolved, Complete, Merged, Shipped, Fixed    ► DONE
```

### Mapping Issues to Plan Items

Link each external issue to plan items (`G-*`, `NG-*`, `REQ-*`, `M-*`, `TSK-*`):
1. **Direct Mention**: Search the issue's identifier, title, description, and labels for plan IDs (`TSK-001`, `REQ-002`).
2. **Provenance Link**: Check the plan's `Sources:` or task titles for the issue identifier.
3. **Semantic Matching**: If no IDs exist, map issues by matching target deliverables, affected files, or charter goals.
4. **Unmapped Issues**: Any issue in the dump with no plan mapping must be flagged as potential **Scope Creep** (see §4).

---

## 3. Code Ground-Truth Auditing (Worktree / Repository)

Never trust the status declared in an issue tracker or plan document without checking the code. When a project code path is available, perform rigorous ground-truth verification:

### 1. Target Files Check
For every `TSK-*`:
- Verify whether the paths in `Target Files:` exist in the codebase.
- Check whether they were actually modified, created, or if they are unchanged stubs.
- If a task is marked `Done` in the tracker but its `Target Files` do not exist, flag a **Ground-Truth Discrepancy**.

### 2. Done Command Verification
For every `TSK-*` with a `Done Command:`:
- Inspect the command (e.g. `./validate.sh`, `python3 -m unittest ...`, linter).
- If the environment is safe and non-destructive, verify that the command passes.
- If running the command is prohibited or impractical, statically verify that the referenced test files, scripts, or targets exist and contain relevant assertions.
- A passing done command is required to verify a task as complete.

### 3. Acceptance Criteria (`AC`) Code Traceability
For every `REQ-*`:
- For each Given/When/Then acceptance criterion:
  - Search test suites and implementation code for the specific triggers, conditions, and expected outcomes.
  - Classify the criterion as:
    - **Met in Code**: Concrete implementation and matching test assertions visible in source.
    - **Partially Met**: Implementation visible, but edge case, error handling, or test assertions missing.
    - **Unverified / Missing**: No matching implementation or assertions found in the codebase.
- Do NOT check off `[x]` in `SPEC.md` if the code lacks evidence.

### 4. Fitness Function Auditing
For every `ADR-*`:
- Check the `Fitness Function:` specified in `DECISIONS.md`.
- Verify that the test, linter, rule, or architectural boundary test actually exists and runs in CI or locally.

---

## 4. Violation Taxonomy & Detection

Rigorous progress tracking means catching violations before they become tech debt or security holes. Actively audit for four distinct classes of violations:

### 1. Non-Goal (`NG-*`) Violations (Critical)
- **Check**: Compare all issue titles, descriptions, and newly modified code files/APIs against every `NG-*` in the plan and its ancestor plans.
- **Signal**: Implementation of excluded protocols, unauthorized external dependencies, or unapproved features.
- **Action**: Immediately flag as a **Critical Boundary Violation**. The work must either be abandoned/reverted or the Non-Goal formally superseded via Workflow B with explicit user approval.

### 2. Architectural Contradictions (`ADR-*`, `DT-*`, `REJ-*`)
- **Check**:
  - Compare work against `REJ-*` proposals and the `Rejected / Ruled Out:` fields of active ADRs.
  - Compare implementation branching against `DT-*` decision trees.
  - Check whether code adheres to the fitness function in active ADRs.
- **Signal**: Re-implementing a rejected alternative, bypassing a decision tree rule, or introducing a pattern forbidden by an ADR.
- **Action**: Flag as an **Architectural Contradiction**. Work must pause until an ADR amendment or redesign is approved.

### 3. Sequencing & Prerequisite Violations
- **Check**: Verify the `Depends On:` graph for every active or completed task/requirement.
- **Signal**: A task is marked `IN_PROGRESS` or `DONE` while one of its prerequisite tasks or requirements is still `OPEN`, `BLOCKED`, or marked `Needs Review`.
- **Action**: Flag as a **Sequencing Violation**. Identify hidden dependencies or unblock prerequisites before declaring progress.

### 4. Scope Creep & Phantom Work
- **Check**: Identify any issue in the tracker dump or any major code addition in the worktree that does not trace back to an approved `REQ-*` or `G-*`.
- **Signal**: "Nice-to-have" features, refactorings, or unrelated bugfixes bundled into project branches without plan coverage.
- **Action**: Flag as **Scope Creep**. The engineer must either extract the work into a separate plan, reject it, or submit it for Workflow B scrutiny.

---

## 5. Documentation Drift & Governance Audits

Ensure the documentation is completely accurate and reflects reality:

### Three-Way State Reconciliation

Audit the alignment between the three sources:

```text
       [ Plan Document (SPEC.md) ]
                 ▲      ▲
                /        \
               ▼          ▼
[ Issue Tracker Dump ] ◄──► [ Code Ground Truth ]
```

- **Tracker Done, Plan Proposed**: Issue tracker closed the ticket, but `SPEC.md` was never updated.
- **Plan Done, Tracker Open**: Plan marked complete, but ticket was abandoned or forgotten in tracker.
- **Tracker/Plan Done, Code Missing**: Task claimed complete by team or tracker, but files or tests do not exist in the repository (phantom completion).
- **Code Done, Plan Missing**: Code merged or implemented without requirement or task coverage.

### Governance Gates Audit

1. **Unvalidated Assumptions (`ASM-*`)**:
   - Check if any `REQ-*` with active or completed tasks depends on an `ASM-*` whose validation is still "TBD" or untested.
   - If an assumption proved false during implementation, flag it immediately.
2. **Open Blocking Questions (`Q-*`)**:
   - Check if any active or completed `REQ-*` has an associated `Q-*` where `Blocking: Yes` and `Answer:` is empty. Work must not proceed on blocked requirements.
3. **Unmitigated High Risks (`RSK-*`)**:
   - Verify that every high-impact risk affecting an active requirement has an assigned mitigation or mitigation task (`TSK-*`).

---

## 6. Actionable Reconciliation Protocol

When the audit is complete:

1. **Produce the Audit Report**: Render using `templates/progress-report.md`.
2. **Review with User**: Present findings, progress metrics, and discovered violations (`ask_question`, recommended action first).
3. **Update Plan Documents**:
   - Query commits (`git log --grep="<slug>" --format="%h %s"`) and PRs (`gh pr list --search "<slug> in:body"`) to discover linked evidence.
   - Update `TSK-*` statuses (`[Proposed]` → `[Accepted]` → `[In Progress]` → `[Done]`) and backfill `- **Evidence**: PR <number> · Commit <sha> · Ticket <id>`.
   - Check off verified acceptance criteria (`- [x] Given ...`).
   - If scope creep is approved, add new items with the next consecutive IDs.
   - If non-goal or architectural violations are found, resolve them via `docs/adr/` or reject the invalid work.
   - Append an audit row with Evidence links to the plan's `## Revision Log`.
