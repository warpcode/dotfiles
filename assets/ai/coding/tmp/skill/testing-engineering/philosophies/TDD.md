# Test-Driven Development (TDD)

## Overview

Comprehensive guide to Test-Driven Development methodology. TDD is a software development process where tests are written before the production code, ensuring better design, fewer bugs, and comprehensive test coverage.

## Core Principles

### TDD Mantra

> **Red → Green → Refactor**

1. **Red**: Write a failing test
2. **Green**: Write the minimum code to make the test pass
3. **Refactor**: Improve the code without changing behavior

### Key Benefits

- **Better Design**: Tests force you to think about API design upfront
- **Fewer Bugs**: Catch bugs early, when they're cheaper to fix
- **Living Documentation**: Tests serve as executable documentation
- **Confidence in Refactoring**: Change code with confidence
- **Faster Development**: Spend less time debugging

---

## The TDD Cycle

### Step-by-Step Process

```
┌─────────┐     ┌─────────┐     ┌──────────┐
│   RED   │────▶│  GREEN  │────▶│ REFACTOR │
│ (Test)  │     │ (Code)  │     │ (Clean)  │
└────┬────┘     └─────────┘     └────┬─────┘
     │                               │
     └───────────────────────────────┘
```

### Detailed Workflow

#### Phase 1: RED (Write a Failing Test)

```javascript
// 1. Write test that fails
describe('User service', () => {
    it('should create a user with valid data', () => {
        const userData = {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!'
        };

        const user = UserService.createUser(userData);

        expect(user).toBeDefined();
        expect(user.id).toBeDefined();
        expect(user.name).toBe('John Doe');
        expect(user.email).toBe('john@example.com');
        expect(user.password).not.toBe('SecurePass123!');  // Hashed
    });
});

// 2. Run test - IT FAILS (function doesn't exist)
// npm test
// FAIL  User service › should create a user
// ReferenceError: UserService is not defined
```

#### Phase 2: GREEN (Make Test Pass)

```javascript
// 1. Write minimum code to pass
class UserService {
    static createUser(userData) {
        return {
            id: 1,
            name: userData.name,
            email: userData.email,
            password: 'hashed_password'  // Fake hash
        };
    }
}

// 2. Run test - IT PASSES
// npm test
// PASS  User service › should create a user
```

#### Phase 3: REFACTOR (Improve Code)

```javascript
// 1. Improve code without changing behavior
class UserService {
    static createUser(userData) {
        const user = {
            id: this.generateId(),
            name: userData.name,
            email: userData.email.toLowerCase().trim(),
            password: this.hashPassword(userData.password)
        };

        this.validateUser(user);
        return user;
    }

    static generateId() {
        return Date.now() + Math.random();
    }

    static hashPassword(password) {
        // In real code, use bcrypt
        return `hashed_${password}`;
    }

    static validateUser(user) {
        if (!user.name || user.name.length < 2) {
            throw new Error('Name is required');
        }
        if (!this.isValidEmail(user.email)) {
            throw new Error('Invalid email');
        }
    }

    static isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
}

// 2. Run test - STILL PASSES (green after refactor)
// npm test
// PASS  User service › should create a user
```

---

## TDD Example: Complete Feature

### Feature: User Registration

#### Test 1: Create User

```javascript
describe('User Registration', () => {
    it('should create a user with valid data', () => {
        const userData = {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'SecurePass123!'
        };

        const user = UserService.register(userData);

        expect(user).toBeDefined();
        expect(user.id).toBeDefined();
        expect(user.name).toBe('John Doe');
        expect(user.email).toBe('john@example.com');
        expect(user.password).toBeDefined();
        expect(user.password).not.toBe('SecurePass123!');
    });
});
```

**Code:**
```javascript
class UserService {
    static register(userData) {
        return {
            id: Date.now(),
            name: userData.name,
            email: userData.email,
            password: `hashed_${userData.password}`
        };
    }
}
```

#### Test 2: Validate Required Fields

