---
name: github
description: >
  Universal GitHub Knowledge Centre and script toolkit for pull requests
  (mainline, epic-tree, and stacked baseRefName targeting/retargeting, inline
  comment anchoring, GraphQL threads, conflict resolution, merging), issues
  (templates, native Sub-Issues, parent Epics, dependency markers), Dependabot
  alert triage and dependabot.yml, releases, repository CRUD, search, and gh CLI
  / MCP execution. Use when performing any GitHub operation, running gh commands,
  managing PRs or issues, or auditing Dependabot alerts.
---

# GitHub Knowledge Centre

Universal domain guidelines, platform mechanics, and black-box script toolkit for GitHub operations via bundled scripts, GitHub MCP tools, and the `gh` CLI.

---

## Execution Priority

1. **Bundled Scripts (`@scripts/`)** — Always prefer bundled composite scripts first whenever one covers the task; they capture consistent snapshots in one call and enforce platform safety invariants.
2. **GitHub MCP Server** — Use GitHub MCP tools when authenticated and no bundled script covers the operation.
3. **`gh` CLI Commands** — Invoke native `gh` commands when MCP is unavailable or for targeted operations.
4. **No Raw `curl`** — Never use raw `curl` against GitHub REST or GraphQL APIs.

---

## Sub-Domain Routing

Load only the reference file(s) needed for the current task:

| Sub-Domain | Reference | Covers |
|---|---|---|
| **Pull Requests** | `@references/pull-requests.md` | PR creation, update, view, checks, Copilot review, rollup, and merge commands |
| **Stacked & Epic PRs** | `@references/stacked-epic-prs.md` | Mainline vs `epic/<id>-<slug>` vs stacked `baseRefName` targeting, retargeting on upstream merge, cascading `--onto` rebase, `rerere`, CI branch filters |
| **`gh stack` CLI** | `@references/stacked-prs.md` | Non-interactive `gh stack` extension commands (`init`, `add`, `submit`, `sync`, `merge`) |
| **Reviews Execution** | `@references/reviews.md` | Thread discovery, REST payload submission, thread resolution, mixed-type GraphQL reviews |
| **Review Mechanics** | `@references/review-mechanics.md` | `side: RIGHT` anchoring rules, stale-ref races, GraphQL thread pagination/plain-text resolution, self-authored HTTP 422, blob-hash sweeps, shipped-dependency checks |
| **Issues** | `@references/issues.md` | Create, read, update, comment, list, assign Copilot, issue types & custom fields |
| **Sub-Issues & Epics** | `@references/sub-issues-and-epics.md` | Native `sub_issues` REST/GraphQL APIs (integer database `id`), parent Epic layout, `Depends on #N` / `Blocked by #N` markers |
| **Dependabot** | `@references/dependabot.md` | Active/phantom/unfixable alert classification, 280-char dismissal cap, lockfile bump recipes, `@dependabot` commands, `.github/dependabot.yml` |
| **Repository** | `@references/repository.md` | Remote file CRUD, atomic commits, branches, tags, commits, repo create/fork |
| **Releases** | `@references/releases.md` | Latest release, release by tag, release listing |
| **Search** | `@references/search.md` | Cross-GitHub code, commit, issue, PR, repository, and user search |
| **Orgs & Teams** | `@references/orgs-teams.md` | Current identity, organization teams, and team membership |

---

## Templates & Queries

- **PR & Review Templates**: `@templates/pull_request.md`, `@templates/pull_request_review_comment.md`
- **Issue Templates** (fallback when `.github/ISSUE_TEMPLATE/` is absent): `@templates/bug_report.md`, `@templates/feature_request.md`, `@templates/task_chore.md`, `@templates/question_discussion.md`, `@templates/security_vulnerability.md`
- **GraphQL Queries**: `@queries/find_prs.gql`, `@queries/pr_state.gql`, `@queries/review_threads.gql`, `@queries/batch_review_threads.gql`, `@queries/resolve_review_thread.gql`

---

## Bundled Script Toolkit (`scripts/`)

Run scripts with `--help` without reading source code. PR/review scripts standardize on `--repo <owner>/<repo>` (legacy `--owner`/`--repo` remains accepted where noted).

