---
name: code-performance
description: >
  Diagnose, profile, and optimize application performance across database
  queries, backend compute, and frontend asset delivery, and verify benchmark
  baseline claims. Use when identifying N+1 query loops, slow API endpoints,
  unindexed database queries, memory leaks, asset bloat, hot-path bottlenecks,
  or reproducing claimed benchmark speedups.
---

# Code Performance Optimization Knowledge Centre

Reference hub for profiling database access, caching strategies, algorithmic hot paths, frontend asset delivery, and reproducing benchmark claims.

## When to Use

- Profiling slow endpoints, API latency spikes, or background job delays.
- Auditing database query patterns (N+1 loops, index selectivity vs. write cost, unbounded queries, connection pooling).
- Designing caching headers, key namespacing, TTL jitter, and stampede protection.
- Detecting `O(n^2)` collection loops, ReDoS regexes, resource leaks, or frontend bundle/rendering bloat.
- Verifying committed benchmarks and claimed speedups against real base-branch baselines.

## Domain Knowledge Index

| Topic | Resource | Use When |
|---|---|---|
| Database bottlenecks & pooling | `@references/database-bottlenecks.md` | Auditing ORM N+1 loops, index selectivity, pagination, connection pools, and search queries |
| Caching strategies | `@references/caching-strategies.md` | Reviewing HTTP `Cache-Control`/`ETag` headers, TTL jitter, and cache stampede mitigations |
| Algorithmic complexity & leaks | `@references/algorithmic-complexity.md` | Eliminating nested `O(n^2)` lookups, ReDoS backtracking, and daemon memory/handle leaks |
| Frontend & asset performance | `@references/frontend-performance.md` | Auditing bundle tree-shaking, route/component code splitting, and list virtualization |
| Benchmark baseline verification | `@references/benchmark-verification.md` | Confirming benchmarks are committed, exercise changed paths, and reproduce head vs. base numbers |

## Report Template

| Template | Path | Use When |
|---|---|---|
| Performance audit report | `@templates/performance-audit-report.md` | Reporting bottlenecks with root cause, optimization strategy, and before/after diffs |
