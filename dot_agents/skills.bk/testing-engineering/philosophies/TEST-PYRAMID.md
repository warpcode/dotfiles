# Test Pyramid

## Overview

Comprehensive guide to the test pyramid strategy for effective testing. The test pyramid emphasizes more low-level unit tests, fewer integration tests, and even fewer end-to-end tests, balancing speed, cost, and value.

## The Test Pyramid

```
                ▲
               /E2E\              (10%) - Slow, expensive, low value
              /------\
             /Integration\        (20-30%) - Medium speed, medium cost
            /------------\
           /   Unit Tests  \      (70-80%) - Fast, cheap, high value
          /----------------\
         /__________________\
```

### Test Layers Comparison

| Aspect | Unit Tests | Integration Tests | E2E Tests |
|--------|-----------|------------------|------------|
| **Execution Speed** | <100ms | <5s | >10s |
| **Cost** | Low | Medium | High |
| **Maintenance** | Low | Medium | High |
| **Isolation** | Yes | Partial | No |
| **Flakiness** | Rare | Occasional | Frequent |
| **Coverage Goal** | 80-90% | 40-60% | Critical paths |
| **Value** | High | Medium | Low |
| **Feedback Time** | Immediate | Minutes | Hours |

---

## Unit Tests (Bottom Layer)

### Definition

Tests that verify individual functions, classes, or modules in isolation.

### Characteristics

- **Fast**: Run in milliseconds
- **Isolated**: No external dependencies (DB, API, filesystem)
- **Numerous**: Majority of test suite
- **Focused**: Test single behavior
- **Deterministic**: Always same result

### What to Test

```javascript
// ✅ Good: Pure functions
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
}

// Test
it('should calculate total of items', () => {
    const items = [
        { name: 'Book', price: 10 },
        { name: 'Pen', price: 5 }
    ];
    expect(calculateTotal(items)).toBe(15);
});

// ✅ Good: Business logic
class ShoppingCart {
    addItem(item) {
        if (!item || !item.id) {
            throw new Error('Invalid item');
        }
        this.items.push(item);
    }
}

// Test
it('should throw error for invalid item', () => {
    const cart = new ShoppingCart();
    expect(() => cart.addItem(null)).toThrow('Invalid item');
});

// ❌ Bad: External dependencies (should be integration test)
it('should save user to database', async () => {
    const user = await User.save({ name: 'John' });  // DB call!
    expect(user.id).toBeDefined();
});
```

### Unit Test Examples

**JavaScript (Jest)**

```javascript
// Test pure function
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

    it('should handle negative prices', () => {
        const items = [
            { price: 10 },
            { price: -5 }  // Discount
        ];
        expect(calculateTotal(items)).toBe(5);
    });
});

// Test class method
describe('EmailValidator', () => {
    let validator;

    beforeEach(() => {
        validator = new EmailValidator();
    });

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
```

**Python (PyTest)**

```python
# Test pure function
def test_calculate_total():
    items = [
        {"price": 10},
        {"price": 20},
        {"price": 30}
    ]
    assert calculate_total(items) == 60

def test_calculate_total_empty():
    assert calculate_total([]) == 0

def test_calculate_total_negative():
    items = [
        {"price": 10},
        {"price": -5}
    ]
    assert calculate_total(items) == 5

# Test class method
class TestEmailValidator:
    def setup_method(self):
        self.validator = EmailValidator()

    def test_valid_email(self):
        assert self.validator.is_valid("john@example.com") == True

    def test_invalid_email_no_at(self):
        assert self.validator.is_valid("johnexample.com") == False

    def test_invalid_email_empty(self):
        assert self.validator.is_valid("") == False
```

**PHP (Pest)**

```php
// Test pure function
it('calculates total of items', function () {
    $items = [
        ['price' => 10],
        ['price' => 20],
        ['price' => 30]
    ];
    expect(calculateTotal($items))->toBe(60);
});

it('returns 0 for empty array', function () {
    expect(calculateTotal([]))->toBe(0);
});

// Test class method
describe('EmailValidator', function () {
    $validator;

    beforeEach(function () {
        $validator = new EmailValidator();
    });

    it('validates correct email', function () use (&$validator) {
        expect($validator->isValid('john@example.com'))->toBeTrue();
    });

    it('rejects invalid email', function () use (&$validator) {
        expect($validator->isValid('invalid'))->toBeFalse();
    });

    it('rejects empty email', function () use (&$validator) {
        expect($validator->isValid(''))->toBeFalse();
    });
});
```

