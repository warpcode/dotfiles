# Maintainability

## Overview

Comprehensive guide to assessing and improving code maintainability. Maintainability is the ease with which a software system can be modified to correct defects, add new features, or adapt to new environments.

---

## Maintainability Dimensions

```
┌─────────────────────────────────────┐
│      MAINTAINABILITY             │
├─────────────────────────────────────┤
│  1. Readability                 │
│  2. Modularity                    │
│  3. Extensibility                 │
│  4. Testability                   │
│  5. Debuggability                │
│  6. Coupling                      │
│  7. Cohesion                      │
└─────────────────────────────────────┘
```

---

## 1. Readability

### Principles

| Principle | Description | Example |
|-----------|-------------|----------|
| **Self-documenting** | Code is clear, minimal comments | `calculateTotal(items)` |
| **Consistent Naming** | Clear, consistent names | `UserRepository` not `UserRepo` |
| **Small Functions** | Functions do one thing well | `getUserById(id)` not `handleUser()` |
| **Logical Flow** | Code follows natural reading order | Top-down, left-to-right |

### Readability Checklist

- [ ] **Names**: Descriptive, consistent, following conventions
- [ ] **Functions**: Small (<50 lines), single responsibility
- [ ] **Comments**: Self-documenting, no over-commenting
- [ ] **Formatting**: Consistent, uses linter/formatter
- [ ] **Magic Numbers**: Extracted to named constants
- [ ] **Boolean Logic**: Clear, no double negatives
- [ ] **Error Messages**: Descriptive, actionable

### Example

```javascript
// ❌ Poor readability
function handleOrder(o) {
    if (o && o.i && o.i.length && o.i.length > 0 && o.i[0]) {
        if (o.i[0].p && o.i[0].p > 0 && o.i[0].p.id) {
            if (o.i[0].p.id > 0 && o.i[0].p.id <= 100) {
                if (o.i[0].p.q && o.i[0].p.q > 0 && o.i[0].p.q <= 1000) {
                    const x = o.i[0].p.q;
                    const y = o.i[0].p.id * 100 + x;
                    return y;
                }
            }
        }
    }
}

// ✅ Good readability
const MIN_PRODUCT_ID = 1;
const MAX_PRODUCT_ID = 100;
const MIN_QUANTITY = 1;
const MAX_QUANTITY = 1000;

function handleOrder(order) {
    const productId = order.items[0]?.productId;

    if (!isValidProductId(productId)) {
        return { success: false, error: 'Invalid product ID' };
    }

    const quantity = order.items[0]?.quantity || 0;

    if (!isValidQuantity(quantity)) {
        return { success: false, error: 'Invalid quantity' };
    }

    const total = calculateTotal(order.items);
    return { success: true, total };
}

function isValidProductId(id) {
    return id >= MIN_PRODUCT_ID && id <= MAX_PRODUCT_ID;
}

function isValidQuantity(quantity) {
    return quantity >= MIN_QUANTITY && quantity <= MAX_QUANTITY;
}

function calculateTotal(items) {
    return items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
}
```

---

## 2. Modularity

### Principles

| Principle | Description | Example |
|-----------|-------------|----------|
| **Single Responsibility** | Each module has one reason to change | `UserRepository` handles only data access |
| **Open/Closed Principle** | Open for extension, closed for modification | Interfaces for extensibility |
| **Encapsulation** | Internal state hidden, accessed through methods | `bankAccount.withdraw(amount)` |
| **High Cohesion** | Related functionality grouped together | `UserService` groups user operations |
| **Low Coupling** | Minimal dependencies between modules | `OrderService` depends on `UserRepository` interface |

### Modular Architecture

```
┌─────────────────────────────────────┐
│         MODULE STRUCTURE         │
├─────────────────────────────────────┤
│  presentation/                    │
│  ├── components/                  │
│  ├── layouts/                     │
│  └── pages/                       │
├─────────────────────────────────────┤
│  application/                    │
│  ├── services/                     │
│  ├── repositories/                 │
│  ├── models/                      │
│  └── utils/                       │
├─────────────────────────────────────┤
│  shared/                         │
│  ├── constants/                    │
│  ├── types/                       │
│  └── validators/                   │
└─────────────────────────────────────┘
```

### Modularity Checklist

- [ ] **Separation of Concerns**: UI, business logic, data access separated
- [ ] **Module Boundaries**: Clear interfaces between modules
- [ ] **Dependency Direction**: Unidirectional (no circular dependencies)
- [ ] **Module Size**: Modules are focused, not massive
- [ ] **Reusability**: Common functionality extracted to shared modules
- [ ] **Interface Design**: Clear, minimal interfaces
- [ ] **Dependency Injection**: Dependencies injected, not instantiated internally

---

## 3. Extensibility

### Principles

| Principle | Description | Example |
|-----------|-------------|----------|
| **Open/Closed** | New features added without modifying existing code | Plugin architecture |
| **Strategy Pattern** | Algorithms can be swapped at runtime | `DiscountStrategy` for different discount rules |
| **Dependency Injection** | Dependencies can be replaced easily | `UserRepository` interface |
| **Configuration over Code** | Behavior configurable, not hard-coded | Feature flags |

