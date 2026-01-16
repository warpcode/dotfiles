# Mocking

## Overview

Comprehensive guide to mocking frameworks and best practices across languages. Mocking allows isolation of code under test by replacing dependencies with controlled substitutes.

---

## What is Mocking?

### Definition

**Mock**: Object that verifies interactions (method calls, parameters) with dependencies.

**Mocking**: Creating fake objects that simulate behavior of real dependencies (APIs, databases, external services) for testing purposes.

### Why Mock?

1. **Isolation**: Test code without external dependencies
2. **Speed**: Avoid slow network calls, database queries
3. **Reliability**: Tests don't fail due to external factors
4. **Control**: Force specific scenarios (errors, timeouts, edge cases)
5. **Determinism**: Same results every time

### When to Mock

| Scenario | Mock? | Reason |
|-----------|----------|---------|
| Database queries | Yes | Slow, requires setup |
| API calls | Yes | Network dependency, rate limits |
| File system | Yes | Side effects, performance |
| Time/Date | Yes | Determinism |
| Random values | Yes | Reproducibility |
| Pure functions | No | Already isolated |
| Simple objects | No | No need |

---

## Mocking by Framework

### JavaScript (Jest)

**Create Mock Function:**
```javascript
// Simple mock
const mockFn = jest.fn();

// Configure mock behavior
mockFn.mockReturnValue(42);
mockFn.mockResolvedValue({ data: 'test' });
mockFn.mockRejectedValue(new Error('Failed'));

// Multiple return values
mockFn
    .mockReturnValueOnce(10)
    .mockReturnValueOnce(20)
    .mockReturnValue(30);

// Implementation
mockFn.mockImplementation((a, b) => a + b);
mockFn.mockImplementationOnce((a, b) => a + b);

// Verify calls
expect(mockFn).toHaveBeenCalled();
expect(mockFn).toHaveBeenCalledTimes(1);
expect(mockFn).toHaveBeenCalledWith(1, 2);
expect(mockFn).toHaveBeenLastCalledWith(1, 2);
expect(mockFn).toHaveBeenNthCalledWith(1, 1, 2);

// Inspect calls
mockFn.mock.calls;        // Array of all calls
mockFn.mock.results;      // Array of results
mockFn.mock.instances;    // Array of `this` values
```

**Mock Module:**
```javascript
// Mock entire module
jest.mock('./api');
const { fetchData } = require('./api');

// Configure mock
fetchData.mockResolvedValue({ data: 'test' });

// Test
it('should fetch data', async () => {
    const result = await fetchData();
    expect(result).toEqual({ data: 'test' });
});

// Clear mock
afterEach(() => {
    jest.clearAllMocks();
    jest.resetAllMocks();
    jest.restoreAllMocks();
});
```

**Spy on Existing Function:**
```javascript
const originalMath = global.Math;

// Spy on method
const spy = jest.spyOn(Math, 'random');

// Mock implementation
spy.mockReturnValue(0.5);

// Test
const result = Math.random();
expect(result).toBe(0.5);

// Restore
spy.mockRestore();
```

---

### TypeScript (Jest)

**Mock Module with Typing:**
```typescript
// Mock with proper types
import { UserService } from './UserService';

// Create mock
const mockUserService = jest.mocked<UserService>(
    UserService as unknown as UserService
);

// Configure mock
mockUserService.findById.mockResolvedValue({
    id: 1,
    name: 'John Doe'
});

// Verify
expect(mockUserService.findById).toHaveBeenCalledWith(1);
```

---

### Python (unittest.mock)

**Create Mock:**
```python
from unittest.mock import Mock, patch, MagicMock

# Simple mock
mock_fn = Mock()

# Configure behavior
mock_fn.return_value = 42
mock_fn.side_effect = ValueError('Invalid input')

# Multiple return values
mock_fn.side_effect = [10, 20, 30]

# Verify calls
mock_fn.assert_called()
mock_fn.assert_called_once()
mock_fn.assert_called_with(1, 2)
mock_fn.assert_called_once_with(1, 2)

# Inspect calls
mock_fn.call_count
mock_fn.call_args
mock_fn.call_args_list
```

**Patch Function/Method:**
```python
from unittest.mock import patch

def test_fetch_data():
    # Patch function
    with patch('module.fetchData') as mock_fetch:
        mock_fetch.return_value = {'data': 'test'}

        # Test
        result = my_function()
        assert result == {'data': 'test'}

        # Verify
        mock_fetch.assert_called_once()
```

