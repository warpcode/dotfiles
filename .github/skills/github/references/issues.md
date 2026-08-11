# GitHub Issues

Manage GitHub issues end-to-end: create, update, query, comment, and triage.

## Workflow

1. **Determine action** — Is this a create, update, or query?
2. **Gather context** — Identify the repo, pull existing labels/milestones/templates
3. **Structure content** — Use issue templates when available, format body as markdown
4. **Review** — Present the full issue/comment to the user for approval before submitting
5. **Execute** — Use GitHub MCP tools if available; otherwise use `gh` CLI. Never use raw API calls.
6. **Confirm** — Report the issue URL back to the user

## Step 1: Determine the Action

| Intent | Operation | Primary command |
|--------|-----------|-----------------|
| File a bug, request a feature, open an issue | **Create** | `gh issue create` |
| Change title, body, labels, assignees, milestone | **Update** | `gh issue edit` |
| Add a comment | **Comment** | `gh issue comment` |
| Close or reopen | **State change** | `gh issue close` / `gh issue reopen` |
| Read a single issue + comments | **View** | `gh issue view` |
| Search / list / filter issues | **Query** | `gh issue list` |

If the intent is ambiguous, ask the user before proceeding — don't guess.

## Step 2: Gather Context

### Identify the repository

Resolve the target repo in this order:

1. **Explicit** — The user supplied `owner/repo` or a full GitHub URL
2. **Current directory** — `gh repo view --json nameWithOwner -q .nameWithOwner`
3. **Ask** — If neither works, ask the user

For cross-repo operations, pass `-R owner/repo` to every `gh` command.

### Discover labels and milestones

```bash
gh label list --json name,description --limit 100
gh api repos/{owner}/{repo}/milestones --jq '.[].title'
```

When the user asks for a label that doesn't exist, confirm whether they want you
to create it (`gh label create "name" --description "..." --color "hex"`)
before applying it.

### Check for issue templates

Check (in priority order): `.github/ISSUE_TEMPLATE/*.md` or `*.yml`, then
`.github/ISSUE_TEMPLATE.md`, then `gh api repos/{owner}/{repo}/contents/.github/ISSUE_TEMPLATE`.

If templates exist: read the template, structure the body to match, and use
`gh issue create --template "Template Name"` when creating interactively.

## Step 3: Structure Content

If no repo templates exist, read `references/templates.md` conventions — pick the
template matching intent (Bug Report, Feature Request, Task/Chore,
Question/Discussion, Security Vulnerability), adapt it, and drop sections that
don't apply. The user's input is the source of truth; templates provide
structure, not content.

When editing, be surgical — only modify what the user asked:

- **Title/body**: `gh issue edit <number> --title "..." --body-file body.md`
- **Labels**: Use `--add-label` / `--remove-label` (not `--label`, which replaces all)
- **Assignees**: Use `--add-assignee` / `--remove-assignee`
- **Milestone**: `--milestone "name"` or `--remove-milestone`

## Step 4: Review Before Submitting

Present the full content for approval before creating or updating anything.
GitHub operations can't be silently undone. For updates, show old → new. For
comments, show the full body. Only proceed after explicit approval.

## Step 5: Execute

### Body text: always use `--body-file`

1. **Action:** Use your native file-writing tool to create a temporary markdown file.
2. **Action:** Run `gh` passing that path to `--body-file`.

**NEVER** use the `--body` flag with inline text and **NEVER** use shell-based
file creation. This preserves backticks, quotes, and newlines exactly.

**Create:**
```bash
gh issue create --title "Issue title" --body-file "tmp_body.md" \
  --label "bug,help wanted" --assignee "@me" --milestone "v1.0" && rm "tmp_body.md"
```

**Edit:**
```bash
gh issue edit 42 --title "Updated title" --add-label "priority:high" --remove-label "triage"
```

**View:**
```bash
gh issue view 42 --comments
gh issue view 42 --json title,body,state,labels,assignees,milestone,comments,createdAt,updatedAt,url
```

**List/search:**
```bash
gh issue list --label "bug" --state open --limit 50
gh issue list --search "login error sort:updated-desc" --limit 20
gh issue list --json number,title,state,labels,assignees,url --limit 50
```

**Close/reopen:**
```bash
gh issue close 42 --reason "completed"   # or "not planned"
gh issue reopen 42
```

### No `gh` or MCP available

If neither the GitHub MCP server nor `gh` CLI is available, tell the user to
install/authenticate `gh` (`gh auth login`) or enable the GitHub MCP server.
Do not fall back to raw `curl` API calls.

## Step 6: Confirm

- **Created**: "✅ Issue #42 created: https://github.com/owner/repo/issues/42"
- **Updated**: "✅ Issue #42 updated: ..."
- **Commented**: "✅ Comment added to #42: ...#issuecomment-XXXXX"
- **Closed**: "✅ Issue #42 closed"

For queries, present a scannable table:
```
#42  [bug, priority:high]  Login fails with SSO enabled          open   @alice  2d ago
#38  [feature]             Add dark mode to settings page        open   —       1w ago
```

## Edge Cases

- **Rate limiting**: 60/hr unauthenticated, 5000/hr authenticated. Tell the
  user and suggest authenticating if hit.
- **Multiple issues**: create sequentially and report all URLs; suggest a
  tracking issue or milestone to link them.
- **Cross-referencing**: use `#number` (same repo) or `owner/repo#number`
  (cross-repo) so GitHub auto-links.
