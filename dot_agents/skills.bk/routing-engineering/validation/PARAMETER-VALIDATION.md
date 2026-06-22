# Parameter Validation

## Overview

Comprehensive guide to validating route parameters, query parameters, and request bodies across frameworks. Proper validation prevents security vulnerabilities (SQLi, XSS), ensures data integrity, and provides better error messages.

## Quick Reference

| Framework | Validation Mechanism | Location |
|-----------|---------------------|----------|
| Laravel | `Validator::make()`, Form Requests | Controllers, `app/Http/Requests/` |
| Symfony | `Validator` component, `Assert` annotations | Entities, Controllers |
| Express | `express-validator`, `joi`, `zod` | Middleware, Controllers |
| FastAPI | Pydantic models, `Query()`, `Path()`, `Body()` | Route handlers |
| Django | Forms, DRF serializers, `clean_*` methods | Forms, Serializers, Models |
| Flask | `Flask-WTF`, `marshmallow`, `jsonschema` | Forms, Serializers |

---

## Phase 1: Route Parameter Validation

### Route Parameters (URI Parameters)

Parameters in the path: `/users/:id`, `/posts/:slug`

#### Laravel

```php
Route::get('/users/{id}', function ($id) {
    // Validate route parameter
    $validator = Validator::make(['id' => $id], [
        'id' => 'required|integer|min:1|max:999999'
    ]);

    if ($validator->fails()) {
        return response()->json(['error' => 'Invalid user ID'], 400);
    }

    $user = User::findOrFail($id);
    return $user;
});

// Or use route constraints
Route::get('/users/{id}', function ($id) {
    return User::findOrFail($id);
})->where('id', '[0-9]+');

// Multiple constraints
Route::get('/posts/{category}/{slug}', function ($category, $slug) {
    return Post::whereCategory($category)->whereSlug($slug)->firstOrFail();
})->where([
    'category' => '[a-z]+',
    'slug' => '[a-z0-9-]+'
]);
```

**Route Parameter Regex Patterns:**

| Type | Pattern | Example |
|------|---------|---------|
| Integer | `[0-9]+` | 123 |
| UUID | `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}` | 550e8400-e29b-41d4-a716-446655440000 |
| Slug | `[a-z0-9-]+` | my-blog-post |
| Email | `[^@]+@[^@]+\.[^@]+` | user@example.com |
| Date | `\d{4}-\d{2}-\d{2}` | 2025-01-15 |

#### Express

```javascript
const { param, validationResult } = require('express-validator');

app.get('/users/:id',
    param('id')
        .isInt({ min: 1 })
        .withMessage('ID must be a positive integer'),
    (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const user = User.findById(req.params.id);
        res.json(user);
    }
);

// Or manual validation
app.get('/users/:id', (req, res) => {
    const id = parseInt(req.params.id);

    if (isNaN(id) || id < 1) {
        return res.status(400).json({ error: 'Invalid user ID' });
    }

    const user = User.findById(id);
    res.json(user);
});
```

#### FastAPI

```python
from fastapi import FastAPI, Path, HTTPException
from pydantic import BaseModel

app = FastAPI()

@app.get("/users/{user_id}")
async def get_user(
    user_id: int = Path(..., gt=0, le=999999, description="User ID")
):
    user = await User.get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.get("/posts/{category}/{slug}")
async def get_post(
    category: str = Path(..., regex="^[a-z]+$", description="Category"),
    slug: str = Path(..., regex="^[a-z0-9-]+$", description="Post slug")
):
    post = await Post.get(category, slug)
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    return post
```

**Pydantic Path Validators:**

```python
from pydantic import BaseModel, field_validator

class UserPathParams(BaseModel):
    user_id: int

    @field_validator('user_id')
    @classmethod
    def validate_user_id(cls, v):
        if v <= 0:
            raise ValueError('User ID must be positive')
        if v > 999999:
            raise ValueError('User ID too large')
        return v

@app.get("/users/{user_id}")
async def get_user(path: UserPathParams):
    return await User.get(path.user_id)
```

#### Django

```python
from django.urls import path
from django.shortcuts import get_object_or_404

# URL pattern validation (path converters)
urlpatterns = [
    path('users/<int:user_id>/', views.user_detail),
    path('posts/<slug:post_slug>/', views.post_detail),
    path('uuid/<uuid:uuid>/', views.uuid_detail),
]

# View validation
def user_detail(request, user_id):
    # user_id is already validated as integer by URL converter

    if user_id < 1:
        return JsonResponse({'error': 'Invalid user ID'}, status=400)

    user = get_object_or_404(User, pk=user_id)
    return JsonResponse(model_to_dict(user))
```