```javascript
it('should throw error when name is missing', () => {
    const userData = {
        email: 'john@example.com',
        password: 'SecurePass123!'
    };

    expect(() => {
        UserService.register(userData);
    }).toThrow('Name is required');
});

it('should throw error when email is missing', () => {
    const userData = {
        name: 'John Doe',
        password: 'SecurePass123!'
    };

    expect(() => {
        UserService.register(userData);
    }).toThrow('Email is required');
});
```

**Code:**
```javascript
class UserService {
    static register(userData) {
        if (!userData.name) {
            throw new Error('Name is required');
        }
        if (!userData.email) {
            throw new Error('Email is required');
        }

        return {
            id: Date.now(),
            name: userData.name,
            email: userData.email,
            password: `hashed_${userData.password}`
        };
    }
}
```

#### Test 3: Validate Email Format

```javascript
it('should throw error for invalid email format', () => {
    const invalidEmails = [
        'invalid',
        '@example.com',
        'john@',
        'john@example',
    ];

    invalidEmails.forEach(email => {
        expect(() => {
            UserService.register({
                name: 'John Doe',
                email,
                password: 'SecurePass123!'
            });
        }).toThrow('Invalid email format');
    });
});
```

**Code:**
```javascript
class UserService {
    static register(userData) {
        if (!userData.name) {
            throw new Error('Name is required');
        }
        if (!this.isValidEmail(userData.email)) {
            throw new Error('Invalid email format');
        }

        return {
            id: Date.now(),
            name: userData.name,
            email: userData.email,
            password: `hashed_${userData.password}`
        };
    }

    static isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
}
```

#### Test 4: Password Strength Validation

```javascript
it('should validate password strength', () => {
    const weakPasswords = [
        'short',
        'nouppercase',
        'NOLOWERCASE',
        'NoNumber123',
        'NoSpecialChar123',
    ];

    weakPasswords.forEach(password => {
        expect(() => {
            UserService.register({
                name: 'John Doe',
                email: 'john@example.com',
                password
            });
        }).toThrow('Password is too weak');
    });
});
```

**Code:**
```javascript
class UserService {
    static register(userData) {
        if (!userData.name) {
            throw new Error('Name is required');
        }
        if (!this.isValidEmail(userData.email)) {
            throw new Error('Invalid email format');
        }
        if (!this.isStrongPassword(userData.password)) {
            throw new Error('Password is too weak');
        }

        return {
            id: Date.now(),
            name: userData.name,
            email: userData.email,
            password: `hashed_${userData.password}`
        };
    }

    static isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    static isStrongPassword(password) {
        return (
            password.length >= 8 &&
            /[A-Z]/.test(password) &&
            /[a-z]/.test(password) &&
            /[0-9]/.test(password)
        );
    }
}
```

#### Test 5: Prevent Duplicate Email

```javascript
it('should throw error when email already exists', () => {
    const userData = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!'
    };

    // First user
    UserService.register(userData);

    // Second user with same email
    expect(() => {
        UserService.register({
            name: 'Jane Doe',
            email: 'john@example.com',
            password: 'AnotherPass123!'
        });
    }).toThrow('Email already exists');
});
```

**Code:**
```javascript
class UserService {
    static users = [];

    static register(userData) {
        if (!userData.name) {
            throw new Error('Name is required');
        }
        if (!this.isValidEmail(userData.email)) {
            throw new Error('Invalid email format');
        }
        if (!this.isStrongPassword(userData.password)) {
            throw new Error('Password is too weak');
        }
        if (this.emailExists(userData.email)) {
            throw new Error('Email already exists');
        }

        const user = {
            id: Date.now(),
            name: userData.name,
            email: userData.email,
            password: `hashed_${userData.password}`
        };

        this.users.push(user);
        return user;
    }

    static isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    static isStrongPassword(password) {
        return (
            password.length >= 8 &&
            /[A-Z]/.test(password);
    }

    static emailExists(email) {
        return this.users.some(user => user.email === email);
    }
}
```

