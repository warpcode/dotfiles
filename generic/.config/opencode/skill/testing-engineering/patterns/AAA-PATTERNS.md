# AAA Patterns (Arrange-Act-Assert)

## Overview

Comprehensive guide to the AAA (Arrange-Act-Assert) test pattern. AAA is a fundamental pattern for structuring tests to ensure clarity, maintainability, and readability.

## The AAA Pattern

### Structure

```
┌─────────────────────────────────┐
│         ARRANGE              │  Setup: Prepare test data,  │
│  (Given, Setup, Prepare)   │  mocks, and initial state    │
├─────────────────────────────────┤
│           ACT               │  Action: Execute code       │
│     (When, Execute, Run)     │  under test               │
├─────────────────────────────────┤
│          ASSERT              │  Verify: Check results      │
│  (Then, Verify, Expect)       │  against expected values   │
└─────────────────────────────────┘
```

### Concept

- **Arrange**: Set up the test (create objects, set variables, configure mocks)
- **Act**: Execute the code being tested
- **Assert**: Verify the result matches expectations

---

## Basic Examples

### JavaScript (Jest)

```javascript
describe('Calculator', () => {
    it('should add two numbers', () => {
        // ARRANGE
        const calculator = new Calculator();
        const a = 5;
        const b = 3;

        // ACT
        const result = calculator.add(a, b);

        // ASSERT
        expect(result).toBe(8);
    });

    it('should throw error for negative numbers', () => {
        // ARRANGE
        const calculator = new Calculator();
        const negativeNumber = -5;

        // ACT & ASSERT
        expect(() => calculator.sqrt(negativeNumber)).toThrow();
    });

    it('should calculate total with discount', () => {
        // ARRANGE
        const cart = new ShoppingCart();
        cart.addItem(new Item('Laptop', 1000));
        cart.addItem(new Item('Mouse', 50));
        const discount = 0.1;  // 10%

        // ACT
        const total = cart.calculateTotalWithDiscount(discount);

        // ASSERT
        expect(total).toBe(945);  // (1000 + 50) * 0.9
    });
});
```

### Python (PyTest)

```python
def test_add_two_numbers():
    # ARRANGE
    calculator = Calculator()
    a = 5
    b = 3

    # ACT
    result = calculator.add(a, b)

    # ASSERT
    assert result == 8

def test_divide_by_zero():
    # ARRANGE
    calculator = Calculator()
    divisor = 0

    # ACT & ASSERT
    with pytest.raises(ZeroDivisionError):
        calculator.divide(10, divisor)

def test_calculate_total_with_discount():
    # ARRANGE
    cart = ShoppingCart()
    cart.add_item(Item('Laptop', 1000))
    cart.add_item(Item('Mouse', 50))
    discount = 0.1

    # ACT
    total = cart.calculate_total_with_discount(discount)

    # ASSERT
    assert total == 945
```

### PHP (Pest)

```php
it('adds two numbers', function () {
    // ARRANGE
    $calculator = new Calculator();
    $a = 5;
    $b = 3;

    // ACT
    $result = $calculator->add($a, $b);

    // ASSERT
    expect($result)->toBe(8);
});

it('throws error for division by zero', function () {
    // ARRANGE
    $calculator = new Calculator();
    $divisor = 0;

    // ACT & ASSERT
    expect(fn() => $calculator->divide(10, $divisor))
        ->toThrow(DivisionByZeroException::class);
});

it('calculates total with discount', function () {
    // ARRANGE
    $cart = new ShoppingCart();
    $cart->addItem(new Item('Laptop', 1000));
    $cart->addItem(new Item('Mouse', 50));
    $discount = 0.1;

    // ACT
    $total = $cart->calculateTotalWithDiscount($discount);

    // ASSERT
    expect($total)->toBe(945);
});
```

### Ruby (RSpec)

```ruby
describe Calculator do
  it 'adds two numbers' do
    # ARRANGE
    calculator = Calculator.new
    a = 5
    b = 3

    # ACT
    result = calculator.add(a, b)

    # ASSERT
    expect(result).to eq(8)
  end

  it 'raises error for division by zero' do
    # ARRANGE
    calculator = Calculator.new
    divisor = 0

    # ACT & ASSERT
    expect {
      calculator.divide(10, divisor)
    }.to raise_error(ZeroDivisionError)
  end
end
```

