# Test Doubles

## Overview

Comprehensive guide to test doubles (mocks, stubs, fakes, spies, dummies). Test doubles replace dependencies during testing to isolate code under test.

---

## What Are Test Doubles?

### Definition

**Test Double**: Object that stands in for a real dependency in a test (like a stunt double in movies).

### Types of Test Doubles

```
┌─────────────────────────────────────────────┐
│           TEST DOUBLES                   │
├─────────────────────────────────────────────┤
│  Dummy      - No implementation          │
│  Stub       - Pre-programmed responses    │
│  Spy        - Records method calls       │
│  Fake       - Working implementation     │
│  Mock       - Expectations verification  │
└─────────────────────────────────────────────┘
```

| Type | Purpose | Verifies | Example |
|------|----------|-----------|----------|
| **Dummy** | Fill parameter slots | None | Null object, empty interface |
| **Stub** | Provide test data | Output | Repository that returns static data |
| **Spy** | Record interactions | Calls | Logger that records calls |
| **Fake** | Working in-memory implementation | None | In-memory database |
| **Mock** | Verify interactions | Calls/Params | API client that verifies calls |

---

## Dummy Objects

### Definition

Objects that are passed around but never actually used. They fill parameter slots.

### When to Use

- When a method requires a parameter you don't use
- When you need to satisfy type requirements
- When the object is never accessed

### Examples

**JavaScript:**
```javascript
// Dummy - Not used in test
const dummyLogger = { log: () => {} };

function processOrder(order, logger) {
    // Logger parameter required but not used in this function
    return { id: 1, status: 'processed' };
}

it('should process order', () => {
    const order = { items: [{ id: 1, quantity: 2 }] };
    const result = processOrder(order, dummyLogger);

    expect(result.status).toBe('processed');
});
```

**Python:**
```python
# Dummy - Not used in test
class DummyLogger:
    def log(self, message):
        pass

def process_order(order, logger):
    # Logger parameter required but not used
    return {'id': 1, 'status': 'processed'}

def test_process_order():
    order = {'items': [{'id': 1, 'quantity': 2}]}
    result = process_order(order, DummyLogger())
    assert result['status'] == 'processed'
```

**PHP:**
```php
// Dummy - Not used in test
class DummyLogger implements LoggerInterface
{
    public function log($message)
    {
        // No implementation
    }
}

class OrderProcessor
{
    public function process(Order $order, LoggerInterface $logger)
    {
        return ['id' => 1, 'status' => 'processed'];
    }
}

it('should process order', function () {
    $processor = new OrderProcessor();
    $order = new Order(['items' => [['id' => 1, 'quantity' => 2]]]);

    $result = $processor->process($order, new DummyLogger());

    expect($result['status'])->toBe('processed');
});
```

---

## Stub Objects

### Definition

Objects that provide pre-programmed responses to method calls.

### When to Use

- When you need to control what a dependency returns
- When testing error handling scenarios
- When avoiding external dependencies (DB, API)

### Examples

**JavaScript:**
```javascript
// Stub - Pre-programmed responses
class UserRepositoryStub {
    constructor(users) {
        this.users = users;
    }

    findById(id) {
        return this.users.find(u => u.id === id) || null;
    }

    save(user) {
        user.id = Date.now();
        this.users.push(user);
        return user;
    }
}

it('should find user by ID', () => {
    // Stub with test data
    const stubRepo = new UserRepositoryStub([
        { id: 1, name: 'John Doe' },
        { id: 2, name: 'Jane Doe' }
    ]);

    const user = stubRepo.findById(1);

    expect(user).toEqual({ id: 1, name: 'John Doe' });
});

it('should return null for non-existent user', () => {
    const stubRepo = new UserRepositoryStub([]);
    const user = stubRepo.findById(999);

    expect(user).toBeNull();
});
```

**Python:**
```python
# Stub - Pre-programmed responses
class UserRepositoryStub:
    def __init__(self, users=None):
        self.users = users or []

    def find_by_id(self, user_id):
        for user in self.users:
            if user['id'] == user_id:
                return user
        return None

    def save(self, user):
        user['id'] = int(time.time())
        self.users.append(user)
        return user

def test_find_user_by_id():
    stub_repo = UserRepositoryStub([
        {'id': 1, 'name': 'John Doe'},
        {'id': 2, 'name': 'Jane Doe'}
    ])

    user = stub_repo.find_by_id(1)

    assert user == {'id': 1, 'name': 'John Doe'}

def test_nonexistent_user():
    stub_repo = UserRepositoryStub([])
    user = stub_repo.find_by_id(999)

    assert user is None
```

