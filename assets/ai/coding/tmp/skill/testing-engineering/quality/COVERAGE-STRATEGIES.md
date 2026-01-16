# Coverage Strategies

## Overview

Comprehensive guide to coverage strategies and goals. Coverage should guide testing efforts, not be an end goal.

---

## Coverage Strategy Framework

### Strategic Approach

```
┌─────────────────────────────────────┐
│      COVERAGE STRATEGY            │
├─────────────────────────────────────┤
│  1. Identify Critical Paths     │
│  2. Set Tiered Targets        │
│  3. Focus on Value            │
│  4. Balance Cost vs Benefit     │
│  5. Review and Adjust          │
└─────────────────────────────────────┘
```

---

## Tiered Coverage Strategy

### By Code Tier

```
┌───────────────────────────────────┐
│         90%+ (Critical)        │  Payment processing
│         Security code             │  Authentication
│         Core business logic      │
├───────────────────────────────────┤
│      80-85% (High Value)      │  API endpoints
│      Service layer             │  Database operations
│      Validation               │  Data transformation
├───────────────────────────────────┤
│      70-75% (Medium Value)    │  Controllers
│      UI components            │  Utilities
│      Error handling           │  Logging
├───────────────────────────────────┤
│      50-60% (Low Value)        │  Configuration
│      Routes                  │  Type definitions
│      Migrations              │  Static assets
└───────────────────────────────────┘
```

### By Risk Level

| Risk Level | Coverage Target | Rationale |
|-----------|-----------------|------------|
| **Critical** | 90-95% | Security, financial, safety |
| **High** | 80-85% | Core business logic, APIs |
| **Medium** | 70-75% | UI, controllers, utilities |
| **Low** | 50-60% | Config, static files |

---

## Risk-Based Coverage Strategy

### Step 1: Identify Risk Areas

**Risk Assessment Matrix:**

| Component | Impact | Probability | Risk Score | Coverage Target |
|-----------|---------|-------------|------------|-----------------|
| Payment Service | High | Medium | High | 90%+ |
| Authentication | High | High | High | 90%+ |
| User Service | Medium | High | Medium | 80%+ |
| Email Service | Low | Medium | Low | 70%+ |
| Logging | Low | Low | Low | 50%+ |

**Risk Score Calculation:**
```
Risk = Impact × Probability

High (3) × High (3) = 9 → 90%+ coverage
High (3) × Medium (2) = 6 → 85-90% coverage
Medium (2) × High (3) = 6 → 85-90% coverage
Medium (2) × Medium (2) = 4 → 80-85% coverage
```

### Step 2: Prioritize by Risk

```javascript
// Priority order for coverage testing
const priorityOrder = [
    'PaymentService',     // High risk, 90%+ target
    'Authentication',     // High risk, 90%+ target
    'UserService',       // Medium risk, 80%+ target
    'EmailService',      // Low risk, 70%+ target
    'Logger',           // Low risk, 50%+ target
];
```

---

## Coverage by Code Type

### Business Logic Strategy

**Target: 85-90%**

**Focus:**
- Complex algorithms
- Calculation logic
- Business rules
- Data transformation

**Why:** Highest value, most bugs occur here

**Example:**
```javascript
// Critical: Calculate discount with complex rules
function calculateDiscount(order, user) {
    // Test all branches
    if (user.isPremium && order.total > 100) { return 0.15; }
    if (order.total > 50) { return 0.10; }
    if (user.isFirstPurchase) { return 0.05; }
    return 0.0;
}

// Test strategy:
// 1. Premium user, order > $100 → 15%
// 2. Premium user, order < $100 → 10%
// 3. Regular user, order > $50 → 10%
// 4. Regular user, order < $50 → 0%
// 5. First purchase user → 5%
```

### API Endpoints Strategy

**Target: 70-80%**

**Focus:**
- Success paths
- Error handling (400, 401, 403, 404, 500)
- Input validation
- Edge cases (empty arrays, null values)

**Why:** Integration with external systems, multiple code paths

