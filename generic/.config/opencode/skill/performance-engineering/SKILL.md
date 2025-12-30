---
name: performance-engineering
description: >-
  Domain specialist for performance optimization, profiling, caching, and resource management. Expertise includes profiling tools, caching strategies (Redis, query cache), load testing, observability (metrics, tracing), N+1 query detection, algorithm complexity analysis, resource leak detection, connection pooling, query optimization, memory leaks, file handle leaks, connection leaks, and resource exhaustion patterns. Use when: performance troubleshooting, slow queries, memory issues, caching strategies, load testing, profiling, resource exhaustion. Triggers: "performance", "slow", "optimization", "profiling", "caching", "load test", "bottleneck", "resource leak", "N+1", "memory leak", "complexity", "Big O".
---

# PERFORMANCE_ENGINEERING

## DOMAIN EXPERTISE
- **Common Issues**: Slow queries, missing indexes, inefficient algorithms, memory leaks, resource exhaustion, cache misses, connection pool exhaustion, hot paths, excessive database queries
- **Common Mistakes**: N+1 queries, missing caching, not using connection pooling, synchronous operations where async possible, excessive memory allocation, not measuring before optimizing, premature optimization
- **Performance Anti-Patterns**: N+1 query problem, SELECT * in production, missing indexes, excessive database roundtrips, synchronous blocking operations, monolithic caches, cache stampede, thundering herd, hot spots
- **Related Patterns**: Caching strategies (write-through, write-back, cache-aside), Lazy loading vs Eager loading, Connection pooling, Event-driven architecture, Asynchronous processing, Message queues, Load balancing, Horizontal scaling, Vertical scaling
- **Problematic Patterns**: God cache (single monolithic cache), Cache without expiration, Over-caching (caching everything), Under-caching (not caching hot paths), Synchronous critical path, Blocking I/O, Memory leaks, Resource leaks, Connection leaks, File handle leaks
- **Algorithm Complexity**: Big O notation analysis (O(1), O(log n), O(n), O(n log n), O(n^2), O(2^n)), Time complexity, Space complexity, Common complexity pitfalls, Sorting algorithms, Searching algorithms, Graph algorithms, Dynamic programming, Greedy algorithms
- **Resource Management**: Memory management, Connection pooling, File handle management, Thread pool management, Socket management, Buffer management, Garbage collection tuning, Resource limits, Memory profiling, Heap dump analysis
- **Caching Strategies**: Cache-aside (lazy loading), Write-through, Write-back (write-behind), Refresh-ahead, Multi-level caching, Cache invalidation strategies, Cache warming, Cache eviction policies (LRU, LFU, TTL-based)

## MODE DETECTION
- **WRITE Mode**: Keywords: ["create", "generate", "write", "build", "implement", "add", "new", "optimize", "cache", "implement caching", "add performance"]
- **REVIEW Mode**: Keywords: ["review", "analyze", "audit", "check", "find issues", "performance review", "bottleneck", "slow", "memory leak", "resource leak"]

## LOADING STRATEGY
### Write Mode (Progressive)
Load patterns based on performance requirements:
- Profiling questions -> Load `@profiling/PROFILING.md`
- Algorithm complexity -> Load `@profiling/ALGORITHM-COMPLEXITY.md`
- Caching questions -> Load `@caching/CACHING-STRATEGIES.md`
- Database performance -> Load `@database/CONNECTION-POOLING.md`, `@optimization/QUERY-OPTIMIZATION.md`
- Resource issues -> Load `@performance/RESOURCE-LEAKS.md`

### Review Mode (Exhaustive)
Load comprehensive checklists:
- IF performance review requested -> Load all performance patterns
- IF slow queries -> Load `@optimization/QUERY-OPTIMIZATION.md`
- IF memory issues -> Load `@performance/RESOURCE-LEAKS.md`, `@profiling/PROFILING.md`
- IF algorithm review -> Load `@profiling/ALGORITHM-COMPLEXITY.md`

### Progressive Loading (Write Mode)
- **IF** request mentions "profile", "bottleneck", "slow" -> READ FILE: `@profiling/PROFILING.md`
- **IF** request mentions "Big O", "complexity", "algorithm" -> READ FILE: `@profiling/ALGORITHM-COMPLEXITY.md`
- **IF** request mentions "cache", "caching", "redis", "memcached" -> READ FILE: `@caching/CACHING-STRATEGIES.md`
- **IF** request mentions "N+1", "slow query", "query optimization" -> READ FILE: `@optimization/QUERY-OPTIMIZATION.md`
- **IF** request mentions "connection pool", "pooling" -> READ FILE: `@database/CONNECTION-POOLING.md`
- **IF** request mentions "memory leak", "resource leak", "exhaustion" -> READ FILE: `@performance/RESOURCE-LEAKS.md`

