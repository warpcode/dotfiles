# Framework Patterns

## Overview

Comprehensive guide to common testing framework patterns across languages. Framework patterns include setup, teardown, fixtures, parametrized tests, and test organization.

---

## Common Test Patterns

### 1. Setup/Teardown Pattern

**Purpose:** Run code before/after tests to set up/clean state.

**JavaScript (Jest):**
```javascript
describe('UserService', () => {
    let userService;
    let mockDb;

    // Setup - Runs once before all tests in describe block
    beforeAll(async () => {
        mockDb = createMockDatabase();
        await mockDb.connect();
        userService = new UserService(mockDb);
    });

    // Teardown - Runs once after all tests in describe block
    afterAll(async () => {
        await mockDb.disconnect();
    });

    // Setup - Runs before each test
    beforeEach(() => {
        mockDb.clear();  // Clean database before each test
        jest.clearAllMocks();  // Clear mocks
    });

    // Teardown - Runs after each test
    afterEach(() => {
        mockDb.clear();  // Clean database after each test
    });

    it('should create user', () => {
        const user = userService.create({ name: 'John' });
        expect(user.id).toBeDefined();
    });

    it('should find user', () => {
        const user = userService.create({ name: 'Jane' });
        const found = userService.findById(user.id);
        expect(found).toEqual(user);
    });
});
```

**Python (PyTest):**
```python
import pytest

class TestUserService:
    # Setup - Runs before all tests in class
    @classmethod
    def setup_class(cls):
        cls.mock_db = create_mock_database()
        cls.mock_db.connect()
        cls.service = UserService(cls.mock_db)

    # Teardown - Runs after all tests in class
    @classmethod
    def teardown_class(cls):
        cls.mock_db.disconnect()

    # Setup - Runs before each test
    def setup_method(self):
        self.mock_db.clear()  # Clean database before each test

    # Teardown - Runs after each test
    def teardown_method(self):
        self.mock_db.clear()  # Clean database after each test

    def test_create_user(self):
        user = self.service.create({'name': 'John'})
        assert user['id'] is not None

    def test_find_user(self):
        user = self.service.create({'name': 'Jane'})
        found = self.service.find_by_id(user['id'])
        assert found == user
```

**PHP (Pest):**
```php
use App\Services\UserService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

describe('UserService', function () {
    $service;
    $mockDb;

    // Setup - Runs before all tests in describe block
    beforeAll(function () use (&$mockDb, &$service) {
        $mockDb = createMockDatabase();
        $mockDb->connect();
        $service = new UserService($mockDb);
    });

    // Teardown - Runs after all tests in describe block
    afterAll(function () use (&$mockDb) {
        $mockDb->disconnect();
    });

    // Setup - Runs before each test
    beforeEach(function () use (&$mockDb) {
        $mockDb->clear();  // Clean database
    });

    // Teardown - Runs after each test
    afterEach(function () use (&$mockDb) {
        $mockDb->clear();  // Clean database
    });

    it('creates user', function () use (&$service) {
        $user = $service->create(['name' => 'John']);
        expect($user->id)->toBeDefined();
    });

    it('finds user', function () use (&$service) {
        $user = $service->create(['name' => 'Jane']);
        $found = $service->findById($user->id);
        expect($found)->toEqual($user);
    });
});
```

---

### 2. Fixture Pattern

**Purpose:** Reusable test data and setup.

**JavaScript (Jest):**
```javascript
// Test fixtures - fixtures/users.js
export const TEST_USERS = {
    active: {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user',
        active: true
    },
    admin: {
        id: 2,
        name: 'Jane Admin',
        email: 'jane@example.com',
        role: 'admin',
        active: true
    },
    inactive: {
        id: 3,
        name: 'Bob Inactive',
        email: 'bob@example.com',
        role: 'user',
        active: false
    }
};

// Using fixtures in tests
import { TEST_USERS } from '../fixtures/users';

describe('UserService', () => {
    it('should allow active user to login', () => {
        const user = TEST_USERS.active;
        const result = authService.login(user.email, 'password');
        expect(result.success).toBe(true);
    });

    it('should not allow inactive user to login', () => {
        const user = TEST_USERS.inactive;
        const result = authService.login(user.email, 'password');
        expect(result.success).toBe(false);
    });
});
```

