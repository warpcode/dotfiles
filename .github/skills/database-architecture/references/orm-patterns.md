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

