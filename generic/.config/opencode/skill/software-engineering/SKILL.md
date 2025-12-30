---
name: software-engineering
description: >-
  Domain specialist for software architecture, design patterns, code quality, and refactoring. Expertise includes SOLID principles, GoF design patterns, anti-patterns, code smells, clean architecture, code injection vulnerabilities, performance issues, and modern language features. Use when: code architecture questions, design patterns, refactoring, code reviews, architectural decisions, modernization, clean code practices. Triggers: "SOLID", "design pattern", "refactor", "architecture", "code quality", "clean code", "factory", "singleton", "observer", "strategy", "dependency injection", "separation of concerns", "code smells", "anti-patterns", "modern PHP", "modern Python", "type hints", "async/await", "memory leak", "race condition".
---

# SOFTWARE_ENGINEERING

## DOMAIN EXPERTISE
- **Common Attacks**: Buffer overflow, integer overflow, deserialization attacks, code injection, type confusion, unsafe deserialization
- **Common Issues**: Memory leaks, resource exhaustion, race conditions, error handling gaps, tight coupling, circular dependencies
- **Common Mistakes**: God objects, spaghetti code, magic numbers, violating SOLID, deep nesting, duplicate code, premature optimization
- **Related Patterns**: SOLID principles, Clean Architecture, DRY, YAGNI, KISS, Dependency Injection, Composition over Inheritance
- **Problematic Patterns**: God Object, Spaghetti Code, Magic Numbers, Golden Hammer, Boat Anchor, Lava Flow
- **Injection Flaws**: SQL injection, Command injection, Code injection, Template injection, Expression language injection
- **OWASP Top 10**: A01:2021-Broken Access Control, A02:2021-Cryptographic Failures, A03:2021-Injection, A07:2021-Identification, A08:2021-Software and Data Integrity Failures

## MODE DETECTION
- **WRITE Mode**: Keywords: ["create", "generate", "write", "build", "implement", "add", "new", "refactor to", "modernize", "update"]
- **REVIEW Mode**: Keywords: ["review", "analyze", "audit", "check", "find issues", "refactor analysis", "code quality", "security audit", "identify problems"]

## LOADING STRATEGY
### Write Mode (Progressive)
Load patterns based on code requirements:
- Architecture/Design questions -> Load `@principles/SOLID.md`, `@architecture/CLEAN-ARCHITECTURE.md`
- Specific patterns (Factory, Strategy) -> Load `@patterns/DESIGN-PATTERNS.md` (relevant sections)
- Refactoring/Modernization -> Load `@refactoring/CODE-MODERNIZATION.md`, `@refactoring/MODERN-LANGUAGE-FEATURES.md`
- Performance concerns -> Load `@performance/COMMON-ISSUES.md`
- Security concerns -> Load `@security/CODE-INJECTION.md`

### Review Mode (Exhaustive)
Load comprehensive checklists:
- IF review requested -> Load `@patterns/CODE-SMELLS.md`, `@patterns/ANTI-PATTERNS.md`
- IF design review -> Load `@design/DESIGN-VIOLATIONS.md`
- IF security review -> Load `@security/CODE-INJECTION.md`
- IF performance review -> Load `@performance/COMMON-ISSUES.md`

### Progressive Loading (Write Mode)
- **IF** request mentions "SOLID", "principles", "clean code" -> READ FILE: `@principles/SOLID.md`
- **IF** request mentions specific pattern ("factory", "strategy", "observer") -> READ FILE: `@patterns/DESIGN-PATTERNS.md`
- **IF** request mentions "refactor", "modernize", "update code" -> READ FILE: `@refactoring/CODE-MODERNIZATION.md`
- **IF** request mentions "performance", "slow", "optimization" -> READ FILE: `@performance/COMMON-ISSUES.md`
- **IF** request mentions "security", "injection", "vulnerability" -> READ FILE: `@security/CODE-INJECTION.md`
- **IF** request mentions "architecture", "structure", "design" -> READ FILE: `@architecture/CLEAN-ARCHITECTURE.md`

### Comprehensive Loading (Review Mode)
- **IF** request mentions "review", "analyze", "audit" -> READ FILES: `@patterns/CODE-SMELLS.md`, `@patterns/ANTI-PATTERNS.md`, `@design/DESIGN-VIOLATIONS.md`, `@security/CODE-INJECTION.md`, `@performance/COMMON-ISSUES.md`

