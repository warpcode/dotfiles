# Changelog - Library & SDK Edition

This project adheres to [Semantic Versioning (SemVer 2.0.0)](https://semver.org/spec/v2.0.0.html) and [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Public API surface contracts, breaking changes, and migration recipes are strictly tracked.

## [Unreleased]

### Breaking Changes ⚠️
- None.

### Added
- Export `createClient` factory with explicit timeout configuration ([#210](https://github.com/owner/repo/pull/210)).

### Changed
- Improved serialization performance for nested payloads ([#208](https://github.com/owner/repo/pull/208)).

### Deprecated
- `client.connectSync()` is deprecated; use asynchronous `await client.connect()` instead ([#205](https://github.com/owner/repo/pull/205)).

### Fixed
- Reconnection backoff timer resetting improperly on socket errors ([#209](https://github.com/owner/repo/pull/209)).

<!--
changelog-provenance:
  version: "Unreleased"
  commit_range: "v2.0.0..HEAD"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v2.0.0...HEAD"
  commit_count: 5
  prs_included: [205, 208, 209, 210]
  labels_recorded:
    enhancement: [208, 210]
    bug: [209]
    deprecation: [205]
  omitted_or_internal:
    - sha: "a1b2c3d"
      reason: "build: update bundler plugins"
-->

---

## [2.0.0] - 2026-10-02

### Breaking Changes ⚠️
- Removed support for Node.js < 20.0.0 ([#190](https://github.com/owner/repo/pull/190)).
- Dropped deprecated callback-based handlers in favor of Promises ([#192](https://github.com/owner/repo/pull/192)).
  - **Migration**: Replace `client.query(sql, (err, res) => ...)` with `const res = await client.query(sql)`.

### Added
- Native TypeScript type definitions for streaming cursors ([#195](https://github.com/owner/repo/pull/195)).

### Fixed
- Memory leak in idle connection pool cleanup ([#198](https://github.com/owner/repo/pull/198)).

<!--
changelog-provenance:
  version: "2.0.0"
  date: "2026-10-02"
  commit_range: "v1.4.2..v2.0.0"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v1.4.2...v2.0.0"
  commit_count: 18
  prs_included: [190, 192, 195, 198]
  labels_recorded:
    breaking: [190, 192]
    enhancement: [195]
    bug: [198]
  omitted_or_internal:
    - sha: "e4f5a6b"
      reason: "test: migrate test suite to vitest"
-->

[Unreleased]: https://github.com/owner/repo/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/owner/repo/compare/v1.4.2...v2.0.0
