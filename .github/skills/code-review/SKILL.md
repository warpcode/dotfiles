---
name: code-review
description: >
  Platform-agnostic code review knowledge centre for local diffs, uncommitted
  changes, branch comparisons, stacked PRs, and formal PR reviews. Use when
  reviewing code changes for correctness, premise validity, security,
  leftover debug artifacts, test/mutation strength, style, performance, or
  maintainability.
---

# Code Review Guidelines

Knowledge centre for reviewing code changes across local working trees, branch comparisons, stacked PRs, and formal pull requests—independent of any issue tracker.

## When to Use

- Reviewing uncommitted local changes, staged diffs, or specific commits.
- Comparing a feature branch against `origin/master`, `origin/main`, or an intermediate stacked base.
- Auditing a GitHub PR or Jira-linked change (treat tracker links as optional context enrichment, never a gating prerequisite).
- Triaging automated security-scanner findings against actual changed code and contracts.

## Review Invariants

- **Read-Only**: Never commit, check out branches, or modify local workspace files unless explicitly instructed.
- **Neutral & Evidence-Backed**: Use strictly neutral, fact-based tone without filler; cite exact `file:line` locations and snippets.
- **Optional Tracker Context**: When an issue/ticket/spec is referenced, verify acceptance criteria against the diff; when none exists, proceed directly with code and diff review.

## Review Prioritization Hierarchy

Evaluate changes systematically in this priority order:

1. **Requirement fulfillment & premise validity** — verify the defect/requirement is real, domain assumptions match existing code, and linked ACs (if any) are met.
2. **Bugs & functional correctness** — logic errors, edge cases, race conditions, error handling, semantic merge drift.
3. **Security issues** — load `code-security-audit` for injection, auth/authz, exposure, or scanner triage.
4. **Leftover test/debug artifacts** — stray `print`/`console.log`/`set -x`, hardcoded dummy data, `WIP`/`HACK` bypasses, or scratch files.
5. **Style guideline violations** — apply relevant language/project style conventions.
6. **Performance & efficiency** — load `code-performance` for hot paths, N+1 queries, or unverified benchmark claims.
7. **Readability & maintainability** — clarity, shallow nesting, modularity; consult `code-architecture` for layering and dead-code audits.
8. **Anti-patterns & duplication** — redundant abstractions, unnecessary churn, or copy-pasted logic.
9. **Project convention consistency** — alignment with repository patterns and architecture invariants.
10. **Unresolved review feedback** — open review comments or unanswered questions on active PRs.

## Knowledge Centre Index

| Topic | Resource | Use When |
|---|---|---|
| Premise, scope & diff integrity | `@references/premise-and-diff-scrutiny.md` | Auditing premise validity, optional issue ACs, debug artifacts, blob-hash sweeps, self-reverts, or base drift |
| Test & mutation verification | `@references/test-and-mutation-verification.md` | Auditing test-only diffs, assertion strength, mutation coverage, CI test discovery, or injection tests |
| Standard finding schema | `@templates/review-finding.md` | Formatting structured review findings (`Severity`, `Description`, `Impact`, `Proposed Solution`) |

## Bundled Scripts

| Script | Purpose | Run When |
|---|---|---|
| `@scripts/mutation_check.sh` | Mutates branches in isolated worktrees and checks whole-package tests (`KILLED` / `SURVIVED` / `PRE-EXISTING`) | Proving test assertions actually cover changed or added branches |
| `@scripts/apply_mutation.py` | Applies or `--check`-validates a mutation spec JSON array | Pre-validating `mutations.json` patterns before running `mutation_check.sh` |
| `@scripts/audit_ci_test_coverage.sh` | Checks whether `.github/workflows/*.yml` execute test files and reports `paths:` filters | Verifying "all tests pass" claims against actual CI coverage |

## Domain Cross-References

- **Security audits & scanner triage**: `code-security-audit`
- **Performance & benchmark reproduction**: `code-performance`
- **Architecture, layering & dead-code reference checks**: `code-architecture`
- **TDD & test smell taxonomy**: `code-tdd`
- **GitHub PR lifecycle, anchor verification & submission**: `github-pr-review`
