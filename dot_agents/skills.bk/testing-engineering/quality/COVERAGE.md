# Coverage

## Overview

Comprehensive guide to test coverage metrics, thresholds, and tools. Coverage measures how much of your code is executed during tests.

---

## Coverage Metrics

### Statement Coverage

Percentage of executable statements executed.

**Example:**
```javascript
function calculateDiscount(price, isPremium) {
    if (isPremium) {
        return price * 0.8;  // Statement 1
    } else {
        return price;  // Statement 2
    }
}

// Test 1: calculateDiscount(100, true) → 80
// Executes: Statement 1
// Statement Coverage: 50% (1 of 2 statements)
```

### Branch Coverage

Percentage of conditional branches executed (both true and false paths).

**Example:**
```javascript
function calculateDiscount(price, isPremium) {
    if (isPremium) {  // Branch 1
        return price * 0.8;
    } else {
        return price;
    }
}

// Test 1: calculateDiscount(100, true) → 80
// Executes: true path (Branch 1 = true)
// Branch Coverage: 50% (only true path tested)

// Test 2: calculateDiscount(100, false) → 100
// Executes: false path (Branch 1 = false)
// Branch Coverage: 100% (both paths tested)
```

### Function Coverage

Percentage of functions/methods called during tests.

**Example:**
```javascript
class Calculator {
    add(a, b) { return a + b; }
    subtract(a, b) { return a - b; }
    multiply(a, b) { return a * b; }
    divide(a, b) { return a / b; }
}

// Tests only add and subtract
// Function Coverage: 50% (2 of 4 functions tested)
```

### Line Coverage

Percentage of executable lines executed (similar to statement coverage).

---

## Coverage Goals

### Recommended Thresholds

| Metric | Minimum | Good | Excellent |
|--------|----------|-------|------------|
| Statement Coverage | 70% | 80% | 90%+ |
| Branch Coverage | 60% | 75% | 85%+ |
| Function Coverage | 80% | 90% | 95%+ |
| Line Coverage | 70% | 80% | 90%+ |

### By Layer

| Layer | Target | Rationale |
|--------|---------|------------|
| Critical Code (security, payment) | 90%+ | High risk, needs thorough testing |
| Business Logic | 80-85% | Complex logic needs coverage |
| UI/Components | 70-75% | Testing is expensive, some uncovered OK |
| Configuration | 50-60% | Simple, low-risk code |
| Utilities | 85-90% | Reused across codebase |

---

## Coverage Tools

### JavaScript (Jest)

**Generate Coverage:**
```bash
npm test -- --coverage
```

**Configuration (jest.config.js):**
```javascript
module.exports = {
    collectCoverage: true,
    collectCoverageFrom: [
        'src/**/*.{js,jsx}',
        '!src/**/*.test.{js,jsx}',
        '!src/config/**',
        '!src/server.js',
    ],
    coverageThreshold: {
        global: {
            branches: 75,
            functions: 80,
            lines: 80,
            statements: 80,
        },
    },
    coverageReporters: [
        'text',
        'html',
        'lcov',
    ],
};
```

**Output Reports:**
- `coverage/lcov-report/index.html` - Interactive HTML report
- `coverage/lcov.info` - LCOV format
- `coverage/coverage-final.json` - JSON format

**Read Reports:**
```bash
# View HTML report
open coverage/lcov-report/index.html

# Generate summary
npx coverage-report-merger
```

### Python (PyTest + Coverage.py)

**Generate Coverage:**
```bash
pytest --cov=src --cov-report=html --cov-report=term
```

**Configuration (pyproject.toml):**
```toml
[tool.pytest.ini_options]
addopts = [
    "--cov=src",
    "--cov-report=html",
    "--cov-report=term-missing",
    "--cov-report=lcov",
]

[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/migrations/*",
    "*/config/*",
]

[tool.coverage.report]
precision = 2
show_missing = true

[tool.coverage.html]
directory = "htmlcov"

[tool.coverage.lcov]
output = "lcov.info"
```

**Output Reports:**
- `htmlcov/index.html` - Interactive HTML report
- `lcov.info` - LCOV format
- `coverage.xml` - Cobertura format

