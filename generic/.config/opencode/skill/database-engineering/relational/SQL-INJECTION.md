# SQL INJECTION PREVENTION

## OVERVIEW
SQL injection is a critical vulnerability where untrusted data is interpolated into SQL queries, allowing attackers to execute arbitrary SQL commands.

## VULNERABILITY TYPES

### 1. Union-Based SQL Injection

**Example**:
```sql
-- VULNERABLE query
SELECT * FROM users WHERE username = '$username';

-- Attacker input: admin' UNION SELECT username, password FROM users --
-- Becomes:
SELECT * FROM users WHERE username = 'admin' UNION SELECT username, password FROM users --'
-- Exposes all usernames and passwords!
```

**Prevention**: Parameterized queries
```sql
-- SECURE: Prepared statement
SELECT * FROM users WHERE username = ?
```

---

### 2. Boolean-Based SQL Injection

**Example**:
```sql
-- VULNERABLE query
SELECT * FROM products WHERE id = $id AND category = 'books';

-- Attacker input: 1 AND 1=1
-- Becomes:
SELECT * FROM products WHERE id = 1 AND 1=1 AND category = 'books'
-- Returns first product regardless of category!
```

**Prevention**: Parameterized queries with proper type validation
```sql
-- SECURE: Parameterized with type check
SELECT * FROM products WHERE id = ? AND category = ?
-- ID must be integer, category string
```

---

### 3. Error-Based SQL Injection

**Example**:
```sql
-- VULNERABLE query
SELECT * FROM users WHERE id = $id;

-- Attacker input: 1' AND 1=CONVERT(int, (SELECT TOP 1 name FROM sys.objects)) --
-- Exploits error message to leak database information
```

**Prevention**: Parameterized queries and proper error handling

---

### 4. Time-Based Blind SQL Injection

**Example**:
```sql
-- VULNERABLE query
SELECT * FROM users WHERE username = '$username' AND SLEEP(5);

-- Attacker input: admin' OR 1=1; WAITFOR DELAY '0:0:5' --
-- Sleeps for 5 seconds if condition is true, confirming vulnerability
```

**Prevention**: Parameterized queries, avoid time-based logic in queries

---

## PREVENTION STRATEGIES

### 1. Parameterized Queries (Preferred)

**PHP (PDO)**:
```php
// VULNERABLE: Direct interpolation
$id = $_GET['id'];
$query = "SELECT * FROM users WHERE id = $id";
$result = $pdo->query($query);

// SECURE: Prepared statement with placeholder
$id = $_GET['id'];
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$id]);
$result = $stmt->fetchAll();
```

**PHP (MySQLi)**:
```php
// SECURE: Prepared statement
$stmt = $mysqli->prepare("SELECT * FROM users WHERE id = ?");
$stmt->bind_param('i', $id);  // 'i' = integer
$stmt->execute();
$result = $stmt->get_result();
```

**Python (SQLAlchemy)**:
```python
# VULNERABLE: String formatting
query = f"SELECT * FROM users WHERE id = {id}"
result = db.execute(query)

# SECURE: Parameterized query
query = text("SELECT * FROM users WHERE id = :id")
result = db.execute(query, {"id": id})
```

**Python (SQLite3)**:
```python
# SECURE: Parameterized query
cursor = conn.cursor()
cursor.execute("SELECT * FROM users WHERE id = ?", (id,))
```

**Java (JDBC)**:
```java
// SECURE: PreparedStatement
String query = "SELECT * FROM users WHERE id = ?";
PreparedStatement stmt = connection.prepareStatement(query);
stmt.setInt(1, id);
ResultSet rs = stmt.executeQuery();
```

---

### 2. ORM Usage (Automatic Parameterization)

**Laravel (Eloquent)**:
```php
// SECURE: ORM automatically parameterizes
$user = User::find($id);
$users = User::where('status', 'active')->where('created_at', '>', $date)->get();
```