**Patch Class:**
```python
def test_user_service():
    with patch('services.UserService') as mock_service:
        # Configure mock
        mock_instance = mock_service.return_value
        mock_instance.findById.return_value = {'id': 1, 'name': 'John'}

        # Test
        user = UserService.findById(1)
        assert user == {'id': 1, 'name': 'John'}

        # Verify
        mock_instance.findById.assert_called_once_with(1)
```

**Patch Decorator:**
```python
from unittest.mock import patch

@patch('services.UserService.findById')
def test_get_user(mock_findById):
    # Configure mock
    mock_findById.return_value = {'id': 1, 'name': 'John'}

    # Test
    user = get_user(1)
    assert user == {'id': 1, 'name': 'John'}

    # Verify
    mock_findById.assert_called_once_with(1)
```

---

### PHP (PHPUnit)

**Create Mock:**
```php
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\MockObject\MockObject;

class UserServiceTest extends TestCase
{
    public function testCreateUser()
    {
        // Create mock
        $userRepository = $this->createMock(UserRepository::class);

        // Configure mock
        $userRepository
            ->expects($this->once())
            ->method('save')
            ->with($this->callback(function ($user) {
                return $user->getName() === 'John Doe';
            }))
            ->willReturn($user);

        // Test
        $service = new UserService($userRepository);
        $result = $service->create(['name' => 'John Doe']);

        $this->assertEquals('John Doe', $result->getName());
    }

    public function testThrowExceptionForDuplicateEmail()
    {
        $userRepository = $this->createMock(UserRepository::class);

        // Configure mock to throw exception
        $userRepository
            ->expects($this->once())
            ->method('findByEmail')
            ->with('john@example.com')
            ->willReturn(null);  // User not found

        // Test
        $this->expectException(EmailAlreadyExistsException::class);

        $service = new UserService($userRepository);
        $service->create(['name' => 'John', 'email' => 'john@example.com']);
    }
}
```

**Mock Builder:**
```php
public function testUserRepository()
{
    // Create mock with more control
    $userRepository = $this->getMockBuilder(UserRepository::class)
        ->disableOriginalConstructor()
        ->disableOriginalClone()
        ->disableArgumentCloning()
        ->getMock();

    // Configure multiple methods
    $userRepository
        ->expects($this->once())
        ->method('save')
        ->willReturn($user);

    $userRepository
        ->expects($this->never())
        ->method('delete');

    // Test
    $service = new UserService($userRepository);
    $service->create($userData);
}
```

---

### Ruby (RSpec)

**Create Mock:**
```ruby
require 'rspec/mocks'

describe UserService do
  it 'creates user with valid data' do
    # Create mock
    user_repository = instance_double('UserRepository')

    # Configure mock
    allow(user_repository).to receive(:save)
      .with(having_attributes(name: 'John Doe'))
      .and_return(user)

    # Test
    service = UserService.new(user_repository)
    result = service.create(name: 'John Doe')

    expect(result.name).to eq('John Doe')
  end

  it 'throws error for duplicate email' do
    user_repository = instance_double('UserRepository')

    # Configure mock
    allow(user_repository).to receive(:find_by_email)
      .with('john@example.com')
      .and_return(nil)

    # Test
    expect {
      service.create(name: 'John', email: 'john@example.com')
    }.to raise_error(EmailAlreadyExistsError)
  end

  it 'sends welcome email after registration' do
    email_service = instance_double('EmailService')

    # Expect method to be called
    expect(email_service).to receive(:send_welcome)
      .with('john@example.com', 'John Doe')
      .once

    # Test
    service = UserService.new(user_repository, email_service)
    service.create(name: 'John Doe', email: 'john@example.com')
  end
end
```

**Allow vs Expect:**
```ruby
# allow - Stub (configure behavior)
allow(user_repository).to receive(:save).and_return(user)

# expect - Mock (verify interaction)
expect(user_repository).to receive(:save).once
```

---

### Go

