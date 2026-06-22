# DATABASE DESIGN

## OVERVIEW
Good database design is foundation for scalability, performance, and data integrity.

## NORMALIZATION

### Normal Forms

**1NF (First Normal Form)**:
- No repeating groups
- All columns atomic (no multi-valued columns)

**2NF (Second Normal Form)**:
- 1NF + No partial dependencies
- All non-key columns depend on entire primary key

**3NF (Third Normal Form)**:
- 2NF + No transitive dependencies
- All non-key columns depend only on primary key

**Example**:
```sql
-- Unnormalized (violates all normal forms)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(100),     -- Depends on user_id, not id
    user_email VARCHAR(255),   -- Depends on user_id, not id
    user_address TEXT,        -- Depends on user_id, not id
    product_name VARCHAR(100),
    quantity INTEGER,
    total DECIMAL(10,2)
);
```

**Normalized (3NF)**:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255) UNIQUE,
    address TEXT
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER,
    total DECIMAL(10,2)
);
```

---

## ENTITY RELATIONSHIPS

### One-to-One

**Definition**: Each record in Table A relates to at most one record in Table B.

**Example**:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id),
    bio TEXT,
    avatar_url VARCHAR(255)
);
```

**When to Use**:
- Optional/extended attributes
- Large fields rarely accessed
- Splitting large tables

---

### One-to-Many

**Definition**: Each record in Table A relates to multiple records in Table B.

**Example**:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10,2),
    created_at TIMESTAMP
);
```

**When to Use**:
- Parent-child relationships
- Hierarchical data (categories, comments)
- Master-detail relationships

---

### Many-to-Many

**Definition**: Records in Table A relate to multiple records in Table B and vice versa.

**Example**:
```sql
CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE student_courses (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    enrolled_at TIMESTAMP
);
```

**When to Use**:
- Tagging systems
- Many-to-many relationships
- Association tables

---

### Self-Referencing Relationships

**Example**:
```sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    parent_id INTEGER REFERENCES categories(id)
);

-- Hierarchical categories
INSERT INTO categories (id, name, parent_id) VALUES
    (1, 'Root', NULL),
    (2, 'Child 1', 1),
    (3, 'Child 2', 1);
```

---

## DATA TYPES

### Choosing Appropriate Types

**Best Practices**:
- Use INTEGER for IDs, not VARCHAR
- Use DECIMAL for monetary values (not FLOAT)
- Use TIMESTAMP or DATE for dates (not VARCHAR)
- Use BOOLEAN for true/false (not 0/1 integers)
- Use ENUM for fixed sets of values
- Use JSON/JSONB for flexible data (not comma-separated strings)

**Examples**:
```sql
-- Monetary values (use DECIMAL)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2),  -- 10 digits, 2 decimal places
    quantity INTEGER
);

-- Dates (use TIMESTAMP)
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    event_date TIMESTAMP,
    created_at TIMESTAMP
);

-- Flexible data (use JSON/JSONB)
CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    preferences JSONB,  -- Flexible key-value pairs
    updated_at TIMESTAMP
);
```

---

## CONSTRAINTS

### NOT NULL
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### UNIQUE
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,  -- Prevents duplicate emails
    username VARCHAR(100) UNIQUE  -- Prevents duplicate usernames
);
```

### CHECK Constraints
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    quantity INTEGER CHECK (quantity > 0),  -- Must be positive
    total DECIMAL(10,2) CHECK (total >= 0),
    status VARCHAR(20) CHECK (status IN ('pending', 'processing', 'completed'))
);
```

### Foreign Keys
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE RESTRICT,
    created_at TIMESTAMP
);
```

---

## MIGRATION STRATEGIES

### Idempotent Migrations
```sql
-- Safe to run multiple times
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE
);

-- Add column if not exists (PostgreSQL)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'users_email_unique'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);
    END IF;
END $$;
```

### Backward-Compatible Changes
```sql
-- Add new column with default value
ALTER TABLE users ADD COLUMN phone VARCHAR(20) DEFAULT NULL;

-- Populate column (optional)
UPDATE users SET phone = '555-1234' WHERE id BETWEEN 1 AND 100;

-- Make column NOT NULL (after data populated)
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
```

---

## DESIGN CHECKLIST

### Before Implementation
- [ ] Identify all entities and relationships
- [ ] Normalize to at least 3NF
- [ ] Choose appropriate data types
- [ ] Define primary keys for all tables
- [ ] Define foreign keys for relationships
- [ ] Add NOT NULL constraints where appropriate
- [ ] Add UNIQUE constraints for unique fields
- [ ] Add CHECK constraints for data validation
- [ ] Define indexes for foreign keys
- [ ] Define indexes for frequently queried columns
- [ ] Consider denormalization for read performance

### Before Deployment
- [ ] Review foreign key relationships
- [ ] Verify constraint definitions
- [ ] Test constraint violations (should fail appropriately)
- [ ] Test cascade delete/update behavior
- [ ] Verify index usage with EXPLAIN
- [ ] Test migration rollback procedures
- [ ] Document database schema and relationships

### Ongoing
- [ ] Monitor table sizes and growth
- [ ] Monitor index size and usage
- [ ] Review slow query log
- [ ] Check for constraint violations
- [ ] Plan for schema migrations
- [ ] Document all schema changes

---

## PLATFORM-SPECIFIC PATTERNS

### PostgreSQL
```sql
-- Use SERIAL for auto-increment
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

-- Use JSONB for flexible data
CREATE TABLE settings (
    id SERIAL PRIMARY KEY,
    config JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- Use GENERATED columns for computed values
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    price DECIMAL(10,2),
    quantity INTEGER,
    total DECIMAL(10,2) GENERATED ALWAYS AS (price * quantity) STORED
);
```

### MySQL
```sql
-- Use AUTO_INCREMENT
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);

-- Use JSON for flexible data
CREATE TABLE settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    config JSON NOT NULL
);
```

### MongoDB
```javascript
// Use embedded documents for one-to-many
db.users.insertOne({
    name: 'John',
    orders: [
        { product: 'Widget', quantity: 2, total: 10.00 },
        { product: 'Gadget', quantity: 1, total: 5.00 }
    ]
});

// Use references for many-to-many
db.students.insertOne({ name: 'Alice' });
db.courses.insertOne({ name: 'Math 101' });
db.enrollments.insertOne({
    student: ObjectId('...'),
    course: ObjectId('...')
});
```

---

## CROSS-REFERENCES
- For SQL injection: @database-engineering/relational/SQL-INJECTION.md
- For indexing: @database-engineering/relational/INDEXING.md
- For migrations: @database-engineering/migrations/MIGRATION-BEST-PRACTICES.md
