# GitHub Review Execution

Execution commands and scripts for review discovery, inspection, and thread resolution.

## 1. Discovery & Selection

- **Triage & Classification**: categorize all open PRs in a single batch:
  `bash @scripts/list_pull_requests.sh --all`
  - Approved PRs: `bash @scripts/list_pull_requests.sh --approved`
  - Ready for re-review (commits after review): `bash @scripts/list_pull_requests.sh --commits-after-review`
  - Stalled / Waiting on author: `bash @scripts/list_pull_requests.sh --waiting-on-author`

- **Review Thread Discovery**: retrieve review threads for a specific PR:
  ```bash
  # Standard auto-detected repo
  bash @scripts/list_pull_request_review_threads.sh --pull-number 42

  # Explicit repo overrides
  bash @scripts/list_pull_request_review_threads.sh --owner octocat --repo hello-world --pull-number 42
  ```
  The script's GraphQL query requests the first 100 threads and first 100 comments per thread. For complete review inventories, check `totalCount` against the returned node counts. Never report first-page counts as exhaustive.

---

## 2. Inspection

- **Gather PR Snapshot**: Collect full PR metadata, git diff, head files, and acceptance criteria in one call:
  `bash @scripts/pr_audit_bundle.sh --repo <owner/repo> --pr <n> --out /tmp/pr<n>`
- **CI / Checks Status**: verify with `gh pr checks <pr_number>`. If checks fail, fetch logs via `gh run view <run_id> --log-failed`.

---

## 3. Review Submission & Comments

- **Submit Review Comment / Approve (Silent Approval Invariant)**:
  *(Note: Never include "LGTM" or approval boilerplate. Approvals must have an empty body).*
  ```bash
  # Submit silent approval via gh CLI:
  gh pr review 42 --approve --body ""

  # Request changes via gh CLI:
  gh pr review 42 --request-changes --body-file review_summary.md

  # General review comment:
  gh pr review 42 --comment --body-file review_summary.md
  ```

- **Submit Structured Review Payload (Line & File Comments)**:
  ```bash
  # Submit structured payload with staged line/file comments via REST:
  bash @scripts/submit_pull_request_review_payload.sh --pr 42 --payload-file review_payload.json
  ```

---

## 4. Review Thread Resolution

Use the following script to resolve a PR review thread via GraphQL:
```bash
# Resolve a review thread
bash @scripts/update_pull_request_review_thread_resolution.sh --thread-id "<thread_id>"
```
After resolving threads, fetch a fresh thread inventory with `list_pull_request_review_threads.sh` to confirm resolution.

---

## 5. Atomically Submit Mixed-Type Reviews (GraphQL)

To submit a pull request review containing both line-level comments and file-level comments (e.g., comments on binary files or without specific line numbers), do NOT use the REST API reviews endpoint (which rejects `subject_type: file` with HTTP 422). Instead, use the GraphQL mutations workflow:
1. Create a pending review via `addPullRequestReview`.
2. Attach comments via `addPullRequestReviewThread` (using `subjectType: FILE` for file-level comments or `subjectType: LINE` for line comments).
3. Finalize and publish via `submitPullRequestReview`.

---

## 6. Mergeability

Check if a PR is mergeable:
```bash
gh pr view <pr_number> --json mergeable,mergeStateStatus
```
