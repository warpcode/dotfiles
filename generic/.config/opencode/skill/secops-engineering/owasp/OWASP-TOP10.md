# OWASP TOP 10

## OVERVIEW
OWASP Top 10 is a standard awareness document for developers and web application security. It represents a broad consensus about the most critical security risks to web applications.

## 2021 OWASP TOP 10

### A01:2021 - Broken Access Control

**Definition**: Failures in enforcing policies on what users can do regardless of their permissions.

**Examples**:
- IDOR (Insecure Direct Object References)
- Vertical privilege escalation
- Horizontal privilege escalation
- Forcing browsing to authenticated URLs
- Missing authentication for sensitive endpoints

**Vulnerability Example**:
```php
// VULNERABLE: IDOR - user can access any order
$order = DB::table('orders')->find($_GET['order_id']);
return $order;

// Attacker changes order_id to another user's order
```

**Prevention**:
```php
// SECURE: Check user owns the order
$order = DB::table('orders')
    ->where('id', $_GET['order_id'])
    ->where('user_id', Auth::id())
    ->first();

if (!$order) {
    abort(403, 'Unauthorized');
}

// Or use authorization middleware
Route::get('/orders/{order}', [OrderController::class, 'show'])
    ->middleware('can:view,order');
```

**Prevention Checklist**:
- [ ] Implement proper authorization checks
- [ ] Use deny-by-default (whitelist instead of blacklist)
- [ ] Invalidate JWT on logout
- [ ] Force password reset on account changes

---

### A02:2021 - Cryptographic Failures

**Definition**: Failures related to cryptography (or lack thereof), leading to exposure of sensitive information.

**Examples**:
- Using deprecated/weak algorithms (MD5, SHA1, RC4, DES)
- Hard-coded encryption keys
- Using weak password hashing (MD5, SHA1)
- Storing secrets in plaintext
- Insufficient entropy for random generation

**Vulnerability Example**:
```php
// VULNERABLE: MD5 password hashing
$hashed = md5($password);
DB::insert('users', ['password' => $hashed]);

// Attacker can crack MD5 with rainbow tables
```

**Prevention**:
```php
// SECURE: Argon2 or bcrypt password hashing
$hashed = password_hash($password, PASSWORD_ARGON2ID);
DB::insert('users', ['password' => $hashed]);

// Verify password
if (password_verify($input, $hashed)) {
    // Valid
}

// Strong encryption for data
$ciphertext = openssl_encrypt(
    $data,
    'aes-256-gcm',
    $key,
    0,
    $iv,
    $tag
);
```

**Prevention Checklist**:
- [ ] Use Argon2 or bcrypt for password hashing
- [ ] Use strong encryption (AES-256-GCM, ChaCha20-Poly1305)
- [ ] Never hard-code encryption keys
- [ ] Use CSPRNG for random generation (random_bytes(), secrets.token_hex())
- [ ] Never use MD5, SHA1, RC4, DES
- [ ] Verify signatures before trusting data

---

### A03:2021 - Injection

**Definition**: Untrusted data sent to an interpreter as part of a command or query.

**Examples**:
- SQL injection
- OS command injection
- NoSQL injection
- LDAP injection
- Template injection
- Expression language injection

**Vulnerability Example**:
```php
// VULNERABLE: SQL injection
$id = $_GET['id'];
$query = "SELECT * FROM users WHERE id = $id";
$result = DB::query($query);

// Attacker input: id=1; DROP TABLE users; --
```

**Prevention**:
```php
// SECURE: Parameterized queries
$id = $_GET['id'];
$stmt = DB::prepare("SELECT * FROM users WHERE id = ?");
$stmt->execute([$id]);
$result = $stmt->fetch();

// Or use ORM (automatically parameterized)
$user = User::find($id);
```

**Prevention Checklist**:
- [ ] Use parameterized queries (prepared statements)
- [ ] Use ORM with automatic parameterization
- [ ] Validate and sanitize all input
- [ ] Use allowlist validation
- [ ] Never concatenate user input into queries/commands
- [ ] Use `escapeshellarg()` for shell commands
- [ ] Use `htmlspecialchars()` for output encoding

---

### A04:2021 - Insecure Design

**Definition**: Systematic design flaws across categories like business logic flaws, rate limiting, etc.

**Examples**:
- Missing rate limiting
- Excessive trust in client-side controls
- Business logic flaws
- Flaws in data model design

**Vulnerability Example**:
```php
// VULNERABLE: No rate limiting
public function login(Request $request) {
    $user = User::where('email', $request->email)->first();

    if ($user && password_verify($request->password, $user->password)) {
        return auth()->login($user);
    }

    // Attacker can brute force without limits
}
```

