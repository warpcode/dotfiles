# Database & Network Bottlenecks

Diagnostic guide for identifying database performance bottlenecks, N+1 queries, indexing deficiencies, socket exhaustion, and runtime profiling.

---

## 1. N+1 Query Anti-Pattern

### Detection
The N+1 problem occurs when an application loads a collection of `N` parent entities and then executes `1` separate query per parent to fetch child relationships inside a loop.

### Inefficient Example
```php
// Executes 1 query for orders, then N queries for user on each iteration
$orders = Order::where('status', 'completed')->get();
foreach ($orders as $order) {
    echo $order->user->name; // Query on every loop!
}
```

### Remediation: Eager Loading
Eager load relationships in a single batch query:
```php
$orders = Order::with('user')->where('status', 'completed')->get();
foreach ($orders as $order) {
    echo $order->user->name; // In-memory relationship access
}
```

---

## 2. Database Indexes & Advanced Indexing Strategies

### High-Risk Indicators
- Foreign keys without indexes (causes table scans on join operations).
- Columns frequently used in `WHERE`, `ORDER BY`, `GROUP BY`, or `JOIN` conditions lacking index coverage.
- Multi-column queries where composite index column order does not match left-prefix rule.

### Standard Indexes
```php
$table->foreignId('user_id')->constrained()->index();
$table->index(['account_id', 'created_at']); // Composite index for filtered sorting
```

### Partial / Filtered Indexes
Index only a subset of rows meeting a predicate (`WHERE` clause) to reduce index size and write overhead:

```sql
-- Index only active subscriptions (ignores millions of cancelled/expired rows)
CREATE INDEX idx_active_subscriptions ON subscriptions (user_id, plan_id)
WHERE status = 'active';

-- Soft-delete filtering: index only non-deleted records
CREATE INDEX idx_users_email_active ON users (email)
WHERE deleted_at IS NULL;
```

### Covering Indexes (`INCLUDE` Clause)
Store non-search payload columns directly in leaf nodes of the B-Tree to enable **Index-Only Scans** without visiting table heap pages:

```sql
-- Search key is (user_id, status); payload (total_price, created_at) included in leaf nodes
CREATE INDEX idx_orders_user_status_covering
ON orders (user_id, status)
INCLUDE (total_price, created_at);

-- Query satisfied entirely by index without table heap lookups:
SELECT user_id, status, total_price, created_at
FROM orders
WHERE user_id = 100 AND status = 'completed';
```

### PostgreSQL Index Hygiene Query
Detect unused or rarely scanned indexes consuming disk space and slowing down write operations:

```sql
SELECT
    schemaname || '.' || relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS number_of_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
WHERE indisunique IS FALSE
  AND idx_scan < 50
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## 3. Unbounded Queries & Result Sets

### Inefficient Example
```php
// Loads 100,000 records into PHP/process memory at once
$users = User::all();
```

### Remediation
Use cursor pagination or chunked streaming for large data sets:
```php
// Cursor pagination for APIs
$users = User::cursorPaginate(25);

// Chunking for batch background processing
User::chunk(500, function ($users) {
    foreach ($users as $user) {
        $user->process();
    }
});
```

---

## 4. Connection Lifecycle & Socket Pooling

### Database Connection Pooling Architecture
- In containerized PHP (FPM) or serverless runtimes (AWS Lambda), enabling persistent connections (`PDO::ATTR_PERSISTENT => true`) causes connection accumulation across worker lifecycles, quickly exhausting the database max connection limit (`too many connections`).
- Use dedicated connection poolers (such as **PgBouncer** for PostgreSQL in transaction pooling mode, or **ProxySQL** for MySQL) between application workers and database servers.
- Configure aggressive idle connection reaping and connection timeouts on poolers to prevent worker connection leaks.
- Size application connection pool limits to `(core_count * 2) + disk_spindle_count` rather than 1:1 per web concurrency worker.

### HTTP / Socket Keep-Alive Connection Pooling

Without keep-alive connection pooling, every outgoing HTTP request initiates a new TCP 3-way handshake + TLS negotiation. Under high throughput, closed connections linger in `TIME_WAIT` state (typically 60s), exhausting ephemeral ports and causing `EADDRNOTAVAIL` / socket starvation.

#### Node.js (`http.Agent` / `https.Agent`)
```javascript
const http = require('http');
const https = require('https');
const axios = require('axios');

