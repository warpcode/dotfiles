# Unit Testing

## Overview

Comprehensive guide to unit testing across frameworks. Unit tests verify individual functions, classes, or modules in isolation.

---

## Unit Testing Fundamentals

### What is a Unit Test?

A test that verifies a single unit of code (function, method, class) in isolation from external dependencies.

### Characteristics

- **Isolated**: No external dependencies (DB, API, filesystem)
- **Fast**: Runs in milliseconds
- **Deterministic**: Same result every time
- **Focused**: Tests single behavior
- **Independent**: Can run in any order

### Unit vs Integration vs E2E

| Aspect | Unit Tests | Integration Tests | E2E Tests |
|--------|-----------|------------------|------------|
| Scope | Single function/class | Multiple components | Full system |
| Dependencies | Mocked/Faked | Real or test doubles | Real system |
| Speed | <100ms | <5s | >10s |
| Isolation | Yes | Partial | No |
| Flakiness | Rare | Occasional | Frequent |

---

## When to Write Unit Tests

### Good Candidates

✅ **Pure functions** (no side effects)
```javascript
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
}
```

✅ **Business logic** (calculations, validation, transformations)
```javascript
function applyDiscount(price, isPremium) {
    return isPremium ? price * 0.8 : price;
}
```

✅ **Validation rules** (format checks, constraints)
```javascript
function isValidEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

✅ **Data transformation** (formatting, parsing)
```javascript
function formatDate(date) {
    return date.toLocaleDateString('en-GB');
}
```

### Poor Candidates

❌ **Database queries** (should be integration test)
```javascript
// Don't unit test this
async function getUserById(id) {
    return await db.query('SELECT * FROM users WHERE id = ?', [id]);
}
```

❌ **API calls** (should be integration test)
```javascript
// Don't unit test this
async function fetchUser(id) {
    return await api.get(`/users/${id}`);
}
```

❌ **File system operations** (should be integration test)
```javascript
// Don't unit test this
function readConfigFile(path) {
    return fs.readFileSync(path, 'utf8');
}
```

---

## Unit Testing Patterns

### Pure Function Testing

**JavaScript (Jest):**
```javascript
describe('calculateTotal', () => {
    it('should sum item prices', () => {
        const items = [
            { price: 10 },
            { price: 20 },
            { price: 30 }
        ];
        expect(calculateTotal(items)).toBe(60);
    });

    it('should return 0 for empty array', () => {
        expect(calculateTotal([])).toBe(0);
    });

    it('should handle negative prices (discounts)', () => {
        const items = [
            { price: 100 },
            { price: -10 }  // Discount
        ];
        expect(calculateTotal(items)).toBe(90);
    });
});
```

**Python (PyTest):**
```python
def test_calculate_total():
    items = [
        {'price': 10},
        {'price': 20},
        {'price': 30}
    ]
    assert calculate_total(items) == 60

def test_calculate_total_empty():
    assert calculate_total([]) == 0

def test_calculate_total_negative_prices():
    items = [
        {'price': 100},
        {'price': -10}
    ]
    assert calculate_total(items) == 90
