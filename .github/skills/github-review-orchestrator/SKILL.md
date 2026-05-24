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

### 3. Descriptive Feedback
Comments MUST NOT use 'caveman' style.
- Use **line-level comments** for specific code defects.
- Use **file-level comments** for architectural or broader file concerns.
- Format: Plain English. Describe the issue, explain the impact/why it is a problem, and suggest a concrete solution with examples where helpful.
- Be concise but descriptive.

### 4. Batch Submission
- Draft all findings before posting.
- Present the full list of comments to the user for approval.
- Submit the review as a single unit (e.g., using `gh api` or a JSON payload).

## Operations

| Operation | Description |
|-----------|-------------|
| **Orchestrate** | Run the full discovery -> inspection -> feedback loop. |

## Shared Resources

| Resource | Path | Purpose |
|----------|------|---------|
| Fetch Script | `scripts/fetch_file.sh` | Fetch remote PR files without checkout. |
