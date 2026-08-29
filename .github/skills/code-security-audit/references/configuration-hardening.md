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

---

## 4. CORS (Cross-Origin Resource Sharing)

### Dangerous Patterns
- `Access-Control-Allow-Origin: *` paired with `Access-Control-Allow-Credentials: true` (invalid in spec, dangerous when dynamically echoed).
- Dynamically reflecting the incoming `Origin` header without an explicit domain allowlist.

### Remediation
- Restrict `allowed_origins` to explicitly verified domain names.
- Avoid wildcard origins on authenticated API endpoints.

