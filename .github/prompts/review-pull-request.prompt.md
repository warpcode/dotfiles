---
name: review-pull-request
description: "Master orchestrator for end-to-end GitHub pull request reviews. Manages discovery, audit, submission, and post-review memory extraction."
tools: [execute, read, agent, search, github/add_comment_to_pending_review, github/add_issue_comment, github/add_reply_to_pull_request_comment, github/create_branch, github/create_or_update_file, github/create_pull_request, github/delete_file, github/get_commit, github/get_file_contents, github/get_label, github/get_latest_release, github/get_me, github/get_release_by_tag, github/get_tag, github/get_team_members, github/get_teams, github/issue_read, github/issue_write, github/list_branches, github/list_commits, github/list_issue_fields, github/list_issue_types, github/list_issues, github/list_pull_requests, github/list_releases, github/list_repository_collaborators, github/list_tags, github/merge_pull_request, github/pull_request_read, github/pull_request_review_write, github/push_files, github/request_copilot_review, github/run_secret_scanning, github/search_code, github/search_commits, github/search_issues, github/search_pull_requests, github/search_repositories, github/search_users, github/sub_issue_write, github/update_pull_request, github/update_pull_request_branch]
agents: ['file-cleaner']
skills: ['ai-conversation-review']
user-invokable: true
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
- **File Lifecycle Check**: If any file is emptied, significantly reduced, or appears obsolete:
    - Invoke the `file-cleaner` subagent to audit its references.
    - Incorporate the subagent's recommendation into your final feedback.

### 3. Submission
- Draft a JSON review payload according to the `github-cli` review standards (Severity, Description, Impact, Solution).
- **Bot-authored PRs** (e.g. Jules): All findings MUST go into inline file-level `comments`. The top-level `body` must be a neutral one-liner only. Bots only act on inline comments, not the main review body.
- **Event**: Use `REQUEST_CHANGES` (user preference — never `COMMENT`).
- Present the full review to the user for approval.
- Write the payload to a scratch JSON file and submit via:
  ```
  gh api "repos/{owner}/{repo}/pulls/{pr}/reviews" --method POST --input <payload-file>
  ```
  > ⚠️ Do NOT use `submit_review.sh` — it is a broken symlink.
- **REST payload gotchas** (all verified 2026-08-29):
  - `subject_type` is GraphQL-only — OMIT it from REST review comments or the API returns 422 (`Field is not defined on DraftPullRequestReviewThread`).
  - Inline comment `line` must be an **added line in the diff** for `side: RIGHT`. Anchoring to a context/unchanged line fails with `Line could not be resolved`. For new files any line works; for modified files only `+` lines.
  - `path` must match the PR's diff path exactly (see Stale-PR Path Check above).
  - Redirect `gh api` output to a file (`> /tmp/out.json 2>&1`) — piping to `--jq`/`cat` can hang the terminal in the alternate buffer and the POST never completes.
  - Build payloads with a Python script (`json.dumps`) rather than hand-writing JSON — unescaped quotes inside comment bodies break parsing.

### 4. Memory Extraction (Automatic)
- **Immediately** after a review is submitted, activate the `ai-conversation-review` skill.
- Review the transcript to extract durable technical context, user corrections, or decisions made during the review into `~/.agents/AGENTS.md` and relevant skills.

## 🧠 Constraints
- **Strict Boundaries**: Do not audit PRs the user did not select.
- **Non-Invasive**: Do not checkout branches or modify the workspace during the audit phase.
  - **No Workspace Testing**: Do not execute local test runners or build commands in the workspace during non-invasive audits, as they will run against the default branch rather than the PR branch.
- **Token Efficiency**: Use summarized outputs from tools unless raw output is strictly required for debugging.
