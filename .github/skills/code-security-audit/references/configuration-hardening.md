# Application Configuration Hardening

Reference guidelines for reviewing and auditing operational security configurations, headers, and secret management.

---

## 1. Secret & Credential Leakage Prevention

### High-Risk Indicators
- Hardcoded API keys, private certificates, JWT signing secrets, or database passwords in source code.
- Tracking `.env`, `id_rsa`, or credentials in version control (`.gitignore` missing secret files).
- Exposing secrets in client-side code bundles (e.g. `VITE_` or `NEXT_PUBLIC_` prefixes with sensitive credentials).

### Grep Search Patterns
```bash
# Grep for potential secret assignments
grep -riE "(api[_-]?key|secret[_-]?key|auth[_-]?token|db[_-]?pass|password)\s*[:=]\s*['\"][^'\"]{8,}['\"]" .
```

---

## 2. HTTP Security Headers

Every production application should deliver the following defense-in-depth headers:

| Header | Recommended Value | Purpose |
|---|---|---|
| `Content-Security-Policy` | `default-src 'self'; script-src 'self'; object-src 'none';` | Mitigates XSS and data injection attacks. |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | Enforces HTTPS connections. |
| `X-Frame-Options` | `DENY` or `SAMEORIGIN` | Prevents clickjacking attacks. |
| `X-Content-Type-Options` | `nosniff` | Prevents MIME-type sniffing. |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Limits leakage of sensitive URL query parameters. |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Restricts browser APIs. |

---

## 3. Session & Cookie Hardening

### Auditing Session Configurations
Verify application session settings (e.g., `config/session.php`, express-session options):

- **`http_only`**: MUST be `true` to prevent client-side JavaScript from accessing session tokens.
- **`secure`**: MUST be `true` in production to enforce transmission only over HTTPS.
- **`same_site`**: Should be set to `lax` or `strict` to defend against CSRF attacks.
- **`lifetime` / `maxAge`**: Should enforce reasonable inactivity timeouts (e.g., 120 minutes).
- **Session ID Regeneration**: Ensure session IDs are regenerated upon authentication state changes (login, privilege escalation) to prevent session fixation.

### Session Fixation Defense
Session fixation occurs when an attacker establishes or intercepts an unauthenticated session ID and tricks a victim into authenticating using that identifier. If the server does not regenerate the session token upon authentication, the attacker retains access to the victim's authenticated session.

#### Remediation Patterns
- **PHP (Native)**: Always invoke `session_regenerate_id(true)` immediately upon successful credential validation or privilege escalation. The `true` parameter ensures the old session storage is deleted:
  ```php
  // Safe Login Handler
  if (password_verify($password, $user['password_hash'])) {
      session_regenerate_id(true); // Destroy old session ID and issue new cryptographic token
      $_SESSION['user_id'] = $user['id'];
      $_SESSION['auth_time'] = time();
  }
  ```
- **Laravel**: Framework automatically regenerates session on login via `Auth::attempt()`; for manual flows use `$request->session()->regenerate()`.
- **Node.js (Express)**:
  ```javascript
  req.session.regenerate((err) => {
      if (err) throw err;
      req.session.userId = user.id;
  });
  ```
- **Django**: Django automatically calls `request.session.cycle_key()` on login.

---

## 4. CORS (Cross-Origin Resource Sharing)

### Dangerous Patterns
- `Access-Control-Allow-Origin: *` paired with `Access-Control-Allow-Credentials: true` (invalid in spec, dangerous when dynamically echoed).
- Dynamically reflecting the incoming `Origin` header without an explicit domain allowlist.

### Remediation
- Restrict `allowed_origins` to explicitly verified domain names.
- Avoid wildcard origins on authenticated API endpoints.

---

## 5. Application Encryption-at-Rest & Cipher Auditing

