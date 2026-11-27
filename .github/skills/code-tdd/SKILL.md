---
name: code-tdd
description: >
  Apply Test-Driven Development (TDD) principles, red-green-refactor cycles,
  bug reproduction regression testing, test suite auditing, and mock hygiene.
  Use when implementing new features with tests, reproducing and fixing bugs
  with regression test coverage, or refactoring fragile test suites.
---

# Test-Driven Development (TDD) Knowledge Centre

Reference hub for disciplined Red-Green-Refactor development, regression-first bug fixing, test taxonomy design, and test suite hygiene.

## When to Use

- Implementing new domain logic or features test-first via Red-Green-Refactor.
- Reproducing reported defects with a failing regression test prior to applying a fix.
- Auditing test suites for brittle assertions, over-mocking, slow execution, or shared state.
- Choosing between unit, integration, and end-to-end test boundaries.

## Core Principles

- **Red-Green-Refactor**: Write a minimal failing test specifying the contract, implement the simplest passing code, then refactor while keeping tests green.
- **Regression-First Bug Fixes**: Isolate boundary conditions, write a test that reproduces the failure before editing production code, then verify the surgical fix turns the suite green.
- **Suite Hygiene**: Mock only at system/I/O boundaries, keep tests deterministic and isolated from shared state, and remove tautological assertions.
- **Mutation Coverage**: For verifying that assertions actually catch branch mutations on diffs, consult `code-review` (`code-review/references/test-and-mutation-verification.md`).

## Domain Knowledge Index

| Topic | Resource | Use When |
|---|---|---|
| Bug reproduction & regression protocol | `@references/regression-protocol.md` | Fixing bugs with reproducing tests before applying production changes |
| Test smells & anti-patterns | `@references/test-smells.md` | Auditing brittle mocks, tautological assertions, or order-dependent state |
| Test taxonomy & boundaries | `@references/test-taxonomy.md` | Structuring unit, integration, and end-to-end test layers |