**PHP:**
```php
// Stub - Pre-programmed responses
class UserRepositoryStub implements UserRepositoryInterface
{
    private $users = [];

    public function __construct(array $users = [])
    {
        $this->users = $users;
    }

    public function findById(int $id): ?User
    {
        foreach ($this->users as $user) {
            if ($user->getId() === $id) {
                return $user;
            }
        }
        return null;
    }

    public function save(User $user): User
    {
        $user->setId(time());
        $this->users[] = $user;
        return $user;
    }
}

it('should find user by ID', function () {
    $stubRepo = new UserRepositoryStub([
        new User(1, 'John Doe'),
        new User(2, 'Jane Doe')
    ]);

    $user = $stubRepo->findById(1);

    expect($user->getId())->toBe(1);
    expect($user->getName())->toBe('John Doe');
});
```

---

## Spy Objects

### Definition

Objects that record method calls (parameters, call count, order) for later verification.

### When to Use

- When you need to verify interactions
- When testing event logging
- When checking callback invocation

### Examples

**JavaScript:**
```javascript
// Spy - Records method calls
class LoggerSpy {
    constructor() {
        this.logs = [];
    }

    log(message) {
        this.logs.push({
            message,
            timestamp: new Date()
        });
    }

    getLogs() {
        return this.logs;
    }

    getCallCount() {
        return this.logs.length;
    }

    wasCalledWith(message) {
        return this.logs.some(log => log.message === message);
    }
}

it('should log order processing', () => {
    const loggerSpy = new LoggerSpy();
    const processor = new OrderProcessor(loggerSpy);

    processor.process({ id: 1, items: [] });

    expect(loggerSpy.getCallCount()).toBe(1);
    expect(loggerSpy.wasCalledWith('Order 1 processed')).toBe(true);
});

it('should log errors when processing fails', () => {
    const loggerSpy = new LoggerSpy();
    const processor = new OrderProcessor(loggerSpy);

    processor.process({ id: 1, items: null });

    expect(loggerSpy.getCallCount()).toBe(1);
    expect(loggerSpy.wasCalledWith('Error: Invalid items')).toBe(true);
});
```

**Python:**
```python
# Spy - Records method calls
class LoggerSpy:
    def __init__(self):
        self.logs = []

    def log(self, message):
        self.logs.append({
            'message': message,
            'timestamp': datetime.now()
        })

    def get_logs(self):
        return self.logs

    def call_count(self):
        return len(self.logs)

    def was_called_with(self, message):
        return any(log['message'] == message for log in self.logs)

def test_log_order_processing():
    spy = LoggerSpy()
    processor = OrderProcessor(spy)

    processor.process({'id': 1, 'items': []})

    assert spy.call_count() == 1
    assert spy.was_called_with('Order 1 processed')

def test_log_errors():
    spy = LoggerSpy()
    processor = OrderProcessor(spy)

    processor.process({'id': 1, 'items': None})

    assert spy.call_count() == 1
    assert spy.was_called_with('Error: Invalid items')
```

---

## Fake Objects

### Definition

Working implementations that are simplified for testing (e.g., in-memory database).

### When to Use

- When you need working but simplified behavior
- When mocking would be too complex
- When you want deterministic behavior without external dependencies

### Examples

**JavaScript:**
```javascript
// Fake - Working in-memory implementation
class InMemoryUserRepository {
    constructor() {
        this.users = [];
        this.nextId = 1;
    }

    async findById(id) {
        return this.users.find(u => u.id === id) || null;
    }

    async save(user) {
        if (user.id) {
            // Update existing
            const index = this.users.findIndex(u => u.id === user.id);
            if (index !== -1) {
                this.users[index] = user;
            }
        } else {
            // Create new
            user.id = this.nextId++;
            user.createdAt = new Date();
            this.users.push(user);
        }
        return user;
    }

    async findByEmail(email) {
        return this.users.find(u => u.email === email) || null;
    }

    async delete(id) {
        this.users = this.users.filter(u => u.id !== id);
    }
}

// Using fake in tests
it('should create and find user', async () => {
    const fakeRepo = new InMemoryUserRepository();
    const service = new UserService(fakeRepo);

    // Create user
    const user = await service.create({
        name: 'John Doe',
        email: 'john@example.com'
    });

    expect(user.id).toBeDefined();
    expect(user.name).toBe('John Doe');

    // Find user
    const found = await fakeRepo.findById(user.id);
    expect(found).toEqual(user);
});

it('should prevent duplicate emails', async () => {
    const fakeRepo = new InMemoryUserRepository();
    const service = new UserService(fakeRepo);

    // Create first user
    await service.create({
        name: 'John Doe',
        email: 'john@example.com'
    });

    // Try to create duplicate
    await expect(
        service.create({
            name: 'Jane Doe',
            email: 'john@example.com'
        })
    ).rejects.toThrow('Email already exists');
});
```