---

## TDD Best Practices

### 1. Keep Tests Simple

```javascript
// ✅ Good - Simple, focused test
it('should calculate total price', () => {
    const cart = new Cart();
    cart.addItem(new Item('Book', 10));

    const total = cart.calculateTotal();

    expect(total).toBe(10);
});

// ❌ Bad - Complex, hard to understand
it('should do many things at once', () => {
    const cart = new Cart();
    cart.addItem(new Item('Book', 10));
    cart.addItem(new Item('Pen', 2));
    cart.applyDiscount(10);
    cart.applyTax(20);
    const total = cart.calculateTotal();
    const formatted = cart.formatPrice(total);
    const withCurrency = cart.addCurrency(formatted);
    expect(withCurrency).toBe('£12.00');
});
```

### 2. Write One Test per Behavior

```javascript
// ✅ Good - One test per behavior
it('should add item to cart');
it('should remove item from cart');
it('should calculate total');
it('should apply discount');
it('should apply tax');

// ❌ Bad - Multiple behaviors in one test
it('should add, remove, calculate total, apply discount and tax');
```

### 3. Use Descriptive Test Names

```javascript
// ✅ Good - Clear test name
it('should throw error when password is less than 8 characters', () => {
    expect(() => validatePassword('abc')).toThrow();
});

// ❌ Bad - Unclear test name
it('should work', () => { });
it('test password', () => { });
it('error case', () => { });
```

### 4. Test Edge Cases

```javascript
// Test normal case
it('should calculate discount for valid amount');
it('should calculate discount for maximum amount');

// Test edge cases
it('should handle zero amount');
it('should handle negative amount');
it('should handle decimal amount');
it('should handle very large amount');
it('should handle null/undefined input');
```

### 5. Don't Mock Everything

```javascript
// ✅ Good - Test real integration
it('should calculate total price with tax', () => {
    const calculator = new TaxCalculator();
    const result = calculator.calculate(100, 20);  // 100 + 20% tax
    expect(result).toBe(120);
});

// ❌ Bad - Over-mocking (testing nothing)
it('should call calculate method', () => {
    const calculator = new TaxCalculator();
    calculator.calculate = jest.fn().mockReturnValue(120);

    const result = calculator.calculate(100, 20);

    expect(calculator.calculate).toHaveBeenCalled();
    expect(result).toBe(120);  // Just testing the mock!
});
```

---

## TDD Anti-Patterns

### ❌ "The Liar" - Tests that pass but don't test anything

```javascript
// This test always passes
it('should calculate total', () => {
    const cart = new Cart();
    const total = cart.calculateTotal();

    expect(total).toBe(total);  // Always true!
});
```

**Fix:**
```javascript
it('should calculate total', () => {
    const cart = new Cart();
    cart.addItem(new Item('Book', 10));
    const total = cart.calculateTotal();

    expect(total).toBe(10);  // Specific expectation
});
```

### ❌ "The Giant" - Monolithic test doing too much

```javascript
it('should process entire order', () => {
    const order = createComplexOrder();
    const result = orderService.process(order);
    // 50+ lines of assertions
    expect(result.status).toBe('completed');
    expect(result.items[0].price).toBe(10);
    expect(result.items[1].price).toBe(20);
    // ... many more assertions
});
```

**Fix:**
```javascript
it('should validate order');
it('should calculate total');
it('should apply discounts');
it('should process payment');
it('should send confirmation email');
it('should update inventory');
```

### ❌ "The Mockery" - Over-mocking external dependencies

```javascript
it('should get user', () => {
    const mockRepo = mock(UserRepository);
    const mockCache = mock(Cache);
    const mockLogger = mock(Logger);
    const mockEventBus = mock(EventBus);

    when(mockRepo.findById(1)).thenReturn(user);
    when(mockCache.get('user:1')).thenReturn(cachedUser);
    when(mockLogger.info()).thenReturn(void 0);
    when(mockEventBus.publish()).thenReturn(void 0);

    const service = new UserService(mockRepo, mockCache, mockLogger, mockEventBus);
    const result = service.getUser(1);

    expect(result).toEqual(user);
});
```

