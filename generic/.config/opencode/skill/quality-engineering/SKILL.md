---
name: quality-engineering
description: >-
  Domain specialist for code quality assessment, maintainability, complexity analysis, code smells detection, anti-patterns identification, and code style enforcement. Expertise includes code review methodologies, naming conventions, coding standards, and technical debt management. Use when: quality questions, code quality, code health, code smells, anti-patterns, complexity, maintainability, naming conventions, code style, technical debt, refactoring, code review, clean code, SOLID principles. Triggers: "quality", "code quality", "code health", "smell", "code smell", "anti-pattern", "complexity", "cyclomatic complexity", "maintainability", "maintainable code", "naming", "naming convention", "style", "code style", "linting", "technical debt", "debt", "code debt", "refactoring", "refactor", "review", "code review", "clean code", "clean code principles", "SOLID", "SOLID principles".
---

## Overview

Domain specialist for code quality assessment, maintainability, complexity analysis, code smells detection, anti-patterns identification, and code style enforcement. Expertise includes code review methodologies, naming conventions, coding standards, and technical debt management.

## Trigger Words

- quality, code quality, code health
- smell, code smell, anti-pattern
- complexity, cyclomatic complexity
- maintainability, maintainable code
- naming, naming convention
- style, code style, linting
- technical debt, debt, code debt
- refactoring, refactor
- review, code review
- clean code, clean code principles
- SOLID principles

---

## Detection

### Code Quality Tools

**JavaScript/TypeScript:**
- ESLint (`eslint`, `eslint.config.js`)
- Prettier (`.prettierrc`)
- TypeScript (`tsconfig.json`)
- SonarQube (`sonar-project.properties`)

**Python:**
- Flake8 (`.flake8`, `setup.cfg`, `tox.ini`)
- Black (`pyproject.toml`, `.black`)
- Ruff (`ruff.toml`, `.ruff.toml`)
- mypy (`mypy.ini`)
- Pylint (`.pylintrc`)

**PHP:**
- PHPStan (`phpstan.neon`, `phpstan-dist.neon`)
- Psalm (`psalm.xml`)
- PHP_CodeSniffer (`phpcs.xml`, `ruleset.xml`)
- PHP-CS-Fixer (`.php-cs-fixer.php`)

**Ruby:**
- RuboCop (`.rubocop.yml`)
- RuboCop Performance (`rubocop-performance.yml`)

**Go:**
- golint, staticcheck, golangci-lint (`.golangci.yml`)

**Java:**
- Checkstyle (`checkstyle.xml`)
- PMD, SpotBugs (`pmd.xml`)
- SonarQube

**C#:**
- StyleCop, ReSharper (`*.ruleset`)

### Code Complexity Tools

- **Cyclomatic Complexity**: `complexity-report`
- **Maintainability Index**: `mi`
- **Code Duplication**: `jscpd`, `phpcpd`

### Technical Debt Tracking

- SonarQube (technical debt metrics)
- CodeClimate (quality metrics)
- Lighthouse (web performance)

---

## Mode Detection

### Write Mode (Progressive Guidance)

**Trigger:** `mode=write` or no explicit quality task

**Load Progressive Files:**
1. `CODE-STYLE.md` - Coding standards and conventions
2. `NAMING-CONVENTIONS.md` - Consistent naming
3. `COMPLEXITY.md` - Complexity analysis and reduction

**Behavior:**
- Provide concise examples
- Focus on applying standards
- Progressive complexity (simple → advanced)
- Framework-specific guidance

### Review Mode (Exhaustive Checklists)

**Trigger:** `mode=review`, "review code", "assess quality", "check code health", "audit code", "code quality assessment"

**Load Review Files:**
1. `CODE-SMELLS.md` - Comprehensive code smell detection
2. `ANTI-PATTERNS.md` - Anti-pattern identification
3. `CODE-HEALTH.md` - Health assessment checklist
4. `MAINTAINABILITY.md` - Maintainability evaluation

**Behavior:**
- Exhaustive review checklists
- Identify code smells and anti-patterns
- Assess complexity metrics
- Evaluate maintainability
- Gap identification and prioritization

---

## Skill Loading Strategy

### Initial Load

```javascript
function loadQualityEngineeringSkill(context) {
    const mode = context.mode || 'write';

    if (mode === 'review') {
        // Load review-mode files
        loadProgressive([
            'CODE-SMELLS.md',
            'ANTI-PATTERNS.md',
            'CODE-HEALTH.md',
            'MAINTAINABILITY.md'
        ]);
    } else {
        // Load write-mode files
        loadProgressive([
            'CODE-STYLE.md',
            'NAMING-CONVENTIONS.md',
            'COMPLEXITY.md'
        ]);
    }

    // Always load core concepts based on query keywords
    if (context.query.match(/smell|anti-pattern/)) {
        loadProgressive(['CODE-SMELLS.md', 'ANTI-PATTERNS.md']);
    }

    if (context.query.match(/complexity|cyclomatic/)) {
        load('COMPLEXITY.md');
    }

    if (context.query.match(/maintain|maintainable/)) {
        load('MAINTAINABILITY.md');
    }

    if (context.query.match(/naming|convention/)) {
        load('NAMING-CONVENTIONS.md');
    }

    if (context.query.match(/style|lint|formatting/)) {
        load('CODE-STYLE.md');
    }

    if (context.query.match(/health|review|audit/)) {
        loadProgressive([
            'CODE-SMELLS.md',
            'ANTI-PATTERNS.md',
            'CODE-HEALTH.md'
        ]);
    }

    if (context.query.match(/debt|refactor/)) {
        loadProgressive([
            'COMPLEXITY.md',
            'CODE-SMELLS.md',
            'ANTI-PATTERNS.md'
        ]);
    }
}
```

