# GitHub Review Execution

Execution commands and scripts for review discovery, inspection, and thread resolution.

## 1. Discovery & Selection

- **Triage & Classification**: categorize all open PRs in a single batch:
  `bash ${SKILL_DIR}/scripts/list_pull_requests.sh --all`
  - Approved PRs: `bash ${SKILL_DIR}/scripts/list_pull_requests.sh --approved`
  - Ready for re-review (commits after review): `bash ${SKILL_DIR}/scripts/list_pull_requests.sh --commits-after-review`
  - Stalled / Waiting on author: `bash ${SKILL_DIR}/scripts/list_pull_requests.sh --waiting-on-author`
- **Review Thread Discovery**: retrieve review threads for a specific PR:
  ```bash
  # Standard auto-detected repo
  bash ${SKILL_DIR}/scripts/list_pull_request_review_threads.sh --pull-number 42

  # Explicit repo overrides
  bash ${SKILL_DIR}/scripts/list_pull_request_review_threads.sh --owner octocat --repo hello-world --pull-number 42
  ```

## 2. Inspection

- Retrieve PR state (summary table, comments, reviews, threads, readiness): 
  `bash ${SKILL_DIR}/scripts/get_pull_request.sh --pull-number <pr_number>`
  *(or with explicit overrides: `bash ${SKILL_DIR}/scripts/get_pull_request.sh --owner <owner> --repo <repo> --pull-number <pr_number>`)*
- Fetch full file contents if needed: 
  `bash ${SKILL_DIR}/scripts/get_file_contents.sh --owner <owner> --repo <repo> --path <path> --branch <branch>`
- **CI / Checks Status**: verify with `gh pr checks <pr_number>`. If checks
  fail, fetch logs via `gh run list --repo <owner>/<repo> --branch <branch_name>`
  and `gh run view <run_id> --log-failed`.

## 3. Review Submission & Comments

- **Verification Gate**: BEFORE approving or merging, check PR state and merge readiness checks:
  ```bash
  bash ${SKILL_DIR}/scripts/get_pull_request.sh --pull-number <pr_number>
  ```

- **Submit Review Comment (Default / Auto-detected Repo)**:
  ```bash
  bash ${SKILL_DIR}/scripts/create_pull_request_review.sh --pull-number 42 --body "LGTM with minor suggestions."
  ```

- **Submit Approval Review (with optional `--approve` flag)**:
  ```bash
  bash ${SKILL_DIR}/scripts/create_pull_request_review.sh --pull-number 42 --body "Approved! Verified locally." --approve true
  ```

- **Submit Review on Cross-Repository (with optional `--owner` and `--repo` overrides)**:
  ```bash
  bash ${SKILL_DIR}/scripts/create_pull_request_review.sh --owner octocat --repo hello-world --pull-number 10 --body "Ready to merge" --approve true
  ```

- **Add Comment to Pending Review**:
  ```bash
  # Standard auto-detected repo
  bash ${SKILL_DIR}/scripts/add_comment_to_pending_review.sh --pull-number 42 --review-id "PRR_kwDOA123" --body "Please check this line."

  # Explicit repo override
  bash ${SKILL_DIR}/scripts/add_comment_to_pending_review.sh --owner octocat --repo hello-world --pull-number 10 --review-id "PRR_kwDOA123" --body "Please check this line."
  ```

- **Reply to Specific Review Comment**:
  ```bash
  # Standard auto-detected repo
  bash ${SKILL_DIR}/scripts/add_reply_to_pull_request_comment.sh --pull-number 42 --comment-id 987654321 --body "Fixed in latest commit."

  # Explicit repo override
  bash ${SKILL_DIR}/scripts/add_reply_to_pull_request_comment.sh --owner octocat --repo hello-world --pull-number 10 --comment-id 987654321 --body "Fixed in latest commit."
  ```

## 4. Review Thread Resolution

Use the following script to resolve a PR review thread via GraphQL:
```bash
# Resolve a review thread
bash ${SKILL_DIR}/scripts/update_pull_request_review_thread_resolution.sh --thread-id "<thread_id>"
```

## 5. Mergeability

Check if a PR is mergeable:
`gh pr view <pr_number> --json mergeable,mergeStateStatus`
