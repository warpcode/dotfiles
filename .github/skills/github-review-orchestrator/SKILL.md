---
name: github-review-orchestrator
description: Orchestrate non-invasive code reviews with a user-centric selection process and descriptive feedback standards. Use this skill whenever the user asks to review pull requests (PRs), find stale PRs, or needs to provide high-quality code review comments on GitHub. It ensures you remain on the current branch without checking out remote code, using 'gh' CLI for all inspections.
---

# GitHub Review Orchestrator

Orchestrate non-invasive code reviews with a user-centric selection process and descriptive feedback standards.

## Workflow

### 1. Discovery & Selection
Unless a specific PR or branch is provided by the user, always perform a discovery phase:
- List open PRs with `gh pr list`.
- **Review Thread Discovery**: Use `./scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]` to retrieve all threads for active PRs in a single batch query. Do NOT query PRs individually. Example: `./scripts/fetch_all_pr_threads.sh warpcode dotfiles 10 ASC`.
- **Efficiency Constraint**: ALWAYS use the default summary output. DO NOT use the `--raw` flag unless specifically instructed for debugging.
- Identify candidates based on:
  - Age (oldest first).
  - Unanswered questions or pending review comments.
  - Stale status (no updates for > 1 hour after user response).
- **Batching Permission**: ALWAYS obtain explicit user permission before processing multiple pull requests in a single review session. Users typically prefer reviewing one PR at a time for focus. Only batch if the user explicitly requests "all", a specific list, or confirms the batching proposal.
- Present a curated list of candidates to the user and wait for explicit approval.

### 2. Non-Invasive Inspection
Perform the review without checking out branches or modifying the workspace:
- **Branch Truncation Warning**: Do not use the branch name directly from the `gh pr list` table columns, as it may be truncated. Fetch the actual untruncated `headRefName` via `gh pr view <number> --json headRefName` or use the `HEAD_OID` when querying files.
- Use the bundled `scripts/get_pr_context.sh` script to retrieve the head OID and diff context (e.g., `./scripts/get_pr_context.sh <owner> <repo> <pr_number>`).
- Use the bundled `scripts/fetch_file.sh` script to retrieve full file contents via API if needed for context (e.g., `./scripts/fetch_file.sh <owner> <repo> <path> <branch>`).
- **Terminal Wrapping Awareness**: Long lines in tool outputs (e.g., from `fetch_file.sh` or `gh pr diff`) can wrap in the display and appear as multiple duplicate or malformed lines. Always verify using a structured, line-numbered `grep` or inspect the lines directly with their line-numbers before assuming a syntax error or duplicate line exists.
- **Verification**: Cross-reference current diff against discovered review threads to identify candidates for resolution.

- Verify findings locally if applicable, but never commit or change branch.

### 3. Professional Feedback & Review Submission Standards
Comments MUST NOT use 'caveman' style.
- **Tone & Content**: Strictly neutral and formal. Avoid encouraging or conversational summaries; focus exclusively on specific technical findings or corrections. Never use "LGTM" or unnecessary affirmations. Do not repeat yourself.
- **Mandatory Complete Review Payload**: Standalone comments or direct command-line body passing are strictly prohibited. A complete, valid JSON review payload containing the event type (`COMMENT`, `APPROVE`, or `REQUEST_CHANGES`), the main review body, and the array of inline comments (if any) MUST always be prepared, written to a staging file (e.g. `/home/jase/.gemini/antigravity-ide/scratch/review_payload.json`) using `write_to_file`, and submitted via `scripts/submit_review.sh`. **Post-submission, clean up all temporary staging payloads, review drafts, and diff files to prevent stale state retention.**
- **Review Event Mapping**: Explicitly audit and map the review event depending on the severity of the findings:
  - **REQUEST_CHANGES**: Use if one or more findings are marked as **Medium** or **High** severity.
  - **COMMENT**: Use if findings are exclusively **Low** severity (style, non-blocking optimizations) or when replying to existing threads.
  - **APPROVE**: Use only when no findings exist or all previously raised issues have been fully resolved.