// Reuse TCP connections across requests
const httpAgent = new http.Agent({
  keepAlive: true,
  maxSockets: 50,
  maxFreeSockets: 10,
  timeout: 60000,
});

const httpsAgent = new https.Agent({
  keepAlive: true,
  maxSockets: 50,
  maxFreeSockets: 10,
  timeout: 60000,
});

const apiClient = axios.create({
  httpAgent,
  httpsAgent,
  timeout: 5000,
});
```

#### Python (`requests.Session` + `HTTPAdapter`)
```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

session = requests.Session()
adapter = HTTPAdapter(
    pool_connections=20,  # Number of connection pools to cache
    pool_maxsize=50,       # Maximum connections to save in each pool
    max_retries=Retry(total=3, backoff_factor=0.5, status_forcelist=[500, 502, 503, 504])
)
session.mount('https://', adapter)
session.mount('http://', adapter)
```

---

## 5. Search Engine Query Profiling (Elasticsearch / OpenSearch)

### Query Scoring Overhead vs Filter Context
- **Scoring Overhead**: Using `must` or `should` clauses computes TF/IDF or BM25 relevance scores for every document, increasing CPU consumption and disabling caching.
- **Filter Context**: Wrap exact matches, status flags, and date/numeric ranges in `filter` context. Filter clauses skip scoring and are automatically cached in Elasticsearch/OpenSearch bitsets.

```json
// Inefficient: Scored query for exact matches
{
  "query": {
    "must": [
      { "term": { "status": "active" } }
    ]
  }
}

// Optimized: Filter context (cached, no scoring overhead)
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "status": "active" } }
      ]
    }
  }
}
```

### Leading Wildcard Performance Traps
- Wildcard queries starting with a wildcard (e.g. `*pattern` or `.*pattern` regex) cannot use the inverted index and force an exhaustive scan across all terms in the index dictionary.
- **Remediation**: Use `edge_ngram` tokenizers, reverse token filters for suffix search, or completion suggesters for prefix/autocomplete queries.

### Deep Pagination Traps (`from` + `size`)
- Using `from + size > 10,000` forces each shard to allocate, sort, and serialize all `from + size` documents before the coordinating node reduces them, causing massive memory spikes and cluster instability.
- **Remediation**: Use `search_after` with tie-breaker sorting (`_shard_doc` or `_id`) for cursor-based deep pagination, or `point_in_time` (PIT) with `search_after` for consistent snapshot pagination.

---

## 6. Runtime Profilers Tooling Matrix

| Runtime / Ecosystem | Tool | Type | Key Capabilities & Use Cases | Command / Invocation |
| :--- | :--- | :--- | :--- | :--- |
| **Node.js** | `clinic.js` | Diagnostic Suite | Identifies event loop lag, I/O bottlenecks (Bubbleprof), CPU hotspots (Flame), memory leaks (Doctor). | `npx clinic flame -- node server.js` |
| **Node.js** | `0x` | Profiler | Generates interactive flamegraphs of V8 stacks and CPU consumption. | `npx 0x server.js` |
| **Python** | `py-spy` | Sampling Profiler | Low-overhead sampling profiler capable of attaching to running production processes without restart. | `py-spy record -o profile.svg --pid <PID>` |
| **Python** | `cProfile` | Deterministic | Built-in module profiling exact function call counts and cumulative execution time. | `python -m cProfile -s cumtime script.py` |
| **Go** | `pprof` | Profiler | Built-in runtime CPU, heap memory, goroutine blocking, and mutex contention profiling. | `go tool pprof http://localhost:6060/debug/pprof/profile` |
| **PHP** | `Blackfire` | APM / Profiler | Production-grade deterministic profiling for CPU, memory, I/O, and database query timeline. | `blackfire curl https://api.local/endpoint` |
| **PHP** | `Xdebug` | Profiler | Generates cachegrind/callgrind trace files for offline visual analysis in KCacheGrind / QCacheGrind. | `php -d xdebug.mode=profile script.php` |
| **Linux** | `perf` | System Profiler | Kernel and userspace hardware performance counters, CPU cycle attribution, cache miss profiling. | `perf record -F 99 -g -p <PID> -- sleep 30` |
