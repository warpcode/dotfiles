# COMMON PERFORMANCE ISSUES

## OVERVIEW
Performance issues degrade application responsiveness, increase resource usage, and cause poor user experience. This guide covers common performance problems and their solutions.

## 1. MEMORY LEAKS

**Definition**: Application fails to release memory that's no longer needed, causing gradual memory exhaustion.

### PHP Example (Circular References)
```php
// BAD: Circular reference prevents garbage collection
class Parent {
    public $child;
}

class Child {
    public $parent;
}

$parent = new Parent();
$child = new Child();

$parent->child = $child;
$child->parent = $parent;  // Circular reference!

unset($parent, $child);  // Memory NOT freed!
```

**Fix**: Break references explicitly
```php
// GOOD: Break circular references before unsetting
$parent->child = null;
$child->parent = null;
unset($parent, $child);
```

### JavaScript Example (Event Listeners)
```javascript
// BAD: Event listeners not removed
document.getElementById('button').addEventListener('click', handler);

// If component re-renders without cleanup, old listeners accumulate
```

**Fix**: Cleanup event listeners
```javascript
// GOOD: Store and remove listeners
const handler = () => { /* ... */ };
const button = document.getElementById('button');
button.addEventListener('click', handler);

// Cleanup when component unmounts
button.removeEventListener('click', handler);
```

**Detection**:
- Memory profiling tools (Xdebug for PHP, Chrome DevTools for JS)
- Monitor memory growth over time
- Look for constant memory increase

---

## 2. RESOURCE EXHAUSTION

**Definition**: Application consumes resources (file handles, database connections) without releasing them.

### Database Connection Leaks (PHP)
```php
// BAD: Connections not closed
function getData() {
    $db = new PDO('mysql:host=localhost;dbname=test', 'user', 'pass');
    $result = $db->query('SELECT * FROM users');
    return $result->fetchAll();
    // Connection not closed!
}

// Many calls = many open connections = connection pool exhaustion
```

**Fix**: Use connection pooling or explicit cleanup
```php
// GOOD: Connection explicitly closed
function getData() {
    $db = new PDO('mysql:host=localhost;dbname=test', 'user', 'pass');
    $result = $db->query('SELECT * FROM users');
    $data = $result->fetchAll();
    $db = null;  // Close connection
    return $data;
}

// BETTER: Use connection pooling
function getData(PDO $db) {
    $result = $db->query('SELECT * FROM users');
    return $result->fetchAll();
}
```

### File Handle Leaks (Python)
```python
# BAD: File handles not closed
def read_file(filename):
    f = open(filename)
    data = f.read()
    # Handle not closed!
    return data
```

**Fix**: Use context managers
```python
# GOOD: Context manager ensures cleanup
def read_file(filename):
    with open(filename) as f:
        return f.read()  # File automatically closed
```

**Detection**:
- Monitor open file descriptors (`lsof -p <pid>`)
- Monitor database connection pool usage
- Check for "too many open files" errors

---

## 3. N+1 QUERY PROBLEM

**Definition**: Executing N+1 database queries when 1 would suffice.

### Example
```php
// BAD: N+1 queries
$users = $db->query("SELECT * FROM users")->fetchAll();
foreach ($users as $user) {
    // Additional query for each user!
    $posts = $db->query("SELECT * FROM posts WHERE user_id = {$user['id']}")->fetchAll();
    // If 100 users = 1 + 100 queries!
}
```

**Impact**:
- Linear performance degradation as N increases
- Database load increases dramatically
- Response time grows with dataset size

**Fix 1**: JOIN
```php
// GOOD: 1 query with JOIN
$users = $db->query("
    SELECT users.*, posts.*
    FROM users
    LEFT JOIN posts ON users.id = posts.user_id
")->fetchAll();

// Group posts by user
$usersWithPosts = [];
foreach ($users as $row) {
    $userId = $row['id'];
    if (!isset($usersWithPosts[$userId])) {
        $usersWithPosts[$userId] = [
            'id' => $row['id'],
            'name' => $row['name'],
            'posts' => []
        ];
    }
    $usersWithPosts[$userId]['posts'][] = [
        'id' => $row['post_id'],
        'title' => $row['post_title']
    ];
}
```

**Fix 2**: Eager Loading (Laravel)
```php
// GOOD: Eager loading with Eloquent
$users = User::with('posts')->get();  // 2 queries total
// SELECT * FROM users
// SELECT * FROM posts WHERE user_id IN (1, 2, 3, ...)
```

**Detection**:
- Query logging/database profiler
- Look for repeated queries in loops
- Monitor query count per request

---

## 4. INEFFICIENT ALGORITHMS

**Definition**: Using algorithms with poor time complexity (O(n²), O(n³)) when better ones exist (O(n), O(n log n)).

### Example: Nested Loops (O(n²))
```php
// BAD: O(n²) - nested loops
function findDuplicates($array) {
    $duplicates = [];
    $count = count($array);

    for ($i = 0; $i < $count; $i++) {
        for ($j = $i + 1; $j < $count; $j++) {
            if ($array[$i] === $array[$j]) {
                $duplicates[] = $array[$i];
                break;
            }
        }
    }
    return $duplicates;
}

// For 10,000 items = 100 million comparisons!
```

