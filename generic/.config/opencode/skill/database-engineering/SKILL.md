---
name: database-engineering
description: >-
  Domain specialist for data persistence, database design, query optimization, and data modeling. Expertise includes SQL injection prevention, indexing strategies, normalization, migrations, scaling (sharding, replication), backup/recovery, ORM patterns (Eloquent, Django), N+1 query detection, query optimization, relationship mapping, and model discovery. Use when: database questions, query optimization, schema design, indexing, migrations, sharding, replication, backup/recovery, ORM usage, N+1 queries, relationship management. Triggers: "database", "SQL", "query", "index", "schema", "migration", "sharding", "replication", "backup", "N+1", "ORM", "Eloquent", "Django", "query optimization", "slow query", "relationship", "foreign key", "join".
---

# DATABASE_ENGINEERING

## DOMAIN EXPERTISE
- **Common Attacks**: SQL injection (union-based, boolean-based, blind), NoSQL injection, privilege escalation, data exfiltration
- **Common Issues**: Missing indexes, lack of constraints, poor normalization, N+1 queries, inefficient joins, no query timeouts, connection leaks
- **Common Mistakes**: N+1 query problem in loops, missing foreign keys, lack of transactions, no pagination on large datasets, using SELECT *, not using query parameterization
- **Related Patterns**: Normalization, denormalization strategies, indexing patterns, connection pooling, caching strategies, query optimization
- **Problematic Patterns**: God query, magic queries, lack of idempotency, missing rollbacks, monolithic databases
- **Injection Flaws**: SQL injection (parameterized queries needed), NoSQL injection
- **Database-Specific Vulnerabilities**: ORACLE/MYSQL/MSSQL specific issues, NoSQL-specific issues (document injection in MongoDB)
- **Performance Issues**: N+1 query patterns, missing indexes, inefficient algorithms, connection pool exhaustion
- **ORM Patterns**: Eloquent/Django ORM patterns, model discovery, relationship mapping, eager/lazy loading
- **Migration Patterns**: Idempotent migrations, rollback strategies, zero-downtime deployments

## MODE DETECTION
- **WRITE Mode**: Keywords: ["create", "generate", "write", "build", "implement", "add", "new", "design schema", "create migration", "add index", "optimize query"]
- **REVIEW Mode**: Keywords: ["review", "analyze", "audit", "check", "find issues", "query analysis", "performance review", "database review", "schema review"]

## LOADING STRATEGY
### Write Mode (Progressive)
Load patterns based on database requirements:
- Schema questions -> Load `@design/DATABASE-DESIGN.md`
- Query questions -> Load `@relational/SQL-INJECTION.md`, `@relational/INDEXING.md`
- Performance concerns -> Load `@performance/query-optimization.md`
- ORM usage -> Load `@discovery/MODEL-DISCOVERY.md`, `@design/RELATIONSHIP-MAPPING.md`
- Migrations -> Load `@migrations/MIGRATION-BEST-PRACTICES.md`

### Review Mode (Exhaustive)
Load comprehensive checklists:
- IF query review requested -> Load `@relational/NPLUS1.md`, `@relational/INDEXING.md`
- IF schema review requested -> Load `@design/DATABASE-DESIGN.md`
- IF performance review requested -> Load `@performance/query-optimization.md`

## CONTENT STRUCTURE
```
database-engineering/
├── relational/
│   ├── SQL-INJECTION.md
│   ├── INDEXING.md
│   ├── DESIGN.md
│   └── NPLUS1.md
├── nosql/
│   └── MONGODB.md
├── scaling/
│   ├── SHARDING.md
│   └── REPLICATION.md
├── backup/
│   └── BACKUP-RECOVERY.md
├── discovery/
│   ├── MODEL-DISCOVERY.md
│   └── RELATIONSHIP-MAPPING.md
├── design/
│   └── DATABASE-DESIGN.md
├── migrations/
│   └── MIGRATION-BEST-PRACTICES.md
└── connections/
    └── CONNECTION-PATTERNS.md
```

