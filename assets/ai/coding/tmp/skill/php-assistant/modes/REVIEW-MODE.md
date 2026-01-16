# Review Mode: PHP Code Review

**Purpose**: Exhaustive review checklists for PHP code analysis, security, performance, and best practices

## EXHAUSTIVE LOADING STRATEGY

### Step 1: Framework-Specific Review
Load framework-specific review patterns:
- **Laravel detected**: Review Eloquent, Blade, Controllers, Service Providers, Jobs, etc.
- **Symfony detected**: Review Doctrine, Twig, Controllers, Services, Console Commands, etc.
- **Bespoke detected**: Review PSR compliance, MVC structure, autoloading, database access

### Step 2: Universal PHP Review
Always review regardless of framework:
- **Security Issues**: SQLi, XSS, CSRF, hardcoded secrets, insecure dependencies
- **Code Quality**: Type hints, modern PHP features, deprecated functions
- **Performance**: N+1 queries, unnecessary queries, missing indexes
- **Code Smells**: Long methods, deep nesting, duplicate code, magic numbers

### Step 3: Multi-Domain Review
Load additional skills for comprehensive review:
- **Database**: Load database-engineering for SQLi, N+1, query optimization
- **Security**: Load secops-engineering for OWASP Top 10, authentication issues
- **Architecture**: Load software-engineering for SOLID violations, design patterns

## LARAVEL REVIEW CHECKLIST

### Eloquent ORM Issues
- [ ] **N+1 Queries**: Querying relationships inside loops without `with()`
- [ ] **Unnecessary Queries**: Loading entire model when only one field needed (use `pluck()`)
- [ ] **Mass Assignment Vulnerability**: Missing `$fillable` or using `$guarded: []`
- [ ] **SQL Injection**: Using `DB::raw()` or `whereRaw()` without validation
- [ ] **Unscoped Queries**: Missing global scopes where applicable
- [ ] **Missing Constraints**: Not defining database constraints (unique, foreign keys)
- [ ] **Soft Deletes**: Inconsistent soft delete handling
- [ ] **Casting Issues**: Missing `$casts` for date/array/json types
- [ ] **Observer Overhead**: Too many observers causing performance issues
- [ ] **Accessors/Mutators**: Incorrect property modification

### Blade Template Issues
- [ ] **XSS Vulnerability**: Using `{!! !!}` on untrusted data without sanitization
- [ ] **Missing CSRF**: Forms without `@csrf` directive
- [ ] **Complex Logic**: Business logic in templates (move to controllers)
- [ ] **Direct PHP**: Using `<?php ?>` instead of Blade directives
- [ ] **N+1 in Views**: Querying in loops (use eager loading)
- [ ] **Missing Validation**: Not displaying validation errors with `@error`
- [ ] **Unused Components**: Components declared but not used
- [ ] **Performance Issues**: Large compiled views, missing view caching

### Controller Issues
- [ ] **Fat Controllers**: Too much business logic in controllers (move to services)
- [ ] **Missing Validation**: Not validating request data (use Form Requests)
- [ ] **Missing Auth**: Forgetting to add `auth` middleware
- [ ] **Hardcoded Data**: Hardcoding data in controllers (use config)
- [ ] **Direct DB Queries**: Using `DB` facade instead of Eloquent in controllers
- [ ] **Wrong Return Type**: Returning array instead of Response object
- [ ] **Missing Authorization**: Not using Gates/Policies for authorization
- [ ] **Mass Assignment**: Accepting all request data without validation
- [ ] **Resource Leaks**: Not cleaning up resources (file uploads, etc.)

### Routing Issues
- [ ] **Route Order**: Specific routes defined after generic routes (never match)
- [ ] **Missing Methods**: Not specifying HTTP methods in routes
- [ ] **API Routes in Web**: API routes should be stateless (no session)
- [ ] **Route Conflicts**: Multiple routes with same path
- [ ] **Missing CSRF**: Web routes without CSRF middleware
- [ ] **Unsecured Routes**: Sensitive routes missing authentication
- [ ] **Route Caching**: Not running `php artisan route:cache` in production
- [ ] **Missing Rate Limiting**: Public endpoints without throttling

### Service Provider Issues
- [ ] **Not Registering**: Services not registered in container
- [ ] **Wrong Method**: Using `boot()` for registration (use `register()`)
- [ ] **Circular Dependencies**: Services depending on each other
- [ ] **Deferred Providers**: Should use deferred loading if possible
- [ ] **Missing Event Listeners**: Not registering event listeners