### Go

```go
func TestAdd(t *testing.T) {
    // ARRANGE
    calculator := NewCalculator()
    a := 5
    b := 3
    expected := 8

    // ACT
    result := calculator.Add(a, b)

    // ASSERT
    if result != expected {
        t.Errorf("Add(%d, %d) = %d; want %d", a, b, result, expected)
    }
}

func TestDivideByZero(t *testing.T) {
    // ARRANGE
    calculator := NewCalculator()

    // ACT & ASSERT
    err := calculator.Divide(10, 0)
    if err == nil {
        t.Error("Expected error for division by zero")
    }
}
```

---

## AAA with Async Operations

### JavaScript (Jest)

```javascript
describe('UserService', () => {
    it('should fetch user by ID', async () => {
        // ARRANGE
        const userId = 123;
        const mockUser = { id: 123, name: 'John Doe' };
        UserRepository.findById.mockResolvedValue(mockUser);

        // ACT
        const user = await UserService.findById(userId);

        // ASSERT
        expect(user).toEqual(mockUser);
        expect(UserRepository.findById).toHaveBeenCalledWith(userId);
    });

    it('should throw error if user not found', async () => {
        // ARRANGE
        const userId = 999;
        UserRepository.findById.mockResolvedValue(null);

        // ACT & ASSERT
        await expect(UserService.findById(userId))
            .rejects.toThrow('User not found');
    });
});
```

### Python (PyTest)

```python
@pytest.mark.asyncio
async def test_fetch_user_by_id():
    # ARRANGE
    user_id = 123
    mock_user = {'id': 123, 'name': 'John Doe'}
    user_repository.find_by_id.return_value = mock_user

    # ACT
    user = await user_service.find_by_id(user_id)

    # ASSERT
    assert user == mock_user
    user_repository.find_by_id.assert_called_once_with(user_id)

@pytest.mark.asyncio
async def test_fetch_user_not_found():
    # ARRANGE
    user_id = 999
    user_repository.find_by_id.return_value = None

    # ACT & ASSERT
    with pytest.raises(UserNotFoundError):
        await user_service.find_by_id(user_id)
```

---

## AAA with Mocks

### JavaScript (Jest)

```javascript
describe('EmailService', () => {
    beforeEach(() => {
        // ARRANGE (reset mocks)
        jest.clearAllMocks();
    });

    it('should send welcome email after user registration', async () => {
        // ARRANGE
        const user = { name: 'John', email: 'john@example.com' };
        EmailService.send.mockResolvedValue({ success: true });

        // ACT
        await UserService.register(user);

        // ASSERT
        expect(EmailService.send).toHaveBeenCalledWith({
            to: 'john@example.com',
            template: 'welcome',
            data: { name: 'John' }
        });
        expect(EmailService.send).toHaveBeenCalledTimes(1);
    });
});
```

### Python (PyTest)

```python
def test_send_welcome_email():
    # ARRANGE
    user = {'name': 'John', 'email': 'john@example.com'}
    email_service.send.return_value = {'success': True}

    # ACT
    user_service.register(user)

    # ASSERT
    email_service.send.assert_called_once_with(
        to='john@example.com',
        template='welcome',
        data={'name': 'John'}
    )
```

---

## AAA Patterns by Scenario

### Happy Path (Success)

```javascript
it('should successfully create order', () => {
    // ARRANGE
    const orderData = {
        userId: 1,
        items: [{ productId: 1, quantity: 2 }],
        paymentMethod: 'credit_card'
    };
    const expectedOrder = { id: 123, ...orderData };
    OrderRepository.create.mockResolvedValue(expectedOrder);

    // ACT
    const order = await OrderService.create(orderData);

    // ASSERT
    expect(order).toEqual(expectedOrder);
});
```

### Error Path (Exception)

