---
applyTo: "**/*.ts,**/*.tsx,**/*.js"
description: "TypeScript and modern JavaScript coding conventions, strict typing, and error handling."
---

# TypeScript & JavaScript Standards

## Type Safety & Modern Syntax

- **Strict Typing**: Enforce `strict: true`. Avoid `any`; use `unknown` with runtime type narrowing or generic parameters.
- **Explicit Returns**: Always declare return types on exported functions and public class methods.
- **Immutability**: Prefer `const` over `let`; avoid `var`. Use `readonly` arrays and properties where data is immutable.

## Error Handling

- **Custom Error Hierarchies**: Extend standard `Error` classes with descriptive error codes and HTTP status mapping where applicable.
- **Fail Early**: Validate preconditions and inputs at boundaries before executing core business logic.
- **No Unhandled Rejections**: Always handle or propagate Promises with explicit `try/catch` or typed result tuples `[Result, Error]`.

## Modular Organization

- Collocate unit tests next to source files using `*.spec.ts` or `*.test.ts`.
- Group related domain logic in cohesive directories rather than flat monolithic utility files.
