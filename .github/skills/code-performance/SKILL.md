---
name: code-performance
description: >
  Diagnose, profile, and optimize application performance across database
  queries, backend compute, and frontend asset delivery. Use when identifying
  N+1 query loops, slow API endpoints, unindexed database queries, memory
  leaks, asset bloat, or hot-path computational bottlenecks.
---

# Code Performance Optimization Skill

Standard Operating Procedure for identifying, measuring, and eliminating performance bottlenecks across the stack.

## When to use

- Profiling slow endpoints, API latency spikes, or background job delays.
- Auditing database query patterns (N+1 query loops, missing indexes, unbuffered large result sets).
- Detecting frontend asset bloat, missing code-splitting, or client-side rendering bottlenecks.
- Investigating memory leaks, unclosed connections, or CPU-intensive hot paths.

## Diagnostic Workflow

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│ 1. Locate Data  │ ──► │ 2. Compute & Memory  │ ──► │ 3. Frontend & Asset │
│    Layer Churn  │     │    Hot-Paths         │     │    Optimization     │
└─────────────────┘     └──────────────────────┘     └─────────────────────┘
```

### Phase 1: Database & Search Engine Query Profiling
1. Identify ORM N+1 query patterns: Look for relation accesses inside loops or template iterations without eager loading (`with()`, `preload`, `include`).
2. Audit index coverage: Ensure foreign keys, unique constraint columns, and filter columns in `WHERE` / `ORDER BY` clauses are backed by database indexes.
3. Check for unbounded result sets: Enforce pagination or chunked streaming for large data sets.
4. Audit connection lifecycle & pooling: Verify connection pool limits (PgBouncer, ProxySQL) and prevent persistent connection leaks in containerized/serverless runtimes.
5. Profile search engine queries (Elasticsearch/OpenSearch): Ensure filter context usage over scoring clauses, eliminate leading wildcards, and enforce cursor-based (`search_after`) deep pagination.
6. Read `@references/database-bottlenecks.md` for patterns.

### Phase 2: Compute & Memory Hot-Paths
1. Detect nested collection iterations (`O(n^2)` or worse) when maps/hash lookups (`O(1)`) should be used.
2. Check for resource leaks: Unclosed file handles, unreleased database connections, or runaway memory accumulators in daemon workers.
3. Review algorithmic complexity and catastrophic regex backtracking.
4. Read `@references/algorithmic-complexity.md`.

### Phase 3: Frontend & Asset Profiling
1. Audit bundle sizes & pipeline: Check for un-treeshaken dependencies, duplicate packages, unminified loaders, or missing font preload/`font-display: swap` headers.
2. Inspect route-level and component-level code splitting: Verify heavy views and modals use dynamic `import()` / lazy loading.
3. Profile client-side rendering & list virtualization: Enforce DOM virtualization (`vue-virtual-scroller`, `react-window`) for large data tables, verify stable loop keys (avoid index keys), and memoize heavy reactive computations.
4. Read `@references/frontend-performance.md`.

## Performance Report Output Format

```markdown
### Performance Audit Summary
- **Primary Bottleneck**: [Database Query Loop / Memory Accumulation / Asset Bloat]
- **Estimated Impact**: [High / Medium / Low]
- **Recommended Action**: [Eager Loading / Index Addition / Lazy Splitting]

### Bottlenecks Identified

#### [IMPACT: HIGH | MEDIUM | LOW] [Bottleneck Title]
- **Location**: `path/to/file.ext:L123-L145`
- **Root Cause**: Explanation of inefficient mechanism (e.g. N+1 query executing in `foreach`).
- **Optimization Strategy**: Step-by-step refactoring proposal.
- **Before / After Snippet**:
  ```diff
  - Inefficient code
  + Optimized code
  ```
```

