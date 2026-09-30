# <Selected issue title>

**Issue:** [<KEY>](<Jira URL>)  
**Focus:** <What this issue or epic is intended to deliver, in one sentence.>  
**Assessment:** <One or two sentences stating condition, current Jira state, and progress against the stated requirements. Distinguish verified progress from reported progress.>

## Project Progress

Report the exact current state before the detailed tables. Separate implementation from verification; source completion is not runtime acceptance.

| Measure | Result | Interpretation |
| --- | ---: | --- |
| Total criteria | <Count> | <All extracted requirements> |
| Implementation: complete | <Count> | <Implementation exists in source or runtime> |
| Implementation: partial | <Count> | <Some implementation exists, with a concrete limitation> |
| Implementation: incomplete | <Count> | <Unmet, ambiguous, or no implementation evidence> |
| Verification: source | <Count> | <Established by source inspection> |
| Verification: runtime/browser | <Count> | <Established by tests or authorized runtime/browser checks> |
| Verification: outstanding | <Count> | <Still requiring evidence> |
| Blocking findings | <Count> | <Confirmed defects or acceptance blockers> |
| Open implementation PRs | <Count> | <Current open PRs affecting scope> |
| Failed or pending checks | <Count> | <Checks that prevent acceptance or remain unresolved> |

## Remaining Issues

Summarize the outstanding criteria established in the assessment below, including the selected issue, its parent, children/subtasks, and relevant siblings or their children/subtasks. For an epic, include its direct children and their subtasks; list external dependencies separately as context. Use one row per issue key: never collapse several tickets into one `Child/subtasks` row. Do not list unrelated siblings merely because they share a parent. Include unmet criteria even when a ticket is marked done. Label work with insufficient evidence as "Verification needed," not as an implementation gap. If no remaining work is verified, say so explicitly.

| Relationship to selected issue | Issue | Jira state | Assessment | Remaining action and evidence |
| --- | --- | --- | --- | --- |
| <Selected / Parent / Child / Subtask / Relevant sibling / Sibling child / Linked dependency> | [<KEY>](<Jira URL>) | <Status> | <Partially met / Unmet / Verification needed> | <Specific criterion, PR/code evidence, and next verification or correction> |

## Requirement Assessment

Assess every criterion of every in-scope issue, including tickets marked done. Put every criterion in exactly one subsection below and preserve one row for every extracted criterion. Each row must contain exactly one issue key and one independently testable requirement; do not collapse requirements with conjunctions such as "Swagger, tests, send page, callback." Never substitute ticket status, a merged PR, or a Jira comment for implementation evidence.

### Completed / Met in Source

Use this subsection only when source or runtime evidence establishes the criterion. Set Implementation status to `Complete` and Verification status to `Source verified` or `Runtime verified`.

| Issue | Requirement or acceptance criterion | Implementation status | Verification status | Evidence type | Owner / implementing PR | Evidence | Release gate | Remaining action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [<KEY>](<Jira URL>) | <One testable criterion> | Complete | <Source verified or Runtime verified> | <source / test / runtime / browser / Figma / external workflow> | <Owner or PR at pinned revision> | <Code link, test, or linked artifact> | <Blocking / Non-blocking / Contextual> | <None, or a non-blocking follow-up check> |

### Partially Met

Use this subsection when evidence establishes only part of the criterion or a concrete defect/limitation remains. Set Implementation status to `Partial`, explain the limitation in the Evidence column, and name the specific correction or verification still needed in the final column.

| Issue | Requirement or acceptance criterion | Implementation status | Verification status | Evidence type | Owner / implementing PR | Evidence | Release gate | Remaining action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [<KEY>](<Jira URL>) | <One testable criterion> | Partial | <Source verified / Runtime verified / Outstanding> | <source / test / runtime / browser / Figma / external workflow> | <Owner or PR at pinned revision> | <PR, code link, test, or linked artifact> | <Blocking / Non-blocking / Contextual> | <Specific reason and next check or correction> |

### Incomplete / Unverified

Use this subsection when the criterion is unmet, unsupported by sufficient evidence, or ambiguous. Set Implementation status to `Incomplete` or `Unknown`, set Verification status to `Outstanding`, explain the reason in the Evidence column, and name the specific evidence, correction, or clarification required in the final column.

| Issue | Requirement or acceptance criterion | Implementation status | Verification status | Evidence type | Owner / implementing PR | Evidence | Release gate | Remaining action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| [<KEY>](<Jira URL>) | <One testable criterion> | <Incomplete or Unknown> | Outstanding | <source / test / runtime / browser / Figma / external workflow / none> | <Owner, PR, or None> | <Specific reason and available evidence> | <Blocking / Non-blocking / Contextual> | <Specific missing evidence, correction, or requirement clarification> |

## Findings

List confirmed defects in severity order. For each, give a code location, linked requirement, evidence, impact, and proposed correction. Keep known unfinished work distinct from a demonstrated defect. If there are no confirmed defects, say so.

## Open Questions And Evidence Gaps

State ambiguous requirements, inaccessible linked material, and unverified design or runtime claims. Do not substitute assumptions for inaccessible evidence.

## Pull Requests And Validation

List relevant open PRs with base and pinned head revision; distinguish merged or contextual PRs. Inspect checks, reviews and change requests at the latest head. For review threads, distinguish active unresolved requests, replied-to requests awaiting confirmation, outdated concerns still present, and outdated concerns fixed in code; do not infer resolution from a reply or outdated label. State tests or checks performed and what could not be verified. If no relevant open PR exists, say so.

| PR and related issues | State, base and pinned head | Checks | Requested changes and thread disposition | Effect on issue assessment |
| --- | --- | --- | --- | --- |
| [<#>](<PR URL>) / [<KEY>](<Jira URL>) | <Open/merged; base; head SHA> | <Pass/fail/pending/unknown> | <Active, answered but unconfirmed, outdated unresolved, addressed, or none; evidence> | <Blocked criterion or no confirmed effect> |

## Conclusion

State whether the selected issue is ready for acceptance, the decisive blocking criteria if not, and the minimum evidence needed to change that conclusion. Do not repeat the full findings list.