**Python (PyTest):**
```python
# conftest.py - Shared fixtures for all tests
import pytest

@pytest.fixture
def test_user():
    """Return a test user"""
    return {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'user',
        'active': True
    }

@pytest.fixture
def admin_user():
    """Return an admin user"""
    return {
        'id': 2,
        'name': 'Jane Admin',
        'email': 'jane@example.com',
        'role': 'admin',
        'active': True
    }

# Using fixtures in tests
def test_regular_user_login(test_user):
    """Test with regular user fixture"""
    result = auth_service.login(test_user['email'], 'password')
    assert result['success'] == True

def test_admin_user_access(admin_user):
    """Test with admin user fixture"""
    result = user_service.access(admin_user['id'])
    assert result['has_access'] == True
```

**PHP (Pest):**
```php
// TestCase - Create base test class
use App\Models\User;

class UserTestCase extends TestCase
{
    protected function createTestUser(array $overrides = []): User
    {
        return User::factory()->create(array_merge([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'hashed_password',
            'role' => 'user',
            'active' => true
        ], $overrides));
    }

    protected function createAdminUser(array $overrides = []): User
    {
        return User::factory()->create(array_merge([
            'name' => 'Jane Admin',
            'email' => 'jane@example.com',
            'password' => 'hashed_password',
            'role' => 'admin',
            'active' => true
        ], $overrides));
    }
}

// Using fixtures in tests
it('should allow regular user to login', function () {
    $user = $this->createTestUser();
    $result = AuthService::login($user->email, 'password');
    expect($result['success'])->toBeTrue();
});

it('should allow admin to access admin panel', function () {
    $admin = $this->createAdminUser();
    $result = UserService::adminAccess($admin->id);
    expect($result['has_access'])->toBeTrue();
});
```

---

### 3. Parametrized Tests Pattern

**Purpose:** Run same test with multiple inputs.

**JavaScript (Jest):**
```javascript
describe.each([
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9]
])('should calculate total correctly (%i, %i, %i)', (a, b, c) => {
    it(`should sum ${a}, ${b}, and ${c}`, () => {
        expect(calculateTotal(a, b, c)).toBe(a + b + c);
    });
});

describe.each([
    { input: 'test@test.com', valid: true },
    { input: 'invalid-email', valid: false },
    { input: '', valid: false },
])('should validate email: $input', ({ input, valid }) => {
    it(`should return ${valid ? 'valid' : 'invalid'} for ${input}`, () => {
        expect(isValidEmail(input)).toBe(valid);
    });
});
```

**Python (PyTest):**
```python
import pytest

@pytest.mark.parametrize('a,b,c,expected', [
    (1, 2, 3, 6),
    (4, 5, 6, 15),
    (7, 8, 9, 24)
])
def test_calculate_total(a, b, c, expected):
    """Test calculateTotal with multiple inputs"""
    result = calculate_total(a, b, c)
    assert result == expected

@pytest.mark.parametrize('email,valid', [
    ('test@test.com', True),
    ('invalid-email', False),
    ('', False),
])
def test_validate_email(email, valid):
    """Test email validation with multiple inputs"""
    result = is_valid_email(email)
    assert result == valid
```

**PHP (Pest):**
```php
test('should calculate total', function (int $a, int $b, int $c, int $expected) {
    expect(calculateTotal($a, $b, $c))->toBe($expected);
})->with([1, 2, 3, 6]);
//->with([4, 5, 6, 15]);
//->with([7, 8, 9, 24]);

test('should validate email', function (string $email, bool $valid) {
    expect(isValidEmail($email))->toBe($valid);
})->with(['test@test.com', true]);
//->with(['invalid-email', false]);
//->with(['', false]);
```

---

### 4. Test Organization Pattern

**Purpose:** Group related tests together.