**Fix**: Hash Map (O(n))
```php
// GOOD: O(n) - single pass with hash map
function findDuplicates($array) {
    $seen = [];
    $duplicates = [];

    foreach ($array as $item) {
        if (isset($seen[$item])) {
            $duplicates[] = $item;
        } else {
            $seen[$item] = true;
        }
    }

    return $duplicates;
}

// For 10,000 items = 10,000 operations (10,000x faster!)
```

### Example: String Concatenation in Loop (O(n²))
```php
// BAD: O(n²) - string concatenation in loop
function buildString($array) {
    $result = '';
    foreach ($array as $item) {
        $result .= $item;  // Creates new string each time!
    }
    return $result;
}
```

**Fix**: Array join (O(n))
```php
// GOOD: O(n) - array join
function buildString($array) {
    return implode('', $array);
}
```

**Detection**:
- Profile code execution time
- Look for nested loops
- Check time complexity of algorithms
- Use Big O analysis

---

## 5. MISSING INDEXES

**Definition**: Database queries without proper indexes causing full table scans.

### Example
```sql
-- BAD: Full table scan without index
SELECT * FROM users WHERE email = 'john@example.com';
-- Scans entire table even if only 1 row matches!

-- Query takes: 10ms with 10,000 rows
-- Time increases linearly with table size
```

**Fix**: Add index
```sql
-- GOOD: Index lookup
CREATE INDEX idx_users_email ON users(email);

-- Query takes: 0.1ms (100x faster!)
-- Time constant regardless of table size
```

**Detection**:
- Use `EXPLAIN` to analyze query execution plan
- Look for "type: ALL" (full table scan)
- Monitor slow query logs
- Use database profiling tools

---

## 6. SYNCHRONOUS BLOCKING OPERATIONS

**Definition**: Blocking I/O operations that prevent concurrent processing.

### Example: Synchronous File I/O
```php
// BAD: Synchronous file reading blocks entire process
function processFiles($files) {
    foreach ($files as $file) {
        $data = file_get_contents($file);  // Blocks!
        processData($data);
    }
}

// Total time = sum of all file reads (sequential)
```

**Fix**: Async Operations (JavaScript)
```javascript
// GOOD: Async operations run concurrently
async function processFiles(files) {
    const promises = files.map(async (file) => {
        const data = await readFile(file);  // Non-blocking!
        return processData(data);
    });
    return Promise.all(promises);  // All run concurrently
}

// Total time = max of all file reads (concurrent)
```

---

## 7. INEFFICIENT CACHING

**Definition**: Not caching or caching incorrectly, causing repeated expensive operations.

### Example: No Caching
```php
// BAD: Expensive operation called every time
function getUserStats($userId) {
    // Complex query takes 500ms
    return $db->query("
        SELECT COUNT(*) as orders,
               SUM(amount) as total_spent
        FROM orders
        WHERE user_id = $userId
    ")->fetch();
}

// 100 requests = 50 seconds total!
```

**Fix**: Cache Results
```php
// GOOD: Cache results
function getUserStats($userId) {
    $cacheKey = "user_stats:$userId";

    if (Cache::has($cacheKey)) {
        return Cache::get($cacheKey);  // 1ms
    }

    $stats = $db->query("...")->fetch();
    Cache::put($cacheKey, $stats, 3600);  // 1 hour
    return $stats;
}

// First request: 500ms, subsequent: 1ms
```

---

## 8. UNNECESSARY DATA TRANSFER

**Definition**: Transferring more data than needed over network.

### Example: SELECT *
```php
// BAD: Fetches all columns
$users = $db->query("SELECT * FROM users")->fetchAll();

// Fetches 20 columns when only 2 needed!
// Increases memory usage and network transfer
```

**Fix**: SELECT Specific Columns
```php
// GOOD: Fetches only needed columns
$users = $db->query("SELECT id, name FROM users")->fetchAll();

// Reduces data transfer by 90%
```

---

## DETECTION TOOLS

### PHP
- Xdebug (profiling)
- Blackfire (performance profiling)
- Tideways (performance monitoring)

### JavaScript
- Chrome DevTools (Performance tab)
- Lighthouse (performance audit)
- WebPageTest (load testing)

### Python
- cProfile (profiling)
- Py-Spy (sampling profiler)
- Memory Profiler (memory analysis)

### Database
- EXPLAIN (query analysis)
- Slow query logs
- Performance Schema (MySQL)

---

## CROSS-REFERENCES
- For database N+1 patterns: @database-engineering/relational/NPLUS1.md
- For algorithm complexity: @performance-engineering/profiling/ALGORITHM-COMPLEXITY.md
- For connection pooling: @performance-engineering/database/CONNECTION-POOLING.md
- For resource leaks: @performance-engineering/performance/RESOURCE-LEAKS.md
