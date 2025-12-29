# CODE SMELLS

## OVERVIEW
Code smells are surface indicators that usually correspond to deeper problems in the system. They're not bugs, but suggest code needs refactoring.

## STRUCTURAL SMELLS

### Long Method

**Definition**: A method that does too much or is too long to understand easily.

**Characteristics**:
- More than 20-30 lines
- Multiple levels of abstraction mixed
- Difficult to test
- Hard to understand purpose

**Example**:
```php
// BAD: Long method (50+ lines)
public function processOrder($orderData) {
    // Validate
    if (!$orderData['email']) {
        throw new Exception('Email required');
    }
    if (!$orderData['address']) {
        throw new Exception('Address required');
    }
    // ... 10 more validations

    // Create user
    $user = new User();
    $user->setEmail($orderData['email']);
    $user->setName($orderData['name']);
    // ... more user setup

    // Calculate totals
    $subtotal = 0;
    foreach ($orderData['items'] as $item) {
        $subtotal += $item['price'] * $item['quantity'];
        // ... more calculations
    }
    // ... 20 more lines of logic
}
```

**Fix**: Extract method
```php
public function processOrder($orderData) {
    $this->validateOrder($orderData);
    $user = $this->createUser($orderData);
    $total = $this->calculateTotal($orderData);
    $this->saveOrder($user, $total);
}

private function validateOrder($orderData) { }
private function createUser($orderData) { }
private function calculateTotal($orderData) { }
```

---

### Deep Nesting

**Definition**: Multiple levels of nested conditionals or loops.

**Characteristics**:
- Nesting depth > 4 levels
- Arrow-shaped code (indentation to the right)
- Difficult to follow logic

**Example**:
```php
// BAD: Deep nesting
function processData($data) {
    if ($data) {
        if ($data['type'] === 'A') {
            if ($data['valid']) {
                if ($data['hasPermission']) {
                    if ($data['withinTimeLimit']) {
                        // Do something
                    }
                }
            }
        }
    }
}
```

**Fix**: Early returns, guard clauses
```php
function processData($data) {
    if (!$data) return null;
    if ($data['type'] !== 'A') return null;
    if (!$data['valid']) return null;
    if (!$data['hasPermission']) return null;
    if (!$data['withinTimeLimit']) return null;

    // Do something
}
```

---

### Duplicate Code

**Definition**: Same or similar code appearing in multiple places.

**Characteristics**:
- Copy-pasted code blocks
- Same logic in multiple methods/classes
- Maintenance nightmare (fix in one place, need to fix in all)

**Example**:
```php
// BAD: Duplicate code
class OrderService {
    public function processOrder($order) {
        if ($order['status'] === 'completed' || $order['status'] === 'paid') {
            // Logic here
        }
    }
}

class InvoiceService {
    public function createInvoice($invoice) {
        if ($invoice['status'] === 'completed' || $invoice['status'] === 'paid') {
            // Same logic here
        }
    }
}
```

**Fix**: Extract method/class
```php
class StatusHelper {
    public static function isFinalStatus(string $status): bool {
        return in_array($status, ['completed', 'paid']);
    }
}

// Usage
if (StatusHelper::isFinalStatus($order['status'])) { }
```

---

## COUPLING SMELLS

### Feature Envy

**Definition**: A method that accesses data of another object more than its own data.

**Characteristics**:
- Method calls many getters on another object
- Should be moved to the other object
- Violates encapsulation

**Example**:
```php
// BAD: Feature envy
class OrderProcessor {
    public function process(Order $order) {
        $total = 0;
        foreach ($order->getItems() as $item) {
            $total += $item->getPrice() * $item->getQuantity();
        }
        $discount = $order->getCustomer()->getDiscountRate();
        $tax = $order->getTaxRate();
        return $this->calculate($total, $discount, $tax);
    }
}
```

**Fix**: Move method to Order
```php
class Order {
    public function calculateTotal(): float {
        $total = 0;
        foreach ($this->items as $item) {
            $total += $item->price * $item->quantity;
        }
        $discount = $this->customer->getDiscountRate();
        $tax = $this->taxRate;
        return $this->calculate($total, $discount, $tax);
    }
}
```

---

