---
name: jira-issue-assessment
description: >
  Produce a read-only progress assessment of a Jira issue or epic against its criteria,
  related tickets, linked evidence, and whether each requirement is visible in pinned
  source. Use for "assess this Jira issue", "check progress", or "is this in the code?".
argument-hint: "Jira issue key or URL"
---

# Jira Issue Assessment

Assess the supplied Jira key or URL in read-only mode. This is a progress assessment, not a peer review: determine whether each requirement is visible in the relevant pinned source, partially visible, or not established by code. Follow applicable repository instructions and load source-specific tools as needed. Do not perform a general code-quality review. The selected issue determines the review boundary; related issues supply context only where relevant.

## Establish Scope

1. Retrieve the selected issue's description, acceptance criteria, status, comments, attachments, links, and relevant history. Respect explicit exclusions and do not relay secrets.
2. If it is an epic, read every direct child and its subtasks; read explicitly linked dependencies for context, distinguishing their work from epic deliverables.
3. Otherwise, keep the selected issue primary. Read its subtasks and relevant linked issues. If it has a parent, read that parent for broader context; read siblings and their subtasks only when a dependency, shared implementation, or explicit link makes their remaining work relevant. Do not automatically assess the parent's entire epic.
4. Record each included ticket's requirements, current status, and links. Label missing, ambiguous, or inaccessible evidence; never invent acceptance criteria from a title.

## Retrieve Linked Evidence

1. Inventory relevant links in the selected issue and its scoped parent, sibling, child, and linked issues, including links in comments and attachments. Identify what each link could establish for the assessment; do not recursively follow unrelated references.
2. For each relevant source, check for an appropriate available MCP server, tool, or skill and follow its required usage instructions. Prefer a source-specific read mechanism for designs, documents, repositories, dashboards, and other external artifacts; do not substitute a browser login screen or a ticket's description for unread source content. Use general web access only when permitted and no more suitable mechanism exists.
3. If an in-scope Jira ticket, comment, or attachment links to Figma, read the repository Figma prompt and use the Figma MCP calls it requires before comparing source with the design. Record the node, design requirements extracted, and whether each is visible in pinned source. Browser comparison is optional and must not be required to complete the progress assessment. Do not call a design inaccessible without attempting the available Figma MCP read path.
4. Extract the requirements or behavior that the linked source actually supports, with its URL or artifact identifier. If access, authentication, or the required tool is unavailable, state exactly what could not be verified; do not claim the linked material was reviewed.

## Assess Progress Against Criteria

Before delegating or repeating source retrieval, create and preserve a compact
evidence packet containing the ticket criterion matrix, linked-design facts,
pinned PR heads and review state. Give that packet to subsequent specialists.
After the baseline is established, retrieve only a missing fact or a delta since
the pinned revision; do not repeat Jira hierarchy, PR-search, or full-diff work
unless the issue scope or PR head changed. When a head changes, inspect the
affected diff and re-evaluate only the criteria it can affect.

1. Independently verify PR state, head, base, and ticket relationship using issue links, every in-scope Jira key, branch names, PR descriptions, and head/base ancestry. For epics, find the epic PR and every unmerged child or stacked PR; do not stop at PRs named in the epic. List merged child PRs only as contextual implementation evidence. Explicitly state when no open child PR exists.
2. For every issue in scope, extract every Jira bullet, acceptance criterion, or design-derived requirement into a criterion matrix before reading source. Preserve each direct child and subtask as a separate issue key, even when it is Closed. Do not combine multiple issue keys as `Child/subtasks`, and do not combine compound criteria merely to shorten the report.
3. Inspect relevant code changes and call sites at pinned PR revisions, including merged child work in the current parent branch and still-open child branches against their own bases. For every matrix criterion, record whether it is `Visible`, `Partially visible`, `Not visible`, or `External / not established in repository code`; cite exact source or artifact evidence and name the implementing PR/owner when known. A ticket's Jira state, PR merge, or author comment is not proof. If no PR exists, inspect available source evidence and state the limit.
4. Record associated PR state, base/head, checks, and review status. Include review feedback only when it affects an in-scope criterion or materially changes progress; do not enumerate unrelated style, security, or maintainability comments and do not conduct a peer review. A passing check or merged PR is not proof that a criterion is implemented.
5. Source visibility is the primary assessment. Tests and authorized runtime/browser checks may be reported as additional evidence when available, but are optional and MUST NOT be required to classify a criterion or complete the report. Do not classify a source-visible criterion as incomplete merely because browser verification was not run. Mark external behavior not established by repository code separately from source-visible implementation. If a PR head moves during assessment, recheck affected criteria or clearly state the pinned-revision limit.

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

Use [templates/assessment-report.md](templates/assessment-report.md) exactly: do not omit, rename, merge, or reorder its headings, subsections, or table columns. Open with the selected issue's title and link, its focus, and a very brief assessment of condition, Jira state, and progress. Then enumerate remaining work in the relevant issue hierarchy. Base each claim on criterion-level source visibility, not Jira status. Keep contextual issues distinct from selected-issue deliverables, and assess criteria even for tickets marked done.

After that overview, present the executive project-progress table, criterion-level coverage, and concise PR state relevant to progress. The progress table must report total criteria, code-visibility counts (`Visible`, `Partially visible`, `Not visible / external`), criteria needing clarification, blocking findings, open PRs, and failed or pending checks. Split `## Requirement Assessment` into exactly these subsections, in this order: `### Completed / Met in Source`, `### Partially Met`, and `### Incomplete / Unverified`. Put every criterion in exactly one subsection and preserve one row per independently testable requirement. Each row must state code visibility, implementation status, optional verification status, evidence type, owner or implementing PR, and release gate (`Blocking`, `Non-blocking`, or `Contextual`). Use the first subsection when implementation is visible in pinned source or runtime; use the second when some implementation is visible but a concrete limitation remains; use the third when it is not visible, externally managed without evidence, or ambiguous. For every row in the second and third subsections, state the specific reason and next check or correction. Do not use Jira status, a merged PR, or an author comment as proof. Report only concrete criterion-affecting mismatches as findings, with code location, requirement, impact, and proposed correction; do not turn the assessment into a general peer review. List ambiguous requirements and evidence gaps separately. Browser/runtime validation is optional, not a completion gate. End with the template's concise Conclusion and do not present source inference as runtime-tested behavior.

Do not edit files, switch branches, mutate Jira or GitHub, post comments, or run tests against a checkout other than the reviewed revision. Never submit a review without the user's explicit request.