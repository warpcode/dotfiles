# CODE MODERNIZATION

## OVERVIEW
Code modernization updates legacy code to use modern language features, deprecated API replacements, and current best practices. This guide covers common modernization patterns.

## 1. ARRAY SYNTAX UPDATES

### PHP: Old Array Syntax
```php
// OLD: array() syntax
$users = array('John', 'Jane', 'Bob');
$config = array(
    'host' => 'localhost',
    'port' => 3306
);

// NEW: [] syntax
$users = ['John', 'Jane', 'Bob'];
$config = [
    'host' => 'localhost',
    'port' => 3306
];
```

### JavaScript: var to const/let
```javascript
// OLD: var (function-scoped)
var name = 'John';
var age = 30;
var isActive = true;

// NEW: const/let (block-scoped)
const name = 'John';  // Cannot be reassigned
let age = 30;  // Can be reassigned
let isActive = true;
```

---

## 2. DEPRECATED API REPLACEMENTS

### PHP: mysql_ Functions
```php
// DEPRECATED: mysql_* functions
$conn = mysql_connect('localhost', 'user', 'pass');
mysql_select_db('database', $conn);
$result = mysql_query("SELECT * FROM users");

// MODERN: PDO or mysqli
$conn = new PDO('mysql:host=localhost;dbname=database', 'user', 'pass');
$stmt = $conn->prepare("SELECT * FROM users");
$stmt->execute();
$result = $stmt->fetchAll();
```

### PHP: ereg Functions
```php
// DEPRECATED: ereg_* functions
if (ereg('pattern', $string)) { }

// MODERN: preg_* functions
if (preg_match('/pattern/', $string)) { }
```

### JavaScript: var to let/const
```javascript
// OLD: var (hoisting issues)
for (var i = 0; i < 10; i++) {
    setTimeout(function() {
        console.log(i);  // Always prints 10!
    }, 100);
}

// NEW: let (block scope)
for (let i = 0; i < 10; i++) {
    setTimeout(function() {
        console.log(i);  // Prints 0, 1, 2, ..., 9
    }, 100);
}
```

---

## 3. TYPE HINT ADDITIONS

### PHP: Scalar Type Hints (PHP 7+)
```php
// OLD: No type hints
function calculateTotal($price, $quantity, $discount) {
    return $price * $quantity * (1 - $discount);
}

// MODERN: Type hints for parameters and return
function calculateTotal(float $price, int $quantity, float $discount): float {
    return $price * $quantity * (1 - $discount);
}
```

### PHP: Return Type Declarations (PHP 7+)
```php
// OLD: No return type
function getUser($id) {
    // Returns array or null, but not declared
    return $db->query("SELECT * FROM users WHERE id = $id")->fetch();
}

// MODERN: Explicit return type
function getUser(int $id): ?array {
    return $db->query("SELECT * FROM users WHERE id = $id")->fetch();
}
```

### PHP: Strict Types
```php
// ADD: Strict types at top of file
declare(strict_types=1);

function calculateTotal(float $price, int $quantity): float {
    // Now strictly enforces types, no implicit conversions
    return $price * $quantity;
}
```

### TypeScript Type Annotations (JavaScript)
```typescript
// OLD: JavaScript (no types)
function calculateTotal(price, quantity, discount) {
    return price * quantity * (1 - discount);
}

// NEW: TypeScript with types
function calculateTotal(price: number, quantity: number, discount: number): number {
    return price * quantity * (1 - discount);
}

// Interface for complex objects
interface User {
    id: number;
    name: string;
    email: string;
}

function getUser(id: number): User | null {
    return users.find(u => u.id === id) || null;
}
```

---

## 4. MODERN LANGUAGE FEATURES

### PHP: Null Coalescing Operator (PHP 7+)
```php
// OLD: Verbose null checks
$username = isset($_GET['username']) ? $_GET['username'] : 'guest';

// MODERN: Null coalescing
$username = $_GET['username'] ?? 'guest';
```

### PHP: Spaceship Operator (PHP 7+)
```php
// OLD: Complex comparison
if ($a < $b) {
    return -1;
} elseif ($a > $b) {
    return 1;
} else {
    return 0;
}

// MODERN: Spaceship operator
return $a <=> $b;  // Returns -1, 0, or 1
```

### PHP: Match Expression (PHP 8+)
```php
// OLD: Switch statement
switch ($status) {
    case 'pending':
        $message = 'Order pending';
        break;
    case 'processing':
        $message = 'Order processing';
        break;
    case 'completed':
        $message = 'Order completed';
        break;
    default:
        $message = 'Unknown status';
}

// MODERN: Match expression
$message = match($status) {
    'pending' => 'Order pending',
    'processing' => 'Order processing',
    'completed' => 'Order completed',
    default => 'Unknown status'
};
```

### JavaScript: Async/Await (ES2017+)
```javascript
// OLD: Promise chains
fetch('/api/users')
    .then(response => response.json())
    .then(users => {
        return fetch(`/api/users/${users[0].id}`);
    })
    .then(response => response.json())
    .then(user => {
        console.log(user);
    })
    .catch(error => console.error(error));

// MODERN: Async/await
async function getUser() {
    try {
        const users = await fetch('/api/users').then(r => r.json());
        const user = await fetch(`/api/users/${users[0].id}`).then(r => r.json());
        console.log(user);
    } catch (error) {
        console.error(error);
    }
}
```

