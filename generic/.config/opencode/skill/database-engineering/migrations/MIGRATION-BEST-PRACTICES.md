# MIGRATION BEST PRACTICES

## OVERVIEW
Safe, repeatable database migrations are critical for zero-downtime deployments and data integrity.

## PRINCIPLES

### 1. Idempotency
**Definition**: Running migration multiple times produces same result.

**Example**:
```sql
-- GOOD: Idempotent CREATE TABLE IF NOT EXISTS
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

-- BAD: Not idempotent (fails on second run)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);
```

### 2. Backward Compatibility

**Definition**: New migrations don't break existing code.

**Best Practice**:
- Add new columns with default values
- Don't drop or rename existing columns
- Use additive changes only

**Example**:
```sql
-- GOOD: Add new column with default
ALTER TABLE users ADD COLUMN email VARCHAR(255) DEFAULT 'user@example.com';

-- BAD: Add required column (breaks existing code)
ALTER TABLE users ADD COLUMN email VARCHAR(255) NOT NULL;
```

### 3. Forward Compatibility
**Definition**: Migrations can run on any database state.

**Best Practice**:
- Check for column existence before altering
- Handle missing indexes gracefully

**Example**:
```sql
-- GOOD: Check before dropping
DO $$
BEGIN;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email') THEN
        ALTER TABLE users DROP COLUMN email;
    END IF;
END $;
```

---

## MIGRATION FRAMEWORKS

### Laravel Migrations

**Create Migration**:
```bash
php artisan make:migration add_email_to_users_table
```

**Migration File**:
```php
// database/migrations/2024_01_15_000000_add_email_to_users_table.php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

class AddEmailToUsersTable extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email', 255)->nullable();
            $table->index('email');
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('email');
            $table->dropIndex(['email']);
        });
    }
}
```

**Run Migration**:
```bash
php artisan migrate
```

**Rollback**:
```bash
php artisan migrate:rollback --step=1
```

### Django Migrations

**Create Migration**:
```bash
python manage.py makemigrations
```

**Migration File**:
```python
# migrations/0001_add_email.py
from django.db import migrations, models
import django.db.models.deletion

class Migration(migrations.Migration):
    dependencies = []

    operations = [
        migrations.AddField(
            model_name='user',
            name='email',
            field=models.EmailField(default='user@example.com', blank=True),
        ),
    ]
```

**Run Migration**:
```bash
python manage.py migrate
```

**Rollback**:
```bash
python manage.py migrate 0001
```

---

## ZERO-DOWNTIME MIGRATIONS

### 1. Expand-Contract Pattern

**Concept**: Add new column, populate, then enforce NOT NULL.

**Step 1: Add nullable column**
```sql
ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

**Step 2: Populate column**
```sql
UPDATE users SET email = CONCAT(name, '@example.com');
```

**Step 3: Make NOT NULL**
```sql
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
```

**Step 4: Add index (after population)**
```sql
CREATE INDEX idx_users_email ON users(email);
```

### 2. Use Default Values

**For new columns**:
```sql
ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'active';
```

**For existing data**:
```sql
-- Update existing rows with default if needed
UPDATE users SET status = 'inactive' WHERE created_at < '2024-01-01';
```

### 3. Avoid Locking Tables

**Use short transactions**:
```sql
BEGIN;
-- Add column
ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- Quick update (not on all rows)
UPDATE users SET email = CONCAT(name, '@example.com')
WHERE id <= 1000;  -- Batch updates

COMMIT;
```

**Create indexes before data**:
```sql
-- Create index BEFORE inserting data (avoid table scans)
CREATE INDEX idx_temp_email ON users(email);

-- Load data
INSERT INTO users ...;

-- Drop temporary index
DROP INDEX idx_temp_email;
```

---

## ROLLBACK STRATEGIES

### 1. Always Implement down()

**Critical**: Every migration must have rollback.

**Example**:
```php
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('email', 255);
    });
}

public function down()
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('email');
    });
}
```

### 2. Test Rollbacks in Development

**Procedure**:
```bash
# Run migration
php artisan migrate

# Test application

# If issues, rollback
php artisan migrate:rollback

# Fix migration
```

### 3. Keep Backups Before Major Migrations

```bash
# PostgreSQL
pg_dump dbname > backup_before_migration.sql

# MySQL
mysqldump -u user dbname > backup_before_migration.sql

# Laravel
php artisan backup:run
```

---

## MIGRATION BEST PRACTICES

### 1. Naming Conventions

**Format**: YYYY_MM_DD_HHMMSS_description

**Examples**:
```
2024_01_15_143022_add_email_to_users_table.php
2024_01_15_143023_add_status_enum_to_users.php
2024_01_15_143024_drop_users_table.php
```

### 2. Keep Migrations Small

**Guideline**: One logical change per migration.

**Good**:
```php
// Migration 1: Add column
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('email', 255);
    });
}

// Migration 2: Add index
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->index('email');
    });
}
```

**Bad**:
```php
// One migration does everything
public function up()
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('email', 255);
        $table->index('email');
        $table->string('status', 20);
        $table->enum('type', ['admin', 'user']);
        $table->dropColumn('old_column');
        // ... 50 more changes
    });
}
```

### 3. Review Migrations Before Committing

**Checklist**:
- [ ] up() method is idempotent
- [ ] down() method works correctly
- [ ] No production data loss in down()
- [ ] Tested in development environment
- [ ] Rollback tested
- [ ] Transaction used where appropriate
- [ ] Indexes added after data population
- [ ] Foreign key constraints defined

---

## MIGRATION TESTING

### 1. Test Migrations Locally

```bash
# Laravel: Run migration
php artisan migrate --force

# Django: Run migration
python manage.py migrate --fake-initial

# Verify database schema
php artisan db:show
python manage.py showmigrations
```

### 2. Test with Production Data Copy

```bash
# Copy production data locally
pg_dump prod_db | psql local_db

# Run migration
php artisan migrate

# Verify application works with migrated data
```

---

## CONTINUOUS DEPLOYMENT

### 1. Blue-Green Deployment with Migrations

**Strategy**: Deploy to green, run migrations, switch traffic.

```bash
# 1. Deploy new code to green
kubectl set image deployment/green myapp:latest

# 2. Run migrations on green
php artisan migrate --env=production --database=green

# 3. Test green environment
curl https://green.example.com/health

# 4. Switch traffic to green
kubectl patch service myapp -p '{"spec":{"selector":{"app":"myapp"},"template":{"spec":{"containers":[{"name":"myapp","image":"myapp:latest"}]}}}'

# 5. Run migrations on blue (prepare for next time)
php artisan migrate --env=production --database=blue
```

### 2. Rollback in Case of Failure

```bash
# If green fails, rollback immediately
kubectl patch service myapp -p '{"spec":{"selector":{"app":"myapp"},"template":{"spec":{"containers":[{"name":"myapp","image":"myapp:old"}]}}}'
```

---

## CROSS-REFERENCES
- For database design: @design/DATABASE-DESIGN.md
- For SQL injection: @relational/SQL-INJECTION.md
- For indexing: @relational/INDEXING.md
- For connection patterns: @connections/CONNECTION-PATTERNS.md