### Auditing ORM Encrypted Attributes
- Ensure Personally Identifiable Information (PII), secrets, financial details, or sensitive health data stored in the database utilize encrypted casting:
  ```php
  // Laravel Eloquent Model
  protected $casts = [
      'ssn' => 'encrypted',
      'api_token' => 'encrypted',
      'bank_account' => 'encrypted',
  ];
  ```
- Verify queries do not attempt raw SQL filters (`WHERE ssn = ...`) on encrypted columns unless deterministic encryption / blind indexing (e.g. CipherSweet) is deliberately implemented.

### Application Key Entropy & Cipher Strength
- Ensure `APP_KEY` / encryption secrets are cryptographically random with sufficient entropy (e.g., 256 bits).
- Verify secure cipher algorithm configuration (e.g. `AES-256-CBC` or `AES-256-GCM` in `config/app.php`). Never use deprecated or weak ciphers (e.g., DES, 3DES, RC4, or unauthenticated modes without MAC).
- Ensure key rotation policies and mechanisms are in place where applicable.

---

## 6. Dependency Freshness & Upgrade Triage

### Auditing Dependency Vulnerabilities & Freshness
Run automated package audit commands to detect known CVEs and assess dependency drift:
```bash
# Security CVE audits
composer audit
npm audit

# Outdated dependency inspection
composer outdated --direct
npm outdated
```

### Semver Risk Categorization & Upgrade Strategy
When triaging outdated packages or security patches, categorize risk according to semantic versioning (SemVer):
- **Patch Releases (`x.y.Z`)**: Bug fixes and backward-compatible security patches. Low risk; prioritize immediate deployment for CVE remediation.
- **Minor Releases (`x.Y.z`)**: New functionality in a backward-compatible manner. Moderate risk; review release notes for deprecations or behavioral changes, test regression suites.
- **Major Releases (`X.y.z`)**: Breaking API changes and architectural shifts. High risk; plan dedicated upgrade tasks with comprehensive integration and acceptance testing.

---

## 7. Timing-Attack Safe Comparison

### Mechanism & Risk
Standard equality operators (`==`, `===`, `strcmp`, `==` in Python/JavaScript) execute byte-by-byte comparisons that return `false` at the very first mismatched byte. An attacker can measure minor execution timing differences (over network averages or local executions) to incrementally guess secrets byte by byte.

### High-Risk Targets
- CSRF token verification.
- HMAC signatures (e.g. webhook verification for Stripe, GitHub, Slack).
- API token / Secret key authentication.
- Password reset tokens, magic links, OTP codes.

### Dangerous Patterns
```php
// VULNERABLE: Short-circuiting equality comparison leaks timing
if ($request->header('X-Webhook-Signature') === $computedHmac) { ... }
if ($userToken === $storedApiSecret) { ... }
```
```python
# VULNERABLE: Python standard comparison short-circuits
if client_token == secret_api_key:
    ...
```

### Remediation: Constant-Time Comparisons

#### PHP
Use native `hash_equals()` which executes in constant time regardless of where or whether strings differ:
```php
// Constant-time token verification
if (!hash_equals($storedCsrfToken, $incomingCsrfToken)) {
    throw new InvalidCsrfTokenException("CSRF token mismatch");
}

// Constant-time webhook HMAC verification
$expectedSignature = hash_hmac('sha256', $payload, $webhookSecret);
if (!hash_equals($expectedSignature, $receivedSignature)) {
    abort(403, 'Invalid signature');
}
```

#### Python
Use `hmac.compare_digest()` or `secrets.compare_digest()`:
```python
import hmac
import secrets

# Constant-time comparison
if not hmac.compare_digest(expected_signature, received_signature):
    raise PermissionDenied("Signature verification failed")
```

#### Node.js
Use `crypto.timingSafeEqual()`:
```javascript
import crypto from 'crypto';

function safeCompare(a, b) {
    const bufA = Buffer.from(a);
    const bufB = Buffer.from(b);
    if (bufA.length !== bufB.length) {
        return false;
    }
    return crypto.timingSafeEqual(bufA, bufB);
}
```