---

## Integration Tests (Middle Layer)

### Definition

Tests that verify interactions between multiple components (services, APIs, database).

### Characteristics

- **Medium Speed**: Run in seconds
- **Partial Isolation**: May use real DB or external APIs (or test doubles)
- **Fewer**: ~20-30% of test suite
- **Broader Scope**: Test component interactions
- **Some Flakiness**: External dependencies can cause failures

### What to Test

```javascript
// ✅ Good: Component interactions
it('should create user and send welcome email', async () => {
    const userService = new UserService(
        userRepository,  // Real DB
        emailService     // Mocked
    );

    const user = await userService.create({
        name: 'John',
        email: 'john@example.com'
    });

    expect(user.id).toBeDefined();
    expect(userRepository.save).toHaveBeenCalled();
    expect(emailService.send).toHaveBeenCalledWith(
        'welcome',
        'john@example.com'
    );
});

// ✅ Good: API endpoints
it('should return user by ID', async () => {
    // Setup: Create test user in DB
    const user = await User.create({ name: 'John' });

    // Act: Call API
    const response = await supertest(app)
        .get(`/api/users/${user.id}`)
        .expect(200);

    // Assert
    expect(response.body.id).toBe(user.id);
    expect(response.body.name).toBe('John');
});

// ✅ Good: Database interactions
it('should save user to database', async () => {
    const user = await User.create({ name: 'John' });

    const found = await User.findById(user.id);
    expect(found.name).toBe('John');
});

// ❌ Bad: Too many external dependencies (should be E2E)
it('should complete full user journey', async () => {
    // This is doing too much - should be E2E
    await fillRegistrationForm();
    await submitForm();
    await checkEmail();
    await verifyEmail();
    await login();
    await viewDashboard();
});
```

### Integration Test Examples

**JavaScript (Jest + Supertest)**

```javascript
const request = require('supertest');
const app = require('./app');
const db = require('./db');

describe('User API Integration', () => {
    beforeAll(async () => {
        await db.connect();
    });

    afterAll(async () => {
        await db.disconnect();
    });

    beforeEach(async () => {
        await db.clear();  // Clean database
    });

    describe('POST /api/users', () => {
        it('should create a new user', async () => {
            const userData = {
                name: 'John Doe',
                email: 'john@example.com',
                password: 'SecurePass123!'
            };

            const response = await request(app)
                .post('/api/users')
                .send(userData)
                .expect(201);

            expect(response.body).toHaveProperty('id');
            expect(response.body.name).toBe('John Doe');
            expect(response.body.email).toBe('john@example.com');
            expect(response.body).not.toHaveProperty('password');  // Should not return password
        });

        it('should reject duplicate email', async () => {
            const userData = {
                name: 'John Doe',
                email: 'john@example.com',
                password: 'SecurePass123!'
            };

            // Create first user
            await request(app)
                .post('/api/users')
                .send(userData)
                .expect(201);

            // Try to create duplicate
            await request(app)
                .post('/api/users')
                .send(userData)
                .expect(409);  // Conflict
        });
    });

    describe('GET /api/users/:id', () => {
        it('should return user by ID', async () => {
            const user = await User.create({
                name: 'John Doe',
                email: 'john@example.com'
            });

            const response = await request(app)
                .get(`/api/users/${user.id}`)
                .expect(200);

            expect(response.body.id).toBe(user.id);
            expect(response.body.name).toBe('John Doe');
        });

        it('should return 404 for non-existent user', async () => {
            await request(app)
                .get('/api/users/999999')
                .expect(404);
        });
    });
});
```

**Python (PyTest + Flask)**

