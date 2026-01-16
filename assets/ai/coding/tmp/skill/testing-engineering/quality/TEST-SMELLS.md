# Test Smells

## Overview

Comprehensive guide to identifying test smells (anti-patterns) that reduce test quality, maintainability, and reliability.

---

## Test Smell Categories

```
┌─────────────────────────────────────┐
│        TEST SMELLS               │
├─────────────────────────────────────┤
│  1. Readability Issues         │
│  2. Isolation Problems         │
│  3. Reliability Issues         │
│  4. Maintainability Problems    │
│  5. Design Issues              │
└─────────────────────────────────────┘
```

---

## Readability Issues

### Smell 1: Vague Test Names

**Problem:** Test name doesn't describe what is being tested.

```javascript
// ❌ Smell - Unclear
it('should work', () => { });
it('test user', () => { });
it('case 1', () => { });
it('do something', () => { });

// ✅ Fixed - Clear and descriptive
it('should create user with valid data', () => { });
it('should throw error for duplicate email', () => { });
it('should return 0 for empty cart', () => { });
```

### Smell 2: Magic Numbers in Tests

**Problem:** Hard-coded values without context.

```javascript
// ❌ Smell - Magic numbers
it('should validate password', () => {
    expect(validatePassword('abc')).toBe(false);  // What's min length?
    expect(validatePassword('LongPassword123')).toBe(true);  // What's min length?
});

// ✅ Fixed - Named constants
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

it('should validate password', () => {
    expect(validatePassword('short')).toBe(false);  // Below MIN_PASSWORD_LENGTH
    expect(validatePassword('ValidPass123')).toBe(true);  // Meets MIN_PASSWORD_LENGTH
});
```

### Smell 3: Complex Test Logic

**Problem:** Test has too much logic, not simple assertions.

```javascript
// ❌ Smell - Complex test logic
it('should calculate discount', () => {
    const price = 100;
    let discount = 0;
    if (isPremium) {
        if (price > 50) {
            discount = price * 0.15;
        } else {
            discount = price * 0.10;
        }
    } else {
        if (price > 100) {
            discount = price * 0.05;
        }
    }
    expect(calculateDiscount(price, isPremium)).toBe(discount);
});

// ✅ Fixed - Simple test
it('should calculate 15% discount for premium user over $50', () => {
    const result = calculateDiscount(100, true);
    expect(result).toBe(15);
});

it('should calculate 10% discount for premium user under $50', () => {
    const result = calculateDiscount(40, true);
    expect(result).toBe(4);
});
```

---

## Isolation Problems

### Smell 4: Tests Depend on Each Other

**Problem:** Tests have implicit dependencies on execution order.

```javascript
// ❌ Smell - Tests depend on each other
describe('UserRegistration', () => {
    it('should create first user', () => {
        const user = userService.create({ name: 'John' });
        expect(user.id).toBe(1);
    });

    it('should create second user', () => {
        // Depends on first test being run!
        const user = userService.create({ name: 'Jane' });
        expect(user.id).toBe(2);
    });
});

// ✅ Fixed - Isolated tests
describe('UserRegistration', () => {
    beforeEach(() => {
        db.clear();  // Clean database before each test
    });

    it('should create user with ID starting fresh', () => {
        const user = userService.create({ name: 'John' });
        expect(user.id).toBeDefined();  // Don't check exact ID
    });

    it('should create second user with fresh state', () => {
        const user = userService.create({ name: 'Jane' });
        expect(user.id).toBeDefined();  // Independent of first test
    });
});
```

### Smell 5: Tests Access Global State

**Problem:** Tests modify or rely on global state.

```javascript
// ❌ Smell - Global state
let globalCounter = 0;

function incrementCounter() {
    return ++globalCounter;
}

it('should increment counter', () => {
    const result = incrementCounter();
    expect(result).toBe(1);
});

it('should increment counter again', () => {
    const result = incrementCounter();
    expect(result).toBe(2);  // FAILS if run alone!
});

// ✅ Fixed - No global state
function createCounter() {
    let counter = 0;
    return () => ++counter;
}

it('should increment counter', () => {
    const counter = createCounter();
    expect(counter()).toBe(1);
});

it('should increment counter independently', () => {
    const counter = createCounter();  // Fresh counter
    expect(counter()).toBe(1);  // Always works
});
```

### Smell 6: Direct Database Access in Tests

**Problem:** Unit tests directly access database.

```javascript
// ❌ Smell - Direct DB access in unit test
it('should save user to database', async () => {
    const user = await User.save({ name: 'John' });
    expect(user.id).toBeDefined();

    const found = await User.findById(user.id);
    expect(found).toEqual(user);
});
// This is an integration test, not unit test!

// ✅ Fixed - Use mock repository
it('should call repository save method', async () => {
    const mockRepo = {
        save: jest.fn().mockResolvedValue({ id: 1, name: 'John' })
    };

    const user = await userService.create({ name: 'John' }, mockRepo);

    expect(mockRepo.save).toHaveBeenCalledWith({ name: 'John' });
});
```

