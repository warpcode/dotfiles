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
- For independent coverage, load `code-review` and `code-security-audit` before synthesizing findings; verify every proposed anchor against the PR diff.
- **Large-PR Delegation**: For diffs beyond ~500 lines or >5 files, skip loading those skills into the main context; instead launch two parallel `general` subagents (functional/conventions + security) with a shared evidence protocol: strictly read-only, head evidence via `git show origin/pr-<n>:<path>` (fetch first with `git fetch origin pull/<n>/head:refs/remotes/origin/pr-<n>`), never trust the dirty workspace tree, return findings as `SEVERITY | file:line | Description | Impact | Solution` plus an explicit verdict table (FIXED/PARTIAL/STILL PRESENT) for every unresolved review thread.
- **Semantic Merge & Base Drift**: Check whether package helpers or functions invoked by the PR branch had their signatures or contracts modified on the base branch (`main`) since the PR was branched. Git often marks additions textually mergeable even when function signatures conflict at compile time.
    - **Same-Path Both-Sides Add**: When the PR adds a new file, verify the path does not already exist on `main`: `git fetch origin pull/<pr>/head:refs/remotes/origin/pr-<pr>`, then `git merge-base origin/main origin/pr-<pr>` and `git ls-tree origin/main <path>`. GitHub's `changeType: ADDED` is merge-base-relative — a file added on **both** sides yields `mergeable: CONFLICTING` and duplicate top-level symbols (e.g. same `Test*` function names) that fail to compile if a resolution keeps both sides. Typical with bot PRs whose premise was already merged via an earlier PR — check whether `main` already covers the claimed gap before evaluating the diff.
    - **CI Absence Check**: `gh run list --repo <owner>/<repo> --branch <head-branch>` (empty = no workflow runs) and `gh api repos/<owner>/<repo>/commits/<sha>/check-suites` (surfaces app-based checks like CodeQL that mask a missing `CI` suite). Flag any "verified" claims in the PR body/commits as unconfirmed when lint/test never ran.
- **Requirements Tracing — field gotcha**: `gh pr view --json linkedIssues` is invalid; use `closingIssuesReferences` (plus `comments`/`body` text) to detect linked issues.
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
   - **Empty amendments**: Verify every commit pushed since the last review — an amendment with no file changes does not resolve prior feedback. Keep affected threads open and cite the failing check in the new review.
     ```bash
     git fetch origin pull/<pr>/head:refs/remotes/origin/pr-<pr>
     mb=$(git merge-base origin/<base> origin/pr-<pr>)
     for c in $(git rev-list --reverse origin/pr-<pr> ^$mb); do
       git diff --name-status "$c^" "$c" | grep -q . || echo "EMPTY: $(git log -1 --format='%h %ci' $c)"
     done
     ```
     Bot PRs routinely push sequences of empty commits after `CHANGES_REQUESTED`; do not credit them as fixes (observed on warpcode/dotfiles#122: 7 consecutive empty amendments, zero threads addressed).

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
  - Inline comment `line` must be an **added line in the diff** for `side: RIGHT`, measured as the 1-indexed line number in the **target file** in its post-change state (never the line offset within a saved `.diff` patch file). Anchoring to a context/unchanged line or using a `.diff` line number fails with `Line could not be resolved`. For new files any line in the file works; for modified files only `+` lines.
  - `path` must match the PR's diff path exactly.
  - **Pre-submit anchor verification**: confirm every comment `line` is a `+` line in the saved `.diff` before posting (skip the check for wholly-new files):
    ```bash
    awk '/^diff --git/{f=$3; sub("^a/","",f)} /^@@/{split($3,a,","); cur=substr(a[1],2)+0; next} /^\+\+\+|^\-\-\-/{next} /^\+/{if (f=="<path>" && cur==<line>) print "ADDED"; cur++; next} /^ /{cur++; next}' <pr>.diff
    ```
    > ⚠️ The `+` branch must compare `cur` **before** incrementing: after the `@@` header and context lines, `cur` holds the line number of the line currently being read, so `cur++` first shifts the test one line late (off-by-one, verified 2026-09-24).
    Note: `$3` on a `diff --git` header carries the `a/`-prefixed path — strip `a/` and compare without a `b/` prefix.
    Authoritative cross-check (works for new and modified files alike): `git show origin/pr-<pr>:<path> | grep -n "<anchor text>"` and compare the reported line number.
  - Write payload files directly with file-writing tools into the agent scratch directory (`scratch/review_payload.json`) instead of spawning Python scripts, avoiding execution gate blocks and quoting errors.
  - Redirect `gh api` output to a scratch file (e.g. `> scratch/out.json 2>&1`) — piping to `--jq`/`cat` can hang the terminal in the alternate buffer and the POST never completes. Avoid redirecting to root `/tmp/` to adhere to security hooks.

### 5. Memory Extraction (Automatic)
- **Immediately** after a review is submitted, activate the `ai-conversation-review` skill.
- Review the transcript to extract durable technical context, user corrections, or decisions made during the review into `~/.agents/AGENTS.md` and relevant skills.

## 🧠 Constraints
- **Strict Boundaries**: Do not audit PRs the user did not select.
- **No Base Branch Update Requests**: Never ask the PR author or bot to update, rebase, or sync the pull request branch with the main branch during reviews.
- **Non-Invasive**: Do not checkout branches or modify the workspace during the audit phase.
  - **No Workspace Testing**: Do not execute local test runners or build commands in the workspace during non-invasive audits, as they will run against the default branch rather than the PR branch.
- **Token Efficiency**: Use summarized outputs from tools unless raw output is strictly required for debugging.
