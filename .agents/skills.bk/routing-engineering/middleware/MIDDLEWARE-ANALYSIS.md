# Middleware Analysis

## Overview

Comprehensive guide to discovering, analyzing, and auditing middleware stacks across frameworks. Middleware is critical for security, performance, and request/response transformation.

## Quick Reference

| Framework | Middleware Location | Order Matters |
|-----------|-------------------|---------------|
| Laravel | `app/Http/Middleware/` | Yes (global first) |
| Symfony | `config/packages/security.yaml`, `src/EventListener/` | Yes |
| Express | `app.use()` calls | Yes (top-down) |
| FastAPI | `@app.middleware("http")` decorators | Yes |
| Django | `MIDDLEWARE` in `settings.py` | Yes (top-down) |
| Flask | `@app.before_request`, `@app.after_request` | Yes |

---

## Phase 1: Framework-Specific Discovery

### Laravel

**Location:** `app/Http/Middleware/` (global), `app/Http/Kernel.php` (registered)

**Discovery Commands:**
```bash
# List global middleware
grep -A 10 "protected \$middleware" app/Http/Kernel.php

# List route middleware
grep -A 20 "protected \$routeMiddleware" app/Http/Kernel.php

# List middleware groups
grep -A 20 "protected \$middlewareGroups" app/Http/Kernel.php

# Find all middleware classes
find app/Http/Middleware -name "*.php"

# Check middleware usage in routes
grep -r "middleware" routes/ --include="*.php"
```

**Middleware Analysis:**

```php
// app/Http/Kernel.php

protected $middleware = [
    // Global middleware (applies to all requests)
    \App\Http\Middleware\TrustProxies::class,
    \App\Http\Middleware\PreventRequestsDuringMaintenance::class,
    \Illuminate\Foundation\Http\Middleware\ValidatePostSize::class,
    \App\Http\Middleware\TrimStrings::class,
    \Illuminate\Foundation\Http\Middleware\ConvertEmptyStringsToNull::class,
];

protected $middlewareGroups = [
    'web' => [
        \App\Http\Middleware\EncryptCookies::class,
        \Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse::class,
        \Illuminate\Session\Middleware\StartSession::class,
        \Illuminate\View\Middleware\ShareErrorsFromSession::class,
        \App\Http\Middleware\VerifyCsrfToken::class,
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],

    'api' => [
        \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        'throttle:api',
        \Illuminate\Routing\Middleware\SubstituteBindings::class,
    ],
];

protected $routeMiddleware = [
    'auth' => \App\Http\Middleware\Authenticate::class,
    'auth.basic' => \Illuminate\Auth\Middleware\AuthenticateWithBasicAuth::class,
    'cache.headers' => \Illuminate\Http\Middleware\SetCacheHeaders::class,
    'can' => \Illuminate\Auth\Middleware\Authorize::class,
    'guest' => \App\Http\Middleware\RedirectIfAuthenticated::class,
    'password.confirm' => \Illuminate\Auth\Middleware\RequirePassword::class,
    'signed' => \Illuminate\Routing\Middleware\ValidateSignature::class,
    'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
    'verified' => \Illuminate\Auth\Middleware\EnsureEmailIsVerified::class,
];
```

**Custom Middleware:**

```php
// app/Http/Middleware/CheckRole.php
class CheckRole
{
    public function handle($request, Closure $next, $role)
    {
        if (!$request->user() || !$request->user()->hasRole($role)) {
            abort(403, 'Unauthorized action.');
        }
        return $next($request);
    }
}

// Route usage
Route::middleware(['auth', 'role:admin'])->group(function () {
    Route::get('/admin', [AdminController::class, 'index']);
});
```

**Middleware Order (Critical):**

1. **TrustProxies** (X-Forwarded headers)
2. **PreventRequestsDuringMaintenance** (maintenance mode)
3. **ValidatePostSize** (large uploads)
4. **TrimStrings** (input sanitization)
5. **EncryptCookies** (cookie encryption)
6. **StartSession** (session management)
7. **VerifyCsrfToken** (CSRF protection)
8. **Authenticate** (user auth)
9. **Authorize** (permission checks)
10. **ThrottleRequests** (rate limiting)
11. **SubstituteBindings** (route model binding)

