# DEPRECATED API REPLACEMENTS

## OVERVIEW
Deprecated APIs should be replaced with modern alternatives to ensure security, performance, and future compatibility.

## PHP DEPRECATED APIS

### 1. mysql_* Functions

**Status**: Removed in PHP 7.0
**Replacement**: PDO or mysqli

```php
// DEPRECATED: mysql_* functions
$conn = mysql_connect('localhost', 'user', 'pass');
mysql_select_db('database', $conn);
$result = mysql_query("SELECT * FROM users");
while ($row = mysql_fetch_assoc($result)) {
    echo $row['name'];
}
mysql_close($conn);

// MODERN: PDO
try {
    $conn = new PDO('mysql:host=localhost;dbname=database', 'user', 'pass');
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $stmt = $conn->prepare("SELECT * FROM users");
    $stmt->execute();
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo $row['name'];
    }
} catch (PDOException $e) {
    error_log($e->getMessage());
}

// ALTERNATIVE: mysqli
$conn = mysqli_connect('localhost', 'user', 'pass', 'database');
$result = mysqli_query($conn, "SELECT * FROM users");
while ($row = mysqli_fetch_assoc($result)) {
    echo $row['name'];
}
mysqli_close($conn);
```

---

### 2. ereg_* Functions

**Status**: Removed in PHP 7.0
**Replacement**: preg_* functions (PCRE)

```php
// DEPRECATED: ereg_* functions
if (ereg('^[a-zA-Z]+$', $string)) {
    echo "Valid";
}

if (eregi('pattern', $string)) { }  // Case-insensitive

// MODERN: preg_* functions
if (preg_match('/^[a-zA-Z]+$/', $string)) {
    echo "Valid";
}

if (preg_match('/pattern/i', $string)) { }  // Case-insensitive

// Replacements:
// ereg()       -> preg_match()
// eregi()      -> preg_match('/.../i')
// ereg_replace() -> preg_replace()
// eregi_replace()-> preg_replace('/.../i')
```

---

### 3. split() Function

**Status**: Removed in PHP 7.0
**Replacement**: explode() or preg_split()

```php
// DEPRECATED: split()
$parts = split(',', 'a,b,c');  // Deprecated even in PHP 5

// MODERN: explode() (for simple delimiters)
$parts = explode(',', 'a,b,c');

// MODERN: preg_split() (for regex patterns)
$parts = preg_split('/,/', 'a,b,c');
$parts = preg_split('/\s+/', $string);  // Split on whitespace
```

---

### 4. each() Function

**Status**: Removed in PHP 7.2
**Replacement**: foreach

```php
// DEPRECATED: each()
while (list($key, $value) = each($array)) {
    echo "$key: $value\n";
}

// MODERN: foreach
foreach ($array as $key => $value) {
    echo "$key: $value\n";
}
```

---

### 5. mcrypt_* Functions

**Status**: Removed in PHP 7.2
**Replacement**: openssl_* functions or Sodium (libsodium)

```php
// DEPRECATED: mcrypt_encrypt()
$key = 'secretkey';
$iv = mcrypt_create_iv(mcrypt_get_iv_size(MCRYPT_RIJNDAEL_128, MCRYPT_MODE_CBC), MCRYPT_RAND);
$encrypted = mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $key, $data, MCRYPT_MODE_CBC, $iv);

// MODERN: openssl_encrypt()
$cipher = "AES-128-CBC";
$iv_length = openssl_cipher_iv_length($cipher);
$iv = openssl_random_pseudo_bytes($iv_length);
$encrypted = openssl_encrypt($data, $cipher, $key, 0, $iv);

// Decrypt
$decrypted = openssl_decrypt($encrypted, $cipher, $key, 0, $iv);

// ALTERNATIVE: Sodium (PHP 7.2+, more secure)
$encrypted = sodium_crypto_secretbox($data, $nonce, $key);
$decrypted = sodium_crypto_secretbox_open($encrypted, $nonce, $key);
```