**Python:**
```python
# Fake - Working in-memory implementation
class InMemoryUserRepository:
    def __init__(self):
        self.users = []
        self.next_id = 1

    async def find_by_id(self, user_id):
        for user in self.users:
            if user['id'] == user_id:
                return user
        return None

    async def save(self, user):
        if 'id' in user and user['id']:
            # Update existing
            for i, u in enumerate(self.users):
                if u['id'] == user['id']:
                    self.users[i] = user
                    break
        else:
            # Create new
            user['id'] = self.next_id
            self.next_id += 1
            user['created_at'] = datetime.now()
            self.users.append(user)
        return user

    async def find_by_email(self, email):
        for user in self.users:
            if user['email'] == email:
                return user
        return None

# Using fake in tests
async def test_create_and_find_user():
    fake_repo = InMemoryUserRepository()
    service = UserService(fake_repo)

    # Create user
    user = await service.create({
        'name': 'John Doe',
        'email': 'john@example.com'
    })

    assert user['id'] is not None
    assert user['name'] == 'John Doe'

    # Find user
    found = await fake_repo.find_by_id(user['id'])
    assert found == user

async def test_prevent_duplicate_emails():
    fake_repo = InMemoryUserRepository()
    service = UserService(fake_repo)

    # Create first user
    await service.create({
        'name': 'John Doe',
        'email': 'john@example.com'
    })

    # Try to create duplicate
    with pytest.raises(EmailAlreadyExistsError):
        await service.create({
            'name': 'Jane Doe',
            'email': 'john@example.com'
        })
```

---

## Mock Objects

### Definition

Objects with pre-programmed expectations (method calls, parameters, call count) that are verified.

### When to Use

- When you need to verify interactions
- When testing message passing
- When expecting specific method calls with specific parameters

### Examples

**JavaScript (Jest):**
```javascript
// Mock - Verifies interactions
describe('UserService', () => {
    it('should send welcome email after registration', async () => {
        // Create mock
        const mockEmailService = {
            sendWelcomeEmail: jest.fn().mockResolvedValue({ success: true })
        };

        const service = new UserService(mockEmailService);

        // Act
        await service.register({
            name: 'John Doe',
            email: 'john@example.com'
        });

        // Assert - Verify interaction
        expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledTimes(1);
        expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledWith(
            'john@example.com',
            'John Doe'
        );
    });
});
```

**Python (unittest.mock):**
```python
# Mock - Verifies interactions
def test_send_welcome_email():
    with patch('services.EmailService') as mock_email_service:
        # Configure mock
        mock_email_service.send_welcome_email.return_value = {'success': True}

        # Act
        service = UserService(mock_email_service)
        service.register({
            'name': 'John Doe',
            'email': 'john@example.com'
        })

        # Assert - Verify interaction
        mock_email_service.send_welcome_email.assert_called_once_with(
            'john@example.com',
            'John Doe'
        )
```

**PHP (PHPUnit):**
```php
// Mock - Verifies interactions
class UserServiceTest extends TestCase
{
    public function testSendWelcomeEmail()
    {
        // Create mock
        $mockEmailService = $this->createMock(EmailService::class);

        // Configure expectations
        $mockEmailService
            ->expects($this->once())
            ->method('sendWelcomeEmail')
            ->with('john@example.com', 'John Doe')
            ->willReturn(['success' => true]);

        // Act
        $service = new UserService($mockEmailService);
        $service->register([
            'name' => 'John Doe',
            'email' => 'john@example.com'
        ]);
    }
}
```

---

## Choosing the Right Test Double

### Decision Tree

```
Need to replace dependency?
│
├─ Object never used? → DUMMY
├─ Need to control return values? → STUB
├─ Need to verify interactions? → SPY or MOCK
│  ├─ Spy = Record calls, verify later
│  └─ Mock = Pre-set expectations
├─ Need working behavior? → FAKE
└─ Complex interaction verification? → MOCK
```

### When to Use Each

| Scenario | Use |
|----------|------|
| Filling parameter slots, never accessed | Dummy |
| Controlling return values for testing | Stub |
| Recording method calls for verification | Spy |
| Working in-memory implementation | Fake |
| Verifying method calls and parameters | Mock |

---

## Test Double Best Practices

### 1. Prefer Fakes Over Mocks

