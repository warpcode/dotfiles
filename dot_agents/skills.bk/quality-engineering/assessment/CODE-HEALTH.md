# Code Health

## Overview

Comprehensive guide to assessing overall code health. Code health combines code quality, maintainability, complexity, and technical debt into a holistic assessment.

---

## Code Health Dimensions

```
┌─────────────────────────────────────┐
│        CODE HEALTH                │
├─────────────────────────────────────┤
│  1. Code Quality                 │
│  2. Maintainability              │
│  3. Test Coverage                │
│  4. Technical Debt               │
│  5. Performance                 │
│  6. Security                    │
│  7. Documentation              │
└─────────────────────────────────────┘
```

---

## 1. Code Quality

### Metrics

| Metric | Healthy | Unhealthy | Target |
|--------|----------|-----------|--------|
| **Cyclomatic Complexity** | <10 | >20 | <10 per function |
| **Code Duplication** | <5% | >15% | <5% duplicated |
| **Code Smells** | <10 | >25 | <10 per 1000 LOC |
| **Test Coverage** | >70% | <50% | >70% |
| **Maintainability Index** | >20 | <10 | >20 (MI) |

### Assessment Tools

**JavaScript/TypeScript:**
- ESLint (code quality checks)
- SonarQube (technical debt, complexity)
- CodeClimate (code quality, security)

**Python:**
- Flake8 (PEP8 compliance)
- Radon (complexity)
- Bandit (security issues)

**PHP:**
- PHPStan (code quality, bugs)
- Psalm (type safety)
- PHP_CodeSniffer (code style)

**Ruby:**
- RuboCop (code style, complexity)

### Code Quality Checklist

- [ ] **Naming**: Consistent, descriptive names
- [ ] **Structure**: Clear file/module organization
- [ ] **Comments**: Self-documenting, not over-commenting
- [ ] **Style**: Consistent formatting, linting
- [ ] **Error Handling**: Proper try-catch, error messages
- [ ] **Validation**: Input validation, type checking
- [ ] **Type Safety**: Type hints, interfaces, strict mode

---

## 2. Maintainability

### Maintainability Index (MI)

```
MI = 171 - 5.2 × ln(cc) - 0.23 × cc - 16.2 × ln(V/G)
```

Where:
- **cc** = Cyclomatic Complexity
- **V** = Number of unique operands
- **G** = Number of unique operators

**MI Scores:**
- 85-100: Very High Maintainability
- 65-85: High Maintainability
- 50-65: Moderate Maintainability
- 0-50: Low Maintainability

### Assessment

**Healthy (>65 MI):**
- Low complexity functions
- Clear, descriptive names
- Single Responsibility
- Minimal coupling
- Good code organization

**Unhealthy (<50 MI):**
- High complexity functions
- Vague or abbreviated names
- Multiple responsibilities per class
- High coupling
- Poor organization

### Maintainability Checklist

- [ ] **Single Responsibility**: Each class/function has one reason to change
- [ ] **Open/Closed Principle**: Open for extension, closed for modification
- [ ] **Coupling**: Low coupling between modules
- [ ] **Cohesion**: High cohesion within modules
- [ ] **Readability**: Easy to understand and follow
- [ ] **Modularity**: Well-organized, separated concerns
- [ ] **Testability**: Easy to test, isolated components

---

## 3. Test Coverage

### Coverage Metrics

| Metric | Healthy | Unhealthy | Target |
|--------|----------|-----------|--------|
| **Statement Coverage** | >80% | <60% | >80% |
| **Branch Coverage** | >75% | <50% | >75% |
| **Function Coverage** | >85% | <70% | >85% |
| **Line Coverage** | >80% | <60% | >80% |

### Coverage Analysis

