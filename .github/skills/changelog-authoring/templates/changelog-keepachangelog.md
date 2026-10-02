# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Feature description with context and link to PR ([#124](https://github.com/owner/repo/pull/124))

### Changed
- Refactored subsystem with user-visible behavior improvement ([#122](https://github.com/owner/repo/pull/122))

### Deprecated
- Notice of feature deprecation and upcoming removal milestone ([#120](https://github.com/owner/repo/pull/120))

### Removed
- Previously deprecated capability removed ([#119](https://github.com/owner/repo/pull/119))

### Fixed
- Bug fix resolving specific symptom or edge case ([#123](https://github.com/owner/repo/pull/123))

### Security
- Security patch addressing vulnerability or advisory ([#121](https://github.com/owner/repo/pull/121))

<!--
changelog-provenance:
  version: "Unreleased"
  commit_range: "v1.0.0..HEAD"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v1.0.0...HEAD"
  commit_count: 6
  prs_included: [119, 120, 121, 122, 123, 124]
  labels_recorded:
    enhancement: [122, 124]
    bug: [123]
    security: [121]
    deprecation: [120]
    breaking: [119]
  omitted_or_internal:
    - sha: "abcdef1"
      reason: "chore(deps): bump dependency version"
    - sha: "abcdef2"
      reason: "ci: update lint workflow"
-->

---

## [1.0.0] - 2026-10-02

### Added
- Initial stable release of project capabilities.
- Core CLI commands and runtime configuration system ([#101](https://github.com/owner/repo/pull/101)).

### Fixed
- Path normalization on Unix environments ([#102](https://github.com/owner/repo/pull/102)).

<!--
changelog-provenance:
  version: "1.0.0"
  date: "2026-10-02"
  commit_range: "v0.9.0..v1.0.0"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v0.9.0...v1.0.0"
  commit_count: 12
  prs_included: [101, 102]
  labels_recorded:
    enhancement: [101]
    bug: [102]
  omitted_or_internal:
    - sha: "1234567"
      reason: "test: expand unit test coverage"
-->

[Unreleased]: https://github.com/owner/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/owner/repo/compare/v0.9.0...v1.0.0
