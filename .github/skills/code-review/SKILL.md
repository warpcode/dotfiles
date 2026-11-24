---
name: code-review
description: >
  Technical code review rubrics, premise scrutiny, mutation testing, and CI test
  coverage verification. Use when reviewing a Jira issue, GitHub issue, pull
  request, or branch against its base for correctness, security, test strength,
  and requirements compliance.
---

# Code Review Knowledge Centre

Standards, defect prioritization rubrics, and test/CI verification tools for auditing code changes. For GitHub PR mechanics (diff preflight, inline anchor verification, review submission, and thread triage), pair with `github-pr` and `github-cli`. For orchestration, parallel subagent dispatch, and disposition policies, see `.github/agents/code-reviewer.agent.md`.

---

## Input Expectations

- **Jira Issue**: Load via `jira-api` (if epic, include tasks/subtasks). Require a linked PR before reviewing code.
- **GitHub Issue**: Load via `github-cli` (issues reference) and verify a linked PR exists (`closingIssuesReferences`).
- **Pull Request**: Gather full snapshot via `github-cli/scripts/pr_audit_bundle.sh` and inspect any linked source issue/ticket.
- **Branch**: Compare `origin/<branch>` against `origin/<baseRefName>` (never hardcode `master`/`main` if an explicit base exists).

---

## Review Principles

- **Read-Only Audit**: Never commit, check out branches in the primary workspace, or make local edits during a code review unless explicitly instructed.
- **Premise & Utility Scrutiny**: Verify the reported bug or requirement actually exists in code/fixtures; reject false premises, superficial churn, or already-superseded fixes.
- **Source Issue Compliance**: Verify every acceptance criterion and edge case from the linked issue/ticket is satisfied.
- **Prioritization & Deep Checks**: Follow the 10-tier defect hierarchy, leftover debug/test artifact checks, merge-regression checks, mutation-testing rules, and benchmark verification in `@references/review-rubrics.md`.
- **Security Triage**: Load `code-security-audit` when reviewing security-sensitive paths or scanner findings.

---

## Bundled Script Toolkit (`scripts/`)

Run scripts with `--help` without reading source code.

| Script | Invocation | Run When |
|---|---|---|
| `mutation_check.sh` | `bash <skill-dir>/scripts/mutation_check.sh --pr <n> --spec <mutations.json> --test-cmd "<pkg-cmd>"` | Verifying test-only PRs or test assertions actually fail when branches under test are mutated (head vs. base) |
| `apply_mutation.py` | `python3 <skill-dir>/scripts/apply_mutation.py --check --root <dir> <spec.json>` | Pre-checking multi-line `old`/`new` mutation patterns against exact indentation before running `mutation_check.sh` |
| `audit_ci_test_coverage.sh` | `bash <skill-dir>/scripts/audit_ci_test_coverage.sh --repo <owner>/<repo> [--ref <ref>] [path ...]` | Verifying whether CI workflows actually discover and execute new/existing test files and checking `paths:` filters |