**Read Reports:**
```bash
# View HTML report
open htmlcov/index.html

# Generate summary
coverage report
```

### PHP (PHPUnit)

**Generate Coverage:**
```bash
./vendor/bin/phpunit --coverage-html coverage
./vendor/bin/phpunit --coverage-clover coverage.xml
```

**Configuration (phpunit.xml):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit ...>
    <coverage processUncoveredFiles="true">
        <include>
            <directory suffix=".php">src</directory>
        </include>
        <exclude>
            <directory>vendor</directory>
            <directory>tests</directory>
            <directory>config</directory>
        </exclude>
        <report>
            <html outputDirectory="coverage/html"/>
            <clover outputFile="coverage/clover.xml"/>
            <text outputFile="coverage/coverage.txt"/>
        </report>
    </coverage>

    <logging>
        <junit outputFile="test-results/junit.xml"/>
    </logging>
</phpunit>
```

**Output Reports:**
- `coverage/html/index.html` - Interactive HTML report
- `coverage/clover.xml` - Clover format
- `coverage/coverage.txt` - Text summary

### Ruby (RSpec)

**Generate Coverage:**
```bash
rspec --format documentation --format RspecJunitFormatter --out results.xml
COVERAGE=true bundle exec rspec
```

**Configuration (.simplecov):**
```ruby
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'

  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Services', 'app/services'

  minimum_coverage 80
  minimum_coverage_by_file 70
  refuse_coverage_drop 5
end
```

**Output Reports:**
- `coverage/index.html` - Interactive HTML report

---

## Interpreting Coverage Reports

### HTML Reports

View interactive report to identify:
- **Red files**: < 80% coverage
- **Yellow files**: 80-90% coverage
- **Green files**: > 90% coverage
- **Uncovered lines**: Marked in red

### Line-by-Line Analysis

```javascript
function processOrder(order) {
    // ✅ Covered
    if (order.items.length === 0) {
        return { error: 'Empty cart' };
    }

    // ❌ Uncovered - No test for this case
    if (order.total > 10000) {
        return { error: 'Order too large' };
    }

    // ✅ Covered
    return { success: true, order };
}
```

### Branch Coverage View

```javascript
function calculateTax(price, country) {
    // Branch 1: country === 'US'
    if (country === 'US') {
        // Branch 1 = true
        return price * 0.08;  // ✅ Covered
    }

    // Branch 1 = false
    if (country === 'UK') {
        // Branch 2 = true (uncovered!)
        return price * 0.20;  // ❌ Uncovered
    }

    // Branch 2 = false
    return price * 0.0;  // ✅ Covered
}

// Branch Coverage: 66% (2 of 3 branches)
// Missing: country === 'UK' case
```

---

## Coverage Anti-Patterns

### ❌ "The Coverage Chaser" - Writing Tests Just for Coverage

```javascript
// Bad - Test only for coverage
it('should handle null input', () => {
    // This test exists only to increase coverage
    expect(calculateTotal(null)).toBe(0);
    // But what does "handle null" actually mean?
    // Is this the expected behavior?
});
```

**Fix:** Write meaningful tests based on requirements, not coverage.

```javascript
// Good - Test based on requirements
it('should return 0 for empty array', () => {
    expect(calculateTotal([])).toBe(0);
});

it('should throw error for null input', () => {
    expect(() => calculateTotal(null))
        .toThrow('Invalid input: items cannot be null');
});
```

### ❌ "The 100% Obsession" - Chasing 100% Coverage

```javascript
// Bad - Testing trivial code just for 100%
it('should return 0 for 0', () => {
    expect(Math.max(0, 0)).toBe(0);
});

