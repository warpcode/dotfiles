---
applyTo: "tests/**,**/__tests__/**,**/*.spec.*,**/*.test.*"
description: "Testing patterns, assertion conventions, fixture management, and mock isolation."
---

# Testing Conventions & Quality Guidelines

## Test Structure & Naming

- **Given-When-Then**: Structure test blocks into distinct setup (Given), execution (When), and assertion (Then) phases.
- **Descriptive Names**: Test names must explicitly state the scenario and expected outcome (e.g. `it('should return 401 when auth token is missing')`).
- **Single Assertion Focus**: Each test should verify a single behavior or invariant.

## Mocking & Isolation

- **Mock External Boundaries Only**: Mock network requests, third-party APIs, database connections, and system clocks; avoid mocking internal domain logic.
- **Clean State**: Always reset mocks, stubs, and temporary test fixtures in `afterEach` or fixture teardowns.
- **Deterministic**: Tests must not rely on execution order or external environmental state.