### Extensibility Example

```javascript
// ❌ Poor extensibility
function calculateDiscount(order, user) {
    // Hard-coded discount rules
    if (user.isPremium) {
        return order.total * 0.9;
    } else {
        return order.total;
    }
}

// ✅ Good extensibility - Strategy pattern
class DiscountCalculator {
    constructor(strategy) {
        this.strategy = strategy;
    }

    calculate(order) {
        return this.strategy.calculate(order);
    }
}

class PremiumDiscount {
    calculate(order) {
        return order.total * 0.9;
    }
}

class RegularDiscount {
    calculate(order) {
        return order.total;
    }
}

class VipDiscount {
    calculate(order) {
        return order.total * 0.85;
    }
}

// Usage
const user = getUser(id);
const calculator = user.isPremium
    ? new DiscountCalculator(new PremiumDiscount())
    : new DiscountCalculator(new RegularDiscount());

const discount = calculator.calculate(order);
```

---

## 4. Testability

### Principles

| Principle | Description | Example |
|-----------|-------------|----------|
| **Unit Testability** | Functions can be tested in isolation | No hidden dependencies |
| **Interface Segregation** | Smaller, focused interfaces | `UserReadRepository`, `UserWriteRepository` |
| **Dependency Injection** | Dependencies can be mocked easily | Services accept interfaces |
| **No Side Effects** | Pure functions, no global state | `calculateTotal(items)` |
| **Deterministic** | Same inputs always produce same outputs | No random values in tests |

### Testability Example

```javascript
// ❌ Poor testability
class OrderService {
    constructor() {
        this.db = new Database();  // Hard to mock
        this.emailService = new EmailService();  // Hard to mock
    }

    async processOrder(order) {
        const user = await this.db.getUser(order.userId);
        const discount = this.calculateDiscount(user, order);  // Hidden logic
        await this.emailService.sendConfirmation(user.email);  // Side effect
        const result = await this.charge(order);  // Hidden logic
        return result;
    }
}

// ✅ Good testability
class OrderService {
    constructor(userRepository, discountCalculator, paymentGateway, emailService) {
        this.userRepository = userRepository;  // Injected, can mock
        this.discountCalculator = discountCalculator;  // Injected, can mock
        this.paymentGateway = paymentGateway;  // Injected, can mock
        this.emailService = emailService;  // Injected, can mock
    }

    async processOrder(order) {
        const user = await this.userRepository.findById(order.userId);
        const discount = await this.discountCalculator.calculate(user, order);
        const payment = await this.charge(order, discount);
        await this.emailService.sendConfirmation(user.email, payment);

        return { success: true, orderId: payment.orderId };
    }

    async charge(order, discount) {
        const total = order.total * (1 - discount);
        return await this.paymentGateway.charge(total, order.paymentMethod);
    }
}
```

---

## 5. Debuggability

### Principles

| Principle | Description | Example |
|-----------|-------------|----------|
| **Meaningful Error Messages** | Clear, actionable error messages | `User not found (ID: 123)` |
| **Logging** | Appropriate logging levels and details | `logger.info('Order processed', { orderId })` |
| **Stack Traces** | Include context, not throw errors | `throw new Error('Payment failed', { orderId })` |
| **Debug Mode** | Easy to enable/disable debug output | `if (process.env.DEBUG)` |
| **Assertions** | Runtime checks for invalid states | `assert(user, 'User must be defined')` |

### Debuggability Example

```javascript
// ❌ Poor debuggability
function processPayment(card) {
    try {
        const result = chargeCard(card);
        return result;
    } catch (error) {
        console.log(error);  // Vague logging
        throw 'Failed';  // Generic error message
    }
}

// ✅ Good debuggability
class PaymentProcessor {
    constructor(logger) {
        this.logger = logger;
    }

    async processPayment(paymentData) {
        this.logger.info('Processing payment', { orderId: paymentData.orderId });

        try {
            const validation = await this.validatePayment(paymentData);
            if (!validation.valid) {
                this.logger.warn('Payment validation failed', validation.errors);
                throw new PaymentError('Validation failed', validation.errors);
            }

            const result = await this.chargeCard(paymentData.card, paymentData.amount);
            this.logger.info('Payment successful', { transactionId: result.transactionId });

            return { success: true, transactionId: result.transactionId };
        } catch (error) {
            this.logger.error('Payment failed', {
                error: error.message,
                stack: error.stack,
                orderId: paymentData.orderId
            });

            throw new PaymentError(
                'Payment processing failed',
                { orderId: paymentData.orderId, error: error.message }
            );
        }
    }

    async validatePayment(paymentData) {
        if (!paymentData.card || !paymentData.card.number) {
            return { valid: false, errors: ['Card details required'] };
        }

        if (paymentData.amount <= 0) {
            return { valid: false, errors: ['Amount must be positive'] };
        }

        return { valid: true };
    }
}
```

---

## 6. Coupling

### Coupling Types

