# Review Mode: Software Engineering

**Purpose**: Exhaustive review checklists for software architecture, code quality, design patterns, and refactoring

## EXHAUSTIVE LOADING STRATEGY

### Comprehensive Review Checklists
Load all relevant patterns for exhaustive code review:
- **Code Architecture**: `@architecture/CLEAN-ARCHITECTURE.md`, `@design/DESIGN-VIOLATIONS.md`
- **Design Patterns**: `@patterns/DESIGN-PATTERNS.md`, `@patterns/ANTI-PATTERNS.md`
- **Code Smells**: `@patterns/CODE-SMELLS.md`
- **Security**: `@security/CODE-INJECTION.md`
- **Performance**: `@performance/COMMON-ISSUES.md`
- **Refactoring**: `@refactoring/CODE-MODERNIZATION.md`, `@refactoring/MODERN-LANGUAGE-FEATURES.md`
- **SOLID Principles**: `@principles/SOLID.md`

## ARCHITECTURAL REVIEW

### SOLID Principles Violations
- [ ] **Single Responsibility Principle (SRP)**
  - Class doing too many things (God Object)
  - Class changed for multiple reasons
  - Method with multiple responsibilities

- [ ] **Open/Closed Principle (OCP)**
  - Code requires modification to extend functionality
  - Hard-coded conditions instead of polymorphism
  - Tight coupling preventing extension

- [ ] **Liskov Substitution Principle (LSP)**
  - Subclass breaking parent class contract
  - Inappropriate inheritance (e.g., Square extending Rectangle)
  - Violating behavioral subtyping

- [ ] **Interface Segregation Principle (ISP)**
  - Fat interfaces with too many methods
  - Classes implementing unused methods
  - No interface segregation for different use cases

- [ ] **Dependency Inversion Principle (DIP)**
  - Depending on concrete implementations
  - High-level modules depending on low-level modules
  - No use of abstraction/interfaces

### Clean Architecture Violations
- [ ] **No Layered Structure**: Business logic mixed with presentation/data access
- [ ] **Dependency Rule Violated**: Dependencies point inward (wrong direction)
- [ ] **Tight Coupling**: Components tightly coupled to implementation details
- [ ] **No Abstraction**: Direct dependencies on concrete classes
- [ ] **Framework Dependencies**: Business logic depends on framework

### Design Violations
- [ ] **Tight Coupling**: Classes depend on each other directly (hard to test/maintain)
- [ ] **Circular Dependencies**: Classes depend on each other in a cycle
- [ ] **God Object**: One class controlling everything
- [ ] **Feature Envy**: Methods using another class's data
- [ ] **Shotgun Surgery**: One change requires modifying multiple classes
- [ ] **Parallel Inheritance**: Inheritance hierarchies growing in parallel
- [ ] **Data Clumps**: Grouped parameters that should be class

## CODE SMELLS

### Long Methods
- [ ] **Method Length**: Methods > 50 lines (extract to smaller methods)
- [ ] **Complex Logic**: Too many branches/nested conditions (extract methods)
- [ ] **Multiple Responsibilities**: Method doing too much (split into methods)

### Deep Nesting
- [ ] **Nesting Depth**: Nesting > 4 levels (use early returns/guard clauses)
- [ ] **Arrow Code**: Excessive indentation making code hard to read
- [ ] **Complex Conditions**: Nested if/else statements (extract methods)

### Duplicate Code
- [ ] **Copy-Paste**: Same code in multiple places (extract to method)
- [ ] **Similar Code**: Slight variations of same logic (generalize)
- [ ] **Duplicated Logic**: Same logic implemented differently

### Magic Numbers
- [ ] **Unexplained Literals**: Numeric literals without explanation (use named constants)
- [ ] **Magic Strings**: String literals without explanation (use constants)
- [ ] **Hardcoded Values**: Configuration values in code

### Large Classes
- [ ] **Too Many Methods**: Class > 20 methods (split into smaller classes)
- [ ] **Too Many Fields**: Class > 10 fields (extract to classes)
- [ ] **Multiple Responsibilities**: Class doing too much (SRP violation)

### Feature Envy
- [ ] **Using Other Class Data**: Method heavily using another class's data
- [ ] **Wrong Responsibility**: Method should belong to other class
- [ ] **Intimacy Violation**: Too intimate with another class's internals

### Data Clumps
- [ ] **Grouped Parameters**: Multiple parameters always passed together (extract to object)
- [ ] **Related Data**: Data items that belong together (create class)