---

### 6. mysql_real_escape_string()

**Status**: Only works with deprecated mysql_* functions
**Replacement**: PDO prepared statements

```php
// DEPRECATED: mysql_real_escape_string()
$escaped = mysql_real_escape_string($_POST['username']);
$query = "SELECT * FROM users WHERE username = '$escaped'";

// MODERN: PDO prepared statements
$stmt = $pdo->prepare("SELECT * FROM users WHERE username = ?");
$stmt->execute([$_POST['username']]);
```

---

### 7. posix_* Functions (on Windows)

**Status**: Not available on Windows
**Replacement**: Cross-platform alternatives

```php
// DEPRECATED: posix_* (not portable)
if (posix_getuid() === 0) {
    echo "Running as root\n";
}

// MODERN: Cross-platform
if (function_exists('posix_getuid') && posix_getuid() === 0) {
    echo "Running as root\n";
}

// Or use platform detection
if (PHP_OS === 'Linux' || PHP_OS === 'Darwin') {
    // Use posix functions
} else {
    // Use Windows equivalents
}
```

---

## JAVASCRIPT DEPRECATED APIS

### 1. var Keyword

**Status**: Not deprecated, but use const/let
**Replacement**: const (immutable), let (mutable)

```javascript
// OLD: var (function-scoped, hoisting)
var name = 'John';
if (true) {
    var name = 'Jane';  // Same variable!
}
console.log(name);  // 'Jane'

// MODERN: const/let (block-scoped)
const name = 'John';
if (true) {
    const name = 'Jane';  // Different variable
}
console.log(name);  // 'John'

// Use const for values that don't change
const API_URL = 'https://api.example.com';

// Use let for values that change
let counter = 0;
counter++;
```

---

### 2. XMLHttpRequest (for new code)

**Status**: Not deprecated, but fetch is preferred
**Replacement**: fetch API

```javascript
// OLD: XMLHttpRequest
const xhr = new XMLHttpRequest();
xhr.open('GET', '/api/users');
xhr.onload = function() {
    if (xhr.status === 200) {
        console.log(JSON.parse(xhr.responseText));
    }
};
xhr.onerror = function() {
    console.error('Request failed');
};
xhr.send();

// MODERN: fetch API
fetch('/api/users')
    .then(response => {
        if (!response.ok) throw new Error('Request failed');
        return response.json();
    })
    .then(data => console.log(data))
    .catch(error => console.error(error));

// WITH async/await (modern)
async function fetchUsers() {
    try {
        const response = await fetch('/api/users');
        if (!response.ok) throw new Error('Request failed');
        const data = await response.json();
        console.log(data);
    } catch (error) {
        console.error(error);
    }
}
```

---

### 3. .then() Chains (for new code)

**Status**: Not deprecated, but async/await is preferred
**Replacement**: async/await

```javascript
// OLD: Promise chains
fetch('/api/users')
    .then(response => response.json())
    .then(users => {
        return fetch(`/api/users/${users[0].id}`);
    })
    .then(response => response.json())
    .then(user => {
        return fetch(`/api/users/${user.id}/posts`);
    })
    .then(response => response.json())
    .then(posts => {
        console.log(posts);
    })
    .catch(error => {
        console.error(error);
    });

// MODERN: async/await
async function fetchUserPosts() {
    try {
        const users = await fetch('/api/users').then(r => r.json());
        const user = await fetch(`/api/users/${users[0].id}`).then(r => r.json());
        const posts = await fetch(`/api/users/${user.id}/posts`).then(r => r.json());
        console.log(posts);
    } catch (error) {
        console.error(error);
    }
}
```

---

### 4. Callback Hell

**Status**: Anti-pattern, not deprecated API
**Replacement**: Promises or async/await