**Django**:
```python
# SECURE: ORM automatically parameterizes
user = User.objects.get(id=user_id)
users = User.objects.filter(status='active', created_at__gt=date)
```

**Sequelize (Node.js)**:
```javascript
// SECURE: ORM automatically parameterizes
const user = await User.findByPk(userId);
const users = await User.findAll({
    where: {
        status: 'active',
        createdAt: { [Op.gt]: date }
    }
});
```

---

### 3. Input Validation and Sanitization

**Type Validation**:
```php
// SECURE: Cast to integer
$id = (int) $_GET['id'];
if ($id < 1) {
    die('Invalid ID');
}

$user = User::find($id);
```

**Allowlist Validation**:
```php
// SECURE: Validate against allowlist
$allowedColumns = ['id', 'name', 'email'];
$sortColumn = $_GET['sort'];

if (!in_array($sortColumn, $allowedColumns)) {
    die('Invalid sort column');
}

$query = "SELECT * FROM users ORDER BY $sortColumn";
```

**Length Limits**:
```php
// SECURE: Limit input length
$username = substr($_POST['username'], 0, 50);  // Max 50 characters
```

---

### 4. Stored Procedures (with Caution)

**PHP Example**:
```php
// CALL stored procedure with parameters
$stmt = $pdo->prepare("CALL GetUserInfo(?)");
$stmt->execute([$userId]);
```

**Warning**: Stored procedures can still be vulnerable if they concatenate input internally.

---

## DATABASE-SPECIFIC CONSIDERATIONS

### PostgreSQL

```php
// SECURE: pg_query_params with parameterized queries
$query = "SELECT * FROM users WHERE id = $1";
$result = pg_query_params($db, $query, array($id));
```

### MySQL

```php
// SECURE: MySQLi prepared statements
$stmt = $mysqli->prepare("SELECT * FROM users WHERE id = ?");
$stmt->bind_param('i', $id);
$stmt->execute();
```

### MongoDB (NoSQL Injection)

**MongoDB Example**:
```javascript
// VULNERABLE: $where operator allows any object
User.find({ $where: { $gt: "" } })

// Attacker can bypass: $where: { $ne: null }

// SECURE: Use field-specific operators
User.find({ name: username })

// SECURE: Use type-casted values
User.find({ age: parseInt(age) })
```

---

## TESTING FOR SQL INJECTION

### Automated Scanning
```bash
# SQLMap - Automated SQL injection testing
sqlmap -u "http://example.com/page?id=1" \
  --level=3 \
  --risk=2 \
  --batch
```

### Manual Testing
```sql
-- Test inputs:
' OR '1'='1
' OR 1=1--
' AND 1=1
' AND 1=2--
' UNION SELECT NULL--
' AND SLEEP(5)--
```

---

## SQL INJECTION CHECKLIST

### Before Deployment
- [ ] All queries use parameterized statements or ORM
- [ ] No string concatenation in SQL queries
- [ ] Input types validated (integer, string, etc.)
- [ ] Input length limits enforced
- [ ] Allowlist validation for dynamic column/table names
- [ ] Stored procedures used with parameterization
- [ ] Database user has minimal permissions (least privilege)
- [ ] Error messages don't leak database information
- [ ] Automated scanning in CI/CD pipeline
- [ ] ORM usage preferred over raw SQL
- [ ] Query logging enabled for forensic analysis

### Ongoing
- [ ] Regular security audits
- [ ] Dependency scanning (SQL libraries)
- [ ] Database access monitoring
- [ ] Incident response procedures for SQLi incidents
- [ ] Penetration testing (quarterly/annual)

---

## CROSS-REFERENCES
- For OWASP Top 10: @secops-engineering/owasp/OWASP-TOP10.md
- For input validation: @secops-engineering/security/INPUT-VALIDATION.md
- For database performance: @database-engineering/relational/INDEXING.md