### Inappropriate Intimacy
- [ ] **Accessing Private Data**: Using reflection to access private members
- [ ] **Breaking Encapsulation**: Directly accessing internal implementation
- [ ] **Tight Coupling**: Too dependent on implementation details

### Primitive Obsession
- [ ] **Using Primitives**: Using primitives instead of classes (create Value Objects)
- [ ] **No Encapsulation**: Data scattered in primitives
- [ ] **Lost Domain Concepts**: Domain concepts not represented

## DESIGN PATTERNS

### Missing Design Patterns
- [ ] **Factory Pattern**: Should use factory for object creation
- [ ] **Strategy Pattern**: Should use strategy for interchangeable algorithms
- [ ] **Observer Pattern**: Should use observer for event handling
- [ ] **Adapter Pattern**: Should use adapter for interface compatibility
- [ ] **Decorator Pattern**: Should use decorator for adding behavior dynamically
- [ ] **Facade Pattern**: Should use facade to simplify complex subsystem

### Anti-Patterns
- [ ] **God Object**: Single object controlling everything
- [ ] **Spaghetti Code**: Code without structure, hard to follow
- [ ] **Ravioli Code**: Too many small objects without cohesion
- [ ] **Magic Numbers**: Unexplained numeric literals
- [ ] **Golden Hammer**: Using same solution for every problem
- [ ] **Boat Anchor**: Unused code kept "just in case"
- [ ] **Lava Flow**: Dead/frozen code that can't be changed
- [ ] **Poltergeists**: Classes with no real responsibility

## CODE INJECTION VULNERABILITIES

### Injection Flaws
- [ ] **SQL Injection**: Concatenating user input into SQL queries (CRITICAL)
- [ ] **Command Injection**: User input in system commands (CRITICAL)
- [ ] **Code Injection**: eval(), include() with user input (CRITICAL)
- [ ] **Template Injection**: User input in template engines (CRITICAL)
- [ ] **Expression Language Injection**: User input in expression evaluation (CRITICAL)

### Buffer Overflows
- [ ] **Fixed Buffers**: Using fixed-size buffers without bounds checking (CRITICAL)
- [ ] **Unsafe Functions**: Using strcpy, sprintf instead of safe alternatives
- [ ] **Integer Overflow**: Not checking integer bounds before operations

### Deserialization Attacks
- [ ] **Unsafe Deserialization**: Deserializing untrusted data (CRITICAL)
- [ ] **Object Injection**: Passing user-controlled serialized objects
- [ ] **Type Confusion**: Type confusion via deserialization

## PERFORMANCE ISSUES

### Memory Leaks
- [ ] **Unclosed Resources**: Not closing database connections, file handles
- [ ] **Circular References**: Objects referencing each other preventing GC
- [ ] **Caches Not Cleared**: Caches growing without bounds
- [ ] **Event Listeners**: Not removing event listeners (memory leak)

### Resource Exhaustion
- [ ] **No Limits**: No limits on resource usage (file size, memory, etc.)
- [ ] **Unbounded Loops**: Loops that don't terminate
- [ ] **Resource Monopolization**: Not releasing resources

### Race Conditions
- [ ] **Shared State**: Multiple threads accessing shared state without locks
- [ ] **Check-Then-Act**: Time-of-check to time-of-use race conditions
- [ ] **Deadlocks**: Potential deadlock in locking strategy

### Inefficient Algorithms
- [ ] **O(n^2) Where O(n) Possible**: Inefficient nested loops
- [ ] **Unnecessary Iteration**: Iterating when O(1) lookup possible
- [ ] **No Memoization**: Repeating expensive computations

## REFACTORING ISSUES

### Code Modernization
- [ ] **Old Array Syntax**: Using `array()` instead of `[]`
- [ ] **Deprecated Functions**: Using deprecated language functions
- [ ] **Missing Type Hints**: No parameter or return type hints
- [ ] **Not Using Modern Features**: Not using modern language features
- [ ] **Legacy Patterns**: Using outdated coding patterns

### Dead Code
- [ ] **Unused Functions**: Functions never called
- [ ] **Unused Variables**: Variables assigned but never used
- [ ] **Unreachable Code**: Code that can never execute
- [ ] **Commented Code**: Large blocks of commented code (remove or document)

### Code Organization
- [ ] **Poor File Structure**: Files in wrong locations
- [ ] **Long Files**: Files > 500 lines (split into smaller files)
- [ ] **Missing Namespaces**: Code not organized by namespaces
- [ ] **Circular Imports**: Import cycles between files

