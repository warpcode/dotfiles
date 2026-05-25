# Updating a PR

When the pre-flight detects an existing PR for the current branch, or the user explicitly asks to update a PR, follow this workflow.

## Pre-checks

Run the view script to fetch the current PR state:

```bash
# With explicit PR number
bash /path/to/this/skill/scripts/view.sh 47

# Auto-detect from current branch
bash /path/to/this/skill/scripts/view.sh
```

This outputs a formatted summary and saves full JSON, comments, and diff to temp files. Show the user the current state before making changes.

If no PR is found, ask the user for the PR number.

## Determine what to change

Map the user's request to the appropriate `gh pr edit` flags:

| Intent | Command |
|--------|---------|
| Change title | `gh pr edit <number> --title "New title"` |
| Change body | `gh pr edit <number> --body-file tmp_pr_body.md` |
| Add labels | `gh pr edit <number> --add-label "bug,enhancement"` |
| Remove labels | `gh pr edit <number> --remove-label "wip"` |
| Add reviewers | `gh pr edit <number> --add-reviewer "alice,bob"` |
| Remove reviewers | `gh pr edit <number> --remove-reviewer "charlie"` |
| Add assignees | `gh pr edit <number> --add-assignee "@me"` |
| Remove assignees | `gh pr edit <number> --remove-assignee "dave"` |
| Change base branch | `gh pr edit <number> --base "develop"` |
| Set milestone | `gh pr edit <number> --milestone "v2.0"` |

Multiple flags can be combined in a single command.

## Body updates: always use `--body-file`

The full JSON saved by `view.sh` in the pre-checks step contains the existing body in the `body` field. Read it from the JSON file — do **not** make a separate API call.

Use the existing body as your starting point — edit, extend, or restructure it rather than replacing it from scratch. The author may have added context, checklists, or formatting that shouldn't be lost.

When writing the updated body, use your native file writing tool to create the file, then pass it via `--body-file`. Never use `--body` with inline text.

## Review before submitting

Present the changes to the user before executing:

```
✏️  Updating PR #47 on owner/repo:

  Title:    feat(ui): Add dark mode toggle → feat(ui): Add dark mode with auto-detect
  Labels:   +needs-review
  Reviewers: +alice

Proceed? (or tell me what to change)
```

Show old → new for changed fields. Only proceed after approval.

## Confirm

```
✅ PR #47 updated: https://github.com/owner/repo/pull/47
```