**Create Mock:**
```go
package mypackage

import (
    "testing"
    "github.com/stretchr/testify/mock"
)

// Mock interface
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(id int) (*User, error) {
    args := m.Called(id)
    if user, ok := args.Get(0).(*User); ok {
        return user, args.Error(1)
    }
    return nil, args.Error(1)
}

func TestUserService_Create(t *testing.T) {
    // Create mock
    mockRepo := new(MockUserRepository)

    // Configure mock
    user := &User{ID: 1, Name: "John Doe"}
    mockRepo.On("FindByID", 1).Return(user, nil)

    // Test
    service := NewUserService(mockRepo)
    result, err := service.Create("John Doe")

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, user, result)

    // Verify mock was called
    mockRepo.AssertExpectations(t)
}

func TestUserService_Create_DuplicateEmail(t *testing.T) {
    mockRepo := new(MockUserRepository)

    // Configure mock to return error
    mockRepo.On("FindByEmail", "john@example.com").
        Return(nil, ErrDuplicateEmail)

    // Test
    service := NewUserService(mockRepo)
    _, err := service.Create("John", "john@example.com")

    // Assert error
    assert.Error(t, err)
    assert.Equal(t, ErrDuplicateEmail, err)
}
```

---

## Mocking Scenarios

### Mocking API Calls

**JavaScript (Jest):**
```javascript
// Mock fetch API
global.fetch = jest.fn(() =>
    Promise.resolve({
        json: () => Promise.resolve({ data: 'test' })
    })
);

// Test
it('should fetch data from API', async () => {
    fetch.mockResolvedValueOnce({
        json: () => Promise.resolve({ data: 'test' })
    });

    const result = await fetchDataFromAPI();
    expect(result).toEqual({ data: 'test' });
});
```

**Python:**
```python
from unittest.mock import patch

def test_fetch_from_api():
    with patch('requests.get') as mock_get:
        # Configure mock response
        mock_response = Mock()
        mock_response.json.return_value = {'data': 'test'}
        mock_get.return_value = mock_response

        # Test
        result = fetch_from_api()
        assert result == {'data': 'test'}

        # Verify
        mock_get.assert_called_once_with('https://api.example.com/data')
```

### Mocking Database

**JavaScript (Jest):**
```javascript
jest.mock('./db');

const { User } = require('./db');

it('should find user by ID', async () => {
    User.findById.mockResolvedValue({
        id: 1,
        name: 'John Doe'
    });

    const user = await UserService.findById(1);
    expect(user).toEqual({ id: 1, name: 'John Doe' });
    expect(User.findById).toHaveBeenCalledWith(1);
});
```

**Python:**
```python
from unittest.mock import patch, MagicMock

def test_find_user_by_id():
    with patch('models.User') as mock_user:
        # Configure mock
        mock_user.objects.get.return_value = MagicMock(id=1, name='John Doe')

        # Test
        user = find_user_by_id(1)
        assert user.id == 1
        assert user.name == 'John Doe'

        # Verify
        mock_user.objects.get.assert_called_once_with(id=1)
```

### Mocking Time

**JavaScript (Jest):**
```javascript
jest.useFakeTimers();

it('should timeout after 5 seconds', () => {
    const callback = jest.fn();

    setTimeout(callback, 5000);

    // Fast-forward time
    jest.advanceTimersByTime(5000);

    expect(callback).toHaveBeenCalled();
});

// Restore real timers
afterAll(() => {
    jest.useRealTimers();
});
```

**Python:**
```python
from unittest.mock import patch
import datetime
from freezegun import freeze_time

def test_time_specific_logic():
    # Freeze time
    with freeze_time('2025-01-15'):
        # Test
        result = get_current_date()
        assert result == datetime.date(2025, 1, 15)
```

### Mocking Random Values

**JavaScript:**
```javascript
// Mock Math.random
const originalRandom = Math.random;
Math.random = jest.fn().mockReturnValue(0.5);

it('should use random value', () => {
    const result = generateRandom();
    expect(result).toBe(5);  // Based on 0.5
});

// Restore
Math.random = originalRandom;
```

**Python:**
```python
from unittest.mock import patch

def test_random_value():
    with patch('random.random') as mock_random:
        # Configure mock
        mock_random.return_value = 0.5

        # Test
        result = generate_random()
        assert result == 5
```

---

## Mocking Best Practices

### 1. Don't Mock Everything

```javascript
// ❌ Bad - Mocking too much
it('should calculate total', () => {
    const calculator = mock(Calculator);
    calculator.add.mockReturnValue(5);
    calculator.multiply.mockReturnValue(10);
    const result = calculateTotal(calculator);
    expect(result).toBe(10);
});

// ✅ Good - Test real logic
it('should calculate total', () => {
    const calculator = new Calculator();  // Real instance
    const result = calculateTotal(calculator);
    expect(result).toBe(expected);
});
```

### 2. Don't Mock Value Objects

