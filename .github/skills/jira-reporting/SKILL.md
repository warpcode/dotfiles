---
name: jira-reporting
description: >-
  Build Jira issue, aging, blocker, workload, epic-progress, daily, and standup reports
  from issue data and change history. Use when asked to analyze team flow, identify
  bottlenecks, summarize developer work, or report Jira project health.
---

# Jira Reporting

Use whichever Jira integration is available to retrieve issue data. This skill covers cross-issue analysis and presentation; it does not depend on a particular API, CLI, MCP server, or Jira client.

## Data Collection

- Discover project-specific statuses and categories before classifying work; status names and workflow meaning vary by project.
- Retrieve change history when calculating time in status, lead time, transition activity, or daily changes. Fetch every result page when the report claims full coverage.
- Request estimation fields explicitly. Use comments and changelog authors as evidence for blocker context; do not infer causes or ownership from status alone.
- State the query scope, reporting period, and any incomplete result set. Do not infer missing activity or external contributions from Jira data.

## Derived Values and Limits

- Derive time in status from the relevant transition timestamps. State whether durations are elapsed time or use an agreed working calendar; do not assume Jira provides a universal work-hours calendar.
- Count repeat visits from the change history only when that history is complete. Describe them as repeat status visits; they do not prove rework, poor quality, or individual performance.
- Define lead time as the interval from issue creation to its first transition into a Done-category status. State the time basis used; lead time alone is not a velocity forecast.
- Separate observed facts from interpretations. Avoid ranking individuals or drawing performance conclusions from issue counts or status durations alone.

## Report Recipes

### Queue Aging and Handoffs

Map statuses to categories, confirm which In Progress statuses represent review or waiting in this project, then query non-Done issues with changelog. Sort by current-status duration and label the calendar assumption.

### Blockers

Discover the project's Blocked or On Hold statuses, fetch matching issues with changelog and comments, and report assignee, current-status duration, and the latest relevant comment. Use transition authors only to identify who made a recorded status change, not who caused the blocker.

### Workload and Flow

Query the requested assignees and statuses, explicitly fetch the estimation field, and group observable issue counts and estimates by assignee. Treat repeated status visits as a workflow signal for investigation, not a performance measure.

### Epic Progress

Query child issues using the project's supported parent relationship. Calculate completion only from a complete result set, define the denominator, and report observed lead times separately from any forecast.

### Status Revisit Review

Query the requested period with changelog. Identify repeated status visits and show the transitions as evidence; do not label them ping-pong or rework unless the history supports that interpretation.

### Developer, Daily, and Standup Reports

Filter to the requested person, team, and time window. Distinguish active work from project-specific handoff states. Use the templates in `@templates/reports.md`; include only Jira-recorded changes, comments, and links. Mark plans, PRs, documentation, or reasons as unavailable unless supplied by Jira data or the user.

## Presentation

- Use concise tables for issue lists and include issue keys so results are traceable.
- Identify the as-of date and query scope. Say when permissions, missing fields, or pagination limit coverage.
- Keep reported values separate from interpretation; include the metric caveats wherever durations or repeat visits materially affect conclusions.