**Django Path Converters:**

| Converter | Pattern | Example |
|-----------|---------|---------|
| `str` | Any non-slash string | `hello` |
| `int` | Positive integers | `123` |
| `slug` | Slug strings | `my-post` |
| `uuid` | UUID format | `550e8400-e29b-41d4-a716-446655440000` |
| `path` | Any string including slashes | `foo/bar` |

#### Flask

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/users/<int:user_id>')
def get_user(user_id):
    # user_id is already validated as integer
    if user_id < 1:
        return jsonify({'error': 'Invalid user ID'}), 400

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    return jsonify(user.to_dict())

# String parameter with validation
@app.route('/posts/<slug:post_slug>')
def get_post(post_slug):
    # post_slug matches [a-zA-Z0-9_-]+ by default
    if not re.match(r'^[a-z0-9-]+$', post_slug):
        return jsonify({'error': 'Invalid slug format'}), 400

    post = Post.query.filter_by(slug=post_slug).first()
    if not post:
        return jsonify({'error': 'Post not found'}), 404

    return jsonify(post.to_dict())
```

**Flask Route Parameter Types:**

| Type | Pattern | Example |
|------|---------|---------|
| `string` | Any non-slash string (default) | `hello` |
| `int` | Positive integers | `123` |
| `float` | Positive floats | `3.14` |
| `path` | Any string including slashes | `foo/bar` |
| `uuid` | UUID format | `550e8400-e29b-41d4-a716-446655440000` |

---

## Phase 2: Query Parameter Validation

### Query Parameters

Parameters after `?`: `?page=2&limit=20&sort=date`

#### Laravel

```php
Route::get('/users', function (Request $request) {
    $validator = Validator::make($request->all(), [
        'page' => 'nullable|integer|min:1',
        'limit' => 'nullable|integer|min:1|max:100',
        'sort_by' => 'nullable|in:id,name,email,created_at',
        'order' => 'nullable|in:asc,desc',
        'search' => 'nullable|string|max:255',
    ]);

    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }

    $page = $request->input('page', 1);
    $limit = $request->input('limit', 20);
    $sortBy = $request->input('sort_by', 'id');
    $order = $request->input('order', 'asc');

    $users = User::orderBy($sortBy, $order)
        ->paginate($limit, ['*'], 'page', $page);

    return $users;
});

// Using Form Request (better separation)
class UserIndexRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'page' => 'nullable|integer|min:1',
            'limit' => 'nullable|integer|min:1|max:100',
            'sort_by' => 'nullable|in:id,name,email,created_at',
            'order' => 'nullable|in:asc,desc',
            'search' => 'nullable|string|max:255',
        ];
    }
}

Route::get('/users', function (UserIndexRequest $request) {
    $page = $request->validated('page', 1);
    $limit = $request->validated('limit', 20);

    return User::paginate($limit);
});
```

**Laravel Validation Rules:**

| Rule | Purpose | Example |
|------|---------|---------|
| `required` | Field must be present | `required` |
| `nullable` | Field can be null | `nullable` |
| `integer` | Must be integer | `integer` |
| `min:X` | Minimum value | `min:1` |
| `max:X` | Maximum value | `max:100` |
| `in:foo,bar` | Must be in list | `in:asc,desc` |
| `regex:pattern` | Match regex | `regex:/^[a-z]+$/` |
| `email` | Valid email | `email` |
| `url` | Valid URL | `url` |
| `date` | Valid date | `date` |
| `boolean` | Must be boolean | `boolean` |
| `array` | Must be array | `array` |

#### Express

```javascript
const { query, validationResult } = require('express-validator');

app.get('/users',
    query('page').optional().isInt({ min: 1 }).toInt(),
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
    query('sort_by').optional().isIn(['id', 'name', 'email', 'created_at']),
    query('order').optional().isIn(['asc', 'desc']),
    query('search').optional().isString().isLength({ max: 255 }),
    (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const page = req.query.page || 1;
        const limit = req.query.limit || 20;
        const sortBy = req.query.sort_by || 'id';
        const order = req.query.order || 'asc';
        const search = req.query.search;

        const users = User.find(search ? { name: new RegExp(search, 'i') } : {})
            .sort({ [sortBy]: order })
            .skip((page - 1) * limit)
            .limit(limit);

        res.json(users);
    }
);

