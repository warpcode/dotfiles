# Resource Leaks Detection

**Purpose**: Guide for detecting and fixing resource leaks (memory, connections, file handles, etc.)

## TYPES OF RESOURCE LEAKS

### Memory Leaks
- **Definition**: Program allocates memory but never releases it
- **Symptoms**: Increasing memory usage, eventual OOM kill
- **Common Causes**: 
  - Unreleased references
  - Circular references
  - Caches without expiration
  - Event listeners not removed
  - Closures capturing large objects
  - Static variables growing indefinitely

### Connection Leaks
- **Definition**: Database connections, HTTP connections not released
- **Symptoms**: Connection pool exhaustion, connection timeouts
- **Common Causes**:
  - Not closing connections in finally blocks
  - Exceptions bypassing close() calls
  - Connection pooling misconfiguration
  - Long-running transactions

### File Handle Leaks
- **Definition**: File descriptors not closed
- **Symptoms**: "Too many open files" errors
- **Common Causes**:
  - Not closing files after use
  - Opening files in loops without closing
  - Exceptions preventing close()
  - Not using context managers

### Thread/Process Leaks
- **Definition**: Threads/processes created but never terminated
- **Symptoms**: Increasing thread count, high CPU usage
- **Common Causes**:
  - Threads not terminated after work
  - Thread pools not bounded
  - Deadlocks preventing thread termination
  - Orphaned processes

### Socket Leaks
- **Definition**: Network sockets not closed
- **Symptoms**: Socket exhaustion, connection timeouts
- **Common Causes**:
  - Not closing sockets
  - Socket cleanup on exceptions
  - Keep-alive connections not closed

### Buffer Leaks
- **Definition**: Allocated buffers not released
- **Symptoms**: Memory growth, allocation failures
- **Common Causes**:
  - Byte buffers not released
  - Direct buffer leaks
  - Buffer pools not returned

## DETECTION METHODS

### Memory Leak Detection

#### PHP
```php
// Use memory_get_usage() to track memory
$initial = memory_get_usage(true);

// Run code
for ($i = 0; $i < 1000; $i++) {
    process_data($data);
}

$final = memory_get_usage(true);
$leaked = $final - $initial;

if ($leaked > 1000000) { // > 1MB
    echo "Potential memory leak: " . ($leaked / 1024 / 1024) . " MB\n";
}
```

#### Python
```python
import tracemalloc

# Start tracking
tracemalloc.start()

# Run code
for i in range(1000):
    process_data(data)

# Get snapshot
snapshot = tracemalloc.take_snapshot()

# Find top allocations
top_stats = snapshot.statistics('lineno')

for stat in top_stats[:10]:
    print(stat)
```

#### Node.js
```javascript
// Use heap snapshots
const v8 = require('v8');

// Initial heap
const heap1 = v8.getHeapStatistics();

// Run code
for (let i = 0; i < 1000; i++) {
    process_data(data);
}

// Final heap
const heap2 = v8.getHeapStatistics();

const leaked = heap2.used_heap_size - heap1.used_heap_size;
if (leaked > 1024 * 1024) {
    console.log(`Potential leak: ${leaked / 1024 / 1024} MB`);
}
```

#### Java
```java
// Use VisualVM or JConsole
// Or programmatically:

Runtime runtime = Runtime.getRuntime();
long before = runtime.totalMemory() - runtime.freeMemory();

// Run code
for (int i = 0; i < 1000; i++) {
    process_data(data);
}

long after = runtime.totalMemory() - runtime.freeMemory();
long leaked = after - before;

if (leaked > 1024 * 1024) {
    System.out.println("Potential leak: " + (leaked / 1024 / 1024) + " MB");
}
```

### Connection Leak Detection

#### Database Connections
```python
# Check connection pool status
from sqlalchemy import create_engine

engine = create_engine('postgresql://...')
pool = engine.pool

print(f"Pool size: {pool.size()}")
print(f"Checked out: {pool.checkedout()}")
print(f"Overflow: {pool.overflow()}")

if pool.overflow() > 0:
    print("WARNING: Connection leak detected!")
```

