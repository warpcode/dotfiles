# Changelog - Monorepo Edition

Multi-package workspace changelog tracking scoped package changes, shared utilities, and dependency synchronizations.
Each entry flags affected package scopes (`@scope/core`, `@scope/cli`, `@scope/web`).

## [Unreleased]

### `@scope/core`
- **Added**: Exponential backoff retry handler for transport calls ([#405](https://github.com/owner/repo/pull/405)).
- **Fixed**: Race condition in in-memory event bus subscriber detach ([#406](https://github.com/owner/repo/pull/406)).

### `@scope/cli`
- **Changed**: Interactive prompts upgraded to render colored badges ([#408](https://github.com/owner/repo/pull/408)).
- **Fixed**: Parsing flag arrays when given multiple `--tag` arguments ([#407](https://github.com/owner/repo/pull/407)).

### Shared & Root Tooling
- Bumped workspace typescript compiler to 5.6.2 ([#402](https://github.com/owner/repo/pull/402)).

<!--
changelog-provenance:
  version: "Unreleased"
  commit_range: "v3.1.0..HEAD"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v3.1.0...HEAD"
  commit_count: 7
  prs_included: [402, 405, 406, 407, 408]
  labels_recorded:
    pkg:core: [405, 406]
    pkg:cli: [407, 408]
    root: [402]
  omitted_or_internal:
    - sha: "7788990"
      reason: "ci: parallelize turbo cache builds"
-->

---

## [3.1.0] - 2026-10-02

### `@scope/core`
- **Added**: Pluggable storage adapter interface ([#380](https://github.com/owner/repo/pull/380)).

### `@scope/cli`
- **Added**: Initial scaffold command `init` ([#382](https://github.com/owner/repo/pull/382)).

<!--
changelog-provenance:
  version: "3.1.0"
  date: "2026-10-02"
  commit_range: "v3.0.0..v3.1.0"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/v3.0.0...v3.1.0"
  commit_count: 15
  prs_included: [380, 382]
  labels_recorded:
    pkg:core: [380]
    pkg:cli: [382]
  omitted_or_internal:
    - sha: "9988776"
      reason: "chore: update pnpm lockfile"
-->

[Unreleased]: https://github.com/owner/repo/compare/v3.1.0...HEAD
[3.1.0]: https://github.com/owner/repo/compare/v3.0.0...v3.1.0