| Script | Invocation | Run When |
|---|---|---|
| `pr_audit_bundle.sh` | `bash <skill-dir>/scripts/pr_audit_bundle.sh --repo <owner/repo> --pr <n> [--out <dir>]` | Gathering PR metadata, diff, head file copies, source issue, and dependency status in one call |
| `pr_state_rollup.py` | `python3 <skill-dir>/scripts/pr_state_rollup.py --repo <owner/repo> [PRs...] [--wait] [--json]` | Inspecting state, draft, head SHA, review decision, mergeability, and CI across PRs |
| `pr_preflight.sh` | `bash <skill-dir>/scripts/pr_preflight.sh --repo <owner/repo> --pr <n> [--expect-sha <sha>]` | Capturing diff + head ref in one fetch and asserting the PR head has not moved |
| `prebundle_prs.sh` | `bash <skill-dir>/scripts/prebundle_prs.sh --repo <owner/repo> (--prs <list> \| --all-open)` | Pre-generating `/tmp/pr<N>/` audit bundles in parent session before parallel subagent reviews |
| `review_worktree.sh` | `bash <skill-dir>/scripts/review_worktree.sh add\|rm\|list\|exec --pr <n> [--role head\|base\|merge]` | Creating, running tests inside, or cleaning up fixed-path throwaway audit worktrees |
| `list_pull_requests.sh` | `bash <skill-dir>/scripts/list_pull_requests.sh [OPTIONS]` | Listing and filtering open/approved/waiting PRs via GraphQL (`find_prs.gql`) |
| `pr_review_queue.sh` | `bash <skill-dir>/scripts/pr_review_queue.sh [--threads] [owner/repo ...]` | Generating a multi-repository PR review queue overview |
| `list_pull_request_review_threads.sh` | `bash <skill-dir>/scripts/list_pull_request_review_threads.sh --repo <owner/repo> --pull-number <n>` | Listing review threads, resolution state, and integer `databaseId` values |
| `update_pull_request_review_thread_resolution.sh` | `bash <skill-dir>/scripts/update_pull_request_review_thread_resolution.sh --thread-id <id>` | Resolving GraphQL PR review threads (supports `--thread-ids` batching; emits plain text) |
| `reply_to_review_thread.sh` | `bash <skill-dir>/scripts/reply_to_review_thread.sh --repo <owner/repo> --pr <n> --comment-id <databaseId> --body "..."` | Replying to an unresolved review thread using its integer REST `databaseId` |
| `build_review_payload.py` | `python3 <skill-dir>/scripts/build_review_payload.py <spec.json> --out <payload.json> [--event ...]` | Converting a findings spec JSON into a REST review payload (`side: RIGHT`) |
| `verify_review_anchors.sh` | `bash <skill-dir>/scripts/verify_review_anchors.sh --diff <pr.diff> --payload <payload.json> [--head <ref>]` | Hard-gating every inline anchor against `+` lines in the PR diff before submission |
| `submit_review.sh` | `bash <skill-dir>/scripts/submit_review.sh --spec <spec.json> --repo <owner/repo> --pr <n> [--validate-only]` | Building, anchor-gating, and submitting a PR review from one consistent fetch |
| `submit_pull_request_review_payload.sh` | `bash <skill-dir>/scripts/submit_pull_request_review_payload.sh --repo <owner/repo> --pull-number <n> --input <payload.json>` | Posting a pre-built, verified REST review payload JSON |
| `batch_disposition.sh` | `bash <skill-dir>/scripts/batch_disposition.sh --repo <owner/repo> [--approve ...] [--request-changes-dir ...] [--close ...] [--execute]` | Dry-running (default) or executing validated multi-PR review dispositions |
| `pr_sync_validate.sh` | `bash <skill-dir>/scripts/pr_sync_validate.sh <pr> --repo <owner/repo> [--push] [--cleanup]` | Merging `origin/<base>` into a standalone PR in an isolated worktree, validating, and pushing |
| `pr_merge.sh` | `bash <skill-dir>/scripts/pr_merge.sh <pr> --repo <owner/repo> [--admin] [--dry-run]` | Preflighting mergeability + CI checks and squash-merging a single approved PR |
| `batch_merge.sh` | `bash <skill-dir>/scripts/batch_merge.sh --repo <owner/repo> --prs <1,2,3> [--admin] [--dry-run]` | Preflighting and sequentially squash-merging multiple approved PRs |
| `merge_pull_request.sh` | `bash <skill-dir>/scripts/merge_pull_request.sh --owner <o> --repo <r> --pull-number <n> [--admin]` | Merging an open PR with ruleset-aware method detection and optional `--admin` bypass |
| `pr_batch_merge.sh` | `bash <skill-dir>/scripts/pr_batch_merge.sh [--repo <owner/repo>] [--dry-run] <pr>...` | Silently approving and squash-merging verified green PRs |
| `audit_repo_alerts.py` | `python3 <skill-dir>/scripts/audit_repo_alerts.py --repo <owner/repo> [--base <default-branch>] [--json]` | Auditing Dependabot and code-scanning alerts against the default branch (separates phantoms) |

---

## Hard Rules & Safety Invariants

1. **Never Infer `baseRefName`**: Confirm mainline (`main`/`master`), epic (`epic/<id>-<slug>`), or stacked parent branch explicitly; never create a PR from `main`/`master`.
2. **Draft First**: Always create pull requests as `--draft` unless explicitly instructed otherwise.
3. **Always Use `--body-file`**: Write PR/issue bodies using file-writing tools and pass `--body-file`; never pass inline `--body` strings or shell heredocs.
4. **Confirm Before Mutating**: Present full proposed PR/issue/review/merge content and obtain explicit user approval before mutating GitHub state.
5. **Pre-PR Checks**: Verify an open PR does not already exist for the branch and run `git-expert/scripts/branch_base_check.sh` before `gh pr create`.
6. **Repo Routing**: Never assume `warpcode/dotfiles` from a bare issue or PR number; confirm `<owner>/<repo>` explicitly.
7. **No N+1 Inspection Loops**: Never loop `gh pr view` in shell; use `scripts/pr_state_rollup.py` or bulk `gh pr list`.
8. **Ephemeral Scratch Paths**: Never create `./scratch/` inside the repo working tree; save diffs and payloads to `/tmp/` or the conversation scratch directory.
9. **Conflict Resolution Policy**: Update standalone PRs by merging `origin/<base>` (`scripts/pr_sync_validate.sh`), never rebase/force-push; update stacked PRs via cascading `--onto` rebase.
