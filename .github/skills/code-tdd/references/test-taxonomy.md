# Test Taxonomy & Boundary Design

Guide for structuring test pyramids, isolation levels, and boundary assertions.

---

## The Testing Pyramid

```
       / \
      / E2E \       <-- High confidence, slow execution, test critical user flows only
     /-------\
    /  Integ  \     <-- Test DB queries, API endpoints, and service integrations
   /-----------\
  /    Unit     \   <-- Pure logic, fast execution, broad edge-case coverage
 /---------------\
```

---

## 1. Unit Tests
- **Scope**: Single class, function, or domain value object in isolation.
- **Speed**: Milliseconds per test.
- **External Dependencies**: Zero I/O; no filesystem or network calls.
- **Goal**: Exhaustive coverage of domain business rules, edge cases, and calculations.

---

## 2. Integration Tests
- **Scope**: Interaction between application services, database repositories, and HTTP endpoints.
- **Speed**: Tens to hundreds of milliseconds.
- **External Dependencies**: Local test database (in-memory or transactional SQLite/PostgreSQL/MySQL), local cache.
- **Goal**: Verify routing, middleware execution, validation rules, and database schema compatibility.

---

## 3. End-to-End (E2E) Tests
- **Scope**: Full browser automation testing end-to-end user journeys (Playwright, Cypress).
- **Speed**: Seconds per test.
- **External Dependencies**: Full running application stack.
- **Goal**: Verify critical revenue-generating paths (authentication, checkout, core workflow completion).

---

## 4. Gerard Meszaros Test Doubles Taxonomy & Decision Matrix

When replacing real collaborators in tests, select the simplest double that satisfies the test condition:

| Double Type | Description | Inspection / Behavior | Typical Use Case |
|-------------|-------------|-----------------------|------------------|
| **Dummy** | Passed only to fill parameter signatures; never inspected or invoked. | Throws if called or does nothing. | Satisfying mandatory constructor/method arguments that are irrelevant to the scenario under test. |
| **Stub** | Provides canned answers to calls made during test execution. | Responds with predetermined return values or exceptions. | Providing fixed input or simulated error states to the system under test (SUT). |
| **Spy** | Wraps real/collaborator objects to record invocations, arguments, and call counts. | Records call telemetry; can delegate to real implementation. | Verifying indirect outputs or side-effect counts without pre-configuring strict mock expectations. |
| **Fake** | Lightweight working in-memory implementation. | Implements business contracts with simplified in-memory logic. | In-memory SQLite/repositories, fake mailers, fake file systems, in-memory caches. |
| **Mock** | Pre-programmed with expectations about interactions; verifies method calls and order. | Fails fast or on verification if unexpected calls occur. | Verifying protocol interactions at strict architectural or system boundaries. |

### Decision Matrix & Core Principle

> **Core Principle: Prefer Fakes / In-Memory Adapters over Mocks.**
> Mock strictly at true architectural/network I/O boundaries (external third-party APIs, payment gateways, hardware devices, email gateways).

- **Choose a Fake** when a collaborator has state or logic that multiple components interact with during a test (e.g. repository, cache, queue). Fakes survive refactorings without changing test assertions.
- **Choose a Stub** when the SUT needs specific canned data or error conditions to trigger an internal code branch.
- **Choose a Dummy** when fulfilling method parameters where the collaborator is never exercised.
- **Choose a Spy** when asserting that a side-effect (e.g. event emitted, metric logged) occurred without coupling to strict mock verification.
- **Choose a Mock** only when verifying the precise sequence or protocol of outbound communications across external system boundaries.