## ROUTING LOGIC
### Progressive Loading (Write Mode)
- **IF** request mentions "SQL injection", "parameterized query" -> READ FILE: `@relational/SQL-INJECTION.md`
- **IF** request mentions "index", "slow query", "optimization" -> READ FILE: `@relational/INDEXING.md`, `@connections/CONNECTION-PATTERNS.md`
- **IF** request mentions "schema", "normalization", "design" -> READ FILE: `@design/DATABASE-DESIGN.md`
- **IF** request mentions "N+1", "loop query" -> READ FILE: `@relational/NPLUS1.md`
- **IF** request mentions "migration", "schema change" -> READ FILE: `@migrations/MIGRATION-BEST-PRACTICES.md`
- **IF** request mentions "Eloquent", "Django", "ORM" -> READ FILE: `@discovery/MODEL-DISCOVERY.md`
- **IF** request mentions "relationship", "foreign key", "one-to-many" -> READ FILE: `@design/RELATIONSHIP-MAPPING.md`
- **IF** request mentions "sharding", "replication", "scale" -> READ FILES: `@scaling/SHARDING.md`, `@scaling/REPLICATION.md`
- **IF** request mentions "backup", "recovery", "restore" -> READ FILE: `@backup/BACKUP-RECOVERY.md`
- **IF** request mentions "MongoDB", "NoSQL", "document" -> READ FILE: `@nosql/MONGODB.md`

### Comprehensive Loading (Review Mode)
- **IF** request mentions "review", "analyze", "audit" -> READ FILES: `@relational/SQL-INJECTION.md`, `@relational/INDEXING.md`, `@relational/NPLUS1.md`, `@design/DATABASE-DESIGN.md`

## MULTI-DOMAIN LOADING
### When to Load Additional Skills

**Context Detection Triggers**:
- **Security Concerns**: If SQLi, injection vulnerabilities, or security mentioned -> LOAD: `@secops-engineering/owasp/OWASP-TOP10.md`, `@secops-engineering/security/INPUT-VALIDATION.md`
- **Performance Concerns**: If slow queries, performance issues, or timeouts mentioned -> LOAD: `@performance-engineering/performance/RESOURCE-LEAKS.md`, `@performance-engineering/database/CONNECTION-POOLING.md`
- **Code Quality**: If refactoring, modernization, or code quality mentioned -> LOAD: `@software-engineering/patterns/CODE-SMELLS.md`
- **Architecture**: If database architecture, data modeling, or system design mentioned -> LOAD: `@software-engineering/architecture/CLEAN-ARCHITECTURE.md`

**Detection Rules**:
1. **Analyze Request**: Scan for keywords and file types
2. **Determine Context**: Identify primary domain (database) and secondary domains
3. **Load Primary Skill**: This skill (database-engineering) with appropriate patterns
4. **Load Secondary Skills**: If secondary domain detected, load relevant skill from that skill's SKILL.md

**Example Scenario**:
```
User: "Review this PHP code for SQL injection and performance issues"

Analysis:
- Primary: database (SQL injection, performance)
- Secondary: software (PHP code)
- Security: SQLi (secops also relevant)

Load:
1. database-engineering/SKILL.md (SQL-INJECTION.md, INDEXING.md)
2. software-engineering/SKILL.md (for PHP context)
3. secops-engineering/SKILL.md (OWASP-TOP10.md, INPUT-VALIDATION.md)
```

## CONTEXT DETECTION

### Relational Database Platform Detection
#### PostgreSQL
- **Connection Strings**: postgresql://, postgres://, pgsql://
- **Command Line Tools**: pg_dump, pg_restore, psql, pg_isready
- **Configuration Files**: postgresql.conf, pg_hba.conf, recovery.conf, postgresql.auto.conf
- **Dump Files**: .sql files with PostgreSQL-specific syntax (serial, bigserial, bytea, jsonb, money)
- **Extensions**: CREATE EXTENSION, .sql files in extensions/
- **Tools/Orchestration**: Patroni (patroni.yml), PgBouncer (pgbouncer.ini), pgBackRest
- **Python Drivers**: psycopg2, psycopg, asyncpg in requirements.txt or pyproject.toml
- **PHP Drivers**: pgsql, pg_ in composer.json
- **Node.js Drivers**: pg, pg-promise in package.json
- **Java Drivers**: postgresql in pom.xml (org.postgresql:postgresql)
- **Go Drivers**: lib/pq in go.mod