### Comprehensive Loading (Review Mode)
- **IF** request mentions "performance review", "audit", "analyze" -> READ FILES: All performance patterns
- **IF** request mentions "slow application" -> Load profiling, caching, query optimization patterns
- **IF** request mentions "memory issues" -> Load resource leaks, profiling patterns

## CONTEXT DETECTION
### Language Detection
- **PHP**: PHP profiling tools (Xdebug, Blackfire, Tideways), OPcache, APCu
- **Python**: Python profiling (cProfile, py-spy, line_profiler), memory profiling (tracemalloc, memory_profiler)
- **JavaScript/Node.js**: Node.js profiling (Chrome DevTools, clinic.js, 0x), memory profiling (heap snapshots)
- **Java**: Java profiling (JProfiler, VisualVM, Java Mission Control), JMX
- **Go**: Go profiling (pprof, go tool pprof), go trace
- **Rust**: Rust profiling (flamegraph, perf)
- **C/C++**: C++ profiling (perf, gprof, valgrind)

### Caching Detection
- **Redis**: redis://, Redis clients (predis, redis-py, ioredis, go-redis)
- **Memcached**: memcache, memcached clients
- **OPcache**: PHP OPcache configuration
- **APCu**: PHP APCu
- **Varnish**: Varnish configuration, VCL
- **CDN**: Cloudflare, CloudFront, Akamai

### Database Detection
- **PostgreSQL**: PostgreSQL performance tuning, EXPLAIN ANALYZE, pg_stat_statements
- **MySQL**: MySQL performance tuning, EXPLAIN, Performance Schema, Slow Query Log
- **MongoDB**: MongoDB profiling, explain(), index optimization

### Framework Detection
- **Laravel**: Laravel caching (cache), Eloquent N+1, query scopes
- **Symfony**: Symfony caching, Doctrine profiling
- **Django**: Django caching, select_related, prefetch_related
- **Express**: Node.js caching, express-rate-limit
- **React**: React performance, useMemo, useCallback
- **Vue.js**: Vue.js performance, computed properties

## WHEN TO USE THIS SKILL
✅ Use when:
- Performance troubleshooting and optimization
- Profiling and bottleneck analysis
- Caching strategies and implementation
- Load testing and capacity planning
- Memory leak detection
- Resource leak detection (connections, file handles)
- Database query optimization
- Algorithm complexity analysis
- Connection pooling configuration
- N+1 query detection and fixing
- Resource exhaustion prevention

❌ Do NOT use when:
- Code architecture (use software-engineering)
- Security operations (use secops-engineering)
- Database design (use database-engineering)
- Infrastructure (use devops-engineering)

## EXECUTION PROTOCOL

### Phase 1: Clarification
1. **Detect Mode**: WRITE vs REVIEW based on keywords
2. **Detect Context**: Language, framework, caching layer, database
3. **Load Patterns**: Progressive (write) or Exhaustive (review)

### Phase 2: Planning
1. Load relevant performance pattern references
2. Profile application to identify bottlenecks
3. Analyze algorithm complexity
4. Implement caching strategies
5. Optimize database queries
6. Tune connection pools
7. Provide performance improvements

### Phase 3: Execution
1. Load all performance checklist references
2. Systematically check each category:
   - Profiling (bottlenecks, hot paths)
   - Caching (cache hits/misses, invalidation)
   - Database (N+1 queries, slow queries, missing indexes)
   - Resource leaks (memory, connections, file handles)
   - Algorithm complexity (Big O analysis)
3. Provide prioritized issues with severity levels
4. Recommend performance improvements

### Phase 4: Validation
- Verify performance improvements measured
- Check for regressions
- Validate caching strategy
- Ensure resource leaks fixed
- Check for cross-references (MUST be within skill only)


### Write Mode Output
```markdown
## Performance Optimization: [Component]

### Performance Issue
[Bottleneck or performance problem description]

### Profiling Results
- [CPU profile results]
- [Memory profile results]
- [Hot path analysis]

### Solution
[Performance optimization implementation]

### Expected Improvement
- [Performance metrics improvement]
- [Resource usage improvement]

### Related Patterns
@profiling/[specific-pattern].md
```

### Review Mode Output
```markdown
## Performance Review Report

### Critical Performance Issues
1. **[Issue Name]**: [Location: file:line]
   - Severity: CRITICAL
   - Category: [N+1/Resource Leak/Algorithm]
   - Description: [Issue details]
   - Impact: [Performance degradation]
   - Fix: [Recommended action]
   - Reference: @performance/[specific-pattern].md

### High Priority Issues
[Same format]

### Medium Priority Issues
[Same format]

### Low Priority Issues
[Same format]

### Recommendations
1. [Performance improvement]
2. [Caching strategy]
3. [Algorithm improvement]