**Prevention**:
```php
// SECURE: Rate limiting
public function login(Request $request) {
    // Rate limit to 5 attempts per 15 minutes
    $attempts = Cache::get("login_attempts:{$request->ip}") ?? 0;

    if ($attempts >= 5) {
        throw new TooManyRequestsException('Too many login attempts. Try again later.');
    }

    $user = User::where('email', $request->email)->first();

    if ($user && password_verify($request->password, $user->password)) {
        Cache::forget("login_attempts:{$request->ip}");
        return auth()->login($user);
    }

    // Increment attempt counter
    Cache::put("login_attempts:{$request->ip}", $attempts + 1, 900);
}
```

**Prevention Checklist**:
- [ ] Implement rate limiting
- [ ] Never trust client-side controls
- [ ] Validate business logic server-side
- [ ] Implement proper data models
- [ ] Use state machines for workflows

---

### A05:2021 - Security Misconfiguration

**Definition**: Failing to implement all the security controls for a server or framework, or improperly implementing security controls.

**Examples**:
- Default credentials
- Open cloud storage
- Error messages with stack traces
- Verbose server headers
- Directory listing enabled
- Debug mode in production

**Vulnerability Example**:
```php
// VULNERABLE: Debug mode in production
// config.php
define('DEBUG', true); // Forgot to change!

// Error handling
if (DEBUG) {
    error_log($e->getTraceAsString()); // Exposes code structure
}
```

**Prevention**:
```php
// SECURE: Environment-based configuration
define('DEBUG', getenv('APP_DEBUG') === 'true');
define('ENVIRONMENT', getenv('APP_ENV') ?? 'production');

// Error handling
if (DEBUG) {
    error_log($e->getMessage()); // Only message, no trace
} else {
    error_log('Application error'); // No details in production
}

// Hide PHP errors in production
ini_set('display_errors', '0');
ini_set('log_errors', '1');
```

**Prevention Checklist**:
- [ ] Use environment-specific configurations
- [ ] Change all default credentials
- [ ] Disable debug mode in production
- [ ] Secure error messages (no stack traces)
- [ ] Disable directory listing
- [ ] Secure cloud storage (S3 buckets, etc.)
- [ ] Remove sensitive headers (Server, X-Powered-By)

---

### A06:2021 - Vulnerable and Outdated Components

**Definition**: Using components with known vulnerabilities or without security support.

**Examples**:
- Outdated frameworks (Laravel 5.x, Express < 4.0)
- Known vulnerable libraries
- No security updates for years
- Unmaintained dependencies

**Prevention**:
```bash
# Dependency scanning
# PHP
composer audit

# JavaScript
npm audit

# Python
pip-audit

# Continuous scanning in CI/CD
- name: Dependency scan
  run: |
    composer audit
    npm audit
```

**Prevention Checklist**:
- [ ] Regularly update dependencies
- [ ] Use automated dependency scanning
- [ ] Subscribe to security advisories
- [ ] Remove unused dependencies
- [ ] Use package locking (composer.lock, package-lock.json)
- [ ] Implement vulnerability scanning in CI/CD

---

### A07:2021 - Identification and Authentication Failures

**Definition**: Failures in confirming the user's identity, session management, or identity authentication.

**Examples**:
- Weak password policies
- Password storage in plaintext
- Session fixation
- Credential stuffing
- Missing authentication for sensitive endpoints

**Vulnerability Example**:
```php
// VULNERABLE: Weak password policy
public function register(Request $request) {
    if (strlen($request->password) < 6) { // Too weak!
        return response('Password too short', 400);
    }

    $user = User::create([
        'password' => password_hash($request->password, PASSWORD_DEFAULT)
    ]);
}
```

**Prevention**:
```php
// SECURE: Strong password policy
public function register(Request $request) {
    $password = $request->password;

    // Minimum 12 characters, mixed case, numbers, special chars
    if (
        strlen($password) < 12 ||
        !preg_match('/[A-Z]/', $password) ||
        !preg_match('/[a-z]/', $password) ||
        !preg_match('/[0-9]/', $password) ||
        !preg_match('/[^A-Za-z0-9]/', $password)
    ) {
        throw new ValidationException(
            'Password must be at least 12 characters, ' .
            'include uppercase, lowercase, numbers, and special characters.'
        );
    }

    $user = User::create([
        'password' => password_hash($password, PASSWORD_ARGON2ID)
    ]);
}
```

**Prevention Checklist**:
- [ ] Implement strong password policies (12+ chars, mixed case, numbers, special)
- [ ] Use Argon2 or bcrypt for password hashing
- [ ] Implement multi-factor authentication (MFA)
- [ ] Implement proper session management
- [ ] Implement account lockout after failed attempts
- [ ] Implement secure password reset
- [ ] Never store passwords in plaintext