---

### Symfony

**Location:** `config/packages/security.yaml`, `src/EventListener/`

**Discovery Commands:**
```bash
# List firewall configuration
cat config/packages/security.yaml

# List event listeners
find src/EventListener -name "*.php"

# Debug firewall
bin/console debug:config security
```

**Middleware Analysis:**

```yaml
# config/packages/security.yaml
security:
    firewalls:
        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false

        main:
            lazy: true
            provider: app_user_provider
            json_login:
                check_path: api_login
                username_path: email
                password_path: password
            stateless: true

        secured_area:
            pattern: ^/api
            stateless: true
            jwt: ~

    access_control:
        - { path: ^/api/login, roles: PUBLIC_ACCESS }
        - { path: ^/api/users, roles: ROLE_USER }
        - { path: ^/api/admin, roles: ROLE_ADMIN }
```

**Event Listeners (Middleware equivalent):**

```php
// src/EventListener/RequestListener.php
use Symfony\Component\HttpKernel\Event\RequestEvent;

class RequestListener
{
    public function onKernelRequest(RequestEvent $event)
    {
        $request = $event->getRequest();

        // Add custom headers
        $request->headers->set('X-Request-Id', uniqid());
    }
}

// services.yaml
services:
    App\EventListener\RequestListener:
        tags:
            - { name: kernel.event_listener, event: kernel.request }
```

**Common Listeners:**
- `kernel.request` (request initialization)
- `kernel.controller` (controller selection)
- `kernel.view` (response generation)
- `kernel.response` (response modification)
- `kernel.exception` (exception handling)
- `kernel.terminate` (after response sent)

---

### Express / Node.js

**Location:** Middleware usually in `app.use()` calls or `middleware/` directory

**Discovery Commands:**
```bash
# Find all middleware usage
grep -r "app\.use\|router\.use" . --include="*.js" --include="*.ts"

# Find middleware modules
find . -name "middleware" -type d

# Find third-party middleware
grep -r "require.*express-" . --include="*.js" | grep -i middleware
```

**Middleware Analysis:**

```javascript
// app.js or server.js
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const bodyParser = require('body-parser');

const app = express();

// Security middleware (CRITICAL ORDER)
app.use(helmet());  // Security headers
app.use(cors());  // CORS configuration
app.use(compression());  // gzip compression

// Body parsing
app.use(bodyParser.json());  // Parse JSON
app.use(bodyParser.urlencoded({ extended: true }));  // Parse URL-encoded

// Logging
app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`);
    next();
});

// Rate limiting
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,  // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP'
});

app.use('/api/', apiLimiter);

// Authentication middleware
const authMiddleware = (req, res, next) => {
    const token = req.headers['authorization'];
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

// Apply authentication to specific routes
app.use('/api/protected', authMiddleware);
```

**Middleware Order (Critical):**

1. **helmet()** (security headers)
2. **cors()** (CORS configuration)
3. **compression()** (response compression)
4. **bodyParser** (request body parsing)
5. **session()** (session management)
6. **passport.initialize()** (auth initialization)
7. **passport.session()** (auth session)
8. **rateLimit()** (rate limiting)
9. **logging** (request logging)
10. **custom auth** (authentication checks)
11. **error handlers** (error handling - at end)

**Error Handling Middleware:**

```javascript
// Error handling middleware (must have 4 arguments)
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        error: 'Something went wrong!',
        message: err.message
    });
});

// 404 handler (must be last)
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});
```

---

### FastAPI

**Location:** Middleware defined in `main.py` using decorators

**Discovery Commands:**
```bash
# Find middleware decorators
grep -r "@.*middleware\|app\.add_middleware" . --include="*.py"
```

**Middleware Analysis:**

```python
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.gzip import GZipMiddleware
import time

app = FastAPI()

# Security middleware (CRITICAL ORDER)

# 1. HTTPS redirect (force HTTPS)
app.add_middleware(HTTPSRedirectMiddleware)

# 2. Trusted host (prevent Host header attacks)
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["example.com", "*.example.com"]
)

