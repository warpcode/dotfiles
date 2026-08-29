---
name: github
description: >
  Workflow guidelines and standards for GitHub: PR readiness, review orchestration,
  issue/PR formatting, and triage standards. Use when reviewing PRs or defining conventions.
  Requires either the GitHub MCP server or the `gh` CLI to be available, but
  does not provide direct execution commands (use the github-cli skill for execution).
user-invocable: false
---

# GitHub Workflows and Procedures

This skill provides guidelines and procedures for managing GitHub issues, pull requests, and code reviews. 

> **Prerequisites:** This skill requires either the GitHub MCP server or the `gh` CLI to be available and authenticated. However, this file contains **ZERO** script or MCP direct references for usage. For execution, refer to the `github-cli` skill.

## 1. Safety and Explicit Consent

- **Never Assume or Infer**: Never infer a base branch. Always ask the user if not provided. Never create a PR from `main`/`master`.
- **Always Draft First**: Always create pull requests as drafts.
- **Explicit Approval Required**: Present the full content to the user for explicit approval before creating/updating an issue, creating/publishing a PR, submitting a review, or merging a PR, regardless of whether verification was successful.
- **Batching Permission**: ALWAYS obtain explicit user permission before processing multiple PRs in one session. Only batch if the user explicitly requests "all", a specific list, or confirms the batching proposal.
- **Review Boundaries**: When discovering multiple PRs, strictly limit auditing and commentary to the specific PR(s) selected by the user. Do not proactively audit other candidates in the same turn or session unless explicitly requested.
- **Domain Separation**: Keep Git-specific commands and logic (e.g. local branching, commits, diffs) logically separate from GitHub API integrations (e.g. issues, pull requests, reviews).

## 2. Issues

### Gathering Context
- Resolve the target repository (explicitly provided, current directory, or ask).
- Check for existing templates (`.github/ISSUE_TEMPLATE/*.md`, `.github/ISSUE_TEMPLATE.md`).
- If templates exist, structure the issue body to match the template.

### Structuring Content
- If no repository templates exist, use the fallback templates located in the `${SKILL_DIR}/templates/` directory:
  - `${SKILL_DIR}/templates/bug_report.md`
  - `${SKILL_DIR}/templates/feature_request.md`
  - `${SKILL_DIR}/templates/task_chore.md`
  - `${SKILL_DIR}/templates/question_discussion.md`
  - `${SKILL_DIR}/templates/security_vulnerability.md`
- Adapt the template and drop sections that do not apply. The user's input is the source of truth.
- When updating, be surgical — only modify the parts the user explicitly asked to change.

## 3. Pull Requests

### Title Formatting
Choose the format based on context:
- User provides a ticket/issue ID: `[TICKET-ID] Summary` (e.g. `[PROJ-123] Add user authentication`)
- Linked GitHub issue: `[#42] Summary` (e.g. `[#42] Fix null pointer in search`)
- Standard (no ticket): `type(scope): summary` (e.g. `feat(ui): add dark mode toggle`)
- Draft with unclear scope: `WIP: Summary` (e.g. `WIP: Explore caching strategies`)

Rules for PR titles: Use imperative mood, keep under 70 characters, capitalise the first letter of the summary, avoid vague titles.

### Body Content
Use the PR template (repo-specific or fallback `${SKILL_DIR}/templates/pull_request.md`). Ensure it explains *what* changed and *why*, links related issues (`Closes #number`), highlights areas needing reviewer attention, and includes testing notes if behaviour changed.

## 4. Code Review Orchestration

### Review Tone & Style
- **Tone**: Strictly neutral, fact-based, and formal. Do not include encouraging adjectives, subjective evaluations, or conversational filler (e.g., "looks excellent", "successfully", "elegantly", "LGTM").
- **Format**: For each finding use the structure: 1. Severity (High/Medium/Low), 2. Description, 3. Impact, 4. Proposed Solution. Refer to `${SKILL_DIR}/templates/pull_request_review_comment.md` for formatting details.

### Review Events
- **REQUEST_CHANGES**: Use when there is one or more findings at Low/Medium/High severity, or if unresolved merge conflicts exist.
- **COMMENT**: Use for replying to existing threads or if no changes are requested.
- **APPROVE**: Use when there are no findings, or all previously raised issues are fully resolved. When approving, NEVER add NEW comments to files. Provide no summary if there is nothing new to add.

### Review Orchestration & Phase Separation
- **Formal Review Harness**: Formal pull request reviews SHOULD be performed where available to ensure end-to-end audit, specialized subagents, and memory extraction.
- **Code Review Phase Separation**: During active PR review workflows, treat any user architectural ideas, cleanup requests, or file removal proposals as requested review comments to be submitted to GitHub. Do NOT checkout the branch or perform local workspace edits unless the user explicitly commands a local change or workspace modification.
- **Inline Comments Required for Bot-Authored PRs**: When reviewing PRs authored by automated bots (e.g., Jules), all findings MUST be submitted as inline file comments on specific lines, not in the main review body. Bot authors respond to inline comments; findings in the review body alone are ignored. The main review body should be a neutral, brief summary only.
- **Conflict Commenting**: When requesting changes due to merge conflicts or general findings, always add corresponding inline comments directly to the affected files in the review payload to ensure external integrations and bots detect the changes required.

### Review Thread Resolution
- Compare the current diff/files against the thread feedback.
- Strict Thread Closing: Resolve ONLY when the change is verified as complete.
- Unfulfilled Threads: DO NOT resolve; post a reply describing what remains outstanding.

### General Review Guidelines
- **Branch Dynamism**: PR review scripts MUST NOT hardcode default branch names (e.g. `origin/master` or `master`). Instead, query the PR metadata dynamically to determine the target base branch.
- **Merge Regression Check**: If the PR has a merge/rebase commit at its tip, diff changed files against their base-branch versions to verify formatting, fixture whitespace, and trailing newlines weren't regressed.
- **Line-Comment Constraint**: Line-level comments MUST be on lines within the current PR diff hunks.
- **Findings Outside Diff**: Use the main review body or a file-level comment describing the issue with the line number and proposed fix.

## 5. Merge Conflict Resolution & PR Merging

### Merge Conflicts
If resolving merge conflicts via a local workspace, use a git worktree:
1. Fetch the remote branch.
2. Add a worktree in a temporary directory (`/tmp/` to avoid workspace pollution).
3. Merge the base branch (e.g., `main`).
4. Resolve conflicts: keep both PR additions and main's existing code. For test files, append the PR's new tests after main's.
5. Push the resolved branch back to the remote.
6. Remove the worktree.
If you are reviewing a PR with conflicts instead of resolving them yourself, submit a review requesting changes (`REQUEST_CHANGES`) and instruct the developer to rebase properly — not copy changes across or overwrite files.

### Merging Pull Requests
- Always obtain explicit user confirmation before merging a pull request.
- All GitHub Actions / CI checks MUST pass before merging.
- Prefer squash-and-merge for pull requests.
- Remote branches MUST be deleted immediately after merging.
- Before approving or merging any PR, always check if there are pre-merge checks to run.