```python
import pytest
from app import create_app
from models import db, User

@pytest.fixture
def app():
    app = create_app('testing')
    with app.app_context():
        db.create_all()
        yield app
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

class TestUserAPI:
    def test_create_user(self, client):
        response = client.post('/api/users', json={
            'name': 'John Doe',
            'email': 'john@example.com',
            'password': 'SecurePass123!'
        })

        assert response.status_code == 201
        data = response.get_json()
        assert 'id' in data
        assert data['name'] == 'John Doe'
        assert data['email'] == 'john@example.com'
        assert 'password' not in data

    def test_duplicate_email(self, client):
        user_data = {
            'name': 'John Doe',
            'email': 'john@example.com',
            'password': 'SecurePass123!'
        }

        # First user
        response1 = client.post('/api/users', json=user_data)
        assert response1.status_code == 201

        # Duplicate
        response2 = client.post('/api/users', json=user_data)
        assert response2.status_code == 409

    def test_get_user(self, client):
        user = User(name='John Doe', email='john@example.com')
        db.session.add(user)
        db.session.commit()

        response = client.get(f'/api/users/{user.id}')
        assert response.status_code == 200
        data = response.get_json()
        assert data['id'] == user.id
        assert data['name'] == 'John Doe'
```

**PHP (Pest + Laravel)**

```php
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('creates a new user via API', function () {
    $userData = [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'SecurePass123!'
    ];

    $response = $this->postJson('/api/users', $userData);

    $response->assertStatus(201)
        ->assertJsonStructure(['id', 'name', 'email'])
        ->assertJsonMissing(['password'])
        ->assertJson([
            'name' => 'John Doe',
            'email' => 'john@example.com'
        ]);

    $this->assertDatabaseHas('users', [
        'name' => 'John Doe',
        'email' => 'john@example.com'
    ]);
});

it('rejects duplicate email', function () {
    $userData = [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'SecurePass123!'
    ];

    $this->postJson('/api/users', $userData)->assertStatus(201);

    $this->postJson('/api/users', $userData)->assertStatus(409);
});

it('returns user by ID', function () {
    $user = User::factory()->create([
        'name' => 'John Doe',
        'email' => 'john@example.com'
    ]);

    $response = $this->getJson("/api/users/{$user->id}");

    $response->assertStatus(200)
        ->assertJson([
            'id' => $user->id,
            'name' => 'John Doe',
            'email' => 'john@example.com'
        ]);
});
```

---

## End-to-End (E2E) Tests (Top Layer)

### Definition

Tests that verify complete user flows through the application UI.

### Characteristics

- **Slow**: Run in minutes to hours
- **No Isolation**: Full system (UI, DB, APIs, external services)
- **Fewest**: ~10% of test suite
- **Broad Scope**: Critical user journeys
- **Flaky**: Most prone to failures (network, timing, UI changes)

### What to Test

```javascript
// ✅ Good: Critical user journeys
it('should allow user to register and login', async () => {
    // Register
    await page.goto('/register');
    await page.fill('input[name="name"]', 'John Doe');
    await page.fill('input[name="email"]', 'john@example.com');
    await page.fill('input[name="password"]', 'SecurePass123!');
    await page.click('button[type="submit"]');

    // Verify email sent
    await expect(page).toHaveURL('/verify-email');

    // Verify email (simulate)
    await verifyEmail('john@example.com');

    // Login
    await page.goto('/login');
    await page.fill('input[name="email"]', 'john@example.com');
    await page.fill('input[name="password"]', 'SecurePass123!');
    await page.click('button[type="submit"]');

    // Verify logged in
    await expect(page).toHaveURL('/dashboard');
    await expect(page.locator('text=Welcome, John')).toBeVisible();
});

it('should allow user to purchase a product', async () => {
    // Browse product
    await page.goto('/products/laptop');
    await page.click('button:has-text("Add to Cart")');

    // View cart
    await page.goto('/cart');
    await expect(page.locator('.cart-items')).toContainText('Laptop');

    // Checkout
    await page.click('button:has-text("Checkout")');
    await page.fill('input[name="card"]', '4111111111111111');
    await page.click('button:has-text("Place Order")');

    // Verify order success
    await expect(page).toHaveURL('/order-success');
    await expect(page.locator('.order-number')).toBeVisible();
});

// ❌ Bad: Low-value scenarios
it('should have correct font size on homepage', async () => {
    await page.goto('/');
    const fontSize = await page.locator('h1').evaluate(el =>
        window.getComputedStyle(el).fontSize
    );
    expect(fontSize).toBe('32px');
});

// ❌ Bad: Internal implementation details (should be unit/integration test)
it('should make API call when clicking button', async () => {
    await page.goto('/');
    await page.click('button');

    // This is internal - should be integration test
    await expect(page).toHaveMadeRequest('/api/data');
});
```

