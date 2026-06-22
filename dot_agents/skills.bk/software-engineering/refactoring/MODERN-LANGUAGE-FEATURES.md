# MODERN LANGUAGE FEATURES

## OVERVIEW
Modern language features improve code readability, maintainability, and expressiveness. This guide covers modern features across PHP, JavaScript, and TypeScript.

## PHP 8+ FEATURES

### 1. Union Types (PHP 8.0+)

```php
// BEFORE: PHPDoc annotations only
/**
 * @param int|float $number
 * @return int|float
 */
function calculate($number) {
    return $number * 2;
}

// MODERN: Native union types
function calculate(int|float $number): int|float {
    return $number * 2;
}
```

---

### 2. Named Arguments (PHP 8.0+)

```php
// BEFORE: Positional arguments (hard to read)
function createUser($name, $email, $active = true, $role = 'user') { }

createUser('John', 'john@example.com', true, 'admin');

// MODERN: Named arguments (clear intent)
createUser(
    name: 'John',
    email: 'john@example.com',
    role: 'admin'
);

// Skip optional parameters
createUser(
    name: 'John',
    email: 'john@example.com',
    role: 'admin'  // Skip $active parameter
);
```

---

### 3. Match Expression (PHP 8.0+)

```php
// BEFORE: Switch statement
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
    case 'cancelled':
        $message = 'Order cancelled';
        break;
    default:
        $message = 'Unknown status';
}

// MODERN: Match expression
$message = match($status) {
    'pending' => 'Order pending',
    'processing' => 'Order processing',
    'completed' => 'Order completed',
    'cancelled' => 'Order cancelled',
    default => 'Unknown status'
};

// Match with conditions
$ageGroup = match(true) {
    $age < 13 => 'Child',
    $age < 18 => 'Teenager',
    $age < 65 => 'Adult',
    default => 'Senior'
};
```

---

### 4. Nullsafe Operator (PHP 8.0+)

```php
// BEFORE: Nested null checks
$country = null;
if ($user !== null) {
    if ($user->address !== null) {
        $country = $user->address->country;
    }
}

// MODERN: Nullsafe operator
$country = $user?->address?->country;

// With default value
$country = $user?->address?->country ?? 'Unknown';
```

---

### 5. Constructor Property Promotion (PHP 8.0+)

```php
// BEFORE: Separate properties and constructor
class User {
    private string $name;
    private string $email;
    private bool $active;

    public function __construct(
        string $name,
        string $email,
        bool $active = true
    ) {
        $this->name = $name;
        $this->email = $email;
        $this->active = $active;
    }
}

// MODERN: Constructor property promotion
class User {
    public function __construct(
        private string $name,
        private string $email,
        private bool $active = true
    ) { }
}
```

---

### 6. Attributes (PHP 8.0+)

```php
// BEFORE: PHPDoc annotations
/**
 * @Route("/users", methods={"GET"})
 * @Security("is_granted('ROLE_USER')")
 */
class UserController {
    /**
     * @param Request $request
     * @return JsonResponse
     */
    public function index($request) { }
}

// MODERN: Native attributes
#[Route('/users', methods: ['GET'])]
#[Security('is_granted("ROLE_USER")')]
class UserController {
    public function index(Request $request): JsonResponse { }
}

// Custom attribute
#[Attribute]
class Validated {
    public function __construct(
        public array $rules
    ) { }
}

#[Validated(['name' => 'required', 'email' => 'required|email'])]
class CreateUserRequest { }
```

---

### 7. Readonly Properties (PHP 8.2+)

```php
// BEFORE: Private with only getter
class Point {
    private float $x;
    private float $y;

    public function __construct(float $x, float $y) {
        $this->x = $x;
        $this->y = $y;
    }

    public function getX(): float { return $this->x; }
    public function getY(): float { return $this->y; }
}

// MODERN: Readonly properties
class Point {
    public function __construct(
        public readonly float $x,
        public readonly float $y
    ) { }
}

$point = new Point(1.0, 2.0);
echo $point->x;  // 1.0
// $point->x = 5.0;  // Error: Cannot modify readonly property
```

---

## JAVASCRIPT ES2020+ FEATURES

### 1. Optional Chaining (ES2020)

```javascript
// BEFORE: Nested null checks
const city = user && user.address && user.address.city;

// MODERN: Optional chaining
const city = user?.address?.city;

// With default value
const city = user?.address?.city ?? 'Unknown';

// Array access
const item = array?.[0]?.name;
```

---

### 2. Nullish Coalescing Operator (ES2020)

```javascript
// BEFORE: || operator (falsy values: 0, '', false)
const timeout = input || 1000;  // 0 becomes 1000 (wrong!)

// MODERN: ?? operator (null/undefined only)
const timeout = input ?? 1000;  // 0 stays 0 (correct!)

// Multiple fallbacks
const value = a ?? b ?? c ?? 'default';
```

---

### 3. Private Class Fields (ES2022)

```javascript
// BEFORE: Convention with underscore
class BankAccount {
    constructor(balance) {
        this._balance = balance;
    }

    deposit(amount) {
        this._balance += amount;
    }
}

// MODERN: Private class fields
class BankAccount {
    #balance;

    constructor(balance) {
        this.#balance = balance;
    }

    deposit(amount) {
        this.#balance += amount;
    }

    getBalance() {
        return this.#balance;
    }
}

const account = new BankAccount(100);
account.deposit(50);
console.log(account.getBalance());  // 150
// console.log(account.#balance);  // SyntaxError (private!)
```

