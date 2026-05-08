---
name: github-issues
description: Create, update, query, and comment on GitHub issues using the gh CLI. Use this skill whenever the user wants to file a bug report, create a feature request, update an existing issue, search or list issues, read issue comments, add labels/milestones, or interact with GitHub issues in any way. Also trigger when the user mentions "open an issue", "file a bug", "update issue \#X", "list issues", "check my issues", "add a comment to issue", "close issue", "label issue", or discusses GitHub issue workflows — even if they don't explicitly say "GitHub issue". If the user is working in a git repository and mentions tracking work, reporting bugs, or requesting features, this skill likely applies.
---

# GitHub Issues

Manage GitHub issues end-to-end: create, update, query, comment, and triage — all from the terminal.

## Workflow

Every interaction follows six steps:

1. **Determine action** — Is this a create, update, or query?
2. **Gather context** — Identify the repo, pull existing labels/milestones/templates
3. **Structure content** — Use issue templates when available, format body as markdown
4. **Review** — Present the full issue/comment to the user for approval before submitting
5. **Execute** — Run the appropriate `gh` command (or fall back to the API)
6. **Confirm** — Report the issue URL back to the user

---

## Step 1: Determine the Action

Map the user's request to one of these operations:

| Intent | Operation | Primary command |
|--------|-----------|-----------------|
| File a bug, request a feature, open an issue | **Create** | `gh issue create` |
| Change title, body, labels, assignees, milestone | **Update** | `gh issue edit` |
| Add a comment | **Comment** | `gh issue comment` |
| Close or reopen | **State change** | `gh issue close` / `gh issue reopen` |
| Read a single issue + comments | **View** | `gh issue view` |
| Search / list / filter issues | **Query** | `gh issue list` |

If the intent is ambiguous, ask the user before proceeding — don't guess.

---

## Step 2: Gather Context

### Identify the repository

Resolve the target repo in this order:

1. **Explicit** — The user supplied `owner/repo` or a full GitHub URL
2. **Current directory** — Run `gh repo view --json nameWithOwner -q .nameWithOwner` to detect it from the local git remote
3. **Ask** — If neither works, ask the user which repo to target

For cross-repo operations, pass `-R owner/repo` to every `gh` command.

### Discover labels and milestones

Before creating or editing issues, fetch available labels and milestones so you can suggest valid options rather than inventing non-existent ones:

```bash
# Labels
gh label list --json name,description --limit 100

# Milestones
gh api repos/{owner}/{repo}/milestones --jq '.[].title'
```

When the user asks for a label that doesn't exist, confirm whether they want you to create it (`gh label create "name" --description "..." --color "hex"`) before applying it.

### Check for issue templates

Repos often define issue templates that enforce structure. Check for them before creating:

```bash
# Check .github directory for templates
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
# Or if not in the repo locally:
gh api repos/{owner}/{repo}/contents/.github/ISSUE_TEMPLATE --jq '.[].name' 2>/dev/null
```

Template locations to check (in priority order):
1. `.github/ISSUE_TEMPLATE/*.md` or `.github/ISSUE_TEMPLATE/*.yml` — multiple templates
2. `.github/ISSUE_TEMPLATE.md` — single template
3. `.github/ISSUE_TEMPLATE/config.yml` — template chooser config

If templates exist:
- Read the template content to understand the expected structure (required fields, sections, headings)
- Use `gh issue create --template "Template Name"` when creating interactively, or manually structure the body to match the template's format when passing `--body-file`
- Tell the user which template you're using and why

---

## Step 3: Structure Content

### Creating issues

If the repo defines issue templates (checked in Step 2), use them — read the template content and structure the body to match its sections and required fields.

If no templates exist, read `references/templates.md` in this skill's directory. It contains fallback templates for the five most common issue types:

| Type | When to use |
|------|-------------|
| **Bug Report** | Something is broken, crashes, or returns wrong results |
| **Feature Request** | Proposing new functionality or an enhancement |
| **Task / Chore** | Refactors, deps, CI, docs, tech debt cleanup |
| **Question / Discussion** | Seeking input before committing to an approach |
| **Security Vulnerability** | Reporting a security issue (check `SECURITY.md` first) |

Pick the template that best matches the user's intent, then adapt it — drop sections that don't apply, add sections that do. The user's input is the source of truth; the templates provide structure, not content.

### Updating issues

When editing, be surgical. Only modify what the user asked to change:

- **Title/body**: `gh issue edit <number> --title "..." --body-file body.md`
- **Labels**: Use `--add-label` / `--remove-label` (not `--label`, which replaces all)
- **Assignees**: Use `--add-assignee` / `--remove-assignee`
- **Milestone**: `--milestone "name"` or `--remove-milestone`

### Adding comments

```bash
gh issue comment <number> --body-file /path/to/comment.md
```

---

## Step 4: Review Before Submitting

Before creating or updating an issue (or adding a comment), present the full content to the user for approval. GitHub operations can't be silently undone — a mislabelled issue or a garbled body is visible to the entire repo. Show the user exactly what will be submitted and wait for their go-ahead.

Present a summary like this:

```
📋 Ready to create issue on owner/repo:

  Title:     Login fails with SSO enabled
  Labels:    bug, priority:high
  Assignee:  @alice
  Milestone: v2.1

  Body:
  ─────────────────────────────────
  ## Description
  Login fails when SSO is enabled...

  ## Steps to Reproduce
  1. Enable SSO in org settings
  2. Attempt login via /auth/sso
  ...
  ─────────────────────────────────

Proceed? (or tell me what to change)
```

