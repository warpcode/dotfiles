# Query Optimization

**Purpose**: Guide for optimizing database queries and preventing N+1 queries

## N+1 QUERY PROBLEM

### What is N+1?
- **Definition**: Query inside loop causes N additional queries (1 initial + N loop queries)
- **Impact**: Performance degradation as N grows, database load increases
- **Example**: Load users, then query each user's posts in loop

### Detection
```sql
-- Check for N+1 queries
-- Enable query logging and look for repeated queries
```

### Fix Strategies
```python
# Bad: N+1 queries
users = User.objects.all()
for user in users:  # N iterations
    posts = user.posts.all()  # N additional queries
    print(f"{user.name}: {len(posts)} posts")

# Good: Eager loading (1 query)
users = User.objects.prefetch_related('posts')  # Django
# OR
users = User.objects.select_related('posts')  # Django
# OR
users = User.objects.with('posts')  # Laravel
# OR
users = User.includes(:posts)  # Rails
```

### Language/Framework Specifics

#### Django
```python
# Bad: N+1
users = User.objects.all()
for user in users:
    posts = user.posts.all()  # N+1 queries

# Good: select_related (Foreign Key - 1 query)
users = User.objects.select_related('profile')

# Good: prefetch_related (Many-to-Many - 2 queries)
users = User.objects.prefetch_related('posts')

# Good: Combined
users = User.objects.select_related('profile').prefetch_related('posts')
```

#### Laravel Eloquent
```php
// Bad: N+1
$users = User::all();
foreach ($users as $user) {
    $posts = $user->posts; // N+1 queries
}

// Good: Eager loading (with)
$users = User::with('posts')->get();

// Good: Nested eager loading
$users = User::with('posts.comments')->get();

// Good: Constrain eager loading
$users = User::with(['posts' => function ($query) {
    $query->where('published', true);
}])->get();
```

#### Rails ActiveRecord
```ruby
# Bad: N+1
users = User.all
users.each do |user|
  posts = user.posts  # N+1 queries
end

# Good: Eager loading (includes)
users = User.includes(:posts).all

# Good: Nested eager loading
users = User.includes(posts: :comments).all

# Good: Constrain eager loading
users = User.includes(:posts).where(posts: { published: true }).references(:posts)
```

#### Sequelize (Node.js)
```javascript
// Bad: N+1
const users = await User.findAll();
for (const user of users) {
  const posts = await user.getPosts(); // N+1 queries
}

// Good: Eager loading
const users = await User.findAll({
  include: [{
    model: Post,
    as: 'posts'
  }]
});

// Good: Nested eager loading
const users = await User.findAll({
  include: [{
    model: Post,
    as: 'posts',
    include: [{
      model: Comment,
      as: 'comments'
    }]
  }]
});
```

#### TypeORM (Node.js)
```typescript
// Bad: N+1
const users = await User.find();
for (const user of users) {
  const posts = await user.posts; // N+1 queries
}

// Good: Eager loading
const users = await User.find({
  relations: ['posts']
});

// Good: Nested eager loading
const users = await User.find({
  relations: ['posts', 'posts.comments']
});
```

#### Spring Data JPA
```java
// Bad: N+1
List<User> users = userRepository.findAll();
for (User user : users) {
    List<Post> posts = user.getPosts(); // N+1 queries
}

// Good: Eager loading (@EntityGraph)
@EntityGraph(attributePaths = {"posts"})
List<User> users = userRepository.findAll();

// Good: JOIN FETCH
@Query("SELECT u FROM User u JOIN FETCH u.posts WHERE u.id = :id")
User findByIdWithPosts(@Param("id") Long id);
```

## MISSING INDEXES

### Detection
```sql
-- PostgreSQL: Check for missing indexes
SELECT schemaname, tablename,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_read
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC;

-- MySQL: Check for slow queries
SELECT * FROM mysql.slow_log
ORDER BY query_time DESC
LIMIT 10;

-- Identify missing indexes with EXPLAIN
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user@example.com';
```

### Common Missing Indexes
```sql
-- Foreign keys
CREATE INDEX idx_posts_user_id ON posts(user_id);

-- WHERE clause columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_published ON posts(published);

-- ORDER BY columns
CREATE INDEX idx_posts_created_at ON posts(created_at);

-- Composite indexes
CREATE INDEX idx_posts_user_published ON posts(user_id, published);
```

### Index Best Practices
- **Foreign Keys**: Always index foreign keys
- **WHERE Clause**: Index columns used in WHERE
- **ORDER BY**: Index columns used in ORDER BY
- **JOIN Columns**: Index columns used in JOIN
- **Composite**: Use composite indexes for multi-column queries
- **Avoid Over-Indexing**: Too many indexes slow down writes

## INEFFICIENT QUERIES

