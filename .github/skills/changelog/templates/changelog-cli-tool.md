# Changelog - CLI & Tooling Edition

All notable changes to this command-line application and environment tooling are documented here.
Adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Commands & Flags Added
- Add `--json` output flag to `status` command ([#85](https://github.com/owner/repo/pull/85)).
- Introduce `profile switch` subcommand for instant runtime reloads ([#87](https://github.com/owner/repo/pull/87)).

### Environment & Configuration
- Support `DF_CONFIG_PATH` override in shell initialization ([#84](https://github.com/owner/repo/pull/84)).

### Platform & OS Compatibility
- Added native macOS Apple Silicon and Linux ARM64 binary targets ([#82](https://github.com/owner/repo/pull/82)).

### Bug Fixes
- Fix terminal cursor artifacting when exiting interactive prompt ([#86](https://github.com/owner/repo/pull/86)).

<!--
changelog-provenance:
  version: "Unreleased"
  commit_range: "v1.2.0..HEAD"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v1.2.0...HEAD"
  commit_count: 8
  prs_included: [82, 84, 85, 86, 87]
  labels_recorded:
    cli: [85, 87]
    config: [84]
    platform: [82]
    bug: [86]
  omitted_or_internal:
    - sha: "f1e2d3c"
      reason: "ci: add shellcheck step to workflow"
-->

---

## [1.2.0] - 2026-10-02

### Commands & Flags Added
- Added `audit` command with summary tables and JSON export ([#75](https://github.com/owner/repo/pull/75)).

### Changed
- Default table output now automatically wraps to detected terminal columns ([#78](https://github.com/owner/repo/pull/78)).

### Deprecated
- Flag `--raw` is deprecated; prefer `--format=plain` or `--json` ([#79](https://github.com/owner/repo/pull/79)).

### Bug Fixes
- Fixed exit code returning 0 on fatal parse failures ([#80](https://github.com/owner/repo/pull/80)).

<!--
changelog-provenance:
  version: "1.2.0"
  date: "2026-10-02"
  commit_range: "v1.1.0..v1.2.0"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v1.1.0...v1.2.0"
  commit_count: 14
  prs_included: [75, 78, 79, 80]
  labels_recorded:
    cli: [75, 78]
    deprecation: [79]
    bug: [80]
  omitted_or_internal:
    - sha: "a9b8c7d"
      reason: "chore: format codebase with shfmt"
-->

[Unreleased]: https://github.com/owner/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/owner/repo/compare/v1.1.0...v1.2.0
