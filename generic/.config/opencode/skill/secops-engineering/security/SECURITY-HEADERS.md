# SECURITY HEADERS

## OVERVIEW
HTTP security headers protect against various attacks by instructing browsers on how to handle content.

## CRITICAL SECURITY HEADERS

### 1. Content-Security-Policy (CSP)

**Purpose**: Restricts resources (scripts, styles, images, etc.) the browser can load.

**Attack Prevented**: XSS attacks by disallowing inline scripts.

**Example**:
```http
Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-2726c7f26c' https://cdn.example.com; style-src 'self' 'unsafe-inline' https://cdn.example.com; img-src 'self' data: https://cdn.example.com; font-src 'self' https://cdn.example.com; connect-src 'self'; frame-ancestors 'none';
```

**Breakdown**:
- `default-src 'self'`: Load resources from same origin by default
- `script-src 'self'`: Only load scripts from same origin
- `nonce-*`: Allow specific inline scripts with nonce
- `unsafe-inline`: Allow inline styles (but not scripts)
- `frame-ancestors 'none'`: Prevent clickjacking

**Implementation**:

**PHP**:
```php
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-" . $nonce . " https://cdn.example.com");
```

**Nginx**:
```nginx
add_header Content-Security-Policy "default-src 'self'; script-src 'self' https://cdn.example.com";
```

**Apache**:
```apache
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' https://cdn.example.com"
```

**Report-Only Mode** (for testing):
```http
Content-Security-Policy-Report-Only: default-src 'self'; script-src 'self'
```

---

### 2. Strict-Transport-Security (HSTS)

**Purpose**: Enforces HTTPS connections, preventing downgrade attacks.

**Attack Prevented**: Man-in-the-middle (MITM) attacks, SSL stripping.

**Example**:
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

**Breakdown**:
- `max-age=31536000`: 1 year (31,536,000 seconds)
- `includeSubDomains`: Apply to all subdomains
- `preload`: Browser preloads domain (requires https://hstspreload.org/)

**Implementation**:

**PHP**:
```php
header("Strict-Transport-Security: max-age=31536000; includeSubDomains");
```

**Nginx**:
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

**Apache**:
```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
```

**Important**: Only set HSTS after confirming HTTPS works correctly.

---

### 3. X-Frame-Options

**Purpose**: Prevents clickjacking attacks by controlling framing.

**Attack Prevented**: Clickjacking (embedding site in invisible frames).

**Example**:
```http
X-Frame-Options: SAMEORIGIN
```

**Values**:
- `DENY`: No framing allowed
- `SAMEORIGIN`: Only allow framing from same origin
- `ALLOW-FROM uri`: Allow framing from specific URL

**Implementation**:

**PHP**:
```php
header("X-Frame-Options: SAMEORIGIN");
```

**Nginx**:
```nginx
add_header X-Frame-Options "SAMEORIGIN";
```

**Apache**:
```apache
Header always set X-Frame-Options "SAMEORIGIN"
```

---

### 4. X-Content-Type-Options

**Purpose**: Prevents MIME-sniffing attacks.

**Attack Prevented**: Browser interpreting files as different MIME types.

**Example**:
```http
X-Content-Type-Options: nosniff
```

**Implementation**:

**PHP**:
```php
header("X-Content-Type-Options: nosniff");
```

**Nginx**:
```nginx
add_header X-Content-Type-Options "nosniff";
```

**Apache**:
```apache
Header always set X-Content-Type-Options "nosniff"
```

---

### 5. X-XSS-Protection

**Purpose**: Activates browser's XSS filter.

**Example**:
```http
X-XSS-Protection: 1; mode=block
```

**Values**:
- `0`: Disable filter (if you have your own XSS protection)
- `1`: Enable filter
- `1; mode=block`: Enable filter and block XSS attempts

**Implementation**:

**PHP**:
```php
header("X-XSS-Protection: 1; mode=block");
```

**Nginx**:
```nginx
add_header X-XSS-Protection "1; mode=block";
```

**Apache**:
```apache
Header always set X-XSS-Protection "1; mode=block"
```

---

### 6. Referrer-Policy

**Purpose**: Controls how much referrer information is sent.

**Attack Prevented**: Information leakage, referrer-based tracking.

**Example**:
```http
Referrer-Policy: strict-origin-when-cross-origin
```

**Values**:
- `no-referrer`: No referrer sent
- `no-referrer-when-downgrade`: No referrer when going from HTTPS to HTTP
- `origin`: Only send origin (no path)
- `strict-origin`: Send origin only for same-origin requests
- `strict-origin-when-cross-origin`: Send full URL for same-origin, origin only for cross-origin
- `unsafe-url`: Send full URL (least secure)

**Implementation**:

**PHP**:
```php
header("Referrer-Policy: strict-origin-when-cross-origin");
```

**Nginx**:
```nginx
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

**Apache**:
```apache
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

---

### 7. Permissions-Policy (formerly Feature-Policy)

**Purpose**: Disables browser features (geolocation, camera, microphone, etc.).

**Attack Prevented**: Unauthorized access to device features.

**Example**:
```http
Permissions-Policy: geolocation=(self), camera=(), microphone=(self)
```

**Breakdown**:
- `geolocation=(self)`: Only allow geolocation from same origin
- `camera=()`: Completely block camera access
- `microphone=(self)`: Allow microphone from same origin

**Implementation**:

**PHP**:
```php
header("Permissions-Policy: geolocation=(self), camera=(), microphone=(self)");
```

**Nginx**:
```nginx
add_header Permissions-Policy "geolocation=(self), camera=(), microphone=(self)";
```

**Apache**:
```apache
Header always set Permissions-Policy "geolocation=(self), camera=(), microphone=(self)"
```

---

### 8. Cross-Origin-Opener-Policy (COOP)

**Purpose**: Prevents cross-origin window attacks (Spectre-like attacks).

**Example**:
```http
Cross-Origin-Opener-Policy: same-origin
```

**Values**:
- `same-origin`: Only allow same-origin popups
- `same-origin-allow-popups`: Allow popups but restrict navigation
- `unsafe-none`: No restrictions

---

### 9. Cross-Origin-Resource-Policy (CORP)

**Purpose**: Restricts cross-origin resource loading.

**Example**:
```http
Cross-Origin-Resource-Policy: same-origin
```

**Values**:
- `same-origin`: Only load from same origin
- `same-site`: Load from same site
- `cross-origin`: Allow cross-origin (unsafe)

---

## REMOVING INFORMATIONAL HEADERS

### 1. Server Header

**Purpose**: Hide server software version to reduce attack surface.

**Attack Prevented**: Version-specific exploits.

**Implementation**:

**Nginx**:
```nginx
server_tokens off;  # Hide Nginx version

# Or custom header
server {
    more_clear_headers Server;
}
```

**Apache**:
```apache
ServerTokens Prod  # Only show "Apache", not version
ServerSignature Off
```

### 2. X-Powered-By Header

**Purpose**: Remove technology information.

**Implementation**:

**PHP**:
```php
header_remove('X-Powered-By');
```

**Nginx**:
```nginx
fastcgi_hide_header X-Powered-By;
```

---

## COMPLETE SECURITY HEADER CONFIGURATION

### Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'nonce-{random_nonce}'; object-src 'none';" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(self), camera=(), microphone=(self)" always;

    # Hide server info
    server_tokens off;

    # Security options
    add_header X-Content-Type-Options "nosniff" always;

    # Remove informational headers
    more_clear_headers Server;
    more_clear_headers X-Powered-By;

    location / {
        # Your application config
        try_files $uri $uri/ /index.php?$query_string;
    }
}
```

### Apache

```apache
<VirtualHost *:443>
    ServerName example.com

    # Security headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' https://cdn.example.com"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "geolocation=(self), camera=()"

    # Hide server info
    ServerTokens Prod
    ServerSignature Off

    # Remove informational headers
    Header unset X-Powered-By
    Header unset Server

    # Your application config
    DocumentRoot /var/www/html
