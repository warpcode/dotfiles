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