**Example:**
```javascript
// GET /api/users/:id
app.get('/api/users/:id', async (req, res) => {
    try {
        // 1. Validate parameter (test: invalid ID)
        if (!isValidId(req.params.id)) {
            return res.status(400).json({ error: 'Invalid ID' });
        }

        // 2. Fetch from DB (test: user not found)
        const user = await User.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // 3. Check authorization (test: not authorized)
        if (req.user.id !== user.id && !req.user.isAdmin) {
            return res.status(403).json({ error: 'Forbidden' });
        }

        // 4. Return user (test: success)
        return res.json(user);
    } catch (error) {
        // 5. Handle errors (test: server error)
        return res.status(500).json({ error: 'Internal server error' });
    }
});

// Test strategy:
// 1. Invalid ID → 400
// 2. User not found → 404
// 3. Not authorized → 403
// 4. Success → 200
// 5. Server error → 500
```

### UI Components Strategy

**Target: 70-75%**

**Focus:**
- User interactions (click, input, submit)
- State changes (loading, success, error)
- Rendering (conditional display)
- Edge cases (empty lists, errors)

**Why:** Testing is expensive (slow, brittle), focus on critical paths

**Example:**
```javascript
// UserForm component
function UserForm({ onSubmit }) {
    const [values, setValues] = useState({ name: '', email: '' });
    const [errors, setErrors] = useState({});
    const [loading, setLoading] = useState(false);

    // Test: Input validation
    const handleChange = (field, value) => {
        setValues({ ...values, [field]: value });

        // Test: Email validation
        if (field === 'email' && !isValidEmail(value)) {
            setErrors({ ...errors, email: 'Invalid email' });
        } else {
            setErrors({ ...errors, email: null });
        }
    };

    // Test: Submit action
    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);

        try {
            await onSubmit(values);
            setLoading(false);
        } catch (error) {
            setLoading(false);
            setErrors({ ...errors, submit: error.message });
        }
    };

    return (
        <form onSubmit={handleSubmit}>
            {/* Test: Name input */}
            <input value={values.name} onChange={e => handleChange('name', e.target.value)} />

            {/* Test: Email input */}
            <input value={values.email} onChange={e => handleChange('email', e.target.value)} />
            {errors.email && <span>{errors.email}</span>}

            {/* Test: Submit button */}
            <button disabled={loading}>
                {loading ? 'Saving...' : 'Submit'}
            </button>

            {errors.submit && <span>{errors.submit}</span>}
        </form>
    );
}

// Test strategy:
// 1. Valid form submission → success
// 2. Email validation → error message
// 3. Loading state → disabled button
// 4. Error handling → error message
```

---

## Coverage Increment Strategy

### Iterative Approach

```
┌─────────────────────────────────────┐
│      CURRENT STATE                │
│      Coverage: 45%                │
├─────────────────────────────────────┤
│      Sprint 1                     │
│      Target: 60%                  │
│      Focus: Critical paths          │
├─────────────────────────────────────┤
│      Sprint 2                     │
│      Target: 75%                  │
│      Focus: Error handling         │
├─────────────────────────────────────┤
│      Sprint 3                     │
│      Target: 85%                  │
│      Focus: Edge cases            │
└─────────────────────────────────────┘
```

### Sprint Planning

**Sprint 1: Critical Paths (Target: 60%)**
```javascript
// Priority 1: Happy path for critical features
- User registration → success
- User login → success
- Order placement → success
- Payment processing → success

// Estimated: 15% coverage increase
// Time: 2 weeks
```

**Sprint 2: Error Handling (Target: 75%)**
```javascript
// Priority 2: Error paths
- Registration → duplicate email
- Login → invalid credentials
- Order → out of stock
- Payment → declined

// Estimated: 15% coverage increase
// Time: 2 weeks
```

**Sprint 3: Edge Cases (Target: 85%)**
```javascript
// Priority 3: Edge cases
- Empty inputs
- Null values
- Large numbers
- Special characters
- Concurrent operations

// Estimated: 10% coverage increase
// Time: 2 weeks
```

---

## Coverage vs Quality Balance

### The 80/20 Rule

**80% of value from 20% of code:**

```javascript
// Focus on:
- 20% most critical files → 80% coverage
// Ignore:
- 80% less critical files → 50% coverage
```

### Quality Over Coverage

```javascript
// Bad: High coverage, low quality
it('should do something', () => {
    const result = myFunction();
    expect(result).toBeDefined();  // Weak assertion!
    // 100% coverage, 0% confidence
});

// Good: Medium coverage, high quality
it('should return specific result', () => {
    const result = myFunction(input);
    expect(result).toEqual({  // Strong assertion!
        id: 1,
        name: 'John Doe',
        status: 'active'
    });
    // 80% coverage, 100% confidence
});
```