```javascript
it('should throw error for invalid email', () => {
    // ARRANGE
    const email = 'invalid-email';

    // ACT & ASSERT
    expect(() => EmailValidator.validate(email))
        .toThrow('Invalid email format');
});
```

### Edge Case (Boundary)

```javascript
it('should handle maximum cart items', () => {
    // ARRANGE
    const cart = new ShoppingCart({ maxItems: 100 });
    const items = Array(100).fill(null).map((_, i) => ({
        id: i,
        price: 10
    }));

    // ACT
    items.forEach(item => cart.addItem(item));

    // ASSERT
    expect(cart.itemCount).toBe(100);
});

it('should throw error when exceeding maximum items', () => {
    // ARRANGE
    const cart = new ShoppingCart({ maxItems: 100 });
    const items = Array(101).fill(null).map((_, i) => ({
        id: i,
        price: 10
    }));

    // ACT & ASSERT
    expect(() => items.forEach(item => cart.addItem(item)))
        .toThrow('Maximum items exceeded');
});
```

---

## AAA Best Practices

### 1. Clear Separation

**Good:** Clear comments marking each phase
```javascript
it('should calculate discount', () => {
    // ARRANGE
    const price = 100;
    const discount = 0.1;

    // ACT
    const finalPrice = calculateDiscount(price, discount);

    // ASSERT
    expect(finalPrice).toBe(90);
});
```

**Bad:** Mixed phases
```javascript
it('should calculate discount', () => {
    const price = 100;
    const result = calculateDiscount(price, 0.1);  // Arrange and Act mixed
    expect(result).toBe(90);
});
```

### 2. One Assertion Per Test

**Good:** Single, focused assertion
```javascript
it('should calculate total', () => {
    const cart = new ShoppingCart();
    cart.addItem(new Item('Book', 10));
    const total = cart.calculateTotal();
    expect(total).toBe(10);
});

it('should update item count', () => {
    const cart = new ShoppingCart();
    cart.addItem(new Item('Book', 10));
    expect(cart.itemCount).toBe(1);
});
```

**Bad:** Multiple assertions
```javascript
it('should handle adding item', () => {
    const cart = new ShoppingCart();
    cart.addItem(new Item('Book', 10));
    expect(cart.calculateTotal()).toBe(10);  // Too many assertions
    expect(cart.itemCount).toBe(1);       // Different behaviors
    expect(cart.items).toHaveLength(1);     // Should be separate tests
});
```

### 3. Descriptive Test Names

**Good:** Clear test name
```javascript
it('should calculate discount for premium users', () => {
    // ...
});

it('should throw error for expired coupon', () => {
    // ...
});
```

**Bad:** Unclear test name
```javascript
it('should work', () => {
    // ...
});

it('test discount', () => {
    // ...
});

it('error case', () => {
    // ...
});
```

### 4. Use Test Builders for Complex Setup

**Good:** Test builder pattern
```javascript
// Test builder
class UserBuilder {
    constructor() {
        this.user = {
            name: 'John Doe',
            email: 'john@example.com',
            role: 'user',
            active: true
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

    build() {
        return this.user;
    }
}

// Test
it('should not allow inactive users to login', () => {
    // ARRANGE
    const user = new UserBuilder()
        .inactive()
        .build();

    // ACT & ASSERT
    expect(() => AuthService.login(user))
        .toThrow('User is inactive');
});
```

### 5. Use Constants for Test Data

**Good:** Reusable test data
```javascript
const TEST_USERS = {
    active: {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        active: true
    },
    inactive: {
        id: 2,
        name: 'Jane Doe',
        email: 'jane@example.com',
        active: false
    }
};

it('should allow active users to login', () => {
    // ARRANGE
    const user = TEST_USERS.active;

    // ACT
    const session = AuthService.login(user);

    // ASSERT
    expect(session).toBeDefined();
});
```

---

## AAA Anti-Patterns

### ❌ "The All-in-One" - No Clear Separation

```javascript
// Bad - Mixed phases, no comments
it('should calculate discount', function () {
    expect(calculateDiscount(100, 0.1)).toBe(90);
});

// Good - Clear phases
it('should calculate discount', function () {
    // ARRANGE
    const price = 100;
    const discount = 0.1;

    // ACT
    const result = calculateDiscount(price, discount);

    // ASSERT
    expect(result).toBe(90);
});
```

