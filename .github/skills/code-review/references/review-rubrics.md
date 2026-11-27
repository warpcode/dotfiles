# Code Review Rubrics

Canonical defect prioritization hierarchy for code reviews.

---

## 1. Audit Prioritization Hierarchy

Evaluate changes systematically in descending priority order:

1. **Bugs and functional correctness** (logic errors, race conditions, boundary failures, nil/null handling).
2. **Security issues** (injection, SSRF, auth/authz bypasses, secret leakage, unsafe deserialization — pair with `code-security-audit`).
3. **Leftover test/debug code and test data** (debug prints, `set -x`, commented-out blocks, hardcoded dummy values, stray fixture files, auth/validation bypasses in production paths).
4. **Style guideline violations** (load language-specific instruction/style skills where applicable).
5. **Performance and efficiency** (N+1 queries, unbounded reads, redundant subprocess calls, hot-path allocations).
6. **Readability and maintainability** (excessive nesting, duplicated logic, unclear naming).
7. **Anti-patterns and duplication** (reimplementing existing repo helpers or diverging from established abstractions).
8. **Project convention consistency** (flag standardization, error formatting, config layering).
9. **Issue requirement compliance** (completeness against source ticket acceptance criteria and edge cases).
10. **Unresolved PR comments and review questions** (open threads from earlier review rounds).

---

## 2. Related Verification References

- **Premise validity, supersession, optional issue ACs & diff integrity**: `references/premise-and-diff-scrutiny.md`
- **Test-only diffs, mutation verification & CI discovery auditing**: `references/test-and-mutation-verification.md`
- **Benchmark baseline & performance-claim reproduction**: `code-performance/references/benchmark-verification.md`
