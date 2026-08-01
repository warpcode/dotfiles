# Creating a PR

1. **Pre-flight** — Verify branch, remote, and existing PRs
2. **Gather context** — Determine base branch, discover templates, collect diff info
3. **Structure content** — Build title and body
4. **Review** — Present the full PR to the user for approval
5. **Execute** — Create the draft PR via `gh`
6. **Confirm** — Report the PR URL

---

## Step 1: Pre-flight Checks

Run the pre-flight script from this skill's `scripts/` directory. It consolidates all safety checks into a single command and outputs structured markdown:

```bash
bash /path/to/this/skill/scripts/preflight.sh
```

The script outputs a markdown report like:

```markdown
# PR Pre-flight

| Check               | Result |
|---------------------|--------|
| gh CLI              | Yes |
| Branch              | feat/dark-mode |
| Mainline branch     | No |
| Pushed to origin    | Yes |
| Unpushed commits    | 0 |
| Uncommitted changes | No |
| Repository          | owner/repo |
| Default branch      | main |
| Commit count        | 5 |
| PR template         | .github/PULL_REQUEST_TEMPLATE.md |

## Existing PRs

None
```

### Interpret the results

Process the table fields in this order — stop at the first blocker:

| Field | Condition | Action |
|-------|-----------|--------|
| _(heading)_ | `FAILED` | **STOP.** The error is shown below the heading (likely detached HEAD or not a git repo). |
| gh CLI | `Not installed` / `Not authenticated` | **STOP.** Tell the user to install (`brew install gh` / https://cli.github.com/) or authenticate (`gh auth login`). |
| Mainline branch | `Yes` | **STOP.** Tell the user you cannot create a PR from `main`/`master`. PRs must be opened from feature/fix branches. Do not proceed under any circumstances. |
| Pushed to origin | `No` | **ASK.** _"This branch hasn't been pushed to origin yet. Would you like me to push it?"_ Only run `git push -u origin <branch>` after explicit approval. If declined, stop. |
| Unpushed commits | `> 0` | **WARN.** Tell the user there are local commits not yet pushed. The PR won't include them. Ask if they want to push first. |
| Existing PRs | any PR listed | **ASK.** Show the existing PR(s) and ask if the user wants to update it instead of creating a duplicate. |
| Uncommitted changes | `Yes` | **WARN.** Tell the user there are uncommitted changes that won't be included in the PR. Ask if they want to commit first. |
| PR template | path or `Multiple: <dir>` | Note the path — use this template for the PR body in Step 3. If `Multiple`, list the files and let the user choose. |
| Repository | `Unknown` | **ASK.** Could not detect the repo — ask the user for `owner/repo`. |
| Default branch | _(informational)_ | Show this as a hint when asking the user for the base branch — but still ask, never assume. |
| Commit count | _(informational)_ | Use for context when structuring the PR body — a 1-commit PR needs less description than a 30-commit one. |

---

## Step 2: Gather Context

### 2a. Determine the base branch

The base branch is the branch the PR will merge **into**. This is critical — getting it wrong means the PR targets the wrong branch and the diff will be meaningless.

**NEVER infer or guess the base branch.** If the user has not explicitly provided one, you MUST ask:

_"Which branch should this PR target? (e.g., `main`, `develop`, `staging`)"_

Do not assume `main` or `develop`. Different repos and teams use different branching strategies, and guessing wrong creates real problems. Wait for the user to tell you.

### 2b. Collect context

Run the context script from this skill's `scripts/` directory. It validates both branches, collects the commit log, file stats, and full diff — writing each to a temp file so you can decide how to process them:

```bash
bash /path/to/this/skill/scripts/context.sh <base_branch> <head_branch>
```

The script outputs a summary report with file paths:

```markdown
# PR Context

| Detail         | Value |
|----------------|-------|
| Base branch    | main |
| Head branch    | feat/dark-mode |
| Base on origin | Yes |
| Head on origin | Yes |

## Output Files

| File | Path | Lines | Size |
|------|------|------:|------|
| Commit log | /tmp/pr-context.XXXXXX/commits.log | 12 | 1 KB |
| Diffstat | /tmp/pr-context.XXXXXX/diffstat.txt | 8 | 0 KB |
| Full diff | /tmp/pr-context.XXXXXX/changes.diff | 340 | 15 KB |
```

### How to handle the output files

Use the line count and size to decide how to process each file:

- **Small** (< ~500 lines) — Read the file directly into your context
- **Large** (500+ lines) — Spawn a subagent to read and summarise the changes, or read the diffstat for an overview and selectively read parts of the diff

The commit log and diffstat are almost always small enough to read directly. The full diff is the one that can blow up — use the size to judge.

If the script reports that either branch doesn't exist, stop and tell the user.

If the head branch is not on origin, warn the user — the PR can be created but the remote diff may not match what they expect locally.

Clean up the temp directory when you're done.

### 2c. Load the PR template

If the pre-flight found a repo template (`PR template` field):
- Read its content and understand the expected structure
- Fill in each section using the context from 2b
- Tell the user which template you're using

If no repo template was found:
- Read `templates/pull_request.md` in this skill's directory for the fallback template
- Adapt the template to fit the changes — drop empty sections, add relevant ones

---

## Step 3: Structure Content

### Title

The PR title is the first thing reviewers see. It must be concise, descriptive, and follow a consistent format.

**Title format selection:**

| Context | Format | Example |
|---------|--------|---------|
| User provides a ticket/issue ID | `[TICKET-ID] Summary` | `[PROJ-123] Add user authentication` |
| Linked GitHub issue | `[#42] Summary` | `[#42] Fix null pointer in search` |
| Standard (no ticket) | `type(scope): summary` | `feat(ui): add dark mode toggle` |
| Draft with unclear scope | `WIP: Summary` | `WIP: Explore caching strategies` |

**Conventional Commits types** (for the standard format):

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `style` | Format / whitespace only |
| `refactor` | Restructure without behaviour change |
| `perf` | Performance improvement |
| `test` | Tests |
| `chore` | Maintenance, dependencies |
| `ci` | CI/CD pipeline |

**Title rules:**
- Use imperative mood: "Add feature" not "Added feature"
- Keep under 70 characters for readability
- Capitalise the first letter of the summary
- Never use vague titles like "Fix bug" or "Update file"
- Only use `WIP:` for draft PRs with genuinely unclear scope — not as a lazy default
- If a ticket ID is provided, verify it relates to the changes before including it in the title
- If a GitHub issue ID is provided, run `gh issue view <id> --json title` to confirm it exists and is relevant

### Body

The body provides reviewers with the context they need to understand and evaluate the changes. Use the template discovered in Step 2c — either the repo's own template or the fallback from this skill's `templates/` directory.

Regardless of template, ensure the body:
- Explains **what** changed and **why**
- Links related issues using `#number` or `Closes #number`
- Highlights anything that needs special reviewer attention
- Includes testing notes if the changes affect behaviour

---

## Step 4: Review Before Submitting

Present the full PR to the user for approval before creating it. GitHub PRs are visible to the team and cannot be silently undone.

```
🔀 Ready to create draft PR on owner/repo:

  Base:      main
  Head:      feat/dark-mode
  Title:     feat(ui): Add dark mode toggle
  Labels:    enhancement
  Reviewers: (none)

  Body:
  ─────────────────────────────────
  ## Summary
  Adds a dark mode toggle to the settings page...

  ## Changes
  - Added ThemeProvider context
  - Updated color tokens to support dark palette
  ...
  ─────────────────────────────────

Proceed? (or tell me what to change)
```

Only proceed after the user explicitly approves. If they request changes, revise and present again.

---

## Step 5: Execute

### Body text: always use `--body-file`

When creating a PR, you MUST use a two-step process for the body:

1. **Action:** Use your native **file writing tool** to create a temporary markdown file (e.g., `tmp_pr_body.md`) containing the full, unescaped markdown content
2. **Action:** Run the `gh` command passing that file path to `--body-file`

**NEVER** use the `--body` flag with inline text and **NEVER** use shell-based file creation (like `cat`, `echo`, `mktemp`, or heredocs). Writing via your native file tool ensures backticks, quotes, and newlines are preserved exactly as intended without shell quoting or expansion errors.

### Create the draft PR

```bash
gh pr create \
  --base "$base_branch" \
  --head "$current_branch" \
  --title "feat(ui): Add dark mode toggle" \
  --body-file tmp_pr_body.md \
  --draft && rm tmp_pr_body.md
```

**Always create as a draft.** This gives the author a chance to review the PR on GitHub, add final touches, and mark it ready when appropriate. Never create a PR in ready-for-review state directly.

Optional flags (add only when the user provides them):
- `--label "bug,enhancement"` — labels
- `--reviewer "alice,bob"` — request reviewers
- `--assignee "@me"` — assign
- `--milestone "v2.0"` — attach to milestone

---

## Step 6: Confirm

After creating the PR, report back:

```
✅ Draft PR #47 created: https://github.com/owner/repo/pull/47

To mark it ready for review:
  gh pr ready 47
```

---

## Edge Cases

### Working with forks

If the user's branch is on a fork, use the `owner:branch` syntax for `--head`:

```bash
gh pr create --head "username:feat/dark-mode" --base main ...
```

### No `gh` CLI available

If `gh` is not installed or not authenticated, tell the user:
- Install: `brew install gh` or see https://cli.github.com/
- Authenticate: `gh auth login`

Do not attempt to fall back to raw API calls for PR creation — the `gh` CLI handles authentication, repo detection, and template rendering that are painful to replicate manually.
