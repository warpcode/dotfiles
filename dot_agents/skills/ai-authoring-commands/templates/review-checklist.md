---
description: Review changes against target branch with structured checklist
argument-hint: "[target-branch]"
allowed-tools: gh, git, view_file, grep_search
model: sonnet
---

# Code Review Directive

You are executing a rigorous, checklist-driven code review on branch changes against `${1:-main}`.

## Context
Target branch diff:
!`git diff ${1:-main}...HEAD`

## Review Directives
Review the changes against repository standards and check off each item:
- [ ] 1. **Security**: Scan for hardcoded credentials, secret leaks, and unescaped shell inputs.
- [ ] 2. **Correctness & Edge Cases**: Verify boundary conditions, nil/null safety, and error handling.
- [ ] 3. **Performance**: Check for unbounded loops, N+1 queries, or inefficient memory allocations.
- [ ] 4. **Testing**: Ensure all modified or new execution paths have corresponding unit tests.

## Output Format
Generate a structured Markdown summary categorized by severity:
- 🚨 **[CRITICAL]**: Security vulnerability or breaking bug (blocks merge).
- ⚠️ **[WARNING]**: Architecture, performance, or error-handling defect.
- 💡 **[SUGGESTION]**: Non-blocking optimization or style improvement.
