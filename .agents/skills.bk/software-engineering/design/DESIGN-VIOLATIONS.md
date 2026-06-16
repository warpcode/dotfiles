# DESIGN VIOLATIONS

## OVERVIEW
Design violations occur when code breaks established design principles and best practices, leading to maintainability, testability, and scalability issues.

## SOLID PRINCIPLE VIOLATIONS

### Single Responsibility Principle (SRP) Violations

**Pattern**: Class has multiple reasons to change.

**Common Violations**:
- God Object with mixed responsibilities
- Database + UI + validation in same class
- Multiple unrelated methods in one class

**Detection**:
```php
// VIOLATION: Class handles user, email, logging, database
class UserService {
    public function createUser($data) { }
    public function sendEmail($user) { }
    public function logActivity($user) { }
    public function saveToDatabase($user) { }
    public function validateInput($data) { }
}
```

**Fix**: Extract responsibilities
```php
class User { /* Domain model */ }
class UserRepository { /* Database */ }
class EmailService { /* Email */ }
class UserValidator { /* Validation */ }
class Logger { /* Logging */ }
```

---

### Open/Closed Principle (OCP) Violations

**Pattern**: Must modify existing code to extend functionality.

**Common Violations**:
- Switch/case statements for types
- Hard-coded class names
- If-else chains checking types

**Detection**:
```php
// VIOLATION: Must modify to add new payment type
class PaymentProcessor {
    public function process($type, $amount) {
        if ($type === 'credit_card') {
            // Process credit card
        } elseif ($type === 'paypal') {
            // Process PayPal
        } elseif ($type === 'bitcoin') {
            // Process Bitcoin
        }
        // Must add new elseif for every new type
    }
}
```

**Fix**: Use interfaces/abstract classes
```php
interface PaymentGateway {
    public function process($amount);
}

class CreditCardGateway implements PaymentGateway { }
class PayPalGateway implements PaymentGateway { }
class BitcoinGateway implements PaymentGateway { }

class PaymentProcessor {
    public function process(PaymentGateway $gateway, $amount) {
        $gateway->process($amount);
    }
}
```

---

### Liskov Substitution Principle (LSP) Violations

**Pattern**: Subtype cannot replace base type without breaking behavior.

**Common Violations**:
- Throwing exceptions in derived classes not thrown in base
- Strengthening preconditions or weakening postconditions
- Returning null when base class returns object

**Detection**:
```php
// VIOLATION: Penguin cannot be substituted for Bird
class Bird {
    public function fly() { }
}

class Penguin extends Bird {
    public function fly() {
        throw new Exception("Penguins cannot fly!");
    }
}

// Code breaks when Bird is replaced with Penguin
function makeBirdFly(Bird $bird) {
    $bird->fly();  // Throws exception for Penguin
}
```

**Fix**: Separate interfaces
```php
interface Flyable { public function fly(); }
interface Swimmable { public function swim(); }

class Eagle implements Flyable {
    public function fly() { }
}

class Penguin implements Swimmable {
    public function swim() { }
}
```

---

### Interface Segregation Principle (ISP) Violations

**Pattern**: Clients forced to depend on interfaces they don't use.

**Common Violations**:
- Fat interfaces with many methods
- Empty method implementations
- "Not implemented" exceptions

**Detection**:
```php
// VIOLATION: Fat interface
interface Worker {
    public function work();
    public function eat();
    public function sleep();
    public function manageTeam();
}

class Developer implements Worker {
    public function work() { }
    public function eat() { }
    public function sleep() { }
    public function manageTeam() {
        throw new Exception("Not implemented!");
    }
}
```

**Fix**: Split into focused interfaces
```php
interface Workable { public function work(); }
interface Eatable { public function eat(); }
interface Managable { public function manageTeam(); }

class Developer implements Workable, Eatable { }
class Manager implements Workable, Eatable, Managable { }
```

---

### Dependency Inversion Principle (DIP) Violations

**Pattern**: High-level modules depend on low-level modules (concretions).

**Common Violations**:
- Direct instantiation of concrete classes
- Hard-coded dependencies
- No interfaces/abstractions

**Detection**:
```php
// VIOLATION: Depends on concrete MySQL
class OrderService {
    private MySQLDatabase $db;

    public function __construct() {
        $this->db = new MySQLDatabase();
    }

    public function saveOrder($order) {
        $this->db->insert('orders', $order->toArray());
    }
}
```