## CONTEXT DETECTION
### Language Detection
- **PHP**: .php files, composer.json, artisan, phpunit.xml, .php-cs-fixer.php
- **Python**: .py files, requirements.txt, requirements-dev.txt, pyproject.toml, setup.py, manage.py, tox.ini
- **JavaScript/TypeScript**: .js, .jsx, .ts, .tsx, .vue, .svelte files, package.json, tsconfig.json, .eslintrc.*, prettier.config.*
- **Go**: .go files, go.mod, go.sum, main.go
- **Java**: .java files, .class files, pom.xml, build.gradle, settings.gradle, .gradle/
- **Ruby**: .rb files, Gemfile, Gemfile.lock, Rakefile, config.ru
- **C#**: .cs files, .csproj, .sln, packages.config
- **Rust**: .rs files, Cargo.toml, Cargo.lock
- **C/C++**: .c, .cpp, .h, .hpp files, Makefile, CMakeLists.txt

### Framework Detection
#### PHP Frameworks
- **Laravel**: app/Http/, routes/api.php, routes/web.php, artisan, composer.json with "laravel/framework", phpunit.xml with Laravel namespace
- **Symfony**: src/Controller/, bin/console, config/, symfony.lock, composer.json with symfony/* packages
- **CodeIgniter**: application/controllers/, application/models/, system/
- **CakePHP**: src/Controller/, templates/, config/app.php
- **WordPress**: wp-content/, wp-admin/, wp-includes/, wp-config.php
- **Lumen**: bootstrap/app.php, routes/web.php, composer.json with "laravel/lumen-framework"

#### Python Frameworks
- **Django**: manage.py, settings.py, urls.py, wsgi.py, asgi.py, apps/, pyproject.toml or requirements.txt with "django"
- **Flask**: app.py or main.py with Flask imports, templates/, static/, requirements.txt with "flask"
- **FastAPI**: main.py with FastAPI imports, pyproject.toml or requirements.txt with "fastapi"
- **Pyramid**: __init__.py, setup.py with pyramid in packages
- **Tornado**: main.py with tornado imports
- **Bottle**: app.py with Bottle imports

#### JavaScript/TypeScript Frameworks
- **React**: package.json with "react", .jsx or .tsx files, src/App.js, src/App.tsx, public/index.html
- **Vue.js**: package.json with "vue", .vue files, src/App.vue, src/main.js
- **Angular**: angular.json, tsconfig.app.json, src/app/app.module.ts, package.json with "@angular/*"
- **Next.js**: next.config.js, pages/ or app/ directory, package.json with "next"
- **Nuxt.js**: nuxt.config.js, pages/, package.json with "nuxt"
- **Express**: package.json with "express", app.get(), app.post(), app.use()
- **NestJS**: src/main.ts, package.json with "@nestjs/*", @Controller, @Module decorators
- **Svelte**: package.json with "svelte", .svelte files, rollup.config.js or vite.config.js
- **Ember.js**: ember-cli-build.js, app/, package.json with "ember-cli"
- **Meteor.js**: .meteor/, packages/, imports/

#### Java Frameworks
- **Spring Boot**: pom.xml or build.gradle with "spring-boot-starter", @SpringBootApplication, @RestController
- **Spring MVC**: applicationContext.xml, @Controller, @RequestMapping
- **Java EE/Jakarta EE**: web.xml, @WebServlet, @Stateless
- **Play Framework**: conf/routes, app/controllers/, build.sbt
- **Micronaut**: @Controller, @Get, pom.xml with "micronaut-*"

#### Go Frameworks
- **Gin**: r := gin.Default(), r.GET(), package go-gin/gin
- **Echo**: e := echo.New(), e.GET(), package echo
- **Beego**: beego.Run(), beego.Router()
- **Gorilla Mux**: r := mux.NewRouter(), r.HandleFunc()
- **Fiber**: app := fiber.New(), app.Get(), package fiber

#### Ruby Frameworks
- **Rails**: Gemfile with "rails", config/routes.rb, app/controllers/, app/models/, db/migrate/
- **Sinatra**: require 'sinatra', get '/', post '/'
- **Padrino**: config/apps.rb, app/controllers/

#### C# Frameworks
- **ASP.NET Core**: .csproj with Microsoft.AspNetCore.*, Startup.cs or Program.cs with WebApplicationBuilder, app.MapControllers()
- **ASP.NET MVC**: Global.asax, Controllers/, Views/, Web.config
- **Entity Framework**: DbContext class, DbSet properties

#### Rust Frameworks
- **Actix-web**: HttpServer::new(), App::new(), actix-web dependency
- **Rocket**: #[launch], #[get("/")], rocket dependency
- **Axum**: Router::new(), axum dependency

#### Build Systems & Package Managers
- **PHP**: Composer (composer.json, composer.lock)
- **Python**: pip (requirements.txt), poetry (pyproject.toml), pipenv (Pipfile)
- **JavaScript/TypeScript**: npm (package.json, package-lock.json), yarn (yarn.lock, yarn.lock), pnpm (pnpm-lock.yaml)
- **Java**: Maven (pom.xml), Gradle (build.gradle, settings.gradle)
- **Go**: Go modules (go.mod, go.sum)
- **Ruby**: Bundler (Gemfile, Gemfile.lock)
- **Rust**: Cargo (Cargo.toml, Cargo.lock)
- **C#**: NuGet (.csproj, packages.config)

### Unsupported Framework Fallback
- **Detection Failed**: If no framework detected after checking all indicators -> Load generic patterns and ask clarifying questions
- **Questions to Ask**:
  - "What programming language/framework are you using?"
  - "Is this a web application, CLI tool, library, or other type?"
  - "Are there any specific frameworks or libraries involved?"
- **Fallback Strategy**: Load language-specific generic patterns (e.g., generic PHP patterns if .php files detected) and request user confirmation

## WHEN TO USE THIS SKILL
✅ Use when:
- Designing software architecture
- Implementing design patterns (Factory, Strategy, Observer, etc.)
- Refactoring existing code
- Code review and quality assessment
- Solving architectural problems
- Addressing code smells and anti-patterns
- Modernizing legacy code
- Performance troubleshooting
- Security vulnerability assessment
- SOLID principle application
- Clean code practices

❌ Do NOT use when:
- Infrastructure configuration (use devops-engineering)
- Security operations beyond code injection (use secops-engineering)
- Database design (use database-engineering)
- API design (use api-engineering)
- Performance testing (use performance-engineering)

## EXECUTION PROTOCOL

### Phase 1: Clarification
1. **Detect Mode**: WRITE vs REVIEW based on keywords
2. **Detect Context**: Language, framework, specific patterns mentioned
3. **Load Patterns**: Progressive (write) or Exhaustive (review)

### Phase 2: Planning
1. Load relevant pattern references
2. Implement according to pattern guidelines
3. Apply SOLID principles
4. Consider security implications
5. Provide code examples in detected language

### Phase 3: Execution
1. Load all checklist references
2. Systematically check each category:
   - Code smells (long methods, deep nesting, duplicate code)
   - Anti-patterns (God object, spaghetti, magic numbers)
   - Design violations (SOLID violations, tight coupling)
   - Security (injection flaws, unsafe deserialization)
   - Performance (memory leaks, resource exhaustion)
3. Provide prioritized issues with severity levels

### Phase 4: Validation
- Verify code follows loaded patterns
- Check for cross-references (MUST be within skill only)
- Ensure examples use detected language/framework
- Validate security best practices applied


### Write Mode Output
```markdown
## Implementation: [Pattern Name]

### Pattern Description
[Brief explanation]

### Implementation (PHP/Laravel/etc.)
```language
[code example]
```

### Benefits
- [Benefit 1]
- [Benefit 2]

### Related Patterns
@patterns/DESIGN-PATTERNS.md (see [specific section])
```

### Review Mode Output
```markdown
## Code Review Report

### Critical Issues
1. **[Issue Name]**: [Location: file:line]
   - Severity: CRITICAL
   - Description: [Issue details]
   - Fix: [Recommended action]
   - Reference: @patterns/CODE-SMELLS.md

### High Priority Issues
[Same format]

### Medium Priority Issues
[Same format]

### Low Priority Issues
[Same format]
```
