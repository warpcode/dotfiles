---
name: review-pull-request
description: Master orchestrator for end-to-end GitHub pull request reviews (discovery, audit, submission, and post-review memory extraction).
---

# PR Review Orchestrator

Master orchestrator for pull request reviews. You are responsible for the entire review lifecycle, delegating specialized audits to subagents and ensuring project memories are updated after every review.

## 🚀 Lifecycle Procedure

### 1. Discovery & Selection
- Activate the `github-cli` skill (reviews + pull-requests references).
- Perform discovery of open PRs and active threads.
- Present candidates to the user and obtain explicit selection for a single PR (strictly follow the **Review Boundaries** mandate in `AGENTS.md`).

### 2. Contextual Audit
- Use `gh pr view <pr> --repo <owner>/<repo> --json <fields>` and `gh pr diff <pr> --repo <owner>/<repo>` to retrieve the PR state without checking out the branch.
- **Requirements Tracing**: If the PR mentions or is linked to a parent issue:
    - Retrieve the parent issue's context, description, and acceptance criteria (AC).
    - Verify if the PR implementation aligns with the stated AC.
    - Check for any incomplete subtasks or related issues that might impact the review.
- Analyze the diff for functional correctness, security, and conventions.
- **Semantic Merge & Base Drift**: Check whether package helpers or functions invoked by the PR branch had their signatures or contracts modified on the base branch (`main`) since the PR was branched. Git often marks additions textually mergeable even when function signatures conflict at compile time.
- **File Lifecycle Check**: If any file is emptied, significantly reduced, or appears obsolete:
    - Invoke the `file-cleaner` subagent to audit its references.
    - Incorporate the subagent's recommendation into your final feedback.

### 3. Outdated Review Thread Triage (Bot-Authored PRs)
When reviewing a bot-authored PR (e.g. Jules) where amendment commits were pushed after a prior review:
1. Retrieve review threads:
   ```bash
   bash <skills-dir>/github-cli/scripts/list_pull_request_review_threads.sh --owner <owner> --repo <repo> --pull-number <pr>
   ```
2. For each **unresolved + outdated** thread:
   - **Completed & Verified**: Resolve directly via GraphQL without adding noise comments:
     ```bash
     bash <skills-dir>/github-cli/scripts/update_pull_request_review_thread_resolution.sh --thread-id "<thread_id>"
     ```
   - **Uncompleted or Broken**: Bump the thread with a contextual reply using the initial comment's REST integer `databaseId`:
     ```bash
     bash <skills-dir>/github-cli/scripts/add_reply_to_pull_request_comment.sh --owner <owner> --repo <repo> --pull-number <pr> --comment-id <databaseId> --body "..."
     ```
   > ⚠️ **Key Invariant**: `--comment-id` in `add_reply_to_pull_request_comment.sh` requires an **integer REST `databaseId`** (surfaced in `list_pull_request_review_threads.sh` output), NOT the GraphQL node `id` string (such as `PRRC_...`).

### 4. Submission
- Draft a JSON review payload according to the `github-cli` review standards (Severity, Description, Impact, Solution).
- **Bot-authored PRs** (e.g. Jules): 
  - `APPROVE`: Submit with empty body, no inline comments.
  - `REQUEST_CHANGES`: Neutral one-liner body + inline file-level `comments` with findings. Bots only act on inline comments.
- **Verify before submit**: Confirm event matches findings — *no blocking issues → APPROVE; blocking issues exist → REQUEST_CHANGES*.
- Present the full review to the user for approval.
- Write the payload to a scratch JSON file and submit via:
  ```bash
  bash <skills-dir>/github-cli/scripts/submit_pull_request_review_payload.sh --owner <owner> --repo <repo> --pull-number <pr> --input <payload-file>
  ```
  > ⚠️ Note: `create_pull_request_review.sh` in `github-cli` only supports top-level review bodies. For structured reviews with inline line/file comments, use `submit_pull_request_review_payload.sh` as shown above.
- **REST payload gotchas** (all verified 2026-08-29):
  - `subject_type` is GraphQL-only — OMIT it from REST review comments or the API returns 422 (`Field is not defined on DraftPullRequestReviewThread`).
  - Inline comment `line` must be an **added line in the diff** for `side: RIGHT`. Anchoring to a context/unchanged line fails with `Line could not be resolved`. For new files any line works; for modified files only `+` lines.
  - `path` must match the PR's diff path exactly.
  - Redirect `gh api` output to a file (`> /tmp/out.json 2>&1`) — piping to `--jq`/`cat` can hang the terminal in the alternate buffer and the POST never completes.
  - Build payloads with a Python script (`json.dumps`) rather than hand-writing JSON — unescaped quotes inside comment bodies break parsing.

### 5. Memory Extraction (Automatic)
- **Immediately** after a review is submitted, activate the `ai-conversation-review` skill.
- Review the transcript to extract durable technical context, user corrections, or decisions made during the review into `~/.agents/AGENTS.md` and relevant skills.

## 🧠 Constraints
- **Strict Boundaries**: Do not audit PRs the user did not select.
- **No Base Branch Update Requests**: Never ask the PR author or bot to update, rebase, or sync the pull request branch with the main branch during reviews.
- **Non-Invasive**: Do not checkout branches or modify the workspace during the audit phase.
  - **No Workspace Testing**: Do not execute local test runners or build commands in the workspace during non-invasive audits, as they will run against the default branch rather than the PR branch.
- **Token Efficiency**: Use summarized outputs from tools unless raw output is strictly required for debugging.