#### MySQL / MariaDB
- **Connection Strings**: mysql://, mariadb://
- **Command Line Tools**: mysqldump, mysql, mysqladmin, mysqlcheck
- **Configuration Files**: my.cnf, my.ini, my.cnf.d/, .my.cnf
- **Dump Files**: .sql files with MySQL-specific syntax (AUTO_INCREMENT, ENGINE=InnoDB, TINYINT, MEDIUMTEXT)
- **Replication**: master.info, relay-log.info, binlog.00000X
- **MariaDB Specific**: mariadb.cnf, mariadb.conf.d/
- **Tools/Orchestration**: MySQL Router, MySQL Shell, Orchestrator, ProxySQL
- **Python Drivers**: mysqlclient, PyMySQL, mysql-connector-python in requirements.txt or pyproject.toml
- **PHP Drivers**: mysql, mysqli, pdo_mysql in composer.json
- **Node.js Drivers**: mysql, mysql2, mariadb in package.json
- **Java Drivers**: mysql-connector-java in pom.xml (mysql:mysql-connector-java)
- **Go Drivers**: go-sql-driver/mysql in go.mod

#### SQLite
- **Connection Strings**: sqlite://, sqlite3://
- **Database Files**: .db, .sqlite, .sqlite3, .sqlite-wal, .sqlite-shm
- **Command Line Tools**: sqlite3
- **Python Drivers**: sqlite3 (built-in), pysqlite in requirements.txt
- **PHP Drivers**: sqlite3, pdo_sqlite in composer.json
- **Node.js Drivers**: sqlite3, better-sqlite3 in package.json
- **Java Drivers**: sqlite-jdbc in pom.xml
- **Go Drivers**: mattn/go-sqlite3 in go.mod

#### SQL Server
- **Connection Strings**: mssql://, sqlserver://, server=
- **Command Line Tools**: sqlcmd, bcp
- **Configuration Files**: sqlservr.conf
- **Database Files**: .mdf, .ndf, .ldf
- **Python Drivers**: pymssql, pyodbc in requirements.txt or pyproject.toml
- **PHP Drivers**: pdo_sqlsrv, sqlsrv in composer.json
- **Node.js Drivers**: mssql, tedious in package.json
- **Java Drivers**: mssql-jdbc in pom.xml (com.microsoft.sqlserver:mssql-jdbc)
- **Go Drivers**: mssql/gomssqldb in go.mod

#### Oracle Database
- **Connection Strings**: oracle://, oracle:thin:
- **Command Line Tools**: sqlplus, expdp, impdp
- **Configuration Files**: tnsnames.ora, sqlnet.ora, listener.ora
- **Dump Files**: .dmp files, .log files
- **Python Drivers**: cx_Oracle, oracledb in requirements.txt or pyproject.toml
- **PHP Drivers**: pdo_oci, oci8 in composer.json
- **Java Drivers**: ojdbc in pom.xml (com.oracle.database.jdbc:ojdbc)
- **Go Drivers**: sijms/go-ora in go.mod

#### H2 Database (Java Embedded)
- **Connection Strings**: jdbc:h2:, h2:
- **Configuration Files**: .h2.db, mv.db
- **Java Drivers**: h2 in pom.xml (com.h2database:h2)

### NoSQL Database Platform Detection
#### MongoDB
- **Connection Strings**: mongodb://, mongodb+srv://
- **Command Line Tools**: mongod, mongos, mongo, mongosh, mongodump, mongorestore
- **Configuration Files**: mongod.conf, mongos.conf
- **Data Files**: .bson files, .json dumps
- **Python Drivers**: pymongo, motor in requirements.txt or pyproject.toml
- **PHP Drivers**: mongodb in composer.json (mongodb/mongodb)
- **Node.js Drivers**: mongodb in package.json (mongodb/mongodb)
- **Go Drivers**: mongo-driver/mongo in go.mod
- **Tools/Orchestration**: MongoDB Atlas, Percona Server for MongoDB

