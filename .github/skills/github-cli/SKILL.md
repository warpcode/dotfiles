---
name: github-cli
description: >
  Execute GitHub remote operations (issues, pull requests, releases, search,
  repo files) using GitHub MCP or the gh CLI. Use when running GitHub commands.
user-invocable: false
---

# GitHub CLI & MCP Execution

Manage GitHub platform operations end-to-end through CLI and MCP tools. This skill is strictly for execution logic. For procedural guidelines (like when a PR is ready, review formatting, and workflows), load the `github` skill.

## Execution Priority

1. **Bundled Workflow Scripts** — Always check and use bundled composite scripts in
   `<skill-dir>/scripts/` first whenever one covers the workflow (e.g. `pr_audit_bundle.sh`
   for PR audits, `submit_pull_request_review_payload.sh` for reviews, `merge_pull_request.sh`
   for ruleset-gated merges, `pr_state_rollup.py` for status). They gather full snapshots in
   one invocation, avoid tool call sprawl, and enforce repo safety invariants.
2. **GitHub MCP server** — For operations not covered by a bundled workflow script,
   use GitHub MCP server tools (e.g. `issue_write`, `list_issues`, `search_code`) if
   authenticated and available.
3. **`gh` CLI Commands** — When MCP is unavailable or for targeted CLI checks,
   invoke native `gh` commands directly.
4. **No raw API access** — Do NOT fall back to raw `curl` calls against the
   GitHub REST or GraphQL APIs. If neither MCP nor `gh` is available, guide the
   user to install/authenticate `gh` (`gh auth login`) or enable the GitHub
   MCP server.

## Architecture & Sub-domain Routing

This skill is a routing hub. Identify the sub-domain and read the corresponding
reference file before executing:

| Sub-domain | Reference file | Capabilities & Covered MCP Tools | Access Level |
|-----------|----------------|----------------------------------|--------------|
| **Issues** | `@references/issues.md` | Create, update, query, comment, close, sub-issues, issue types, Copilot assignment (`get_issue`, `issue_write`, `add_issue_comment`, `list_issues`, `search_issues`, `list_issue_fields`, `list_issue_types`, `sub_issue_write`, `assign_copilot_to_issue`) | Read + Mutating |
| **Pull Requests** | `@references/pull-requests.md` | Create, update, publish, view, merge, list, triage/filter, branch update, merge status, Copilot review request (`create_pull_request`, `update_pull_request`, `update_pull_request_branch`, `get_pull_request`, `list_pull_requests`, `search_pull_requests`, `merge_pull_request`, `request_copilot_review`) | Read + Mutating |
| **Reviews** | `@references/reviews.md` | Thread discovery, batch payloads, thread resolution (`pull_request_review_write`, `add_comment_to_pending_review`, `add_reply_to_pull_request_comment`) | Read + Mutating |
| **Repository** | `@references/repository.md` | Remote file CRUD, atomic commits, remote branches, tags, collaborators, repo create/fork (`get_file_contents`, `create_or_update_file`, `delete_file`, `push_files`, `list_branches`, `create_branch`, `get_tag`, `list_tags`, `get_commit`, `list_commits`, `create_repository`, `fork_repository`, `list_repository_collaborators`) | Read + Mutating |
| **Releases** | `@references/releases.md` | Releases and release assets (`get_latest_release`, `get_release_by_tag`, `list_releases`) | Read + Mutating |
| **Search** | `@references/search.md` | Cross-GitHub discovery (`search_code`, `search_commits`, `search_issues`, `search_pull_requests`, `search_repositories`, `search_users`) | Read-Only |
| **Orgs & Teams** | `@references/orgs-teams.md` | Identity, organization teams, membership (`get_me`, `get_teams`, `get_team_members`) | Read-Only |

Read only the reference(s) needed for the query. Never load all references upfront.

## Shared Resources

Run bundled helper scripts relative to this skill's root directory (`<skill-dir>/scripts/...` e.g. `.github/skills/github-cli/scripts/...`):

