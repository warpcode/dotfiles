---
description: Scaffold a new component or module with tests
argument-hint: "<component-name> <layer> [description]"
allowed-tools: file_read, file_write, run_command
---

# Scaffold Directive: $1 ($2)

Generate a new `$2` component named `$1`.

## Parameters
- **Component Name**: `$1`
- **Architectural Layer**: `$2`
- **Specification / Details**: `$3`

## Instructions
1. Inspect neighboring implementations in `@src/$2/` for local conventions and naming patterns.
2. Implement the component in `@src/$2/$1.ts`.
3. Create corresponding unit tests in `@tests/$2/$1.test.ts`.
4. Run the test suite:
   !`npm test`
5. Report the created files and test results back to the user.
