# Integration Testing

## Overview

Comprehensive guide to integration testing. Integration tests verify interactions between multiple components (services, APIs, database) without mocking external dependencies.

---

## Integration Testing Fundamentals

### What is an Integration Test?

A test that verifies how multiple components work together (e.g., API + Database + Email Service).

### Characteristics

- **Multiple Components**: Tests interactions between 2+ components
- **Real Dependencies**: Uses real DB, APIs (or test doubles)
- **Medium Speed**: Runs in seconds
- **Partial Isolation**: May use some test doubles
- **Broader Scope**: Component interactions, not single functions

### Unit vs Integration vs E2E

| Aspect | Unit Tests | Integration Tests | E2E Tests |
|--------|-----------|------------------|------------|
| **Scope** | Single function/class | Multiple components | Full system |
| **Dependencies** | Mocked/Faked | Real or test doubles | Real system |
| **Speed** | <100ms | <5s | >10s |
| **Isolation** | Yes | Partial | No |
| **Purpose** | Logic correctness | Component interactions | User flows |

---

## When to Write Integration Tests

### Good Candidates

✅ **API endpoints** (controller + service + DB)
```javascript
// Test full request/response cycle
app.get('/api/users/:id', async (req, res) => {
    const user = await UserService.findById(req.params.id);
    res.json(user);
});
```

✅ **Database operations** (service + repository + DB)
```javascript
// Test with real DB
async function createUser(userData) {
    return await UserRepository.save(userData);
}
```

✅ **Service interactions** (service A + service B)
```javascript
// Test service calling another service
async function processOrder(order) {
    const user = await UserService.findById(order.userId);
    const email = await EmailService.sendConfirmation(user);
    return { orderId: order.id, emailSent: email.success };
}
```

✅ **External API integrations** (service + external API + test double)
```javascript
// Test with mock/stub of external API
async function processPayment(paymentData) {
    const result = await StripeAPI.charge(paymentData);
    return { success: result.paid, transactionId: result.id };
}
```

### Poor Candidates

❌ **Pure functions** (should be unit tests)
```javascript
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.price, 0);
}
```

❌ **Single component** (should be unit tests)
```javascript
class EmailValidator {
    isValid(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }
}
```

---

## Integration Testing Patterns

### API Endpoint Testing

