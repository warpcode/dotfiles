# Changelog Standards Reference

This document details the open standards, conventions, and mapping rules governing structured changelogs across modern software projects.

---

## 1. Keep a Changelog (1.1.0) Specification

The standard [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) guidelines state that changelogs are written for **humans, not machines**. They provide a curated narrative of what changed, why it matters, and how to upgrade.

### Core Principles
1. **One version per release**: Group changes chronologically, latest release at the top.
2. **ISO 8601 Dates**: Release dates MUST be formatted as `YYYY-MM-DD` (e.g. `2026-10-02`).
3. **An `[Unreleased]` section**: Track upcoming changes at the very top to facilitate continuous documentation before tagging.
4. **Linkable versions**: Every version header should be a Markdown link pointing to the Git compare diff between the previous and current tags.

### Standard Change Categories

| Category | Definition | SemVer Implication |
|---|---|---|
| **Added** | New features, flags, endpoints, or public capabilities. | Minor (or Major if breaking) |
| **Changed** | Changes in existing functionality, behavior, or defaults. | Minor or Major |
| **Deprecated** | Features marked for future removal with migration advice. | Minor |
| **Removed** | Features, flags, or interfaces eliminated from the codebase. | Major (Breaking) |
| **Fixed** | Any bug fix resolving improper behavior or errors. | Patch |
| **Security** | Vulnerability remediations, CVE fixes, dependency patches. | Patch or Minor |

---

## 2. Semantic Versioning (SemVer 2.0.0) Alignment

Under [SemVer 2.0.0](https://semver.org/), version numbers follow `MAJOR.MINOR.PATCH`:
- **MAJOR (`X.0.0`)**: Incompatible API changes, removed functions, modified parameter signatures, changed default behaviors.
- **MINOR (`0.Y.0`)**: Backwards-compatible additions, newly supported platforms, non-breaking feature enhancements, deprecation notices.
- **PATCH (`0.0.Z`)**: Backwards-compatible bug fixes, security patches, performance improvements without API changes.

### Version Header Syntax
```markdown
## [Unreleased]
## [2.1.0] - 2026-10-02
## [2.0.1] - 2026-09-15
## [2.0.0] - 2026-09-01
```

---

## 3. Conventional Commits (1.0.0) Mapping

When generating changelogs from Git commit history, map conventional commit types to Keep a Changelog categories using this matrix:

| Conventional Commit Prefix | Keep a Changelog Category | Classification |
|---|---|---|
| `feat:` / `feat(scope):` | **Added** | User-Facing |
| `fix:` / `fix(scope):` | **Fixed** | User-Facing |
| `perf:` / `perf(scope):` | **Changed** (Performance) | User-Facing |
| `refactor:` (behavioral) | **Changed** | User-Facing |
| `deprecate:` / `deprecate(scope):` | **Deprecated** | User-Facing |
| `revert:` | **Removed** or **Fixed** | User-Facing |
| `sec:` / `security:` | **Security** | User-Facing |
| `feat!:` / `BREAKING CHANGE:` | **Breaking Changes** ⚠️ | User-Facing (Major) |
| `chore:` / `ci:` / `test:` / `build:` | *Omitted from narrative* | Recorded in Provenance |
| `style:` / `docs:` (internal) | *Omitted from narrative* | Recorded in Provenance |

---

## 4. Compare URL Reference Conventions

At the bottom of the changelog, include markdown reference links for each release:

```markdown
[Unreleased]: https://github.com/owner/repo/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/owner/repo/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/owner/repo/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/owner/repo/compare/v1.9.0...v2.0.0
```

For initial releases (e.g. `1.0.0` or `0.1.0` without a prior tag):
```markdown
[1.0.0]: https://github.com/owner/repo/releases/tag/v1.0.0
```