- **Approval Constraints**: If approving a pull request, NEVER add NEW comments to files. Do not provide a summary if there is nothing new to add; just ask to approve.
- **Replies**: Only reply if needed (with user approval). Give a thumbs up (👍) ONLY if the developer replied saying they fixed a requested change.
- **Resolution**: Proactively resolve GitHub pull request review threads when the code changes addressing them have been verified. Use `scripts/resolve_review_thread.sh <thread_id>`. If the developer asks a question, alert the user for a response.
- **Format**: For each technical finding, use line-level comments structured according to the `templates/github/review_comment.md` template, which includes:
  1. **Severity**: High, Medium, or Low (written in words).
  2. **Description**: Clear explanation of the issue.
  3. **Impact**: Why this is a problem for the codebase (security, performance, stability).
  4. **Proposed Solution**: Technical fix with a code example if it clarifies the implementation.
- **Batching**: Use line-level comments for specific issues and file-level concerns. If nothing is wrong, do not add any comments.
- **Review Constraint**: Line-level comments MUST be placed on lines that are part of the current PR diff (within hunks). Attempting to comment on lines outside the diff will result in an HTTP 422 error from the GitHub API.
- **Handling Findings Outside Diff**:
    - If a finding is in a line NOT modified/added by the PR (outside the diff hunk), DO NOT use a line-level comment.
    - Instead, use the main review `body` or a file-level comment to describe the issue, citing the line number and providing the proposed solution in the text.

## Operations

| Operation | Description |
|-----------|-------------|
| **Orchestrate** | Run the full discovery -> inspection -> feedback loop. |
| **Resolve Review Threads** | List and resolve addressed PR review threads using GraphQL. |

## Shared Resources

| Resource | Path | Purpose | Usage |
|----------|------|---------|-------|
| Fetch Script | `scripts/fetch_file.sh` | Fetch remote PR files without checkout. | `./scripts/fetch_file.sh <owner> <repo> <path> <branch>` |
| Fetch Threads Script | `scripts/fetch_all_pr_threads.sh` | Batch retrieve active review threads for all open PRs. | `./scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]` |
| Context Script | `scripts/get_pr_context.sh` | Fetch PR head OID and diff for review context. | `./scripts/get_pr_context.sh <owner> <repo> <pr_number>` |
| Submit Script | `scripts/submit_review.sh` | Submit atomic JSON reviews via API. | `./scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>` |
| Resolve Review Thread Script | `scripts/resolve_review_thread.sh` | Resolve GitHub PR review threads via GraphQL. | `./scripts/resolve_review_thread.sh <thread_id>` |
| Pre-merge Checks Script | `scripts/pre_merge_checks.sh` | Validate syntax, interactive safety, scope hygiene, and regression constraints. | `./scripts/pre_merge_checks.sh <pr_number>` |
| Review Threads Query | `queries/review_threads.gql` | GraphQL query to list review threads and status. | `gh api graphql -F owner=<owner> -F repo=<repo> -F pr=<number> -f query=@queries/review_threads.gql` |
| Resolve Review Thread Query | `queries/resolve_review_thread.gql` | GraphQL mutation to resolve review threads. | Used internally by `resolve_review_thread.sh` |

## Procedures

### Review Thread Resolution
Use this procedure to close addressed feedback loops:
1. **Batch Discovery**: Use `scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]` to identify threads across all open PRs.
2. **Verification**: Compare the current diff/files against the feedback in the thread.
3. **Resolution**: Use `scripts/resolve_review_thread.sh <thread_id>` once the fix is verified in the remote branch.

### Non-Invasive Review Orchestration
Use this procedure to audit pull requests without workspace mutation:
1. **Discovery**: Batch fetch all open PRs and active review threads using `scripts/fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]`.
2. **Selection**: Present candidates and get user approval (respecting the Batching Permission rule).
3. **Inspection**: Use `get_pr_context.sh` and `fetch_file.sh` to retrieve diffs and full file context for the target PR(s).
4. **Audit**: Perform read-only verification of fixes and identify regressions against local files fetched to temporary paths.
5. **Architectural Audit**: If files are emptied or renamed:
    - Identify target files in the diff.
    - Perform a global `grep_search` for the file names and common command aliases.
    - Verify if call sites expect logic that has been removed.
    - Cross-reference with project-specific environment generation scripts.
6. **Batching**: Construct atomic JSON review payloads using `templates/github/review_comment.md`.
7. **Submission**: Submit as a single review event (COMMENT, APPROVE, or REQUEST_CHANGES) via `submit_review.sh`.


