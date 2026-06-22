# SOLID PRINCIPLES

## OVERVIEW
SOLID is a mnemonic for five design principles intended to make software designs more understandable, flexible, and maintainable.

## SINGLE RESPONSIBILITY PRINCIPLE (SRP)

### Definition
A class should have one, and only one, reason to change.

### What It Means
- Each class should handle a single task/responsibility
- Changes to one requirement should affect only one class
- Avoid God Objects that do too much

### Violation Examples
**God Object Violation**:
```php
class UserManager {
    public function createUser() { }
    public function sendEmail() { }
    public function logActivity() { }
    public function saveToDatabase() { }
    public function validateInput() { }
}
```

**Correct Implementation**:
```php
class UserRepository {
    public function save(User $user) { }
}

class EmailService {
    public function sendWelcomeEmail(User $user) { }
}

class UserValidator {
    public function validate(array $data) { }
}

class Logger {
    public function log(string $message) { }
}
```

### When to Apply
- When a class has multiple responsibilities
- When tests are hard to write because of many dependencies
- When changing one requirement breaks unrelated functionality

---

## OPEN/CLOSED PRINCIPLE (OCP)

### Definition
Software entities should be open for extension but closed for modification.

### What It Means
- Extend functionality without modifying existing code
- Use abstractions (interfaces, abstract classes) to define behavior
- New features add new classes, not modify old ones

### Violation Examples
**Tight Coupling Violation**:
```php
class OrderProcessor {
    public function process(Order $order, string $paymentType) {
        if ($paymentType === 'credit_card') {
            // Process credit card
        } elseif ($paymentType === 'paypal') {
            // Process PayPal
        } elseif ($paymentType === 'bitcoin') {
            // Process Bitcoin
        }
        // Must modify this class for every new payment type
    }
}
```

**Correct Implementation**:
```php
interface PaymentGateway {
    public function process(Order $order): bool;
}

class CreditCardGateway implements PaymentGateway {
    public function process(Order $order): bool { }
}

class PayPalGateway implements PaymentGateway {
    public function process(Order $order): bool { }
}

class BitcoinGateway implements PaymentGateway {
    public function process(Order $order): bool { }
}

class OrderProcessor {
    public function __construct(private PaymentGateway $gateway) { }
    public function process(Order $order): bool {
        return $this->gateway->process($order);
    }
}
```

### When to Apply
- When adding features requires modifying existing tested code
- When you have many conditional statements checking types
- When you anticipate future variations in behavior

---

## LISKOV SUBSTITUTION PRINCIPLE (LSP)

### Definition
Subtypes must be substitutable for their base types without altering program correctness.

### What It Means
- Derived classes must behave exactly as base class contracts expect
- If method signature accepts Parent, it must work with Child
- Cannot strengthen preconditions or weaken postconditions

### Violation Examples
**Precondition Violation**:
```php
class Bird {
    public function fly() { echo "Flying\n"; }
}

class Penguin extends Bird {
    public function fly() {
        throw new Exception("Penguins cannot fly!");
    }
}

// Violation: Code breaks when Bird is replaced with Penguin
function makeBirdFly(Bird $bird) {
    $bird->fly();  // Throws exception for Penguin!
}
```

**Correct Implementation**:
```php
interface Flyable {
    public function fly();
}

class Eagle implements Flyable {
    public function fly() { echo "Eagle flying\n"; }
}

class Penguin {
    public function swim() { echo "Penguin swimming\n"; }
}

// No violation: Only Flyable birds can be passed to fly
function makeBirdFly(Flyable $bird) {
    $bird->fly();
}
```

### When to Apply
- When derived classes break base class contracts
- When type checking (instanceof) is needed in methods
- When derived classes throw exceptions base class doesn't

---

## INTERFACE SEGREGATION PRINCIPLE (ISP)

### Definition
Clients should not be forced to depend on interfaces they don't use.

### What It Means
- Create focused, specific interfaces
- Avoid "fat interfaces" with many methods
- Clients should only know about methods they need

### Violation Examples
**Fat Interface Violation**:
```php
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
        throw new Exception("Developers don't manage teams!");
    }
}
```

**Correct Implementation**:
```php
interface Workable {
    public function work();
}

interface Eatable {
    public function eat();
}

interface Managable {
    public function manageTeam();
}

class Developer implements Workable, Eatable {
    public function work() { }
    public function eat() { }
}

class Manager implements Workable, Eatable, Managable {
    public function work() { }
    public function eat() { }
    public function manageTeam() { }
}
```

### When to Apply
- When classes throw "not implemented" exceptions
- When interfaces have many methods clients don't use
- When clients are forced to depend on unrelated methods

---

## DEPENDENCY INVERSION PRINCIPLE (DIP)

### Definition
Depend on abstractions, not concretions. High-level modules should not depend on low-level modules.

### What It Means
- Depend on interfaces, not concrete classes
- High-level logic shouldn't know about low-level implementation details
- Use dependency injection to supply abstractions

### Violation Examples
**Concrete Dependency Violation**:
```php
class OrderService {
    private MySQLDatabase $db;

    public function __construct() {
        $this->db = new MySQLDatabase();  // Tight coupling to MySQL
    }

    public function saveOrder(Order $order) {
        $this->db->insert('orders', $order->toArray());
    }
}

// Hard to test, hard to change database
```

**Correct Implementation**:
```php
interface DatabaseConnection {
    public function insert(string $table, array $data);
}

class MySQLDatabase implements DatabaseConnection {
    public function insert(string $table, array $data) { }
}

class PostgreSQLDatabase implements DatabaseConnection {
    public function insert(string $table, array $data) { }
}

class OrderService {
    public function __construct(
        private DatabaseConnection $db  // Depend on abstraction
    ) { }

    public function saveOrder(Order $order) {
        $this->db->insert('orders', $order->toArray());
    }
}

// Easy to test with mock database
// Easy to switch to PostgreSQL
```

### When to Apply
- When testing requires complex setup for concrete classes
- When code breaks when implementation changes
- When high-level modules know too much about low-level details

---

## ADDITIONAL PRINCIPLES

### DRY (Don't Repeat Yourself)
- Duplicate code is a maintenance nightmare
- Extract repeated logic into methods/functions/classes
- If code changes in one place, it changes in all places

### YAGNI (You Aren't Gonna Need It)
- Don't build functionality for hypothetical future needs
- Implement what's required now
- Avoid over-engineering

### KISS (Keep It Simple, Stupid)
- Simple solutions are better than complex ones
- Avoid clever code that's hard to understand
- Readability > Cleverness

## CROSS-REFERENCES
- For code smells related to SOLID violations: @patterns/CODE-SMELLS.md
- For design pattern implementations: @patterns/DESIGN-PATTERNS.md
- For architecture patterns: @architecture/CLEAN-ARCHITECTURE.md
- For SOLID violations checklist: @design/DESIGN-VIOLATIONS.md