---

## Reliability Issues

### Smell 7: Hard-Coded Waits

**Problem:** Tests use fixed sleep/waits instead of waiting for conditions.

```javascript
// ❌ Smell - Hard-coded wait
it('should load data', () => {
    cy.visit('/dashboard');
    cy.wait(5000);  // Always wait 5 seconds
    cy.contains('Welcome').should('be.visible');
    // Flaky if slow network!
});

// ✅ Fixed - Wait for condition
it('should load data', () => {
    cy.visit('/dashboard');
    cy.contains('Welcome', { timeout: 10000 }).should('be.visible');
    // Wait up to 10 seconds for element
});
```

### Smell 8: Sleepy Tests

**Problem:** Tests intentionally sleep without reason.

```javascript
// ❌ Smell - Sleepy test
it('should process order', async () => {
    const order = await orderService.process({ items: [...] });
    await new Promise(resolve => setTimeout(resolve, 1000));  // Why?
    expect(order.status).toBe('completed');
});

// ✅ Fixed - Remove unnecessary sleep
it('should process order', async () => {
    const order = await orderService.process({ items: [...] });
    expect(order.status).toBe('completed');
});
```

### Smell 9: Brittle Selectors

**Problem:** Tests use tight coupling to DOM structure.

```javascript
// ❌ Smell - Brittle selector
it('should display user name', () => {
    cy.get('div > div > div > div:nth-child(2) > span.user-name').click();
    // Breaks if DOM changes!
});

// ✅ Fixed - Stable selector
it('should display user name', () => {
    cy.get('[data-testid="user-name"]').click();
    // Stable even if DOM structure changes
});
```

---

## Maintainability Problems

### Smell 10: Duplicated Test Code

**Problem:** Same code repeated across multiple tests.

```javascript
// ❌ Smell - Duplicated setup
describe('UserService', () => {
    it('should create user', () => {
        const user = userService.create({
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!',
            role: 'user',
            active: true,
            createdAt: new Date()
        });
        expect(user.id).toBeDefined();
    });

    it('should find user by email', () => {
        const user = userService.findByEmail('john@example.com');
        expect(user).toBeDefined();
        // Same user data repeated!
    });

    it('should update user', () => {
        const user = userService.create({
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!',
            // ... again
        });
        // ...
    });
});

// ✅ Fixed - Extract to helper
function createTestUser(overrides = {}) {
    return {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!',
        role: 'user',
        active: true,
        createdAt: new Date(),
        ...overrides
    };
}

describe('UserService', () => {
    it('should create user', () => {
        const user = userService.create(createTestUser());
        expect(user.id).toBeDefined();
    });
});
```

### Smell 11: Excessive Setup Code

**Problem:** Tests have too much arrangement code.

```javascript
// ❌ Smell - Excessive setup
it('should process order', () => {
    // 50+ lines of setup...
    const user = new User({ name: 'John', email: 'john@example.com', ... });
    const products = [
        new Product({ name: 'Laptop', price: 1000, stock: 10, ... }),
        new Product({ name: 'Mouse', price: 25, stock: 50, ... })
    ];
    const cart = new ShoppingCart({ user, ... });
    products.forEach(p => cart.addItem(p));
    cart.applyDiscount(new Coupon({ code: 'SAVE10', ... }));
    cart.applyTax(0.2);
    const shipping = new Shipping({ address: {...}, ... });
    const payment = new Payment({ method: 'credit_card', ... });

    const order = cart.checkout(payment, shipping);

    expect(order.total).toBe(expected);
});

// ✅ Fixed - Extract to helper
function createTestOrder() {
    return {
        user: createTestUser(),
        cart: createTestCart(),
        payment: createTestPayment(),
        shipping: createTestShipping()
    };
}

it('should process order', () => {
    const orderData = createTestOrder();
    const order = orderService.process(orderData);
    expect(order.total).toBe(expected);
});
```

### Smell 12: Test Only Mock Interactions

**Problem:** Tests verify mock calls instead of real behavior.

```javascript
// ❌ Smell - Testing mock only
it('should call repository', () => {
    const mockRepo = {
        save: jest.fn().mockResolvedValue({ id: 1, name: 'John' })
    };

    const user = userService.create({ name: 'John' }, mockRepo);

    expect(mockRepo.save).toHaveBeenCalled();  // Only testing mock!
    expect(user).toEqual({ id: 1, name: 'John' });  // Mock returns what we set!
    // What are we actually testing?
});

// ✅ Fixed - Test real behavior
it('should transform user data', () => {
    const mockRepo = {
        save: jest.fn().mockResolvedValue({
            id: 1,
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com'
        })
    };

    const user = userService.create({ name: 'John' }, mockRepo);

    expect(user).toEqual({
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
        initials: 'JD'
    });
});
```

---

## Design Issues

### Smell 13: Assertion Roulette

**Problem:** Too many assertions in a single test.