**JavaScript (Jest):**
```javascript
describe('Calculator', () => {
    // Nested describe for grouping
    describe('Addition', () => {
        it('should add two positive numbers', () => {
            expect(add(2, 3)).toBe(5);
        });

        it('should add positive and negative numbers', () => {
            expect(add(2, -3)).toBe(-1);
        });
    });

    describe('Subtraction', () => {
        it('should subtract two positive numbers', () => {
            expect(subtract(5, 3)).toBe(2);
        });

        it('should handle negative results', () => {
            expect(subtract(3, 5)).toBe(-2);
        });
    });

    describe('Edge Cases', () => {
        it('should handle zero', () => {
            expect(add(0, 5)).toBe(5);
        });

        it('should handle large numbers', () => {
            expect(add(1000000, 1000000)).toBe(2000000);
        });
    });
});
```

**Python (PyTest):**
```python
class TestCalculator:
    # Grouped as test classes

    class TestAddition:
        def test_add_positive_numbers(self):
            assert add(2, 3) == 5

        def test_add_positive_negative(self):
            assert add(2, -3) == -1

    class TestSubtraction:
        def test_subtract_positive_numbers(self):
            assert subtract(5, 3) == 2

        def test_subtract_negative_result(self):
            assert subtract(3, 5) == -2

    class TestEdgeCases:
        def test_add_zero(self):
            assert add(0, 5) == 5

        def test_add_large_numbers(self):
            assert add(1000000, 1000000) == 2000000
```

**Ruby (RSpec):**
```ruby
RSpec.describe Calculator do
  describe '#add' do
    it 'adds two positive numbers' do
      expect(described_class.add(2, 3)).to eq(5)
    end

    it 'adds positive and negative numbers' do
      expect(described_class.add(2, -3)).to eq(-1)
    end
  end

  describe '#subtract' do
    it 'subtracts two positive numbers' do
      expect(described_class.subtract(5, 3)).to eq(2)
    end

    it 'handles negative results' do
      expect(described_class.subtract(3, 5)).to eq(-2)
    end
  end

  describe 'Edge Cases' do
    it 'handles zero' do
      expect(described_class.add(0, 5)).to eq(5)
    end

    it 'handles large numbers' do
      expect(described_class.add(1000000, 1000000)).to eq(2000000)
    end
  end
end
```

---

### 5. Test Helper Pattern

**Purpose:** Extract common test logic into reusable helpers.

**JavaScript (Jest):**
```javascript
// Test helper - testHelpers.js
export function createMockDatabase() {
    const db = {
        data: [],
        connect() {
            return Promise.resolve();
        },
        disconnect() {
            this.data = [];
            return Promise.resolve();
        },
        clear() {
            this.data = [];
        },
        save(record) {
            record.id = this.data.length + 1;
            record.createdAt = new Date();
            this.data.push(record);
            return Promise.resolve(record);
        },
        findById(id) {
            return Promise.resolve(this.data.find(r => r.id === id) || null);
        }
    };
    return db;
}

export function createMockEmailService() {
    const emails = [];
    return {
        send(to, subject, data) {
            emails.push({ to, subject, data });
            return Promise.resolve({ success: true });
        },
        getSentEmails() {
            return emails;
        },
        clear() {
            emails.length = 0;
        }
    };
}

// Using test helpers
import { createMockDatabase, createMockEmailService } from './testHelpers';

describe('UserService', () => {
    let mockDb;
    let mockEmailService;

    beforeEach(() => {
        mockDb = createMockDatabase();
        mockEmailService = createMockEmailService();
    });

    it('should create user and send welcome email', async () => {
        const service = new UserService(mockDb, mockEmailService);

        const user = await service.create({
            name: 'John Doe',
            email: 'john@example.com'
        });

        expect(mockEmailService.getSentEmails()).toHaveLength(1);
        expect(mockEmailService.getSentEmails()[0].to).toBe('john@example.com');
    });
});
```