### SELECT * Anti-Pattern
```sql
-- Bad: SELECT * (returns all columns)
SELECT * FROM users WHERE id = 1;

-- Good: SELECT only needed columns
SELECT id, name, email FROM users WHERE id = 1;
```

### NOT IN Anti-Pattern
```sql
-- Bad: NOT IN (slow for large datasets)
SELECT * FROM users WHERE id NOT IN (SELECT user_id FROM posts);

-- Good: LEFT JOIN with NULL check
SELECT u.* FROM users u
LEFT JOIN posts p ON u.id = p.user_id
WHERE p.id IS NULL;

-- Good: NOT EXISTS
SELECT * FROM users u
WHERE NOT EXISTS (SELECT 1 FROM posts p WHERE p.user_id = u.id);
```

### OR in WHERE
```sql
-- Bad: OR can prevent index usage
SELECT * FROM users WHERE email = 'a@example.com' OR email = 'b@example.com';

-- Good: IN
SELECT * FROM users WHERE email IN ('a@example.com', 'b@example.com');

-- Good: UNION for complex OR
SELECT * FROM users WHERE email = 'a@example.com'
UNION
SELECT * FROM users WHERE email = 'b@example.com';
```

### LIKE Wildcard Prefix
```sql
-- Bad: Prefix wildcard prevents index usage
SELECT * FROM users WHERE name LIKE '%John%';

-- Good: Suffix wildcard (index usable)
SELECT * FROM users WHERE name LIKE 'John%';

-- Good: Full-text search
SELECT * FROM users WHERE to_tsvector(name) @@ to_tsquery('John');
```

## QUERY REFACTORING

### Subqueries vs Joins
```sql
-- Bad: Subquery in WHERE (slow)
SELECT * FROM users WHERE id IN (SELECT user_id FROM posts);

-- Good: JOIN (faster)
SELECT DISTINCT u.* FROM users u
INNER JOIN posts p ON u.id = p.user_id;
```

### Pagination
```sql
-- Bad: OFFSET for large offsets (slow)
SELECT * FROM posts ORDER BY created_at DESC OFFSET 10000 LIMIT 10;

-- Good: Keyset pagination (fast)
SELECT * FROM posts WHERE created_at < '2024-01-01 12:00:00'
ORDER BY created_at DESC LIMIT 10;
```

### COUNT Queries
```sql
-- Bad: COUNT(*) on large table (slow)
SELECT COUNT(*) FROM posts;

-- Good: Approximate count (PostgreSQL)
SELECT reltuples::bigint AS estimate FROM pg_class WHERE relname = 'posts';

-- Good: Use EXPLAIN (check if rows are counted)
EXPLAIN SELECT * FROM posts;
```

## QUERY CACHING

### Database Query Cache
```sql
-- MySQL: Query cache (deprecated in 8.0)
-- PostgreSQL: Result cache (pg_prewarm)
-- Consider application-level caching instead
```

### Application-Level Caching
```python
# Good: Cache query results
from django.core.cache import cache

def get_popular_posts():
    cache_key = 'popular_posts'
    posts = cache.get(cache_key)
    
    if posts is None:
        posts = Post.objects.filter(popular=True).order_by('-created_at')[:10]
        cache.set(cache_key, posts, 3600)  # Cache for 1 hour
    
    return posts
```

## QUERY ANALYSIS TOOLS

### PostgreSQL
```sql
-- EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user@example.com';

-- pg_stat_statements extension
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

### MySQL
```sql
-- EXPLAIN
EXPLAIN SELECT * FROM users WHERE email = 'user@example.com';

-- Slow query log
-- Enable in my.cnf:
-- slow_query_log = 1
-- long_query_time = 2
-- slow_query_log_file = /var/log/mysql/mysql-slow.log
```

### MongoDB
```javascript
// Explain query
db.users.find({ email: 'user@example.com' }).explain();

// Index usage
db.users.find({ email: 'user@example.com' }).explain('executionStats');
```

## BEST PRACTICES

### General
- **N+1 Queries**: Always use eager loading
- **Indexes**: Index WHERE, ORDER BY, JOIN, foreign key columns
- **SELECT ***: Select only needed columns
- **Pagination**: Use keyset pagination for large offsets
- **EXPLAIN**: Always EXPLAIN slow queries
- **Query Logging**: Enable query logging in development
- **Batch Operations**: Use batch inserts/updates instead of loops
- **Prepared Statements**: Always use parameterized queries (security + performance)

### Framework-Specific
- **Django**: Use `select_related()` for Foreign Keys, `prefetch_related()` for Many-to-Many
- **Laravel**: Use `with()` for eager loading, `whereHas()` for filtering relationships
- **Rails**: Use `includes()` for eager loading, `joins()` for filtering
- **Sequelize**: Use `include` for eager loading
- **Spring Data**: Use `@EntityGraph` or `JOIN FETCH` for eager loading
