# Code Smells & Complexity Reduction

Practical reference for detecting Martin Fowler code smells, calculating complexity metrics, and applying deterministic refactoring heuristics.

---

## 1. Code Smell Refactoring Catalog

### Feature Envy
*Smell*: A method accesses the data and methods of another object more than its own.

```php
// ❌ BAD: Feature Envy (OrderProcessor reaches into Customer & Item internals)
final class OrderProcessor {
    public function computeTotal(Order $order): float {
        $total = 0.0;
        foreach ($order->getItems() as $item) {
            $total += $item->getPrice() * $item->getQuantity();
        }
        $discount = $order->getCustomer()->getTierDiscount();
        return $total * (1 - $discount);
    }
}

// ✅ REFACTORED: Move Method & Tell, Don't Ask
final class Order {
    /** @param list<OrderItem> $items */
    public function __construct(
        private Customer $customer,
        private array $items
    ) {}

    public function totalAmount(): float {
        $subtotal = array_reduce(
            $this->items,
            fn(float $sum, OrderItem $item) => $sum + $item->subtotal(),
            0.0
        );
        return $subtotal * (1 - $this->customer->discountRate());
    }
}
```

---

### Data Clumps & Long Parameter Lists
*Smell*: The same cluster of 3+ primitive parameters repeatedly travel together across methods and constructors.

```typescript
// ❌ BAD: Data Clump passed through multiple layers
function createInvoice(
  customerName: string,
  street: string,
  city: string,
  zipCode: string,
  country: string,
  amount: number
): Invoice { /* ... */ }

function shipOrder(
  orderId: string,
  street: string,
  city: string,
  zipCode: string,
  country: string
): void { /* ... */ }

// ✅ REFACTORED: Parameter Object / Address Value Object
export class Address {
  constructor(
    public readonly street: string,
    public readonly city: string,
    public readonly zipCode: string,
    public readonly country: string
  ) {
    if (!street || !city || !zipCode || !country) {
      throw new Error('All address fields are mandatory');
    }
    Object.freeze(this);
  }
}

function createInvoice(customerName: string, billingAddress: Address, amount: number): Invoice { /* ... */ }
function shipOrder(orderId: string, shippingAddress: Address): void { /* ... */ }
```

---

### Primitive Obsession
*Smell*: Relying exclusively on raw primitives (`string`, `int`, `array`) instead of lightweight Value Objects for domain concepts (e.g. Email, Money, ISBN, Currency, Coordinates).

```php
// ❌ BAD: Raw strings and repeated validation
function transferFunds(string $fromIban, string $toIban, int $amountCents, string $currency): void {
    if (!preg_match('/^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$/', $fromIban)) {
        throw new InvalidArgumentException('Invalid source IBAN');
    }
    // Repeated in every method touching IBANs
}

// ✅ REFACTORED: Encapsulated Value Objects
final readonly class Iban {
    public string $value;

    public function __construct(string $value) {
        $clean = strtoupper(str_replace(' ', '', $value));
        if (!preg_match('/^[A-Z]{2}\d{2}[A-Z0-9]{1,30}$/', $clean)) {
            throw new InvalidArgumentException("Invalid IBAN format: {$value}");
        }
        $this->value = $clean;
    }

    public function countryCode(): string {
        return substr($this->value, 0, 2);
    }
}

final readonly class Money {
    public function __construct(
        public int $amountInCents,
        public string $currency = 'USD'
    ) {
        if ($amountInCents < 0) {
            throw new InvalidArgumentException('Money amount cannot be negative');
        }
    }
}

function transferFunds(Iban $from, Iban $to, Money $amount): void {
    // Safe by design: invariants enforced upon instantiation
}
```

---

### Divergent Change vs Shotgun Surgery

| Smell | Definition | Diagnostic Question | Refactoring Remedy |
|---|---|---|---|
| **Divergent Change** | One class is constantly modified for different reasons (violating SRP). | *"When I change the database schema, billing logic, and email templates, why am I editing the same `User` class?"* | **Extract Class / Separate Layers**: Split into Entity, Repository, Notifier, and Validator. |
| **Shotgun Surgery** | A single logical change requires making small edits across many different classes. | *"When I add a new payment gateway, why do I have to touch 12 different files?"* | **Move Method / Centralize Strategy**: Consolidate dispersed logic into a single dedicated module or polymorphic strategy. |

