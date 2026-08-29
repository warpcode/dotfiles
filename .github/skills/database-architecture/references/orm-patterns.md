# ORM Pattern & Model Discovery

Reference guide for locating and cataloging data models across major ORM frameworks.

---

## 1. ORM Detection Matrix

| Framework / Ecosystem | Primary Manifest Indicator | Default Model Location | Base Class / Decorator |
|---|---|---|---|
| **Laravel (PHP)** | `composer.json` (`laravel/framework`) | `app/Models/` or `app/` | `extends Model` |
| **Prisma (TypeScript)** | `prisma/schema.prisma` | Generated client | `model Name { ... }` |
| **TypeORM (TypeScript)** | `package.json` (`typeorm`) | `src/entities/` | `@Entity()` |
| **Django (Python)** | `requirements.txt` / `pyproject.toml` | `*/models.py` | `extends models.Model` |
| **SQLAlchemy (Python)** | `requirements.txt` (`sqlalchemy`) | `models/` or `db/` | `Base = declarative_base()` |
| **GORM (Go)** | `go.mod` (`gorm.io/gorm`) | `models/` or `entity/` | `gorm.Model` struct embedding |

---

## 2. Model Discovery Procedure

1. **Locate Schema / Configuration**:
   - Check `config/database.php`, `schema.prisma`, `ormconfig.json`, or `.env` for database connection settings and driver.
2. **Find Model Base Classes**:
   - Grep for `extends Model`, `@Entity`, or `Base = declarative_base()`.
3. **Inventory All Entities**:
   - List all files inheriting from the base model to produce a complete list of application domain entities.

---

## 3. Secondary Datastores & Search Index Mapping

When applications leverage dedicated search engines (Elasticsearch, OpenSearch, Meilisearch, Algolia) or secondary read-models:

1. **Search Driver & Engine Identification**:
   - Identify packages/libraries managing search sync (e.g., `laravel/scout`, `@elastic/elasticsearch`, `django-haystack`, `searchkick`).
   - Check connection configuration (`config/scout.php`, `.env`, index settings).

2. **Model-to-Index Mapping**:
   - **Index Naming**: Locate index identifier hooks (e.g., `searchableAs()` in Laravel Scout, `__tablename__` overrides, or `@Searchable(index="...")`).
   - **Search Payload Schema**: Inspect data transformation methods (e.g., `toSearchableArray()`, custom serializer, or DTO transformers) determining which fields and relations are indexed.
   - **Index Schema & Settings**: Locate mapping definitions, tokenizers, stop words, and filter configurations (e.g. Meilisearch filterable/sortable attributes, Elasticsearch analyzer mappings).

---

## 4. Event-Driven Search Synchronization

Search indices must remain synchronized with primary datastore writes:

1. **Lifecycle Hooks & Observers**:
   - Trace ORM lifecycle events (`saved`, `created`, `updated`, `deleted`, `restored`, `forceDeleted`, or equivalent ORM post-commit hooks like Django `post_save`/`post_delete`, Prisma middleware / extensions).
   - Verify if synchronization hooks are attached via model traits (e.g. `Searchable`), model observers, or event subscribers.

2. **Asynchronous Queue Dispatching**:
   - Audit whether indexing operations execute synchronously (blocking database transactions/HTTP requests) or asynchronously via background workers/queue jobs (e.g., `MakeSearchable`, `RemoveFromSearch`).
   - Check transaction safety: Ensure search sync jobs are dispatched *after* database transactions commit (`afterCommit` callbacks / queue connection settings) to prevent indexing stale or uncommitted state.

