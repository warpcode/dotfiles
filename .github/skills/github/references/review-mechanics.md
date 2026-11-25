# GitHub PR Review Mechanics & Platform Gotchas

Reference guide for GitHub PR diff isolation, REST inline comment anchoring, stale-ref races, GraphQL thread triage, and dependency verification.

---

## 1. REST Inline Comment Anchoring

- **Required Fields**: Use `side: "RIGHT"` with a 1-indexed line number in the **post-change target file** (never the line offset inside a `.diff` file).
- **Omit GraphQL-Only Fields**: Never include `subject_type` in REST review comment objects; GitHub returns HTTP 422 (`Field is not defined on DraftPullRequestReviewThread`).
- **Added Lines Only (`+` Lines)**: For modified files, REST line comments must anchor on `+` lines within a current PR diff hunk. Anchoring on context (` `) or deleted (`-`) lines fails with `Line could not be resolved` (HTTP 422).
- **Deleted Files**: Deleted files have no `+` (`side: RIGHT`) lines in diff hunks. Anchor findings on deleted paths onto a related modified file and name the deleted path in the comment body, or place them in the main review body.
- **Exact Diff Path**: `path` must match the PR's diff path verbatim (without `a/` or `b/` prefixes).
- **Hard Gate**: Always verify payloads with `scripts/verify_review_anchors.sh` rather than hand-parsing diff hunks. In unified diff parsing, `@@ -old,len +NEW,len @@` places the post-change start line in `$3`, and the `+` branch must test the current line number before incrementing.
- **Unresolved Anchor Diagnosis**: When `verify_review_anchors.sh --head <ref>` reports `could not be resolved against <ref>`, the diff and the head ref came from different fetches (or the file was renamed/deleted). Empty added lines are valid anchors; treat resolution errors as a cue to re-fetch via `pr_preflight.sh`, not to shift line numbers.

---

## 2. Stale-Ref & Moving-Head Races

- **Single-Fetch Consistency**: Capture the diff and head ref in one step so anchor verification cannot cross-check a fresh diff against an older local ref (or vice versa).
  - Use `scripts/pr_preflight.sh --repo <owner>/<repo> --pr <n> --expect-sha <sha>` to fetch `+refs/pull/<n>/head:refs/remotes/origin/pr-<n>` and capture `pr<n>.diff` together. Exit code `3` indicates the PR head moved since discovery; re-audit the new head before submitting.
  - Prefer `scripts/submit_review.sh --spec <findings.json> --repo <owner>/<repo> --pr <n>`, which performs a fresh single-fetch capture, builds the payload, runs the anchor gate, and submits atomically. Omit `--diff` and `--head` unless both were just captured together by `pr_preflight.sh`.
- **Fully Qualified Fetch Refspecs**: Always fetch PR heads with `+refs/pull/<n>/head:refs/remotes/origin/pr-<n>` (`--force`). A short destination like `origin/pr-<n>` creates a local branch `refs/heads/origin/pr-<n>`, causing ambiguous ref resolution once `refs/remotes/origin/pr-<n>` also exists.
- **Ephemeral Scratch Storage**: Never write review payloads or diffs to `./scratch/` inside the repository tree. Store in-flight artifacts in `/tmp/` or the conversation scratch directory, and treat them as non-durable: if an external cleanup removes cached files between validation and submission, re-fetch, rebuild, re-verify anchors, and submit.
- **Never Probe via `POST /reviews`**: There is no dry-run mode on `POST /repos/{o}/{r}/pulls/{n}/reviews`; even an empty probe creates a stray `PENDING` review. Validate payloads locally with `jq` or `submit_review.sh --validate-only`. Remove any stray `PENDING` review via:
  ```bash
  gh api --method DELETE repos/<owner>/<repo>/pulls/<n>/reviews/<review_id>
  gh api repos/<owner>/<repo>/pulls/<n>/reviews -q '.[] | select(.state=="PENDING") | .id'
  ```
- **Avoid Terminal Hang on `gh api`**: Redirect `gh api` output to a temporary file rather than piping directly when submitting large payloads.

---

## 3. Self-Authored PRs & Mixed-Type Reviews

- **Self-Authored PR Restriction**: GitHub rejects `REQUEST_CHANGES` and `APPROVE` on PRs authored by the authenticated user with HTTP 422 (`Review Can not request changes on your own pull request`). Use `event: "COMMENT"` when reviewing your own PR.
- **File-Level Comments (Mixed-Type Reviews)**: REST `POST .../reviews` rejects `subject_type: file`. To attach file-level comments alongside line-level comments (e.g., for binary files or unchanged lines), use GraphQL mutations: `addPullRequestReview` -> `addPullRequestReviewThread` (`subjectType: FILE` or `LINE`) -> `submitPullRequestReview`.

---

## 4. GraphQL Review Thread Triage

- **Pagination**: `list_pull_request_review_threads.sh` queries up to 100 threads and 100 comments per thread. Always reconcile returned counts against `totalCount` / the header summary (`Total Threads: N (X resolved, Y unresolved)`) before concluding a list is complete.
- **Plain-Text Output on Resolution**: `scripts/update_pull_request_review_thread_resolution.sh` invokes GraphQL `resolveReviewThread` and prints plain text (`Thread ID: <id> | Resolved: <bool>`), not JSON. Do not pipe its output to `jq`, which causes false-negative failures even though the resolution succeeded. Re-query `list_pull_request_review_threads.sh` to verify final state.
- **Reply ID Types**: `scripts/reply_to_review_thread.sh` requires the integer REST `databaseId` (shown in thread listings), never the GraphQL node ID (`PRRC_...`).
- **Thread Triage Hygiene**: Resolve outdated threads only after verifying the fix in the current head blob. Never credit empty commits or unverified commit-message/reply claims as fixes; inspect `git diff <prev>..<head>` and `git show origin/pr-<n>:<path>` directly.

---

## 5. Diff Isolation, Branch Drift & Dependency Checks

- **Dynamic Base Branch**: Never hardcode `main` or `master` during audits. Query `baseRefName` dynamically from PR metadata (`gh pr view <n> --repo <owner>/<repo> --json baseRefName`).
- **Blob-Hash Sweep**: `gh pr diff` is merge-base-relative and can include files already landed on the base branch. Compare blob hashes between `origin/<base>:<path>` and `origin/pr-<n>:<path>` to isolate genuinely modified files and detect self-reverting refactors (where an intermediate commit refactors a file and a later commit reverts it back to the base blob).
- **Duplicate Sibling PRs**: Check for competing open PRs touching the same files before line-by-line review using `git-expert/scripts/audit_repo_branches.py --repo <owner>/<repo> --fetch`. Re-run conflict checks (`git merge-tree`) after any PR amendment, as conflict counts can drop or grow.
- **Same-Path Both-Sides Additions**: Verify newly added files do not already exist on the base branch (`git ls-tree origin/<base> <path>`). Merge-base-relative `ADDED` status hides duplicate-file collisions until merge time.
- **Linked Issues & Shipped Dependencies**:
  - `gh pr view --json linkedIssues` is invalid; query `closingIssuesReferences` plus PR body/comments.
  - A dependency issue in `CLOSED` state is not proof the dependency shipped (it may have been closed without a merged PR). Confirm a merged PR in `closedByPullRequestsReferences` or verify the required symbols exist on the base branch.
- **Stacked PRs on Unmerged or Closed Bases**: When `baseRefName` is not the repository default branch, `gh pr diff` shows only the incremental delta over that base. Always inspect the base PR's state and `git diff --stat origin/<default> origin/pr-<n>` to verify the full shipping delta.
