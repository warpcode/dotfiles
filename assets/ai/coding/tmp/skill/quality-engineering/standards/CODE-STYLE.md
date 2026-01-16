# Code Style

## Overview

Comprehensive guide to code style and linting standards across languages. Consistent code style improves readability, maintainability, and reduces merge conflicts.

---

## General Style Principles

### 1. Be Consistent

- Use same formatting across all files
- Follow language-specific conventions
- Stick to chosen style (don't mix styles)

### 2. Be Minimal

- Avoid excessive comments
- Don't add dead code
- Keep functions focused and small

### 3. Be Readable

- Write code that explains itself
- Use meaningful variable/function names
- Limit line length (usually 80-120 characters)

### 4. Be Predictable

- Place imports at top of file
- Organize code in logical sections
- Use consistent structure for similar operations

---

## JavaScript / TypeScript Style

### Formatting

**Indentation:** 2 spaces (no tabs)

```javascript
// ✅ Good - 2 spaces
function calculateTotal(items) {
    let total = 0;
    for (const item of items) {
        total += item.price * item.quantity;
    }
    return total;
}

// ❌ Bad - 4 spaces
function calculateTotal(items) {
    let total = 0;
    for (const item of items) {
        total += item.price * item.quantity;
    }
    return total;
}

// ❌ Bad - tabs
function calculateTotal(items) {
    	total = 0;
	for (const item of items) {
    		total += item.price * item.quantity;
    	}
    	return total;
}
```

**Line Length:** Max 100-120 characters

```javascript
// ✅ Good
const result = fetchUserData(userId)
    .then(user => processUser(user));

// ❌ Bad (too long)
const result = fetchUserData(userId).then(user => processUser(user)).catch(error => handleError(error));
```

**Semicolons:** Use semicolons consistently

```javascript
// ✅ Good - Always use
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
}

// ❌ Bad - Inconsistent
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
}

function processData(data) {  // No semicolon
    return transform(data)
}
```

### Naming Conventions

**Variables:** camelCase
```javascript
// ✅ Good
const userName = 'John Doe';
const userId = 123;
const isLoggedIn = true;
const totalPrice = 100.50;

// ❌ Bad
const user_name = 'John Doe';
const user_id = 123;
const is_logged_in = true;
const total_price = 100.50;
```

**Functions:** camelCase
```javascript
// ✅ Good
function getUserById(userId) { return users.find(u => u.id === userId); }
function calculateTotal(items) { return items.reduce(...); }
function isEmailValid(email) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email); }

// ❌ Bad
function get_user_by_id(userId) { return users.find(u => u.id === userId); }
function calculate_total(items) { return items.reduce(...); }
function is_email_valid(email) { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email); }
```

**Classes:** PascalCase
```javascript
// ✅ Good
class UserService {
    constructor(userRepository, emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}

// ❌ Bad
class userService {
    constructor(userRepository, emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
    }
}
```

**Constants:** UPPER_SNAKE_CASE
```javascript
// ✅ Good
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 5000;

// ❌ Bad
const apiBaseUrl = 'https://api.example.com';
const maxRetryCount = 3;
const defaultTimeout = 5000;
```

**Private Members:** Underscore prefix
```javascript
// ✅ Good
class UserService {
    constructor(database) {
        this._db = database;
    }

    _findUserById(id) {
        return this._db.query('SELECT * FROM users WHERE id = ?', [id]);
    }
}

// ❌ Bad
class UserService {
    constructor(database) {
        this.db = database;
    }

    findUserById(id) {
        return this.db.query('SELECT * FROM users WHERE id = ?', [id]);
    }
}
```

### Import/Export

**Imports:** Grouped by type
```javascript
// ✅ Good
// Third-party
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

// Local
import { getUserById } from './services/userService';
import { calculateTotal } from './utils/calculate';

// ❌ Bad - Mixed and unordered
import express from 'express';
import { getUserById } from './services/userService';
import cors from 'cors';
import helmet from 'helmet';
import calculateTotal from './utils/calculate';
```

**Exports:** Named exports preferred
```javascript
// ✅ Good
export const API_BASE_URL = 'https://api.example.com';
export const MAX_RETRY_COUNT = 3;

// Default export for main function
export default function createApp() {
    const app = express();
    return app;
}

// ❌ Bad
module.exports = {
    API_BASE_URL: 'https://api.example.com',
    MAX_RETRY_COUNT: 3
};
```

### Template Literals

**Backticks:** Use backticks for multi-line strings
```javascript
// ✅ Good
const query = `
    SELECT
        u.id,
        u.name,
        u.email
    FROM users
    WHERE u.id = ?
`;

// ❌ Bad - String concatenation
const query = 'SELECT u.id, u.name, u.email ' +
               'FROM users ' +
               'WHERE u.id = ?';
```

**Variable Interpolation:** Use `${}` syntax
```javascript
// ✅ Good
const message = `User ${userName} logged in at ${new Date().toISOString()}`;

// ❌ Bad - String concatenation
const message = 'User ' + userName + ' logged in at ' + new Date().toISOString();
```

---

## Python Style

### Formatting

**Indentation:** 4 spaces (PEP 8)

```python
# ✅ Good
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total

# ❌ Bad - 2 spaces
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total

# ❌ Bad - Tabs
def calculate_total(items):
    total = 0
    for item in items:
        total += item['price'] * item['quantity']
    return total
```

**Line Length:** Max 79-88 characters (PEP 8 recommends 79)

```python
# ✅ Good
def get_user_by_id(user_id: int) -> dict:
    user = db.query('SELECT * FROM users WHERE id = ?', [user_id])
    return user

# ❌ Bad (too long)
def get_user_by_id(user_id: int) -> dict:
    user = db.query('SELECT * FROM users WHERE id = ?', [user_id])
    return user
```

**Blank Lines:** 2 blank lines between top-level definitions (PEP 8)

```python
# ✅ Good
from database import Database
from utils import calculate_total


def process_order(order: dict) -> dict:
    total = calculate_total(order['items'])
    return {'total': total}

# ❌ Bad - No separation
from database import Database
from utils import calculate_total

def process_order(order: dict) -> dict:
    total = calculate_total(order['items'])
    return {'total': total}
```

### Naming Conventions

**Variables:** snake_case
```python
# ✅ Good
user_name = 'John Doe'
user_id = 123
is_logged_in = True
total_price = 100.50

# ❌ Bad
userName = 'John Doe'
userId = 123
isLoggedIn = True
totalPrice = 100.50
```

**Functions:** snake_case
```python
# ✅ Good
def get_user_by_id(user_id: int) -> dict:
    return users.find(u -> u['id'] == user_id)

def calculate_total(items: list) -> float:
    return sum(item['price'] * item['quantity'] for item in items)

def is_email_valid(email: str) -> bool:
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))

# ❌ Bad
def getUserById(userId: int) -> dict:
    return users.find(u -> u['id'] == userId)

def calculateTotal(items: list) -> float:
    return sum(item['price'] * item['quantity'] for item in items)

def isEmailValid(email: str) -> bool:
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))
```

**Classes:** PascalCase
```python
# ✅ Good
class UserService:
    def __init__(self, database: Database):
        self._database = database

    def get_user_by_id(self, user_id: int) -> dict:
        return self._database.query('SELECT * FROM users WHERE id = ?', [user_id])

# ❌ Bad
class userService:
    def __init__(self, database: Database):
        self._database = database

    def get_user_by_id(self, user_id: int) -> doc:
        return self._database.query('SELECT * FROM users WHERE id = ?', [user_id])
```

**Constants:** UPPER_SNAKE_CASE
```python
# ✅ Good
API_BASE_URL = 'https://api.example.com'
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT = 5000

# ❌ Bad
apiBaseUrl = 'https://api.example.com'
maxRetryCount = 3
defaultTimeout = 5000
```

### Private Members

**Underscore prefix for protected/private methods**
```python
# ✅ Good
class UserService:
    def __init__(self, database):
        self._database = database

    def _get_user_by_id(self, user_id: int) -> dict:
        return self._database.query('SELECT * FROM users WHERE id = ?', [user_id])

# ❌ Bad - No prefix
class UserService:
    def __init__(self, database):
        self.database = database

    def get_user_by_id(self, user_id: int) -> dict:
        return self.database.query('SELECT * FROM users WHERE id = ?', [user_id])
```

### Import/Export

**Imports:** Grouped by type (PEP 8)
```python
# ✅ Good
# Standard library
import os
import sys
import datetime

# Third-party
import requests
from flask import Flask, request

# Local application
from models import User
from services import UserService
from utils import calculate_total

# ❌ Bad - Mixed and unordered
import os
import sys
import requests
from flask import Flask, request
from models import User
from services.user_service import UserService
from utils import calculate_total
```

---

## PHP Style

### Formatting

**Indentation:** 4 spaces (PSR-12)

```php
// ✅ Good
class UserService
{
    public function createUser(array $data): array
    {
        // Indented with 4 spaces
        $user = $this->repository->create($data);
        return $this->serializer->toArray($user);
    }
}

// ❌ Bad - 2 spaces
class UserService
{
    public function createUser(array $data): array
    {
        // Indented with 2 spaces
        $user = $this->repository->create($data);
        return $this->serializer->toArray($user);
    }
}
```

**Opening Braces:** Opening brace on new line (PSR-12)

```php
// ✅ Good
class UserService
{
    public function createUser(array $data): array
    {
        // Opening brace on new line
    }
}

// ❌ Bad
class UserService {
    public function createUser(array $data): array
    {
        // Opening brace on same line
    }
}
```

**Line Length:** Max 120 characters (PSR-12)

```php
// ✅ Good
public function createUser(array $data): array
{
    $user = $this->repository->create($data);
    return $this->serializer->toArray($user);
}

// ❌ Bad (too long)
public function createUser(array $data): array{
    $user = $this->repository->create($data);
    return $this->serializer->toArray($user);
}
```

### Naming Conventions

**Classes:** PascalCase (PSR-1)
```php
// ✅ Good
class UserService { }

// ❌ Bad
class userService { }
```

**Methods:** camelCase (PSR-1)
```php
// ✅ Good
class UserService
{
    public function createUser(array $data): array
    {
        $user = $this->repository->create($data);
        return $this->serializer->toArray($user);
    }

    public function getUserById(int $id): ?array
    {
        return $this->repository->find($id);
    }
}

// ❌ Bad
class UserService
{
    public function CreateUser(array $data): array
    {
        $user = $this->repository->create($data);
        return $this->serializer->toArray($user);
    }

    public function GetUserById(int $id): ?array
    {
        return $this->repository->find($id);
    }
}
```

**Variables:** camelCase (PSR-1)
```php
// ✅ Good
public function createUser(array $data): array
{
    $userId = $data['userId'];
    $userName = $data['userName'];
    $isLoggedIn = true;

    // ...
}

// ❌ Bad
public function createUser(array $data): array
{
    $user_id = $data['userId'];
    $user_name = $data['userName'];
    $is_logged_in = true;

    // ...
}
```

**Constants:** UPPER_SNAKE_CASE (PSR-1)
```php
// ✅ Good
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 5000;

// ❌ Bad
const apiBaseUrl = 'https://api.example.com';
const maxRetryCount = 3;
const defaultTimeout = 5000;
```

---

## Ruby Style

### Formatting

**Indentation:** 2 spaces (Ruby style guide)

```ruby
# ✅ Good
class UserService
  def get_user_by_id(user_id)
    if user_id
      # Indented with 2 spaces
      user = @database.find(user_id)
    end
  end

# ❌ Bad - 4 spaces
class UserService
  def get_user_by_id(user_id)
    if user_id
      # Indented with 4 spaces
      user = @database.find(user_id)
    end
  end
```

**Line Length:** Max 80 characters (Ruby style guide)

```ruby
# ✅ Good
def get_user_by_id(user_id)
  if user_id
    user = @database.find(user_id)
    end

# ❌ Bad (too long)
def get_user_by_id_with_very_long_name_that_exceeds_recommended_line_length(user_id)
  if user_id
    user = @database.find(user_id)
  end
```

### Naming Conventions

**Variables:** snake_case
```ruby
# ✅ Good
user_name = 'John Doe'
user_id = 123
is_logged_in = true
total_price = 100.50

# ❌ Bad
userName = 'John Doe'
userId = 123
isLoggedIn = true
totalPrice = 100.50
```

**Classes:** PascalCase (Ruby style guide)
```ruby
# ✅ Good
class UserService
end

# ❌ Bad
class userService
end
```

**Methods:** snake_case
```ruby
# ✅ Good
class UserService
  def get_user_by_id(user_id)
    if user_id
      user = @database.find(user_id)
    end

  def calculate_total(items)
    items.sum { |item| item['price'] * item['quantity'] }
  end
end

# ❌ Bad
class UserService
  def getUserById(userId)
    if userId
      user = @database.find(userId)
    end

  def CalculateTotal(items)
    items.sum { |item| item['price'] * item['quantity'] }
  end
end
```

---

## Linter Configuration

### JavaScript/TypeScript (ESLint)

**Configuration: `.eslintrc.js`**
```javascript
module.exports = {
    env: {
        browser: true,
        node: true
    },
    extends: ['eslint:recommended'],
    parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: {
            arrowFunctions: true,
            classes: true,
            modules: true
        }
    },
    rules: {
        'no-var': 'error',
        'no-console': 'warn',
        'no-debugger': 'warn',
        'eqeqeqy': ['error', { allowNull: true }],
        'indent': ['error', 2, { 'MemberExpression': 4 }]
    }
};
```

**Prettier Configuration: `.prettierrc.js`**
```javascript
module.exports = {
    printWidth: 100,
    tabWidth: 2,
    trailingComma: 'none',
    semi: false,
    singleQuote: true,
    arrowParens: 'always',
    endOfLine: 'lf'
};
```

### Python (Black + Flake8)

**Configuration: `pyproject.toml`**
```toml
[tool.black]
line-length = 88
target-version = ['py38', 'py39', 'py310']
include = '\.pyi$'
exclude = '''
/(
    migrations/
    | venv/
    | settings/
)/
'''

[tool.flake8]
max-line-length = 88
extend-ignore = ['E203', 'W503']
exclude = ['migrations/*']
```

### PHP (PHP_CodeSniffer + PHPStan)

**Configuration: `phpcs.xml`**
```xml
<?xml version="1.0"?>
<ruleset name="Custom">
    <rule ref="Generic.WhiteSpace">
        <severity>0</severity>
    </rule>
</ruleset>
```

**PHPStan Configuration: `phpstan.neon`**
```neon
parameters.level = 5
paths.%databse%/excludePaths.%databse%[] = ['*/Migrations/*', '*/ValueObjects/*']
```

---

## Style Checklist

### JavaScript/TypeScript

- [ ] **Indentation**: 2 spaces (not tabs)
- [ ] **Naming**: camelCase variables, PascalCase classes
- [ ] **Quotes**: Single quotes for strings
- [ ] **Semicolons**: Always used at end of statements
- [ ] **Line Length**: Max 100-120 characters
- [ ] **Blank Lines**: One blank line between blocks
- [ ] **Imports**: Grouped by type (standard, third-party, local)
- [ ] **Constants**: UPPER_SNAKE_CASE
- [ ] **Private Members**: Underscore prefix

### Python

- [ ] **Indentation**: 4 spaces (PEP 8)
- [ ] **Naming**: snake_case variables, PascalCase classes
- [ ] **Line Length**: Max 79-88 characters
- [ ] **Blank Lines**: 2 blank lines between top-level definitions
- [ ] **Imports**: Grouped by type (standard, third-party, local)
- [ ] **Constants**: UPPER_SNAKE_CASE
- [ ] **Private Members**: Underscore prefix
- [ ] **Docstrings**: Use triple quotes

### PHP

- [ ] **Indentation**: 4 spaces (PSR-12)
- [ ] **Naming**: camelCase methods, PascalCase classes
- [ ] **Opening Braces**: Opening brace on new line
- [ ] **Line Length**: Max 120 characters
- [ ] **Constants**: UPPER_SNAKE_CASE
- [ ] **Variables**: camelCase

### Ruby

- [ ] **Indentation**: 2 spaces
- [ ] **Naming**: snake_case methods, PascalCase classes
- [ ] **Line Length**: Max 80 characters
- [ ] **Constants**: UPPER_SNAKE_CASE

---

## Summary

Code style improves readability and maintainability:

**Principles:**
- Be consistent (formatting, naming, structure)
- Be minimal (no dead code, focused functions)
- Be readable (clear names, logical structure)
- Be predictable (consistent patterns, logical organization)

**By Language:**
- **JavaScript/TypeScript**: camelCase (vars/classes), PascalCase (constants), 2 spaces
- **Python**: snake_case (vars/classes), PascalCase (constants), 4 spaces
- **PHP**: camelCase (methods/classes), PascalCase (constants), 4 spaces
- **Ruby**: snake_case (methods/classes), PascalCase (constants), 2 spaces

**Tools:**
- **JavaScript**: ESLint + Prettier
- **Python**: Black + Flake8
- **PHP**: PHPStan + PHP_CodeSniffer
- **Ruby**: RuboCop

**Goals:**
- Consistent formatting across codebase
- Easy to read and understand
- Follow language-specific conventions
- Automated linting to enforce standards

Use consistent code style to improve developer experience and reduce merge conflicts.