**Good:** Use fake when reasonable
```javascript
it('should calculate total', () => {
    const fakeRepo = new InMemoryCartRepository();
    const calculator = new CartCalculator(fakeRepo);

    // Use real fake implementation
    const total = calculator.calculate(1);
    expect(total).toBe(100);
});
```

**Avoid:** Over-mocking
```javascript
it('should calculate total', () => {
    const mockRepo = {
        findById: jest.fn().mockReturnValue({ items: [{ price: 100 }] })
    };
    const calculator = new CartCalculator(mockRepo);

    const total = calculator.calculate(1);
    expect(total).toBe(100);
    expect(mockRepo.findById).toHaveBeenCalled();  // Unnecessary verification
});
```

### 2. Don't Over-Verify Interactions

**Good:** Verify only important interactions
```javascript
it('should send order confirmation', () => {
    const mockEmailService = createMockEmailService();

    orderService.process(order);

    // Verify only critical interaction
    expect(mockEmailService.sendConfirmation).toHaveBeenCalledWith(
        order.user.email,
        order.id
    );
});
```

**Avoid:** Verifying every interaction
```javascript
it('should send order confirmation', () => {
    const mockEmailService = createMockEmailService();
    const mockInventoryService = createMockInventoryService();
    const mockPaymentService = createMockPaymentService();

    orderService.process(order);

    // Too many verifications
    expect(mockEmailService.sendConfirmation).toHaveBeenCalled();
    expect(mockInventoryService.check).toHaveBeenCalled();
    expect(mockPaymentService.charge).toHaveBeenCalled();
});
```

### 3. Keep Test Doubles Simple

**Good:** Simple stub
```javascript
const stubRepo = {
    findById: (id) => testUsers.find(u => u.id === id)
};
```

**Avoid:** Complex stub
```javascript
const stubRepo = {
    findById: (id) => {
        if (id < 100) return testUsers[0];
        if (id < 200) return testUsers[1];
        if (id < 300) return testUsers[2];
        // ... too much logic in stub
    }
};
```

### 4. Use Factory Functions for Test Data

**Good:** Test data factory
```javascript
function createTestUser(overrides = {}) {
    return {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        active: true,
        ...overrides
    };
}

it('should process user', () => {
    const user = createTestUser({ role: 'admin' });
    const result = processUser(user);
    expect(result.hasAccess).toBe(true);
});
```

---

## Common Mistakes

### ❌ Confusing Mock with Stub

```javascript
// Bad - Using mock when stub is sufficient
const mockRepo = jest.fn();
mockRepo.findById.mockReturnValue(user);
mockRepo.findById.mockReturnValue(otherUser);

const result = myFunction(mockRepo);
expect(mockRepo.findById).toHaveBeenCalled();  // Unnecessary!

// Good - Use stub (just need return values)
const stubRepo = {
    findById: (id) => (id === 1 ? user : otherUser)
};

const result = myFunction(stubRepo);
expect(result).toEqual(expected);
```

### ❌ Using Fake When Mock is Needed

```javascript
// Bad - Using fake when interaction verification is needed
const fakeRepo = new InMemoryUserRepository();

const service = new UserService(fakeRepo);
await service.register({ name: 'John', email: 'john@example.com' });

// Can't easily verify if email was sent!
// Fake doesn't record interactions

// Good - Use mock for interaction verification
const mockEmailService = jest.fn();
const fakeRepo = new InMemoryUserRepository();

const service = new UserService(fakeRepo, mockEmailService);
await service.register({ name: 'John', email: 'john@example.com' });

expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalled();
```

### ❌ Test Double Does Too Much

```javascript
// Bad - Test double has complex logic
class ComplexStubRepository {
    async findById(id) {
        // 50+ lines of complex logic
        if (id === 1) return this.users[0];
        if (id === 2) return this.users[1];
        // ... lots of conditional logic
        // Should just return static data!
    }
}

// Good - Simple stub
class SimpleStubRepository {
    async findById(id) {
        return this.testData[id] || null;
    }
}
```

---

## Summary

Test doubles replace dependencies during testing:

**Types:**
- **Dummy**: Fills parameter slots, never used
- **Stub**: Pre-programmed responses
- **Spy**: Records method calls
- **Fake**: Working in-memory implementation
- **Mock**: Verifies interactions and expectations

**When to Use:**
- Dummy: Parameter slots, not used
- Stub: Control return values
- Spy: Record interactions
- Fake: Working behavior needed
- Mock: Verify interactions

**Best Practices:**
- Prefer fakes over mocks
- Don't over-verify interactions
- Keep test doubles simple
- Use test data factories

Choose the right test double for the testing scenario.
