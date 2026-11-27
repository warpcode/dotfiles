---
name: code-review
description: >
  Platform-agnostic code review knowledge centre for local diffs, uncommitted
  changes, branch comparisons, stacked PRs, and formal PR reviews. Use when
  reviewing code changes for correctness, premise validity, security,
  leftover debug artifacts, test/mutation strength, style, performance, or
  maintainability.
---

# Code Review Knowledge Centre

Knowledge centre for reviewing code changes across local working trees, branch comparisons, stacked PRs, and formal pull requests—independent of any issue tracker. For GitHub PR mechanics (diff preflight, inline anchor verification, review submission, and thread triage), pair with `github`. For orchestration, parallel subagent dispatch, and disposition policies, see `.github/agents/code-reviewer.agent.md`.

---

## When to Use

- Reviewing uncommitted local changes, staged diffs, or specific commits.
- Comparing a feature branch against `origin/master`, `origin/main`, or an intermediate stacked base.
- Auditing a GitHub PR or Jira-linked change (treat tracker links as optional context enrichment, never a gating prerequisite).
- Triaging automated security-scanner findings against actual changed code and contracts.

## Input Expectations

Tracker and PR context is optional enrichment, never a gate before reviewing:

- **Jira Issue** (optional): Load via `jira-api` (if epic, include tasks/subtasks).
- **GitHub Issue** (optional): Load via `github` (issues reference) and verify a linked PR exists (`closingIssuesReferences`).
- **Pull Request**: Gather a full snapshot via `github/scripts/pr_audit_bundle.sh`.
- **Branch**: Compare `origin/<branch>` against `origin/<baseRefName>` (never hardcode `master`/`main` if an explicit base exists).

## Review Invariants

- **Read-Only**: Never commit, check out branches, or modify local workspace files unless explicitly instructed.
- **Neutral & Evidence-Backed**: Use strictly neutral, fact-based tone without filler; cite exact `file:line` locations and snippets.
- **Optional Tracker Context**: When an issue/ticket/spec is referenced, verify acceptance criteria against the diff; when none exists, proceed directly with code and diff review.
- **Security Triage**: Load `code-security-audit` when reviewing security-sensitive paths or scanner findings.

## Review Prioritization Hierarchy

Evaluate changes systematically in the 10-tier defect priority order defined in `@references/review-rubrics.md` §1 (bugs & correctness first, through unresolved review feedback).

## Knowledge Centre Index

| Topic | Resource | Use When |
|---|---|---|
| Prioritization rubric | `@references/review-rubrics.md` | Applying the 10-tier defect prioritization hierarchy |
| Premise, scope & diff integrity | `@references/premise-and-diff-scrutiny.md` | Auditing premise validity, optional issue ACs, debug artifacts, blob-hash sweeps, self-reverts, or base drift |
| Test & mutation verification | `@references/test-and-mutation-verification.md` | Auditing test-only diffs, assertion strength, mutation coverage, CI test discovery, or injection tests |
| Standard finding schema | `@templates/review-finding.md` | Formatting structured review findings (`Severity`, `Description`, `Impact`, `Proposed Solution`) |

## Bundled Scripts

| Script | Invocation | Run When |
|---|---|---|
| `@scripts/mutation_check.sh` | `bash <skill-dir>/scripts/mutation_check.sh --pr <n> --spec <mutations.json> --test-cmd "<pkg-cmd>"` | Proving test assertions actually cover changed or added branches (`KILLED` / `SURVIVED` / `PRE-EXISTING`) |
| `@scripts/apply_mutation.py` | `python3 <skill-dir>/scripts/apply_mutation.py --check --root <dir> <spec.json>` | Pre-validating multi-line `old`/`new` mutation patterns before running `mutation_check.sh` |
| `@scripts/audit_ci_test_coverage.sh` | `bash <skill-dir>/scripts/audit_ci_test_coverage.sh --repo <owner>/<repo> [--ref <ref>] [path ...]` | Verifying "all tests pass" claims against actual CI discovery and `paths:` filters |

## Domain Cross-References

- **Security audits & scanner triage**: `code-security-audit`
- **Performance & benchmark reproduction**: `code-performance`
- **Architecture, layering & dead-code reference checks**: `code-architecture`
- **TDD & test smell taxonomy**: `code-tdd`
- **GitHub PR lifecycle, anchor verification & submission**: `github`