---

## 2. Complexity Metrics & Thresholds

### Cyclomatic Complexity (CC)
Measures the number of linearly independent paths through code ($CC = E - N + 2P$).

| Cyclomatic Score | Risk Category | Action Heuristic |
|---|---|---|
| **1 - 10** | Low Complexity | Clean code; no action needed |
| **11 - 20** | Moderate Risk | Review for guard clauses and method extraction |
| **21 - 50** | High Risk | Refactor immediately: extract strategies/subroutines |
| **> 50** | Untestable / Dangerous | Complete rewrite / decompose module |

### Cognitive Complexity
Measures how difficult code is to comprehend mentally, scoring structural increments for nesting (`if`, `for`, `switch`, callbacks) and boolean operators.

| Cognitive Score | Action |
|---|---|
| **0 - 5** | Optimal readability |
| **6 - 15** | Acceptable for complex domain logic |
| **> 15** | Mandatory refactoring: flatten nesting, remove nested ternaries |

---

## 3. Complexity Reduction Heuristics

### Heuristic 1: Guard Clauses & Early Returns (Flatten Arrow Code)
Eliminate nested conditionals by validating preconditions and returning early.

```python
# ❌ BAD: Deep nesting (Cognitive Complexity = 14)
def process_refund(order, user, reason):
    if order is not None:
        if order.is_paid:
            if user.is_authenticated:
                if user.has_permission("refund"):
                    if not order.is_refunded:
                        order.refund(reason)
                        return {"success": True}
                    else:
                        return {"error": "Already refunded"}
                else:
                    return {"error": "Unauthorized"}
            else:
                return {"error": "Unauthenticated"}
        else:
            return {"error": "Order not paid"}
    return {"error": "Invalid order"}

# ✅ REFACTORED: Guard Clauses (Cognitive Complexity = 1)
def process_refund(order, user, reason):
    if not order:
        return {"error": "Invalid order"}
    if not order.is_paid:
        return {"error": "Order not paid"}
    if not user.is_authenticated:
        return {"error": "Unauthenticated"}
    if not user.has_permission("refund"):
        return {"error": "Unauthorized"}
    if order.is_refunded:
        return {"error": "Already refunded"}

    order.refund(reason)
    return {"success": True}
```

---

### Heuristic 2: Replace Nested Conditionals with Strategy / Lookup Table
Replace cascading `if/elif` or `switch` statements with direct dictionary lookups or polymorphic strategies.

```typescript
// ❌ BAD: Multi-branch tax calculator (High Cyclomatic Complexity)
function getShippingRate(country: string, state: string, weightKg: number): number {
  if (country === 'US') {
    if (state === 'AK' || state === 'HI') return weightKg * 15.0;
    return weightKg * 5.0;
  } else if (country === 'CA') {
    return weightKg * 8.0;
  } else if (country === 'UK') {
    return weightKg * 7.5;
  }
  return weightKg * 20.0;
}

// ✅ REFACTORED: Table-Driven Rate Strategy
type RateCalculator = (weightKg: number, state?: string) => number;

const SHIPPING_RATES: Record<string, RateCalculator> = {
  US: (weight, state) => (state === 'AK' || state === 'HI' ? weight * 15.0 : weight * 5.0),
  CA: (weight) => weight * 8.0,
  UK: (weight) => weight * 7.5,
};

function getShippingRate(country: string, state: string, weightKg: number): number {
  const calculator = SHIPPING_RATES[country] ?? ((w: number) => w * 20.0);
  return calculator(weightKg, state);
}
```

---

### Heuristic 3: Composed Method Pattern
Keep methods short (< 15-20 lines) and at a uniform level of abstraction.

1. **Extract Validation**: Separate input checking from processing.
2. **Extract Business Calculations**: Delegate math/rules to domain entities or pure helper functions.
3. **Extract Persistence & I/O**: Delegate database/API calls to repositories or client services.

---

## 4. Complexity Analysis Commands

```bash
# JavaScript/TypeScript (ESLint complexity rule)
npx eslint --rule 'complexity: ["error", 10]' src/

# Python (Radon complexity audit)
radon cc src/ -a -nb -s

# PHP (PHP Mess Detector - Cyclomatic Complexity)
phpmd app text codesize --suffixes php
```
