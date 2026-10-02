# Changelog - Service & Web Application Edition

Deployment and release log for backend services, APIs, and web client applications.
Organized by release train / deployment date with operational, schema, and user-facing callouts.

## [Unreleased]

### User-Facing Features
- Real-time notification badge on user dashboard navigation bar ([#310](https://github.com/owner/repo/pull/310)).

### API & Backend Enhancements
- Batch processing endpoint for bulk artifact exports at `/api/v2/artifacts/batch` ([#308](https://github.com/owner/repo/pull/308)).

### Database & Schema Migrations
- Migration `20261002_add_index_on_org_id` applied concurrently without downtime ([#306](https://github.com/owner/repo/pull/306)).

### Operational & Infrastructure Notes
- Requires environment variable `REDIS_CLUSTER_MODE=true` prior to rolling deployment ([#309](https://github.com/owner/repo/pull/309)).

### Bug Fixes
- Fixed session expiration redirection looping on stale cookies ([#307](https://github.com/owner/repo/pull/307)).

<!--
changelog-provenance:
  version: "Unreleased"
  commit_range: "deploy-2026-09-25..HEAD"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/deploy-2026-09-25...HEAD"
  commit_count: 9
  prs_included: [306, 307, 308, 309, 310]
  labels_recorded:
    ui: [310]
    api: [308]
    migration: [306]
    ops: [309]
    bug: [307]
  omitted_or_internal:
    - sha: "1122334"
      reason: "ops: update datadog agent sidecar image"
-->

---

## [2026-09-25]

### User-Facing Features
- Added CSV download button to billing transaction history ([#295](https://github.com/owner/repo/pull/295)).

### Bug Fixes
- Resolved 500 error on checkout when promo code contains trailing whitespace ([#298](https://github.com/owner/repo/pull/298)).

<!--
changelog-provenance:
  version: "2026-09-25"
  date: "2026-09-25"
  commit_range: "deploy-2026-09-18..deploy-2026-09-25"
  base_commit: "BASE_SHA_HERE"
  head_commit: "HEAD_SHA_HERE"
  compare_url: "https://github.com/owner/repo/compare/deploy-2026-09-18...deploy-2026-09-25"
  commit_count: 11
  prs_included: [295, 298]
  labels_recorded:
    ui: [295]
    bug: [298]
  omitted_or_internal:
    - sha: "5566778"
      reason: "chore: rotate dev staging credentials"
-->

[Unreleased]: https://github.com/owner/repo/compare/deploy-2026-09-25...HEAD
[2026-09-25]: https://github.com/owner/repo/compare/deploy-2026-09-18...deploy-2026-09-25