# 3. CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://example.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 4. GZip compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Custom middleware (process time logging)
@app.middleware("http")
async def add_process_time_header(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Custom middleware (request ID)
import uuid

@app.middleware("http")
async def add_request_id(request: Request, call_next):
    request_id = str(uuid.uuid4())
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response

# Custom middleware (authentication)
@app.middleware("http")
async def auth_middleware(request: Request, call_next):
    if request.url.path.startswith("/public"):
        return await call_next(request)

    token = request.headers.get("Authorization")
    if not token:
        return JSONResponse(
            {"error": "No authorization header"},
            status_code=401
        )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        request.state.user = payload
    except jwt.PyJWTError:
        return JSONResponse(
            {"error": "Invalid token"},
            status_code=401
        )

    response = await call_next(request)
    return response
```

**Middleware Order (Critical):**

1. **HTTPSRedirectMiddleware** (force HTTPS)
2. **TrustedHostMiddleware** (trusted hosts)
3. **CORSMiddleware** (CORS)
4. **GZipMiddleware** (compression)
5. **SessionMiddleware** (sessions)
6. **Authentication** (custom auth)
7. **Authorization** (permission checks)
8. **Rate limiting** (custom rate limit)
9. **Logging** (request logging)
10. **Error handling** (exception handlers)

---

### Django

**Location:** `MIDDLEWARE` setting in `settings.py`

**Discovery Commands:**
```bash
# List middleware
grep -A 20 "MIDDLEWARE" settings.py

# Find custom middleware
find . -name "middleware.py" -o -name "middleware" -type d
```

**Middleware Analysis:**

```python
# settings.py

MIDDLEWARE = [
    # Security middleware
    'django.middleware.security.SecurityMiddleware',  # Security headers
    'django.contrib.sessions.middleware.SessionMiddleware',  # Session management
    'django.middleware.common.CommonMiddleware',  # Common functionality (slash, etc.)
    'django.middleware.csrf.CsrfViewMiddleware',  # CSRF protection
    'django.contrib.auth.middleware.AuthenticationMiddleware',  # User authentication
    'django.contrib.messages.middleware.MessageMiddleware',  # Message framework
    'django.middleware.clickjacking.XFrameOptionsMiddleware',  # Clickjacking protection

    # Custom middleware
    'myapp.middleware.RequestIdMiddleware',  # Add request ID
    'myapp.middleware.RateLimitMiddleware',  # Rate limiting
    'myapp.middleware.LoggingMiddleware',  # Request logging
]

# Custom middleware example
# myapp/middleware.py
import time
import uuid

class RequestIdMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.id = str(uuid.uuid4())
        request.start_time = time.time()
        response = self.get_response(request)
        response['X-Request-ID'] = request.id
        response['X-Process-Time'] = str(time.time() - request.start_time)
        return response

class LoggingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        logger.info(f"{request.method} {request.path}")
        response = self.get_response(request)
        logger.info(f"{request.method} {request.path} - {response.status_code}")
        return response

class RateLimitMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if self.is_rate_limited(request):
            from django.http import HttpResponseForbidden
            return HttpResponseForbidden("Rate limit exceeded")
        return self.get_response(request)

    def is_rate_limited(self, request):
        # Implement rate limiting logic
        return False
```

**Middleware Order (Critical):**

1. **SecurityMiddleware** (security headers)
2. **SessionMiddleware** (session management)
3. **CommonMiddleware** (common functionality)
4. **CsrfViewMiddleware** (CSRF protection)
5. **AuthenticationMiddleware** (user auth)
6. **MessageMiddleware** (messages)
7. **XFrameOptionsMiddleware** (clickjacking)
8. **Custom logging**
9. **Custom rate limiting**
10. **Custom authentication**

**Exception Middleware:**

```python
# myapp/middleware.py
from django.http import JsonResponse

class ExceptionMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        return self.get_response(request)

    def process_exception(self, request, exception):
        if request.path.startswith('/api/'):
            return JsonResponse({
                'error': str(exception),
                'type': type(exception).__name__
            }, status=500)
```

---

### Flask

**Location:** Decorators in `app.py` or separate files

**Discovery Commands:**
```bash
# Find Flask hooks
grep -r "@.*\(before_request\|after_request\|teardown_request\)" . --include="*.py"
```

**Middleware Analysis:**

```python
from flask import Flask, request, g
from flask_compress import Compress
from flask_talisman import Talisman
import time

app = Flask(__name__)

# Security middleware
talisman = Talisman(app, force_https=True)

# Compression
compress = Compress(app)

# Custom middleware (before request)
@app.before_request
def before_request():
    g.start_time = time.time()
    g.request_id = str(uuid.uuid4())

    # CORS check
    origin = request.headers.get('Origin')
    if origin not in ['https://example.com', 'https://www.example.com']:
        return {'error': 'Invalid origin'}, 403

    # Authentication check
    if request.path.startswith('/api/protected'):
        token = request.headers.get('Authorization')
        if not token or not validate_token(token):
            return {'error': 'Unauthorized'}, 401

# Custom middleware (after request)
@app.after_request
def after_request(response):
    # Add custom headers
    response.headers['X-Request-ID'] = g.get('request_id', '')
    response.headers['X-Process-Time'] = str(time.time() - g.get('start_time', 0))

    # CORS headers
    response.headers['Access-Control-Allow-Origin'] = 'https://example.com'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'

    return response

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return {'error': 'Not found'}, 404

@app.errorhandler(500)
def internal_error(error):
    return {'error': 'Internal server error'}, 500

@app.errorhandler(Exception)
def handle_exception(error):
    return {'error': str(error)}, 500
```

**Middleware Execution Order:**

1. **@before_first_request** (once on startup)
2. **@before_request** (before each request - in registration order)
3. **Route handler**
4. **@after_request** (after each request - in reverse registration order)
5. **@teardown_request** (after request processed - in reverse registration order)

---

## Phase 2: Security Middleware Audit

### Critical Security Middleware

| Middleware | Purpose | Severity |
|------------|---------|----------|
| Helmet / SecurityMiddleware | Security headers | Critical |
| CSRF Protection | CSRF tokens | Critical |
| CORS | Cross-origin policies | High |
| Rate Limiting | Prevent abuse | High |
| Authentication | User login | Critical |
| Authorization | Permission checks | Critical |
| Input Sanitization | XSS prevention | High |
| HTTPS Redirect | Force HTTPS | Medium |

**Checklist:**

- [ ] Security headers (X-Content-Type-Options, X-Frame-Options, CSP)
- [ ] CSRF protection on state-changing requests
- [ ] CORS properly configured (restrict origins)
- [ ] Rate limiting on public endpoints
- [ ] Authentication middleware on protected routes
- [ ] Authorization checks (role-based or permission-based)
- [ ] Input sanitization (trim strings, prevent XSS)
- [ ] HTTPS redirection (in production)

### Security Headers Middleware

**Expected Headers:**

```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY or SAMEORIGIN
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=()
```

**Audit Commands:**

```bash
# Test security headers
curl -I https://example.com

# Or use online tools:
# https://securityheaders.com
# https://observatory.mozilla.org
```

---

## Phase 3: Performance Middleware Analysis

### Performance-Optimizing Middleware

| Middleware | Purpose | Impact |
|------------|---------|--------|
| Compression | Gzip responses | High |
| Caching | HTTP caching | High |
| Static File Serving | CDN or efficient serving | Medium |
| Connection Pooling | DB connection reuse | High |
| Response Time Logging | Monitor slow requests | Medium |

**Audit Checklist:**

- [ ] Response compression (gzip, brotli)
- [ ] Cache headers (Cache-Control, ETag)
- [ ] Static file caching
- [ ] Database connection pooling
- [ ] Slow request logging
- [ ] Memory usage monitoring

---

## Phase 4: Common Middleware Vulnerabilities

### 1. Authentication Bypass

**Vulnerable:**
```javascript
app.use((req, res, next) => {
    if (req.path === '/admin') {
        return res.redirect('/login');
    }
    next();
});

app.get('/admin/dashboard', (req, res) => {
    res.send('Admin dashboard');  // No auth check!
});
```

**Fixed:**
```javascript
const authMiddleware = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ error: 'Unauthorized' });
    }
    next();
};