**Fix**: Depend on abstractions
```php
interface Database {
    public function insert($table, $data);
}

class MySQLDatabase implements Database { }
class PostgreSQLDatabase implements Database { }

class OrderService {
    public function __construct(private Database $db) { }
    public function saveOrder($order) {
        $this->db->insert('orders', $order->toArray());
    }
}
```

---

## COUPLING VIOLATIONS

### Tight Coupling

**Pattern**: Classes depend heavily on each other's concrete implementations.

**Characteristics**:
- Cannot test without all dependencies
- Hard to change one without affecting others
- No interfaces between modules

**Detection**:
```php
// VIOLATION: Tight coupling to concrete classes
class OrderService {
    public function __construct() {
        $this->db = new MySQLDatabase();
        $this->email = new SendGridEmail();
        $this->payment = new StripePayment();
    }
}
```

**Fix**: Dependency injection
```php
class OrderService {
    public function __construct(
        private Database $db,
        private EmailService $email,
        private PaymentGateway $payment
    ) { }
}
```

---

### Circular Dependencies

**Pattern**: Two or more modules depend on each other.

**Characteristics**:
- Cannot compile/test independently
- Violates dependency inversion
- Indicates poor separation of concerns

**Detection**:
```php
// VIOLATION: Circular dependency
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

**Fix**: Extract shared functionality
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

## ABSTRACTION VIOLATIONS

### Leaky Abstraction

**Pattern**: Abstraction exposes implementation details to clients.

**Characteristics**:
- Client needs to know internal details
- Cannot change implementation without breaking clients
- Abstraction doesn't hide enough

**Detection**:
```php
// VIOLATION: Leaky abstraction
interface Cache {
    public function set($key, $value, $ttl);
    public function get($key);
}

// Client needs to know Redis specifics
$cache->set('key', 'value', 3600);  // TTL in seconds (Redis-specific)
```

**Fix**: True abstraction
```php
interface Cache {
    public function set($key, $value);
    public function get($key);
}

// TTL handled internally
class RedisCache implements Cache {
    private const DEFAULT_TTL = 3600;
    public function set($key, $value) {
        $this->redis->setex($key, self::DEFAULT_TTL, $value);
    }
}
```

---

### Premature Abstraction

**Pattern**: Creating abstractions before understanding the problem.

**Characteristics**:
- Interfaces for one implementation
- Over-engineering for simple problems
- YAGNI violation

**Detection**:
```php
// VIOLATION: Premature abstraction (only one implementation)
interface PaymentGateway {
    public function process($amount);
}

// Only Stripe exists, why abstraction?
class StripePaymentGateway implements PaymentGateway {
    public function process($amount) { }
}

// Used in only one place
$gateway = new StripePaymentGateway();
```

**Fix**: Start concrete, abstract when needed
```php
// Simple case: No abstraction needed
class StripePayment {
    public function process($amount) { }
}

$payment = new StripePayment();
$payment->process(100);

// Add abstraction when second gateway needed
```

---

## ENCAPSULATION VIOLATIONS

### Broken Encapsulation

**Pattern**: Direct access to internal state or bypassing public interface.

**Characteristics**:
- Public fields instead of getters/setters
- Exposing internal data structures
- Mutating state directly

**Detection**:
```php
// VIOLATION: Broken encapsulation
class Order {
    public $items = [];
    public $total = 0;
}

// Direct manipulation
$order = new Order();
$order->items[] = ['name' => 'Item', 'price' => 10];
$order->total += 10;
```

**Fix**: Proper encapsulation
```php
class Order {
    private array $items = [];
    private float $total = 0;

    public function addItem(string $name, float $price): void {
        $this->items[] = ['name' => $name, 'price' => $price];
        $this->total += $price;
    }

    public function getTotal(): float {
        return $this->total;
    }
}
```

---

## CROSS-REFERENCES
- For SOLID principles: @principles/SOLID.md
- For code smells: @patterns/CODE-SMELLS.md
- For anti-patterns: @patterns/ANTI-PATTERNS.md
- For design patterns (solutions): @patterns/DESIGN-PATTERNS.md
- For clean architecture: @architecture/CLEAN-ARCHITECTURE.md
