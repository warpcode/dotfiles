# INDEXING STRATEGIES

## OVERVIEW
Proper indexing dramatically improves query performance by enabling fast data retrieval without full table scans.

## INDEX TYPES

### 1. Single-Column Indexes

**Purpose**: Fast lookup on single column.

**Example**:
```sql
-- Create index on username column
CREATE INDEX idx_users_username ON users(username);

-- Query now uses index
SELECT * FROM users WHERE username = 'john@example.com';
```

**When to Use**:
- Columns used in WHERE clause
- Columns used in JOIN conditions
- Columns used in ORDER BY
- Columns with high cardinality (many unique values)

---

### 2. Composite Indexes

**Purpose**: Index on multiple columns for queries filtering/joining on multiple columns.

**Example**:
```sql
-- Create composite index
CREATE INDEX idx_users_email_status ON users(email, status);

-- Query uses index on both columns
SELECT * FROM users
WHERE email = 'john@example.com' AND status = 'active';

-- Query still uses index (index covers email)
SELECT * FROM users WHERE email = 'john@example.com';

-- Query DOES NOT use index (status not first in index)
SELECT * FROM users WHERE status = 'active';
```

**Column Order Matters**:
- Put most selective column first
- Put equality columns first, range columns last
- Consider query patterns

---

### 3. Unique Indexes

**Purpose**: Enforce uniqueness and enable fast lookups.

**Example**:
```sql
-- Unique index on email
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Prevents duplicate emails, fast lookups
INSERT INTO users (email, name) VALUES ('john@example.com', 'John');
-- Succeeds

INSERT INTO users (email, name) VALUES ('john@example.com', 'Jane');
-- FAILS with unique constraint violation
```

---

### 4. Foreign Key Indexes

**Purpose**: Speed up JOINs on foreign key columns.

**Example**:
```sql
-- Orders table references users table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2),
    created_at TIMESTAMP
);

-- Index foreign key for fast JOINs
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Query uses index
SELECT users.*, orders.total
FROM users
JOIN orders ON users.id = orders.user_id
WHERE orders.user_id = 123;
```

---

### 5. Partial Indexes

**Purpose**: Index subset of data matching WHERE condition.

**Example**:
```sql
-- Partial index for active users only
CREATE INDEX idx_users_active_email ON users(email, status)
WHERE status = 'active';

-- Query uses partial index
SELECT * FROM users
WHERE email = 'john@example.com' AND status = 'active';

-- Query uses regular index (partial index not used)
SELECT * FROM users
WHERE status = 'inactive';
```

---

### 6. Covering Indexes

**Purpose**: Index that includes all columns needed for query (avoids table lookup).

**Example**:
```sql
-- Covering index on (user_id, status, total)
CREATE INDEX idx_orders_user_status_total ON orders(user_id, status, total);

-- Query uses covering index (no table lookup!)
SELECT status, total
FROM orders
WHERE user_id = 123;
-- Index contains status and total - FAST!
```

---

### 7. Full-Text Indexes

**Purpose**: Fast text search (LIKE, ILIKE).

**PostgreSQL**:
```sql
-- Create full-text index
CREATE INDEX idx_posts_content_fulltext ON posts USING gin(to_tsvector('english', content));

-- Text search uses full-text index (no LIKE)
SELECT title, content
FROM posts
WHERE to_tsvector('english', content) @@ plainto_tsquery('english', 'search term');
```

**MySQL**:
```sql
-- Create full-text index
CREATE FULLTEXT INDEX idx_posts_content ON posts(content);

-- Text search uses full-text index
SELECT * FROM posts
WHERE MATCH(content) AGAINST('search term' IN NATURAL LANGUAGE MODE);
```

---

## INDEXING BEST PRACTICES

### 1. Analyze Query Patterns

**Use EXPLAIN**:
```sql
-- Analyze query execution plan
EXPLAIN SELECT * FROM users WHERE email = 'john@example.com';

-- Check if index is used
-- Look for "Seq Scan" (bad - full table scan)
-- Look for "Index Scan" (good - using index)
```