```

### Class Method Testing

**JavaScript (Jest):**
```javascript
describe('EmailValidator', () => {
    let validator;

    beforeEach(() => {
        validator = new EmailValidator();
    });

    describe('isValid', () => {
        it('should validate correct email', () => {
            expect(validator.isValid('john@example.com')).toBe(true);
        });

        it('should reject email without @', () => {
            expect(validator.isValid('johnexample.com')).toBe(false);
        });

        it('should reject email without domain', () => {
            expect(validator.isValid('john@')).toBe(false);
        });

        it('should reject empty string', () => {
            expect(validator.isValid('')).toBe(false);
        });
    });

    describe('normalize', () => {
        it('should trim whitespace', () => {
            expect(validator.normalize('  john@example.com  '))
                .toBe('john@example.com');
        });

        it('should convert to lowercase', () => {
            expect(validator.normalize('John@Example.COM'))
                .toBe('john@example.com');
        });
    });
});
```

**PHP (Pest):**
```php
describe('EmailValidator', function () {
    $validator;

    beforeEach(function () {
        $validator = new EmailValidator();
    });

    describe('isValid', function () {
        it('validates correct email', function () use (&$validator) {
            expect($validator->isValid('john@example.com'))->toBeTrue();
        });

        it('rejects email without @', function () use (&$validator) {
            expect($validator->isValid('johnexample.com'))->toBeFalse();
        });

        it('rejects empty email', function () use (&$validator) {
            expect($validator->isValid(''))->toBeFalse();
        });
    });
});
```

### Testing with Dependencies (Using Test Doubles)

**JavaScript (Jest):**
```javascript
describe('UserService', () => {
    let userService;
    let mockUserRepository;
    let mockEmailService;

    beforeEach(() => {
        // Mock dependencies
        mockUserRepository = {
            findById: jest.fn(),
            save: jest.fn(),
            findByEmail: jest.fn(),
        };

        mockEmailService = {
            sendWelcome: jest.fn(),
        };

        // Create service with mocked dependencies
        userService = new UserService(mockUserRepository, mockEmailService);
    });

    describe('createUser', () => {
        it('should create user and send welcome email', async () => {
            const userData = {
                name: 'John Doe',
                email: 'john@example.com',
                password: 'SecurePass123!'
            };

            mockUserRepository.findByEmail.mockResolvedValue(null);
            mockUserRepository.save.mockResolvedValue({
                id: 1,
                ...userData
            });
            mockEmailService.sendWelcome.mockResolvedValue({ success: true });

            const user = await userService.createUser(userData);

            // Verify user created
            expect(user.id).toBeDefined();
            expect(user.name).toBe('John Doe');

            // Verify dependencies called
            expect(mockUserRepository.findByEmail).toHaveBeenCalledWith('john@example.com');
            expect(mockUserRepository.save).toHaveBeenCalled();
            expect(mockEmailService.sendWelcome).toHaveBeenCalledWith(
                'john@example.com',
                'John Doe'
            );
        });

        it('should throw error if email already exists', async () => {
            mockUserRepository.findByEmail.mockResolvedValue({
                id: 1,
                email: 'john@example.com'
            });

            await expect(
                userService.createUser({
                    name: 'John Doe',
                    email: 'john@example.com',
                    password: 'SecurePass123!'
                })
            ).rejects.toThrow('Email already exists');
        });
    });
});
```

**Python (PyTest):**
```python
class TestUserService:
    def setup_method(self):
        # Mock dependencies
        self.mock_repo = Mock()
        self.mock_email_service = Mock()

        # Create service with mocked dependencies
        self.service = UserService(self.mock_repo, self.mock_email_service)

    def test_create_user_sends_welcome_email(self):
        user_data = {
            'name': 'John Doe',
            'email': 'john@example.com',
            'password': 'SecurePass123!'
        }

        # Configure mocks
        self.mock_repo.find_by_email.return_value = None
        self.mock_repo.save.return_value = {
            'id': 1,
            **user_data
        }
        self.mock_email_service.send_welcome.return_value = {'success': True}

        # Test
        user = self.service.create_user(user_data)

        # Verify user created
        assert user['id'] == 1
        assert user['name'] == 'John Doe'

        # Verify dependencies called
        self.mock_repo.find_by_email.assert_called_once_with('john@example.com')
        self.mock_repo.save.assert_called_once()
        self.mock_email_service.send_welcome.assert_called_once_with(
            'john@example.com',
            'John Doe'
        )

    def test_create_user_throws_if_email_exists(self):
        # Configure mock
        self.mock_repo.find_by_email.return_value = {
            'id': 1,
            'email': 'john@example.com'
        }

        # Test and assert
        with pytest.raises(EmailAlreadyExistsError):
            self.service.create_user({
                'name': 'John Doe',
                'email': 'john@example.com',
                'password': 'SecurePass123!'
            })
```

---

## Unit Testing Best Practices

### 1. Test Behavior, Not Implementation

```javascript
// ❌ Bad - Testing implementation details
it('should call findById method', () => {
    const spy = jest.spyOn(UserRepository, 'findById');
    const user = userService.findById(1);
    expect(spy).toHaveBeenCalled();  // Testing internal!
});

// ✅ Good - Testing behavior
it('should return user by ID', () => {
    const user = userService.findById(1);
    expect(user).toEqual(expectedUser);
    expect(user.id).toBe(1);
    expect(user.name).toBe('John Doe');
});
```

### 2. One Assertion Per Test

```javascript
// ❌ Bad - Multiple assertions
it('should create user', () => {
    const user = userService.create({ name: 'John' });
    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
    expect(user.email).toBeDefined();
    expect(user.active).toBe(true);
    expect(user.createdAt).toBeDefined();
});

// ✅ Good - One assertion per test
it('should create user with correct name', () => {
    const user = userService.create({ name: 'John' });
    expect(user.name).toBe('John');
});

it('should generate user ID', () => {
    const user = userService.create({ name: 'John' });
    expect(user.id).toBeDefined();
});

it('should set user as active', () => {
    const user = userService.create({ name: 'John' });
    expect(user.active).toBe(true);
});
```

### 3. Test Edge Cases

```javascript
describe('calculateDiscount', () => {
    it('should apply premium discount', () => {
        expect(calculateDiscount(100, true)).toBe(80);
    });

    it('should not apply discount for non-premium', () => {
        expect(calculateDiscount(100, false)).toBe(100);
    });

    // Edge cases
    it('should handle zero price', () => {
        expect(calculateDiscount(0, true)).toBe(0);
    });

    it('should handle negative price', () => {
        expect(calculateDiscount(-100, true)).toBe(-100);
    });

    it('should handle very large price', () => {
        expect(calculateDiscount(1000000, true)).toBe(800000);
    });
});
```

### 4. Use Descriptive Test Names

```javascript
// ❌ Bad - Unclear names
it('should work', () => { });
it('test discount', () => { });
it('case 1', () => { });

