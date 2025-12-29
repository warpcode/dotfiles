# ANTI-PATTERNS

## OVERVIEW
Anti-patterns are common responses to recurring problems that are ineffective and counterproductive. Recognizing them helps avoid costly mistakes.

## CREATIONAL ANTI-PATTERNS

### God Object

**Definition**: A class that knows too much or does too much.

**Characteristics**:
- Hundreds or thousands of lines of code
- Many responsibilities (database, UI, validation, logging, etc.)
- Difficult to test
- Changes ripple through many features

**Example**:
```php
// BAD: God Object with 500+ lines
class UserManager {
    public function createUser() { }
    public function sendEmail() { }
    public function logActivity() { }
    public function saveToDatabase() { }
    public function validateInput() { }
    public function generatePDF() { }
    public function handlePayment() { }
    public function sendNotification() { }
    // ... 20 more methods
}
```

**Fix**: Split into focused classes using SRP
```php
class UserRepository { public function save(User $user) { } }
class EmailService { public function send(User $user) { } }
class UserValidator { public function validate(array $data) { } }
class Logger { public function log(string $message) { } }
```

---

## STRUCTURAL ANTI-PATTERNS

### Spaghetti Code

**Definition**: Tangled, unstructured code that's hard to follow and maintain.

**Characteristics**:
- Goto statements or deep nesting
- No clear structure or organization
- Control flow jumps around
- Difficult to trace execution

**Example**:
```php
// BAD: Spaghetti code
function process($data) {
    if ($data) {
        if ($data['type'] == 'A') {
            if ($data['valid']) {
                goto do_a;
            } else {
                if ($data['retry']) {
                    goto do_a;
                } else {
                    return;
                }
            }
        } else {
            goto do_b;
        }
    }
    do_a:
    // ...
    do_b:
    // ...
}
```

**Fix**: Early returns, guard clauses, clear structure
```php
function process($data) {
    if (!$data) {
        return;
    }

    if (!$data['valid'] && !$data['retry']) {
        return;
    }

    return match($data['type']) {
        'A' => processA($data),
        default => processB($data)
    };
}
```

---

### Golden Hammer

**Definition**: Using the same familiar tool/pattern for every problem, regardless of suitability.

**Characteristics**:
- "When all you have is a hammer, everything looks like a nail"
- Overuse of a specific technology or pattern
- Inappropriate use of tools

**Examples**:
- Using database for everything (including message queues)
- Using arrays for all data structures
- Using factory pattern when simple instantiation works
- Using dependency injection for everything

**Fix**: Choose the right tool for each specific problem

---

## BEHAVIORAL ANTI-PATTERNS

### Magic Numbers

**Definition**: Unnamed numeric literals in code without clear meaning.

**Characteristics**:
- Random numbers scattered throughout code
- No explanation of what numbers represent
- Difficult to change safely

**Example**:
```php
// BAD: Magic numbers
function calculateBonus($salary) {
    if ($salary < 50000) {
        return $salary * 0.05;
    } elseif ($salary < 100000) {
        return $salary * 0.1;
    } else {
        return $salary * 0.15;
    }
}

if ($status === 3) {
    sendEmail('support@example.com');
}

setTimeout(5000);
```

**Fix**: Named constants
```php
const MIN_SALARY = 50000;
const MAX_SALARY = 100000;
const BONUS_LOW = 0.05;
const BONUS_MEDIUM = 0.10;
const BONUS_HIGH = 0.15;

const STATUS_PENDING = 1;
const STATUS_APPROVED = 2;
const STATUS_REJECTED = 3;

const EMAIL_TIMEOUT = 5000;

function calculateBonus($salary) {
    return $salary * match(true) {
        $salary < MIN_SALARY => BONUS_LOW,
        $salary < MAX_SALARY => BONUS_MEDIUM,
        default => BONUS_HIGH
    };
}

if ($status === STATUS_REJECTED) {
    sendEmail('support@example.com');
}

setTimeout(EMAIL_TIMEOUT);
```

---

### Boat Anchor

**Definition**: Keeping parts of a system that no longer serve any purpose.

**Characteristics**:
- Unused variables, methods, classes
- Commented-out code blocks
- "Just in case we need it later" code
- Dead code that never executes