---

## Coverage Tracking Strategy

### Metrics Dashboard

**Track:**
1. Overall coverage percentage
2. Coverage by module/file
3. Uncovered lines count
4. Trend over time (improving/regressing)

**Example Dashboard:**

| Module | Coverage | Uncovered Lines | Trend |
|---------|-----------|-----------------|--------|
| UserService | 92% | 15 | ↗ Improving |
| PaymentService | 85% | 25 | → Stable |
| OrderService | 78% | 45 | ↗ Improving |
| EmailService | 65% | 80 | ↘ Regressing |

### Coverage Reports

**Weekly Coverage Report:**
```markdown
## Coverage Report - Week 1

### Overall Coverage: 78% (↑ 5% from last week)

### High Risk Modules
| Module | Coverage | Target | Status |
|---------|-----------|---------|--------|
| PaymentService | 85% | 90% | ⚠️ Below target |
| Authentication | 82% | 90% | ⚠️ Below target |

### Improvements
- UserService: 85% → 92% (+7%)
- OrderService: 70% → 78% (+8%)

### Regression
- EmailService: 70% → 65% (-5%)

### Action Items
- Focus on PaymentService coverage (missing edge cases)
- Investigate EmailService regression (new code added without tests)
- Target next week: 80% overall coverage
```

---

## Coverage Anti-Patterns

### ❌ "One-Size-Fits-All" - Same Target for All Code

**Bad:**
```javascript
// Same target for all modules
{
    global: {
        lines: 80  // Same for everything!
    }
}
```

**Good:**
```javascript
// Different targets by module
{
    global: {
        lines: 75
    },
    './src/PaymentService.js': {
        lines: 90      // Critical: 90%
    },
    './src/UserService.js': {
        lines: 85      // High: 85%
    },
    './src/EmailService.js': {
        lines: 70      // Low: 70%
    }
}
```

### ❌ "Coverage Chasing" - Tests Just for Coverage

**Bad:**
```javascript
// Test only to increase coverage
it('should handle all possible inputs', () => {
    // Testing trivial cases just for coverage
    expect(myFunction(0)).toBe(0);
    expect(myFunction(1)).toBe(1);
    expect(myFunction(2)).toBe(2);
    expect(myFunction(3)).toBe(3);
    // ... 100 more lines of trivial tests
});
```

**Good:**
```javascript
// Test based on requirements
it('should calculate discount for premium users', () => {
    const order = createOrder({ total: 150 });
    const user = createPremiumUser();

    const discount = calculateDiscount(order, user);

    expect(discount).toBe(22.5);  // 15% of 150
});
```

### ❌ "False High Coverage" - Dead Code Covered

**Bad:**
```javascript
function process(data) {
    if (data === null) {
        return null;
    }

    // Unreachable code (always returns above)
    return process(data);  // Infinite recursion!
    // But tests with null = 100% coverage!
}
```

**Good:**
```javascript
function process(data) {
    if (data === null) {
        return null;
    }

    return transform(data);  // Real implementation
}
```

---

## Summary

Coverage strategy should guide testing:

**Strategic Approach:**
1. Identify critical paths by risk
2. Set tiered targets (critical 90%, high 80%, low 70%)
3. Focus on value, not coverage
4. Balance cost vs benefit
5. Review and adjust

**Targets by Tier:**
- **Critical (90%+)**: Payment, security, core logic
- **High (80-85%)**: APIs, services, business rules
- **Medium (70-75%)**: UI, controllers, utilities
- **Low (50-60%)**: Config, static files

**Incremental Strategy:**
- Sprint 1: Critical paths (→ 60%)
- Sprint 2: Error handling (→ 75%)
- Sprint 3: Edge cases (→ 85%)

**Balance:**
- Quality > Coverage (meaningful tests > 100% coverage)
- 80/20 rule (critical paths > comprehensive coverage)
- Track trends (improving/regressing)

**Anti-Patterns:**
- One-size-fits-all targets
- Coverage chasing (tests just for coverage)
- False high coverage (dead code covered)

Use coverage as a guide, not a goal.