```javascript
// Example coverage report
{
    "total": {
        "lines": 10000,
        "statements": 5000
    },
    "covered": {
        "lines": 8000,
        "statements": 4000
    },
    "coverage": {
        "line": 80,
        "statement": 80,
        "branch": 75,
        "function": 85
    },
    "files": {
        "src/services/OrderService.js": {
            "lines": { "total": 500, "covered": 450, "pct": 90 },
            "statements": { "total": 250, "covered": 225, "pct": 90 },
            "branches": { "total": 50, "covered": 40, "pct": 80 },
            "functions": { "total": 20, "covered": 18, "pct": 90 }
        },
        "src/utils/Formatter.js": {
            "lines": { "total": 200, "covered": 100, "pct": 50 },
            "statements": { "total": 100, "covered": 50, "pct": 50 },
            "branches": { "total": 20, "covered": 5, "pct": 25 },
            "functions": { "total": 10, "covered": 5, "pct": 50 }
        }
    }
}
```

### Coverage Gaps

**Identify uncovered code:**
1. New features without tests
2. Error handling paths
3. Edge cases
4. Configuration code
5. Utility functions

**Action Plan:**
1. Prioritize critical paths (payments, security)
2. Add integration tests for API endpoints
3. Add unit tests for business logic
4. Add E2E tests for critical user flows
5. Aim for 80% coverage, not 100%

---

## 4. Technical Debt

### Debt Metrics

| Metric | Healthy | Unhealthy | Target |
|--------|----------|-----------|--------|
| **Debt Ratio** | <5% | >15% | <5% |
| **Code Duplication** | <5% | >15% | <5% |
| **Complex Functions** | <10% | >25% | <10% |
| **Bug Density** | <0.5/1000 LOC | >2/1000 LOC | <0.5/1000 LOC |

### Debt Categories

**1. Design Debt:** Architectural issues, wrong patterns
```javascript
// Example: Missing abstraction, using copy-paste instead of inheritance
function calculateDiscountForRegular(price) {
    return price * 0.95;
}

function calculateDiscountForPremium(price) {
    return price * 0.90;
}

function calculateDiscountForVIP(price) {
    return price * 0.85;
}

// Debt: Should use polymorphism or strategy pattern
```

**2. Code Debt:** Poor code quality, technical problems
```javascript
// Example: Hard-coded values, magic numbers
function calculateInterest(principal, years) {
    // Debt: Hard-coded interest rate
    return principal * Math.pow(1.05, years);
}
```

**3. Test Debt:** Missing or insufficient tests
```javascript
// Example: No test coverage for critical payment processing
class PaymentService {
    async processPayment(card, amount) {
        // Critical code - no tests!
        // Debt: Missing test coverage
    }
}
```

**4. Documentation Debt:** Missing or outdated documentation
```javascript
// Example: No documentation for complex algorithms
function calculateHash(data) {
    // Complex algorithm - no documentation
    // Debt: Missing documentation
}
```

### Debt Management

**Prioritization:**
1. Fix security vulnerabilities immediately
2. Address performance bottlenecks
3. Refactor high-complexity functions
4. Add test coverage to critical paths
5. Pay down code duplication debt

**Debt Reduction Strategy:**
- Sprint 1: Security fixes
- Sprint 2: Performance optimization
- Sprint 3: Refactoring
- Sprint 4: Test coverage improvement
- Sprint 5: Documentation updates

---

## 5. Performance

### Performance Metrics

| Metric | Healthy | Unhealthy | Target |
|--------|----------|-----------|--------|
| **API Response Time** | <200ms | >1000ms | <200ms |
| **Database Query Time** | <100ms | >500ms | <100ms |
| **Bundle Size** | <200KB | >1MB | <200KB |
| **Lighthouse Score** | >90 | <70 | >90 |

### Performance Analysis

```javascript
// Example: Slow database queries
async function getUserOrders(userId) {
    // Performance issue: N+1 queries
    const user = await db.query('SELECT * FROM users WHERE id = ?', [userId]);

    for (const orderId of user.orderIds) {
        const order = await db.query('SELECT * FROM orders WHERE id = ?', [orderId]);
        // Process order
    }

    return orders;
}

// ✅ OPTIMIZED - Single query with JOIN
async function getUserOrders(userId) {
    const orders = await db.query(`
        SELECT
            u.id AS user_id,
            o.id,
            o.total,
            o.created_at
        FROM users u
        INNER JOIN orders o ON u.id = o.user_id
        WHERE u.id = ?
        ORDER BY o.created_at DESC
    `, [userId]);

    return orders;
}
```