**Example**:
```php
// BAD: Boat anchor - unused code
class UserService {
    public function createUser($data) {
        // $legacyId = $this->generateLegacyId(); // Unused
        // $this->logToLegacySystem($user); // Unused

        $user = new User($data);
        $this->repository->save($user);
        return $user;
    }

    // This method is never called
    private function generateLegacyId() {
        return 'LEG-' . uniqid();
    }

    // Dead code - never executed
    public function oldMethod() {
        return null;
    }
}
```

**Fix**: Remove dead code, use version control for history

---

### Lava Flow

**Definition**: Dead code and forgotten design ideas that remain in the system.

**Characteristics**:
- Old interfaces that are no longer used
- Deprecated methods still present
- "TODO" comments from years ago
- Multiple versions of similar functionality

**Example**:
```php
// BAD: Lava flow - multiple implementations
class PaymentService {
    // New implementation
    public function processPaymentV3($amount) {
        return $this->gatewayV3->charge($amount);
    }

    // Old implementation - still here
    public function processPaymentV2($amount) {
        return $this->gatewayV2->charge($amount);
    }

    // Even older - why keep it?
    public function processPaymentV1($amount) {
        return $this->gatewayV1->charge($amount);
    }

    // TODO: Remove V2 in 2020
    // TODO: Remove V1 in 2019
}
```

**Fix**: Remove deprecated code, maintain clean interface

---

## ARCHITECTURAL ANTI-PATTERNS

### Tight Coupling

**Definition**: Classes depend heavily on each other, making changes difficult.

**Characteristics**:
- Direct instantiation of concrete classes
- Hard-coded dependencies
- No interfaces or abstractions
- Changes cascade through system

**Example**:
```php
// BAD: Tight coupling
class OrderService {
    private MySQLDatabase $db;
    private StripePayment $payment;
    private SendGridEmail $email;

    public function __construct() {
        $this->db = new MySQLDatabase();  // Tight coupling
        $this->payment = new StripePayment();  // Tight coupling
        $this->email = new SendGridEmail();  // Tight coupling
    }
}
```

**Fix**: Dependency injection with interfaces
```php
interface Database { }
interface PaymentGateway { }
interface EmailService { }

class OrderService {
    public function __construct(
        private Database $db,
        private PaymentGateway $payment,
        private EmailService $email
    ) { }
}
```

---

### Circular Dependencies

**Definition**: Two or more modules depend on each other.

**Characteristics**:
- Class A depends on Class B, which depends on Class A
- Cannot compile/test independently
- Violates dependency inversion

**Example**:
```php
// BAD: Circular dependency
class UserManager {
    public function __construct(private OrderService $orders) { }
    public function getUserOrders($userId) {
        return $this->orders->getByUser($userId);
    }
}

class OrderService {
    public function __construct(private UserManager $users) { }
    public function getOrderUser($orderId) {
        return $this->users->getById($this->orders[$orderId]['user_id']);
    }
}
```

**Fix**: Extract shared functionality to separate service
```php
class OrderRepository {
    public function getByUser($userId) { }
    public function getById($orderId) { }
}

class UserManager {
    public function __construct(private OrderRepository $repo) { }
}

class OrderService {
    public function __construct(private OrderRepository $repo) { }
}
```

---

## DATABASE ANTI-PATTERNS

### N+1 Query Problem

**Definition**: Executing N+1 database queries when 1 would suffice.

**Characteristics**:
- Query in loop to fetch related data
- Performance degrades as N increases
- Excessive database load

**Example**:
```php
// BAD: N+1 queries
$users = $db->query("SELECT * FROM users");
foreach ($users as $user) {
    $posts = $db->query("SELECT * FROM posts WHERE user_id = {$user['id']}");
    // This runs N additional queries!
}
```

**Fix**: Eager loading / JOIN
```php
// GOOD: 1 query with JOIN
$users = $db->query("
    SELECT users.*, posts.*
    FROM users
    LEFT JOIN posts ON users.id = posts.user_id
");
```

---

## CROSS-REFERENCES
- For SOLID violations: @design/DESIGN-VIOLATIONS.md
- For code smells: @patterns/CODE-SMELLS.md
- For design patterns (solutions): @patterns/DESIGN-PATTERNS.md
- For performance issues: @performance/COMMON-ISSUES.md
