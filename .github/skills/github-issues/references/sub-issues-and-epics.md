# GitHub Native Sub-Issues, Epics & Dependency Graph

Reference guide for structuring multi-issue Epics, linking native GitHub Sub-Issues, and annotating machine-parseable dependencies.

---

## 1. GitHub Native Sub-Issues API

GitHub Sub-Issues establish parent-child hierarchies across repositories.

> **Key Identifier Invariant**: The REST `sub_issue_id` parameter requires the child issue's **integer database `id`** (returned by `gh api repos/{owner}/{repo}/issues/{number} --jq .id`), **NOT** its human-facing issue `number` (e.g., `403`).

### REST Endpoints (`gh api`)

| Operation | Method & Endpoint | Notes |
|---|---|---|
| **List sub-issues** | `GET repos/{owner}/{repo}/issues/{parent_num}/sub_issues` | Lists child issues linked to parent |
| **Get parent issue** | `GET repos/{owner}/{repo}/issues/{child_num}/parent` | Returns the parent issue (404 if none) |
| **Add sub-issue** | `POST repos/{owner}/{repo}/issues/{parent_num}/sub_issues` | Body: `-F sub_issue_id=<int_db_id>` (optional `-F replace_parent=true`) |
| **Remove sub-issue** | `DELETE repos/{owner}/{repo}/issues/{parent_num}/sub_issue` | Body: `-F sub_issue_id=<int_db_id>` |
| **Reprioritize sub-issue** | `PATCH repos/{owner}/{repo}/issues/{parent_num}/sub_issues/priority` | Body: `-F sub_issue_id=<int_db_id>` and `-F after_id=<int_db_id>` or `-F before_id=<int_db_id>` |

### GraphQL Fields & Mutations

- **Queries**: Query `issue(number: $n) { parent { number title state } subIssues(first: 50) { totalCount nodes { number title state } } }` with header `GraphQL-Features: sub_issues` if required by the client version.
- **Mutations**: `addSubIssue(input: {issueId: $parentNodeId, subIssueId: $childNodeId})` and `removeSubIssue(...)` accept GraphQL global node IDs (`I_...`).

---

## 2. Parent Epic Structuring

Structure Epic issues so both humans and automated trackers can reconcile scope, branch topology, and completion status:

1. **Epic Metadata & Branch Target**:
   - Label the issue (e.g., `epic` / `architecture`).
   - If subtasks land into a shared integration branch before merging to trunk, declare the integration branch explicitly in the Epic body (`Base branch: epic/<id>-<slug>`).
2. **Recommended Epic Sections**:
   - **Objective & Problem Statement**: Why the initiative exists and the target end state.
   - **Non-Goals / Boundaries**: Explicit exclusions to prevent scope creep in child PRs.
   - **Execution Plan / Child Tasks**: Tasklist (`- [ ] #101 ...`) paired with native Sub-Issue links so progress rolls up natively in GitHub UI and APIs.
   - **Acceptance Criteria**: End-to-end verification criteria across the completed Epic.
3. **Child Issue Conventions**:
   - Reference the parent Epic (`Parent: #100` or `Part of #100`) and ensure the native sub-issue link is attached.
   - Specify target `baseRefName` (`main`/`master` or `epic/<id>-<slug>`) when non-default.

---

## 3. Machine-Parseable Dependency Markers

Use standardized, single-line dependency markers in issue and PR bodies so triage scripts (`github-cli/scripts/pr_audit_bundle.sh`, project trackers) can detect ordering constraints automatically:

| Marker | Meaning | Example |
|---|---|---|
| `Depends on #N` | Functional or code prerequisite; `#N` must ship before this issue/PR can complete or merge | `Depends on #401` |
| `Blocked by #N` | Hard blocker preventing execution or review progression until `#N` is resolved | `Blocked by #402` |
| `Depends on owner/repo#N` | Cross-repository prerequisite | `Depends on warpcode/cloakenv#189` |

### Dependency Shipped Verification Rule

- A dependency issue showing `state: CLOSED` is **not** proof that the dependency actually shipped — an issue can be closed as won't-fix, duplicate, or superseded without code landing.
- Always confirm at least one merged PR in `closedByPullRequestsReferences` (or verify the required symbols/files exist on the target base branch) before treating a `Depends on #N` or `Blocked by #N` marker as satisfied.
