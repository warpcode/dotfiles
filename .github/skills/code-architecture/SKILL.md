---
name: code-architecture
description: >
  Map application topology, discover routing and middleware chains, inspect
  clean architecture layers (SOLID, GoF patterns, WCAG UI accessibility), and purge
  dead code or complexity smells. Use when reverse-engineering unfamiliar codebases,
  structuring new modules, reviewing architectural boundaries, auditing emptied
  files before deletion, or refactoring legacy code.
---

# Code Architecture & Design Knowledge Centre

Reference hub for application topology, route/middleware pipelines, clean architectural boundaries, accessible frontend components, complexity reduction, and dead-code audits.

## When to Use

- Mapping unfamiliar codebase entrypoints, monorepo trees, and rendering strategies (SPA/SSR).
- Auditing HTTP routes, canonical middleware order, and OpenAPI/Swagger contract alignment.
- Evaluating SOLID layering (Presentation, Application, Domain, Infrastructure) and GoF design patterns.
- Auditing frontend HTTP client wrappers, UI compound components, and WCAG 2.1 Level AA accessibility.
- Detecting Fowler code smells, reducing cyclomatic/cognitive complexity, or verifying whether emptied/refactored files can be safely deleted.

## Domain Knowledge Index

| Topic | Resource | Use When |
|---|---|---|
| Routing & middleware pipelines | `@references/routing-and-controllers.md` | Discovering entrypoints, route manifests, and middleware execution order |
| API contracts & OpenAPI | `@references/api-contracts-openapi.md` | Detecting contract drift, undocumented endpoints, and breaking schema changes |
| Clean layers & SOLID | `@references/clean-layers-and-solid.md` | Auditing Presentation/Application/Domain/Infrastructure boundaries and leaky abstractions |
| Design patterns | `@references/design-patterns.md` | Selecting or reviewing Factory, Builder, Adapter, Decorator, Strategy, Observer, or Command patterns |
| Frontend accessibility | `@references/accessibility-wcag.md` | Auditing UI compound components and WCAG 2.1 AA compliance |
| Code smells & complexity | `@references/code-smells-and-complexity.md` | Identifying Fowler smells and flattening deep nesting with guard clauses or table-driven dispatch |
| Dead code & file lifecycle | `@references/dead-code-and-refactoring.md` | Auditing unreferenced symbols and verifying static/dynamic references on emptied or refactored files |

## Report Template

| Template | Path | Use When |
|---|---|---|
| Application topology report | `@templates/architecture-topology-report.md` | Summarizing framework/runtime, module layer diagram, boundary violations, and dead-code candidates |