// Using Zod for validation
const { z } = require('zod');

const UserQuerySchema = z.object({
    page: z.coerce.number().int().min(1).optional().default(1),
    limit: z.coerce.number().int().min(1).max(100).optional().default(20),
    sort_by: z.enum(['id', 'name', 'email', 'created_at']).optional().default('id'),
    order: z.enum(['asc', 'desc']).optional().default('asc'),
    search: z.string().max(255).optional(),
});

app.get('/users', (req, res) => {
    try {
        const query = UserQuerySchema.parse(req.query);
        const users = User.find().skip((query.page - 1) * query.limit).limit(query.limit);
        res.json(users);
    } catch (err) {
        res.status(400).json({ errors: err.errors });
    }
});
```

**Express-Validator Validators:**

| Validator | Purpose | Example |
|-----------|---------|---------|
| `optional()` | Parameter is optional | `optional()` |
| `isInt()` | Must be integer | `isInt({ min: 1 })` |
| `isIn()` | Must be in list | `isIn(['asc', 'desc'])` |
| `isString()` | Must be string | `isString()` |
| `isLength()` | String length | `isLength({ max: 255 })` |
| `isEmail()` | Valid email | `isEmail()` |
| `isURL()` | Valid URL | `isURL()` |
| `isDate()` | Valid date | `isDate()` |
| `isBoolean()` | Must be boolean | `isBoolean()` |
| `toArray()` | Convert to array | `toArray()` |
| `toInt()` | Convert to int | `toInt()` |

#### FastAPI

```python
from fastapi import FastAPI, Query
from typing import Optional, List

app = FastAPI()

@app.get("/users")
async def get_users(
    page: int = Query(1, ge=1, description="Page number"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    sort_by: str = Query("id", regex="^(id|name|email|created_at)$"),
    order: str = Query("asc", regex="^(asc|desc)$"),
    search: Optional[str] = Query(None, max_length=255)
):
    skip = (page - 1) * limit
    users = await User.find(search).skip(skip).limit(limit)
    return users

# Using Pydantic for complex validation
from pydantic import BaseModel, Field

class UserQuery(BaseModel):
    page: int = Field(1, ge=1, description="Page number")
    limit: int = Field(20, ge=1, le=100, description="Items per page")
    sort_by: str = Field("id", regex="^(id|name|email|created_at)$")
    order: str = Field("asc", regex="^(asc|desc)$")
    search: Optional[str] = Field(None, max_length=255)

@app.get("/users")
async def get_users(query: UserQuery = Query()):
    skip = (query.page - 1) * query.limit
    users = await User.find(query.search).skip(skip).limit(query.limit)
    return users

# Array query parameters
@app.get("/users/filter")
async def filter_users(
    ids: List[int] = Query([], description="List of user IDs"),
    statuses: List[str] = Query([], regex="^(active|inactive|pending)$")
):
    users = await User.find({"_id": {"$in": ids}, "status": {"$in": statuses}})
    return users
```

**FastAPI Query Validators:**

| Validator | Purpose | Example |
|-----------|---------|---------|
| `default=...` | Default value | `default=1` |
| `ge=X` | Greater or equal | `ge=1` |
| `gt=X` | Greater than | `gt=0` |
| `le=X` | Less or equal | `le=100` |
| `lt=X` | Less than | `lt=1000` |
| `regex="..."` | Match regex | `regex="^(asc|desc)$"` |
| `min_length=X` | Min string length | `min_length=3` |
| `max_length=X` | Max string length | `max_length=255` |
| `alias="..."` | Alternative name | `alias="sort"` |

#### Django

```python
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.db.models import Q

def user_list(request):
    # Query parameter validation
    try:
        page = int(request.GET.get('page', 1))
        limit = int(request.GET.get('limit', 20))
        sort_by = request.GET.get('sort_by', 'id')
        order = request.GET.get('order', 'asc')
        search = request.GET.get('search', '')

        # Validate
        if page < 1:
            return JsonResponse({'error': 'Invalid page number'}, status=400)
        if limit < 1 or limit > 100:
            return JsonResponse({'error': 'Limit must be between 1 and 100'}, status=400)
        if sort_by not in ['id', 'name', 'email', 'created_at']:
            return JsonResponse({'error': 'Invalid sort field'}, status=400)
        if order not in ['asc', 'desc']:
            return JsonResponse({'error': 'Invalid order direction'}, status=400)

        # Query
        sort_field = f'-{sort_by}' if order == 'desc' else sort_by
        queryset = User.objects.all()

        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) | Q(email__icontains=search)
            )

        queryset = queryset.order_by(sort_field)

        # Paginate
        paginator = Paginator(queryset, limit)
        users = paginator.get_page(page)

        return JsonResponse({
            'data': list(users.object_list.values()),
            'meta': {
                'page': page,
                'limit': limit,
                'total': paginator.count,
                'pages': paginator.num_pages
            }
        })

    except (ValueError, TypeError):
        return JsonResponse({'error': 'Invalid parameter format'}, status=400)

