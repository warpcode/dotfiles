# Gap Detection & Missing Pieces Heuristics

This document provides heuristics and triage rules for detecting missing pieces between Git commit logs and release changelogs.

---

## 1. Commit Classification Heuristics

When auditing a Git range (`<base>..<head>`), commits must be evaluated against the following criteria to determine whether they belong in the user-facing changelog:

### 1. User-Visible vs Internal
- **User-Visible (Must Appear in Narrative)**:
  - Changes modifying public functions, types, exports, or classes.
  - Changes altering runtime flags, CLI options, environment variables, or config files.
  - Bug fixes that alter user observable behavior, error handling, or performance.
  - Platform/dependency compatibility changes (e.g. dropping Node 18, supporting Python 3.12).
- **Internal (Belongs in Provenance Omission Ledger)**:
  - CI workflow file updates (`.github/workflows/*.yml`).
  - Unit/integration test refactors without behavioral impact (`tests/*`).
  - Code formatting, lint fixes, typo corrections in internal comments (`style:`).
  - Dependency version bumps that do not introduce user-facing changes (`chore(deps):`).

---

## 2. Handling Git History Anomalies

### Squash Merges vs Merge Commits
- In repositories using GitHub **Squash and Merge**, the commit on the main branch contains the PR number in parentheses: `feat: streaming response (#142)`.
- In repositories using **Merge Commits**, the merge commit subject is `Merge pull request #142 from user/feature`.
- When auditing, parse both patterns to ensure the underlying PR is linked and its labels are resolved.

### Rebased or Cherry-Picked Commits
- If commits were rebased or cherry-picked onto a release branch, the commit SHA on the release branch may differ from the commit SHA on `master`/`main`.
- When auditing release branches, resolve ranges relative to the branch refs (e.g. `release/v1.2.0`), not mainline commits.

---

## 3. Monorepo Path Filtering

In a monorepo, a commit on `master` may touch multiple packages or only a single package:
- When auditing a package changelog (`packages/cli/CHANGELOG.md`), filter git log by path:
  `git log <base>..<head> -- packages/cli`
- A commit touching both `packages/cli` and `packages/core` must be cross-referenced in both package changelogs.
- Commits touching only root configuration (`turbo.json`, `.prettierrc`) belong in root tooling release notes or the root omission ledger.