it('should return 5 for Math.max(5, 0)', () => {
    expect(Math.max(5, 0)).toBe(5);
});
```

**Fix:** Focus on meaningful code, not 100%.

```javascript
// Good - Test complex logic, ignore trivial code
it('should calculate total with discounts', () => {
    const items = [
        { price: 100, category: 'electronics' },  // 10% discount
        { price: 50, category: 'books' }         // 5% discount
    ];
    expect(calculateTotal(items)).toBe(136.5);  // (100*0.9) + (50*0.95)
});
```

### ❌ "The False Confidence" - High Coverage, Low Quality

```javascript
// 100% coverage but 0% confidence
it('should do something', () => {
    const result = myFunction();

    // No assertion - just calling function for coverage!
    // 100% coverage, but what are we testing?
});
```

**Fix:** Always verify results.

```javascript
// Good - Verifies behavior
it('should return correct result', () => {
    const result = myFunction();

    expect(result).toEqual(expected);
    expect(result).toHaveProperty('id');
});
```

### ❌ "The Unreachable Code" - Coverage Masking Dead Code

```javascript
function process(data) {
    if (data === null) {
        return null;
    }

    // ❌ Unreachable code (always returns above)
    return process(data);  // Infinite recursion!
    // But tests with null = 100% coverage!
}
```

**Fix:** Remove or fix unreachable code.

```javascript
function process(data) {
    if (data === null) {
        return null;
    }

    return transform(data);  // Real implementation
}
```

---

## Coverage by File Type

### What to Cover

| File Type | Coverage Target | Rationale |
|----------|-----------------|------------|
| **Business Logic** | 85-90% | Complex, high-value code |
| **API Endpoints** | 70-80% | Test validation, responses |
| **Controllers** | 70-80% | Route handling, errors |
| **Services** | 85-90% | Business rules |
| **Models** | 60-70% | Simple CRUD, some edge cases OK |
| **Migrations** | 0% | Not testable |
| **Config Files** | 0% | No logic to test |
| **Routes** | 50-60% | Route definitions |
| **Middleware** | 75-85% | Security, logging |
| **Utilities** | 80-90% | Reused functions |

### What to Exclude

```javascript
// Exclude from coverage
{
    collectCoverageFrom: [
        'src/**/*.{js,jsx}',
        '!src/**/*.test.{js,jsx}',  // Test files
        '!src/config/**',            // Config files
        '!src/migrations/**',        // Migrations
        '!src/types/**',             // Type definitions
        '!src/server.js',           // Entry point
        '!src/**/*.d.ts',           // Definition files
    ],
}
```

---

## Coverage in CI/CD

### Enforce Coverage Thresholds

**GitHub Actions (JavaScript):**
```yaml
- name: Run tests with coverage
  run: npm test -- --coverage

- name: Check coverage
  run: |
    if [ $(cat coverage/coverage-summary.json | jq '.total.lines.pct') -lt 80 ]; then
      echo "Coverage below 80%"
      exit 1
    fi
```

**GitHub Actions (Python):**
```yaml
- name: Run tests with coverage
  run: pytest --cov=src --cov-fail-under=80
```

**GitLab CI:**
```yaml
test:
  script:
    - pytest --cov=src --cov-report=xml --cov-report=html
  coverage: '/(?i)^total.*? (100(?:\.0+)?\s*)$/'
  artifacts:
    paths:
      - htmlcov/
```

### Coverage Badges

**README.md:**
```markdown
![Coverage](https://img.shields.io/badge/coverage-85%25-brightgreen.svg)
```

---

## Summary

Coverage measures code execution during tests:

**Metrics:**
- **Statement**: Executable statements
- **Branch**: Conditional branches (true/false)
- **Function**: Functions/methods called
- **Line**: Executable lines

**Targets:**
- Critical code: 90%+
- Business logic: 80-85%
- UI/Components: 70-75%
- Configuration: 50-60%

**Tools:**
- JavaScript: Jest, Istanbul
- Python: PyTest + Coverage.py
- PHP: PHPUnit
- Ruby: RSpec + SimpleCov

**Anti-Patterns to Avoid:**
- Coverage chasing (tests only for coverage)
- 100% obsession (trivial tests)
- False confidence (no assertions)
- Unreachable code (masking dead code)

**Use Coverage Wisely:**
- Aim for 80% target, not 100%
- Focus on meaningful tests, not coverage
- Test critical paths thoroughly
- Exclude non-testable code (config, migrations)

Use coverage as a guide, not the goal.
