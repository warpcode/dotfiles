# Migration Hygiene & Zero-Downtime Schema Evolution

Guidelines for reviewing and authoring production-safe database migrations.

---

## 1. Zero-Downtime Migration Principles

### Expand and Contract Pattern
Never perform breaking schema changes (e.g. renaming a column or dropping a column) in a single deploy.

1. **Step 1 (Expand)**: Add the new column or table alongside the old one.
2. **Step 2 (Dual-Write)**: Update application code to write to both columns and read from the new one.
3. **Step 3 (Backfill)**: Run a background migration to backfill historical rows.
4. **Step 4 (Contract)**: Drop the old unused column in a subsequent release.

---

## 2. Locking & Table Availability

### High-Risk Operations
- Adding a `NOT NULL` column with a non-constant default value to a table with millions of rows (causes full table lock on older database versions).
- Creating indexes synchronously on large tables.

### Safe Practices
- In PostgreSQL: Use `CREATE INDEX CONCURRENTLY` for index additions.
- In MySQL: Verify `ALGORITHM=INPLACE, LOCK=NONE` support for online DDL.

---

## 3. Reversibility & Rollback Integrity

- Every `up()` migration MUST have an exact corresponding `down()` method.
- Never write destructive irreversible operations in `down()` (such as dropping unrelated tables).
- Verify migrations rollback cleanly in testing environments before deploying.

