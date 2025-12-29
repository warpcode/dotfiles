# Route Discovery & Analysis

## Overview

Comprehensive guide to discovering, analyzing, and mapping routing architecture across frameworks.

## Quick Reference

| Framework | Route File Location | Convention |
|-----------|-------------------|------------|
| Laravel | `routes/*.php` | Closure-based or Controller method |
| Symfony | `config/routes.yaml` | YAML, Annotations, or PHP |
| Express | `app.js` or `routes/*.js` | `app.get/post/put/delete()` |
| FastAPI | `app.py` | `@app.get/post/put/delete()` decorator |
| Django | `urls.py` | `path()` or `re_path()` |
| Flask | `app.py` or `views.py` | `@app.route()` decorator |

---

## Phase 1: Framework-Specific Discovery

### Laravel

**Location:** `routes/*.php` (web.php, api.php, console.php, channels.php)

**Detection Commands:**
```bash
# Find all route files
find routes/ -name '*.php'

# List all registered routes
php artisan route:list

# Show routes with middleware
php artisan route:list --columns=uri,middleware

# Show routes for specific controller
php artisan route:list --controller=UserController

# Show route cache status
php artisan route:cache --status
```

**Route Analysis Checklist:**

```php
// Standard route definition
Route::get('/users', [UserController::class, 'index'])->name('users.index');
Route::post('/users', [UserController::class, 'store'])->name('users.store');
Route::get('/users/{user}', [UserController::class, 'show'])->name('users.show');
Route::put('/users/{user}', [UserController::class, 'update'])->name('users.update');
Route::delete('/users/{user}', [UserController::class, 'destroy'])->name('users.destroy');

// Resource routes (CRUD)
Route::resource('users', UserController::class);

// API resource routes (exclude create/edit)
Route::apiResource('users', UserController::class);

// Grouped routes with middleware
Route::middleware(['auth', 'throttle:60,1'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index']);
});

// Route prefixes
Route::prefix('api/v1')->group(function () {
    Route::resource('users', UserController::class);
});

// Subdomain routing
Route::domain('{account}.example.com')->group(function () {
    Route::get('users/{id}', function ($account, $id) {
        //
    });
});

// Route model binding
Route::get('/users/{user}', function (User $user) {
    return $user;
});

// Explicit binding
Route::bind('user', function ($value) {
    return User::where('slug', $value)->firstOrFail();
});
```

**Key Patterns:**
- Closure routes vs Controller routes
- Route groups (middleware, prefix, subdomain)
- Route model binding (implicit vs explicit)
- Resource routes vs individual routes
- Named routes (important for URL generation)

---

### Symfony

**Location:** `config/routes.yaml` or `src/Controller/*.php` (annotations/attributes)

**Detection Commands:**
```bash
# Debug routes
bin/console debug:router

# Show specific route
bin/console debug:router app_home

# Show routes for a specific bundle
bin/console debug:router --show-aliases

# Match a URL to a route
bin/console router:match /users/123
```

**Route Analysis:**

```yaml
# config/routes.yaml
app_home:
    path: /
    controller: App\Controller\HomeController::index

app_users:
    path: /users
    controller: App\Controller\UserController::index
    methods: [GET]

app_user_show:
    path: /users/{id}
    controller: App\Controller\UserController::show
    methods: [GET]
    requirements:
        id: '\d+'
```

```php
// src/Controller/UserController.php
use Symfony\Component\Routing\Annotation\Route;

class UserController extends AbstractController
{
    #[Route('/users', name: 'app_users', methods: ['GET'])]
    public function index(): JsonResponse
    {
        //
    }

    #[Route('/users/{id}', name: 'app_user_show', methods: ['GET'], requirements: ['id' => '\d+'])]
    public function show(int $id): JsonResponse
    {
        //
    }
}
```

**Key Patterns:**
- YAML config vs PHP attributes
- Method requirements
- Parameter requirements (regex)
- Route names (for `generateUrl()`)

---

### Express / Node.js

**Location:** Usually in `app.js`, `server.js`, or `routes/*.js`

**Detection Strategy:**
```bash
# Find route files
grep -r "app\.\(get\|post\|put\|delete\)" . --include="*.js" --include="*.ts"

# Find Express router instances
grep -r "require.*express.*Router" . --include="*.js" --include="*.ts"

# Find route exports
grep -r "module\.exports.*router" . --include="*.js" --include="*.ts"
```

**Route Analysis:**

