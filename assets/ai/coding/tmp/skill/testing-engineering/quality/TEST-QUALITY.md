# Test Quality

## Overview

Comprehensive guide to assessing test quality. High-quality tests are maintainable, reliable, and provide confidence in code correctness.

---

## Test Quality Dimensions

### 1. Readability

**Clear test names and structure**

✅ **Good:**
```javascript
it('should throw error when email is invalid', () => {
    expect(() => validateEmail('invalid')).toThrow();
});
```

❌ **Bad:**
```javascript
it('test error case', () => {
    expect(() => validateEmail('invalid')).toThrow();
});
```

### 2. Reliability

**Consistent results, no flakiness**

✅ **Good:**
```javascript
it('should return user by ID', async () => {
    const user = await userService.findById(1);
    expect(user).toEqual(expectedUser);
    // Always same result
});
```

❌ **Bad (Flaky):**
```javascript
it('should return user by ID', async () => {
    cy.wait(1000);  // Random wait!
    const user = await userService.findById(1);
    expect(user).toEqual(expectedUser);
    // Will fail sometimes due to timing
});
```

### 3. Maintainability

**Easy to update, well-structured**

✅ **Good:**
```javascript
function createTestUser(overrides = {}) {
    return {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!',
        ...overrides
    };
}

it('should create user', () => {
    const user = createTestUser({ name: 'Jane Doe' });
    expect(user.name).toBe('Jane Doe');
});
```

❌ **Bad:**
```javascript
it('should create user', () => {
    const user = {
        name: 'Jane Doe',
        email: 'jane@example.com',
        password: 'SecurePass123!',
        active: true,
        createdAt: new Date(),
        updatedAt: new Date(),
        // ... 50 more lines
    };
    expect(user.name).toBe('Jane Doe');
});
```

### 4. Isolation

**Tests don't affect each other**

✅ **Good:**
```javascript
beforeEach(() => {
    // Clean state
    db.clear();
    jest.clearAllMocks();
});

it('test 1', () => {
    // Independent test
});

it('test 2', () => {
    // Independent test (won't be affected by test 1)
});
```

❌ **Bad:**
```javascript
// No cleanup between tests!
it('test 1', () => {
    db.save({ id: 1, name: 'John' });
});

it('test 2', () => {
    const user = db.findById(1);
    expect(user).toBeUndefined();  // FAILS! User from test 1 still there
});
```

### 5. Speed

**Fast feedback (<1 second for unit tests)**

✅ **Good:**
```javascript
it('should calculate total', () => {
    expect(calculateTotal([{ price: 10 }, { price: 20 }])).toBe(30);
    // Runs in <10ms
});
```

❌ **Bad:**
```javascript
it('should calculate total', async () => {
    // Unnecessary async
    const result = await Promise.resolve(calculateTotal([...]));
    expect(result).toBe(30);
    // Slower than necessary
});
```

---

## Test Quality Assessment Checklist

### Unit Test Quality

For each unit test:

- [ ] **Clear Name**: Describes what is being tested
- [ ] **Single Assertion**: Tests one behavior per test
- [ ] **AAA Pattern**: Clear Arrange-Act-Assert structure
- [ ] **No Magic Numbers**: Uses named constants
- [ ] **Test Data Factory**: Uses builders/helpers for complex data
- [ ] **Tests Happy Path**: Normal operation
- [ ] **Tests Error Path**: Edge cases, invalid inputs
- [ ] **Fast**: Runs in <100ms
- [ ] **Isolated**: No external dependencies (mocked)
- [ ] **Deterministic**: Same result every time

### Integration Test Quality

For each integration test:

- [ ] **Clear Purpose**: Describes component interaction
- [ ] **Real Dependencies**: Uses real DB (not mocked)
- [ ] **Clean State**: Resets DB/cache between tests
- [ ] **Test Error Cases**: Invalid inputs, database failures
- [ ] **Medium Speed**: Runs in <5 seconds
- [ ] **Partial Isolation**: Only external services mocked
- [ ] **Verifies Side Effects**: Emails sent, cache updated, etc.

### E2E Test Quality

