# Changelog Audit Report

**Target File**: `{{CHANGELOG_PATH}}`  
**Date of Audit**: `{{AUDIT_DATE}}`  
**Audit Scope**: Versions `{{VERSIONS_AUDITED}}`  
**Overall Status**: `{{STATUS_BADGE}}` (PASS / WARN / FAIL)

---

## 1. Executive Summary

| Check Category | Status | Details |
|---|---|---|
| **Structural & Format Compliance** | {{FORMAT_STATUS}} | Keep a Changelog headers, ISO dates, compare link references |
| **Provenance & Metadata Blocks** | {{PROVENANCE_STATUS}} | Valid commit ranges, base/head SHAs, PR label mappings |
| **Range Continuity** | {{CONTINUITY_STATUS}} | Continuous commit chain without untracked gaps |
| **Commit Completeness (Gap Detection)** | {{GAP_STATUS}} | Zero unaccounted commits between Git history and changelog |
| **SemVer Alignment** | {{SEMVER_STATUS}} | Breaking changes mapped to MAJOR, features to MINOR |

---

## 2. Version Range Continuity Analysis

| Version | Release Date | Commit Range | Commit Count | Gap to Predecessor |
|---|---|---|---|---|
| `{{VERSION_1}}` | `{{DATE_1}}` | `{{RANGE_1}}` | {{COUNT_1}} | None (Continuous) |
| `{{VERSION_2}}` | `{{DATE_2}}` | `{{RANGE_2}}` | {{COUNT_2}} | None (Continuous) |

---

## 3. Missing Pieces & Unaccounted Commits

The following commits fall inside the audited Git range but are **neither documented in the user-facing changelog nor classified in the audited omission ledger**:

| Commit SHA | Author | Subject Line | Detected Category / Scope | Severity |
|---|---|---|---|---|
| `{{SHA_1}}` | {{AUTHOR_1}} | {{SUBJECT_1}} | {{CATEGORY_1}} | High / Medium / Low |
| `{{SHA_2}}` | {{AUTHOR_2}} | {{SUBJECT_2}} | {{CATEGORY_2}} | High / Medium / Low |

> [!WARNING]
> High-severity missing commits represent user-visible changes (features, bug fixes, or breaking modifications) that were dropped from release communication.

---

## 4. PR Label & Classification Discrepancies

| PR # | Repository Labels | Changelog Section | Discrepancy Note |
|---|---|---|---|
| #{{PR_1}} | `[{{LABELS_1}}]` | `{{SECTION_1}}` | Label indicates breaking change, but listed under Fixed |

---

## 5. Remediation Action Items

- [ ] Incorporate high-severity missing commits into `CHANGELOG.md` under appropriate sections.
- [ ] Add internal/chore commits to the `omitted_or_internal` provenance block.
- [ ] Correct version comparison link target for `[{{VERSION}}]`.
- [ ] Update release date formatting to strict `YYYY-MM-DD`.