### E2E Test Examples

**JavaScript (Playwright)**

```javascript
const { test, expect } = require('@playwright/test');

test.describe('User Registration Flow', () => {
    test('should complete registration and login', async ({ page }) => {
        // Register
        await page.goto('/register');
        await page.fill('input[name="name"]', 'John Doe');
        await page.fill('input[name="email"]', 'john@example.com');
        await page.fill('input[name="password"]', 'SecurePass123!');
        await page.fill('input[name="password_confirmation"]', 'SecurePass123!');
        await page.click('button[type="submit"]');

        // Verify redirect
        await expect(page).toHaveURL(/\/verify-email/);
        await expect(page.locator('text=Check your email')).toBeVisible();

        // Simulate email verification
        const user = await User.findOne({ email: 'john@example.com' });
        await page.goto(`/verify/${user.verificationToken}`);

        // Verify redirected to login
        await expect(page).toHaveURL('/login');
        await expect(page.locator('text=Email verified')).toBeVisible();

        // Login
        await page.fill('input[name="email"]', 'john@example.com');
        await page.fill('input[name="password"]', 'SecurePass123!');
        await page.click('button[type="submit"]');

        // Verify logged in
        await expect(page).toHaveURL('/dashboard');
        await expect(page.locator('text=Welcome, John Doe')).toBeVisible();
    });

    test('should show validation errors for invalid data', async ({ page }) => {
        await page.goto('/register');
        await page.click('button[type="submit"]');

        // Expect validation errors
        await expect(page.locator('text=Name is required')).toBeVisible();
        await expect(page.locator('text=Email is required')).toBeVisible();
        await expect(page.locator('text=Password is required')).toBeVisible();
    });
});

test.describe('E-commerce Checkout', () => {
    test('should complete purchase flow', async ({ page }) => {
        // Browse products
        await page.goto('/products');

        // Add to cart
        await page.click('.product:first-child button:has-text("Add to Cart")');

        // View cart
        await page.goto('/cart');
        await expect(page.locator('.cart-item')).toHaveCount(1);

        // Checkout
        await page.click('button:has-text("Proceed to Checkout")');
        await page.fill('input[name="shipping_address"]', '123 Main St');
        await page.fill('input[name="shipping_city"]', 'London');
        await page.click('button:has-text("Continue")');

        // Payment
        await page.fill('input[name="card_number"]', '4111111111111111');
        await page.fill('input[name="expiry"]', '12/25');
        await page.fill('input[name="cvv"]', '123');
        await page.click('button:has-text("Place Order")');

        // Verify order success
        await expect(page).toHaveURL(/\/order-success/);
        await expect(page.locator('.order-confirmation')).toBeVisible();

        // Verify cart is empty
        await page.goto('/cart');
        await expect(page.locator('.empty-cart')).toBeVisible();
    });
});
```

**JavaScript (Cypress)**

```javascript
describe('User Registration', () => {
    it('should complete registration flow', () => {
        // Visit registration page
        cy.visit('/register');

        // Fill form
        cy.get('input[name="name"]').type('John Doe');
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');
        cy.get('input[name="password_confirmation"]').type('SecurePass123!');

        // Submit form
        cy.get('button[type="submit"]').click();

        // Verify redirect
        cy.url().should('include', '/verify-email');
        cy.contains('Check your email').should('be.visible');

        // Verify email (simulate)
        cy.request('GET', '/api/users/email=john@example.com')
            .its('body')
            .then((user) => {
                cy.visit(`/verify/${user.verificationToken}`);
            });

        // Verify login page
        cy.url().should('include', '/login');
        cy.contains('Email verified').should('be.visible');

        // Login
        cy.get('input[name="email"]').type('john@example.com');
        cy.get('input[name="password"]').type('SecurePass123!');
        cy.get('button[type="submit"]').click();

        // Verify dashboard
        cy.url().should('include', '/dashboard');
        cy.contains('Welcome, John Doe').should('be.visible');
    });
});
```

