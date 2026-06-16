# N+1 QUERY DETECTION AND OPTIMIZATION

## OVERVIEW
N+1 query problem is a classic performance anti-pattern where executing N queries to fetch related data when 1 would suffice.

## THE PROBLEM

### Example: N+1 Queries

```php
// BAD: N+1 queries
$users = DB::table('users')->get();  // 1 query

foreach ($users as $user) {
    // N additional queries!
    $posts = DB::table('posts')
        ->where('user_id', $user->id)
        ->get();
}
// Total: 1 + N queries (N = number of users)
// If 100 users = 101 queries!
```

**Performance Impact**:
- Linear degradation as N increases
- Database load increases dramatically
- Response time grows with dataset size
- Network latency amplified (round-trip per query)

---

## SOLUTION STRATEGIES

### 1. Eager Loading (JOIN)

**Example (Raw SQL)**:
```sql
-- SECURE: Single query with JOIN
SELECT users.*, posts.*
FROM users
LEFT JOIN posts ON users.id = posts.user_id;
-- Total: 1 query regardless of N!
```

**Laravel (Eloquent)**:
```php
// BAD: N+1
$users = User::all();
foreach ($users as $user) {
    $posts = Post::where('user_id', $user->id)->get();
}

// SECURE: Eager loading with with()
$users = User::with('posts')->get();
// Executes 2 queries: SELECT users; SELECT posts WHERE user_id IN (1,2,3,...)

foreach ($users as $user) {
    // Posts already loaded, no additional query!
    $posts = $user->posts;
}
```

**Django**:
```python
# BAD: N+1
users = User.objects.all()
for user in users:
    posts = Post.objects.filter(user_id=user.id)

# SECURE: Eager loading with select_related()
users = User.objects.select_related('posts').all()
# Or prefetch_related() for many-to-many
users = User.objects.prefetch_related('posts').all()
```

**Sequelize (Node.js)**:
```javascript
// BAD: N+1
const users = await User.findAll();
for (const user of users) {
    const posts = await Post.findAll({ where: { userId: user.id } });
}

// SECURE: Eager loading with include()
const users = await User.findAll({
    include: [{
        model: Post,
        as: 'posts'
    }]
});
```

---

### 2. Batch Loading

**When**: Need to load large datasets in chunks.

**Example**:
```php
// SECURE: Batch loading with chunk()
User::chunk(100, function ($users) {
    foreach ($users as $user) {
        // Process 100 users at a time
    }
});
```

**SQL LIMIT/OFFSET**:
```sql
-- SECURE: Pagination
SELECT * FROM users
ORDER BY id
LIMIT 100 OFFSET 0;  -- First 100
```

---

### 3. Cache Query Results

**Example (Redis)**:
```php
// SECURE: Cache user posts
$posts = Cache::remember("user_posts:{$userId}", 3600, function () use ($userId) {
    return Post::where('user_id', $userId)->get();
});

// First request: database query, caches for 1 hour
// Subsequent requests: cache hit (no database query)
```

---

### 4. Lazy Loading with Pagination

**When**: Related data is rarely accessed.

**Example**:
```php
// SECURE: Lazy loading accessor
class User extends Model {
    protected $posts = null;

    public function getPosts() {
        if ($this->posts === null) {
            // Load on first access
            $this->posts = Post::where('user_id', $this->id)->get();
        }
        return $this->posts;
    }
}

// Usage: Posts loaded only when accessed
$user = User::find($userId);
// Posts NOT loaded yet

$user->getPosts();  // Posts loaded now
```

---

## DETECTING N+1 QUERIES

### 1. Query Logging

**Laravel**:
```php
// Enable query logging
DB::listen(function ($query, $bindings, $time) {
    Log::info($query->sql, ['bindings' => $bindings, 'time' => $time]);
});

// Look for repeated queries in logs
```

**Django Debug Toolbar**:
```python
# Django Debug Toolbar shows N+1 queries in real-time
# Shows duplicate queries, number of queries, query time
```

**MySQL Slow Query Log**:
```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;  -- Log queries > 1 second

-- Check for patterns
-- Query executed N times for N users
```

---

### 2. Automated Detection Tools

**Laravel N+1 Detector**:
```bash
# Install package
composer require --dev beyondcode/laravel-query-detector

# Run detection
php artisan query-detector

# Output
# Found 1 N+1 query in app/Http/Controllers/UserController.php
#   Line 15: Call to Post::where() inside loop
```

**N+1 Query Detector (General)**:
```javascript
// Node.js package
const nplus1 = require('n-plus-one-detector');

nplus1.detect('./app', {
    include: ['**/*.php', '**/*.js'],
    exclude: ['**/vendor/**']
});
```

---

### 3. Monitoring

**Application Performance Monitoring (APM)**:
- New Relic: Detects repeated database queries
- Datadog: Monitors query patterns and N+1 issues
- Scout: Laravel-specific monitoring for N+1 queries

---

## PREVENTION CHECKLIST

### Before Development
- [ ] Use ORM eager loading (with(), include(), etc.)
- [ ] Use JOIN for related data
- [ ] Implement pagination for large datasets
- [ ] Cache frequently accessed data
- [ ] Use batch operations instead of loops
- [ ] Review queries in code review
- [ ] Use query analysis tools during development

### Before Deployment
- [ ] Run N+1 detection tools on codebase
- [ ] Enable query logging in staging
- [ ] Load test with realistic data volumes
- [ ] Profile database queries (EXPLAIN)
- [ ] Verify no N+1 queries in critical paths
- [ ] Set up APM monitoring for production

### Ongoing
- [ ] Monitor slow query log for N+1 patterns
- [ ] Set alerts for high query counts per request
- [ ] Regularly review APM dashboards for N+1 issues
- [ ] Benchmark database performance after changes
- [ ] Analyze query patterns in production logs

---

## PERFORMANCE COMPARISON

| Approach | Queries (N=100) | Time (ms) | Scalability |
|---------|------------------|-----------|-------------|
| N+1 (loop) | 101 | 1010 | O(n) - Degrades linearly |
| Eager Loading (JOIN) | 1 | 10 | O(1) - Constant time |
| Eager Loading (with()) | 2 | 20 | O(1) - Constant time |
| Batch Loading (chunks of 10) | 10 | 100 | O(n/10) - Better than N+1 |
| Cached | 0 (after first) | 1 | O(1) - Best |

---

## COMMON PATTERNS CAUSING N+1

### 1. Loop Queries
```php
// BAD: Query in loop
foreach ($orders as $order) {
    $user = User::find($order->user_id);  // N queries
}

// SECURE: Eager loading
$orders = Order::with('user')->get();  // 2 queries
```

### 2. Lazy Loading in Views
```php
// BAD: Implicit lazy loading
@foreach ($orders as $order)
    {{ $order->user->name }}  <!-- N queries! -->
@endforeach

// SECURE: Eager loading before view
$orders = Order::with('user')->get();
```

### 3. Nested Loops
```php
// BAD: Nested loops = N*M queries
foreach ($users as $user) {
    foreach ($user->posts as $post) {
        $comments = Comment::where('post_id', $post->id)->get();  // N*M queries!
    }
}

// SECURE: Eager loading at all levels
$users = User::with(['posts.comments'])->get();  // 3 queries
```

---

## CROSS-REFERENCES
- For query optimization: @database-engineering/relational/INDEXING.md
- For connection pooling: @database-engineering/connections/CONNECTION-PATTERNS.md
- For performance issues: @software-engineering/performance/COMMON-ISSUES.md