| Resource | Location | Invocation Syntax | Purpose |
|----------|----------|-------------------|---------|
| PR audit bundle script | `@scripts/pr_audit_bundle.sh` | `bash <skill-dir>/scripts/pr_audit_bundle.sh --repo <owner/repo> --pr <n> [--out <dir>]` | One-call non-invasive PR audit: metadata, diff file, head file copies, source issues + acceptance criteria, dependency shipped status |
| List / Filter PRs script | `@scripts/list_pull_requests.sh` | `bash <skill-dir>/scripts/list_pull_requests.sh [OPTIONS]` | List and filter PRs (approved, commits after review, waiting on author, unresponded) |
| List PR review threads script | `@scripts/list_pull_request_review_threads.sh` | `bash <skill-dir>/scripts/list_pull_request_review_threads.sh [OPTIONS]` | Retrieve review threads for a pull request via GraphQL |
| Merge PR script | `@scripts/merge_pull_request.sh` | `bash <skill-dir>/scripts/merge_pull_request.sh --pull-number <n> [--admin]` | Ruleset-gated squash merge with safety bypass |
| Resolve thread script | `@scripts/update_pull_request_review_thread_resolution.sh` | `bash <skill-dir>/scripts/update_pull_request_review_thread_resolution.sh [OPTIONS]` | Resolve PR review threads via GraphQL |
| Submit review payload script | `@scripts/submit_pull_request_review_payload.sh` | `bash <skill-dir>/scripts/submit_pull_request_review_payload.sh [OPTIONS]` | Submit structured PR review payload (with file/line comments) via REST |
| PR status query | `@queries/find_prs.gql` | GraphQL query for PR status, review, and activity classification |
| Review threads query | `@queries/review_threads.gql` | GraphQL query to list review threads |
| Resolve thread query | `@queries/resolve_review_thread.gql` | GraphQL mutation to resolve review threads |
| PR state rollup | `@scripts/pr_state_rollup.py` | `python3 <skill-dir>/scripts/pr_state_rollup.py --repo <owner/repo> [PR numbers…] [--all-states] [--wait] [--expect-sha N=SHA] [--json]` | One `gh pr list` call → dense table of state, draft, head SHA, review decision, mergeability, CI checks. `--wait` polls internally instead of sleep-looping in bash; `--expect-sha` flags a bot amending mid-audit. Exit 2 if any PR is conflicting, has failing checks, or drifted |
| Repo alert audit | `@scripts/audit_repo_alerts.py` | `python3 <skill-dir>/scripts/audit_repo_alerts.py --repo <owner/repo> [--base master] [--json] [--fetch]` | Dependabot + code-scanning triage in one call. Classifies each alert against the default branch, separates **phantom** alerts (manifest deleted/moved) from real ones, flags `first_patched_version: NONE` (no upgrade exists — record, don't churn), summarises triplicated advisories, prints the exact dismiss commands and valid `dismissed_reason` values. Read-only |

### Alert triage notes

- **Phantom alerts are the norm without a `dependabot.yml`.** Dependabot auto-discovers
  manifests repo-wide and keeps alerts for files that were later deleted or moved. Observed:
  9 open alerts for 3 real ones — the same advisories triplicated across a live path, a
  deleted tree, and a `.bk` backup directory. Dismissal does not fix the cause; pin
  `directory:` in `.github/dependabot.yml`.
- **`dismissed_comment` is capped at 280 characters** — the API returns HTTP 422 if you exceed
  it. Valid code-scanning `dismissed_reason` values are exactly `false positive`, `won't fix`,
  `used in tests`, `mitigated`.
- **Never bind a shell loop variable to `path` in zsh.** `path` is tied to `PATH`, so the
  assignment removes `git`/`gh` from `PATH` and every manifest-existence check silently
  returns "absent" — producing a confident, complete-looking answer that marks real alerts as
  phantoms. Observed classifying 10/10 as missing when 3 existed. Both scripts here are
  Python for that reason; `audit_repo_alerts.py` also refuses to run outside a work tree,
  where the same failure would mark *every* alert phantom.
- A `py/command-line-injection` finding on `subprocess.run(cmd, ...)` is usually a false
  positive when `cmd` is an argv **list**. Check for `shell=True`, `os.system`,
  `subprocess.call` and `Popen` before treating it as real.

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
8. **Execution priority**: Bundled workflow scripts first, then GitHub MCP
   server, then `gh` CLI. Never use raw `curl` against the GitHub REST or
   GraphQL APIs.
9. **Write operations require authentication** — guide the user to
   `gh auth login` or enable the GitHub MCP server when missing.
