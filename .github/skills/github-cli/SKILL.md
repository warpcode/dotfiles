---
name: github-cli
description: >
  Manage GitHub platform operations: issues & sub-issues (create, update, query,
  comment, hierarchy, triage), pull requests (create, update, publish, view,
  merge, review, list, search), PR review orchestration, remote repository files
  & commits (read, create, update, delete, push), releases & tags, global search
  (code, commits, issues, PRs, repos, users), and organizations/teams.
  Prioritises GitHub MCP server actions when available; falls back to the gh CLI
  when MCP is unavailable. Use this skill whenever the user says things like
  "open a PR", "create a pull request", "review this PR", "merge PR", "list open
  PRs", "file an issue", "sub-issue", "search code on GitHub", "get release",
  "list teams", "update remote file", or "check CI status". Triggers on any
  GitHub workflow discussed even without the word "GitHub". Do NOT use for local
  git operations (local commit, rebase, branch naming, local triage) — use the
  git-expert skill instead.
---

# GitHub

Manage GitHub platform operations end-to-end — safely, consistently, always as
drafts first, and always with explicit user approval before any mutating action.

## Execution Priority

1. **GitHub MCP server** — If the GitHub MCP server is available and
   authenticated, use its tools (e.g. `create_pull_request`, `list_issues`,
   `add_issue_comment`, `pull_request_review_write`) as the primary execution surface.
2. **`gh` CLI** — If MCP is unavailable or unauthenticated, use the `gh` CLI
   or `gh api` for all operations.
3. **No raw API access** — Do NOT fall back to raw `curl` calls against the
   GitHub REST or GraphQL APIs. If neither MCP nor `gh` is available, guide the
   user to install/authenticate `gh` (`gh auth login`) or enable the GitHub
   MCP server.

## Architecture & Sub-domain Routing

This skill is a routing hub. Identify the sub-domain and read the corresponding
reference file before responding:

| Sub-domain | Reference file | Capabilities & Covered MCP Tools | Access Level |
|-----------|----------------|----------------------------------|--------------|
| **Issues** | `${SKILL_DIR}/references/issues.md` | Create, update, query, comment, close, sub-issues, issue types, Copilot assignment (`issue_read`, `issue_write`, `add_issue_comment`, `list_issues`, `search_issues`, `list_issue_fields`, `list_issue_types`, `sub_issue_write`, `assign_copilot_to_issue`) | Read + Mutating |
| **Pull Requests** | `${SKILL_DIR}/references/pull-requests.md` | Create (draft), update, publish, view, merge, list, triage/filter, branch update, Copilot review request (`create_pull_request`, `update_pull_request`, `update_pull_request_branch`, `pull_request_read`, `list_pull_requests`, `search_pull_requests`, `merge_pull_request`, `request_copilot_review`) | Read + Mutating |
| **Reviews** | `${SKILL_DIR}/references/reviews.md` | Non-invasive PR review orchestration, thread discovery, batch payloads, thread resolution (`pull_request_review_write`, `add_comment_to_pending_review`, `add_reply_to_pull_request_comment`) | Read + Mutating |
| **Repository** | `${SKILL_DIR}/references/repository.md` | Remote file CRUD, atomic commits, remote branches, tags, collaborators, repo create/fork (`get_file_contents`, `create_or_update_file`, `delete_file`, `push_files`, `list_branches`, `create_branch`, `get_tag`, `list_tags`, `get_commit`, `list_commits`, `create_repository`, `fork_repository`, `list_repository_collaborators`) | Read + Mutating |
| **Releases** | `${SKILL_DIR}/references/releases.md` | Releases and release assets (`get_latest_release`, `get_release_by_tag`, `list_releases`) | Read + Mutating |
| **Search** | `${SKILL_DIR}/references/search.md` | Cross-GitHub discovery (`search_code`, `search_commits`, `search_issues`, `search_pull_requests`, `search_repositories`, `search_users`) | Read-Only |
| **Orgs & Teams** | `${SKILL_DIR}/references/orgs-teams.md` | Identity, organization teams, membership (`get_me`, `get_teams`, `get_team_members`) | Read-Only |
| **Templates** | `${SKILL_DIR}/references/templates.md` | Standard issue and PR templates (Bug, Feature, Chore, Discussion, Security) | Read-Only |

Read only the reference(s) needed for the query. Never load all references
upfront.

## Shared Resources

| Resource | Path | Purpose |
|----------|------|---------|
| Pre-flight script | `${SKILL_DIR}/scripts/preflight.sh` | Safety checks (branch, remote, auth, existing PRs) — run before Create |
| Context script | `${SKILL_DIR}/scripts/context.sh <base> <head>` | Collect commits, diffstat, and full diff — run during Create |
| View script | `${SKILL_DIR}/scripts/view.sh [<pr_number>]` | Fetch PR metadata, comments, and diff — run during View |
| Find / Triage PRs script | `${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] [flags]` | Filter PRs (approved, commits after review, waiting on author, unresponded) |
| Fetch threads script | `${SKILL_DIR}/scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]` | Batch retrieve review threads for all open PRs |
| Fetch file script | `${SKILL_DIR}/scripts/fetch_file.sh <owner> <repo> <path> <branch>` | Fetch remote PR file contents without checkout |
| PR context script | `${SKILL_DIR}/scripts/fetch_pr_context.sh <owner> <repo> <pr_number>` | Fetch comprehensive PR state (comments, reviews, threads, readiness) for review |
| Submit review script | `${SKILL_DIR}/scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>` | Submit atomic JSON reviews |
| Resolve thread script | `${SKILL_DIR}/scripts/resolve_review_thread.sh <thread_id>` | Resolve PR review threads via GraphQL |
| Pre-merge checks script | `${SKILL_DIR}/scripts/fetch_pr_merge_checks.sh <pr_number>` | Validate syntax, safety, scope, regressions before approve/merge |
| Fallback PR body template | `${SKILL_DIR}/templates/pull_request.md` | PR body template when the repo has none |
| Review comment template | `${SKILL_DIR}/templates/github/review_comment.md` | Structure for line-level review comments |
| PR status query | `${SKILL_DIR}/queries/find_prs.gql` | GraphQL query for PR status, review, and activity classification |
| Review threads query | `${SKILL_DIR}/queries/review_threads.gql` | GraphQL query to list review threads |
| Resolve thread query | `${SKILL_DIR}/queries/resolve_review_thread.gql` | GraphQL mutation to resolve review threads |

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
