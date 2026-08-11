---
name: github
description: >
  Manage GitHub platform operations: issues (create, update, query, comment,
  triage), pull requests (create, update, publish, view, review, list, search),
  and PR review orchestration (discovery, inspection, submission, thread
  resolution). Prioritises GitHub MCP server actions when available; falls back
  to the gh CLI when MCP is unavailable. Use this skill whenever the user says
  things like "open a PR", "create a pull request", "review this PR", "list
  open PRs", "file an issue", "update issue #42", "check my issues", "add a
  comment to PR", "what's the status of PR #42", or "check CI status". Triggers
  on any GitHub workflow discussed even without the word "GitHub". Do NOT use
  for local git operations (commit, rebase, branch naming, triage) — use the
  git-expert skill instead.
---

# GitHub

Manage GitHub issues, pull requests, and reviews end-to-end — safely,
consistently, always as drafts first, and always with explicit user approval
before any mutating action.

## Execution Priority

1. **GitHub MCP server** — If the GitHub MCP server is available and
   authenticated, use its tools (e.g. `create_pull_request`, `list_issues`,
   `add_issue_comment`, `submit_review`) as the primary execution surface.
2. **`gh` CLI** — If MCP is unavailable or unauthenticated, use the `gh` CLI
   for all operations.
3. **No raw API access** — Do NOT fall back to raw `curl` calls against the
   GitHub REST or GraphQL APIs. If neither MCP nor `gh` is available, guide the
   user to install/authenticate `gh` (`gh auth login`) or enable the GitHub
   MCP server.

## Architecture

This skill is a routing hub. Identify the sub-domain and read the corresponding
reference file before responding:

| Sub-domain | Reference file | When |
|-----------|----------------|------|
| Issues | `references/issues.md` | Create, update, query, comment, close issues; labels; milestones; templates |
| Pull requests | `references/pull-requests.md` | Create (draft), update, publish, view, list, search PRs |
| Reviews | `references/reviews.md` | Orchestrate PR reviews: discovery, inspection, review payloads, thread resolution |

Read only the reference(s) needed for the query. Never load all references
upfront.

## Shared Resources

| Resource | Path | Purpose |
|----------|------|---------|
| Pre-flight script | `scripts/preflight.sh` | Safety checks (branch, remote, auth, existing PRs) — run before Create |
| Context script | `scripts/context.sh <base> <head>` | Collect commits, diffstat, and full diff — run during Create |
| View script | `scripts/view.sh [<pr_number>]` | Fetch PR metadata, comments, and diff — run during View |
| Fetch threads script | `scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]` | Batch retrieve review threads for all open PRs |
| Fetch file script | `scripts/fetch_file.sh <owner> <repo> <path> <branch>` | Fetch remote PR file contents without checkout |
| PR context script | `scripts/get_pr_context.sh <owner> <repo> <pr_number>` | Fetch PR head OID and diff for review |
| Submit review script | `scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>` | Submit atomic JSON reviews |
| Resolve thread script | `scripts/resolve_review_thread.sh <thread_id>` | Resolve PR review threads via GraphQL |
| Pre-merge checks script | `scripts/pre_merge_checks.sh <pr_number>` | Validate syntax, safety, scope, regressions before approve/merge |
| Fallback PR body template | `templates/pull_request.md` | PR body template when the repo has none |
| Review comment template | `templates/github/review_comment.md` | Structure for line-level review comments |
| Review threads query | `queries/review_threads.gql` | GraphQL query to list review threads |
| Resolve thread query | `queries/resolve_review_thread.gql` | GraphQL mutation to resolve review threads |

## Hard Rules

These apply to **all** operations:

1. **Never infer the base branch.** Always ask the user if not provided.
2. **Never create a PR from `main`/`master`.** Stop immediately and tell the user.
3. **Always create PRs as drafts.** Never create in ready-for-review state.
4. **Always use `--body-file`** for PR and issue bodies. Write via the agent's
   file-writing tool, then pass the path to `gh`. Never use `--body` with inline
   text. Never use shell-based file creation (`cat`, `echo`, `mktemp`, heredocs).
5. **Always confirm before executing** any mutating operation. Present the full
   content and wait for explicit approval.
6. **Always check for existing PRs** before creating — verify one doesn't
   already exist for the branch.
7. **Always get explicit permission before posting a review** (COMMENT,
   APPROVE, REQUEST_CHANGES). Present the full comment list and status.
8. **Execution priority**: GitHub MCP server first, then `gh` CLI. Never use
   raw `curl` against the GitHub REST or GraphQL APIs.
9. **Write operations require authentication** — guide the user to
   `gh auth login` or enable the GitHub MCP server when missing.
