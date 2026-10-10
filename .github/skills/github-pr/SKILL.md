---
name: github-pr
description: >
  Workflow guidelines and standards for authoring, structuring, managing, and merging Pull Requests.
  Use when creating, updating, resolving conflicts in, or merging pull requests.
user-invocable: false
---

# Pull Request Workflows and Standards

This skill provides guidelines and procedures for authoring, structuring, managing, and merging GitHub Pull Requests.

> **Prerequisites:** This skill requires either the GitHub MCP server or the `gh` CLI to be available and authenticated. However, this file contains **ZERO** script or MCP direct references for usage. For execution, refer to the `github-cli` skill.

## 1. Base Branch & Safety Rules

- **Base Branch Rule**: NEVER infer or assume a base branch. Always ask the user if not explicitly provided. NEVER create a PR targeting `main` or `master` by default unless explicitly instructed.
- **Draft PR Policy**: ALWAYS create pull requests as drafts (`--draft`) first.
- **Explicit Approval Required**: Present the full proposed content (title, body, base/head branches, draft state) to the user for explicit approval before creating, publishing, or updating a PR. Obtain explicit confirmation before merging any PR.
- **Domain Separation**: Keep Git-specific commands and workspace logic (local branching, commits, diffs) logically separate from GitHub PR API management.

## 2. Title Formatting Standards

Choose the format based on context:
- **User provides a ticket/issue ID**: `[TICKET-ID] Summary` (e.g., `[PROJ-123] Add user authentication`)
- **Linked GitHub issue**: `[#42] Summary` (e.g., `[#42] Fix null pointer in search`)
- **Standard (no ticket)**: `type(scope): summary` (e.g., `feat(ui): add dark mode toggle`)
- **Draft with unclear scope**: `WIP: Summary` (e.g., `WIP: Explore caching strategies`)

**Rules for PR titles**:
- Use the imperative mood (e.g., "Add feature", "Fix bug", not "Added" or "Fixes").
- Keep under 70 characters.
- Capitalise the first letter of the summary.
- Avoid vague or generic titles (e.g., "Fix stuff", "Update code").

## 3. Body Content & Formatting

Use repository-specific PR templates if available (`.github/PULL_REQUEST_TEMPLATE.md` or `.github/PULL_REQUEST_TEMPLATE/*.md`). If none exist, use the fallback template at `@templates/pull_request.md`.

Ensure the body:
- Explains **what** changed and **why**.
- Links related issues or tickets (`Closes #number`, `Fixes #number`).
- Highlights specific areas needing reviewer attention.
- Includes testing notes and verification proof if behavior changed.

## 4. Author-Side Conflict Resolution

When resolving base branch merge conflicts on a PR branch as the PR author (using a local workspace):
1. Use an isolated git worktree in `/tmp/` to prevent main workspace contamination.
2. Fetch the remote branch and base branch.
3. Merge the base branch into the PR branch non-interactively (`git -c core.editor=true merge origin/<base>`).
4. Resolve conflicts while preserving both PR additions and base branch code.
5. Push the resolved branch using a standard `git push` (NEVER force-push `--force` or `--force-with-lease`).
6. Clean up the isolated worktree.

> ⚠️ **Jules-Owned PR Exception**: Jules exclusively owns changes to its PR branch. NEVER push Git/code changes or perform merges on a Jules-owned PR branch. If base-branch drift or conflicts become unmanageable on a Jules PR, start a new Jules session from the current PR branch and let Jules handle the subsequent changes.

## 5. Pull Request Merging Rules

- **Explicit User Confirmation**: Always obtain explicit user approval before executing a merge.
- **CI Requirement**: All GitHub Actions / CI checks MUST pass before merging.
- **Squash-Merge Preference**: Prefer squash-and-merge (`gh pr merge --squash`) for pull requests.
- **Ruleset-Gated PR Merges**: On repositories using active GitHub branch rulesets where the user has bypass privileges, if `gh pr merge --squash` fails due to base branch policy, supply `--admin` to bypass the ruleset gate once CI checks and approvals are satisfied.
- **Remote Branch Deletion**: Remote branch deletion is optional and separate. Delete a remote branch only after explicit user approval for that deletion.