### Job/Queue Issues
- [ ] **Workers Not Running**: Jobs dispatched but no workers processing
- [ ] **Timeout Issues**: Jobs exceeding timeout (increase timeout or split job)
- [ ] **Failed Jobs**: Not handling or monitoring failed jobs
- [ ] **Memory Leaks**: Workers consuming memory (restart workers)
- [ ] **Missing Retry**: Failed jobs not retried (should use retry)
- [ ] **Large Payloads**: Jobs with excessive data (use references instead)
- [ ] **Missing Transactions**: Jobs not using database transactions

### Migration Issues
- [ ] **Not Idempotent**: Migrations not safe to run multiple times
- [ ] **Missing Rollback**: Not defining `down()` method
- [ ] **Foreign Key Issues**: Dropping tables without dropping foreign keys first
- [ ] **Data Loss**: Migrations losing data without backup
- [ ] **Performance**: Large migrations blocking production
- [ ] **Missing Indexes**: Missing indexes on foreign keys/queried columns
- [ ] **Schema Conflicts**: Migration conflicts with existing schema

### Configuration Issues
- [ ] **Sensitive Data**: Hardcoded credentials in `.env.example`
- [ ] **Debug Mode**: Debug enabled in production (APP_DEBUG=true)
- [ ] **Cache Issues**: Stale config cache, missing cache:clear
- [ ] **Missing Encryption**: Not setting `APP_KEY` or using weak key
- [ ] **Queue Configuration**: Wrong queue driver or missing queue worker config

## SYMFONY REVIEW CHECKLIST

### Doctrine ORM Issues
- [ ] **N+1 Queries**: Not joining relationships (use LEFT JOIN)
- [ ] **Unnecessary Queries**: Loading entities when only specific data needed
- [ ] **Missing Indexes**: Querying without indexes (slow queries)
- [ ] **Not Flushing**: Persisting entities without flushing (data not saved)
- [ ] **Circular References**: Entities referencing each other (infinite loops)
- [ ] **Lazy Loading Issues**: Unexpected lazy loading causing N+1
- [ ] **Missing Fetch Mode**: Not setting fetch mode (EAGER vs LAZY)
- [ ] **DQL Injections**: Using DQL with user input without parameterization
- [ ] **Duplicate Queries**: Same query executed multiple times

### Controller Issues
- [ ] **Static Dependencies**: Using static methods instead of services
- [ ] **Fat Controllers**: Too much business logic in controllers (move to services)
- [ ] **Missing Validation**: Not validating request data (use Forms)
- [ ] **Wrong Return Type**: Returning string instead of Response object
- [ ] **Not Using Form Component**: Handling form data manually
- [ ] **Missing Type Hints**: Parameters and return types missing
- [ ] **Not Using Services**: Direct instantiation instead of service container

### Twig Template Issues
- [ ] **XSS Vulnerability**: Using `|raw` filter on untrusted data
- [ ] **Complex Logic**: Business logic in templates (move to PHP)
- [ ] **Missing CSRF**: Forms without CSRF tokens
- [ ] **Hardcoded Text**: Text in templates (use translations)
- [ ] **Performance**: Too many database queries in templates
- [ ] **Missing Escaping**: Output not properly escaped (XSS risk)
- [ ] **Large Templates**: Templates too large/complex (split into includes)

### Routing Issues
- [ ] **Route Order**: Generic routes before specific routes (never match)
- [ ] **Missing Methods**: Not specifying HTTP methods (matches all)
- [ ] **Wrong Return**: Controllers returning strings instead of Response
- [ ] **Route Conflicts**: Multiple routes with same path
- [ ] **Missing Requirements**: Not validating route parameters

### Service Container Issues
- [ ] **Service Conflicts**: Multiple services with same ID
- [ ] **Circular Dependencies**: Services depending on each other
- [ ] **Not Using Autowiring**: Manual configuration when autowiring works
- [ ] **Missing Dependencies**: Services not defined in container
- [ ] **Factory Pattern Issues**: Not using factories for complex instantiation

### Console Command Issues
- [ ] **Not Using Return Codes**: Not returning proper exit codes
- [ ] **Missing Error Handling**: Not catching exceptions in commands
- [ ] **Interactive by Default**: Not using `--no-interaction` for automation
- [ ] **Not Using Dependencies**: Using global/static code instead of injected services
- [ ] **Missing Help**: Not providing help/usage information

### Security Issues
- [ ] **Weak Passwords**: Not using password encoders properly
- [ ] **Missing CSRF**: Forms without CSRF protection
- [ ] **Open Redirects**: Redirecting to user-provided URLs
- [ ] **Hardcoded Roles**: Checking roles manually instead of using security system
- [ ] **Missing Access Control**: Not using `#[IsGranted]` where needed
- [ ] **User Provider Issues**: Wrong implementation of UserProviderInterface

