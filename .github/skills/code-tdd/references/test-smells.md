# Test Smells & Anti-Patterns

Catalog of common testing anti-patterns and concrete remediation strategies.

---

## 1. Over-Mocking & Implementation Coupling

### The Smell
Mocking every collaborator and private method instead of exercising real code. The test tests *how* code is implemented rather than *what* it accomplishes. When refactoring internal implementation, the test breaks even if behavior is identical.

### Remediation
- Mock only at architectural boundaries (external HTTP APIs, payment gateways, email delivery, clock/time).
- Prefer using in-memory databases, real objects, or fake adapters over mock spies for internal services.

---

## 2. Tautological / Assertion-Free Tests

### The Smell
- Tests that execute code but make no assertions (`assert(true)` or zero assertions).
- Tests that configure a mock to return `X` and assert that the method returned `X` without testing logic.

### Remediation
- Assert on state changes, return values, or database state mutations.
- Delete zero-value assertion-free tests.

---

## 3. Brittle / Flaky Tests

### Common Causes
- **Order Dependency**: Test A mutates database state without rolling back, causing Test B to fail if run out of order.
- **Time Sensitivity**: Tests relying on `Date.now()` or `sleep()` instead of deterministic time freezing/mocking.
- **Race Conditions**: Asynchronous promises resolving without proper `await` in test runners.

### Remediation
- Use database transactions with automatic rollbacks (e.g. `RefreshDatabase`, transactional test runners).
- Freeze system clock in test setups (`Carbon::setTestNow()`, `vi.useFakeTimers()`).

---

## 4. Assertion Roulette

### The Smell
Tests containing multiple unlabelled assertions where a failure gives no diagnostic context on which assertion failed or why. When an assertion fails without an explanatory message or among multiple similar assertions, developers must inspect line numbers or attach a debugger to determine which invariant broke.

### Remediation
- Follow the **Single Concept per Test** rule: split unrelated assertions into focused, discrete test cases.
- Provide descriptive assertion messages explaining the failure context (e.g., `assert(user.isActive, "Expected user to be active after activation email verification")`).
- Use table-driven / parameterized tests to isolate discrete inputs and expected outputs with clear test case descriptions.

---

## 5. Leaky / Shared State Fixtures

### The Smell
Tests mutating shared global singletons, static class state, environment variables, or database records without isolated per-test teardown or transactional rollback. This introduces cross-test pollution and order-dependent test failures.

### Remediation
- Wrap database tests in per-test transactions with automatic rollback (`RefreshDatabase`, transactional test fixtures).
- Reset global singletons, static state, and environment overrides in `tearDown` / `afterEach` hooks.
- Use fresh dependency injection containers and in-memory test fixtures per test execution.