```javascript
// app.js or server.js
const express = require('express');
const app = express();

// Basic routes
app.get('/users', (req, res) => {
    res.json(users);
});

app.post('/users', (req, res) => {
    const user = createUser(req.body);
    res.status(201).json(user);
});

// Route parameters
app.get('/users/:id', (req, res) => {
    const user = users.find(u => u.id === req.params.id);
    res.json(user);
});

// Optional parameters
app.get('/users/:id?', (req, res) => {
    const id = req.params.id;
    // ...
});

// Router modules
const userRoutes = require('./routes/users');
app.use('/api/users', userRoutes);

// routes/users.js
const router = express.Router();

router.get('/', (req, res) => { /* ... */ });
router.post('/', (req, res) => { /* ... */ });
router.get('/:id', (req, res) => { /* ... */ });
router.put('/:id', (req, res) => { /* ... */ });
router.delete('/:id', (req, res) => { /* ... */ });

module.exports = router;
```

**Key Patterns:**
- Express Router for modular routes
- Route parameters (req.params)
- Middleware stacks
- RESTful route patterns

---

### FastAPI

**Location:** `main.py`, `app.py`, or `routers/*.py`

**Detection Strategy:**
```bash
# Find FastAPI route decorators
grep -r "@.*app\.\(get\|post\|put\|delete\)" . --include="*.py"

# Find APIRouter usage
grep -r "from fastapi import.*APIRouter" . --include="*.py"
```

**Route Analysis:**

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Basic routes
@app.get("/users")
async def get_users():
    return users

@app.get("/users/{user_id}")
async def get_user(user_id: int):
    return users[user_id]

# Path validation
@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str = None):
    return {"item_id": item_id, "q": q}

# Request body validation
from pydantic import BaseModel

class UserCreate(BaseModel):
    name: str
    email: str

@app.post("/users")
async def create_user(user: UserCreate):
    new_user = create_user(user)
    return new_user

# Router modules
from routers import users

app.include_router(users.router, prefix="/api/v1", tags=["users"])
```

**Key Patterns:**
- Decorator-based routing
- Automatic validation (Pydantic)
- Type hints for parameters
- Router modules with `include_router()`

---

### Django

**Location:** `urls.py` (project and app level)

**Detection Commands:**
```bash
# Show all URLs
python manage.py show_urls  # requires django-extensions

# Find url.py files
find . -name "urls.py" -not -path "*/venv/*"
```

**Route Analysis:**

```python
# myproject/urls.py
from django.urls import path, include
from django.contrib import admin

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('myapp.urls')),
]

# myapp/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('users/', views.user_list, name='user-list'),
    path('users/<int:user_id>/', views.user_detail, name='user-detail'),
    path('users/<int:user_id>/edit/', views.user_edit, name='user-edit'),
]

# URL patterns with regex
from django.urls import re_path

urlpatterns = [
    re_path(r'^articles/(?P<year>[0-9]{4})/$', views.year_archive),
]
```

**View Implementation:**

```python
# myapp/views.py
from django.http import JsonResponse

def user_list(request):
    users = User.objects.all()
    return JsonResponse(list(users.values()), safe=False)

def user_detail(request, user_id):
    user = get_object_or_404(User, pk=user_id)
    return JsonResponse(model_to_dict(user))
```

**Key Patterns:**
- Project vs app-level URL configuration
- Path converters (str, int, slug, uuid, path)
- Named URLs (for `{% url %}` template tag)
- Include() for modular URLs

---

### Flask

**Location:** `app.py` or `views.py`

**Detection Strategy:**
```bash
# Find Flask routes
grep -r "@.*route\(" . --include="*.py"
```

**Route Analysis:**

```python
from flask import Flask, jsonify, request

app = Flask(__name__)

# Basic routes
@app.route('/users', methods=['GET'])
def get_users():
    return jsonify(users)

@app.route('/users', methods=['POST'])
def create_user():
    user_data = request.get_json()
    user = create_user(user_data)
    return jsonify(user), 201

# Route parameters
@app.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = get_user_by_id(user_id)
    return jsonify(user)

# String parameters
@app.route('/users/<username>')
def get_user_by_username(username):
    user = get_user_by_username(username)
    return jsonify(user)

# Blueprints (modular routes)
from flask import Blueprint

user_bp = Blueprint('users', __name__)

@user_bp.route('/', methods=['GET'])
def get_users():
    return jsonify(users)

@user_bp.route('/<int:user_id>', methods=['GET'])
def get_user(user_id):
    return jsonify(get_user_by_id(user_id))