---

## 6. Security

### Security Metrics

| Metric | Healthy | Unhealthy | Target |
|--------|----------|-----------|--------|
| **Known Vulnerabilities** | 0 | >0 | 0 |
| **OWASP Compliance** | Passed | Failed | Passed |
| **Dependency Vulnerabilities** | 0 | >0 | 0 |
| **Secrets Exposure** | 0 | >0 | 0 |

### Security Checklist

- [ ] **Input Validation**: All user inputs validated
- [ ] **SQL Injection Prevention**: Parameterized queries, ORMs used
- [ ] **XSS Prevention**: Output encoding, CSP headers
- [ ] **CSRF Protection**: Tokens for state-changing requests
- [ ] **Authentication**: Strong password policies, multi-factor
- [ ] **Authorization**: Role-based access control
- [ ] **Secrets Management**: No secrets in code, environment variables
- [ ] **Dependencies**: Updated, no known vulnerabilities
- [ ] **Error Messages**: Don't expose sensitive information

---

## 7. Documentation

### Documentation Metrics

| Metric | Healthy | Unhealthy | Target |
|--------|----------|-----------|--------|
| **API Documentation** | Complete | Incomplete | Complete |
| **Code Comments** | Self-documenting | Over-commenting | Self-documenting |
| **README Coverage** | Complete | Missing | Complete |
| **Changelog** | Up-to-date | Outdated | Up-to-date |

### Documentation Checklist

- [ ] **README**: Project setup, installation, usage
- [ ] **API Docs**: Endpoints, parameters, responses, examples
- [ ] **Architecture Docs**: System design, modules, patterns
- [ ] **Deployment Docs**: How to deploy, environment variables
- [ ] **Contributing Guidelines**: Coding standards, PR process
- [ ] **Change Log**: Version history, breaking changes

---

## Code Health Dashboard

### Example Dashboard

```markdown
# Code Health Dashboard

## Overall Score: 72/100

### Breakdown

| Dimension | Score | Weight | Weighted Score |
|-----------|--------|--------|---------------|
| Code Quality | 75 | 20% | 15 |
| Maintainability | 68 | 25% | 17 |
| Test Coverage | 80 | 20% | 16 |
| Technical Debt | 70 | 15% | 10.5 |
| Performance | 75 | 10% | 7.5 |
| Security | 65 | 10% | 6.5 |

### Recommendations

1. **High Priority**
   - Reduce complexity in PaymentService (current CC: 25)
   - Add test coverage for EmailService (current: 30%)
   - Fix security vulnerabilities in User module (3 critical issues)

2. **Medium Priority**
   - Refactor OrderService to reduce debt
   - Update API documentation for new endpoints
   - Optimize database queries in Reports module

3. **Low Priority**
   - Improve code style consistency
   - Add inline comments for complex algorithms
   - Update README with latest deployment steps

### Trends

| Metric | Week 1 | Week 2 | Week 3 | Trend |
|--------|--------|--------|--------|-------|
| Overall Score | 68 | 70 | 72 | ↗ Improving |
| Test Coverage | 65% | 72% | 80% | ↗ Improving |
| Technical Debt | 25% | 20% | 15% | ↗ Improving |
| Security Score | 60 | 63 | 65 | ↗ Improving |
```

---

## Summary

Code health assessment covers:

**Dimensions:**
- Code quality (complexity, duplication, smells)
- Maintainability (MI index, coupling, cohesion)
- Test coverage (statements, branches, functions)
- Technical debt (design, code, test, documentation)
- Performance (response times, query speed)
- Security (vulnerabilities, compliance)
- Documentation (API docs, code comments, README)

**Metrics:**
- Overall health score (0-100)
- Dimension scores with weights
- Priority recommendations

**Tools:**
- SonarQube, CodeClimate (technical debt)
- Linters (ESLint, Flake8, RuboCop)
- Coverage tools (Jest, PyTest, PHPUnit)
- Security scanners (SAST, dependency checkers)

**Goal:**
- Maintain >70 overall health score
- Address critical issues first
- Track trends over time
- Continuously improve quality

Use code health assessment to track and improve codebase quality.
