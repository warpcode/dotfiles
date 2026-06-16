# Naming Conventions

## Overview

Comprehensive guide to naming conventions across programming languages. Consistent naming improves code readability and maintainability.

---

## General Naming Principles

### 1. Be Descriptive

**✅ Good:**
```javascript
// Descriptive
const calculateTotalPrice = (items) => { /* ... */ };
const userAuthenticationToken = 'token';
const getActiveUsers = () => { /* ... */ };
```

**❌ Bad:**
```javascript
// Not descriptive
const calc = (items) => { /* ... */ };
const t = 'token';
const getU = () => { /* ... */ };
```

### 2. Use Consistent Terminology

**✅ Good:**
```javascript
// Consistent verb-noun
const getUser = () => { /* ... */ };
const createUser = () => { /* ... */ };
const updateUser = () => { /* ... */ };
const deleteUser = () => { /* ... */ };
```

**❌ Bad:**
```javascript
// Inconsistent verbs
const getUser = () => { /* ... */ };
const create = () => { /* ... */ };
const update = () => { /* ... */ };
const remove = () => { /* ... */ };
```

### 3. Avoid Abbreviations

**✅ Good:**
```javascript
// Full words
const calculateTotalPrice = () => { /* ... */ };
const convertToEmailAddress = () => { /* ... */ };
```

**❌ Bad:**
```javascript
// Abbreviations (unclear)
const calcTP = () => { /* ... */ };
const convToEmail = () => { /* ... */ };
```

### 4. Use Appropriate Language

**✅ Good:**
```javascript
// English for code
const user = { /* ... */ };
const calculateTotal = (items) => { /* ... */ };
const isEmailValid = (email) => { /* ... */ };
```

---

## JavaScript/TypeScript Conventions

### Variables

**CamelCase for regular variables**
```javascript
// ✅ Good
const userName = 'John Doe';
const userId = 123;
const isLoggedIn = true;
const totalPrice = 100.50;
const user = { name: 'John', email: 'john@example.com' };

// ❌ Bad
const user_name = 'John Doe';
const user_id = 123;
const is_logged_in = true;
const total_price = 100.50;
const u = { name: 'John', email: 'john@example.com' };
```

**UPPER_SNAKE_CASE for constants**
```javascript
// ✅ Good
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 5000;

// ❌ Bad
const api_base_url = 'https://api.example.com';
const max_retry_count = 3;
const default_timeout = 5000;
```

### Functions

**CamelCase for function names**
```javascript
// ✅ Good
function getUserById(id) { /* ... */ }
function calculateTotalPrice(items) { /* ... */ }
function sendWelcomeEmail(email) { /* ... */ }
function isEmailValid(email) { /* ... */ }

// ❌ Bad
function getUserById(id) { /* ... */ }
function calculate_total_price(items) { /* ... */ }
function send_welcome_email(email) { /* ... */ }
function is_email_valid(email) { /* ... */ }
```

### Classes

**PascalCase for class names**
```javascript
// ✅ Good
class UserService { /* ... */ }
class OrderService { /* ... */ }
class EmailValidator { /* ... */ }
```

**❌ Bad:**
class userService { /* ... */ }
class orderService { /* ... */ }
class emailValidator { /* ... */ }
```

### Constants

**SCREAMING_SNAKE_CASE for constants**
```javascript
// ✅ Good
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 5000;

const CONFIG = {
    API_BASE_URL: 'https://api.example.com',
    MAX_RETRY_COUNT: 3,
    DEFAULT_TIMEOUT: 5000
};

// ❌ Bad
const api_base_url = 'https://api.example.com';
const max_retry_count = 3;
const config = {
    api_base_url: 'https://api.example.com',
    max_retry_count: 3
    default_timeout: 5000
};
```

### Private Variables

**Underscore prefix for private variables**
```javascript
// ✅ Good
class UserService {
    constructor(userRepository, emailService) {
        this._userRepository = userRepository;
        this._emailService = emailService;
        this._config = { /* ... */ };
    }
}

// ❌ Bad
class UserService {
    constructor(userRepository, emailService) {
        this.userRepository = userRepository;
        this.emailService = emailService;
        this.config = { /* ... */ };
    }
}
```

---

## Python Conventions

### Variables

**snake_case for regular variables**
```python
# ✅ Good
user_name = 'John Doe'
user_id = 123
is_logged_in = True
total_price = 100.50
user = {'name': 'John', 'email': 'john@example.com'}

