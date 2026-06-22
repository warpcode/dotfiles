# CONNECTION PATTERNS

## OVERVIEW
Database connection management is critical for performance, reliability, and resource usage.

## CONNECTION POOLING

### Benefits
- Reduced connection overhead (expensive to establish)
- Better performance under load
- Control over maximum connections
- Prevents connection leaks
- Improved resource utilization

### Connection Pool Settings

### Laravel (PHP)

**Configuration**:
```php
// config/database.php
return [
    'default' => [
        'driver' => 'mysql',
        'host' => env('DB_HOST', '127.0.0.1'),
        'port' => env('DB_PORT', '3306'),
        'database' => env('DB_DATABASE', 'forge'),
        'username' => env('DB_USERNAME', 'forge'),
        'password' => env('DB_PASSWORD', ''),
        'pool' => [
            'max_connections' => env('DB_POOL_MAX', 100),
            'min_connections' => env('DB_POOL_MIN', 10),
        ],
    ],
];
```

**Best Practices**:
- Max connections = (CPU cores × 2) + effective spindles
- Min connections = 25% of max connections
- Test with production load

---

### SQLAlchemy (Python)

**Configuration**:
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Create engine with connection pool
engine = create_engine(
    'postgresql://user:password@localhost/dbname',
    poolclass=QueuePool,
    pool_size=10,  # Max connections
    max_overflow=5,  # Extra connections when pool is full
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=3600,  # Recycle connections after 1 hour
    echo_pool=True,  # Recycle idle connections
)
)

# Get connection from pool
with engine.connect() as connection:
    result = connection.execute('SELECT * FROM users')
```

---

### Go (database/sql)

**Configuration**:
```go
import (
    "database/sql"
    "github.com/go-sql-driver/mysql"
)

db, err := sql.Open("mysql", "user:password@tcp(localhost:3306)/dbname")

db.SetMaxOpenConns(25)  // Max connections in pool
db.SetMaxIdleConns(10)  // Max idle connections
db.SetConnMaxLifetime(time.Hour)  // Connection lifetime
db.SetConnMaxIdleTime(time.Minute * 30)  // Idle connection lifetime
```

---

### Node.js (pg)

**Configuration**:
```javascript
const { Pool } = require('pg');

const pool = new Pool({
    host: 'localhost',
    database: 'mydb',
    max: 20,  // Max connections
    idleTimeoutMillis: 30000,  // 30 seconds
    connectionTimeoutMillis: 2000,
});

async function query(sql, params) {
    const client = await pool.connect();
    try {
        const result = await client.query(sql, params);
        return result.rows;
    } finally {
        client.release();  // Return to pool
    }
}
```

---

## CONNECTION LEAK PREVENTION

### 1. Always Release Connections

**Bad**:
```php
// Laravel: Forgetting to release connection
public function getUsers()
{
    $connection = DB::connection();  // Acquires connection

    // Process data
    $users = $connection->table('users')->get();
    // Connection automatically released after request
}
```

**Good** (Manual release):
```php
// Explicitly release in long-running scripts
$connection = DB::connection();

try {
    // Long-running operation
    $this->processLargeDataset($connection);
} finally {
    $connection->disconnect();  // Explicit release
}
```

### 2. Use Context Managers

**Python**:
```python
# GOOD: Context manager automatically releases connection
from contextlib import contextmanager

@contextmanager
def get_connection():
    conn = engine.connect()
    try:
        yield conn
    finally:
        conn.close()

# Usage
with get_connection() as conn:
    result = conn.execute('SELECT * FROM users')
```

**JavaScript**:
```javascript
// GOOD: Pool automatically manages connections
async function getData() {
    const client = await pool.connect();
    try {
        const result = await client.query('SELECT * FROM users');
        return result.rows;
    } finally {
        client.release();
    }
}
```

---

### 3. Monitor Connection Usage

**PostgreSQL**:
```sql
-- Check active connections
SELECT count(*) FROM pg_stat_activity
WHERE state = 'active';

-- Check max connections
SHOW max_connections;
```

**MySQL**:
```sql
-- Check active connections
SHOW STATUS WHERE `Threads_connected` > 0;

-- Check max connections
SHOW VARIABLES LIKE 'max_connections';
```

---

## PERFORMANCE TUNING

### Connection Pool Size

**Guidelines**:
- Small apps: 5-10 connections
- Medium apps: 20-50 connections
- Large apps: 50-100 connections
- Test with production load to find optimal size

**Example**:
```python
# Start with 10 connections
pool_size = 10

# Monitor under load
# If connection wait times > 100ms, increase pool
# If idle connections > 50%, decrease pool
```

### Connection Timeouts

**Laravel**:
```php
// Set connection timeout
'options' => [
    PDO::ATTR_TIMEOUT => 5,  // 5 seconds
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]
```

**PostgreSQL**:
```python
# Set statement timeout
conn.execute("SET statement_timeout = '5s'")
```

---

## CONNECTION-STRINGS

### PostgreSQL

```postgresql://user:password@host:port/database?options
```

**Examples**:
```
postgresql://postgresuser:secret@localhost:5432/myapp?connect_timeout=5&application_name=myapp
postgresql://127.0.0.1:5432/myapp?sslmode=require
postgresql:///myapp?host=/var/run/postgresql/
```

### MySQL

```mysql://user:password@host:port/database?options
```

**Examples**:
```
mysql://root:password@localhost:3306/myapp?connect_timeout=5
mysql://127.0.0.1:3306/myapp?charset=utf8mb4
mysql:///myapp?socket=/var/run/mysqld/mysqld.sock
```

### MongoDB

```mongodb://user:password@host:27017/database?options
```

**Examples**:
```
mongodb://user:password@localhost:27017/myapp?retryWrites=true&wtimeoutMS=5000
mongodb://localhost:27017/myapp
mongodb:///myapp?socket=/var/run/mongodb/mongodb.sock
```

---

## CONNECTION MANAGEMENT CHECKLIST

### Configuration
- [ ] Connection pool configured
- [ ] Max connections appropriate for expected load
- [ ] Min connections set (25% of max)
- [ ] Connection timeout configured
- [ ] Idle connection timeout configured

### Application Code
- [ ] Connections released after use (automatic or manual)
- [ ] Long-running scripts explicitly release connections
- [ ] Context managers used for database operations
- [ ] Connection errors handled gracefully
- [ ] Retry logic for transient connection errors

### Monitoring
- [ ] Connection pool metrics monitored
- [ ] Alerts for connection pool exhaustion
- [ ] Alerts for connection leaks (connections not released)
- [ ] Active connections tracked
- [ ] Connection wait times monitored

### Database Configuration
- [ ] Max connections set in database
- [ ] Connection timeouts set appropriately
- [ ] Statement timeouts configured
- [ ] Connection limits enforced (per-user, per-database)

### Testing
- [ ] Connection pool tested under load
- [ ] Connection leak testing performed
- [ ] Failover scenarios tested
- [ ] Database configuration tested with application

---

## CROSS-REFERENCES
- For database performance: @database-engineering/relational/INDEXING.md
- For query optimization: @database-engineering/relational/NPLUS1.md
- For migration best practices: @migrations/MIGRATION-BEST-PRACTICES.md
