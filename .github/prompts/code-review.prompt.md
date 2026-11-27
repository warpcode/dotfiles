---
name: code-review
description: "Focused code review entrypoint for local diffs, uncommitted changes, branch comparisons, stacked PRs, and formal PRs or issues."
---

# Code Review

Review code changes objectively using `code-review` rubrics and verification guidelines. Issue/PR links are optional enrichment—never halt for missing tracker or PR links when a diff, commit, or branch target is available.

## Scope & Context Gathering

- **Uncommitted / Local Diff / Commit**: Inspect the local working-tree diff (`git diff`) or commit directly.
- **Branch Comparison**: Compare `origin/<branch>` against `origin/<base>` (default `origin/master` or `origin/main`).
- **Pull Request**: Load PR snapshot via `github/scripts/pr_audit_bundle.sh` and check any associated issue context.
- **Jira / GitHub Issue (optional)**: Load via `jira-api` (include subtasks/epic context) or `github` if referenced; if no linked PR exists, review any available diff/branch or clarify the target diff without gating on a tracker link.
- **No Target Supplied**: Review the local `git diff`; if the working tree is clean, ask which commit, branch, or PR to review.

## Review Behavior

- **Read-Only**: Never commit, check out branches, or modify local files unless explicitly instructed.
- **Neutral & Evidence-Backed**: Cite exact `file:line` locations and snippets; follow the `code-review` prioritization hierarchy (`code-review/references/review-rubrics.md`), premise/diff scrutiny (`code-review/references/premise-and-diff-scrutiny.md`), and test/mutation verification (`code-review/references/test-and-mutation-verification.md`).
- **Domain Specialists**: Load `code-security-audit`, `code-performance`, `code-architecture`, or `code-tdd` as needed for security, performance, architecture, or test-design findings.
- **Finding Format**: Structure findings per `code-review/templates/review-finding.md` (`Severity`, `Description`, `Impact`, `Proposed Solution`).