# Using DRF serializers for better validation
from rest_framework import serializers

class UserQuerySerializer(serializers.Serializer):
    page = serializers.IntegerField(required=False, default=1, min_value=1)
    limit = serializers.IntegerField(required=False, default=20, min_value=1, max_value=100)
    sort_by = serializers.ChoiceField(
        required=False,
        default='id',
        choices=['id', 'name', 'email', 'created_at']
    )
    order = serializers.ChoiceField(required=False, default='asc', choices=['asc', 'desc'])
    search = serializers.CharField(required=False, max_length=255, allow_blank=True)

def user_list(request):
    serializer = UserQuerySerializer(data=request.GET)
    if not serializer.is_valid():
        return JsonResponse(serializer.errors, status=400)

    data = serializer.validated_data
    queryset = User.objects.all().order_by(data['sort_by'])
    return JsonResponse(list(queryset.values()), safe=False)
```

**Django Validation:**

| Validation | Purpose | Example |
|------------|---------|---------|
| `required=False` | Optional field | `required=False` |
| `default=X` | Default value | `default=1` |
| `min_value=X` | Minimum value | `min_value=1` |
| `max_value=X` | Maximum value | `max_value=100` |
| `choices=[...]` | Must be in list | `choices=['asc', 'desc']` |
| `max_length=X` | Max string length | `max_length=255` |
| `allow_blank=True` | Allow empty string | `allow_blank=True` |

#### Flask

```python
from flask import Flask, request, jsonify
from marshmallow import Schema, fields, validate, ValidationError

app = Flask(__name__)

class UserQuerySchema(Schema):
    page = fields.Integer(load_default=1, validate=validate.Range(min=1))
    limit = fields.Integer(load_default=20, validate=validate.Range(min=1, max=100))
    sort_by = fields.String(
        load_default='id',
        validate=validate.OneOf(['id', 'name', 'email', 'created_at'])
    )
    order = fields.String(
        load_default='asc',
        validate=validate.OneOf(['asc', 'desc'])
    )
    search = fields.String(load_default='', validate=validate.Length(max=255))

@app.route('/users')
def get_users():
    try:
        query = UserQuerySchema().load(request.args)
    except ValidationError as err:
        return jsonify({'errors': err.messages}), 400

    page = query['page']
    limit = query['limit']
    sort_by = query['sort_by']
    order = query['order']
    search = query['search']

    # Query and paginate
    users = User.query
    if search:
        users = users.filter(User.name.ilike(f'%{search}%'))

    users = users.order_by(
        getattr(getattr(User, sort_by).desc() if order == 'desc' else sort_by)()
    )

    pagination = users.paginate(page=page, per_page=limit, error_out=False)

    return jsonify({
        'data': [user.to_dict() for user in pagination.items],
        'meta': {
            'page': page,
            'limit': limit,
            'total': pagination.total,
            'pages': pagination.pages
        }
    })
```

**Marshmallow Validators:**

| Validator | Purpose | Example |
|-----------|---------|---------|
| `required=True` | Field required | `required=True` |
| `load_default=X` | Default value | `load_default=1` |
| `validate.Range()` | Range validation | `validate.Range(min=1, max=100)` |
| `validate.OneOf()` | Must be in list | `validate.OneOf(['asc', 'desc'])` |
| `validate.Length()` | String length | `validate.Length(max=255)` |
| `validate.Email()` | Valid email | `validate.Email()` |
| `validate.URL()` | Valid URL | `validate.URL()` |

---

## Phase 3: Request Body Validation

### POST/PUT Request Bodies

#### Laravel

```php
// Using Form Request
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:admin,user,moderator',
            'bio' => 'nullable|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'email.required' => 'The email field is required.',
            'email.email' => 'Please provide a valid email address.',
            'email.unique' => 'This email is already registered.',
            'password.min' => 'Password must be at least 8 characters.',
        ];
    }
}

