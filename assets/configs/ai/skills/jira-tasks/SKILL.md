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

Query and search Jira issues using the bundled `jira.sh` script. This skill is currently **READ-ONLY**.

## EXECUTION PROTOCOL

### 1. Authentication & Secret Resolution
- The bundled script `scripts/jira.sh` automatically resolves `JIRA_URL`, `JIRA_USER`, and `JIRA_API_TOKEN` using `DF_SECRET_GET_CMD`.
- MUST NOT prompt the user for credentials if `DF_SECRET_GET_CMD` is available.
- IF credentials are missing AND `DF_SECRET_GET_CMD` is undefined, THEN inform the user and stop.

### 2. Information Gathering
- IF the user's request is vague (e.g., "find the login bugs"), THEN:
  1. Use `scripts/jira.sh fields` to find relevant field names if searching custom fields.
  2. Construct a broad JQL search to find candidate issues.
- IF specific ticket keys are mentioned, THEN use `scripts/jira.sh issues` to fetch full details.

### 3. Command Selection & Execution

#### JQL Search
Use `jql` for finding issues based on criteria.
```bash
bash scripts/jira.sh jql "project = PROJ AND status = 'In Progress' ORDER BY updated DESC" --max-results 10
```

#### Fetch Specific Issues
Use `issues` for deep-dives into known tickets.
```bash
bash scripts/jira.sh issues PROJ-123 PROJ-456 --fields "summary,status,description,assignee,priority,comment"
```

#### List/Filter Fields
Use `fields` to discover field IDs (e.g., finding the ID for "Story Points").
```bash
bash scripts/jira.sh fields "Story Points"
```

### 4. Data Synthesis
- Present search results in a scannable markdown table.
- For single issues, provide a structured summary of status, assignee, and recent activity.
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
- [ ] JQL query is valid and properly quoted.
- [ ] Authentication is handled via `resolve_secret` or existing env.
- [ ] No modification commands attempted.
- [ ] Results are synthesized into readable markdown.