For each E2E test:

- [ ] **Critical Flow**: Tests important user journey
- [ ] **User-Centric**: Simulates real user actions
- [ ] **Page Objects**: Uses page object model
- [ ] **Explicit Waits**: Waits for specific elements
- [ ] **Data Attributes**: Uses data-testid selectors
- [ ] **Clean State**: Starts with clean application state
- [ ] **Error Scenarios**: Tests error paths
- [ ] **Data-Driven**: Tests with multiple data sets
- [ ] **Acceptable Speed**: Runs in <2 minutes

---

## Test Quality Metrics

### Metrics Dashboard

Track these metrics over time:

| Metric | Good | Excellent |
|--------|-------|------------|
| **Test Execution Time** | <5s | <2s |
| **Test Failure Rate** | <5% | <2% |
| **Flaky Test Rate** | <3% | <1% |
| **Test Coverage** | 80% | 90%+ |
| **Code Coverage per Test** | >10 lines | >20 lines |
| **Assertion Count per Test** | 1-3 | 1-2 |
| **Test Duplication** | <10% | <5% |

### Example Report

```markdown
## Test Quality Report - Week 1

### Overall Metrics
- Total Tests: 250
- Pass Rate: 98% (245/250)
- Flaky Tests: 5 (2%)
- Average Execution Time: 3.2s
- Code Coverage: 82%

### Quality Issues
1. **Slow Tests**: 15 tests >10s
   - Recommend: Optimize or split into smaller tests

2. **High Assertion Count**: 20 tests with 5+ assertions
   - Recommend: Split into focused tests

3. **Test Duplication**: 30 similar test cases
   - Recommend: Use data-driven testing

### Trends
- Pass Rate: Stable (96% → 98%)
- Execution Time: Improving (4.5s → 3.2s)
- Flakiness: Stable (2% → 2%)

### Action Items
- [ ] Optimize slow tests (target: <5s average)
- [ ] Reduce assertion count per test (target: 1-2)
- [ ] Use data-driven testing for duplicate cases
```

---

## Common Test Quality Issues

### Issue 1: Vague Test Names

**Problem:**
```javascript
it('should work', () => { });
it('test user', () => { });
it('error case', () => { });
```

**Solution:**
```javascript
it('should calculate discount for premium users', () => { });
it('should throw error when email is invalid', () => { });
it('should return 0 for empty array', () => { });
```

### Issue 2: Multiple Behaviors in One Test

**Problem:**
```javascript
it('should handle user creation and login', () => {
    // Creates user
    const user = userService.create({ name: 'John' });
    expect(user.id).toBeDefined();

    // Logs in
    const session = authService.login(user.email, 'password');
    expect(session.token).toBeDefined();
    // Too much!
});
```

**Solution:**
```javascript
it('should create user', () => {
    const user = userService.create({ name: 'John' });
    expect(user.id).toBeDefined();
});

it('should login user', () => {
    const session = authService.login('john@example.com', 'password');
    expect(session.token).toBeDefined();
});
```

### Issue 3: Magic Numbers

**Problem:**
```javascript
it('should validate password', () => {
    expect(validatePassword('abc')).toBe(false);  // What's the minimum?
    expect(validatePassword('short')).toBe(false);  // What's the minimum?
    expect(validatePassword('LongPassword123')).toBe(true);  // What's the minimum?
});
```

**Solution:**
```javascript
const MIN_PASSWORD_LENGTH = 8;
const MAX_PASSWORD_LENGTH = 128;

it('should reject password below minimum length', () => {
    expect(validatePassword('short')).toBe(false);
});

it('should accept password at minimum length', () => {
    expect(validatePassword('Pass1234')).toBe(true);  // 8 chars
});
```

### Issue 4: Over-Mocking

**Problem:**
```javascript
it('should process order', () => {
    const mockDb = jest.fn();
    const mockApi = jest.fn();
    const mockCache = jest.fn();
    const mockEmail = jest.fn();

    // Testing nothing real!
    const result = orderService.process(orderData, {
        db: mockDb,
        api: mockApi,
        cache: mockCache,
        email: mockEmail
    });
    expect(result).toBeDefined();
});
```