Route::post('/users', function (StoreUserRequest $request) {
    $user = User::create($request->validated());
    return response()->json($user, 201);
});

// Manual validation
Route::post('/users', function (Request $request) {
    $validator = Validator::make($request->all(), [
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users,email',
        'password' => 'required|string|min:8',
    ]);

    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }

    $user = User::create($request->all());
    return response()->json($user, 201);
});

// Nested array validation
Route::post('/orders', function (Request $request) {
    $validator = Validator::make($request->all(), [
        'user_id' => 'required|exists:users,id',
        'items' => 'required|array|min:1',
        'items.*.product_id' => 'required|exists:products,id',
        'items.*.quantity' => 'required|integer|min:1',
    ]);

    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }

    $order = Order::create($request->validated());
    return response()->json($order, 201);
});
```

#### Express

```javascript
const { body, validationResult } = require('express-validator');
const { z } = require('zod');

// Using express-validator
app.post('/users',
    body('name')
        .trim()
        .notEmpty()
        .withMessage('Name is required')
        .isLength({ max: 255 })
        .withMessage('Name too long'),
    body('email')
        .trim()
        .notEmpty()
        .withMessage('Email is required')
        .isEmail()
        .withMessage('Invalid email')
        .normalizeEmail(),
    body('password')
        .notEmpty()
        .withMessage('Password is required')
        .isLength({ min: 8 })
        .withMessage('Password must be at least 8 characters'),
    body('role')
        .optional()
        .isIn(['admin', 'user', 'moderator'])
        .withMessage('Invalid role'),
    (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(422).json({ errors: errors.array() });
        }

        const user = await User.create(req.body);
        res.status(201).json(user);
    }
);

// Using Zod (type-safe)
const UserSchema = z.object({
    name: z.string().min(1).max(255),
    email: z.string().email(),
    password: z.string().min(8),
    role: z.enum(['admin', 'user', 'moderator']).optional(),
    bio: z.string().max(1000).optional(),
});

app.post('/users', async (req, res) => {
    try {
        const data = UserSchema.parse(req.body);
        const user = await User.create(data);
        res.status(201).json(user);
    } catch (err) {
        res.status(422).json({ errors: err.errors });
    }
});

// Nested validation with Zod
const OrderSchema = z.object({
    user_id: z.number().int().positive(),
    items: z.array(z.object({
        product_id: z.number().int().positive(),
        quantity: z.number().int().positive(),
    })).min(1),
});

app.post('/orders', async (req, res) => {
    try {
        const data = OrderSchema.parse(req.body);
        const order = await Order.create(data);
        res.status(201).json(order);
    } catch (err) {
        res.status(422).json({ errors: err.errors });
    }
});
```

#### FastAPI

```python
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import List, Optional

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=8)
    role: str = Field(default='user', pattern='^(admin|user|moderator)$')
    bio: Optional[str] = Field(None, max_length=1000)

    @field_validator('email')
    @classmethod
    def email_must_be_lowercase(cls, v: str) -> str:
        return v.lower()

    @field_validator('password')
    @classmethod
    def password_strength(cls, v: str) -> str:
        if not any(c.isupper() for c in v):
            raise ValueError('Password must contain uppercase letter')
        if not any(c.isdigit() for c in v):
            raise ValueError('Password must contain digit')
        return v

@app.post("/users")
async def create_user(user_data: UserCreate):
    user = await User.create(user_data.model_dump())
    return user

# Nested validation
class OrderItemCreate(BaseModel):
    product_id: int = Field(..., gt=0)
    quantity: int = Field(..., gt=0)

class OrderCreate(BaseModel):
    user_id: int = Field(..., gt=0)
    items: List[OrderItemCreate] = Field(..., min_length=1)

    @field_validator('items')
    @classmethod
    def validate_items(cls, v: List[OrderItemCreate]) -> List[OrderItemCreate]:
        if len(v) > 100:
            raise ValueError('Cannot have more than 100 items')
        return v

@app.post("/orders")
async def create_order(order_data: OrderCreate):
    order = await Order.create(order_data.model_dump())
    return order
```

---

## Phase 4: Security Validation

### Common Security Validations

#### SQL Injection Prevention

```php
// ❌ VULNERABLE: Direct concatenation
$user = DB::select("SELECT * FROM users WHERE id = " . $_GET['id']);

// ✅ SECURE: Parameter binding
$user = DB::select("SELECT * FROM users WHERE id = ?", [$id]);

