# Ticket Formatting & Acceptance Criteria Guidelines

Reference guide for authoring unambiguous tickets, issues, and acceptance criteria.

---

## 1. Acceptance Criteria: Given-When-Then (Gherkin) Structure

Always write Acceptance Criteria using the deterministic Given-When-Then structure:

- **Given**: Initial state or prerequisite condition.
- **When**: Action performed by user or external event.
- **Then**: Measurable, observable system result.

### Example: User Registration
```markdown
- [ ] **AC 1 (Happy Path)**:
  - **Given** an unregistered visitor on the registration page,
  - **When** they submit a valid email, strong password, and name,
  - **Then** a user account is created, a verification email is dispatched, and they are redirected to the onboarding wizard.

- [ ] **AC 2 (Duplicate Email)**:
  - **Given** an existing registered user with email `user@example.com`,
  - **When** a visitor attempts to register with `user@example.com`,
  - **Then** registration is rejected with HTTP 422 ("Email is already registered") and no account is created.
```

---

## 2. Issue Quality Checklist

Before finalizing a ticket, verify:
- [ ] Does the description avoid vague phrases like "make it work properly" or "fix UI"?
- [ ] Are error states, validation rules, and empty states explicitly specified?
- [ ] Are necessary API route signatures, payload structures, or mockups linked?
- [ ] Is the scope constrained enough to be delivered within a single pull request?