**Solution:**
```javascript
it('should process order', () => {
    // Use real DB
    const result = orderService.process(orderData, {
        db: realDb,
        api: mockApi,  // Mock only external
        cache: realCache,
        email: mockEmail  // Mock external
    });

    expect(result).toBeDefined();
});
```

### Issue 5: Test-Only Mock Verification

**Problem:**
```javascript
it('should call API', () => {
    const mockApi = jest.fn().mockResolvedValue({ data: 'test' });

    const result = myFunction(mockApi);

    expect(mockApi).toHaveBeenCalled();  // Only testing mock!
    expect(result).toBeUndefined();  // No real verification
});
```

**Solution:**
```javascript
it('should transform API response', () => {
    const mockApi = jest.fn().mockResolvedValue({
        id: 1,
        name: 'John',
        email: 'john@example.com'
    });

    const result = myFunction(mockApi);

    expect(mockApi).toHaveBeenCalled();
    expect(result).toEqual({
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
        initials: 'JD'
    });  // Test real transformation
});
```

---

## Improving Test Quality

### Refactoring Tests

**Extract Common Setup:**
```javascript
// Before (duplicated)
describe('UserService', () => {
    it('should create user', () => {
        const db = new Database();
        const emailService = mockEmailService();
        const service = new UserService(db, emailService);
        // ...
    });

    it('should find user', () => {
        const db = new Database();
        const emailService = mockEmailService();
        const service = new UserService(db, emailService);
        // ...
    });
});

// After (extracted to helper)
function createUserService() {
    const db = new Database();
    const emailService = mockEmailService();
    return new UserService(db, emailService);
}

describe('UserService', () => {
    it('should create user', () => {
        const service = createUserService();
        // ...
    });

    it('should find user', () => {
        const service = createUserService();
        // ...
    });
});
```

**Use Test Builders:**
```javascript
// Before (inline data)
it('should create user', () => {
    const user = userService.create({
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!',
        role: 'user',
        active: true,
        createdAt: new Date(),
        updatedAt: new Date()
    });
});

// After (builder)
const user = new UserBuilder()
    .withName('John Doe')
    .withEmail('john@example.com')
    .withPassword('SecurePass123!')
    .build();

userService.create(user);
```

### Making Tests More Reliable

**Add Explicit Waits:**
```javascript
// Before (implicit wait)
it('should load data', () => {
    cy.visit('/dashboard');
    cy.contains('Welcome').should('be.visible');
    // May fail if slow!
});

// After (explicit wait)
it('should load data', () => {
    cy.visit('/dashboard');
    cy.contains('Welcome', { timeout: 10000 }).should('be.visible');
    // Clear timeout
});
```

**Use Data Attributes:**
```javascript
// Before (brittle selector)
cy.get('div > div > div > span').click();
// Breaks if DOM changes!

// After (data attribute)
cy.get('[data-testid="submit-button"]').click();
// More stable
```

---

## Summary

Test quality assessment focuses on:

**Quality Dimensions:**
- **Readability**: Clear names, good structure
- **Reliability**: Consistent, non-flaky
- **Maintainability**: Easy to update, well-structured
- **Isolation**: Tests don't affect each other
- **Speed**: Fast feedback

**Checklists:**
- **Unit Tests**: Clear name, single assertion, AAA pattern, fast
- **Integration Tests**: Real dependencies, clean state, error cases
- **E2E Tests**: Critical flows, page objects, explicit waits

**Metrics:**
- Execution time: <5s (good), <2s (excellent)
- Failure rate: <5% (good), <2% (excellent)
- Flakiness: <3% (good), <1% (excellent)
- Coverage: 80% (good), 90%+ (excellent)

**Common Issues:**
- Vague test names → Use descriptive names
- Multiple behaviors → Split into focused tests
- Magic numbers → Use named constants
- Over-mocking → Use real dependencies
- Mock-only tests → Test real behavior

**Improvement:**
- Refactor tests (extract common setup)
- Use test builders
- Add explicit waits
- Use data attributes

Use quality assessment to maintain high test quality.
