# OUTPUT FORMAT: SEVERITY CLASSIFICATION

## PURPOSE
Define severity hierarchy for Review/Check/Validate mode output.

## SEVERITY LEVELS (CRITICAL → LOW)

### CRITICAL
- **Definition**: Immediate action required. System failure, security breach, data loss.
- **Examples**:
  - SQL injection vulnerabilities
  - Password stored in plaintext
  - Authentication bypass
  - Data exposure (credentials, tokens)
  - System crash / data corruption
- **Action**: Fix immediately before deployment
- **Priority**: 1

### HIGH
- **Definition**: Significant issue. Performance degradation, security weakness, major bug.
- **Examples**:
  - Missing authentication on sensitive endpoints
  - N+1 query performance issues
  - Memory leaks
  - Broken error handling
  - Inefficient algorithms
- **Action**: Fix as soon as possible
- **Priority**: 2

### MEDIUM
- **Definition**: Moderate issue. Code quality, maintainability, minor bugs.
- **Examples**:
  - Inconsistent coding style
  - Unused code / dead code
  - Missing error messages
  - Inefficient but functional code
  - Insufficient test coverage
- **Action**: Fix in next iteration
- **Priority**: 3

### LOW
- **Definition**: Minor issue. Documentation, naming conventions, edge cases.
- **Examples**:
  - Poor variable/function names
  - Missing inline comments (complex logic)
  - Inconsistent whitespace
  - Minor typos in docs
  - Rare edge case bugs
- **Action**: Fix when convenient
- **Priority**: 4

## OUTPUT FORMAT REQUIREMENTS

### Structure
```markdown
**Summary**: [PASS/FAIL/PARTIAL] - [Overall assessment]

### Critical Issues: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### High Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Medium Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Low Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

**Recommendations**: [Descriptive corrections only, NO implementations]
```

### Rules
- **Ordering**: Issues MUST be sorted by severity (CRITICAL first, then HIGH, MEDIUM, LOW)
- **Formatting**: Each issue MUST include:
  - File location: `file:line` format
  - Description: Concise, clear issue description
  - Impact: Explanation of why this is a problem
- **Recommendations**: MUST be descriptive only (what to fix), NOT implementation code (how to fix)
- **Counts**: MUST display issue count for each severity level

### Validation
- [ ] Severity hierarchy respected (CRITICAL → HIGH → MEDIUM → LOW)
- [ ] All issues include location + description + impact
- [ ] No implementation code provided
- [ ] Recommendations descriptive only
- [ ] Counts displayed for each severity level
- [ ] Summary accurately reflects overall assessment

## IMPACT ASSESSMENT GUIDELINES

### What to Include in Impact Section
- **Why is this a problem?**: Explain the risk or issue
- **What could happen?**: Potential consequences
- **Who is affected?**: Users, systems, data
- **When is it critical?**: Deployment scenarios, use cases

### Impact Examples
- **Critical**: "Allows attackers to exfiltrate all user data via SQL injection. Immediate security breach."
- **High**: "Database query returns 10,000 rows but only 1 needed. Performance degradation under load."
- **Medium**: "Function is 200 lines long, making it hard to test and maintain. Code quality issue."
- **Low**: "Variable name `$x` provides no context about purpose. Readability issue."
