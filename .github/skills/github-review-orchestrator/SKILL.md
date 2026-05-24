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
- **Review Thread Discovery**: Use `./scripts/fetch_all_pr_threads.sh` to retrieve all threads for active PRs in a single batch query. Do NOT query PRs individually.
- Identify candidates based on:
  - Age (oldest first).
  - Unanswered questions or pending review comments.
  - Stale status (no updates for > 1 hour after user response).
- Present a curated list of candidates to the user and wait for explicit approval.

### 2. Non-Invasive Inspection
Perform the review without checking out branches or modifying the workspace:
- Use the bundled `scripts/get_pr_context.sh` script to retrieve the head OID and diff context (e.g., `./scripts/get_pr_context.sh <owner> <repo> <pr_number>`).
- Use the bundled `scripts/fetch_file.sh` script to retrieve full file contents via API if needed for context (e.g., `./scripts/fetch_file.sh <owner> <repo> <path> <branch> <tmp_path>`).
- **Verification**: Cross-reference current diff against discovered review threads to identify candidates for resolution.
- Verify findings locally if applicable, but never commit or change branch.

### 3. Professional Feedback Standards
Comments MUST NOT use 'caveman' style.
- **Tone & Content**: Strictly neutral and formal. Avoid encouraging or conversational summaries; focus exclusively on specific technical findings or corrections. Never use "LGTM" or unnecessary affirmations. Do not repeat yourself.
- **Approval**: If approving a pull request, NEVER add NEW comments to files. Do not provide a summary if there is nothing new to add; just ask to approve.
- **Replies**: Only reply if needed (with user approval). Give a thumbs up (👍) ONLY if the developer replied saying they fixed a requested change.
- **Resolution**: Proactively resolve GitHub pull request review threads when the code changes addressing them have been verified. Use `scripts/resolve_review_thread.sh <thread_id>`. If the developer asks a question, alert the user for a response.
- **Format**: Use line-level comments for specific issues and file-level comments for file-wide concerns. If nothing is wrong, do not add any comments. Use plain English to describe the issue, explain why it is a problem, and suggest a potential solution.

### 4. Batch Submission
- Draft all findings before posting.
- Present the full list of comments to the user for approval.
- Submit the review using `scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>`.

## Operations

| Operation | Description |
|-----------|-------------|
| **Orchestrate** | Run the full discovery -> inspection -> feedback loop. |
| **Resolve Review Threads** | List and resolve addressed PR review threads using GraphQL. |

## Shared Resources

| Resource | Path | Purpose | Usage |
|----------|------|---------|-------|
| Fetch Script | `scripts/fetch_file.sh` | Fetch remote PR files without checkout. | `./scripts/fetch_file.sh <owner> <repo> <path> <branch> <tmp_path>` |
| Context Script | `scripts/get_pr_context.sh` | Fetch PR head OID and diff for review context. | `./scripts/get_pr_context.sh <owner> <repo> <pr_number>` |
| Submit Script | `scripts/submit_review.sh` | Submit atomic JSON reviews via API. | `./scripts/submit_review.sh <owner> <repo> <pr_number> <payload_file>` |
| Resolve Review Thread Script | `scripts/resolve_review_thread.sh` | Resolve GitHub PR review threads via GraphQL. | `./scripts/resolve_review_thread.sh <thread_id>` |
| Review Threads Query | `queries/review_threads.gql` | GraphQL query to list review threads and status. | `gh api graphql -F owner=<owner> -F repo=<repo> -F pr=<number> -f query=@queries/review_threads.gql` |
| Resolve Review Thread Query | `queries/resolve_review_thread.gql` | GraphQL mutation to resolve review threads. | Used internally by `resolve_review_thread.sh` |