**Monitor Slow Query Log**:
```sql
-- Enable slow query logging
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;

-- Check log regularly
-- Identify queries needing indexes
```

---

### 2. Index Selectively

**DO Index**:
- Columns in WHERE clauses
- Columns in JOIN conditions
- Columns in ORDER BY
- Foreign key columns
- High-cardinality columns
- Frequently queried columns

**DON'T Index**:
- Low-cardinality columns (status: 3 values)
- Columns rarely queried
- BLOB/TEXT columns (use full-text search instead)
- Columns already covered by composite index

---

### 3. Monitor Index Usage

**Check Unused Indexes**:
```sql
-- PostgreSQL: Check index statistics
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan < 100;  -- Rarely used indexes

-- MySQL: Check index statistics
SELECT TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX, CARDINALITY
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'your_database';
```

**Remove Unused Indexes**:
```sql
-- Drop unused indexes
DROP INDEX idx_users_name ON users;
```

---

### 4. Rebuild Indexes Periodically

**PostgreSQL**:
```sql
-- Reindex table
REINDEX TABLE users;

-- Reindex specific index
REINDEX INDEX idx_users_email ON users;
```

**MySQL**:
```sql
-- Optimize table (rebuilds indexes)
OPTIMIZE TABLE users;
```

---

### 5. Consider Index Size and Performance

**Trade-offs**:
- More indexes = Faster reads, slower writes
- Indexes take up disk space
- Indexes increase memory usage

**Guidelines**:
- Keep indexes minimal
- Drop unused indexes
- Monitor index-to-table size ratio
- Use composite indexes instead of many single indexes

---

## INDEXING CHECKLIST

### Before Deployment
- [ ] Analyze all query execution plans with EXPLAIN
- [ ] Add indexes on WHERE clause columns
- [ ] Add indexes on JOIN columns
- [ ] Add indexes on foreign key columns
- [ ] Add indexes on ORDER BY columns
- [ ] Use composite indexes for multi-column queries
- [ ] Consider covering indexes for frequent queries
- [ ] Add full-text indexes for text search
- [ ] Use partial indexes for filtered queries
- [ ] Remove unused indexes
- [ ] Monitor index size and write performance

### Ongoing
- [ ] Monitor slow query log
- [ ] Check index usage statistics
- [ ] Rebuild indexes periodically
- [ ] Monitor database performance metrics
- [ ] Update indexes as query patterns change
- [ ] Test index changes in staging first

---

## PLATFORM-SPECIFIC CONSIDERATIONS

### PostgreSQL
```sql
-- Partial indexes with WHERE clause
CREATE INDEX CONCURRENTLY idx_active ON users(email) WHERE status = 'active';

-- Expression indexes
CREATE INDEX idx_users_email_lower ON users(LOWER(email));

-- Unique indexes with WHERE clause
CREATE UNIQUE INDEX idx_active_users_email ON users(email) WHERE status = 'active';
```

### MySQL
```sql
-- Composite indexes with column order (most selective first)
CREATE INDEX idx_user_status_created ON users(status, created_at);

-- Prefix indexes for long strings
CREATE INDEX idx_user_email_prefix ON users(email(50));

-- InnoDB: Clustered index (automatically created on primary key)
```

### MongoDB
```javascript
// Index on array field
db.users.createIndex({ "roles": 1 });

// Text index
db.posts.createIndex({ "content": "text" });

// Compound index
db.orders.createIndex({ "user_id": 1, "status": 1 });

// Unique sparse index
db.users.createIndex({ "email": 1 }, { unique: true, sparse: true });
```

---

## CROSS-REFERENCES
- For N+1 query detection: @database-engineering/relational/NPLUS1.md
- For query optimization: @database-engineering/connections/CONNECTION-PATTERNS.md
- For database design: @database-engineering/design/DATABASE-DESIGN.md