**JavaScript (Jest + Supertest):**
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
        it('should create user and save to database', async () => {
            const userData = {
                name: 'John Doe',
                email: 'john@example.com',
                password: 'SecurePass123!'
            };

            const response = await request(app)
                .post('/api/users')
                .send(userData)
                .expect(201);

            // Verify response
            expect(response.body).toHaveProperty('id');
            expect(response.body.name).toBe('John Doe');
            expect(response.body.email).toBe('john@example.com');
            expect(response.body).not.toHaveProperty('password');

            // Verify database
            const user = await User.findById(response.body.id);
            expect(user.name).toBe('John Doe');
            expect(user.email).toBe('john@example.com');
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
                .send({ ...userData, name: 'Jane Doe' })
                .expect(409);  // Conflict
        });

        it('should validate required fields', async () => {
            const response = await request(app)
                .post('/api/users')
                .send({ name: 'John Doe' })  // Missing email, password
                .expect(400);

            expect(response.body.errors).toHaveProperty('email');
            expect(response.body.errors).toHaveProperty('password');
        });
    });

    describe('GET /api/users/:id', () => {
        it('should return user by ID', async () => {
            // Create user in DB
            const createdUser = await User.create({
                name: 'John Doe',
                email: 'john@example.com'
            });

            const response = await request(app)
                .get(`/api/users/${createdUser.id}`)
                .expect(200);

            expect(response.body.id).toBe(createdUser.id);
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

**Python (PyTest + Flask):**
```python
import pytest
from app import create_app, db
from models import User

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

        # Verify database
        user = User.query.get(data['id'])
        assert user is not None
        assert user.name == 'John Doe'

    def test_duplicate_email(self, client):
        user_data = {
            'name': 'John Doe',
            'email': 'john@example.com',
            'password': 'SecurePass123!'
        }

        # Create first user
        client.post('/api/users', json=user_data)
        assert response1.status_code == 201

        # Try to create duplicate
        response2 = client.post('/api/users', json={
            **user_data,
            'name': 'Jane Doe'
        })
        assert response2.status_code == 409  # Conflict
```

**PHP (Pest + Laravel):**
```php
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('creates user via API', function () {
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

    // Try duplicate
    $this->postJson('/api/users', [
        ...$userData,
        'name' => 'Jane Doe'
    ])->assertStatus(409);
});
```

### Database Integration Testing

**JavaScript (Jest + Real DB):**
```javascript
describe('UserRepository Integration', () => {
    beforeAll(async () => {
        await db.connect();
    });

    afterAll(async () => {
        await db.disconnect();
    });

    beforeEach(async () => {
        await db.clear();
    });

    it('should save and retrieve user', async () => {
        const userData = {
            name: 'John Doe',
            email: 'john@example.com',
            password: 'hashed_password'
        };

        // Save
        const saved = await UserRepository.save(userData);
        expect(saved.id).toBeDefined();
        expect(saved.name).toBe('John Doe');

        // Retrieve
        const found = await UserRepository.findById(saved.id);
        expect(found).toEqual(saved);
    });

    it('should find user by email', async () => {
        await UserRepository.save({
            name: 'John Doe',
            email: 'john@example.com',
            password: 'hashed_password'
        });

        const user = await UserRepository.findByEmail('john@example.com');
        expect(user).toBeDefined();
        expect(user.email).toBe('john@example.com');
    });

    it('should update user', async () => {
        const user = await UserRepository.save({
            name: 'John Doe',
            email: 'john@example.com'
        });

        user.name = 'Jane Doe';
        const updated = await UserRepository.update(user.id, user);

        expect(updated.name).toBe('Jane Doe');

        const found = await UserRepository.findById(user.id);
        expect(found.name).toBe('Jane Doe');
    });

    it('should delete user', async () => {
        const user = await UserRepository.save({
            name: 'John Doe',
            email: 'john@example.com'
        });

        await UserRepository.delete(user.id);

        const found = await UserRepository.findById(user.id);
        expect(found).toBeNull();
    });
});
```

### Service Integration Testing

**JavaScript (Jest):**
```javascript
describe('OrderService Integration', () => {
    let orderService;
    let mockPaymentService;
    let mockEmailService;

    beforeEach(() => {
        // Use real repositories (DB)
        const userRepository = new UserRepository();
        const productRepository = new ProductRepository();

        // Mock external services
        mockPaymentService = {
            charge: jest.fn().mockResolvedValue({ success: true, transactionId: 'txn_123' })
        };
        mockEmailService = {
            sendConfirmation: jest.fn().mockResolvedValue({ success: true })
        };

        orderService = new OrderService(
            userRepository,
            productRepository,
            mockPaymentService,
            mockEmailService
        );
    });

    it('should process order end-to-end', async () => {
        const user = await UserRepository.save({
            name: 'John Doe',
            email: 'john@example.com'
        });

        const product = await ProductRepository.save({
            name: 'Laptop',
            price: 1000,
            stock: 10
        });

        const orderData = {
            userId: user.id,
            items: [
                { productId: product.id, quantity: 1 }
            ],
            paymentMethod: 'credit_card'
        };

        const order = await orderService.process(orderData);

        // Verify order created
        expect(order.id).toBeDefined();
        expect(order.status).toBe('completed');
        expect(order.total).toBe(1000);

        // Verify payment charged
        expect(mockPaymentService.charge).toHaveBeenCalledWith({
            amount: 1000,
            method: 'credit_card'
        });

        // Verify email sent
        expect(mockEmailService.sendConfirmation).toHaveBeenCalledWith(
            'john@example.com',
            order.id
        );

        // Verify database
        const savedOrder = await OrderRepository.findById(order.id);
        expect(savedOrder).toEqual(order);

        const savedItems = await OrderItemRepository.findByOrderId(order.id);
        expect(savedItems).toHaveLength(1);
    });

    it('should handle payment failure', async () => {
        mockPaymentService.charge.mockResolvedValue({
            success: false,
            error: 'Payment declined'
        });

        const user = await UserRepository.save({
            name: 'John Doe',
            email: 'john@example.com'
        });

        const product = await ProductRepository.save({
            name: 'Laptop',
            price: 1000,
            stock: 10
        });

        const orderData = {
            userId: user.id,
            items: [
                { productId: product.id, quantity: 1 }
            ],
            paymentMethod: 'credit_card'
        };

        await expect(
            orderService.process(orderData)
        ).rejects.toThrow('Payment declined');

        // Verify order not saved
        const savedOrder = await OrderRepository.findByUserId(user.id);
        expect(savedOrder).toBeNull();
    });
});
```

---

## Integration Testing Best Practices

### 1. Use Test Database

**Good:** Isolated test database
```javascript
beforeAll(async () => {
    await db.connect('test_database');
});

afterEach(async () => {
    await db.clear();  // Clean between tests
});
```

### 2. Reset State Between Tests

**Good:** Clean state
```javascript
beforeEach(async () => {
    await db.clear();
    await redis.flushall();
    await mockReset();
});
```

### 3. Test Real Interactions

**Good:** Use real DB for data persistence
```javascript
it('should save user to database', async () => {
    const user = await UserService.create({ name: 'John' });
    const found = await UserRepository.findById(user.id);
    expect(found).toEqual(user);
});
```

### 4. Mock Only External Dependencies

**Good:** Mock external APIs, use real DB
```javascript
const mockStripeAPI = {
    charge: jest.fn().mockResolvedValue({ success: true })
};

it('should process payment with real order data', async () => {
    const order = await orderService.process(
        orderData,
        mockStripeAPI  // Mock external service
    );

    expect(order.status).toBe('completed');
});
```

### 5. Test Error Scenarios

**Good:** Test integration failures
```javascript
it('should handle database connection error', async () => {
    mockDbConnection('error');

    await expect(
        UserService.create({ name: 'John' })
    ).rejects.toThrow('Database connection failed');
});
```

---

## Integration Testing Anti-Patterns

### ❌ "The Unit Test in Disguise" - All Dependencies Mocked

```javascript
// Bad - Everything mocked (unit test)
it('should create user', () => {
    const mockDb = jest.fn().mockResolvedValue(user);
    const mockEmail = jest.fn().mockResolvedValue({ success: true });

    const service = new UserService(mockDb, mockEmail);

    const result = await service.create(userData);

    expect(mockDb).toHaveBeenCalled();  // Testing mocks!
    expect(mockEmail).toHaveBeenCalled();
});
```

**Fix:** Use real DB for integration tests.

```javascript
// Good - Real DB, only external services mocked
it('should create user in database', async () => {
    const mockEmail = jest.fn().mockResolvedValue({ success: true });
    const realDb = new Database();  // Real DB connection

    const service = new UserService(realDb, mockEmail);

    const result = await service.create(userData);

    // Verify real DB state
    const found = await UserRepository.findById(result.id);
    expect(found).toEqual(result);
});
```

### ❌ "The E2E Test" - Full User Flow

```javascript
// Bad - Too many components (should be E2E)
it('should complete full purchase journey', async () => {
    // Register
    await authService.register(userData);
    await emailService.verifyEmail(userData.email);
    await authService.login(userData.email, userData.password);

    // Browse
    const products = await productService.getAll();
    const product = products[0];

    // Add to cart
    await cartService.addItem(product.id, 1);

    // Checkout
    const order = await orderService.create({ userId: user.id, items: cart.items });

    // Payment
    await paymentService.charge(order.total);

    // Verify all steps...
    // This is doing too much!
});
```

**Fix:** Break into focused integration tests.

```javascript
// Good - Focused integration
it('should save order to database', async () => {
    const order = await orderService.create(orderData);
    const found = await OrderRepository.findById(order.id);
    expect(found).toEqual(order);
});
```

### ❌ "The Flaky Test" - Depends on External APIs

```javascript
// Bad - Depends on real external API
it('should call Stripe API', async () => {
    // Real Stripe API - will flake!
    const result = await stripe.charges.create({
        amount: 1000,
        currency: 'gbp'
    });

    expect(result.status).toBe('succeeded');
});
```

**Fix:** Mock external APIs.

```javascript
// Good - Mock external API
it('should handle Stripe payment response', async () => {
    const mockStripe = {
        charges: {
            create: jest.fn().mockResolvedValue({
                id: 'ch_123',
                status: 'succeeded'
            })
        }
    };

    const result = await paymentService.charge(1000, mockStripe);
    expect(result.transactionId).toBe('ch_123');
});
```

---

## Integration Testing Checklist

### Setup Checklist

- [ ] Test database configured (isolated from production)
- [ ] Database migrations run before tests
- [ ] Database cleaned between tests
- [ ] External services mocked (Stripe, SendGrid, etc.)
- [ ] Environment variables set (test environment)

### Test Case Checklist

For each integration test:

- [ ] **Request**: Valid input data
- [ ] **Response**: Correct status code and data
- [ ] **Database**: Data persisted correctly
- [ ] **Side Effects**: Emails sent, cache updated, etc.
- [ ] **Error Cases**: Invalid input, duplicate data, etc.
- [ ] **Cleanup**: Database state restored

---

## Summary

Integration testing verifies component interactions:

**Characteristics:**
- Multiple components (service + DB + external API)
- Real dependencies (or test doubles)
- Medium speed (<5s)
- Partial isolation

**Good Candidates:**
- API endpoints (controller + service + DB)
- Database operations (service + repository + DB)
- Service interactions (service A + service B)
- External API integrations (service + mock API)

**Poor Candidates:**
- Pure functions (unit tests)
- Single component (unit tests)

**Best Practices:**
- Use test database
- Reset state between tests
- Test real interactions
- Mock only external dependencies
- Test error scenarios

**Anti-Patterns:**
- All dependencies mocked (unit test in disguise)
- Full user flows (E2E test)
- Depends on external APIs (flaky)

Use integration tests to verify components work together correctly.
