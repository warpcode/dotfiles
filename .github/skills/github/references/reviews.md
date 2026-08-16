# GitHub Review Orchestration

Orchestrate non-invasive code reviews: discovery, inspection, feedback
submission, and review-thread resolution. Read this file when reviewing PRs,
finding stale PRs, or providing formal review feedback.

## Workflow

### 1. Discovery & Selection

Unless a specific PR or branch is provided, always perform discovery:
- **Triage & Classification**: categorize all open PRs in a single batch:
  `${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --all`
  - Approved PRs: `${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --approved`
  - Ready for re-review (commits after review): `${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --commits-after-review`
  - Stalled / Waiting on author: `${SKILL_DIR}/scripts/find_prs.sh [owner] [repo] --waiting-on-author`
- **Review Thread Discovery**: batch-retrieve threads for all open PRs in one
  query (do NOT query PRs individually):
  `${SKILL_DIR}/scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]`
- **Efficiency Constraint**: ALWAYS use the default summary output. DO NOT use
  `--raw` unless explicitly instructed for debugging.
- Identify candidates by: age (oldest first), unanswered questions / pending
  comments, stale status (no updates > 1 hour after user response).
- **Batching Permission**: ALWAYS obtain explicit user permission before
  processing multiple PRs in one session. Users typically prefer one PR at a
  time. Only batch if the user explicitly requests "all", a specific list, or
  confirms the batching proposal.
  - **Similar PRs Exception**: PRs with identical scope (e.g., all adding tests
    to the same file from the same bot author) may be batched without per-PR
    permission if intent is clear (e.g., "do PRs 19-26").
- Present a curated candidate list and wait for explicit approval.

### 2. Non-Invasive Inspection

Perform the review without checking out branches or modifying the workspace:
- **Branch Truncation Warning**: Do not use branch names from `gh pr list` table
  columns — they may be truncated. Fetch the actual untruncated `headRefName`
  via `gh pr view <number> --json headRefName` or use the `HEAD_OID` when
  querying files.
- Retrieve head OID and diff: `${SKILL_DIR}/scripts/get_pr_context.sh <owner> <repo> <pr_number>`.
- Fetch full file contents if needed: `${SKILL_DIR}/scripts/fetch_file.sh <owner> <repo> <path> <branch>`.
- **Terminal Wrapping Awareness**: long lines in tool outputs can wrap and
  appear as duplicate/malformed lines. Verify with structured, line-numbered
  `grep` before assuming a syntax error.
- **Verification**: cross-reference the current diff against discovered review
  threads to identify resolution candidates.
- **CI / Checks Status**: verify with `gh pr checks <pr_number>`. If checks
  fail, fetch logs via `gh run list --repo <owner>/<repo> --branch <branch_name>`
  and `gh run view <run_id> --log-failed`. **Explicitly evaluate whether the
  failure is caused by the PR's code or is pre-existing repo/infra failure.**
- Verify findings locally if applicable, but never commit or change branch.
- **Merge Regression Check**: if the PR has a merge/rebase commit at its tip,
  diff changed files against their base-branch versions (e.g. `main`) to verify
  formatting, fixture whitespace, and trailing newlines weren't regressed.

### 3. Professional Feedback & Review Submission

- **Tone**: strictly neutral and formal. No encouraging/conversational summary,
  no "LGTM", no repetition, no emojis unless part of a defined convention.
- **Mandatory Complete Review Payload**: Standalone comments or direct
  command-line body passing are prohibited. ALWAYS prepare a complete valid JSON
  payload (event, main body, comments array), write it to a unique staging file
  in a writeable directory using the file-writing tool, and submit via
  `${SKILL_DIR}/scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>`.
  File-level comments are supported by omitting `line` or setting
  `subject_type: "file"`. **Post-submission, clean up all temp payloads, drafts,
  and diff files.**
- **Review Event Mapping**:
  - **Verification Gate**: BEFORE approving or merging, run
    `${SKILL_DIR}/scripts/pre_merge_checks.sh <pr_number>`.
  - **REQUEST_CHANGES**: one or more findings at Low/Medium/High severity.
  - **COMMENT**: replying to existing threads or no changes requested.
  - **APPROVE**: no findings, or all previously raised issues fully resolved.
- **Approval Constraint**: when approving, NEVER add NEW comments to files.
  Provide no summary if nothing new to add.
- **Replies**: only reply if needed (with user approval). Give a thumbs up (👍)
  ONLY if the developer replied that they fixed a requested change.
- **Resolution**: resolve threads only when the addressing change is verified.
  Use `${SKILL_DIR}/scripts/resolve_review_thread.sh <thread_id>`. If the developer asks a
  question, alert the user. If a finding is not fully resolved, post a reply
  comment instead of resolving.
- **Merge Conflict Resolution Reviews**: if the PR has conflicts, submit a
  review requesting changes and instruct the developer to rebase from the base
  branch properly — not copy changes across or overwrite files.
- **Format** per finding, per `${SKILL_DIR}/templates/github/review_comment.md`:
  1. Severity (High/Medium/Low), 2. Description, 3. Impact, 4. Proposed Solution.
- **Line-Comment Constraint**: line-level comments MUST be on lines within the
  current PR diff hunks (else GitHub returns HTTP 422).
- **Findings Outside Diff**: use the main review `body` or a file-level comment
  describing the issue with the line number and proposed fix.

## Procedures

### Review Thread Resolution
1. **Batch Discovery**: `${SKILL_DIR}/scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]`.
2. **Verification**: compare the current diff/files against the thread feedback.
3. **Strict Thread Closing**: resolve ONLY when the change is verified complete.
4. **Unfulfilled Threads**: DO NOT resolve; post a reply describing what remains.

### Merge Conflict Resolution (worktree)
1. `git fetch origin <branch_name>`
2. `git worktree add <path> origin/<branch_name>` (use `/tmp/` to avoid workspace pollution)
3. `cd <path> && git merge origin/main`
4. Resolve: keep both PR additions and main's existing code; for test files
   append the PR's new tests after main's.
5. `git push origin HEAD:<branch_name>`
6. `git worktree remove <path>`; remove leftover dirs after merge.

### Non-Invasive Review Orchestration
1. **Discovery**: batch fetch open PRs + threads.
2. **Mergeability**: `gh pr view <pr_number> --json mergeable,mergeStateStatus`.
3. **Selection**: present candidates, get approval (respect batching rules).
4. **Inspection**: `${SKILL_DIR}/scripts/get_pr_context.sh` + `${SKILL_DIR}/scripts/fetch_file.sh`.
5. **Testing Constraint**: do NOT run local test suites during non-invasive
   reviews — they run against the default branch, not the remote PR branch,
   producing misleading results.
6. **Audit**: read-only verification of fixes and regressions.
7. **Batching**: construct atomic JSON payloads; when submitting REQUEST_CHANGES
   always include inline comments on affected files so bots detect the changes.
8. **Submission**: single review event via `${SKILL_DIR}/scripts/submit_review.sh`.
