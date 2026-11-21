---
name: github-pr
description: >
  Workflow guidelines and standards for authoring, structuring, managing, and merging Pull Requests and Stacked Pull Requests.
  Use when creating, updating, resolving conflicts in, or merging standalone or stacked pull requests.
user-invocable: false
---

# Pull Request Workflows and Standards

This skill provides guidelines and procedures for authoring, structuring, managing, and merging GitHub Pull Requests.

> **Prerequisites:** This skill requires either the GitHub MCP server or the `gh` CLI to be available and authenticated. However, this file contains **ZERO** script or MCP direct references for usage. For execution, refer to the `github-cli` skill.

## 1. Base Branch & Safety Rules

- **Base Branch Rule**: NEVER infer or assume a base branch. Always ask the user if not explicitly provided. NEVER create a PR targeting `main` or `master` by default unless explicitly instructed.
- **New Branch Origin & Check**:
  - **Standalone PRs**: Always create new branches from `origin/<default-branch>` (e.g., `origin/master` or `origin/main`), never from whatever unrelated branch happens to be checked out. Run `git-expert/scripts/branch_base_check.sh` before opening a PR.
  - **Stacked PRs**: A stack is an ordered linear chain of branches `(trunk) <- layer-1 <- layer-2 <- ... <- layer-N`. The bottom layer branches from the trunk (`origin/<default-branch>` or an explicitly approved epic base branch), and each subsequent layer branches from the layer immediately below it so reviewers see only that layer's incremental diff.
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
- For **stacked PRs**, clearly states the layer's position and purpose within the stack/epic and links the parent PR or overarching epic issue.
- Highlights specific areas needing reviewer attention.
- Includes testing notes and verification proof if behavior changed.

## 4. Author-Side Conflict Resolution

### Standalone (Unstacked) PRs
When resolving base branch merge conflicts on a standalone PR branch as the PR author (using a local workspace):
1. Use an isolated git worktree in `/tmp/` to prevent main workspace contamination.
2. Fetch the remote branch and base branch.
3. Merge the base branch into the PR branch non-interactively (`git -c core.editor=true merge origin/<base>`).
4. Resolve conflicts while preserving both PR additions and base branch code.
5. Push the resolved branch using a standard `git push` (NEVER force-push `--force` or `--force-with-lease`).
6. Clean up the isolated worktree.