```javascript
// OLD: Nested callbacks (callback hell)
getData(function(data) {
    processData(data, function(processed) {
        saveData(processed, function(saved) {
            notifyUser(saved, function(notified) {
                // Deeply nested!
            });
        });
    });
});

// MODERN: Promises
getData()
    .then(processData)
    .then(saveData)
    .then(notifyUser)
    .catch(error => console.error(error));

// MODERN: async/await
async function main() {
    try {
        const data = await getData();
        const processed = await processData(data);
        const saved = await saveData(processed);
        await notifyUser(saved);
    } catch (error) {
        console.error(error);
    }
}
```

---

## DATABASE-SPECIFIC DEPRECATIONS

### MySQL: OLD_PASSWORD Function

**Status**: Removed in MySQL 8.0
**Replacement**: Use modern password hashing

```sql
-- DEPRECATED: OLD_PASSWORD() (weak hashing)
-- INSERT INTO users (password) VALUES (OLD_PASSWORD('secret'));

-- MODERN: Use application-level hashing
-- PHP: password_hash()
$hashed = password_hash('secret', PASSWORD_DEFAULT);

-- JavaScript: bcrypt
const hashed = await bcrypt.hash('secret', 10);
```

---

### MySQL: Query Cache

**Status**: Removed in MySQL 8.0
**Replacement**: InnoDB buffer pool, external caching (Redis, Memcached)

```sql
-- DEPRECATED: Query cache variables
-- SET GLOBAL query_cache_size = 1000000;

-- MODERN: Use application-level caching
-- Or InnoDB configuration optimization
SET GLOBAL innodb_buffer_pool_size = 2G;
```

---

## PYTHON DEPRECATED APIS

### 1. print Statement (Python 2)

**Status**: Removed in Python 3
**Replacement**: print() function

```python
# DEPRECATED: print statement (Python 2)
print "Hello, World!"
print "Name:", name

# MODERN: print() function (Python 3)
print("Hello, World!")
print("Name:", name)
```

---

### 2. xrange (Python 2)

**Status**: Removed in Python 3
**Replacement**: range (optimized in Python 3)

```python
# DEPRECATED: xrange (Python 2)
for i in xrange(100):
    print(i)

# MODERN: range (Python 3)
for i in range(100):
    print(i)
```

---

### 3. basestring (Python 2)

**Status**: Removed in Python 3
**Replacement**: str

```python
# DEPRECATED: basestring (Python 2)
if isinstance(s, basestring):
    print("It's a string")

# MODERN: str (Python 3)
if isinstance(s, str):
    print("It's a string")
```

---

## REPLACEMENT CHECKLIST

- [ ] Replace all `mysql_*` with PDO or mysqli
- [ ] Replace all `ereg_*` with `preg_*`
- [ ] Replace `split()` with `explode()` or `preg_split()`
- [ ] Replace `each()` with `foreach`
- [ ] Replace `mcrypt_*` with `openssl_*` or Sodium
- [ ] Replace `var` with `const` or `let` (JavaScript)
- [ ] Use `fetch` instead of `XMLHttpRequest` (JavaScript)
- [ ] Replace callback hell with `async/await` (JavaScript)
- [ ] Replace `print` statement with `print()` (Python 2 to 3)
- [ ] Replace `xrange` with `range` (Python 2 to 3)
- [ ] Replace `basestring` with `str` (Python 2 to 3)

---

## MIGRATION TOOLS

### PHP
- PHPCompatibility (static analysis)
- PHPStan (type checking)
- Rector (automated refactoring)

### JavaScript
- ESLint (linting)
- Babel (transpilation)
- TypeScript (type checking)

### Python
- 2to3 (Python 2 to 3 migration tool)
- Pylint (code analysis)
- Black (code formatting)

---

## CROSS-REFERENCES
- For code modernization: @refactoring/CODE-MODERNIZATION.md
- For modern language features: @refactoring/MODERN-LANGUAGE-FEATURES.md
- For security best practices: @security/CODE-INJECTION.md