app.register_blueprint(user_bp, url_prefix='/api/users')
```

**Key Patterns:**
- Decorator-based routing
- Route methods array
- Blueprints for modular routes
- Type-annotated parameters (int, string, path, uuid)

---

## Phase 2: Route Classification

### Static Routes

Routes with no parameters.

**Examples:**
- `/about`
- `/contact`
- `/api/status`

**Detection:** Route definitions with no parameters.

**Analysis:**
- Should map to page-level content or static resources
- Should use caching headers (Cache-Control, ETag)
- Should be SEO-friendly for public pages

### Dynamic Routes

Routes with parameters.

**Examples:**
- `/users/:id`
- `/posts/:slug`
- `/products/:category/:id`

**Detection:** Route definitions with `:param`, `{param}`, `<param>`, or `<converter:param>`.

**Analysis:**
- Parameter validation (type, format, allowed values)
- Parameter sanitization (SQL injection, XSS)
- 404 handling for invalid parameters
- Parameter extraction for analytics

### Optional Parameters

Routes with optional segments.

**Examples:**
- `/products/:category?` (Express)
- `/products/<category?>` (Flask)

**Analysis:**
- Clear default behavior when parameter is omitted
- Avoid ambiguous routing (optional at end only)

### Query Parameters

Parameters after `?`.

**Examples:**
- `/users?page=2&limit=20`
- `/search?q=term&sort=date`

**Analysis:**
- Validation of query parameters
- Type coercion (string to int/boolean)
- Default values
- Pagination parameters (page, limit, offset)
- Sorting parameters (sort_by, order)
- Filtering parameters

---

## Phase 3: Route Grouping Analysis

### Middleware Groups

Routes sharing middleware stacks.

**Detection:**
```bash
# Laravel
grep -r "Route::middleware" routes/

# Express
grep -r "router\|app\.use" . --include="*.js"
```

**Analysis:**

| Middleware Type | Purpose | Security Impact |
|----------------|---------|-----------------|
| Authentication | Protect private routes | Critical |
| Rate Limiting | Prevent abuse | Important |
| CORS | Allow/deny domains | Important |
| CSRF Protection | Prevent CSRF attacks | Critical for forms |
| Logging | Track requests | Medium |
| Validation | Validate input | Important |

**Examples:**

```javascript
// Express
const authMiddleware = require('./middleware/auth');
const rateLimit = require('express-rate-limit');

const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});

router.use(authMiddleware);
router.use(apiLimiter);
router.get('/protected', handler);
```

### Route Prefixes

Shared URL prefixes.

**Examples:**
- `/api/v1/users`
- `/api/v2/users`
- `/admin/users`

**Analysis:**
- API versioning strategy
- Admin vs public routes
- Environment-specific routes (`/dev/`, `/staging/`)

---

## Phase 4: RESTful Conformance Check

### Resource Naming

**✅ Good:**
- `/users` (plural nouns)
- `/orders/123/items` (nested resources)
- `/users/{id}/profile` (single subresource)

**❌ Bad:**
- `/getUser` (verb)
- `/user` (singular)
- `/users/{id}/getProfile` (verb in URL)

### HTTP Method Usage

| Method | Purpose | Idempotent? | Safe? |
|--------|---------|-------------|-------|
| GET | Retrieve resource | Yes | Yes |
| POST | Create resource | No | No |
| PUT | Replace resource | Yes | No |
| PATCH | Partial update | No | No |
| DELETE | Delete resource | Yes | No |

**Detection:**
```bash
# Check for inconsistent methods
grep -r "app\.post.*'/users/:id'" . --include="*.js"  # POST should not be used for updates
```

### Status Code Usage

| Code | Meaning |
|------|---------|
| 200 | OK (GET, PUT, PATCH) |
| 201 | Created (POST) |
| 204 | No Content (DELETE) |
| 400 | Bad Request (validation error) |
| 401 | Unauthorized (not logged in) |
| 403 | Forbidden (no permission) |
| 404 | Not Found |
| 422 | Unprocessable Entity (validation) |
| 500 | Internal Server Error |

---

## Phase 5: Security Analysis

### Route-Level Vulnerabilities

#### 1. IDOR (Insecure Direct Object Reference)

**Vulnerable:**
```javascript
app.get('/users/:id', (req, res) => {
    const user = User.findById(req.params.id);  // No authorization check
    res.json(user);
});
```

**Fixed:**
```javascript
app.get('/users/:id', authMiddleware, (req, res) => {
    if (req.user.id !== req.params.id && !req.user.isAdmin) {
        return res.status(403).json({ error: 'Forbidden' });
    }
    const user = User.findById(req.params.id);
    res.json(user);
});
```

#### 2. Parameter Pollution

**Vulnerable:**
```javascript
// Request: GET /users?id=1&id=2
app.get('/users', (req, res) => {
    const id = req.query.id;  // May be '1,2' or just '2' depending on framework
    // ...
});
```

**Fixed:**
```javascript
app.get('/users', (req, res) => {
    const ids = Array.isArray(req.query.id) ? req.query.id : [req.query.id];
    // Validate single ID only
    // ...
});
```

#### 3. Path Traversal

**Vulnerable:**
```javascript
app.get('/files/*', (req, res) => {
    const filename = req.params[0];
    res.sendFile(path.join(__dirname, 'uploads', filename));
});
```

**Fixed:**
```javascript
const path = require('path');