---

### A08:2021 - Software and Data Integrity Failures

**Definition**: Code and infrastructure that does not protect against integrity violations (e.g., deserialization).

**Examples**:
- Insecure deserialization
- Using unsigned libraries
- No integrity checks on updates
- Insecure CI/CD pipelines

**Vulnerability Example**:
```php
// VULNERABLE: Insecure deserialization
$data = unserialize($_GET['data']);

// If object has __wakeup() magic method,
// malicious code gets executed
```

**Prevention**:
```php
// SECURE: JSON instead of serialization
$data = json_decode($_GET['data'], true);

// Or use allowlist if unserialization required
$data = unserialize($_GET['data'], [
    'allowed_classes' => [MyClass::class]
]);
```

**Prevention Checklist**:
- [ ] Use JSON instead of serialization when possible
- [ ] Use allowlist for deserialization
- [ ] Sign artifacts (code, packages, images)
- [ ] Verify signatures before trusting data
- [ ] Secure CI/CD pipelines (code signing, artifact verification)
- [ ] Use dependency pinning (lock files)

---

### A09:2021 - Security Logging and Monitoring Failures

**Definition**: Failing to log, monitor, and audit security events effectively.

**Examples**:
- No logging of security events
- Insufficient logging (no context)
- Logs not protected
- No alerting on critical events
- Over-logging (performance impact)

**Prevention**:
```javascript
// SECURE: Structured security logging
const logger = require('pino')();

logger.info({
    event: 'user_login',
    userId: 123,
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    timestamp: new Date().toISOString(),
    success: true
});

logger.error({
    event: 'authentication_failure',
    userId: 123,
    ip: req.ip,
    reason: 'invalid_password',
    timestamp: new Date().toISOString()
});

// Critical security events
logger.critical({
    event: 'suspicious_activity',
    userId: 123,
    ip: req.ip,
    details: 'multiple_failed_logins',
    timestamp: new Date().toISOString(),
    alert: true  // Trigger alerting
});
```

**Prevention Checklist**:
- [ ] Log all security events (login, logout, failures)
- [ ] Use structured logging (JSON)
- [ ] Protect logs (permissions, encryption)
- [ ] Implement alerting for critical events
- [ ] Retain logs for appropriate period
- [ ] Regularly review logs for anomalies

---

### A10:2021 - Server-Side Request Forgery (SSRF)

**Definition**: Server fetches a remote resource without validating the user-supplied URL.

**Examples**:
- Fetching arbitrary URLs from user input
- Metadata attacks (cloud instance metadata)
- Internal network scanning

**Vulnerability Example**:
```php
// VULNERABLE: SSRF
$url = $_GET['url'];
$content = file_get_contents($url);

// Attacker: ?url=http://169.254.169.254/latest/meta-data/iam/security-credentials
// Accesses cloud instance metadata!
```

**Prevention**:
```php
// SECURE: URL allowlist
$allowed_domains = ['api.example.com', 'cdn.example.com'];

$url = $_GET['url'];
$parsed = parse_url($url);

if (!in_array($parsed['host'], $allowed_domains)) {
    throw new ForbiddenException('Invalid URL');
}

$content = file_get_contents($url);
```

**Prevention Checklist**:
- [ ] Implement URL allowlist
- [ ] Validate and sanitize URLs
- [ ] Block access to internal IPs (127.0.0.1, 169.254.169.254, etc.)
- [ ] Network segmentation (internal services isolated)
- [ ] Disable unnecessary URL schemes (file://, ftp://)

---

## SECURITY CHECKLIST

### Before Deployment
- [ ] All dependencies updated and scanned
- [ ] No hardcoded secrets
- [ ] Strong password policies implemented
- [ ] Proper authentication/authorization implemented
- [ ] Input validation on all inputs
- [ ] Output encoding implemented
- [ ] Security headers configured
- [ ] Error handling secure (no stack traces)
- [ ] Logging and monitoring configured
- [ ] Rate limiting implemented
- [ ] File upload validation implemented
- [ ] Debug mode disabled
- [ ] Default credentials changed

### OWASP ASVS Verification
- [ ] Verify against OWASP Application Security Verification Standard (ASVS)
- [ ] Level 1 requirements (basic security)
- [ ] Level 2 requirements (standard security)
- [ ] Level 3 requirements (advanced security)

---

## CROSS-REFERENCES
- For input validation: @security/INPUT-VALIDATION.md
- For authentication: @security/AUTHENTICATION.md
- For security headers: @security/SECURITY-HEADERS.md
- For code injection: @software-engineering/security/CODE-INJECTION.md
