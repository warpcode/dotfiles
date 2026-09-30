---
name: jira-api
description: >-
  Use when a user asks to query Jira's REST API, run JQL, fetch issue data, inspect Jira
  fields or project metadata, or make a read-only Jira REST call. Triggers include
  "search Jira with JQL", "fetch Jira issue", "list Jira fields", and "call Jira API".
---

# Jira API

Use the bundled CLI for read-only Jira queries. For report interpretation and team or project analysis, use the `jira-reporting` skill.

## Authentication and Invocation

- Resolve `JIRA_API` to this skill package's installed `scripts/main.py` path; do not assume a repository-specific `.github/skills` location.
- The script resolves `JIRA_URL`, `JIRA_USER`, `JIRA_API_TOKEN`, and `JIRA_PROJECT` through `DF_SECRET_GET_CMD` or existing environment variables. Never request or print these values. If required configuration is missing, report the error and stop.

## Commands

Use `jql` for searches. Limit general searches to 10 results unless the user asks for more; the CLI itself defaults to 50.
```bash
python3 "$JIRA_API" jql "project = PROJ AND status = 'In Progress' ORDER BY updated DESC" --max-results 10
```

If a JQL response has `"isLast": false`, fetch subsequent pages using `nextPageToken` with `--param`; do not use `startAt`.
```bash
python3 "$JIRA_API" jql "project = PROJ" --max-results 10 --param nextPageToken=YOUR_TOKEN_HERE
```

Use `issues` for known issue keys. Add `--fields` to request specific fields.
```bash
python3 "$JIRA_API" issues PROJ-123 PROJ-456 --fields "summary,status,description,assignee,priority,comment"
```

Use `--expand changelog` when the request requires transition history. This also adds wrapper-computed metrics to each issue; these are not native Jira API fields.
```bash
python3 "$JIRA_API" issues PROJ-123 --expand changelog
```

Use `fields` to discover field IDs before requesting custom fields. Other metadata commands are `statuses`, `types`, `priorities`, `resolutions`, and `projects`; use `users` to search Jira users.
```bash
python3 "$JIRA_API" fields "Story Points"
```

Use `call` only for a read-only GET to a relative Jira API path. Absolute URLs are rejected so Jira credentials cannot be sent to another host.
```bash
python3 "$JIRA_API" call GET "/rest/api/3/issue/PROJ-123/transitions"
```

## Output and Safety

- The CLI returns JSON. Extract the fields needed to answer the API query; use `--raw` or `--full-issue` only when the user requests the full response.
- `metrics.rework_count` counts repeated visits to any status; it does not establish that rework occurred.
- Duration metrics use a fixed Monday-Friday 09:00-17:30 UTC work window (8.5 hours/day), without holidays or project calendars.
- The generic `call` command permits GET only and requires a relative endpoint path. The search and bulk-fetch subcommands use POST transport internally but do not mutate Jira data.
- Quote JQL strings. For a user-facing report or cross-issue analysis, use the `jira-reporting` skill.

## COMMON JQL PATTERNS
- **By Assignee**: `assignee = currentUser()` or `assignee = "email@example.com"`
- **By Status**: `status in ("To Do", "In Progress")`
- **Text Search**: `text ~ "search term"`
- **Project + Type**: `project = "PROJ" AND issuetype = "Bug"`

## VALIDATION CHECKLIST
- [ ] JQL query is valid, properly quoted, and escapes necessary characters.
- [ ] General searches explicitly use `--max-results 10` unless the user asks for more.
- [ ] If `isLast: false` is returned, pagination is handled via `nextPageToken` or the user is informed that more results exist.
- [ ] Direct API calls use GET and a relative Jira endpoint.
- [ ] If searching custom fields, the `fields` subcommand was used to discover the correct field ID.