---

### 4. Top-Level await (ES2022)

```javascript
// BEFORE: IIFE or async function
(async () => {
    const data = await fetch('/api/data');
    console.log(data);
})();

// MODERN: Top-level await (in ES modules)
const data = await fetch('/api/data');
console.log(data);
```

---

### 5. Array.at() Method (ES2022)

```javascript
// BEFORE: Access last element
const last = array[array.length - 1];

// MODERN: Array.at()
const last = array.at(-1);
const first = array.at(0);
const third = array.at(2);

// Negative indexes
const last = array.at(-1);
const secondLast = array.at(-2);
```

---

### 6. Object.hasOwn() (ES2022)

```javascript
// BEFORE: Object.prototype.hasOwnProperty.call()
if (Object.prototype.hasOwnProperty.call(obj, 'name')) { }

// MODERN: Object.hasOwn()
if (Object.hasOwn(obj, 'name')) { }
```

---

### 7. String.replaceAll() (ES2021)

```javascript
// BEFORE: Regex with global flag
const text = 'hello world'.replace(/o/g, '0');

// MODERN: replaceAll()
const text = 'hello world'.replaceAll('o', '0');
```

---

## TYPESCRIPT FEATURES

### 1. Union Types

```typescript
// BEFORE: any type (loses type safety)
function process(value: any) {
    return value * 2;  // Runtime error if value is string!
}

// MODERN: Union types
function process(value: number | string): number | string {
    if (typeof value === 'number') {
        return value * 2;
    }
    return value.toUpperCase();
}
```

---

### 2. Intersection Types

```typescript
// BEFORE: Repeating properties
interface User {
    name: string;
    email: string;
}
interface Admin {
    name: string;
    email: string;
    permissions: string[];
}

// MODERN: Intersection types
type AdminUser = User & Admin;

const admin: AdminUser = {
    name: 'John',
    email: 'john@example.com',
    permissions: ['read', 'write', 'delete']
};
```

---

### 3. Generics

```typescript
// BEFORE: Duplicate code for different types
function getFirstString(arr: string[]): string {
    return arr[0];
}

function getFirstNumber(arr: number[]): number {
    return arr[0];
}

// MODERN: Generics
function getFirst<T>(arr: T[]): T {
    return arr[0];
}

const string = getFirst(['a', 'b', 'c']);
const number = getFirst([1, 2, 3]);
```

---

### 4. Utility Types

```typescript
// Partial - make all properties optional
interface User {
    name: string;
    email: string;
    age: number;
}

function updateUser(id: number, data: Partial<User>) {
    // Update user with partial data
}

// Record - create object type with specific keys and values
type Permissions = Record<string, boolean>;
const perms: Permissions = {
    read: true,
    write: false
};

// Pick - select specific properties
type UserSummary = Pick<User, 'name' | 'email'>;

// Omit - exclude specific properties
type CreateUser = Omit<User, 'id'>;

// Readonly - make all properties readonly
type ReadonlyUser = Readonly<User>;
```

---

### 5. Type Guards

```typescript
// Type guard function
function isString(value: unknown): value is string {
    return typeof value === 'string';
}

function process(value: unknown) {
    if (isString(value)) {
        // TypeScript knows value is string here
        console.log(value.toUpperCase());
    }
}

// Discriminated union
type Shape =
    | { type: 'circle'; radius: number }
    | { type: 'rectangle'; width: number; height: number };

function getArea(shape: Shape): number {
    switch (shape.type) {
        case 'circle':
            return Math.PI * shape.radius ** 2;
        case 'rectangle':
            return shape.width * shape.height;
    }
}
```

---

## MODERN FEATURE CHECKLIST

### PHP 8+
- [ ] Use union types for flexible parameters
- [ ] Use named arguments for clarity
- [ ] Replace switch with match expression
- [ ] Use nullsafe operator `?->`
- [ ] Use constructor property promotion
- [ ] Use attributes for annotations
- [ ] Use readonly properties where appropriate
- [ ] Use typed properties (PHP 7.4+)

### JavaScript ES2020+
- [ ] Use optional chaining `?.`
- [ ] Use nullish coalescing `??`
- [ ] Use private class fields `#`
- [ ] Use top-level await (in modules)
- [ ] Use `array.at(-1)` for last element
- [ ] Use `Object.hasOwn()` instead of `hasOwnProperty`
- [ ] Use `replaceAll()` instead of `replace(/g)`

### TypeScript
- [ ] Use union types `|`
- [ ] Use intersection types `&`
- [ ] Use generics `T`
- [ ] Use utility types (Partial, Pick, Omit, etc.)
- [ ] Use type guards
- [ ] Use discriminated unions

---

## CROSS-REFERENCES
- For code modernization: @refactoring/CODE-MODERNIZATION.md
- For deprecated API replacements: @refactoring/DEPRECATED-API-REPLACEMENTS.md
- For algorithm complexity: @performance-engineering/profiling/ALGORITHM-COMPLEXITY.md
