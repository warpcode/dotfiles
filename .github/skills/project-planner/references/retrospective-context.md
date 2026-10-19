# Retrospective Context Gathering

`project-planner` never calls `git`, `gh`, Jira or other trackers itself. To document existing work
(SKILL.md Workflow C), use the matching provider skill (`jira-api`, `github-cli`, `git-expert`) or
read local docs. Then extract the fields below and present them to the user for approval before
writing anything.

## What to extract

| Evidence | Extract | Maps to |
|---|---|---|
| Epics, roadmap docs, READMEs | Problem statement, intended outcomes | Charter, `G-*` |
| "Won't do" / closed-as-out-of-scope tickets, README "not supported" sections | Explicit exclusions | `NG-*` |
| Feature tickets, user stories, spec docs | Behaviour and acceptance criteria | `REQ-*` |
| Design docs, PR discussions, commit messages explaining "why" | Choice made and alternatives discussed | `ADR-*` (with Rejected field) |
| Closed-unmerged PRs, rejected RFCs, "we tried X" comments | Ruled-out ideas and why | `REJ-*` |
| Releases, tags, milestone boards | Phases and what shipped | `M-*` |
| Open tickets / TODOs | Remaining work | `TSK-*` or `Q-*` |
| Incidents, bug clusters, known limitations | Hazards | `RSK-*` |

## Rules

- Every extracted item carries a **Source** (`jira://PROJ-142`, `gh://owner/repo#12`, commit SHA,
  `docs/file.md`). Don't record an item if you can't cite where it came from.
- The folder date prefix is the date of the **earliest evidence**. Record today's date as
  "Documented retrospectively on YYYY-MM-DD" in the SPEC header.
- Mark imported items `Accepted (Retrospective)`. Record gaps (no Non-Goals, missing AC, unknown
  rationale) as `Q-*` items rather than inventing answers.
- Before adding anything, check for duplicates: if an item with the same source is already
  recorded, update it via supersession instead of adding a second copy.