```javascript
// ❌ Bad - Mocking simple data object
it('should format user name', () => {
    const mockUser = {
        firstName: 'John',
        lastName: 'Doe'
    };
    const formatted = formatUserName(mockUser);
    expect(formatted).toBe('John Doe');
});

// ✅ Good - Mock is unnecessary here
it('should format user name', () => {
    const user = new User('John', 'Doe');
    const formatted = formatUserName(user);
    expect(formatted).toBe('John Doe');
});
```

### 3. Verify Only Important Interactions

```javascript
// ❌ Bad - Verifying everything
it('should process order', () => {
    expect(OrderService.create).toHaveBeenCalled();
    expect(EmailService.send).toHaveBeenCalled();
    expect(InventoryService.check).toHaveBeenCalled();
    expect(PaymentService.charge).toHaveBeenCalled();
    expect(AnalyticsService.track).toHaveBeenCalled();
});

// ✅ Good - Verify critical interactions
it('should process order', () => {
    expect(PaymentService.charge).toHaveBeenCalledWith(amount);
    expect(EmailService.send).toHaveBeenCalledWith(
        'order_confirmation',
        user.email
    );
});
```

### 4. Use Meaningful Mock Names

```javascript
// ❌ Bad - Unclear mock names
const mock1 = jest.fn();
const mock2 = jest.fn();
const mock3 = jest.fn();

// ✅ Good - Descriptive mock names
const mockUserRepository = jest.fn();
const mockEmailService = jest.fn();
const mockPaymentGateway = jest.fn();
```

### 5. Reset Mocks Between Tests

```javascript
beforeEach(() => {
    jest.clearAllMocks();
    jest.resetAllMocks();
});

afterEach(() => {
    jest.clearAllTimers();
});

afterAll(() => {
    jest.restoreAllMocks();
});
```

---

## Common Mocking Anti-Patterns

### ❌ "The Mock-Only Test" - Testing Nothing

```javascript
// Bad - Just testing the mock
it('should call API', () => {
    const mockApi = jest.fn().mockResolvedValue({ data: 'test' });

    const result = await fetchFromAPI(mockApi);

    expect(mockApi).toHaveBeenCalled();  // Only verifying mock!
    expect(result).toBeUndefined();     // Didn't test actual logic
});
```

**Fix:** Test actual logic, not just mock interactions.

```javascript
// Good - Test real logic
it('should transform API response', () => {
    const mockApi = jest.fn().mockResolvedValue({
        id: 1,
        first_name: 'John',
        last_name: 'Doe'
    });

    const result = await fetchAndTransformUser(mockApi);

    expect(result).toEqual({
        id: 1,
        fullName: 'John Doe',
        initials: 'JD'
    });
});
```

### ❌ "The Over-Specified Mock" - Too Strict

```javascript
// Bad - Mock too specific
const mockApi = jest.fn().mockResolvedValue({
    data: {
        items: [
            { id: 1, name: 'Product 1', price: 10 },
            { id: 2, name: 'Product 2', price: 20 }
        ],
        total: 2,
        page: 1,
        per_page: 10
    }
});
```

**Fix:** Only specify what's needed.

```javascript
// Good - Mock only essential data
const mockApi = jest.fn().mockResolvedValue({
    data: {
        items: [
            { id: 1, name: 'Product 1' },
            { id: 2, name: 'Product 2' }
        ]
    }
});
```

### ❌ "The Stub in Disguise" - Mock without Verification

```javascript
// Bad - Mock without verification (should be stub)
const mockApi = jest.fn().mockResolvedValue({ data: 'test' });

const result = await fetchFromAPI(mockApi);
expect(result).toEqual({ data: 'test' });

// Never verified that mock was called!
```

**Fix:** Use stub (just configure behavior) or verify mock calls.

```javascript
// Stub - No verification needed
const stubApi = { fetch: () => ({ data: 'test' }) };

const result = await fetchFromAPI(stubApi);
expect(result).toEqual({ data: 'test' });

// Or verify mock calls
const mockApi = jest.fn().mockResolvedValue({ data: 'test' });

const result = await fetchFromAPI(mockApi);
expect(mockApi).toHaveBeenCalledWith(expectedParams);
```

---

## Summary

Mocking isolates code under test:

**When to Mock:**
- Database queries
- API calls
- File system operations
- Time/Date dependencies
- Random values

**Best Practices:**
- Don't mock everything
- Don't mock value objects
- Verify only important interactions
- Use descriptive mock names
- Reset mocks between tests

**Anti-Patterns:**
- Mock-only tests (testing nothing)
- Over-specified mocks (too strict)
- Stubs in disguise (mocks without verification)

Use mocks wisely to isolate code and ensure reliable tests.
