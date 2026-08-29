---
name: jira-tasks
description: >-
  Query Jira issues, perform JQL searches, and list project fields.
  Trigger this skill whenever the user mentions "Jira", "JQL", "tickets", "issues",
  "search Jira", or wants to fetch status/details for specific ticket keys (e.g., PROJ-123),
  even if they don't explicitly name "Jira". Use this skill to explore project metadata
  and discover available fields.
---

# Jira Tasks

Query and search Jira issues using the bundled `main.py` script. This skill is currently **READ-ONLY**.

## EXECUTION PROTOCOL

### 1. Authentication & Secret Resolution
- The bundled script `scripts/main.py` automatically resolves `JIRA_URL`, `JIRA_USER`, `JIRA_API_TOKEN`, and `JIRA_PROJECT` using `DF_SECRET_GET_CMD` or existing environment variables.
- You do not need to provide these credentials manually.
- If the script fails due to missing credentials (e.g., "Error: Jira URL is required."), inform the user and stop.

### 2. Information Gathering
- IF the user's request is vague (e.g., "find the login bugs"), THEN:
  1. Use `scripts/main.py fields` to find relevant field names if searching custom fields.
  2. Construct a broad JQL search to find candidate issues.
- IF specific ticket keys are mentioned, THEN use `scripts/main.py issues` to fetch full details.
- **Reporting & History**: When asked for "how long" a ticket has been in a status, or to perform any "Aging" or "Metrics" report, ALWAYS include `--expand changelog` in the `issues` or `jql` command to fetch the transition history.

### 3. Command Selection & Execution

#### JQL Search
Use `jql` for finding issues based on criteria.
```bash
python3 scripts/main.py jql "project = PROJ AND status = 'In Progress' ORDER BY updated DESC" --max-results 10
```

#### Pagination & Extra Parameters
When a `jql` search returns `"isLast": false`, a `"nextPageToken"` will be included in the response. You MUST use this token via the `--param` flag to fetch the next page of results. **DO NOT use `startAt` for pagination.**
```bash
# Example: Fetching the next page
python3 scripts/main.py jql "project = PROJ" --max-results 10 --param nextPageToken=YOUR_TOKEN_HERE
```
The `--param key=value` option can also be used to inject any other arbitrary parameters into the JSON payload of the API request.

#### Fetch Specific Issues
Use `issues` for deep-dives into known tickets.
```bash
python3 scripts/main.py issues PROJ-123 PROJ-456 --fields "summary,status,description,assignee,priority,comment"
```

#### Advanced History & Metrics
To perform analysis on **status aging**, **lead time**, or **history**, include the `--expand changelog` flag. This works with both `jql` and `issues` subcommands.
```bash
# Fetch history for specific issues
python3 scripts/main.py issues PROJ-123 --expand changelog

# Fetch history for all issues matching a search
python3 scripts/main.py jql "project = PROJ AND status = Blocked" --expand changelog
```
When this flag is used, the script provides a `metrics` object for each issue containing:
- `time_in_status_seconds`: Total work seconds (excluding weekends) spent in each status.
- `time_in_category_seconds`: Total work seconds spent in each generic Jira category (`To Do`, `In Progress`, `Done`).
- `current_status_duration_seconds`: Time spent in the current status.
- `transition_count`: Number of times the status has changed.
- `work_day_seconds`: The duration of a single work day used for calculations (default 30600s / 8.5h).

#### List/Filter Fields
Use `fields` to discover field IDs (e.g., finding the ID for "Story Points").
```bash
python3 scripts/main.py fields "Story Points"
```

#### Schema & Metadata Discovery
Use these subcommands to understand the Jira instance structure.
- **Statuses**: `python3 scripts/main.py statuses` (Returns map of ID -> {name, category})
- **Issue Types**: `python3 scripts/main.py types` (Returns map of ID -> {name, subtask})
- **Priorities**: `python3 scripts/main.py priorities`
- **Resolutions**: `python3 scripts/main.py resolutions`
- **Projects**: `python3 scripts/main.py projects`
- **Users**: `python3 scripts/main.py users "John Doe"` (Search for users by name or email)

#### Direct API Call (Escape Hatch)
Use `call` for any endpoint not covered by specific subcommands.
```bash
# Example: Fetch transitions for a specific issue
python3 scripts/main.py call GET "/rest/api/3/issue/PROJ-123/transitions"
```

### 4. REPORTING RECIPES
When asked to generate reports, use the following "Discover -> Fetch -> Synthesize" patterns. Do NOT assume status names; use metadata to map the project's specific dialect.