app.get('/admin/dashboard', authMiddleware, (req, res) => {
    res.send('Admin dashboard');
});
```

### 2. CORS Misconfiguration

**Vulnerable:**
```javascript
app.use(cors({ origin: '*' }));  // Allows any origin
```

**Fixed:**
```javascript
app.use(cors({
    origin: ['https://example.com', 'https://www.example.com'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
```

### 3. Missing Rate Limiting

**Vulnerable:**
```javascript
// No rate limiting
app.post('/api/login', (req, res) => {
    // ...
});
```

**Fixed:**
```javascript
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 5,  // 5 login attempts per 15 minutes
    message: 'Too many login attempts'
});

app.post('/api/login', loginLimiter, (req, res) => {
    // ...
});
```

### 4. Information Disclosure

**Vulnerable:**
```javascript
app.use((err, req, res, next) => {
    res.status(500).json({
        error: err.message,  // Exposes internal details
        stack: err.stack  // Exposes stack trace
    });
});
```

**Fixed:**
```javascript
app.use((err, req, res, next) => {
    console.error(err);  // Log internally

    if (process.env.NODE_ENV === 'production') {
        res.status(500).json({
            error: 'Internal server error'
        });
    } else {
        res.status(500).json({
            error: err.message,
            stack: err.stack
        });
    }
});
```

---

## Phase 5: Middleware Order Validation

### Correct Order Example

```javascript
app.use(helmet());  // 1. Security headers
app.use(compression());  // 2. Compression
app.use(cors());  // 3. CORS
app.use(bodyParser.json());  // 4. Body parsing
app.use(session());  // 5. Session
app.use(passport.initialize());  // 6. Auth init
app.use(passport.session());  // 7. Auth session
app.use(authMiddleware);  // 8. Custom auth
app.use(rateLimiter);  // 9. Rate limiting
app.use(loggingMiddleware);  // 10. Logging
app.use(errorHandler);  // 11. Error handling (last)
```

### Incorrect Order Examples

**❌ Bad - Body parser before helmet:**
```javascript
app.use(bodyParser.json());  // Wrong order
app.use(helmet());  // Should be first
```

**❌ Bad - Auth before session:**
```javascript
app.use(authMiddleware);  // Wrong - requires session
app.use(session());  // Should be before auth
```

**❌ Bad - Error handler before routes:**
```javascript
app.use(errorHandler);  // Wrong - catches everything
app.use('/api', apiRoutes);  // Never reached
```

---

## Phase 6: Automated Middleware Audit

### Middleware Audit Commands

```bash
# 1. Check for security middleware
# Laravel
grep -r "TrustProxies\|VerifyCsrfToken" app/Http/

# Express
grep -r "helmet\|cors" . --include="*.js"

# FastAPI
grep -r "CORSMiddleware\|HTTPSRedirectMiddleware" . --include="*.py"

# 2. Check for authentication middleware
grep -r "auth\|Authenticate" routes/ --include="*.php" --include="*.js" --include="*.py"

# 3. Check for rate limiting
grep -r "throttle\|rateLimit\|rate_limit" . --include="*.php" --include="*.js" --include="*.py"

# 4. Check for CORS configuration
grep -r "cors\|CORS" . --include="*.php" --include="*.js" --include="*.py"

# 5. Check for error handling middleware
grep -r "errorHandler\|process_exception\|error" . --include="*.js" --include="*.py"

# 6. Check middleware order
grep -n "app\.use\|router\.use" . --include="*.js"

# 7. Check for unused middleware
grep -r "middleware" routes/ | grep -v "auth\|csrf\|throttle"
```

---

## Summary

Middleware analysis involves:
1. **Discovering middleware** (framework-specific locations and patterns)
2. **Auditing security** (headers, CORS, CSRF, rate limiting, auth)
3. **Analyzing performance** (compression, caching, logging)
4. **Checking vulnerabilities** (auth bypass, CORS misconfig, info disclosure)
5. **Validating order** (security first, then parsing, then auth, then logging)
6. **Automated audits** (command-line checks for missing/incorrect middleware)

Use this guide to comprehensively analyze middleware stacks across frameworks.
