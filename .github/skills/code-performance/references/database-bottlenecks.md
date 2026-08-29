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

