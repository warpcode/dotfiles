---
name: github-pr
description: >
  GitHub Pull Requests Knowledge Centre covering PR lifecycle, draft conventions,
  mainline and epic-tree/stacked baseRefName targeting and retargeting, REST inline
  comment anchoring, GraphQL thread triage, conflict resolution, and merging. Use
  when creating, updating, reviewing, syncing, retargeting, or merging pull requests.
user-invocable: false
---

# GitHub Pull Requests Knowledge Centre

Domain guidelines, platform mechanics, and black-box script toolkit for GitHub Pull Requests (standalone, epic-tree, and stacked). For raw `gh` CLI / MCP tool routing and GraphQL query files, pair with `github-cli`.

---

## 1. Base Branch, Targeting & Draft Conventions

- **Never Infer Base Branch**: Query or confirm `baseRefName` explicitly. Never default to `main` or `master` without explicit instruction.
- **Mainline vs. Epic-Tree vs. Stacked Targeting**:
  - **Standalone**: Branch from `origin/<default-branch>` and verify ancestry with `git-expert/scripts/branch_base_check.sh`.
  - **Epic Integration**: Target `epic/<id>-<slug>` when subtasks land into a shared epic branch before merging to trunk.
  - **Stacked**: Target the immediate upstream dependency branch `(trunk) <- layer-1 <- layer-2`. When an upstream PR squash-merges, retarget `baseRefName` (`gh pr edit <n> --base <new-base>`) and replay with `git rebase --onto` so squashed commits are not replayed.
  - See `@references/stacked-epic-prs.md` for layer ordering, retargeting, `rerere`, and CI branch-filter rules.
- **Draft First**: Always create PRs as `--draft` first unless explicitly instructed otherwise.
- **Explicit Approval**: Present proposed title, body, base/head branches, and draft state before creating, publishing, or merging.

---

## 2. Title & Body Standards

- **Title Format**: `[TICKET-ID] Summary`, `[#42] Summary`, `type(scope): summary`, or `WIP: Summary` — imperative mood, under 70 characters, capitalized summary.
- **Body Template**: Prefer repo templates (`.github/PULL_REQUEST_TEMPLATE.md` or `.github/PULL_REQUEST_TEMPLATE/*.md`); fallback to `@templates/pull_request.md`. Include what/why, linked issues (`Closes #N` / `Depends on #N`), stack position if stacked, and observed verification results.
- **Inline Review Finding Format**: Use `@templates/pull_request_review_comment.md` (`Severity`, `Description`, `Impact`, `Proposed Solution`).

---

## 3. Inline Comment Anchoring & Review Mechanics

- **REST Inline Anchors**: Always use `side: "RIGHT"` and 1-indexed post-change line numbers on `+` lines within diff hunks. Never include GraphQL-only `subject_type` in REST payloads.
- **Pre-Submit Anchor Gate**: Always run `scripts/verify_review_anchors.sh` (or `scripts/submit_review.sh`, which runs build + anchor gate + submit in one fetch).
- **Single-Fetch Consistency**: Never pass stale `--diff`/`--head` artifacts across separate fetches; use `scripts/pr_preflight.sh` or plain `scripts/submit_review.sh`.
- **Self-Authored PRs**: GitHub rejects `REQUEST_CHANGES` and `APPROVE` on self-authored PRs (HTTP 422); use `COMMENT`.
- **Thread Resolution & Replies**: `github-cli/scripts/update_pull_request_review_thread_resolution.sh` emits plain text (never pipe to `jq`); `scripts/reply_to_review_thread.sh` requires the integer REST `databaseId` (never the `PRRC_...` node ID).
- **Full Mechanics Reference**: Load `@references/review-mechanics.md` for stale-ref races, blob-hash sweeps, duplicate sibling PR detection, stacked-base inspection, and shipped-dependency checks.

---

## 4. Conflict Resolution & Merging

- **Standalone PRs**: Sync by merging `origin/<base>` in an isolated worktree (`scripts/pr_sync_validate.sh`) — never `git rebase` or force-push standalone PR branches.
- **Stacked PRs**: Update via bottom-up cascading rebase (`--onto`) rather than merge commits. See `@references/stacked-epic-prs.md`.
- **Merging**: Prefer squash-merge (`scripts/pr_merge.sh` / `scripts/batch_merge.sh`) after CI passes and explicit user approval. Pass `--admin` only for ruleset-gated repos where the user has bypass privileges. Remote branch deletion requires separate explicit approval.

---

## 5. Bundled Script Toolkit (`scripts/`)

All scripts accept standardized `--repo <owner>/<repo>` flags (legacy `--owner <o> --repo <r>` also supported where noted). Run via `--help` without reading source code.

| Script | Invocation | Run When |
|---|---|---|
| `pr_preflight.sh` | `bash <skill-dir>/scripts/pr_preflight.sh --repo <owner/repo> --pr <n> [--expect-sha <sha>]` | Capturing PR diff + head ref in one fetch and checking for mid-audit head movement |
| `review_worktree.sh` | `bash <skill-dir>/scripts/review_worktree.sh add\|rm\|list\|exec --pr <n> [--role head\|base\|merge]` | Creating, running tests inside, or tearing down isolated throwaway audit worktrees |
| `prebundle_prs.sh` | `bash <skill-dir>/scripts/prebundle_prs.sh --repo <owner/repo> (--prs <list> \| --all-open)` | Pre-generating `/tmp/pr<N>/` audit bundles in parent session before parallel subagent reviews |
| `build_review_payload.py` | `python3 <skill-dir>/scripts/build_review_payload.py <spec.json> --out <payload.json> [--event ...]` | Converting a structured findings JSON spec into a REST review payload |
| `verify_review_anchors.sh` | `bash <skill-dir>/scripts/verify_review_anchors.sh --diff <pr.diff> --payload <payload.json> [--head <ref>]` | Hard-gating every inline `path`/`line` anchor against `+` lines in the diff before submission |
| `submit_review.sh` | `bash <skill-dir>/scripts/submit_review.sh --spec <spec.json> --repo <owner/repo> --pr <n> [--validate-only]` | Building, anchor-gating, and submitting a PR review from one consistent fetch |
| `reply_to_review_thread.sh` | `bash <skill-dir>/scripts/reply_to_review_thread.sh --repo <owner/repo> --pr <n> --comment-id <databaseId> --body "..."` | Posting a contextual reply to an unresolved PR review thread using its integer `databaseId` |
| `batch_disposition.sh` | `bash <skill-dir>/scripts/batch_disposition.sh --repo <owner/repo> [--approve ...] [--request-changes-dir ...] [--close ...] [--execute]` | Dry-running (default) or executing validated multi-PR review dispositions |
| `pr_sync_validate.sh` | `bash <skill-dir>/scripts/pr_sync_validate.sh <pr> --repo <owner/repo> [--push] [--cleanup]` | Merging base into a standalone PR branch in an isolated worktree, running `./validate.sh`, and pushing |
| `pr_merge.sh` | `bash <skill-dir>/scripts/pr_merge.sh <pr> --repo <owner/repo> [--admin] [--dry-run]` | Preflighting mergeability + CI checks and squash-merging a single approved PR |
| `batch_merge.sh` | `bash <skill-dir>/scripts/batch_merge.sh --repo <owner/repo> --prs <1,2,3> [--admin] [--dry-run]` | Preflighting and sequentially squash-merging multiple approved PRs |