#### Redis (Key-Value Store)
- **Connection Strings**: redis://, rediss://
- **Command Line Tools**: redis-cli, redis-server
- **Configuration Files**: redis.conf, sentinel.conf
- **Python Drivers**: redis, hiredis in requirements.txt or pyproject.toml
- **PHP Drivers**: predis, phpredis in composer.json
- **Node.js Drivers**: redis in package.json
- **Go Drivers**: redis/go-redis in go.mod

#### Cassandra
- **Connection Strings**: cassandra://, cassandra+spark://
- **Command Line Tools**: cqlsh, nodetool
- **Configuration Files**: cassandra.yaml
- **Python Drivers**: cassandra-driver in requirements.txt or pyproject.toml
- **PHP Drivers**: cassandra in composer.json (datastax/php-driver)
- **Java Drivers**: cassandra-driver-core in pom.xml

#### Elasticsearch (Search Engine)
- **Connection Strings**: http://localhost:9200, https://
- **Command Line Tools**: elasticsearch, esquery, esbulk
- **Configuration Files**: elasticsearch.yml, elasticsearch.yaml, log4j2.properties
- **Python Drivers**: elasticsearch, elasticsearch-dsl in requirements.txt or pyproject.toml
- **Node.js Drivers**: @elastic/elasticsearch in package.json
- **Go Drivers**: olivere/elastic in go.mod

#### Apache CouchDB (Document Database)
- **Connection Strings**: http://localhost:5984
- **Command Line Tools**: couchdb, curl
- **Configuration Files**: local.ini, default.ini, couchdb.ini

#### InfluxDB (Time Series)
- **Connection Strings**: http://localhost:8086
- **Command Line Tools**: influx, influxd, influx_inspect
- **Configuration Files**: influxdb.conf, influxdb.conf.backup
- **Python Drivers**: influxdb-client, influxdb in requirements.txt or pyproject.toml
- **Node.js Drivers**: influxdb in package.json

### ORM Detection
#### PHP ORMs
- **Laravel Eloquent**: app/Models/, Illuminate\Database\Eloquent\Model, protected $fillable, protected $guarded, relationships (belongsTo, hasMany, hasOne)
- **Symfony Doctrine**: src/Entity/, Doctrine\ORM\Mapping as ORM annotations (@Entity, @Column, @OneToMany), src/Repository/
- **Doctrine DBAL**: Doctrine\DBAL\Connection, DBAL queries
- **CakePHP ORM**: src/Model/Entity/Table.php, belongsTo, hasMany associations
- **CodeIgniter**: application/models/, CI_Model, $this->db
- **PHP ActiveRecord**: ActiveRecord\Model, static methods
- **Propel**: schema.xml, propel.php

#### Python ORMs
- **Django ORM**: models.py with django.db.models.Model, migrations/, makemigrations, migrate command, Meta class, objects.filter()
- **SQLAlchemy**: declarative_base(), Base = declarative_base(), sessionmaker(), Column, Integer, String, relationship(), backref()
- **SQLAlchemy Core**: Engine, create_engine(), text(), execute()
- **SQLAlchemy (Async):** AsyncSession, create_async_engine(), select()
- **Peewee**: peewee.Model, CharField, IntegerField, Database()
- **Tortoise ORM**: models.Model, fields.CharField, generate_schemas(), run_server()
- **Databases (AsyncSQL)**: databases.Database, connect(), execute(), fetch_all()