// Or using ORM
$user = User::find($id);
```

```javascript
// ❌ VULNERABLE: Direct concatenation
const user = await db.query(`SELECT * FROM users WHERE id = ${req.params.id}`);

// ✅ SECURE: Parameter binding
const user = await db.query('SELECT * FROM users WHERE id = ?', [req.params.id]);

// Or using ORM
const user = await User.findByPk(req.params.id);
```

#### XSS Prevention

```php
// ❌ VULNERABLE: Unescaped output
echo $_GET['name'];

// ✅ SECURE: Escaped output
echo htmlspecialchars($_GET['name'], ENT_QUOTES, 'UTF-8');

// Or using template engine
{{ $name }}  <!-- Automatically escaped in Laravel Blade -->
```

```javascript
// ❌ VULNERABLE: Unescaped output
res.send(`<h1>${req.query.name}</h1>`);

// ✅ SECURE: Escaped output
res.send(`<h1>${escapeHtml(req.query.name)}</h1>`);

// Or using template engine
// React/JSX automatically escapes
```

#### File Upload Validation

```php
// Validate file upload
$validator = Validator::make($request->all(), [
    'avatar' => 'required|image|mimes:jpg,jpeg,png,gif|max:2048',
    // Max 2MB, allowed formats
]);

if ($validator->fails()) {
    return response()->json(['error' => 'Invalid file'], 422);
}

// Store file
$path = $request->file('avatar')->store('avatars', 'public');
```

```javascript
const multer = require('multer');
const { extname } = require('path');

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, 'uploads/'),
    filename: (req, file, cb) => cb(null, Date.now() + extname(file.originalname))
});

const upload = multer({
    storage,
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['.jpg', '.jpeg', '.png', '.gif'];
        const ext = extname(file.originalname).toLowerCase();
        if (allowedTypes.includes(ext)) {
            cb(null, true);
        } else {
            cb(new Error('Invalid file type'));
        }
    },
    limits: { fileSize: 2 * 1024 * 1024 }  // 2MB
});

app.post('/upload', upload.single('avatar'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }
    res.json({ path: req.file.path });
});
```

---

## Phase 5: Validation Error Responses

### Standard Error Response Format

```json
{
  "error": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "The email field is required."
    },
    {
      "field": "password",
      "message": "Password must be at least 8 characters."
    }
  ],
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### Framework-Specific Formats

**Laravel:**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password must be at least 8 characters."]
  }
}
```

**Express (express-validator):**
```json
{
  "errors": [
    {
      "location": "body",
      "msg": "Email is required",
      "path": "email",
      "type": "field"
    }
  ]
}
```

**FastAPI:**
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "field required",
      "type": "value_error.missing"
    },
    {
      "loc": ["body", "password"],
      "msg": "ensure this value has at least 8 characters",
      "type": "value_error.any_str.min_length",
      "ctx": { "limit_value": 8 }
    }
  ]
}
```

---

## Phase 6: Automated Validation Audit

### Validation Checklist

```bash
# 1. Check for missing input validation
grep -r "req\.body\|req\.query\|req\.params" . --include="*.js" | grep -v "validate\|sanitize"

# 2. Check for SQL injection vulnerabilities
grep -r "SELECT.*WHERE.*req\." . --include="*.js" --include="*.php" --include="*.py"

# 3. Check for XSS vulnerabilities
grep -r "innerHTML\|dangerouslySetInnerHTML" . --include="*.js" --include="*.jsx"

# 4. Check for file upload validation
grep -r "upload\|multer\|move_uploaded_file" . --include="*.js" --include="*.php"

# 5. Check for parameter type validation
grep -r "parseInt\|Number(" . --include="*.js"

# 6. Check for email validation
grep -r "email" . --include="*.js" --include="*.php" --include="*.py" | grep -v "validate\|regex"

# 7. Check for password complexity
grep -r "password" . --include="*.js" --include="*.php" --include="*.py" | grep -v "min.*8\|complexity"
```

---

## Summary

Parameter validation involves:
1. **Route parameters** (type, format, regex validation)
2. **Query parameters** (optional, defaults, ranges, choices)
3. **Request bodies** (required fields, types, nested arrays)
4. **Security validations** (SQLi prevention, XSS prevention, file upload validation)
5. **Error responses** (standard format, helpful messages)
6. **Automated audits** (check for missing validation, common vulnerabilities)

Use this guide to implement comprehensive validation across frameworks.
