---
name: github-cli
description: >
  Execute GitHub platform operations: issues & sub-issues (create, update, query,
  comment, hierarchy), pull requests (create, update, publish, view,
  merge, list, search), remote repository files & commits (read, create, update, delete, push), 
  releases & tags, global search, and organizations/teams.
  Prioritises GitHub MCP server actions when available; falls back to the `gh` CLI
  when MCP is unavailable. Use this skill for pure execution and CLI guidance. 
  For procedure-based guidelines and preferences, refer to the `github` skill instead.
  Do NOT use for local git operations (local commit, rebase, branch naming) — use the
  git-expert skill instead.
user-invocable: false
---

# GitHub CLI & MCP Execution

Manage GitHub platform operations end-to-end through CLI and MCP tools. This skill is strictly for execution logic. For procedural guidelines (like when a PR is ready, review formatting, and workflows), load the `github` skill.

## Execution Priority

1. **GitHub MCP server** — If the GitHub MCP server is available and
   authenticated, use its tools (e.g. `create_pull_request`, `list_issues`,
   `add_issue_comment`, `pull_request_review_write`) as the primary execution surface.
2. **MCP Parity Scripts** — If MCP is unavailable, you MUST use the corresponding wrapper script in `${SKILL_DIR}/scripts/` (e.g., `${SKILL_DIR}/scripts/create_pull_request.sh`, `${SKILL_DIR}/scripts/list_issues.sh`). There is a 1-to-1 parity script for every MCP tool. Do NOT manually construct complex `gh` or `gh api` CLI commands yourself; pass the required MCP arguments as flags to the wrapper script (e.g. `--owner`, `--repo`, `--title`).
3. **No raw API access** — Do NOT fall back to raw `curl` calls against the
   GitHub REST or GraphQL APIs. If neither MCP nor `gh` is available, guide the
   user to install/authenticate `gh` (`gh auth login`) or enable the GitHub
   MCP server.

## Architecture & Sub-domain Routing

This skill is a routing hub. Identify the sub-domain and read the corresponding
reference file before executing:

| Sub-domain | Reference file | Capabilities & Covered MCP Tools | Access Level |
|-----------|----------------|----------------------------------|--------------|
| **Issues** | `${SKILL_DIR}/references/issues.md` | Create, update, query, comment, close, sub-issues, issue types, Copilot assignment (`get_issue`, `issue_write`, `add_issue_comment`, `list_issues`, `search_issues`, `list_issue_fields`, `list_issue_types`, `sub_issue_write`, `assign_copilot_to_issue`) | Read + Mutating |
| **Pull Requests** | `${SKILL_DIR}/references/pull-requests.md` | Create, update, publish, view, merge, list, triage/filter, branch update, merge status, Copilot review request (`create_pull_request`, `update_pull_request`, `update_pull_request_branch`, `get_pull_request`, `list_pull_requests`, `search_pull_requests`, `merge_pull_request`, `request_copilot_review`) | Read + Mutating |
| **Reviews** | `${SKILL_DIR}/references/reviews.md` | Thread discovery, batch payloads, thread resolution (`pull_request_review_write`, `add_comment_to_pending_review`, `add_reply_to_pull_request_comment`) | Read + Mutating |
| **Repository** | `${SKILL_DIR}/references/repository.md` | Remote file CRUD, atomic commits, remote branches, tags, collaborators, repo create/fork (`get_file_contents`, `create_or_update_file`, `delete_file`, `push_files`, `list_branches`, `create_branch`, `get_tag`, `list_tags`, `get_commit`, `list_commits`, `create_repository`, `fork_repository`, `list_repository_collaborators`) | Read + Mutating |
| **Releases** | `${SKILL_DIR}/references/releases.md` | Releases and release assets (`get_latest_release`, `get_release_by_tag`, `list_releases`) | Read + Mutating |
| **Search** | `${SKILL_DIR}/references/search.md` | Cross-GitHub discovery (`search_code`, `search_commits`, `search_issues`, `search_pull_requests`, `search_repositories`, `search_users`) | Read-Only |
| **Orgs & Teams** | `${SKILL_DIR}/references/orgs-teams.md` | Identity, organization teams, membership (`get_me`, `get_teams`, `get_team_members`) | Read-Only |

Read only the reference(s) needed for the query. Never load all references upfront.

## Shared Resources

| Resource | Path | Purpose |
|----------|------|---------|
| List / Filter PRs script | `${SKILL_DIR}/scripts/list_pull_requests.sh [OPTIONS]` | List and filter PRs (approved, commits after review, waiting on author, unresponded) |
| List PR review threads script | `${SKILL_DIR}/scripts/list_pull_request_review_threads.sh [OPTIONS]` | Retrieve review threads for a pull request via GraphQL |
| Get PR script | `${SKILL_DIR}/scripts/get_pull_request.sh [OPTIONS]` | Fetch comprehensive PR state (summary table, merge readiness checks, comments, reviews, stats) |
| Resolve thread script | `${SKILL_DIR}/scripts/update_pull_request_review_thread_resolution.sh [OPTIONS]` | Resolve PR review threads via GraphQL |
| PR status query | `${SKILL_DIR}/queries/find_prs.gql` | GraphQL query for PR status, review, and activity classification |
| Review threads query | `${SKILL_DIR}/queries/review_threads.gql` | GraphQL query to list review threads |
| Resolve thread query | `${SKILL_DIR}/queries/resolve_review_thread.gql` | GraphQL mutation to resolve review threads |

## Hard Rules

These apply to **all** operations executed via `gh` CLI:

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
   APPROVE, REQUEST_CHANGES).
8. **Execution priority**: GitHub MCP server first, then `gh` CLI. Never use
   raw `curl` against the GitHub REST or GraphQL APIs.
9. **Write operations require authentication** — guide the user to
   `gh auth login` or enable the GitHub MCP server when missing.