#### HTTP Connections
```python
import requests
from requests.adapters import HTTPAdapter

s = requests.Session()

# Check active connections
for prefix, adapter in s.adapters.items():
    if hasattr(adapter, 'poolmanager'):
        pool = adapter.poolmanager.connection_from_url(prefix)
        print(f"Pool: {pool.pool.qsize()} available, {pool.num_connections} total")
```

### File Handle Leak Detection

#### Linux
```bash
# Check open file descriptors for process
lsof -p <PID> | wc -l

# Monitor over time
watch -n 1 "lsof -p <PID> | wc -l"

# Find unclosed files
lsof -p <PID> | grep ".*DEL.*"
```

#### Python
```python
# Use psutil to check open files
import psutil
import os

proc = psutil.Process(os.getpid())

try:
    open_files = proc.open_files()
    print(f"Open files: {len(open_files)}")
    
    if len(open_files) > 100:
        print("WARNING: Possible file handle leak!")
except psutil.AccessDenied:
    print("Access denied to process info")
```

### Socket Leak Detection

#### Linux
```bash
# Check open sockets for process
ss -tulnp | grep <PID>

# Monitor over time
watch -n 1 "ss -tulnp | grep <PID>"

# Check socket count
netstat -an | grep <PID> | wc -l
```

#### Python
```python
# Use psutil to check connections
import psutil
import os

proc = psutil.Process(os.getpid())

try:
    connections = proc.connections()
    print(f"Connections: {len(connections)}")
    
    if len(connections) > 50:
        print("WARNING: Possible socket leak!")
except psutil.AccessDenied:
    print("Access denied to process info")
```

## PREVENTION STRATEGIES

### Memory Leak Prevention

#### Use Context Managers (Python)
```python
# Bad: Memory leak
def process_large_file(filename):
    data = []
    with open(filename) as f:
        for line in f:
            data.append(line)
    # data not released

# Good: Process and release
def process_large_file(filename):
    with open(filename) as f:
        for line in f:
            yield process_line(line)  # Generator, releases memory
```

#### Clear Caches
```python
from functools import lru_cache

# Bad: Unbounded cache
@lru_cache(maxsize=None)
def expensive_function(x):
    return compute(x)

# Good: Bounded cache with TTL
@lru_cache(maxsize=1024)
def expensive_function(x):
    return compute(x)
```

#### Remove Event Listeners
```javascript
// Bad: Event listener never removed
document.addEventListener('click', handler);

// Good: Remove when done
const handler = () => { /* ... */ };
document.addEventListener('click', handler);
// Later:
document.removeEventListener('click', handler);
```

#### Avoid Closures Capturing Large Objects
```javascript
// Bad: Closure captures large object
function createHandler(largeData) {
    return function() {
        console.log(largeData.id);  // Captures entire largeData
    };
}

// Good: Only capture needed data
function createHandler(largeData) {
    const id = largeData.id;  // Only capture id
    return function() {
        console.log(id);
    };
}
```

### Connection Leak Prevention

#### Use Connection Pooling
```python
# Bad: New connection each time
def query(sql):
    conn = psycopg2.connect(dsn)
    cursor = conn.cursor()
    cursor.execute(sql)
    conn.close()

# Good: Use connection pool
from psycopg2 import pool
connection_pool = pool.SimpleConnectionPool(1, 10, dsn)

def query(sql):
    conn = connection_pool.getconn()
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        connection_pool.putconn(conn)
```

#### Always Use try-finally
```python
# Bad: Exception prevents close
def query(sql):
    conn = psycopg2.connect(dsn)
    cursor = conn.cursor()
    cursor.execute(sql)
    conn.close()  # Never reached if exception

# Good: Finally ensures close
def query(sql):
    conn = psycopg2.connect(dsn)
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        return cursor.fetchall()
    finally:
        conn.close()
```

