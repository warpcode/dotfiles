# Criterion-to-Code Evidence Verification

Tracker-agnostic rules for scoping issue hierarchies, assembling an evidence packet, building a criterion matrix, classifying code visibility, and gating report completeness.

---

## 1. Scoping Rules

The selected issue or epic defines the verification boundary:

1. **Epic / Parent Initiative**: Read the epic and **every direct child issue and subtask**. Read explicitly linked upstream or external dependencies for context, keeping contextual dependencies separate from epic deliverables.
2. **Non-Epic Issue (Story / Task / Bug)**: Keep the selected issue primary. Read its subtasks and directly linked issues. Read its parent epic only for broader context; read siblings and their subtasks only when a dependency, shared implementation, or explicit link makes their remaining work relevant. Do not silently expand scope to the entire parent epic.
3. **Ambiguity & Missing Data**: Record every included ticket's requirements, status, and links. Label missing, ambiguous, or inaccessible evidence explicitly; never invent acceptance criteria from a title alone.

---

## 2. Linked Evidence Retrieval

1. Inventory relevant links across in-scope items, comments, and attachments (design specs, ADRs, RFCs, dashboards, Figma nodes, external docs). Do not recursively follow unrelated references.
2. Use the appropriate source-specific tool (MCP server, CLI, or API) for each external artifact. Never substitute a login wall or a ticket's paraphrase for unread source content.
3. Extract concrete requirements or behavior supported by the linked artifact alongside its URL or artifact ID. If authentication, permissions, or the required tool is unavailable, record the exact gap rather than claiming the artifact was reviewed.

---

## 3. Evidence Packet & Delta Re-Checks

Before inspecting diffs or delegating read-only code sweeps, establish a compact **evidence packet** containing:
- The extracted **criterion matrix** (one row per issue key + requirement).
- **Linked-artifact facts** (design/spec constraints with IDs/URLs).
- **Pinned PR heads, bases, and review/check state** (`headRefOid`, `baseRefName`, merge state).

After establishing this baseline, retrieve only missing facts or deltas since the pinned revision. When a PR head moves, re-inspect only the affected diff and re-evaluate the criteria that diff can impact.

---

## 4. Criterion Matrix & Visibility Classification

Extract every bullet, acceptance criterion, or design-derived requirement into a flat matrix **before** reading source code:
- **One Key, One Requirement**: Preserve each direct child and subtask as its own issue key, even when marked closed/done. Never collapse multiple issue keys into a single row or merge compound criteria just to shorten a table.

Inspect relevant implementation files, call sites, and tests at the pinned PR/branch revisions (including merged child work in the integration/parent branch and open child branches against their own bases). Classify each row as:

| Classification | Definition |
|---|---|
| **`Visible`** | Concrete implementation establishing the criterion is present in pinned source (and wired into active execution paths). |
| **`Partially visible`** | Some implementation is visible in pinned source, but an edge case, integration link, error path, or concrete sub-requirement remains missing. |
| **`Not visible`** | No supporting implementation is present in pinned source, or requirements are too ambiguous to verify. |
| **`External`** | Behavior is managed outside repository code (e.g., external SaaS config, infrastructure toggle) and is not established in source. |

### Evidence Rules
- **No Claim-by-Status**: A tracker status (`Done`/`Closed`), a merged PR, a green CI run, or an author comment is **never** proof that a criterion is implemented. Cite exact `file:line` references, symbol names, or commit SHAs.
- **Optional Verification Evidence**: Unit tests, integration checks, and authorized runtime/browser checks strengthen confidence when present, but source visibility is the primary classification axis; do not mark a source-visible criterion incomplete solely because optional browser/runtime checks were not run.
- **Non-Meta / Read-Only Discipline**: Progress verification is read-only. Do not turn a progress audit into an unrequested code-style peer review; flag only criterion-affecting mismatches, stub/unwired code, and sequencing breaches.

---

## 5. Completeness Gate

Verify all conditions below before finalizing any criterion-level progress report:

1. **Full Scope Coverage**: The evidence packet names every in-scope issue key (epic + all direct children + subtasks), with external dependencies clearly marked contextual.
2. **1:1 Matrix Accounting**: Every extracted criterion appears in exactly one matrix row (`report row count == matrix criterion count`), each naming one issue key and one testable requirement.
3. **External Artifact Accounting**: Every linked external design or spec either cites retrieved artifact evidence or records an explicit tool/access gap.
4. **PR Inventory Completeness**: The PR inventory lists the epic PR (if any) and every open child or stacked PR with `base`, `head` (pinned SHA), CI check state, and dependency alignment. Merged PRs are recorded as contextual implementation evidence.
5. **Pinned Revision Alignment**: Findings are reconciled against the latest pinned head so already-fixed items are not reported as open defects.