</VirtualHost>
```

### PHP Middleware

```php
class SecurityHeadersMiddleware
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        // Set security headers
        $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        $response->headers->set('Content-Security-Policy', "default-src 'self'; script-src 'self'");
        $response->headers->set('X-Frame-Options', 'SAMEORIGIN');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'geolocation=(self), camera=()');

        return $response;
    }
}

// Register middleware
app->middleware([SecurityHeadersMiddleware::class]);
```

### Express Middleware

```javascript
const helmet = require('helmet');

app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            objectSrc: ["'none'"]
        }
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    frameguard: {
        action: 'sameorigin'
    },
    noSniff: true,
    xssFilter: true,
    referrerPolicy: {
        policy: 'strict-origin-when-cross-origin'
    },
    permissionPolicy: {
        features: {
            geolocation: ["'self'"],
            camera: ["'none'"],
            microphone: ["'self'"]
        }
    }
}));
```

---

## TESTING SECURITY HEADERS

### 1. Using Browser DevTools

1. Open DevTools (F12)
2. Go to Network tab
3. Refresh page
4. Click on any request
5. Check Response Headers section

### 2. Using curl

```bash
curl -I https://example.com
```

**Output**:
```
HTTP/2 200
content-type: text/html; charset=UTF-8
strict-transport-security: max-age=31536000; includeSubDomains
content-security-policy: default-src 'self'
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
x-xss-protection: 1; mode=block
referrer-policy: strict-origin-when-cross-origin
```

### 3. Online Tools

- https://securityheaders.com/
- https://observatory.mozilla.org/
- https://csperalyzer.com/

---

## SECURITY HEADER CHECKLIST

### Before Deployment
- [ ] Content-Security-Policy set (prevent XSS)
- [ ] Strict-Transport-Security set (prevent MITM)
- [ ] X-Frame-Options set (prevent clickjacking)
- [ ] X-Content-Type-Options set (prevent MIME sniffing)
- [ ] X-XSS-Protection set (XSS filter)
- [ ] Referrer-Policy set (information leakage)
- [ ] Permissions-Policy set (device access)
- [ ] Server header removed/minimized
- [ ] X-Powered-By header removed
- [ ] Headers tested with securityheaders.com
- [ ] HTTPS properly configured before HSTS

---

## CROSS-REFERENCES
- For OWASP Top 10: @owasp/OWASP-TOP10.md
- For input validation: @security/INPUT-VALIDATION.md
- For XSS prevention: @security/INPUT-VALIDATION.md (XSS section)
- For CSRF prevention: @security/INPUT-VALIDATION.md (CSRF section)