**Python (PyTest):**
```python
# conftest.py - Shared fixtures and helpers
import pytest

@pytest.fixture
def mock_db():
    """Mock database fixture"""
    class MockDatabase:
        def __init__(self):
            self.data = []

        async def connect(self):
            return

        async def disconnect(self):
            self.data = []

        def clear(self):
            self.data = []

        async def save(self, record):
            record['id'] = len(self.data) + 1
            record['created_at'] = datetime.now()
            self.data.append(record)
            return record

        async def find_by_id(self, user_id):
            for record in self.data:
                if record['id'] == user_id:
                    return record
            return None

    db = MockDatabase()
    yield db
    # Teardown
    db.clear()

# Using mock_db fixture
async def test_create_user(mock_db):
    """Test create user with mock database"""
    service = UserService(mock_db)

    user = await service.create({
        'name': 'John Doe',
        'email': 'john@example.com'
    })

    assert user['id'] is not None
```

---

### 6. Custom Matchers Pattern

**Purpose:** Create reusable assertion helpers.

**JavaScript (Jest):**
```javascript
// Custom matcher - matchers/toBeValidEmail.js
expect.extend({
    toBeValidEmail(received) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const pass = emailRegex.test(received);
        return {
            pass,
            message: pass
                ? `expected ${received} to be valid email`
                : `expected ${received} to be valid email, but it isn't`
        };
    }
});

// Using custom matcher
describe('EmailValidator', () => {
    it('should validate correct email', () => {
        expect('john@example.com').toBeValidEmail();
    });

    it('should reject invalid email', () => {
        expect('invalid-email').not.toBeValidEmail();
    });
});
```

**Python (PyTest):**
```python
# conftest.py - Custom fixtures
import pytest

@pytest.fixture
def assert_valid_user():
    """Custom assertion for valid user"""
    def _assert(user):
        assert user is not None
        assert user['id'] is not None
        assert user['name'] is not None
        assert user['email'] is not None
        assert user['email'] is not None
    return _assert

# Using custom assertion fixture
def test_create_valid_user(assert_valid_user):
    """Test with custom assertion"""
    user = create_user({'name': 'John Doe'})
    assert_valid_user(user)  # Custom assertion
```

**PHP (Pest):**
```php
// Custom matcher
beforeEach(function () {
    expect()->extend([
        'toBeValidUser' => function ($user) {
            return $this->not->toBeNull()
                ->and->toHaveProperty('id')
                ->and->toHaveProperty('name')
                ->and->toHaveProperty('email');
        }
    ]);
});

// Using custom matcher
it('should create valid user', function () {
    $user = UserService::create(['name' => 'John Doe']);
    expect($user)->toBeValidUser();
});
```

---

### 7. Test Factories Pattern

**Purpose:** Create test data programmatically.

**JavaScript:**
```javascript
// Test factory - factories/UserFactory.js
export class UserFactory {
    static create(overrides = {}) {
        return {
            id: 1,
            name: 'John Doe',
            email: 'john@example.com',
            password: 'hashed_password',
            role: 'user',
            active: true,
            createdAt: new Date(),
            ...overrides
        };
    }

    static createActive(overrides = {}) {
        return UserFactory.create({ active: true, ...overrides });
    }

    static createInactive(overrides = {}) {
        return UserFactory.create({ active: false, ...overrides });
    }

    static createAdmin(overrides = {}) {
        return UserFactory.create({ role: 'admin', ...overrides });
    }

    static createSequence(count) {
        return Array.from({ length: count }, (_, i) =>
            UserFactory.create({ id: i + 1, name: `User ${i + 1}` })
        );
    }
}

// Using test factories
import { UserFactory } from './factories/UserFactory';

describe('UserService', () => {
    it('should create active user', () => {
        const user = UserFactory.createActive({ name: 'Jane Doe' });
        expect(user.active).toBe(true);
        expect(user.name).toBe('Jane Doe');
    });

    it('should create multiple users', () => {
        const users = UserFactory.createSequence(5);
        expect(users).toHaveLength(5);
        expect(users[0].name).toBe('User 1');
        expect(users[4].name).toBe('User 5');
    });
});
```

**Python (Factory Boy):**
```bash
# Install Factory Boy
pip install factory_boy
```

```python
# factories.py
import factory
from datetime import datetime
from models import User