### ❌ "The Setup Overload" - Too Much Arrangement

```javascript
// Bad - Too much setup code
it('should process order', () => {
    // ARRANGE (50+ lines of setup)
    const user = new User({ name: 'John', email: 'john@example.com', ... });
    const products = [new Product(...), new Product(...), new Product(...)];
    const cart = new ShoppingCart({ user, ... });
    products.forEach(p => cart.addItem(p));
    cart.applyDiscount(new Coupon(...));
    cart.applyTax(...);
    const shipping = new Shipping({ ... });
    const payment = new Payment({ ... });

    // ACT
    const order = cart.checkout(payment, shipping);

    // ASSERT
    expect(order.total).toBe(expected);
});

// Good - Extracted to helper
function createTestOrder() {
    return {
        user: createTestUser(),
        cart: createTestCart(),
        payment: createTestPayment(),
        shipping: createTestShipping()
    };
}

it('should process order', () => {
    // ARRANGE
    const orderData = createTestOrder();

    // ACT
    const order = OrderService.process(orderData);

    // ASSERT
    expect(order.total).toBe(expected);
});
```

### ❌ "The Empty Assert" - No Verification

```javascript
// Bad - No assertion
it('should create user', () => {
    // ARRANGE
    const userData = { name: 'John', email: 'john@example.com' };

    // ACT
    const user = UserService.create(userData);

    // ASSERT - No verification!
});

// Good - Proper assertion
it('should create user', () => {
    // ARRANGE
    const userData = { name: 'John', email: 'john@example.com' };

    // ACT
    const user = UserService.create(userData);

    // ASSERT
    expect(user).toBeDefined();
    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
});
```

### ❌ "The Assertion Overload" - Too Many Assertions

```javascript
// Bad - Too many assertions
it('should create user', () => {
    const user = UserService.create({ name: 'John' });

    expect(user).toBeDefined();            // Assertion 1
    expect(user.id).toBeDefined();        // Assertion 2
    expect(user.name).toBe('John');     // Assertion 3
    expect(user.email).toBe('john@example.com');  // Assertion 4
    expect(user.role).toBe('user');     // Assertion 5
    expect(user.active).toBe(true);      // Assertion 6
    expect(user.createdAt).toBeDefined();  // Assertion 7
    // ... many more assertions
});

// Good - Focus on critical assertions
it('should create user with valid data', () => {
    const user = UserService.create({ name: 'John' });

    expect(user.id).toBeDefined();
    expect(user.name).toBe('John');
});
```

---

## AAA Variations

### Given-When-Then (Gherkin Style)

```gherkin
# Feature file
Feature: User Registration

  Scenario: User registers with valid data
    Given I have valid user registration data
    When I submit the registration form
    Then I should see a success message
    And I should receive a confirmation email
```

```javascript
// Step definitions
Given('I have valid user registration data', () => {
    this.userData = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!'
    };
});

When('I submit the registration form', async () => {
    await this.page.goto('/register');
    await this.page.fill('input[name="name"]', this.userData.name);
    await this.page.fill('input[name="email"]', this.userData.email);
    await this.page.fill('input[name="password"]', this.userData.password);
    await this.page.click('button[type="submit"]');
});

Then('I should see a success message', async () => {
    await expect(this.page.locator('text=Registration successful')).toBeVisible();
});
```

---

## Summary

AAA pattern ensures clean, readable tests:

**Structure:**
- **Arrange**: Setup test data, mocks, initial state
- **Act**: Execute code under test
- **Assert**: Verify results

**Best Practices:**
- Clear separation with comments
- One assertion per test
- Descriptive test names
- Use test builders for complex setup
- Use constants for test data

**Anti-Patterns to Avoid:**
- Mixed phases (no separation)
- Setup overload (too much arrangement)
- Empty assert (no verification)
- Assertion overload (too many checks)

Use AAA to make tests readable, maintainable, and focused.