| Type | Description | Good | Bad |
|------|-------------|------|-----|
| **Tight Coupling** | Direct dependency on implementation | ❌ |
| **Loose Coupling** | Depends on interface/abstraction | ✅ |
| **Content Coupling** | Modifies passed objects | ❌ |
| **Control Coupling** | Controls flow of other objects | ❌ |
| **Stamp Coupling** | Parent assumes child implementation | ❌ |
| **Data Coupling** | Shared data structures | ⚠️ (minimal OK) |

### Coupling Examples

```javascript
// ❌ Tight coupling
class OrderService {
    constructor() {
        this.db = new MysqlDatabase();  // Direct dependency on implementation
        this.cache = new RedisCache();  // Direct dependency on implementation
    }

    async createOrder(order) {
        await this.db.query('INSERT INTO orders ...');  // Tied to MySQL
        await this.cache.set(`order:${order.id}`, order);  // Tied to Redis
    }
}

// ✅ Loose coupling
class OrderService {
    constructor(database, cache) {
        this.db = database;  // Depends on interface
        this.cache = cache;  // Depends on interface
    }

    async createOrder(order) {
        await this.db.query('INSERT INTO orders ...');  // Can swap implementations
        await this.cache.set(`order:${order.id}`, order);  // Can swap implementations
    }
}
```

---

## 7. Cohesion

### Cohesion Types

| Type | Description | Example |
|------|-------------|----------|
| **Functional Cohesion** | All operations contribute to single task | `StringUtils` |
| **Sequential Cohesion** | Output of one operation is input to next | `Pipeline` |
| **Communicational Cohesion** | Operations on same data | `UserManager` |
| **Temporal Cohesion** | Operations related by timing | `OrderLifecycle` |
| **Logical Cohesion** | Operations logically related | `EmailService` |
| **Coincidental Cohesion** | No relationship between operations | ❌ Bad |

### Cohesion Example

```javascript
// ❌ Coincidental cohesion (bad)
class Utils {
    // Random unrelated functions
    formatDate(date) { /* ... */ }
    calculateDiscount(price) { /* ... */ }
    sendEmail(to, subject, body) { /* ... */ }
    hashPassword(password) { /* ... */ }
    validateUser(user) { /* ... */ }
    generateId() { /* ... */ }
    // ... 20 more unrelated functions
}

// ✅ Logical cohesion (good)
class EmailService {
    sendWelcomeEmail(user) { /* ... */ }
    sendPasswordResetEmail(user) { /* ... */ }
    sendConfirmationEmail(user, orderId) { /* ... */ }
}

class DiscountCalculator {
    calculateRegularDiscount(price) { /* ... */ }
    calculatePremiumDiscount(price) { /* ... */ }
    calculateVipDiscount(price) { /* ... */ }
}
```

---

## Maintainability Assessment

### MI (Maintainability Index) Calculation

```javascript
// MI = 171 - 5.2 × ln(V) - 0.23 × V - 16.2 × ln(G)

Where:
V = Number of unique operators
G = Number of unique operands

function calculateMI(code) {
    const operators = new Set();
    const operands = new Set();

    // Count operators and operands (simplified)
    code.match(/[+\-*/%=<>!&|^|=]/g)?.forEach(op => operators.add(op));
    code.match(/[a-zA-Z_$][a-zA-Z0-9_]*\s*[a-zA-Z0-9_$]/g)?.forEach(match => {
        if (!operands.has(match[0])) operands.add(match[0]);
        if (!operators.has(match[1])) operators.add(match[1]);
    });

    const V = operands.size;
    const G = operators.size;
    const L = code.split('\n').length;

    return 171 - 5.2 * Math.log(V) - 0.23 * V * Math.log(G) - 16.2 * Math.log(L);
}
```

### Maintainability Scores

| MI Score | Maintainability | Risk | Action |
|----------|---------------|-------|--------|
| 85-100 | Very High | Low | No action needed |
| 65-85 | High | Low | Monitor for degradation |
| 50-65 | Moderate | Medium | Consider refactoring |
| 25-50 | Low | High | Refactoring recommended |
| 0-25 | Very Low | Critical | Refactoring required |

---

## Summary

Maintainability assessment:

**Dimensions:**
- **Readability**: Self-documenting, consistent naming, small functions
- **Modularity**: Single responsibility, clear interfaces, separation of concerns
- **Extensibility**: Open/closed principle, strategy patterns, configuration
- **Testability**: Unit testable, dependency injection, no side effects
- **Debuggability**: Meaningful errors, good logging, stack traces
- **Coupling**: Loose coupling (interface-based), minimal dependencies
- **Cohesion**: Logical cohesion (related functionality grouped)

**Assessment:**
- MI (Maintainability Index) score calculation
- Scores: Very High (85-100) to Very Low (0-25)
- Risk-based recommendations

**Improvement Goals:**
- Reduce complexity (CC < 10)
- Improve MI (>65)
- Increase test coverage (>70%)
- Reduce coupling (interface-based dependencies)
- Improve cohesion (logical grouping)

Use maintainability assessment to ensure code can be easily maintained and extended.
