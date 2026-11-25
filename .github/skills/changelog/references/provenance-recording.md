# Changelog Provenance & Audit Trail Reference

This document defines the specification for recording Git commit ranges, PR metadata, associated labels, and omission records within changelogs.

---

## 1. Why Provenance Matters

Traditional changelogs suffer from the **"Missing Change Dilemma"**:
- An engineer or AI agent drafts a release entry by cherry-picking commits.
- Weeks later, users report a regression or an unannounced behavioral change.
- Because the changelog does not record *which* exact commits or PRs were evaluated, nobody knows whether the omission was intentional (e.g. an internal chore) or an oversight (a missed breaking fix).

By embedding a **Provenance Block**, every changelog entry explicitly records:
1. The **exact commit range** (`<base>..<head>`, start SHA, end SHA, compare link).
2. The **total commit count** in that range.
3. Every **PR number and its associated GitHub/GitLab labels** (e.g. `breaking`, `enhancement`, `security`).
4. An **omission ledger** listing non-user-facing commits (e.g. `chore:`, `ci:`, `test:`) with explicit reasons.

This allows continuous, automated verification: if a commit falls inside the range but is neither documented in the narrative nor present in the omission ledger, it is flagged as a **missing piece**.

---

## 2. Machine-Readable Provenance Block Specification

The provenance block is placed inside an HTML comment immediately following each version section (including `[Unreleased]`):

```markdown
<!--
changelog-provenance:
  version: "1.3.0"
  date: "2026-10-02"
  commit_range: "v1.2.0..v1.3.0"
  base_commit: "9f8e7d6c5b4a3f2e1d0c9b8a7f6e5d4c3b2a1098"
  head_commit: "1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b"
  compare_url: "https://github.com/warpcode/dotfiles/compare/v1.2.0...v1.3.0"
  commit_count: 24
  prs_included: [42, 45, 48, 51]
  labels_recorded:
    enhancement: [42, 51]
    bug: [45]
    breaking: [48]
  omitted_or_internal:
    - sha: "b3c4d5e"
      reason: "chore(deps): bump actions/checkout from 3 to 4"
    - sha: "c4d5e6f"
      reason: "ci: add workflow linter"
    - sha: "d5e6f7a"
      reason: "test: improve unit test assertions"
-->
```

### Schema Attributes

| Field | Type | Description |
|---|---|---|
| `version` | string | Target version tag or `"Unreleased"` |
| `date` | string | Release date in `YYYY-MM-DD` (omitted for `Unreleased`) |
| `commit_range` | string | Git revision range expression (e.g. `v1.2.0..v1.3.0`) |
| `base_commit` | string | Full 40-character SHA of the base commit |
| `head_commit` | string | Full 40-character SHA of the head commit |
| `compare_url` | string | Full URL to the remote git diff view |
| `commit_count` | integer | Total number of commits between base and head |
| `prs_included` | list[int] | List of pull request numbers represented in user-facing entries |
| `labels_recorded` | map[str, list[int]] | PR numbers mapped by their repository classification labels |
| `omitted_or_internal` | list[dict] | Commits excluded from user-facing notes with SHA and reason |

---

## 3. Human-Readable Audit Collapsible (Optional)

In repositories where public transparency is valued, the machine-readable comment can be complemented by an optional collapsible details element:

```markdown
<details>
<summary><b>Audit Trail & Provenance</b> (v1.2.0..v1.3.0 · 24 commits)</summary>

- **Commit Range**: [`9f8e7d6`...`1a2b3c4`](https://github.com/warpcode/dotfiles/compare/v1.2.0...v1.3.0)
- **PRs & Labels**:
  - #42 `[enhancement, core]`: Added streaming response parser
  - #45 `[bug, cli]`: Fixed argument splitting in zsh subshells
  - #48 `[breaking, api]`: Replaced sync client with async promises
- **Internal / Filtered Commits** (audited):
  - `b3c4d5e` chore(deps): bump actions/checkout
  - `c4d5e6f` ci: add workflow linter
</details>
```

---

## 4. Continuity & Gap Verification

To guarantee that no changes slip through between releases, provenance blocks must satisfy the **Contiguity Invariant**:
- For any release `N` and predecessor `N-1`:
  `base_commit(N) == head_commit(N-1)`
- If `base_commit(N)` differs from `head_commit(N-1)`, an untracked git range gap exists that must be resolved.