### Inappropriate Intimacy

**Definition**: Two classes are too familiar with each other's internals.

**Characteristics**:
- Excessive use of getters/setters
- Direct field access
- Breaks encapsulation

**Example**:
```php
// BAD: Inappropriate intimacy
class OrderService {
    public function validate(Order $order) {
        // Directly accessing internal fields
        if ($order->customer->address->city === 'London') {
            // Logic
        }
        if ($order->items[0]->discount > 0.5) {
            // Logic
        }
    }
}
```

**Fix**: Tell, Don't Ask principle
```php
class Order {
    public function isValidForShipping(): bool {
        return $this->customer->isInLondon() &&
               $this->hasValidDiscounts();
    }
}

class OrderService {
    public function validate(Order $order) {
        return $order->isValidForShipping();
    }
}
```

---

## CHANGE PREVENTERS

### Divergent Change

**Definition**: One class requires many different changes for different reasons.

**Characteristics**:
- Different types of changes require modifying same class
- Violates Single Responsibility Principle
- Class does too much

**Example**:
```php
// BAD: Divergent change
class User {
    public function saveToDatabase() { } // Database change
    public function sendEmail() { } // Email change
    public function formatOutput() { } // UI change
    public function validateInput() { } // Validation change
    public function calculatePermissions() { } // Security change
}
```

**Fix**: Split into separate classes
```php
class User { /* Domain model only */ }
class UserRepository { /* Database operations */ }
class EmailService { /* Email operations */ }
class UserValidator { /* Validation logic */ }
```

---

### Shotgun Surgery

**Definition**: Making a single change requires modifying many different classes.

**Characteristics**:
- One feature spread across many classes
- Feature envy across codebase
- Poor cohesion

**Example**:
```php
// BAD: Shotgun surgery
// To change email format, need to modify all these:
class User { public function getEmail() { } }
class Order { public function getEmail() { } }
class Invoice { public function getEmail() { } }
class Notification { public function getEmail() { } }
```

**Fix**: Centralize logic
```php
class EmailFormatter {
    public static function format(string $email): string { }
}

// All classes use: EmailFormatter::format($email)
```

---

## ABSTRACTION SMELLS

### Primitive Obsession

**Definition**: Using primitive types (strings, numbers) instead of small classes.

**Characteristics**:
- No type safety for domain concepts
- Logic scattered across codebase
- Duplicate validation

**Example**:
```php
// BAD: Primitive obsession
class Order {
    public function __construct(
        public string $email,
        public string $phone,
        public string $postcode
    ) { }
}

// Validation repeated everywhere
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) { }
if (!preg_match('/^\+44\d{10}$/', $phone)) { }
```

**Fix**: Value objects
```php
class Email {
    public function __construct(public string $value) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email');
        }
    }
}

class Phone {
    public function __construct(public string $value) {
        if (!preg_match('/^\+44\d{10}$/', $value)) {
            throw new InvalidArgumentException('Invalid phone');
        }
    }
}

class Order {
    public function __construct(
        public Email $email,
        public Phone $phone,
        public Postcode $postcode
    ) { }
}
```

---

### Data Clumps

**Definition**: Group of variables that always appear together.

**Characteristics**:
- Same parameters passed together repeatedly
- Data belongs together
- Should be object

**Example**:
```php
// BAD: Data clumps
function processUser($name, $email, $phone, $address, $city, $postcode) { }
function sendNotification($name, $email, $phone, $address, $city, $postcode) { }
function createInvoice($name, $email, $phone, $address, $city, $postcode) { }
```

**Fix**: Value object
```php
class UserContactInfo {
    public function __construct(
        public string $name,
        public string $email,
        public string $phone,
        public string $address,
        public string $city,
        public string $postcode
    ) { }
}

function processUser(UserContactInfo $info) { }
function sendNotification(UserContactInfo $info) { }
function createInvoice(UserContactInfo $info) { }
```

---

## CROSS-REFERENCES
- For anti-patterns: @patterns/ANTI-PATTERNS.md
- For SOLID violations: @design/DESIGN-VIOLATIONS.md
- For design patterns: @patterns/DESIGN-PATTERNS.md
- For performance issues: @performance/COMMON-ISSUES.md
