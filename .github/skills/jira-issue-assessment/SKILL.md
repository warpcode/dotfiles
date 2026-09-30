---
name: jira-issue-assessment
description: >
  Assess progress on a Jira issue or epic against its requirements, related tickets,
  linked evidence, and implementation. Use when asked to "review this Jira issue",
  "assess this epic", or "compare these tickets to their PRs", including read-only
  assessments of work in progress.
argument-hint: "Jira issue key or URL"
---

# Jira Issue Assessment

Assess the supplied Jira key or URL in read-only mode. Follow applicable repository instructions and load relevant review or tool skills. The selected issue determines the review boundary; related issues supply context only where relevant.

## Establish Scope

1. Retrieve the selected issue's description, acceptance criteria, status, comments, attachments, links, and relevant history. Respect explicit exclusions and do not relay secrets.
2. If it is an epic, read every direct child and its subtasks; read explicitly linked dependencies for context, distinguishing their work from epic deliverables.
3. Otherwise, keep the selected issue primary. Read its subtasks and relevant linked issues. If it has a parent, read that parent for broader context; read siblings and their subtasks only when a dependency, shared implementation, or explicit link makes their remaining work relevant. Do not automatically assess the parent's entire epic.
4. Record each included ticket's requirements, current status, and links. Label missing, ambiguous, or inaccessible evidence; never invent acceptance criteria from a title.

## Retrieve Linked Evidence

1. Inventory relevant links in the selected issue and its scoped parent, sibling, child, and linked issues, including links in comments and attachments. Identify what each link could establish for the assessment; do not recursively follow unrelated references.
2. For each relevant source, check for an appropriate available MCP server, tool, or skill and follow its required usage instructions. Prefer a source-specific read mechanism for designs, documents, repositories, dashboards, and other external artifacts; do not substitute a browser login screen or a ticket's description for unread source content. Use general web access only when permitted and no more suitable mechanism exists.
3. If an in-scope Jira ticket, comment, or attachment links to Figma, read the repository Figma prompt and use the Figma MCP calls it requires before comparing source with the design. For an assessment, record the node, the actual design requirements extracted, and whether comparison is source-only or browser-verified. Do not call a design inaccessible without attempting the available Figma MCP read path.
4. Extract the requirements or behavior that the linked source actually supports, with its URL or artifact identifier. If access, authentication, or the required tool is unavailable, state exactly what could not be verified; do not claim the linked material was reviewed.

## Verify Implementation

Before delegating or repeating source retrieval, create and preserve a compact
evidence packet containing the ticket criterion matrix, linked-design facts,
pinned PR heads and review state. Give that packet to subsequent specialists.
After the baseline is established, retrieve only a missing fact or a delta since
the pinned revision; do not repeat Jira hierarchy, PR-search, or full-diff work
unless the issue scope or PR head changed. When a head changes, inspect the
affected diff and re-evaluate only the criteria it can affect.

1. Independently verify PR state, head, base, and ticket relationship using issue links, every in-scope Jira key, branch names, PR descriptions, and head/base ancestry. For epics, find the epic PR and every unmerged child or stacked PR; do not stop at PRs named in the epic. List merged child PRs only as contextual implementation evidence. Explicitly state when no open child PR exists.
2. For every issue in scope, extract every Jira bullet, acceptance criterion, or design-derived requirement into a criterion matrix before reading source. Preserve each direct child and subtask as a separate issue key, even when it is Closed. Do not combine multiple issue keys as `Child/subtasks`, and do not combine compound criteria merely to shorten the report.
3. Inspect the relevant code changes and call sites at pinned PR revisions, including merged child work in the current parent branch and still-open child branches against their own bases. Map every matrix criterion to the implementing PR, exact code or artifact evidence, status, and a specific remaining check. Distinguish source implementation from tested behavior. A ticket's Jira state, PR merge, or author comment is not proof that its criteria are met. If no PR exists, inspect available implementation evidence and report what cannot be established.
4. For each associated PR, inspect current checks, reviews, change requests, and review threads. Compare feedback with the latest head: identify active unresolved requests, responses awaiting reviewer confirmation, outdated threads whose concern is still present, and outdated threads actually addressed by code. A reply, an outdated marker, or a passing check alone does not resolve a request. Report the effect on the relevant issue's criteria without performing a full code-quality peer review.
5. Verify claims using the appropriate source, tests, or authorized runtime checks. If a linked design or external service cannot be inspected through an allowed read mechanism, mark the comparison unverified rather than asserting it matches. If the head moves during assessment, recheck affected criteria and review feedback at the new revision or clearly state the pinned-review limit.

## Completeness Gate

Do not draft the report until all checks below are true:

1. The evidence packet names every in-scope issue key, including every direct child and subtask, plus each external dependency marked contextual.
2. The criterion matrix has one row for every extracted criterion. Each row names exactly one issue key and exactly one testable requirement; a count of report rows must equal the count of matrix criteria.
3. Every linked Figma node has MCP evidence or an explicit tool-access failure. A browser login screen, an untried MCP path, or a Jira paraphrase is not design evidence.
4. The PR inventory includes the epic PR and all discovered open child/stacked PRs, each with base, pinned head, checks, and thread disposition. Merged PRs are contextual only.
5. Findings are reconciled with the pinned head so fixed concerns are not reported as current defects.
6. Before delivery, run the report validator using every in-scope issue key, the exact criterion-matrix row count, and `--require-figma-evidence` when Figma is in scope:

```bash
python3 <skill-dir>/scripts/validate_assessment_report.py report.md \
  --expected-issue <KEY> \
  --criterion-count <matrix-row-count> \
  --require-figma-evidence
```

## Report

Use [templates/assessment-report.md](templates/assessment-report.md) exactly: do not omit, rename, merge, or reorder its headings, subsections, or table columns. Open with the selected issue's title and link, its focus, and a very brief assessment of condition, Jira state, and progress. Then enumerate all remaining work in the relevant issue hierarchy: the selected issue, its parent, children/subtasks, and relevant sibling issues or their children/subtasks. Base each remaining-work claim on the criterion assessment, not Jira status alone; label unverified work as needing verification rather than incomplete. Keep contextual issues distinct from selected-issue deliverables, and assess criteria even for tickets marked done.

After that overview, present the executive project-progress table, criterion-level coverage, and PR review-state inventory. The progress table must report total criteria, implementation status counts, verification status counts, blocking findings, open PRs, and failed checks. Split `## Requirement Assessment` into exactly these subsections, in this order: `### Completed / Met in Source`, `### Partially Met`, and `### Incomplete / Unverified`. Put every criterion in exactly one subsection and preserve one row per independently testable requirement. Each requirement row must separately state implementation status and verification status, identify the evidence type, name the owner or implementing PR, and classify the release gate as `Blocking`, `Non-blocking`, or `Contextual`. The first subsection is for criteria established in source or runtime; the second is for criteria with some supporting evidence but a concrete limitation; the third is for criteria with no sufficient proof, an unmet requirement, or an ambiguous requirement. For every row in the second and third subsections, state the specific reason and the concrete next check or correction. Do not use Jira status, a merged PR, or an author comment as proof. Report severity-ordered, evidence-backed defects only where a concrete mismatch affects a criterion; give code location, requirement, impact, and proposed correction. Separately list ambiguous requirements and validation gaps. End with the template's concise Conclusion. Do not present source inference as tested runtime behavior.

Do not edit files, switch branches, mutate Jira or GitHub, post comments, or run tests against a checkout other than the reviewed revision. Never submit a review without the user's explicit request.