Bundled helper: `bash <skill-dir>/scripts/pr_sync_validate.sh <pr> --repo <owner/repo> [--dry-run] [--push] [--cleanup]` performs steps 1-3, validation (`./validate.sh`) and the push in one call. It exits `2` and lists the conflicted files when conflicts occur; after resolving and `git add`-ing them, re-run with `--continue`. When finishing a conflicted merge by hand, use `GIT_EDITOR=true git merge --continue`, never `git commit -m` (it failed at event #90 of session 4ff115e0). Do not open the script source; `--help` documents every flag.

### Stacked PRs
Stacked pull requests rely on **rebasing rather than merge commits** to update branches. Merging upstream changes into a stacked branch creates merge-commit knots and pollutes diffs in higher layers. Instead, replay the commits from each head branch on top of the latest base in bottom-to-top order:
1. Check out the stack of branches locally (preferring an isolated worktree if the main workspace has active uncommitted work).
2. Perform a cascading rebase across the stack from the updated base/trunk upward so each layer replays cleanly onto the tip of the layer immediately below it.
3. If conflicts occur at any layer, resolve the conflicted files, stage them, and continue the cascading rebase until all layers in the stack are rebased and pass local verification.
4. Push the updated stack branches atomically to the remote after explicit user approval.
5. For CLI execution instructions (`gh stack`), refer to the `github-cli` skill.

## 5. Pull Request Merging Rules

- **Explicit User Confirmation**: Always obtain explicit user approval before executing a merge.
- **CI Requirement**: All GitHub Actions / CI checks MUST pass before merging.
- **Squash-Merge Preference**: Prefer squash-and-merge (`gh pr merge --squash`) for standalone pull requests.
- **Stacked PR Merging**: Stacked PRs must be merged **bottom-up** (merging the target layer and every unmerged layer beneath it as an all-or-nothing atomic operation) using native stack merge tooling rather than single-PR merge commands. When a lower PR is squash-merged, synchronize the remaining stack so upper layers automatically retarget and replay (`--onto`) against the trunk without replaying already-merged commits. Refer to the `github-cli` skill for execution.
- **Ruleset-Gated PR Merges**: On repositories using active GitHub branch rulesets where the user has bypass privileges, if `gh pr merge --squash` fails due to base branch policy, supply `--admin` to bypass the ruleset gate once CI checks and approvals are satisfied.
- **Remote Branch Deletion**: Remote branch deletion is optional and separate. Delete a remote branch only after explicit user approval for that deletion.

### Automated Merging Tool (`scripts/pr_merge.sh`)

Use the bundled helper script `scripts/pr_merge.sh` to safely preflight and squash-merge a PR in one call:
```bash
bash <skill-dir>/scripts/pr_merge.sh <pr> --repo <owner/repo> [--admin] [--dry-run] [--delete-branch]
```
The script automatically verifies:
1. PR open status and mergeability (fails loudly with exit code 2 on merge conflicts).
2. CI status check rollup (fails with exit code 3 if CI checks are failing or pending).
3. Applies `--admin` for ruleset bypass if requested.
4. Supports `--dry-run` to preview the preflight without executing the merge.

### Batch Merging Tool (`scripts/batch_merge.sh`)

Use `scripts/batch_merge.sh` to preflight and squash-merge multiple approved pull requests sequentially:
```bash
bash <skill-dir>/scripts/batch_merge.sh --repo <owner/repo> --prs <1,2,3> [--admin] [--delete-branch] [--dry-run]
```
The script preflights every PR first, prints a clean Markdown status table, skips blocked/conflicting PRs, and sequentially merges conflict-free candidates with `--admin` ruleset bypass and branch deletion.

## 6. Stacked Pull Request Rules & Architecture

Stacked pull requests decompose large features or architectural migrations into an ordered chain of small, logically dependent pull requests:

```text
(trunk) <- layer-1 (bottom) <- layer-2 (middle) <- layer-3 (top)
```

### Layer Design & Dependency Ordering
- **Plan Layers Before Writing Code**: A stack is a strict dependency chain. If code in one layer depends on code in another, the dependency must live in the same layer or a lower one. Plan the layer order upfront rather than writing a monolithic branch and splitting it later.
- **Bottom-Up Architectural Order**:
  1. *Bottom (Foundation)*: ADRs/plans, schemas, core types, data models, shared interfaces, or pure preparatory refactors.
  2. *Middle (Core Logic)*: Engine rules, services, pipelines, and business logic consuming the foundation.
  3. *Top (Surface & Teardown)*: CLI/UI wiring, consumer integrations, end-to-end tests, and removal of deprecated/legacy code once all callers have been migrated in lower layers.
- **Atomic Layer Compilation**: Every individual PR in the stack must compile and pass all tests and verification gates independently when checked out in isolation. Never commit broken intermediate state or delete legacy interfaces at the bottom of a stack before upper layers migrate their callers.
- **One Stack, One Story / One Layer, One Concern**: Group branches into a single stack only when they serve the same feature or epic. Start a separate stack for unrelated bug fixes or features. If a layer cannot be described in one sentence, split it into two layers.
- **Stack Depth & Epic Integration Branches**: Keep routine feature stacks shallow (2–4 layers) to minimize review and rebase overhead. For large architectural epics (5+ layers), consider rooting the stack on an epic integration branch or keeping bottom layers non-controversial so they can land early.

### Modifying & Maintaining a Stack
- **Editing a Lower Layer**: Never fix a defect or review comment belonging to a lower layer by committing on the top branch. Always switch to the layer that owns the concern, commit the change there, and run an upstack cascading rebase so all higher layers inherit the fix linearly.
- **Conflict Resolution Reuse (`rerere`)**: Enable Git reuse of recorded conflict resolutions (`rerere`) when working with stacks so a conflict resolved on a lower layer is replayed automatically as upper layers cascade.
- **CI Branch-Filter Awareness**: If repository CI workflows restrict `pull_request` triggers to the default branch (e.g., `branches: [main]`), mid-stack PRs targeting parent feature branches will not trigger full CI suites on GitHub until retargeted to trunk. Always run the project's full local verification suite across rebased stack layers before pushing.
- **Execution Delegation**: For concrete CLI commands to initialize, add layers, view, checkout, rebase, sync, submit, and merge stacks, refer to the `github-cli` skill (Stacked PRs reference).