**Fix:** Test with real dependencies where possible, or use fakes.

---

## TDD by Language

### JavaScript (Jest)

```javascript
// Red - Write failing test
describe('UserService', () => {
    it('should create user', () => {
        const user = UserService.create({ name: 'John' });
        expect(user.name).toBe('John');
    });
});

// Green - Make it pass
class UserService {
    static create(data) {
        return { name: data.name };
    }
}

// Refactor - Improve
class UserService {
    static create(data) {
        const user = { ...data };
        user.id = this.generateId();
        user.createdAt = new Date();
        return user;
    }

    static generateId() {
        return Date.now();
    }
}
```

### Python (PyTest)

```python
# Red - Write failing test
def test_create_user():
    user = UserService.create({"name": "John"})
    assert user["name"] == "John"

# Green - Make it pass
class UserService:
    @staticmethod
    def create(data):
        return {"name": data["name"]}

# Refactor - Improve
class UserService:
    @staticmethod
    def create(data):
        user = data.copy()
        user["id"] = UserService.generate_id()
        user["created_at"] = datetime.now()
        return user

    @staticmethod
    def generate_id():
        return int(time.time() * 1000)
```

### PHP (Pest)

```php
// Red - Write failing test
it('should create user', function () {
    $user = UserService::create(['name' => 'John']);
    expect($user->name)->toBe('John');
});

// Green - Make it pass
class UserService {
    public static function create(array $data): User {
        return new User($data['name']);
    }
}

// Refactor - Improve
class UserService {
    public static function create(array $data): User {
        $user = new User($data['name']);
        $user->id = self::generateId();
        $user->createdAt = new DateTime();
        return $user;
    }

    private static function generateId(): int {
        return time() * 1000;
    }
}
```

### Ruby (RSpec)

```ruby
# Red - Write failing test
it 'creates user' do
  user = UserService.create(name: 'John')
  expect(user.name).to eq('John')
end

# Green - Make it pass
class UserService
  def self.create(data)
    User.new(data[:name])
  end
end

# Refactor - Improve
class UserService
  def self.create(data)
    user = User.new(data[:name])
    user.id = generate_id
    user.created_at = Time.now
    user
  end

  def self.generate_id
    (Time.now.to_f * 1000).to_i
  end
end
```

---

## TDD Workflow Tips

### 1. Write the Simplest Test First

Start with the simplest test case, then add complexity incrementally.

### 2. Run Tests Frequently

Run tests after each small change. Don't wait until the end.

```bash
# Jest - Watch mode
npm test -- --watch

# PyTest - Watch mode
pytest -f

# Pest - Watch mode
./vendor/bin/pest --watch

# RSpec - Watch mode
rspec --watch
```

### 3. Don't Refactor Without Tests

Never refactor code that isn't covered by tests.

### 4. Keep Tests Fast

Tests should run in seconds, not minutes. If tests are slow, you'll avoid running them.

### 5. Use Code Coverage

Use coverage tools to identify untested code, but don't chase 100%.

```bash
# Jest
npm test -- --coverage

# PyTest
pytest --cov=src

# Pest
./vendor/bin/pest --coverage

# RSpec
rspec --format documentation --format RspecJunitFormatter --out results.xml
```

---

## Summary

TDD is a disciplined approach:
1. **Red** - Write failing test
2. **Green** - Make test pass (minimal code)
3. **Refactor** - Improve code

**Best Practices:**
- Keep tests simple and focused
- One test per behavior
- Descriptive test names
- Test edge cases
- Don't over-mock

**Avoid:**
- Liar tests (always pass)
- Giant tests (do too much)
- Mockery (over-mocked)

Use TDD to improve code quality, catch bugs early, and have confidence in refactoring.
