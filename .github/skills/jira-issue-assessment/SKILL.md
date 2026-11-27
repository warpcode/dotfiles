---
name: jira-issue-assessment
description: >
  Assess progress of a Jira issue or epic in read-only mode by retrieving Jira
  hierarchy and dependency links and verifying acceptance criteria against
  repository code. Use when asked to "assess this Jira issue", "check Jira
  progress", or "is this Jira ticket in the code?".
argument-hint: "Jira issue key or URL"
---

# Jira Issue Assessment

Thin Jira adapter for read-only criterion-to-code progress verification.
Retrieve Jira context with `jira-api`, then apply the shared verification
methodology in `../project-tracker/references/criterion-evidence-verification.md`.

## 1. Jira Retrieval Adapter

1. **Selected Issue & Details**: Fetch description, acceptance criteria, status,
   comments, attachments, and `issuelinks` via `jira-api` (`issues KEY --fields "summary,status,description,issuelinks,parent,subtasks,comment,attachment"`).
2. **Epic Children & Subtasks**: When the selected issue is an epic, query all
   direct children via JQL `parent = KEY` (plus any child subtasks) using
   `jira-api` `jql`.
3. **Dependencies (`issuelinks`)**: Extract `Blocks` / `is blocked by` links as
   contextual upstream/downstream edges and keep contextual work separate from
   epic deliverables.
4. **Linked Designs & External Artifacts**: For linked designs or documents
   (e.g., Figma URLs, Confluence specs), use the source-specific tool or MCP
   server (such as the Figma MCP); if unavailable or unauthenticated, record the
   exact access gap rather than claiming review.

## 2. Shared Verification & Completeness Rules

Apply `../project-tracker/references/criterion-evidence-verification.md` (and
`project-tracker` three-way reconciliation when checking PR stacks):
- **Scoping & Evidence Packet**: Pin PR heads/bases, record linked-artifact
  facts, and perform delta-only re-checks if a PR head moves.
- **1:1 Criterion Matrix**: Extract one row per issue key and testable
  requirement; classify each as `Visible`, `Partially visible`, `Not visible`,
  or `External` with exact `file:line` citations.
- **No Claim-by-Status**: Jira status, merged PRs, passing CI, or comments are
  not proof of criterion completion.
- **Completeness Gate**: Verify every in-scope issue key, 1:1 row accounting,
  PR inventory (`base`, pinned `head`, checks), and reconciliation against
  pinned revisions. Present findings concisely, grouping criteria by visibility
  status rather than enforcing a single rigid template.

## Read-Only Constraint

Do not edit files, switch branches, mutate Jira or GitHub, post comments, or
run tests against a checkout other than the reviewed revision. Never submit a
review without the user's explicit request.