### File Handle Leak Prevention

#### Use Context Managers
```python
# Bad: File not closed on exception
def process_file(filename):
    f = open(filename)
    data = f.read()
    process(data)
    f.close()  # Never reached if exception

# Good: Context manager ensures close
def process_file(filename):
    with open(filename) as f:
        data = f.read()
    process(data)
    # File automatically closed
```

#### Limit Open Files
```python
# Good: Use limit and wait
import threading

 semaphore = threading.Semaphore(10)  # Max 10 open files

def process_file(filename):
    with semaphore:
        with open(filename) as f:
            data = f.read()
            process(data)
```

### Thread Leak Prevention

#### Use Thread Pools
```python
# Bad: New thread for each task
for task in tasks:
    threading.Thread(target=process, args=(task,)).start()

# Good: Use thread pool
from concurrent.futures import ThreadPoolExecutor

with ThreadPoolExecutor(max_workers=10) as executor:
    futures = [executor.submit(process, task) for task in tasks]
    for future in futures:
        result = future.result()
```

#### Always Join Threads
```python
# Bad: Thread not joined
def start_worker():
    t = threading.Thread(target=worker_loop)
    t.start()
    # Thread never joined, becomes orphaned

# Good: Join thread
def start_worker():
    t = threading.Thread(target=worker_loop)
    t.start()
    t.join()  # Wait for thread to finish
```

## COMMON LEAK PATTERNS

### Circular References
```python
# Bad: Circular reference prevents GC
class Node:
    def __init__(self):
        self.next = None
        self.prev = None

node1 = Node()
node2 = Node()
node1.next = node2
node2.prev = node1  # Circular reference

# Good: Break cycle when done
node1.next = None
node2.prev = None
```

### Unreleased Listeners
```javascript
// Bad: Event listener never removed
function setup() {
    element.addEventListener('click', handler);
    // Element or handler never cleaned up
}

// Good: Remove listener
function setup() {
    const handler = () => { /* ... */ };
    element.addEventListener('click', handler);
    
    // Cleanup function
    return () => {
        element.removeEventListener('click', handler);
    };
}

const cleanup = setup();
// Later:
cleanup();
```

### Caches Without Expiration
```python
# Bad: Cache grows indefinitely
cache = {}

def expensive_computation(key):
    if key not in cache:
        cache[key] = compute(key)  # Never expires
    return cache[key]

# Good: Cache with TTL
import time

cache = {}

def expensive_computation(key, ttl=3600):
    if key in cache and time.time() - cache[key]['timestamp'] < ttl:
        return cache[key]['value']
    
    result = compute(key)
    cache[key] = {'value': result, 'timestamp': time.time()}
    return result
```

## TOOLS FOR LEAK DETECTION

### PHP
- **Xdebug**: Memory profiling
- **Blackfire**: Memory tracking
- **Memory_get_usage()**: Built-in memory functions

### Python
- **tracemalloc**: Memory tracking
- **memory_profiler**: Line-by-line memory profiling
- **objgraph**: Object graph visualization
- **gc**: Garbage collector inspection
- **psutil**: Process and system utilities

### Node.js
- **Chrome DevTools**: Heap snapshots
- **clinic.js**: Memory profiling
- **heapdump**: Node.js heap dumps
- **v8.getHeapStatistics()**: Heap statistics

### Java
- **VisualVM**: Memory profiling
- **JConsole**: Monitoring
- **jcmd**: Command-line tools
- **MAT (Memory Analyzer Tool)**: Heap dump analysis

### Go
- **pprof**: Memory profiling
- **runtime**: Runtime statistics
- **GODEBUG**: Garbage collector debugging

### C/C++
- **valgrind**: Memory leak detection
- **AddressSanitizer**: Memory error detector
- **gperftools**: Performance and memory profiling