# ❌ Bad
userName = 'John Doe'
userId = 123
isLoggedIn = True
totalPrice = 100.50
```

**UPPER_SNAKE_CASE for constants**
```python
# ✅ Good
API_BASE_URL = 'https://api.example.com'
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT = 5000

# ❌ Bad
api_base_url = 'https://api.example.com'
max_retry_count = 3
default_timeout = 5000
```

### Functions

**snake_case for function names**
```python
# ✅ Good
def get_user_by_id(user_id):
    """Get user by ID."""
    pass

def calculate_total_price(items):
    """Calculate total price."""
    pass

def send_welcome_email(email):
    """Send welcome email."""
    pass

def is_email_valid(email):
    """Check if email is valid."""
    pass

# ❌ Bad
def getUserById(user_id):
    pass

def calculateTotalPrice(items):
    pass

def sendWelcomeEmail(email):
    pass

def isEmailValid(email):
    pass
```

### Classes

**PascalCase for class names**
```python
# ✅ Good
class UserService:
    """User service class."""
    pass

class OrderService:
    """Order service class."""
    pass

class EmailValidator:
    """Email validator class."""
    pass

# ❌ Bad
class userService:
    pass

class orderService:
    pass

class emailValidator:
    pass
```

### Private Variables

**Underscore prefix for private variables**
```python
# ✅ Good
class UserService:
    def __init__(self, user_repository, email_service):
        self._user_repository = user_repository
        self._email_service = email_service
        self._config = {}
        pass

# ❌ Bad
class UserService:
    def __init__(self, user_repository, email_service):
        self.user_repository = user_repository
        self.email_service = email_service
        self.config = {}
        pass
```

---

## PHP Conventions

### Variables

**snake_case for variables**
```php
// ✅ Good
$user_name = 'John Doe';
$user_id = 123;
$is_logged_in = true;
$total_price = 100.50;
$user = ['name' => 'John', 'email' => 'john@example.com'];

// ❌ Bad
$userName = 'John Doe';
$userId = 123;
$loggedIn = true;
$totalPrice = 100.50;
```

**UPPER_SNAKE_CASE for constants**
```php
// ✅ Good
const API_BASE_URL = 'https://api.example.com';
const MAX_RETRY_COUNT = 3;
const DEFAULT_TIMEOUT = 5000;

// ❌ Bad
$api_base_url = 'https://api.example.com';
$max_retry_count = 3;
$default_timeout = 5000;
```

### Functions

**camelCase for function names**
```php
// ✅ Good
function getUserById($id) { /* ... */ }
function calculateTotalPrice($items) { /* ... */ }
function sendWelcomeEmail($email) { /* ... */ }
function isEmailValid($email) { /* ... */ }

// ❌ Bad
function getUserById($id) { /* ... */ }
function calculate_total_price($items) { /* ... */ }
function send_welcome_email($email) { /* ... */ }
function is_email_valid($email) { /* ... */ }
```

### Classes

**PascalCase for class names**
```php
// ✅ Good
class UserService { /* ... */ }
class OrderService { /* ... */ }
class EmailValidator { /* ... */ }

// ❌ Bad
class userService { /* ... */ }
class orderService { /* ... */ }
class emailValidator { /* ... */ }
```

---

## Ruby Conventions

### Variables

**snake_case for regular variables**
```ruby
# ✅ Good
user_name = 'John Doe'
user_id = 123
is_logged_in = true
total_price = 100.50
user = { name: 'John', email: 'john@example.com' }

# ❌ Bad
userName = 'John Doe'
userId = 123
isLoggedIn = true
totalPrice = 100.50
```

**SCREAMING_SNAKE_CASE for constants**
```ruby
# ✅ Good
API_BASE_URL = 'https://api.example.com'
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT = 5000

# ❌ Bad
api_base_url = 'https://api.example.com'
max_retry_count = 3
default_timeout = 5000
```

### Functions

**snake_case for method names**
```ruby
# ✅ Good
def get_user_by_id(user_id)
  # Get user by ID
  # ...
end

def calculate_total_price(items)
  # Calculate total price
  # ...
end

def send_welcome_email(email)
  # Send welcome email
  # ...
end

def is_email_valid?(email)
  # Check if email is valid
  # ...
end

# ❌ Bad
def getUserById(user_id)
  # ...