### Configuration Issues
- [ ] **Environment Variables**: Not using `.env` for sensitive data
- [ ] **Cache Issues**: Stale cache, corrupted cache, permission issues
- [ ] **Autoloader Issues**: Not running `composer dump-autoload`
- [ ] **Missing Services**: Services not registered in `services.yaml`

## BESPOKE PHP REVIEW CHECKLIST

### PSR Compliance Issues
- [ ] **No Namespace**: Code not in namespace (violates PSR-1)
- [ ] **Wrong Namespace**: Namespace doesn't match directory structure
- [ ] **Class Naming**: Class name doesn't match filename
- [ ] **Multiple Classes**: Multiple classes in one file
- [ ] **Missing Autoload**: Not configuring PSR-4 in composer.json
- [ ] **Wrong Directory**: Namespace doesn't map to directory
- [ ] **Missing Composer Dump**: Changes not reflected (run dump-autoload)

### MVC Structure Issues
- [ ] **Fat Controllers**: Too much business logic in controllers
- [ ] **Logic in Views**: Business logic in templates (move to PHP)
- [ ] **Direct Database Access**: Controllers accessing database directly (use repositories)
- [ ] **Missing Separation**: Models, views, controllers mixed together
- [ ] **No Dependency Injection**: Using static/global code
- [ ] **Fat Models**: Too much logic in models (move to services)

### Routing Issues
- [ ] **Case Sensitivity**: URLs are case-sensitive (should be case-insensitive)
- [ ] **Trailing Slashes**: Inconsistent trailing slashes
- [ ] **Missing 404**: Not handling unmatched routes
- [ ] **SQL Injection in Routes**: Not validating route parameters
- [ ] **Wrong Dispatch Logic**: Router not matching correctly

### Database Issues
- [ ] **SQL Injection**: Not using prepared statements (CRITICAL)
- [ ] **Not Closing Connections**: Not closing database connections
- [ ] **Raw Queries Everywhere**: Not using abstraction layer
- [ ] **Missing Transactions**: Not using transactions for multi-step operations
- [ ] **Missing Error Handling**: Not catching database exceptions
- [ ] **Inconsistent Naming**: Table/column naming inconsistent

### Security Issues
- [ ] **XSS Vulnerability**: Not escaping output with `htmlspecialchars()`
- [ ] **CSRF Vulnerability**: Missing CSRF token validation (CRITICAL)
- [ ] **SQL Injection**: Concatenating strings in SQL queries (CRITICAL)
- [ ] **Hardcoded Secrets**: Credentials in code instead of environment variables (CRITICAL)
- [ ] **Weak Password Hashing**: Using MD5/SHA1 instead of `password_hash()`
- [ ] **Missing Input Validation**: Not validating user input
- [ ] **Path Traversal**: Not validating file paths
- [ ] **Open Redirect**: Redirecting to user-provided URLs

### Error Handling Issues
- [ ] **Silencing Errors**: Using `@` operator
- [ ] **Not Logging Errors**: Not recording errors in production
- [ ] **Showing Errors in Production**: Exposing stack traces (CRITICAL)
- [ ] **Not Handling Exceptions**: Uncaught exceptions crash application
- [ ] **Missing Validation Errors**: Not showing validation errors to users

### Performance Issues
- [ ] **Not Using Autoloading**: Requiring files manually
- [ ] **Unnecessary Queries**: Querying database unnecessarily
- [ ] **Missing Indexes**: Database queries without indexes
- [ ] **Not Using Cache**: Repeated expensive operations not cached
- [ ] **N+1 Queries**: Querying in loops (use joins/eager loading)
- [ ] **Large Files**: Loading entire files into memory

### Code Quality Issues
- [ ] **No Type Hints**: Missing parameter/return types
- [ ] **Deprecated Functions**: Using deprecated PHP functions
- [ ] **Old Array Syntax**: Using `array()` instead of `[]`
- [ ] **Magic Numbers**: Unexplained numeric literals
- [ ] **Long Methods**: Methods too long (> 50 lines)
- [ ] **Deep Nesting**: Nesting > 4 levels
- [ ] **Duplicate Code**: Same code in multiple places (extract to functions)
- [ ] **Missing Strict Types**: Not using `declare(strict_types=1)`

## UNIVERSAL PHP ISSUES

### Deprecated Functions
- [ ] **mysql_* functions**: Using deprecated mysql_ functions (use PDO/mysqli)
- [ ] **ereg_* functions**: Using deprecated ereg functions (use preg)
- [ ] **split()**: Using deprecated split (use explode/preg_split)
- [ ] **each()**: Using deprecated each (use foreach)
- [ ] **mysql_escape_string()**: Using deprecated escape (use prepared statements)