#### Node.js ORMs
- **Sequelize**: Sequelize, Model.define(), DataTypes, belongsTo, hasMany, sync(), where, include
- **TypeORM**: Entity, Column, PrimaryGeneratedColumn, @Entity, @Column, getRepository(), createQueryBuilder()
- **Mongoose**: mongoose.model(), mongoose.Schema(), new Schema({}), save(), find(), populate()
- **Prisma**: schema.prisma, prisma generate, prisma.db.prisma, prisma.model
- **Bookshelf**: bookshelf.Model, bookshelf.Collection, knex
- **Objection.js**: Model, RelationExpression, static get relationMappings()
- **MikroORM**: Entity, EntityRepository, @Entity, @Property, findOne(), find()

#### Java ORMs
- **Hibernate**: @Entity, @Table, @Column, @OneToMany, @ManyToOne, Session, EntityManager, Criteria API
- **Spring Data JPA**: JpaRepository, CrudRepository, @Repository, @Entity, @Id, save(), findAll(), findById()
- **JPA (Java Persistence API)**: @Entity, @Table, @Column, @Id, EntityManager, CriteriaBuilder
- **MyBatis**: @Mapper, SqlSession, @Select, @Insert, @Update, @Delete
- **JOOQ**: DSL.select(), DSL.field(), Table classes

#### Go ORMs
- **GORM**: gorm.Model, DB.First(), DB.Where(), gorm:"column", preload()
- **sqlx**: sqlx.Open(), DB.Get(), DB.Select(), DB.Exec(), DB.NamedExec()
- **Ent**: ent.NewClient(), ent.Customer.Query().Where(), ent.Schema, ent.Generate()
- **sqlboiler**: models.UserWhere, models.Users(qm), db.Models()

#### .NET ORMs
- **Entity Framework Core**: DbContext, DbSet<T>, DbContextOptions, ToTable(), HasKey(), HasMany(), Include(), ThenInclude()
- **Dapper**: Dapper.Query<T>(), Dapper.Execute(), connection.Query(), connection.Execute()
- **NHibernate**: ISession, SessionFactory, ICriteria, QueryOver<T>, Linq

#### Ruby ORMs
- **Active Record**: ApplicationRecord, belongs_to, has_many, validates, before_save, after_create
- **Sequel**: Sequel::Model, DB[:table].where(), dataset association methods

### Framework Detection
#### PHP Frameworks with Database Integration
- **Laravel**: app/Http/, app/Models/ (Eloquent), routes/api.php, routes/web.php, artisan, database/migrations/, config/database.php
- **Symfony**: src/Controller/, src/Entity/ (Doctrine), config/packages/doctrine.yaml, src/Repository/, bin/console
- **CakePHP**: src/Model/Table/, config/app.php
- **CodeIgniter**: application/models/, application/config/database.php
- **Lumen**: bootstrap/app.php, database/migrations/

#### Python Frameworks with Database Integration
- **Django**: manage.py, settings.py (DATABASES), models.py (ORM), apps/, urls.py, wsgi.py, asgi.py
- **Flask**: app.py or main.py with SQLAlchemy integration, models/ directory, db = SQLAlchemy(app)
- **FastAPI**: main.py with SQLAlchemy or Tortoise ORM, dependencies.get_db(), database sessions
- **Pyramid**: __init__.py, models.py, setup.py with pyramid-sqlalchemy
- **Tornado**: main.py with SQLAlchemy or aiopg (async)
- **Sanic**: main.py with SQLAlchemy or asyncpg

#### Node.js Frameworks with Database Integration
- **Express**: app.js or server.js with Sequelize/Mongoose/Prisma integration, models/ directory
- **NestJS**: src/main.ts, src/app.module.ts (TypeOrmModule.forRoot()), @Injectable, Repository pattern
- **Sails.js**: api/models/, config/models.js, config/datastores.js
- **LoopBack**: models/model-name.json, server/model-config.json, @loopback/repository

#### Java Frameworks with Database Integration
- **Spring Boot**: pom.xml with spring-boot-starter-data-jpa or spring-boot-starter-data-mongodb, @Entity, @Repository, JpaRepository, CrudRepository
- **Spring MVC**: applicationContext.xml with DataSource, JPA context, Hibernate configuration
- **Dropwizard**: bundles of Jackson, Hibernate, Jersey, migrations/
- **Micronaut**: @Entity, @Repository, @JdbcRepository