end

def calculateTotalPrice(items)
  # ...
end

def sendWelcomeEmail(email)
  # ...
end

def isEmailValid?(email)
  # ...
end
```

### Classes

**PascalCase for class names**
```ruby
# ✅ Good
class UserService
  # User service class
  # ...
end

class OrderService
  # Order service class
  # ...
end

class EmailValidator
  # Email validator class
  # ...
end

# ❌ Bad
class userService
  # ...
end

class orderService
  # ...
end

class emailValidator
  # ...
end
```

---

## File Naming

### Conventions

| Language | Files | Pattern |
|----------|-------|---------|
| **JavaScript** | Utilities | camelCase.js |
| **TypeScript** | Components | PascalCase.tsx |
| **Python** | Modules | snake_case.py |
| **PHP** | Controllers | PascalCaseController.php |
| **Ruby** | Classes | PascalCase.rb |

---

## Database Naming

### Tables

**snake_case, plural for table names**
```sql
-- ✅ Good
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL
);

-- ❌ Bad
CREATE TABLE User (
    id SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    CreatedAt TIMESTAMP NOT NULL
);

CREATE TABLE Order (
    id SERIAL PRIMARY KEY,
    UserId INTEGER REFERENCES users(id),
    Total DECIMAL(10, 2) NOT NULL,
    CreatedAt TIMESTAMP NOT NULL
);
```

### Columns

**snake_case for column names**
```sql
-- ✅ Good
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(255) NOT NULL,
    email_address VARCHAR(255) UNIQUE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL
);

-- ❌ Bad
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    userName VARCHAR(255) NOT NULL,
    emailAddress VARCHAR(255) UNIQUE NOT NULL,
    isActive BOOLEAN NOT NULL DEFAULT TRUE,
    createdAt TIMESTAMP NOT NULL
);
```

---

## Common Naming Anti-Patterns

### 1. Hungarian Notation

```javascript
// ❌ Anti-pattern
const iUserId = 123;
const sUserName = 'John';
const bIsLoggedIn = true;
const strUserEmail = 'john@example.com';
```

### 2. Single-Letter Variables

```javascript
// ❌ Anti-pattern
const x = 'John Doe';
const y = 100;
const a = 50;
const b = 75;
```

### 3. Abbreviations Without Context

```javascript
// ❌ Anti-pattern
const usr = {};  // Unclear abbreviation
const calc = {};  // Could be calculate, calculator, etc.

// ✅ Better
const user = {};
const calculator = {};
```

### 4. Names with "Data" Suffix

```javascript
// ❌ Anti-pattern
const userData = fetchUserData();
const orderData = processOrderData();

// ✅ Better
const user = fetchUser();
const order = processOrder();
```

---

## Naming Checklist

- [ ] **Consistency**: Following language conventions (camelCase, snake_case, PascalCase)
- [ ] **Descriptiveness**: Names clearly indicate purpose
- [ ] **No Abbreviations**: Using full words (except well-known ones)
- [ ] **Appropriate Length**: Names not too short or too long
- [ ] **Context Relevance**: Names relate to domain context
- [ ] **Constants**: Properly cased (UPPER_SNAKE_CASE, SCREAMING_SNAKE_CASE)
- [ ] **Privates**: Using underscore prefix or private modifiers
- [ ] **Interfaces**: Descriptive interface names
- [ ] **Files**: Following file naming conventions
- [ ] **Database**: Tables in snake_case, columns in snake_case

---

## Summary

Naming conventions improve readability:

**Principles:**
- Be descriptive and clear
- Use consistent terminology
- Avoid abbreviations (unless well-known)
- Follow language-specific conventions

**By Language:**
- **JavaScript**: camelCase (vars/functions), PascalCase (classes), UPPER_SNAKE_CASE (constants)
- **Python**: snake_case (vars/functions/classes), UPPER_SNAKE_CASE (constants)
- **PHP**: snake_case (vars), PascalCase (classes/functions), UPPER_SNAKE_CASE (constants)
- **Ruby**: snake_case (vars/methods), PascalCase (classes), SCREAMING_SNAKE_CASE (constants)

**Avoid:**
- Hungarian notation (type prefixes)
- Single-letter variables
- Unclear abbreviations
- "Data" suffix redundancy
- Inconsistent casing

Use consistent, descriptive naming to make code more maintainable.