## REFACTORING SUGGESTIONS

### Extract Method
- **When**: Method doing too much, complex logic, duplicated code
- **How**: Extract logic to separate method with meaningful name
- **Benefit**: Smaller methods, easier to understand, reusable

### Extract Class
- **When**: Class doing too much, multiple responsibilities
- **How**: Split into smaller classes with single responsibilities
- **Benefit**: Follows SRP, easier to test and maintain

### Introduce Parameter Object
- **When**: Multiple parameters always passed together
- **How**: Create object to hold related parameters
- **Benefit**: Cleaner method signatures, encapsulation

### Replace Conditional with Polymorphism
- **When**: Large switch/if-else chains on type
- **How**: Use polymorphism (subclasses with different behavior)
- **Benefit**: Open/Closed principle, easier to extend

### Replace Magic Number with Constant
- **When**: Unexplained numeric literals
- **How**: Extract to named constant
- **Benefit**: Self-documenting, easier to change

### Extract Interface
- **When**: Concrete class directly used, tight coupling
- **How**: Create interface, implement in concrete class
- **Benefit**: Dependency Inversion, easier to mock/test

## MODERN LANGUAGE FEATURES

### Type Hints
- [ ] **Missing Parameter Types**: Parameters lack type hints
- [ ] **Missing Return Types**: Functions lack return type hints
- [ ] **Mixed Types**: Using `mixed` type where specific type possible
- [ ] **Type Coercion**: Implicit type conversions causing bugs

### Modern Syntax
- [ ] **Null Coalescing**: Using isset() instead of `??`
- [ ] **Spaceship Operator**: Multiple comparisons instead of `<=>`
- [ ] **Array Syntax**: Using `array()` instead of `[]`
- [ ] **Short Ternary**: Not using `?:` where appropriate
- [ ] **Match Expression**: Using switch instead of `match` (PHP 8+)

### Deprecated API Replacements
- [ ] **mysql_* functions**: Use PDO/mysqli instead
- [ ] **ereg_* functions**: Use preg_* functions instead
- [ ] **split()**: Use explode() or preg_split() instead
- [ ] **each()**: Use foreach instead
- [ ] **mysql_escape_string()**: Use prepared statements instead

## OUTPUT FORMAT

### Review Report Output
```markdown
## Software Engineering Review Report

### Critical Issues (CRITICAL - Fix Immediately)

1. **[Issue Name]**: [File:line]
   - Severity: CRITICAL
   - Category: [Architecture/Code Smell/Security/Performance]
   - Description: [Detailed issue description]
   - Impact: [What could happen if not fixed]
   - Refactoring: [Specific refactoring suggestion]
   - Example: [Before/After code examples]
   - Reference: @patterns/[SPECIFIC-PATTERN].md or @modes/REVIEW-MODE.md

### High Priority Issues (HIGH - Fix Soon)

[Same format as Critical]

### Medium Priority Issues (MEDIUM - Consider Fixing)

[Same format as Critical]

### Low Priority Issues (LOW - Nice to Have)

[Same format as Critical]

### Architectural Issues
- **SOLID Violations**: [List violations found]
- **Design Violations**: [List violations found]
- **Missing Patterns**: [Patterns that should be used]
- **Anti-Patterns**: [Anti-patterns found]

### Code Quality Issues
- **Code Smells**: [List code smells with locations]
- **Modernization**: [Modern features to adopt]
- **Dead Code**: [Unused code to remove]
- **Code Organization**: [Organization issues]

### Security Issues
- **Injection Flaws**: [Locations and types]
- **Deserialization**: [Unsafe deserialization locations]
- **Buffer Overflows**: [Potential overflow locations]

### Performance Issues
- **Memory Leaks**: [Potential leak locations]
- **Race Conditions**: [Race condition locations]
- **Inefficient Algorithms**: [Locations of inefficient code]

### Refactoring Recommendations
1. [Specific refactoring suggestion with example]
2. [Specific refactoring suggestion with example]
3. [Specific refactoring suggestion with example]

### Modernization Recommendations
1. [Modern language feature to adopt]
2. [Deprecated function to replace]
3. [Type hint to add]

### Related Skills
- @database-engineering/SKILL.md (for SQLi, query optimization)
- @secops-engineering/SKILL.md (for OWASP Top 10, security best practices)
- @performance-engineering/SKILL.md (for performance optimization)
```
