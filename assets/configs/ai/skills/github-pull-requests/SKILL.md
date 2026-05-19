---
name: github-pull-requests
description: >
  Create, update, publish, view, and search pull requests on GitHub using the gh
  CLI. Use this skill whenever the user wants to open a PR, create a pull request,
  submit code for review, or says anything like "open a PR", "create pull request",
  "submit for review", "PR this branch", "raise a PR", or "send this for review".
  Also trigger when the user wants to update an existing PR ("update the PR",
  "change the PR title", "add reviewers", "edit PR description"), mark a draft PR
  as ready ("publish the PR", "mark PR ready", "undraft the PR"), view PR details
  ("show me the PR", "what's the status of PR #42", "check PR comments", "are
  there merge conflicts", "what did reviewers say", "check CI status"), or list
  and search PRs ("list open PRs", "my PRs", "find PRs with label bug", "show
  PRs needing review"). If the user is on a feature branch and mentions shipping,
  merging, or getting eyes on their code, this skill likely applies.
  Do NOT use this skill for issues — use the github-issues skill instead.
---

# GitHub Pull Requests

Create, update, publish, view, and search pull requests on GitHub — safely, consistently, and always as drafts first.

## Operations

Identify the user's intent and read the corresponding reference file from this skill's `references/` directory:

| Operation | When | Reference |
|-----------|------|-----------|
| **Create** | No PR exists for this branch | `references/create.md` |
| **Update** | PR already exists or user asks to edit title, body, labels, reviewers, assignees, or milestone | `references/update.md` |
| **Publish** | User wants to mark a draft PR as ready for review | `references/publish.md` |
| **View** | User wants to inspect a specific PR — description, comments, reviews, CI status, merge conflicts, or requested changes | `references/view.md` |
| **List** | User wants to search, filter, or browse PRs by state, label, author, assignee, branch, or full-text search | `references/list.md` |

Read **only** the reference you need — do not load all of them.

## Shared Resources

| Resource | Path | Purpose |
|----------|------|---------|
| Pre-flight script | `scripts/preflight.sh` | Safety checks (branch, remote, auth, existing PRs) — run before Create |
| Context script | `scripts/context.sh <base> <head>` | Collect commits, diffstat, and full diff into temp files — run during Create |
| View script | `scripts/view.sh [<pr_number>]` | Fetch PR metadata, comments, and diff into temp files — run during View |
| Fallback body template | `templates/pull_request.md` | PR body template when the repo has none |

## Hard Rules

These rules apply to **all** operations:

1. **Never infer the base branch.** Always ask the user if not provided.
2. **Never create a PR from `main`/`master`.** Stop immediately and tell the user.
3. **Always create PRs as drafts.** Never create in ready-for-review state.
4. **Always use `--body-file`.** Write the body via your native file writing tool, then pass the path to `gh`. Never use `--body` with inline text. Never use shell-based file creation (`cat`, `echo`, `mktemp`, heredocs).
5. **Always confirm before executing.** Present the full PR/change to the user and wait for explicit approval.
6. **Always check for existing PRs.** Before creating, verify one doesn't already exist for this branch.
