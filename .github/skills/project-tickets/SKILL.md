---
name: project-tickets
description: >
  Decompose feature specifications, PRDs, and RFCs into vertical slices and author
  structured tickets with Given/When/Then acceptance criteria for Jira and GitHub
  Issues. Use when breaking down epics, writing user stories, formulating
  acceptance criteria, sizing tasks, preparing batch ticket creation, or
  provisioning issues.
user-invocable: false
---

# Project Tickets

A procedure-only skill for decomposing technical specifications (`docs/plans/`), PRDs, and RFCs
into small, context-free, vertically sliced tickets (Epics, Stories, Tasks) with unambiguous
acceptance criteria, ready for execution or batch provisioning in external issue trackers.

## 1. Principles of Ticket Decomposition

1. **Vertical Slices Over Horizontal Layers**: Every ticket delivers one thin, testable capability
   cutting through all necessary layers (UI, service, data), rather than isolated horizontal layers.
2. **Strict Sizing ($\le 3$ pt)**: No ticket may exceed 3.0 points. If an item is estimated at 5+ pt,
   it contains unresolved uncertainty and must be split into a spike (`ADR`) and smaller tasks.
3. **Context-Free Independence**: An engineer or subagent must be able to execute the ticket using
   only the ticket text, target files, and linked ADRs, without prior conversation context.
4. **Zero-Hunting Traceability**: Every ticket carries a canonical plan tag `Plan: <slug>:<TSK-xxx>`
   to enable automated discovery by `project-tracker`.

## 2. Decomposition Workflow (Step-by-Step)

### Step 1: Ingest Source Specification
Ingest the input document:
- An in-repo Technical Design Spec (`docs/plans/YYYY-MM-DD-<slug>/SPEC.md`).
- Or an external PRD / RFC text provided by the user.

Extract the core problem, measurable goals (`G-*`), explicit non-goals (`NG-*`), and requirements (`REQ-*`).

### Step 2: Slice into Epics & Stories
1. **Epic Level**: Create high-level container for the feature initiative (`templates/epic.md`).
2. **Story Level**: Break the initiative into end-to-end user/operator journeys (`templates/story.md`).
3. **Task Level**: Break complex stories into distinct engineering steps (`templates/task.md`) if
   multi-file refactoring or dedicated test suites are required.

### Step 3: Author Strict Acceptance Criteria (Given / When / Then)
Every Story and Task must contain unambiguous criteria:
- **Given** [preconditions, setup state, or mock configuration].
- **When** [action, API request, or CLI invocation is executed].
- **Then** [verifiable system state, exit code, returned payload, or error message].

Always include at least one Happy Path criterion and at least one Failure/Edge Case criterion.

### Step 4: Dry-Run Review
Before publishing or creating issues in remote trackers, present a markdown preview table to the user:

```markdown
| Ticket ID | Type | Title | Sizing | Target Files | Dependencies |
|---|---|---|---|---|---|
| `TSK-101` | Story | Add sandbox memory limit cgroup | 1.0 pt | `src/sandbox.c` | None |
| `TSK-102` | Story | Add CLI flag `--max-memory` | 1.0 pt | `src/cli.c` | `TSK-101` |
```

Request explicit user review before provisioning remote issues.

### Step 5: Provisioning Remote Tickets (Delegation)
Upon user confirmation, delegate ticket creation to the appropriate provider skills:
- **GitHub Issues**: Use `github-issues` (or `gh issue create`) specifying title, body, labels, and milestone.
- **Jira**: Use `jira-api` (or Jira REST CLI) specifying project key, issue type, summary, description, and Epic link.
- **Markdown / Local**: Export the decomposed tickets to the plan's `SPEC.md` or a sprint backlog file.

## 3. Sizing Calibration

| Points | Complexity | Effort | Uncertainty | Guideline |
|---|---|---|---|---|
| **0.5 pt** | Low | Small | Low | Trivial config or isolated one-line fix. |
| **1.0 pt** | Low–Med | Small–Med | Low | Standard single-PR vertical slice. |
| **2.0 pt** | Medium | Medium | Low–Med | Multi-file vertical slice with unit tests. |
| **3.0 pt** | Med–High | Med–High | Low | Maximum permissible size for single task. |
| **$\ge$ 5.0 pt** | High | Large | High | **Must be split** before implementation. |

## 4. Templates & References

- **Templates**:
  - `templates/epic.md` — Epic container with goals, non-goals, and child stories.
  - `templates/story.md` — Vertically sliced user story with Given/When/Then acceptance criteria.
  - `templates/task.md` — Engineering task with explicit target files and evidence logging.
- **Reference**:
  - `references/ticket-authoring-guide.md` — Slicing heuristics, AC patterns, and git trailer linking.