#### A. Queue Aging & Bottleneck Report
**Goal**: Identify work stuck in "handover" states (e.g., waiting for QA, Review, or UAT).
1. **Discover**: Run `python3 scripts/main.py statuses` to identify which statuses map to `statusCategory: In Progress` but represent "Passive/Waiting" states in this project.
2. **Fetch**: Run `jql` with `--expand changelog` for all non-Done tickets.
3. **Synthesize**: Use `metrics.current_status_duration_formatted` to list tickets in those passive states, sorted by the longest duration.

#### B. The "Blocker Pulse"
**Goal**: Identify why work is stopped and for how long.
1. **Discover**: Use `statuses` to find the exact name for "Blocked" or "On Hold".
2. **Fetch**: Run `jql` for those statuses with `--expand changelog`.
3. **Synthesize**: Create a table with `Key` | `Assignee` | `Days Blocked (metrics.current_status_duration_formatted)` | `Latest Comment`. Use the `metrics.rework_count` to flag if this is a recurring block.

#### C. Developer Workload & Flow
**Goal**: Assess team capacity and individual "churn."
1. **Discover**: Use `fields` to find the ID for estimation (e.g., "Story Points").
2. **Fetch**: Run `jql` for `statusCategory = "In Progress"` with `--expand changelog`.
3. **Synthesize**: Group by `assignee`. Calculate `Total Points`, `Active Tickets`, and `Avg. Rework Rate (metrics.rework_count)`. High rework + low throughput suggests a person is stuck in a feedback loop.

#### D. Epic Health & Progress
**Goal**: High-level status of a large initiative.
1. **Fetch**: Run `jql` for child issues (`parent = EPIC-KEY`) with `--expand changelog`.
2. **Synthesize**: Calculate `% Complete` based on `Done` status category. Use `metrics.lead_time_formatted` of completed children to estimate the "velocity" of this Epic. Flag if any children have high `rework_count`.

#### E. Quality & Rework Audit
**Goal**: Identify "Ping-Ponging" and process instability.
1. **Fetch**: Run `jql` for recently updated issues with `--expand changelog`.
2. **Synthesize**: Highlight tickets where `metrics.rework_count > 1`. Look at `metrics.status_visit_counts` to see exactly which status is being re-entered (e.g., if "In Progress" visit count > 1, it was sent back from a later stage).

#### F. Individual Developer Deep-Dive
**Goal**: Detailed view of a developer's focus, handover, and impediments.
1. **Discover**: Identify all non-Done statuses and their categories.
2. **Fetch**: Run `jql` for `assignee = "DEVELOPER_NAME" AND statusCategory != Done` with `--expand changelog`.
3. **Synthesize**: Group the developer's work into three zones:
    *   **Active**: Tickets in `In Progress` categories. Use `metrics.current_status_duration_formatted` to show how long they've been on it.
    *   **Handover**: Tickets in `In Progress` category but "Passive" (e.g., In QA, Peer Review).
    *   **Impediments**: Tickets in `Blocked` or `On Hold` statuses.
4. **Blocker Analysis**: For any Impediment, check:
    *   **Who blocked it?** Check `changelog` for the user who moved it to the Blocked status.
    *   **Why is it blocked?** Extract the most recent comment from the developer (or others) that justifies the block.
    *   **Rework?** Flag if `metrics.rework_count > 0` to see if they've been here before.

### 5. Data Synthesis
- **Templates**: For common reports (Developer Deep-Dive, Daily Report), use the predefined structures found in `./templates/reports.md`.
- Present search results in a scannable markdown table.
- For single issues, provide a structured summary of status, assignee, and recent activity.
- Use status categories (To Do, In Progress, Done) to group and summarize work status.
- MUST NOT include raw JSON in the final response to the user; format it as clean markdown.

## CONSTRAINTS
- **READ-ONLY**: MUST NOT attempt to create, edit, or delete Jira issues.
- **Quoting**: ALWAYS quote JQL queries to prevent shell parsing errors.
- **Max Results**: Default to `--max-results 10` for general searches to save context; increase only if requested.

## COMMON JQL PATTERNS
- **By Assignee**: `assignee = currentUser()` or `assignee = "email@example.com"`
- **By Status**: `status in ("To Do", "In Progress")`
- **Text Search**: `text ~ "search term"`
- **Project + Type**: `project = "PROJ" AND issuetype = "Bug"`

## VALIDATION CHECKLIST
- [ ] JQL query is valid, properly quoted, and escapes necessary characters.
- [ ] `--max-results` is explicitly limited (default 10) to avoid context overflow.
- [ ] If `isLast: false` is returned, pagination is handled via `nextPageToken` or the user is informed that more results exist.
- [ ] No modification commands (POST/PUT/DELETE) are attempted via the `call` escape hatch.
- [ ] If searching custom fields, the `fields` subcommand was used to discover the correct field ID.
- [ ] Results are synthesized into readable markdown, not raw JSON.