For **updates**, show what will change (old → new) so the user can verify the diff. For **comments**, show the full comment body.

Only proceed to execution after the user explicitly approves. If they request changes, revise and present again.

---

## Step 5: Execute

### Body text: always use `--body-file`

When any `gh` command needs body text (create, edit, comment), write the content to a temp file first and pass it via `--body-file`. Never use `--body` with inline text — markdown content contains backticks, quotes, and newlines that cause shell quoting problems. The temp-file approach is reliable regardless of body length or content.

```bash
# Write body to temp file, pass to gh, clean up
tmpfile=$(mktemp /tmp/gh-issue-XXXXXX.md)
cat > "$tmpfile" << 'EOF'
## Description
Body content goes here — markdown, backticks, quotes, all safe.
EOF

gh issue create --title "Title" --body-file "$tmpfile" --label "bug"
rm -f "$tmpfile"
```

### Primary method: `gh` CLI

The `gh` CLI is the preferred tool. All commands should run non-interactively by supplying all required flags (especially `--title` and `--body-file` for create).

**Create:**
```bash
tmpfile=$(mktemp /tmp/gh-issue-XXXXXX.md)
cat > "$tmpfile" << 'EOF'
## Description
Issue body in markdown
EOF

gh issue create \
  --title "Issue title" \
  --body-file "$tmpfile" \
  --label "bug,help wanted" \
  --assignee "@me" \
  --milestone "v1.0"
rm -f "$tmpfile"
```

**Edit:**
```bash
gh issue edit 42 \
  --title "Updated title" \
  --add-label "priority:high" \
  --remove-label "triage"
```

**View (with comments and metadata):**
```bash
# Human-readable
gh issue view 42 --comments

# Machine-readable JSON with all fields
gh issue view 42 --json title,body,state,labels,assignees,milestone,comments,createdAt,updatedAt,url
```

**List/search:**
```bash
# By label
gh issue list --label "bug" --state open --limit 50

# Full text search
gh issue list --search "login error sort:updated-desc" --limit 20

# JSON output for processing
gh issue list --json number,title,state,labels,assignees,url --limit 50
```

**Close/reopen:**
```bash
gh issue close 42 --reason "completed"   # or "not planned"
gh issue reopen 42
```

### Fallback: API via curl

If `gh` is not installed or not authenticated, fall back to the GitHub REST API. This matters because the user might be in a CI environment, a container, or simply hasn't set up `gh`.

**Detection logic:**
```bash
# Check if gh is available and authenticated
if ! command -v gh &>/dev/null || ! gh auth status &>/dev/null 2>&1; then
  # Fall back to API
fi
```

**For API access, check for a token:**
```bash
# gh stores its token; try to extract it first
GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

if [[ -z "${GITHUB_TOKEN}" ]]; then
  # Try gh's own token store
  GITHUB_TOKEN=$(gh auth token 2>/dev/null)
fi

if [[ -z "${GITHUB_TOKEN}" ]]; then
  echo "No GitHub token available. Read-only access to public repos only."
  echo "Set GITHUB_TOKEN or run 'gh auth login' for full access."
fi
```

**API examples:**

```bash
# List issues (public repo, no auth needed)
curl -s "https://api.github.com/repos/owner/repo/issues?state=open&per_page=30"

# View a specific issue
curl -s "https://api.github.com/repos/owner/repo/issues/42"

# View comments
curl -s "https://api.github.com/repos/owner/repo/issues/42/comments"

# Create issue (requires auth)
curl -s -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/owner/repo/issues" \
  -d '{"title":"Bug report","body":"Description here","labels":["bug"]}'

# Update issue (requires auth)
curl -s -X PATCH \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/owner/repo/issues/42" \
  -d '{"title":"Updated title","labels":["bug","priority:high"]}'

# Add comment (requires auth)
curl -s -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/owner/repo/issues/42/comments" \
  -d '{"body":"Comment text here"}'
```

Write operations (create, update, comment, close) require authentication. If no token is available for a private repo, tell the user exactly what they need to do:
- `gh auth login` (preferred), or
- Set `GITHUB_TOKEN` environment variable with a PAT that has `repo` scope

---

## Step 6: Confirm

After every mutating operation, report the result back to the user:

- **Created**: "✅ Issue #42 created: https://github.com/owner/repo/issues/42"
- **Updated**: "✅ Issue #42 updated: https://github.com/owner/repo/issues/42"
- **Commented**: "✅ Comment added to #42: https://github.com/owner/repo/issues/42#issuecomment-XXXXX"
- **Closed**: "✅ Issue #42 closed"

For queries, present results in a scannable format:

```
#42  [bug, priority:high]  Login fails with SSO enabled          open   @alice  2d ago
#38  [feature]             Add dark mode to settings page        open   —       1w ago
#35  [bug]                 API returns 500 on empty payload      closed @bob    2w ago
```

---

## Edge Cases

### Rate limiting
The GitHub API has rate limits (60/hr unauthenticated, 5000/hr authenticated). If you hit a rate limit, tell the user and suggest authenticating if they haven't already.

### Multiple issues
When the user wants to create several related issues, create them sequentially and report all URLs at the end. Consider suggesting a tracking issue or milestone to link them.

### Cross-referencing
When mentioning other issues in a body or comment, use the `#number` shorthand (same repo) or `owner/repo#number` (cross-repo) so GitHub auto-links them.