class UserFactory(factory.Factory):
    class Meta:
        model = User

    id = factory.Sequence(lambda n: n + 1)
    name = factory.Faker('first_name')
    email = factory.LazyAttribute(lambda o: f"{o.name.lower().replace(' ', '.')}@example.com")
    password = 'hashed_password'
    role = 'user'
    active = True
    created_at = factory.LazyAttribute(lambda o: datetime.now())

# Using factories
import pytest
from factories import UserFactory

@pytest.fixture
def user():
    """User fixture using factory"""
    return UserFactory()

def test_user_is_active(user):
    """Test user created by factory"""
    assert user.active == True
```

**PHP (Factory):**
```bash
# Install Factory
composer require --dev "league/factory"
```

```php
// factories/UserFactory.php
use App\Models\User;
use League\Factory\Adapter\Doctrine;
use League\Factory\Attribute;
use League\Factory\Factory;

class UserFactory extends Factory
{
    protected string $model = User::class;

    protected array $defaults = [
        'name' => 'John Doe',
        'email' => 'john@example.com',
        'password' => 'hashed_password',
        'role' => 'user',
        'active' => true,
    ];

    public function definition(): array
    {
        return [
            'id' => fn(fn('id') => fn()),
            'name' => fn(fn('name') => fn()),
            'email' => fn(fn('email') => fn()),
            'password' => fn(fn('password') => fn()),
            'role' => fn(fn('role') => fn()),
            'active' => fn(fn('active') => fn()),
        ];
    }
}

// Using factories
use App\Models\User;
use Tests\Factories\UserFactory;

it('creates user from factory', function () {
    $user = UserFactory::new()->create();
    expect($user->id)->toBeDefined();
    expect($user->name)->toBe('John Doe');
});
```

---

## Framework Patterns by Language

### JavaScript (Jest Patterns)

| Pattern | Description | Example |
|--------|-------------|----------|
| `beforeAll` | Setup once before all tests | Database connection |
| `afterAll` | Teardown once after all tests | Database disconnect |
| `beforeEach` | Setup before each test | Clear database |
| `afterEach` | Teardown after each test | Clean database |
| `describe.each` | Parametrized tests | Test multiple inputs |
| `expect.extend` | Custom matchers | `toBeValidEmail()` |
| `jest.fn()` | Mock functions | `jest.fn()` |

### Python (PyTest Patterns)

| Pattern | Description | Example |
|--------|-------------|----------|
| `@pytest.fixture` | Reusable fixtures | `mock_db` fixture |
| `setup_method` | Setup before each test | `def setup_method(self)` |
| `teardown_method` | Teardown after each test | `def teardown_method(self)` |
| `@pytest.mark.parametrize` | Parametrized tests | Test multiple inputs |
| `conftest.py` | Shared fixtures/fixtures | Global fixtures |
| `factory_boy` | Test data factories | `UserFactory()` |

### PHP (Pest Patterns)

| Pattern | Description | Example |
|--------|-------------|----------|
| `beforeAll` | Setup once before all tests | Database connection |
| `afterAll` | Teardown once after all tests | Database disconnect |
| `beforeEach` | Setup before each test | Clear database |
| `afterEach` | Teardown after each test | Clean database |
| `->with()` | Parametrized tests | Test multiple inputs |
| `uses()` | Use fixtures | `uses(RefreshDatabase::class)` |
| `expect()->extend()` | Custom matchers | `toBeValidUser()` |

---

## Summary

Framework patterns improve test organization:

**Common Patterns:**
- **Setup/Teardown**: beforeAll/afterAll, beforeEach/afterEach
- **Fixtures**: Reusable test data
- **Parametrized Tests**: Test multiple inputs
- **Test Organization**: Group related tests
- **Test Helpers**: Extract common logic
- **Custom Matchers**: Reusable assertions
- **Test Factories**: Programmatic test data

**By Language:**
- **JavaScript**: Jest, Vitest (beforeEach, describe.each, expect.extend)
- **Python**: PyTest (fixtures, parametrize, factory_boy)
- **PHP**: Pest, PHPUnit (beforeEach, with, uses)

**Benefits:**
- Reduced duplication
- Consistent test data
- Cleaner test code
- Easier maintenance

Use framework patterns to write maintainable, organized tests.
