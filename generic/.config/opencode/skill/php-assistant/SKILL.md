---
name: php-assistant
description: >-
  PHP language specialist for framework-specific patterns, modern PHP features, and PHP best practices. Expertise includes Laravel patterns (Eloquent ORM, routing, middleware, services), Symfony patterns (Doctrine ORM, routing, Twig, services), Bespoke PHP patterns (MVC conventions, autoloading, PSR standards), modern PHP features (type hints, scalar types, return types, null coalescing, spread operator, attributes, properties, enums), deprecated API replacements, array syntax updates, and common PHP mistakes/platform errors. Use when: PHP code generation, framework-specific patterns, modern PHP syntax, PHP refactoring, Laravel/Symfony/Bespoke development. Triggers: "PHP", "Laravel", "Symfony", "Eloquent", "Blade", "Twig", "composer", "artisan", "type hints", "modern PHP", "PHP 8", "array syntax", "deprecated PHP", "MVC", "autoloading".
---

# PHP_ASSISTANT

## DOMAIN EXPERTISE
- **Common Mistakes**: Missing type hints, using old array() syntax, magic numbers, tight coupling, violating PSR standards, using deprecated functions, not using namespace, hardcoded secrets, missing return types, incorrect error handling
- **Common Issues**: Composer dependency conflicts, autoloading issues, namespace conflicts, PSR-4 autoloader configuration, framework version compatibility, missing vendor dependencies, composer dump-autoload needed, caching issues
- **Platform Errors**: Laravel 500 errors, Laravel migration rollbacks, Eloquent mass assignment, Laravel service provider registration issues, Symfony cache:warmup failures, Doctrine mapping issues, Twig template errors, Bespoke autoloader not finding classes
- **Modern PHP**: Type hints (int, string, bool, float, array, callable, object, mixed, never), scalar types, return types, nullable types, void return type, null coalescing operator (??), null coalescing assignment (??=), spaceship operator (<=>), spread operator (...), named arguments, attributes (#[]), constructor property promotion, readonly properties, union types, intersection types, enums, match expression, str_contains(), str_starts_with(), str_ends_with()
- **Deprecated Functions**: mysql_* functions (replaced with PDO/mysqli), ereg_* functions (replaced with preg_*), split() (replaced with explode/preg_split), each() (use foreach), mysql_escape_string() (use PDO::quote()), mysqli_real_escape_string() (use prepared statements)
- **Framework-Specific Patterns**: Laravel (Eloquent relationships, Service providers, Middleware, Request validation, Jobs, Queues, Events, Listeners, Policies, Gates, Broadcasting), Symfony (Doctrine ORM, Console commands, Console helpers, Twig templates, Form components, Validator components, Security component, Event Dispatcher), Bespoke (PSR-4 autoloading, composer autoload, MVC separation, routing patterns, dependency injection)

## MODE DETECTION
- **WRITE Mode**: Keywords: ["create", "generate", "write", "build", "implement", "add", "new", "make", "artisan make", "php artisan", "refactor to", "modernize", "update PHP"]
- **REVIEW Mode**: Keywords: ["review", "analyze", "audit", "check", "find issues", "PHP review", "Laravel review", "Symfony review", "code quality", "security audit", "PHP errors", "platform errors"]

## LOADING STRATEGY
### Write Mode (Progressive)
Load patterns based on framework and code requirements:
- Laravel detected -> Load `@frameworks/LARAVEL.md` + specific patterns from request
- Symfony detected -> Load `@frameworks/SYMFONY.md` + specific patterns from request
- Bespoke detected -> Load `@frameworks/BESPOKE.md` + specific patterns from request
- Modern PHP requested -> Load type hints, modern features patterns from relevant framework guide
- Refactoring requested -> Load deprecated API replacements, modern language features

### Review Mode (Exhaustive)
Load comprehensive checklists:
- IF Laravel review requested -> Load `@frameworks/LARAVEL.md` + `@modes/REVIEW-MODE.md`
- IF Symfony review requested -> Load `@frameworks/SYMFONY.md` + `@modes/REVIEW-MODE.md`
- IF Bespoke review requested -> Load `@frameworks/BESPOKE.md` + `@modes/REVIEW-MODE.md`
- IF general PHP review -> Load `@modes/REVIEW-MODE.md` with generic PHP checklists

## CONTENT STRUCTURE
```
php-assistant/
├── SKILL.md
├── frameworks/
│   ├── LARAVEL.md
│   ├── SYMFONY.md
│   └── BESPOKE.md
└── modes/
    ├── WRITE-MODE.md
    └── REVIEW-MODE.md
```

## ROUTING LOGIC
### Progressive Loading (Write Mode)
- **IF** Laravel detected (artisan, composer.json with laravel/framework, app/Http/, routes/) -> READ FILE: `@frameworks/LARAVEL.md`
- **IF** Symfony detected (bin/console, composer.json with symfony/*, src/Controller/, config/) -> READ FILE: `@frameworks/SYMFONY.md`
- **IF** Bespoke detected (no framework detected, .php files, PSR-4 autoload in composer.json) -> READ FILE: `@frameworks/BESPOKE.md`
- **IF** request mentions "type hints", "modern PHP", "PHP 8", "strict types" -> READ FILE: `@modes/WRITE-MODE.md` (modern PHP section)
- **IF** request mentions "refactor", "modernize", "update" -> READ FILE: `@modes/WRITE-MODE.md` (deprecated API section)

### Comprehensive Loading (Review Mode)
- **IF** request mentions "review", "audit", "analyze" -> READ FILES: `@frameworks/[DETECTED_FRAMEWORK].md`, `@modes/REVIEW-MODE.md`
- **IF** Laravel detected -> Load Laravel-specific review checklists (Eloquent issues, Blade issues, Service provider issues, etc.)
- **IF** Symfony detected -> Load Symfony-specific review checklists (Doctrine issues, Twig issues, Container issues, etc.)
- **IF** Bespoke detected -> Load Bespoke-specific review checklists (PSR violations, autoloader issues, MVC violations)

## CONTEXT DETECTION
### Framework Detection
#### Laravel
- **File Indicators**: artisan, composer.json with "laravel/framework", app/Http/, routes/web.php, routes/api.php, database/migrations/, app/Models/, resources/views/, public/index.php
- **Directory Structure**: app/, bootstrap/, config/, database/, public/, resources/, routes/, storage/, tests/
- **Configuration Files**: .env.example, phpunit.xml, webpack.mix.js, vite.config.js
- **Command Indicators**: php artisan, artisan make:* commands

#### Symfony
- **File Indicators**: bin/console, composer.json with symfony/* packages, src/Controller/, config/, templates/, var/, public/index.php
- **Directory Structure**: src/, config/, templates/, var/, public/, bin/, tests/
- **Configuration Files**: .env.dist, symfony.lock, services.yaml, routes.yaml, phpunit.xml.dist
- **Command Indicators**: php bin/console, bin/console cache:clear

#### CodeIgniter
- **File Indicators**: index.php, composer.json with codeigniter, application/controllers/, application/models/, system/
- **Directory Structure**: application/, system/, public/, writable/

#### CakePHP
- **File Indicators**: composer.json with cakephp/cakephp, src/Controller/, src/Model/, templates/, config/app.php
- **Directory Structure**: src/, config/, templates/, tests/, logs/, tmp/

#### WordPress
- **File Indicators**: wp-config.php, wp-content/, wp-admin/, wp-includes/, index.php
- **Directory Structure**: wp-admin/, wp-content/, wp-includes/

#### Bespoke (No Framework Detected)
- **Detection Logic**: PHP files present but no framework indicators found
- **Indicators**: composer.json without framework packages, index.php, custom MVC structure, PSR-4 autoload
- **Fallback Strategy**: Load generic PHP patterns and ask user to confirm framework

### PHP Version Detection
#### PHP 8.0+
- **Features**: Attributes (#[Attribute]), named arguments, constructor property promotion, union types, mixed type, static return type
- **Detection**: Code contains named parameters, attributes, or constructor property promotion

#### PHP 8.1+
- **Features**: Readonly properties, first-class callable syntax, intersection types, never return type, array_is_list(), enums
- **Detection**: Code contains enums, readonly properties, or never return type

#### PHP 8.2+
- **Features**: Disjunctive Normal Form (DNF) types, null, false, true as standalone types, readonly classes
- **Detection**: Code contains readonly classes or DNF types

#### PHP 8.3+
- **Features**: Typed class constants, \Random\Randomizer, json_validate()
- **Detection**: Code contains typed class constants

#### Legacy PHP (< 8.0)
- **Indicators**: array() syntax instead of [], mysql_* functions, ereg_* functions, no type hints, no namespace usage
- **Detection**: Code uses array(), mysql_query(), or lacks type hints

### PSR Standard Detection
- **PSR-1**: Basic coding standard (namespace, class names, file naming)
- **PSR-4**: Autoloading standard (namespace to directory mapping)
- **PSR-12**: Extended coding style (code formatting, indentation)
- **Detection**: composer.json autoload psr-4 mapping, namespace declarations, file naming conventions

## MULTI-DOMAIN LOADING
### When to Load Additional Skills

**Context Detection Triggers**:
- **Database Operations**: If SQL queries, Eloquent models, or Doctrine entities mentioned -> LOAD: `@database-engineering/SKILL.md`
- **Security Concerns**: If SQLi, XSS, CSRF, or authentication mentioned -> LOAD: `@secops-engineering/SKILL.md`
- **Code Architecture**: If design patterns, refactoring, or SOLID mentioned -> LOAD: `@software-engineering/SKILL.md`
- **API Development**: If API routes, controllers, or REST mentioned -> LOAD: `@api-engineering/SKILL.md`
- **Infrastructure**: If Docker, deployment, or CI/CD mentioned -> LOAD: `@devops-engineering/SKILL.md`

**Detection Rules**:
1. **Analyze Request**: Scan for keywords and file types
2. **Determine Context**: Identify framework (Laravel/Symfony/Bespoke) and secondary domains
3. **Load Primary Skill**: This skill (php-assistant) with appropriate framework guide
4. **Load Secondary Skills**: If secondary domain detected, load relevant skill from that skill's SKILL.md

**Example Scenario**:
```
User: "Review this Laravel code for SQL injection and performance issues"

Analysis:
- Primary: php (Laravel)
- Secondary 1: database (SQL injection)
- Secondary 2: performance (performance issues)

Load:
1. php-assistant/SKILL.md (LARAVEL.md, REVIEW-MODE)
2. database-engineering/SKILL.md (SQL-INJECTION.md, INDEXING.md)
3. performance-engineering/SKILL.md (RESOURCE-LEAKS.md, QUERY-OPTIMIZATION.md)
```

## WHEN TO USE THIS SKILL
✅ Use when:
- Writing PHP code (Laravel, Symfony, Bespoke)
- Implementing Laravel-specific patterns (Eloquent, Jobs, Events, Listeners)
- Implementing Symfony-specific patterns (Doctrine, Console commands, Twig)
- Writing Bespoke PHP code with MVC patterns
- Modernizing legacy PHP code
- Applying modern PHP features (type hints, attributes, enums)
- Refactoring deprecated PHP functions
- Solving Laravel/Symfony platform errors
- PHP code review and quality assessment
- PSR standards compliance
- Composer dependency management

❌ Do NOT use when:
- Non-PHP code (use language-specific assistant for that language)
- Infrastructure configuration (use devops-engineering)
- Database design (use database-engineering)
- General architecture patterns (use software-engineering)

## EXECUTION PROTOCOL

### Phase 1: Analysis
1. **Detect Framework**: Laravel, Symfony, CodeIgniter, CakePHP, WordPress, or Bespoke
2. **Detect Mode**: WRITE vs REVIEW based on keywords
3. **Detect PHP Version**: Legacy (< 8.0) vs Modern (8.0+)
4. **Detect Multi-Domain**: Check if additional skills needed (database, security, architecture, API)
5. **Load Patterns**: Framework-specific guide + progressive (write) or exhaustive (review)

### Phase 2: Execution (Write Mode)
1. Load framework-specific patterns (@frameworks/[FRAMEWORK].md)
2. Implement code according to framework conventions
3. Apply PSR standards (PSR-1, PSR-4, PSR-12)
4. Use modern PHP features (type hints, strict types, named arguments, etc.)
5. Follow framework best practices (Laravel: Service providers, Events; Symfony: Services, Console)
6. Provide examples in detected framework style
7. Consider multi-domain requirements (load database, security, etc. if needed)

### Phase 3: Execution (Review Mode)
1. Load framework-specific guide + review mode checklist
2. Systematically check each category:
   - **Framework-Specific Issues**: Laravel (Eloquent issues, Blade issues, Service provider problems), Symfony (Doctrine issues, Twig issues, Container problems)
   - **Common Mistakes**: Missing type hints, old array syntax, magic numbers, PSR violations
   - **Security Issues**: SQLi, XSS, CSRF, hardcoded secrets (load secops-engineering if needed)
   - **Platform Errors**: Laravel 500 errors, migration rollbacks, Symfony cache issues
   - **Modernization Issues**: Deprecated functions, missing type hints, legacy patterns
   - **Code Quality**: Code smells, anti-patterns (load software-engineering if needed)
3. Provide prioritized issues with severity levels (CRITICAL, HIGH, MEDIUM, LOW)
4. Suggest modern PHP improvements

### Phase 4: Validation
- Verify code follows framework conventions
- Check PSR standards compliance
- Ensure modern PHP features are used appropriately
- Validate no security vulnerabilities (SQLi, XSS, CSRF)
- Check for cross-references (MUST be within php-assistant only)

## OUTPUT FORMAT

### Write Mode Output
```markdown
## [Framework] Implementation: [Component]

### Framework: [Laravel/Symfony/Bespoke]

### Implementation
```php
// PHP code following framework conventions
```

### Modern PHP Features
- [Type hints used]
- [Named arguments where applicable]
- [Strict types enabled]

### PSR Compliance
- [PSR-1: Namespace and file naming]
- [PSR-4: Autoloading]
- [PSR-12: Code style]

### Related Patterns
@frameworks/[FRAMEWORK].md
```

### Review Mode Output
```markdown
## PHP Code Review Report: [Framework]

### Critical Issues
1. **[Issue Name]**: [File:line]
   - Severity: CRITICAL
   - Category: [Security/Framework/Modernization]
   - Description: [Issue details]
   - Fix: [Recommended action]
   - Reference: @frameworks/[FRAMEWORK].md or @modes/REVIEW-MODE.md

### High Priority Issues
[Same format]

### Medium Priority Issues
[Same format]

### Low Priority Issues
[Same format]

### Modernization Recommendations
1. [Modern PHP feature to adopt]
2. [Deprecated function to replace]
3. [PSR standard to apply]

### Framework-Specific Notes
- [Framework-specific best practices]
- [Framework-specific gotchas]
```
