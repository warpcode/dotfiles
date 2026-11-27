---
name: database-architecture
description: >
  Discover and document data models, inspect ORM patterns (Eloquent, Prisma,
  TypeORM, SQLAlchemy, GORM), generate Entity-Relationship Diagrams (ERDs),
  and verify schema migration hygiene. Use when reverse-engineering database
  schemas, authoring migrations, or mapping entity relationships.
---

# Database Architecture Knowledge Centre

Reference hub for data model discovery, ORM conventions, Entity-Relationship Diagram (ERD) modeling, and zero-downtime migration safety.

## When to Use

- Reverse-engineering database schemas, model mappings, and secondary search index sync across an unfamiliar codebase.
- Auditing ORM data-access patterns (Eloquent, Prisma, TypeORM, SQLAlchemy, GORM) and relationship definitions (`1:1`, `1:N`, `N:M`, polymorphic).
- Designing or reviewing schema migrations for reversibility, table locks, concurrent index creation, and foreign-key cascades.
- Generating Mermaid ERDs and entity catalogs.

## Domain Knowledge Index

| Topic | Resource | Use When |
|---|---|---|
| ORM patterns & model discovery | `@references/orm-patterns.md` | Auditing ORM entity mappings, relationships, and secondary search datastore sync |
| ERD modeling & conventions | `@references/erd-generation.md` | Generating Mermaid `erDiagram` graphs with accurate cardinality notation |
| Migration safety & DDL hygiene | `@references/migration-hygiene.md` | Reviewing migrations for `down()` reversibility, lock hazards, concurrent indexes, and cascades |

## Report Template

| Template | Path | Use When |
|---|---|---|
| Schema & ERD report | `@templates/schema-erd-report.md` | Documenting ORM/driver overview, Mermaid ERD, and entity catalog |
