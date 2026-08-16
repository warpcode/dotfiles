# GitHub Pull Requests

Create, update, publish, view, review, and search pull requests — safely,
consistently, always as drafts first.

## Operations Overview

Identify the user's intent and jump to the matching section:

| Operation | When | Section |
|-----------|------|---------|
| **Create** | No PR exists for this branch | Create |
| **Update** | PR exists or user asks to edit title, body, labels, reviewers, assignees, milestone | Update |
| **Publish** | User wants to mark a draft PR as ready for review | Publish |
| **View** | User wants to inspect a specific PR — description, comments, reviews, CI, conflicts | View |
| **Review** | User wants line-level comments or a formal review | Review |
| **List** | User wants to search, filter, or browse PRs | List |

---

## Create

### Step 1: Pre-flight Checks

Run the pre-flight script — it consolidates all safety checks:

```bash
bash ${SKILL_DIR}/scripts/preflight.sh
```

Interpret results in order — stop at the first blocker:

| Field | Condition | Action |
|-------|-----------|--------|
| _(heading)_ | `FAILED` | **STOP.** Error below (likely detached HEAD or not a git repo). |
| gh CLI | `Not installed` / `Not authenticated` | **STOP.** Install (`brew install gh` / https://cli.github.com/) or `gh auth login`. |
| Mainline branch | `Yes` | **STOP.** Cannot create a PR from `main`/`master`. PRs open from feature/fix branches. |
| Pushed to origin | `No` | **ASK.** Offer to `git push -u origin <branch>`; only run after explicit approval. |
| Unpushed commits | `> 0` | **WARN.** PR won't include them. Ask if they want to push first. |
| Existing PRs | any PR listed | **ASK.** Offer to update instead of creating a duplicate. |
| Uncommitted changes | `Yes` | **WARN.** Won't be included. Ask if they want to commit first. |
| PR template | path or `Multiple: <dir>` | Note the path; use it for the body in Step 3. |
| Repository | `Unknown` | **ASK.** Ask for `owner/repo`. |
| Default branch | _(informational)_ | Hint when asking for base — still ask, never assume. |

### Step 2: Gather Context

**2a. Base branch** — NEVER infer or guess. If not provided, ask: *"Which
branch should this PR target? (e.g., `main`, `develop`, `staging`)"*.

**2b. Collect context** — run the context script:
```bash
bash ${SKILL_DIR}/scripts/context.sh <base_branch> <head_branch>
```
Use line count/size to decide how to process output files: small (< ~500
lines) read directly; large files spawn a subagent to summarise or read
selectively. Clean up the temp directory when done.

**2c. Load the PR template** — repo template from pre-flight, or the fallback
`${SKILL_DIR}/templates/pull_request.md`. Tell the user which template you're using.

### Step 3: Structure Content

**Title format selection:**

| Context | Format | Example |
|---------|--------|---------|
| User provides a ticket/issue ID | `[TICKET-ID] Summary` | `[PROJ-123] Add user authentication` |
| Linked GitHub issue | `[#42] Summary` | `[#42] Fix null pointer in search` |
| Standard (no ticket) | `type(scope): summary` | `feat(ui): add dark mode toggle` |
| Draft with unclear scope | `WIP: Summary` | `WIP: Explore caching strategies` |

Title rules: imperative mood, under 70 chars, capitalise the first letter of
the summary, no vague titles. If a ticket/issue ID is provided, verify it
relates (`gh issue view <id> --json title`) before including.

**Body** — use the template. Ensure it explains *what* changed and *why*, links
related issues (`Closes #number`), highlights anything needing reviewer
attention, and includes testing notes if behaviour changed.

### Step 4: Review Before Submitting

Present the full PR for approval. Only proceed after explicit approval.

### Step 5: Execute

**Always use `--body-file`.** Write the body via your native file-writing tool,
then pass the path. Never `--body` with inline text, never shell-based creation.

```bash
gh pr create --base "$base_branch" --head "$current_branch" \
  --title "feat(ui): Add dark mode toggle" --body-file tmp_pr_body.md --draft \
  && rm tmp_pr_body.md
```

**Always create as a draft.** Optional flags (only when the user provides
them): `--label "bug,enhancement"`, `--reviewer "alice,bob"`,
`--assignee "@me"`, `--milestone "v2.0"`.

### Step 6: Confirm
```
✅ Draft PR #47 created: https://github.com/owner/repo/pull/47
To mark it ready for review: gh pr ready 47
```

### Edge cases
- **Forks**: use `owner:branch` syntax: `gh pr create --head "username:feat/dark-mode"`.
- **No `gh` or MCP**: tell the user to install/authenticate `gh`
  (`gh auth login`) or enable the GitHub MCP server. Do not fall back to raw
  API calls — `gh` handles auth, repo detection, and templates.

---

## Update

1. **Pre-checks** — run `${SKILL_DIR}/scripts/view.sh <number>` (or auto-detect) to fetch
   current state and show the user.
2. **Map intent to `gh pr edit` flags:**

| Intent | Command |
|--------|---------|
| Change title | `gh pr edit <number> --title "New title"` |
| Change body | `gh pr edit <number> --body-file tmp_pr_body.md` |
| Add labels | `gh pr edit <number> --add-label "bug,enhancement"` |
| Remove labels | `gh pr edit <number> --remove-label "wip"` |
| Add reviewers | `gh pr edit <number> --add-reviewer "alice,bob"` |
| Remove reviewers | `gh pr edit <number> --remove-reviewer "charlie"` |
| Add assignees | `gh pr edit <number> --add-assignee "@me"` |
| Change base branch | `gh pr edit <number> --base "develop"` |
| Set milestone | `gh pr edit <number> --milestone "v2.0"` |

3. **Body updates** — read the existing body from the JSON saved by `view.sh`;
   edit/extend it rather than replacing from scratch. Use `--body-file`.
4. **Review** — show old → new for changed fields; wait for approval.
5. **Confirm** — `✅ PR #47 updated: <url>`.

---

## Publish

1. **Pre-checks** — `${SKILL_DIR}/scripts/view.sh <number>` (confirm `State` is `Draft`;
   if not, tell the user no action needed) and `${SKILL_DIR}/scripts/preflight.sh` (warn on
   unpushed commits/uncommitted changes).
2. **Review** — present key details, then `gh pr ready <number>`.
3. **Confirm** — `✅ PR #47 is now ready for review: <url>`.

---

## Update Branch

Keep a PR branch synchronized with the base branch:

```bash
# Update with merge commit
gh pr update-branch <number>

# Update with rebase
gh pr update-branch <number> --rebase
```

---

## Request Copilot Review

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{number}/requested_reviewers \
  -f 'reviewers[]=github-copilot[bot]'
```

---

## Merge

> [!CAUTION]
> **Approval Requirement**: ALWAYS obtain explicit user approval before merging any PR. Run `${SKILL_DIR}/scripts/fetch_pr_merge_checks.sh <pr_number>` first to verify tests, checks, and regression status.

```bash
# Squash and merge (recommended default) and delete branch
gh pr merge <number> --squash --delete-branch

# Rebase and merge
gh pr merge <number> --rebase --delete-branch

# Auto-merge when all checks pass
gh pr merge <number> --auto --squash
```

---

## View

1. **Identify the PR** — explicit number/URL, auto-detect from current branch,
   or ask.
2. **Fetch details** — `${SKILL_DIR}/scripts/view.sh [<number>]`. Outputs a formatted
   summary (state, branch, author, assignees, labels, changes, mergeability,
   reviews, CI status) and saves full JSON, comments, and diff to temp files.
3. **Handle output** — summary covers most queries. For deeper dives: comments
   file for discussion; JSON `reviews` for review feedback; diff file for the
   full diff (read directly if small, else subagent). Clean up temp files.

---

## Review

1. **Identify target** — ensure PR number and repo context.
2. **Fetch latest commit ID** — reviews pin to the head commit:
   ```bash
   gh pr view <number> --json headRefOid --template '{{.headRefOid}}'
   ```
3. **Map findings** — for each: `path` (relative file), `line` (final-version
   line number), `body` (descriptive, actionable comment).
4. **Construct JSON payload** (`review_payload.json`):
   ```json
   {
     "commit_id": "<HEAD_REF_OID>",
     "body": "<SUMMARY_MESSAGE>",
     "event": "APPROVE | REQUEST_CHANGES | COMMENT",
     "comments": [{"path": "path/to/file", "line": 10, "body": "Comment text"}]
   }
   ```
5. **Confirm with user** — MUST obtain explicit permission before submission.
   Present summary, findings, and comment details.
6. **Submit** — use `${SKILL_DIR}/scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>`
   (which submits the payload atomically via `gh api`). Do not use raw `curl` API calls.
7. **Cleanup** — delete the temp payload file.

**Comment guidelines** — actionable, specific (reference exact symbols/standards),
consolidated (one review with multiple comments, not many individual ones).

---

## List & Triage

### Basic Listing (`gh pr list`)

```bash
gh pr list --state open --limit 30              # Open PRs (default)
gh pr list --state all --limit 30               # All states
gh pr list --state closed/merged --limit 30
gh pr list --label "bug" --limit 30             # By label
gh pr list --author "alice" --limit 30          # By author
gh pr list --assignee "@me" --limit 30          # By assignee
gh pr list --base "develop" --limit 30          # By base branch
gh pr list --head "feat/dark-mode"              # By head branch
gh pr list --draft --limit 30                   # Drafts only
gh pr list --search "review-requested:@me" --limit 30   # Needing my review
gh pr list --search "dark mode sort:updated-desc" --limit 20  # Full text search
```

JSON output for processing:
```bash
gh pr list --state open --limit 30 --json number,title,state,isDraft,author,labels,assignees,reviewRequests,url,createdAt,updatedAt
```

### Advanced Discovery & Triage Script (`find_prs.sh`)

Use `${SKILL_DIR}/scripts/find_prs.sh` to classify PRs by review status, commit timestamps, and author responsiveness in a single GraphQL batch query:

```bash
# 1. Full categorized overview across all open PRs
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --all

# 2. Find all approved pull requests (ready to merge)
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --approved

# 3. Find PRs where commits were made after a review (ready for re-review)
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --commits-after-review

# 4. Find PRs with no commits since review was submitted
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --no-commits-since-review

# 5. Find PRs where author has not responded to owner / reviewer activity
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --author-not-responded

# 6. Find PRs where author response occurred prior to latest commit
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --author-response-prior-to-commit

# 7. Find all PRs waiting on author action (unresponsive / no commits)
bash ${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --waiting-on-author
```

Optional flags: `--state <OPEN|CLOSED|MERGED|ALL>`, `--limit <number>`, `--raw` (JSON output).

Cross-repo queries pass `-R owner/other-repo` to `gh` or provide `owner repo` to `find_prs.sh`.