app.get('/files/*', (req, res) => {
    const filename = req.params[0];
    const safePath = path.join(__dirname, 'uploads', filename);
    const realPath = path.resolve(safePath);
    const uploadDir = path.resolve(__dirname, 'uploads');

    if (!realPath.startsWith(uploadDir)) {
        return res.status(403).json({ error: 'Invalid path' });
    }

    res.sendFile(realPath);
});
```

---

## Phase 6: Performance Analysis

### N+1 Query Detection in Routes

**Vulnerable:**
```python
# GET /users
@app.get("/users")
async def get_users():
    users = db.query(User).all()  # 1 query
    result = []
    for user in users:
        orders = db.query(Order).filter(Order.user_id == user.id).all()  # N queries
        result.append({"user": user, "orders": orders})
    return result
```

**Fixed:**
```python
@app.get("/users")
async def get_users():
    users = db.query(User).options(joinedload(User.orders)).all()  # 1 query with JOIN
    return users
```

### Route Caching Strategy

**Static Routes (Cache: Long-term):**
```javascript
app.get('/about', cache('1d'), (req, res) => {
    res.render('about');
});
```

**Dynamic Routes (Cache: Short-term):**
```javascript
app.get('/users/:id', cache('5m'), async (req, res) => {
    const user = await User.findById(req.params.id);
    res.json(user);
});
```

**No Cache (Always fresh):**
```javascript
app.post('/users', (req, res) => {
    // Never cache
});
```

---

## Phase 7: Route Documentation

### API Documentation Requirements

For each route, document:

```markdown
## GET /users

**Description:** Retrieve a paginated list of users.

**Authentication:** Required (Bearer token)

**Permissions:** `users:read`

**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number |
| limit | integer | No | 20 | Items per page (max 100) |
| sort_by | string | No | id | Sort field (id, name, email) |
| order | string | No | asc | Sort order (asc, desc) |
| search | string | No | | Search in name/email |

**Response:**
```json
{
    "data": [...],
    "meta": {
        "page": 1,
        "limit": 20,
        "total": 150
    }
}
```

**Status Codes:**
- 200: Success
- 401: Unauthorized
- 403: Forbidden
```

---

## Phase 8: Automated Route Analysis

### Route Audit Checklist

Run these commands for comprehensive route analysis:

```bash
# 1. List all routes
# Laravel
php artisan route:list

# Symfony
bin/console debug:router

# Express
grep -r "app\.\(get\|post\|put\|delete\)" . --include="*.js"

# FastAPI
grep -r "@.*app\.\(get\|post\|put\|delete\)" . --include="*.py"

# Django
python manage.py show_urls

# 2. Check for unauthenticated sensitive routes
grep -r "DELETE\|PUT\|PATCH" routes/ | grep -v "middleware.*auth"

# 3. Check for rate limiting on public routes
grep -r "POST\|PUT" routes/ | grep -v "throttle\|rateLimit"

# 4. Check for parameter validation
grep -r "req\.params\|req\.query" . --include="*.js" | head -20

# 5. Check for IDOR vulnerabilities
grep -r "\.findById(req\.params\." . --include="*.js" | grep -v "auth\|permission"

# 6. Check for SQL injection patterns
grep -r "query.*req\.params" . --include="*.js" --include="*.py"
```

---

## Summary

Route discovery involves:
1. **Identifying route files** (framework-specific locations)
2. **Classifying routes** (static, dynamic, query parameters)
3. **Analyzing groups** (middleware, prefixes)
4. **Checking RESTful conformance** (resource naming, HTTP methods)
5. **Security analysis** (IDOR, parameter pollution, path traversal)
6. **Performance analysis** (N+1 queries, caching)
7. **Documentation** (API specs, examples)
8. **Automated audits** (command-line checks)

Use this guide to comprehensively analyze routing architecture across frameworks.
