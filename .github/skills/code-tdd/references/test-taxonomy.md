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

