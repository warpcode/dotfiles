# Database Query Bottlenecks

Diagnostic guide for identifying database performance bottlenecks, N+1 queries, and indexing deficiencies.

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

## 2. Missing Database Indexes

### High-Risk Indicators
- Foreign keys without indexes (causes table scans on join operations).
- Columns frequently used in `WHERE`, `ORDER BY`, `GROUP BY`, or `JOIN` conditions lacking index coverage.
- Multi-column queries where composite index column order does not match left-prefix rule.

### Remediation
Ensure migration files include explicit index declarations:
```php
$table->foreignId('user_id')->constrained()->index();
$table->index(['account_id', 'created_at']); // Composite index for filtered sorting
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

## 4. Database Connection Lifecycle & Connection Pooling

### Persistent Connection Anti-Patterns
- In containerized PHP (FPM) or serverless runtimes (AWS Lambda), enabling persistent connections (`PDO::ATTR_PERSISTENT => true`) causes connection accumulation across worker lifecycles, quickly exhausting the database max connection limit (`too many connections`).
- In short-lived, auto-scaling instances, persistent connections survive across requests within worker processes but are abruptly abandoned when containers scale down.

### Connection Pooling Architecture
- Use dedicated connection poolers (such as **PgBouncer** for PostgreSQL in transaction pooling mode, or **ProxySQL** for MySQL) between application workers and database servers.
- Configure aggressive idle connection reaping and connection timeouts on poolers to prevent worker connection leaks.
- Size application connection pool limits to `(core_count * 2) + disk_spindle_count` rather than 1:1 per web concurrency worker.

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