---

## Progressive Disclosure Files

### Assessment (Progressive)

1. `CODE-SMELLS.md` - Code smell detection (duplicate code, long methods, etc.)
2. `ANTI-PATTERNS.md` - Anti-patterns (God Object, Magic Numbers, etc.)
3. `CODE-HEALTH.md` - Health assessment checklist
4. `COMPLEXITY.md` - Complexity analysis (cyclomatic, cognitive, maintainability index)
5. `MAINTAINABILITY.md` - Maintainability evaluation

### Standards (Progressive)

6. `NAMING-CONVENTIONS.md` - Consistent naming across languages
7. `CODE-STYLE.md` - Coding standards and linting

---

## Quick Reference

### Code Quality Metrics

| Metric | Good | Excellent | Target |
|--------|-------|----------|--------|
| **Cyclomatic Complexity** | <10 | <5 | <10 per function |
| **Maintainability Index** | >20 | >85 | >20 (MI = 171 - 5.2 × ln(CC) - 0.23 × CC - 16.2 × ln(LOC)) |
| **Code Duplication** | <5% | <3% | <5% duplicated |
| **Code Smells** | <10 | <5 | Smells per 1000 LOC |
| **Test Coverage** | 70% | 90% | See testing-engineering |
| **Technical Debt Ratio** | <5% | <2% | Debt / Total Code |

### Code Quality Dimensions

| Dimension | Metrics | Tools |
|-----------|----------|-------|
| **Readability** | Naming, formatting, comments | Linters, formatters |
| **Complexity** | Cyclomatic, cognitive, nesting | Complexity analyzers |
| **Maintainability** | MI, duplication, coupling | SonarQube, CodeClimate |
| **Reliability** | Test coverage, bug density | Test frameworks, issue trackers |
| **Performance** | Execution time, memory usage | Profilers, benchmarking |
| **Security** | Vulnerabilities, dependency issues | SAST, dependency scanners |

### Common Code Quality Tools

| Language | Linter | Formatter | Complexity | Coverage |
|----------|---------|-----------|------------|----------|
| **JavaScript** | ESLint | Prettier | ESLint complexity | Jest/Istanbul |
| **TypeScript** | ESLint + TSLint | Prettier | TSLint | Jest/Istanbul |
| **Python** | Flake8, Ruff | Black | Radon | PyTest/Coverage.py |
| **PHP** | PHPStan | PHP-CS-Fixer | PHPStan | PHPUnit |
| **Ruby** | RuboCop | RuboCop | RuboCop | SimpleCov |
| **Go** | golint | gofmt | gocyclo | go test -cover |
| **Java** | Checkstyle, PMD | SpotBugs | PMD | JaCoCo |
| **C#** | StyleCop | dotnet format | ReSharper | dotCover |

---

## Core Concepts

### SOLID Principles

1. **S** - Single Responsibility Principle: Each class should have one reason to change
2. **O** - Open/Closed Principle: Open for extension, closed for modification
3. **L** - Liskov Substitution Principle: Subtypes must be substitutable for base types
4. **I** - Interface Segregation Principle: Many specific interfaces > one general interface
5. **D** - Dependency Inversion Principle: Depend on abstractions, not concretions

### Code Smell Categories

- **Bloaters**: Long methods, large classes, primitive obsession
- **Object-Orientation Abusers**: Switch statements, alternative classes
- **Change Preventers**: Divergent change, parallel inheritance, shotgun surgery
- **Dispensables**: Comments, dead code, unnecessary abstractions
- **Couplers**: Feature envy, inappropriate intimacy, data clumps
- **Coupling**: Law of Demeter, inappropriate intimacy
- **Deodorants**: Message chains, middle man, inappropriate intimacy

### Anti-Patterns

- **Creational**: Singleton, Factory, Builder, Prototype
- **Structural**: Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy
- **Behavioral**: Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor
- **Architectural**: Front Controller, Model-View-Controller (MVC), Service Locator

---

## When to Use This Skill

**Use When:**
- User mentions quality, code quality, code health
- Reviewing code for smells or anti-patterns
- Assessing complexity or maintainability
- Establishing coding standards or conventions
- Technical debt assessment
- Code review preparation
- Refactoring guidance
- Setting up linting/formatting tools

**Do Not Use For:**
- Implementation details of specific libraries/frameworks (use framework-specific skills)
- Database queries (use `database-engineering`)
- Security vulnerabilities (use `secops-engineering`)
- Performance optimization (use `performance-engineering`)
- Testing strategies (use `testing-engineering`)

---

## Internal References

This skill does NOT reference other skills. All quality concepts are self-contained.

---

## File Structure

```
~/.config/opencode/skill/quality-engineering/
├── SKILL.md (this file)
├── assessment/
│   ├── CODE-SMELLS.md
│   ├── ANTI-PATTERNS.md
│   ├── CODE-HEALTH.md
│   ├── COMPLEXITY.md
│   └── MAINTAINABILITY.md
└── standards/
    ├── NAMING-CONVENTIONS.md
    └── CODE-STYLE.md
```