### Unsupported Database Fallback
- **Detection Failed**: If no database platform detected after checking all indicators -> Load generic database patterns and ask clarifying questions
- **Questions to Ask**:
  - "What database are you using (PostgreSQL, MySQL, MongoDB, etc.)?"
  - "What ORM or query layer are you using (Eloquent, SQLAlchemy, etc.)?"
  - "Is this a relational (SQL) or NoSQL database?"
- **Fallback Strategy**: Load generic SQL or NoSQL patterns based on query syntax detected and request user confirmation

## WHEN TO USE THIS SKILL
✅ Use when:
- Designing database schemas
- Writing SQL queries
- Optimizing database queries
- Creating database migrations
- Implementing indexing strategies
- Solving N+1 query problems
- Managing database connections
- Implementing database scaling (sharding, replication)
- Setting up backup/recovery strategies
- Working with ORMs (Eloquent, Django, SQLAlchemy, etc.)
- Designing database relationships (one-to-many, many-to-many)
- Analyzing query performance

❌ Do NOT use when:
- Application architecture (use software-engineering)
- Database infrastructure (use devops-engineering)
- Security operations beyond SQLi (use secops-engineering)
- Performance testing (use performance-engineering)

## EXECUTION PROTOCOL

### Phase 1: Analysis
1. **Detect Mode**: WRITE vs REVIEW based on keywords
2. **Detect Context**: Database platform (PostgreSQL, MySQL, MongoDB, etc.), ORM, Framework
3. **Load Patterns**: Progressive (write) or Exhaustive (review)
4. **Detect Multi-Domain**: Check if additional skills needed (security, performance, code quality)

### Phase 2: Execution (Write Mode)
1. Load relevant database pattern references
2. Implement according to database best practices
3. Apply platform-specific patterns (PostgreSQL vs MySQL vs MongoDB)
4. Consider ORM-specific patterns (Eloquent vs Django vs Sequelize)
5. Provide code examples in detected platform/language

### Phase 3: Execution (Review Mode)
1. Load all database checklist references
2. Systematically check each category:
   - SQL injection vulnerabilities (parameterization, prepared statements)
   - N+1 query patterns (loops with queries)
   - Missing indexes (slow queries)
   - Schema design issues (normalization, constraints)
   - ORM usage issues (eager loading, relationship mapping)
3. Provide prioritized issues with severity levels

### Phase 4: Validation
- Verify database follows loaded patterns
- Check for SQL injection vulnerabilities
- Ensure proper indexing strategy
- Validate query performance
- Check for cross-references (MUST be within skill only)
- Ensure ORM usage follows best practices

## OUTPUT FORMAT

### Write Mode Output
```markdown
## Database Implementation: [Component]

### Platform
[Detected database platform: PostgreSQL/MySQL/MongoDB/etc.]

### Implementation
```sql
-- SQL example for detected platform
```

### ORM Implementation (if applicable)
```language
[Language-specific ORM code]
```

### Performance Considerations
- [Indexing strategy]
- [Query optimization]
- [Connection management]

### Related Patterns
@relational/[specific-pattern].md
```

### Review Mode Output
```markdown
## Database Review Report

### Critical Issues
1. **[Issue Name]**: [Location: file:line]
   - Severity: CRITICAL
   - OWASP Category: [A03:2021-Injection]
   - Description: [Issue details]
   - Impact: [Data exfiltration, unauthorized access]
   - Fix: [Recommended action: parameterized queries, prepared statements]
   - Reference: @relational/SQL-INJECTION.md

### High Priority Issues
1. **[N+1 Query Problem]**: [Location: file:line]
   - Severity: HIGH
   - Description: [Query in loop causing N+1 queries]
   - Impact: [Performance degradation]
   - Fix: [Recommended action: eager loading, JOIN]
   - Reference: @relational/NPLUS1.md

### Medium Priority Issues
[Same format]

### Low Priority Issues
[Same format]
```