```javascript
// ❌ Smell - Too many assertions
it('should create user', () => {
    const user = userService.create({ name: 'John' });

    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
    expect(user.email).toBe('john@example.com');
    expect(user.password).not.toBe('SecurePass123!');
    expect(user.role).toBe('user');
    expect(user.active).toBe(true);
    expect(user.createdAt).toBeDefined();
    expect(user.updatedAt).toBeDefined();
    // 8 assertions!
});

// ✅ Fixed - Split into focused tests
it('should generate user ID', () => {
    const user = userService.create({ name: 'John' });
    expect(user.id).toBeDefined();
});

it('should hash password', () => {
    const user = userService.create({ name: 'John', password: 'Pass123' });
    expect(user.password).not.toBe('Pass123');
});

it('should set default role', () => {
    const user = userService.create({ name: 'John' });
    expect(user.role).toBe('user');
});
```

### Smell 14: The Liar

**Problem:** Test always passes, doesn't actually test anything.

```javascript
// ❌ Smell - Liar test
it('should calculate total', () => {
    const result = calculateTotal(items);
    expect(result).toBe(result);  // Always true!
});

// ✅ Fixed - Real assertion
it('should calculate total', () => {
    const items = [{ price: 10 }, { price: 20 }];
    const result = calculateTotal(items);
    expect(result).toBe(30);  // Specific value
});
```

### Smell 15: Test Code in Production

**Problem:** Test-only code or assertions in production code.

```javascript
// ❌ Smell - Test code in production
class UserService {
    async create(userData) {
        const user = await this.repo.save(userData);

        // TEST ONLY
        if (process.env.NODE_ENV === 'test') {
            console.log('User created:', user);
        }

        return user;
    }
}

// ✅ Fixed - Remove test code
class UserService {
    async create(userData) {
        const user = await this.repo.save(userData);
        return user;
    }
}

// Add logging separately if needed
```

---

## Detecting Test Smells

### Automated Detection

```bash
# Find tests with vague names
grep -r "it('should work" tests/
grep -r "it('test " tests/
grep -r "it('case" tests/

# Find tests with magic numbers
grep -r "expect.*toBe(0)\|toBe(1)\|toBe(2)" tests/

# Find tests with hard-coded waits
grep -r "cy.wait\|sleep(" tests/

# Find tests with too many assertions (>5 per test)
# This requires custom tooling or manual review
```

### Manual Code Review Checklist

For each test, check:

- [ ] Test name is descriptive and clear
- [ ] No magic numbers (use named constants)
- [ ] No hard-coded waits (wait for conditions)
- [ ] Test is isolated (doesn't depend on other tests)
- [ ] No global state modified
- [ ] No duplicated setup code (extract to helpers)
- [ ] Reasonable setup length (<20 lines)
- [ ] Tests real behavior, not just mocks
- [ ] Single focused assertion (1-3 assertions max)
- [ ] Test always passes (not a liar)
- [ ] No test-only code in production

---

## Refactoring Test Smells

### Smell: Duplicated Code → Extract Helpers

**Before:**
```javascript
describe('UserService', () => {
    it('test 1', () => {
        const user = {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!',
            role: 'user'
        };
        // ...
    });

    it('test 2', () => {
        const user = {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!',
            role: 'user'
        };
        // ...
    });
});
```

**After:**
```javascript
function createTestUser() {
    return {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!',
        role: 'user'
    };
}

describe('UserService', () => {
    it('test 1', () => {
        const user = createTestUser();
        // ...
    });

    it('test 2', () => {
        const user = createTestUser();
        // ...
    });
});
```

### Smell: Excessive Assertions → Split Tests

**Before:**
```javascript
it('should create user', () => {
    const user = userService.create(data);
    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
    expect(user.email).toBe('john@example.com');
    expect(user.role).toBe('user');
    expect(user.active).toBe(true);
});
```

**After:**
```javascript
it('should generate user ID', () => {
    const user = userService.create(data);
    expect(user.id).toBeDefined();
});

it('should set user properties correctly', () => {
    const user = userService.create(data);
    expect(user.name).toBe('John');
    expect(user.email).toBe('john@example.com');
});
```

---

## Summary

Test smells reduce quality and maintainability:

**Categories:**
- **Readability**: Vague names, magic numbers, complex logic
- **Isolation**: Test dependencies, global state, direct DB access
- **Reliability**: Hard-coded waits, sleepy tests, brittle selectors
- **Maintainability**: Duplication, excessive setup, mock-only tests
- **Design**: Assertion roulette, liar tests, test code in production

**Detection:**
- Automated: grep patterns for vague names, magic numbers, waits
- Manual: Code review checklist

**Refactoring:**
- Extract duplicated code to helpers
- Split tests with excessive assertions
- Remove test-only code from production
- Replace hard-coded waits with condition waits

**Goal:** Write clear, isolated, reliable tests that are easy to maintain.

Use test smell detection to improve test quality over time.
