# RELATIONSHIP MAPPING

## OVERVIEW
Relationship mapping defines how entities relate to each other in database design.

## ONE-TO-ONE (1:1)

### Description
Each record in Table A relates to at most one record in Table B, and vice versa.

### Schema

```
users (1) ←→ (1) profiles
```

### Implementation

**PostgreSQL**:
```sql
-- Option 1: Foreign key in users table
CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    bio TEXT,
    user_id INTEGER UNIQUE REFERENCES users(id)
);

CREATE UNIQUE INDEX idx_profiles_user ON profiles(user_id);

-- Option 2: Foreign key in profiles table (recommended)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE profiles (
    id SERIAL PRIMARY KEY,
    bio TEXT,
    user_id INTEGER UNIQUE REFERENCES users(id)
);
```

**Laravel**:
```php
// User model
class User extends Model
{
    public function profile()
    {
        return $this->hasOne(Profile::class);
    }
}

// Profile model
class Profile extends Model
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

// Usage
$user = User::find(1);
$profile = $user->profile;  // Loads related profile
```

**Django**:
```python
# models.py
class User(models.Model):
    name = models.CharField(max_length=100)

class Profile(models.Model):
    bio = models.TextField()
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile'
    )
```

---

## ONE-TO-MANY (1:N)

### Description
Each record in Table A relates to multiple records in Table B.

### Schema

```
users (1) ←→ (N) orders
```

### Implementation

**PostgreSQL**:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    total DECIMAL(10,2),
    created_at TIMESTAMP
);

CREATE INDEX idx_orders_user ON orders(user_id);
```

**Laravel**:
```php
// User model
class User extends Model
{
    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}

// Order model
class Order extends Model
{
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}

// Eager loading
$orders = User::with('orders')->find(1);

// Lazy loading
$user = User::find(1);
foreach ($user->orders as $order) { }
```

**Django**:
```python
# models.py
class User(models.Model):
    name = models.CharField(max_length=100)

class Order(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='orders'
    )
    total = models.DecimalField(max_digits=10, decimal_places=2)
```

---

## MANY-TO-MANY (N:M)

### Description
Each record in Table A relates to multiple records in Table B, and vice versa.

### Schema

```
users (N) ←→ (M) roles
```

### Implementation

**PostgreSQL**:
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE user_roles (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);
```

**Laravel**:
```php
// User model
class User extends Model
{
    public function roles()
    {
        return $this->belongsToMany(Role::class);
    }
}

// Role model
class Role extends Model
{
    public function users()
    {
        return $this->belongsToMany(User::class);
    }
}

// Pivot table automatically: user_role
$users = User::find(1);
$roles = $users->roles;  // Collection of roles
```

**Django**:
```python
# models.py
class User(models.Model):
    name = models.CharField(max_length=100)

class Role(models.Model):
    name = models.CharField(max_length=100)

class UserRole(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)

# Or use ManyToMany (automatically creates pivot)
class User(models.Model):
    roles = models.ManyToManyField(Role)

# Reverse relation in Role
class Role(models.Model):
    users = models.ManyToManyField(User)
```

---

## POLYMORPHIC RELATIONSHIPS

### Description
Entity can be related to multiple different entity types.

### Schema

```
comments
    ├─ post (polymorphic to posts table)
    ├─ video (polymorphic to videos table)
    └─ image (polymorphic to images table)
```

### Implementation

**PostgreSQL**:
```sql
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255)
);

CREATE TABLE videos (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255)
);

CREATE TABLE images (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    commentable_type VARCHAR(50),
    commentable_id INTEGER,
    content TEXT
);

CREATE INDEX idx_comments_commentable ON comments(commentable_type, commentable_id);
```

**Laravel**:
```php
// Comment model
class Comment extends Model
{
    public function commentable()
    {
        return $this->morphTo();
    }
}

// Post model
class Post extends Model
{
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}

// Video model
class Video extends Model
{
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}

// Image model
class Image extends Model
{
    public function comments()
    {
        return $this->morphMany(Comment::class, 'commentable');
    }
}
```

**Django**:
```python
# models.py
from django.db import models
from django.contrib.contenttypes.fields import GenericForeignKey

class Post(models.Model):
    title = models.CharField(max_length=255)

class Video(models.Model):
    title = models.CharField(max_length=255)

class Image(models.Model):
    title = models.CharField(max_length=255)

class Comment(models.Model):
    comment = models.TextField()

    # Polymorphic relationship
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()

    content_object = GenericForeignKey(
        ContentType,
        object_id_field_name='object_id'
    )

    def get_content_object(self):
        return self.content_object
```

---

## SELF-REFERENCING RELATIONSHIPS

### Description
Entity relates to itself (hierarchies, nested sets).

### Schema

```
categories (1) ←→ (N) subcategories
```

### Implementation

**PostgreSQL**:
```sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    parent_id INTEGER REFERENCES categories(id)
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
```

**Laravel**:
```php
class Category extends Model
{
    public function parent()
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    public function children()
    {
        return $this->hasMany(Category::class, 'parent_id');
    }
}

// Usage
$category = Category::find(1);
$children = $category->children;
```

**Django**:
```python
class Category(models.Model):
    name = models.CharField(max_length=100)
    parent = models.ForeignKey('self', null=True, blank=True)

    def get_children(self):
        return Category.objects.filter(parent=self)

    def get_descendants(self):
        return Category.objects.filter(parent__in=self.get_children())
```

---

## CASCADE RULES

### Foreign Key Cascading

**ON DELETE**: What happens when referenced record is deleted
- `CASCADE`: Delete all related records
- `SET NULL`: Set foreign key to NULL
- `RESTRICT`: Prevent deletion if related records exist
- `SET DEFAULT`: Set foreign key to default value

**Laravel**:
```php
// Default: CASCADE for belongsTo
public function user()
{
    return $this->belongsTo(User::class, 'onDelete', 'cascade');
}

// Soft deletes: Restore deleted records
public function softDelete()
{
    $this->deleted_at = now();
}
```

---

## CROSS-REFERENCES
- For model discovery: @discovery/MODEL-DISCOVERY.md
- For database design: @design/DATABASE-DESIGN.md
- For N+1 queries: @relational/NPLUS1.md