### JavaScript: Arrow Functions (ES2015+)
```javascript
// OLD: Function expression
const doubled = numbers.map(function(number) {
    return number * 2;
});

// MODERN: Arrow function
const doubled = numbers.map(number => number * 2);

// Multiple parameters
const sum = numbers.reduce((a, b) => a + b, 0);

// Implicit return
const doubled = numbers.map(n => n * 2);
```

### JavaScript: Template Literals (ES2015+)
```javascript
// OLD: String concatenation
const message = 'Hello ' + name + ', you have ' + count + ' messages.';

// MODERN: Template literals
const message = `Hello ${name}, you have ${count} messages.`;
```

### JavaScript: Destructuring (ES2015+)
```javascript
// OLD: Manual property access
const name = user.name;
const email = user.email;
const age = user.age;

// MODERN: Destructuring
const { name, email, age } = user;

// With default values
const { name, email, age = 0 } = user;

// Array destructuring
const [first, second, ...rest] = numbers;
```

### JavaScript: Spread Operator (ES2015+)
```javascript
// OLD: Object.assign()
const newObj = Object.assign({}, obj1, obj2);

// MODERN: Spread operator
const newObj = { ...obj1, ...obj2 };

// Array spread
const newArray = [...arr1, ...arr2];
```

---

## 5. OPTIONAL CHAINING

### JavaScript (ES2020+)
```javascript
// OLD: Nested null checks
const city = user && user.address && user.address.city;

// MODERN: Optional chaining
const city = user?.address?.city;

// With default
const city = user?.address?.city ?? 'Unknown';
```

### PHP (PHP 8+)
```php
// OLD: Nested null checks
$city = isset($user->address) ? $user->address->city : null;

// MODERN: Nullsafe operator (PHP 8.0+)
$city = $user?->address?->city;

// With null coalescing
$city = $user?->address?->city ?? 'Unknown';
```

---

## 6. NULL COALESCING

### PHP
```php
// OLD: isset() checks
$value = isset($array['key']) ? $array['key'] : 'default';

// MODERN: Null coalescing
$value = $array['key'] ?? 'default';

// Nested
$value = $array['key'] ?? $array['other'] ?? 'default';
```

### JavaScript
```javascript
// OLD: || operator (falsy values: 0, '', false)
const value = input || 'default';

// MODERN: ?? operator (null/undefined only)
const value = input ?? 'default';
```

---

## 7. DEPRECATED FUNCTION REPLACEMENTS

### PHP
| Old Function | Modern Replacement | Notes |
|-------------|-------------------|-------|
| `mysql_*` | `PDO` or `mysqli` | mysql_* removed in PHP 7 |
| `ereg_*` | `preg_*` | ereg_* removed in PHP 7 |
| `split()` | `explode()` or `preg_split()` | split() removed in PHP 7 |
| `each()` | `foreach` | each() removed in PHP 7.2 |
| `mcrypt_*` | `openssl_*` | mcrypt removed in PHP 7.2 |

### JavaScript
| Old API | Modern Replacement | Notes |
|----------|-------------------|-------|
| `var` | `const`/`let` | Use const for constants, let for variables |
| Callbacks | Promises/async-await | Avoid callback hell |
| `.then()` chains | `async/await` | More readable async code |
| `XMLHttpRequest` | `fetch` | Modern API for HTTP requests |

---

## 8. CLASS SYNTAX UPDATES

### PHP: Constructor Property Promotion (PHP 8+)
```php
// OLD: Separate properties and constructor
class User {
    private string $name;
    private string $email;

    public function __construct(string $name, string $email) {
        $this->name = $name;
        $this->email = $email;
    }
}

// MODERN: Constructor property promotion
class User {
    public function __construct(
        private string $name,
        private string $email
    ) { }
}
```

### JavaScript: Class Syntax (ES2015+)
```javascript
// OLD: Prototype-based
function User(name, email) {
    this.name = name;
    this.email = email;
}
User.prototype.greet = function() {
    console.log('Hello ' + this.name);
};

// MODERN: Class syntax
class User {
    constructor(name, email) {
        this.name = name;
        this.email = email;
    }

    greet() {
        console.log(`Hello ${this.name}`);
    }
}
```

---

## MODERNIZATION CHECKLIST

- [ ] Replace `var` with `const`/`let` (JavaScript)
- [ ] Use `[]` instead of `array()` (PHP)
- [ ] Add type hints to function parameters (PHP 7+, TypeScript)
- [ ] Add return type declarations (PHP 7+, TypeScript)
- [ ] Use `??` instead of `isset()` checks (PHP 7+)
- [ ] Use `??` instead of `||` for null checks (JavaScript)
- [ ] Replace callback hell with `async/await` (JavaScript)
- [ ] Use arrow functions where appropriate (JavaScript)
- [ ] Use template literals instead of concatenation (JavaScript)
- [ ] Replace deprecated APIs (mysql_*, ereg_*, etc.)
- [ ] Add `declare(strict_types=1)` to PHP files
- [ ] Use match expression instead of switch (PHP 8+)
- [ ] Use optional chaining `?.` (JavaScript, PHP 8+)

---

## CROSS-REFERENCES
- For deprecated API replacements: @refactoring/DEPRECATED-API-REPLACEMENTS.md
- For modern language features: @refactoring/MODERN-LANGUAGE-FEATURES.md
- For algorithm complexity: @performance-engineering/profiling/ALGORITHM-COMPLEXITY.md