### Modern PHP Features
- [ ] **Missing Type Hints**: Parameters and return types missing
- [ ] **Not Using Null Coalescing**: Using isset checks instead of `??`
- [ ] **Old Array Syntax**: Using `array()` instead of `[]`
- [ ] **Not Using Return Types**: Missing return type declarations
- [ ] **Not Using Namespace**: Code not in namespace
- [ ] **Not Using Composer**: Including files manually instead of autoloading

### Code Smells
- [ ] **Long Methods**: Methods > 50 lines (extract to smaller methods)
- [ ] **Deep Nesting**: Nesting > 4 levels (use early returns/guard clauses)
- [ ] **Duplicate Code**: Same code in multiple places (extract to functions)
- [ ] **God Objects**: Classes doing too much (split into smaller classes)
- [ ] **Feature Envy**: Methods using another class's data
- [ ] **Shotgun Surgery**: Changing multiple classes for one change
- [ ] **Data Clumps**: Grouped parameters that should be class

## SECURITY REVIEW

### OWASP Top 10 Check
- [ ] **A01: Broken Access Control**: Missing authorization checks
- [ ] **A02: Cryptographic Failures**: Weak encryption/hashing
- [ ] **A03: Injection**: SQLi, XSS, command injection
- [ ] **A04: Insecure Design**: Missing security requirements
- [ ] **A05: Security Misconfiguration**: Debug mode, default credentials
- [ ] **A06: Vulnerable Components**: Outdated dependencies
- [ ] **A07: Auth Failures**: Weak authentication, session issues
- [ ] **A08: Integrity Failures**: Unverified dependencies, insecure updates
- [ ] **A09: Logging Failures**: Missing logging, audit trails
- [ ] **A10: SSRF**: Server-side request forgery

### Dependency Scanning
- [ ] **Outdated Packages**: Dependencies with known vulnerabilities (use composer audit)
- [ ] **Unpinned Versions**: Using `*` or `~` versions (security risk)
- [ ] **Missing Updates**: Security patches not applied

## OUTPUT FORMAT

### Review Report Output
```markdown
## PHP Code Review Report: [Framework: Laravel/Symfony/Bespoke]

### Critical Issues (CRITICAL - Fix Immediately)

1. **[Issue Name]**: [File:line]
   - Severity: CRITICAL
   - Category: [Security/Framework/Modernization]
   - OWASP Category: [A01-A10 if applicable]
   - Description: [Detailed issue description]
   - Impact: [What could happen if not fixed]
   - Fix: [Specific remediation steps]
   - Example: [Before/After code examples]
   - Reference: @frameworks/[FRAMEWORK].md or @modes/REVIEW-MODE.md

### High Priority Issues (HIGH - Fix Soon)

[Same format as Critical]

### Medium Priority Issues (MEDIUM - Consider Fixing)

[Same format as Critical]

### Low Priority Issues (LOW - Nice to Have)

[Same format as Critical]

### Code Quality Issues

#### Modernization Recommendations
- [ ] Use type hints: [Specific locations]
- [ ] Replace deprecated functions: [Function replacements]
- [ ] Use modern syntax: [Specific improvements]

#### Code Smells
- [ ] Long methods: [Method names and line counts]
- [ ] Deep nesting: [Locations and levels]
- [ ] Duplicate code: [Code blocks to extract]

#### PSR Compliance
- [ ] PSR-1: [Namespace, class naming issues]
- [ ] PSR-4: [Autoloading issues]
- [ ] PSR-12: [Code style issues]

### Framework-Specific Notes
- **[Framework-Specific Best Practices]**
- **[Framework-Specific Gotchas]**
- **[Platform-Specific Errors to Watch For]**

### Dependencies
- **Outdated Packages**: List packages with known vulnerabilities
- **Composer Audit**: Run `composer audit` for security scan
- **Required Updates**: Packages needing security updates

### Security Assessment
- **SQL Injection**: [Locations and severity]
- **XSS**: [Locations and severity]
- **CSRF**: [Forms missing CSRF protection]
- **Hardcoded Secrets**: [Locations of credentials in code]
- **Input Validation**: [Missing validation locations]
- **Authentication/Authorization**: [Issues with auth implementation]

### Recommendations
1. [Security improvement]
2. [Performance improvement]
3. [Code quality improvement]
4. [Modernization suggestion]

### Related Skills
- @database-engineering/SKILL.md (for SQLi, N+1, query optimization)
- @secops-engineering/SKILL.md (for OWASP Top 10, security best practices)
- @software-engineering/SKILL.md (for SOLID violations, design patterns)
```
