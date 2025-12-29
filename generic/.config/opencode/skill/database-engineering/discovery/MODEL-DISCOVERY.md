# MODEL DISCOVERY

## OVERVIEW
Model discovery automatically identifies ORM entities, models, and their relationships from existing codebase.

## DETECTION PATTERNS

### Laravel (PHP)

**Model Files**:
```php
// app/Models/User.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $fillable = ['name', 'email', 'password'];

    public function posts()  // One-to-Many relationship
    {
        return $this->hasMany(Post::class);
    }

    public function profile()  // One-to-One relationship
    {
        return $this->hasOne(Profile::class);
    }
}
```

**Detection Rules**:
- Models extend `Illuminate\Database\Eloquent\Model`
- Model files in `app/Models/` directory
- Relationships: `hasMany()`, `hasOne()`, `belongsTo()`, `belongsToMany()`
- Fillable: Array of mass-assignable attributes
- Table name: Snake_case class name

---

### Django (Python)

**Model Files**:
```python
# models.py
from django.db import models

class User(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)

    def posts(self):  # One-to-Many
        return self.post_set.all()

    def profile(self):  # One-to-One
        return self.profile
```

**Detection Rules**:
- Models extend `django.db.models.Model`
- Model files in `models.py`
- Relationships: `ForeignKey`, `OneToOneField`, `ManyToManyField`
- Related names: `<model>_set` for reverse relationships

---

### SQLAlchemy (Python)

**Model Files**:
```python
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String, ForeignKey

Base = declarative_base()

class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    name = Column(String(100))
    email = Column(String(255), unique=True)

    # One-to-Many relationship
    posts = relationship("Post", back_populates="user")
```

**Detection Rules**:
- Classes extend `declarative_base`
- `__tablename__` defines table name
- Relationships via `relationship()` decorator
- `ForeignKey` for foreign keys
- `back_populates` for bidirectional relationships

---

### Sequelize (Node.js)

**Model Files**:
```javascript
// models/User.js
const { Model, DataTypes } = require('sequelize');

class User extends Model {}
User.init({
    name: DataTypes.STRING(100),
    email: DataTypes.STRING(255),
    password: DataTypes.STRING(255)
}, {
    sequelize,
    modelName: 'User'
});

User.hasMany(Post, { as: 'posts' });
```

**Detection Rules**:
- Classes extend `Model`
- `init()` defines schema
- Relationships: `hasMany()`, `hasOne()`, `belongsTo()`, `belongsToMany()`
- `as` option for relationship naming

---

## RELATIONSHIP MAPPING

### One-to-One (1:1)

**Example**: User has one Profile

**Laravel**:
```php
// User model
public function profile()
{
    return $this->hasOne(Profile::class);
}

// Profile model
public function user()
{
    return $this->belongsTo(User::class);
}
```

**Detection Pattern**:
- `$this->hasOne()` → One-to-Many from user's perspective
- `$this->belongsTo()` → One-to-Many from profile's perspective
- Foreign key on belongsTo side

---

### One-to-Many (1:N)

**Example**: User has many Posts

**Laravel**:
```php
// User model
public function posts()
{
    return $this->hasMany(Post::class);
}

// Post model
public function user()
{
    return $this->belongsTo(User::class);
}
```

**Detection Pattern**:
- `$this->hasMany()` → One-to-Many (user side)
- `$this->belongsTo()` → One-to-Many (post side)
- Multiple related records

---

### Many-to-Many (N:M)

**Example**: Users have many Roles, Roles have many Users

**Laravel**:
```php
// User model
public function roles()
{
    return $this->belongsToMany(Role::class);
}

// Role model
public function users()
{
    return $this->belongsToMany(User::class);
}
```

**Detection Pattern**:
- `$this->belongsToMany()` → Many-to-Many
- Requires pivot table (user_role)
- Both sides have belongsToMany

---

### Self-Referencing

**Example**: User has parent/children (tree structure)

**Laravel**:
```php
class User extends Model
{
    public function parent()
    {
        return $this->belongsTo(User::class, 'parent_id');
    }

    public function children()
    {
        return $this->hasMany(User::class, 'parent_id');
    }
}
```

**Detection Pattern**:
- Self-reference via `$this->belongsTo(Self::class)`
- Parent/child relationship with same model

---

## ENTITY IDENTIFICATION

### Primary Key Detection

**Auto-Increment**:
```php
// Laravel: id column auto-detected as primary key
class User extends Model {
    // id field automatically primary key
}

// Django: AutoField automatically primary key
id = models.AutoField(primary_key=True)
```

**Composite Primary Keys**:
```php
// Laravel: Composite key via $primaryKey property
class OrderItem extends Model
{
    protected $primaryKey = ['order_id', 'product_id'];
}
```

### Foreign Key Detection

**Laravel**:
```php
// foreign() on migrations
$table->foreign('user_id')->references('id')->on('users');
```

**Django**:
```python
# ForeignKey field
user = models.ForeignKey(User, on_delete=models.CASCADE)
```

---

## AUTOMATIC DISCOVERY ALGORITHM

### Step 1: Scan Model Files
```bash
# Find all model files
find . -name "*.php" -path "*/Models/*"
find . -name "models.py"
find . -name "*Model.js" -path "*/models/*"
```

### Step 2: Extract Models
```python
# Pseudo-code for model extraction
models = []

for file in model_files:
    if file.endswith('.php'):
        models.extend(extract_laravel_models(file))
    elif file.endswith('.py'):
        models.extend(extract_django_models(file))
    elif file.endswith('.js'):
        models.extend(extract_sequelize_models(file))
```

### Step 3: Map Relationships
```python
# Pseudo-code for relationship mapping
relationships = []

for model in models:
    for method in model.methods:
        if method.returns_related_models():
            relationships.append({
                'from': model.name,
                'to': method.related_model,
                'type': method.relationship_type  # 1:1, 1:N, N:M
            })
```

### Step 4: Visualize Relationships
```mermaid
erDiagram
    User ||--o{ Post : has
    User ||--o{ Profile : has
    User }|..|{ Role : belongs to
```

---

## COMMON ANTI-PATTERNS

### 1. God Models

**Detection**: Models with too many relationships (> 10) and methods (> 50)

**Problem**:
```php
class User extends Model {
    // 50+ fields and methods
    public function posts() { }
    public function comments() { }
    public function likes() { }
    public function ratings() { }
    public function messages() { }
    // ... many more
}
```

**Fix**: Split into focused models

---

### 2. Circular Dependencies

**Detection**: Models reference each other causing issues

**Problem**:
```python
# A depends on B
class A(models.Model):
    b = models.ForeignKey(B)

# B depends on A
class B(models.Model):
    a = models.ForeignKey(A)
```

**Fix**: Extract shared fields to new model

---

## DISCOVERY TOOLS

### Laravel
```bash
# List all models
php artisan model:list

# Show model relationships
php artisan model:show User

# Generate model diagram
php artisan model:diagram
```

### Django
```python
# Show models
python manage.py showmigrations

# Inspect model
python manage.py inspectdb

# Django extensions: django-extensions
# pip install django-extensions
python manage.py graph_models -a
```

### ORM Designer Tools
- **Laravel**: dbdiagram.io, laravel-erd
- **Django**: Django Graphviz
- **Sequelize**: Sequelize UI, Sequelize-Typescript

---

## CROSS-REFERENCES
- For relationship patterns: @design/RELATIONSHIP-MAPPING.md
- For N+1 detection: @relational/NPLUS1.md
- For SQL injection: @relational/SQL-INJECTION.md
- For query optimization: @relational/INDEXING.md
