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
- Identify candidates based on:
  - Age (oldest first).
  - Unanswered questions or pending review comments.
  - Stale status (no updates for > 1 hour after user response).
- Present a curated list of candidates to the user and wait for explicit approval.

### 2. Non-Invasive Inspection
Perform the review without checking out branches or modifying the workspace:
- Remain on your current branch.
- Use `gh pr diff` to get the changes.
- Use the bundled `scripts/fetch_file.sh` script to retrieve full file contents via API if needed for context.
- Verify findings locally if applicable, but never commit or change branch.

### 3. Professional Feedback Standards
Comments MUST NOT use 'caveman' style.
- **Tone**: Short, professional, and to the point. Never use "LGTM" or unnecessary affirmations. Do not repeat yourself.
- **Approval**: If approving a pull request, NEVER add NEW comments to files. Do not provide a summary if there is nothing new to add; just ask to approve.
- **Replies**: Only reply if needed (with user approval). Give a thumbs up (👍) ONLY if the developer replied saying they fixed a requested change.
- **Interaction**: If no further questions or modifications are required, mark the thread as resolved. If the developer asks a question, alert the user for a response.
- **Format**: Use line-level comments for specific issues and file-level comments for file-wide concerns. If nothing is wrong, do not add any comments. Use plain English to describe the issue, explain why it is a problem, and suggest a potential solution.

### 4. Batch Submission
- Draft all findings before posting.
- Present the full list of comments to the user for approval.
- Submit the review using `scripts/submit_review.sh <number> <payload_file>`.

## Operations

| Operation | Description |
|-----------|-------------|
| **Orchestrate** | Run the full discovery -> inspection -> feedback loop. |

## Shared Resources

| Resource | Path | Purpose |
|----------|------|---------|
| Fetch Script | `scripts/fetch_file.sh` | Fetch remote PR files without checkout. |
. |
| Submit Script | `scripts/submit_review.sh` | Submit atomic JSON reviews via API. |
| Fetch Script | `scripts/fetch_file.sh` | Fetch remote PR files without checkout. |
