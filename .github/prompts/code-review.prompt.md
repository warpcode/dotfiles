---
name: code-review
description: "Thin review entrypoint delegating local diffs, branch comparisons, stacked PRs, and formal PR or issue reviews to the code-reviewer agent."
argument-hint: "Target to review (e.g. PR #123, owner/repo#123, branch name, issue URL, or leave blank for local diff)"
agent: "code-reviewer"
---

# Code Review

Delegate the review to `code-reviewer` (`.github/agents/code-reviewer.agent.md`) to execute its 4-phase review pipeline (`Gather & Scope` -> `Audit & Mutate-Verify` -> `Reconcile Review Threads` -> `Disposition & Submit`) across the `code-review`, `github`, `git-expert`, `code-security-audit`, `code-architecture`, and `code-performance` knowledge centres.

## Target Binding

- **Pull Request (`#N`, URL, or `<owner>/<repo>#N`)**: Confirm `<owner>/<repo>` explicitly, gather context via `github/scripts/pr_audit_bundle.sh`, and inspect the PR's actual `baseRefName` (supporting mainline, `epic/<id>-<slug>`, and stacked parent branches).
- **Branch (`<branch>` vs optional `<base>`)**: Compare `origin/<branch>` against the resolved or explicit base (`origin/master`, `origin/main`, or stacked parent).
- **Local Diff / Commit**: Inspect working-tree `git diff` or the named commit directly without requiring an issue or PR link.
- **Jira / GitHub Issue (optional)**: Load via `jira-api` (include subtasks/epic context) or `github` as optional enrichment; never halt a diff or branch review for missing tracker links.
- **No Target Supplied**: Inspect the local `git diff`; if the working tree is clean, ask which commit, branch, or PR to review.

## Execution Constraints

- **Read-Only Audit**: Never commit, check out branches in the primary working tree, or modify local files unless explicitly instructed.
- **Disposition & Submission Policy**: Apply `code-reviewer` neutral tone, finding schema (`code-review/templates/review-finding.md`), and event rules (`REQUEST_CHANGES` on any valid finding, silent empty-body `APPROVE` when clean, `COMMENT` for self-authored PRs), obtaining explicit approval before posting GitHub reviews.