// ✅ Good - Clear names
it('should calculate premium discount correctly', () => { });
it('should throw error for negative price', () => { });
it('should handle edge case of zero price', () => { });
```

### 5. Use Test Builders for Complex Data

```javascript
// Test builder
class UserBuilder {
    constructor() {
        this.user = {
            name: 'John Doe',
            email: 'john@example.com',
            role: 'user',
            active: true,
            createdAt: new Date()
        };
    }

    withRole(role) {
        this.user.role = role;
        return this;
    }

    inactive() {
        this.user.active = false;
        return this;
    }

    withEmail(email) {
        this.user.email = email;
        return this;
    }

    build() {
        return this.user;
    }
}

// Test
it('should not allow inactive users to login', () => {
    const user = new UserBuilder()
        .inactive()
        .withRole('user')
        .build();

    expect(() => authService.login(user))
        .toThrow('User is inactive');
});
```

---

## Unit Testing Anti-Patterns

### ❌ "The Test-Only Mock" - Testing the Mock

```javascript
// Bad - Testing nothing real
it('should call repository', () => {
    const mockRepo = jest.fn().mockResolvedValue(user);
    const service = new UserService(mockRepo);

    const result = await service.findById(1);

    expect(mockRepo).toHaveBeenCalled();  // Only testing mock!
    expect(result).toBe(user);  // Mock returns what we set!
});
```

**Fix:** Test real behavior.

```javascript
// Good - Testing actual logic
it('should transform user data', () => {
    const mockRepo = {
        findById: jest.fn().mockResolvedValue({
            id: 1,
            first_name: 'John',
            last_name: 'Doe',
            email: 'john@example.com'
        })
    };

    const result = await userService.findById(1);

    expect(result).toEqual({
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
        initials: 'JD'
    });
});
```

### ❌ "The Setup Overload" - Too Much Arrangement

```javascript
// Bad - Too much setup code
it('should process order', () => {
    // 50+ lines of setup...
    const user = new User({ name: 'John', email: 'john@example.com', ... });
    const products = [new Product(...), new Product(...), new Product(...)];
    const cart = new ShoppingCart({ user, ... });
    products.forEach(p => cart.addItem(p));
    cart.applyDiscount(new Coupon(...));
    cart.applyTax(...);
    const shipping = new Shipping({ ... });
    const payment = new Payment({ ... });

    const order = cart.checkout(payment, shipping);

    expect(order.total).toBe(expected);
});
```

**Fix:** Extract setup to helpers.

```javascript
// Good - Helper functions
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

### ❌ "The Implementation Leak" - Testing Internal Methods

```javascript
// Bad - Testing private/internal methods
class UserService {
    async createUser(data) {
        this.validateEmail(data.email);  // Private method
        this.validatePassword(data.password);  // Private method
        return await this.repo.save(data);
    }
}

it('should validate email', () => {
    const service = new UserService();
    expect(service.validateEmail('invalid')).toBe(false);  // Testing private!
});
```

**Fix:** Test public API, not internals.

```javascript
// Good - Testing public behavior
it('should throw error for invalid email', () => {
    expect(() => userService.create({
        name: 'John',
        email: 'invalid-email'
    })).toThrow('Invalid email');
});
```

---

## Unit Testing Checklist

### Test Case Checklist

For each unit, test:

- [ ] **Happy path**: Normal operation
- [ ] **Edge cases**: Empty, null, zero, negative
- [ ] **Error cases**: Invalid inputs, missing data
- [ ] **Boundary conditions**: Min/max values, limits
- [ ] **Success case**: Expected result returned
- [ ] **Failure case**: Error thrown, null returned

### Example: `calculateDiscount` Function

```javascript
describe('calculateDiscount', () => {
    // Happy path
    it('should apply 20% discount for premium users');

    it('should not apply discount for regular users');

    // Edge cases
    it('should handle zero price');
    it('should handle negative price (refunds)');
    it('should handle very large price');

    // Boundary conditions
    it('should handle minimum price (0)');
    it('should handle maximum discount threshold');

    // Error cases
    it('should handle null price');
    it('should handle undefined isPremium flag');
});
```

---

## Summary

Unit testing tests isolated code:

**Characteristics:**
- Fast (<100ms)
- Isolated (no external dependencies)
- Deterministic (same result)
- Focused (single behavior)

**Good Candidates:**
- Pure functions
- Business logic
- Validation rules
- Data transformation

**Poor Candidates:**
- Database queries
- API calls
- File system operations

**Best Practices:**
- Test behavior, not implementation
- One assertion per test
- Test edge cases
- Descriptive test names
- Use test builders

**Anti-Patterns:**
- Testing only mocks
- Setup overload
- Implementation leak (testing private methods)

Use unit tests for fast, reliable feedback on code correctness.