**Python (Playwright)**

```python
from playwright.sync_api import Page, expect

def test_user_registration(page: Page):
    # Register
    page.goto('/register')
    page.fill('input[name="name"]', 'John Doe')
    page.fill('input[name="email"]', 'john@example.com')
    page.fill('input[name="password"]', 'SecurePass123!')
    page.fill('input[name="password_confirmation"]', 'SecurePass123!')
    page.click('button[type="submit"]')

    # Verify redirect
    expect(page).to_have_url(re.compile(r'/verify-email'))
    expect(page.locator('text=Check your email')).to_be_visible()

    # Verify email (simulate)
    user = db.users.find_one({'email': 'john@example.com'})
    page.goto(f'/verify/{user["verification_token"]}')

    # Verify login page
    expect(page).to_have_url('/login')
    expect(page.locator('text=Email verified')).to_be_visible()

    # Login
    page.fill('input[name="email"]', 'john@example.com')
    page.fill('input[name="password"]', 'SecurePass123!')
    page.click('button[type="submit"]')

    # Verify dashboard
    expect(page).to_have_url('/dashboard')
    expect(page.locator('text=Welcome, John Doe')).to_be_visible()
```

---

## Pyramid Strategy

### Ideal Test Distribution

- **70-80% Unit Tests**: Fast, isolated, comprehensive
- **20-30% Integration Tests**: Component interactions, API endpoints
- **10% E2E Tests**: Critical user journeys only

### When to Write Each Type

| Scenario | Test Type |
|----------|-----------|
| Complex business logic | Unit |
| Data transformation | Unit |
| Validation rules | Unit |
| API endpoint | Integration |
| Database queries | Integration |
| Email sending | Integration |
| Full user flow (register → login → dashboard) | E2E |
| Checkout process | E2E |

---

## Common Anti-Patterns

### ❌ "The Inverted Pyramid" - Too many E2E tests

```
         ▲
        /E2E\         (70%) - Slow, flaky, expensive
       /------\
      /Integr\        (20%)
     /--------\
    /   Unit   \      (10%)
   /------------\
```

**Fix:** Add more unit tests, reduce E2E tests.

### ❌ "The Hourglass" - Only integration tests

```
      ▲
     / \          (0%)
    /   \
   /Integr\      (100%)
  /--------\
 /          \
/            \
```

**Fix:** Add unit tests for business logic, reduce E2E tests.

### ❌ Testing Implementation Details

```javascript
// ❌ Bad - Testing internal implementation
it('should call saveUser method', () => {
    const spy = jest.spyOn(UserService, 'saveUser');
    const user = UserService.create({ name: 'John' });
    expect(spy).toHaveBeenCalled();
});

// ✅ Good - Testing behavior
it('should create user with valid data', () => {
    const user = UserService.create({ name: 'John' });
    expect(user.name).toBe('John');
    expect(user.id).toBeDefined();
});
```

### ❌ E2E Tests for Every Scenario

```javascript
// ❌ Bad - E2E test for simple validation
test('should show error when name is empty', async ({ page }) => {
    await page.goto('/register');
    await page.click('button[type="submit"]');
    await expect(page.locator('text=Name is required')).toBeVisible();
});

// ✅ Good - Unit test for validation
test('should throw error when name is empty', () => {
    expect(() => validateUser({})).toThrow('Name is required');
});
```

---

## Summary

The test pyramid emphasizes:
- **70-80% Unit Tests**: Fast, isolated, high value
- **20-30% Integration Tests**: Component interactions, APIs
- **10% E2E Tests**: Critical user journeys only

**Best Practices:**
- Write unit tests for business logic
- Write integration tests for APIs and DB
- Write E2E tests for critical flows only
- Test behavior, not implementation
- Keep E2E tests focused and stable

**Anti-Patterns to Avoid:**
- Inverted pyramid (too many E2E tests)
- Hourglass shape (only integration tests)
- E2E tests for every scenario
- Testing internal implementation

Use the pyramid strategy for balanced, efficient testing.
