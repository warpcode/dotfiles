---
description: >-
  Comprehensive output format design guidelines for creating skills, agents, and commands.
  Provides templates, examples, and validation protocols for all 5 operational modes.
---

# OUTPUT FORMAT DESIGN GUIDELINES

## CORE PRINCIPLES

### 1. Purpose-Driven Formats
- Each operational mode serves distinct purpose
- Design output structure to match mode intent
- Enforce mode-specific constraints

### 2. Consistency
- Same domain -> Similar output structure
- Same mode -> Similar schema across domains
- Headers, subsections, formatting conventions

### 3. Informative Density
- Maximize information per token
- STM format (Structured Telegraphic Markdown)
- Avoid conversational filler

### 4. Mode-Specific Constraints
- Define what MUST and MUST NOT be included
- Validate against mode requirements
- Ensure output fulfills mode purpose

### 5. Multi-Mode Support
- Prompts can activate multiple modes simultaneously
- Design output formats to combine modes when needed
- Maintain clarity when presenting multi-mode outputs

## MODE 1: ANALYSE/READ

### Purpose
Provide structured information without modifications. Focus on clarity, hierarchy, and quick scanning.

### When to Use
- Provide information about existing code/data
- Extract patterns, dependencies, structures
- Answer questions without making changes
- Report findings from codebase analysis

### Permissions
- Read-only tools: read, glob, grep
- No write, edit, bash
- MUST NOT modify files

### Output Format Template

```markdown
## [Analysis Topic]

### Section 1
- [Item 1]
- [Item 2]

### Section 2
[code snippet with language annotation]

[Optional: Next Steps / Recommendations]
```

### Requirements
- Use hierarchical headers (H2 → H3 → H4)
- Bullet points for lists
- Code blocks with language annotation
- Include location references (file:line) where applicable
- Avoid conversational filler

### Validation
- All sections present and properly structured
- Code blocks annotated with language
- No modification instructions included
- Location references accurate

### Multi-Mode Combinations
- **+ Write/Edit**: Analysis followed by proposed changes
- **+ Review**: Analysis with issue identification
- **+ Plan**: Analysis feeding into planning phase
- **+ Teach**: Analysis with educational explanations

### Examples

#### Example A: Dependency Analysis
```markdown
## Dependency Analysis Report

### PHP Dependencies (`/composer.json`)

#### Production Dependencies (`require`)
- **`php`**: `^8.1`
- **`laravel/framework`**: `^10.0` _(Key Framework)_

#### Development Dependencies (`require-dev`)
- **`phpunit/phpunit`**: `^10.0` _(Testing Framework)_
```

#### Example B: Architecture Overview
```markdown
## Architecture Overview

### Frontend Layer
- **Framework**: Vue.js 3
- **Build Tool**: Webpack
- **State Management**: Pinia

### Backend Layer
- **Framework**: Laravel 10
- **API**: RESTful endpoints
- **Database**: PostgreSQL
```

## MODE 2: WRITE/EDIT/UPDATE

### Purpose
Confirm creation/modification with clear change summary. Focus on change visibility and confirmation.

### When to Use
- Create new files or content
- Edit existing files
- Generate code, documentation, configurations
- Implement features or bug fixes

### Permissions
- Write/edit tools allowed
- User confirmation required for destructive operations
- Execute atomic steps with validation

### Output Format Template

```markdown
**Summary**: [Action taken] - [Files affected]

**Changes**:
- `[file:line]`: [Change description]
- `[file:line]`: [Change description]

**Example Change**:
```language
Before:
[original code]

After:
[modified code]
```

**Validation**: [Checklist passed]
```

### Requirements
- Show all files modified
- Before/after comparison for significant changes
- Line number references
- User confirmation for destructive operations
- Execute steps atomically

### Validation
- All changes documented
- Line references accurate
- User confirmed (if destructive)
- No unintended modifications

### Multi-Mode Combinations
- **+ Analyse**: Analysis followed by changes
- **+ Review**: Review findings then implement fixes
- **+ Plan**: Plan execution then implement
- **+ Teach**: Changes with educational rationale

### Examples

#### Example A: File Creation
```markdown
**Summary**: Created README.md - 1 file created

**Changes**:
- `README.md`: New file with project documentation

**Content Preview**:
```markdown
# Project Name

This is a brief description of project.
```

**Validation**: File created successfully
```

#### Example B: Code Refactoring
```markdown
**Summary**: Sorted use statements - 2 files modified

**Changes**:
- `app/Http/Controllers/ProductController.php`: Reordered use statements
- `app/Services/BillingService.php`: Reordered use statements

**Example Change** (`ProductController.php`):
```php
Before:
use App\Models\Product;
use Illuminate\Http\Request;
use App\Http\Controllers\Controller;

After:
use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
```

**Validation**: 2 files modified successfully
```

## MODE 3: REVIEW/CHECK/VALIDATE

### Purpose
Identify issues with severity classification and recommendations. Focus on prioritization and actionability.

### When to Use
- Code review and quality assessment
- Security audits
- Compliance checking
- Performance analysis

### Permissions
- Read-only (strictly enforced)
- MUST NOT create/modify/delete files
- MUST NOT execute code or commands
- MUST NOT implement fixes or corrections

### Output Format Template

```markdown
**Summary**: [PASS/FAIL/PARTIAL] - [Overall assessment]

### Critical Issues: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### High Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Medium Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Low Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

**Recommendations**: [Descriptive corrections only, NO implementations]
```

### Requirements
- Severity levels: CRITICAL, HIGH, MEDIUM, LOW
- Issues sorted by severity (CRITICAL first)
- Each issue: location + description + impact
- Recommendations must be descriptive, not code
- MUST NOT implement fixes

### Validation
- Severity hierarchy respected
- All issues include location
- No implementation code provided
- Recommendations descriptive only

### Multi-Mode Combinations
- **+ Analyse**: Review with supporting analysis
- **+ Write**: Review findings then implement fixes
- **+ Plan**: Review findings then create remediation plan
- **+ Teach**: Review with educational explanations

### Examples

#### Example A: Security Review
```markdown
**Summary**: FAIL - 2 Critical issues found

### Critical Issues: 2
- `app/Http/Controllers/UserController.php:42` - SQL Injection vulnerability - Impact: Data exfiltration, unauthorized access
- `app/Models/User.php:15` - Password stored in plaintext - Impact: Credential compromise

### High Priority: 1
- `routes/api.php:28` - Missing authentication middleware - Impact: Unauthorized API access

**Recommendations**:
- Use parameterized queries for database operations
- Hash passwords with bcrypt before storage
- Add authentication middleware to protected routes
```

#### Example B: Code Quality Review
```markdown
**Summary**: PARTIAL - 3 High priority issues

### Critical Issues: 0

### High Priority: 3
- `app/Services/PaymentService.php:78` - Function too long (156 lines) - Impact: Hard to maintain, difficult to test
- `app/Http/Controllers/ProductController.php:34` - Deep nesting (5 levels) - Impact: Reduced readability
- `app/Models/Order.php:22` - Magic number (7 days) - Impact: Unclear business logic

### Medium Priority: 2
- `app/Http/Controllers/UserController.php:56` - Unused variable `$temp` - Impact: Code clarity

**Recommendations**:
- Extract function into smaller methods
- Use early returns to reduce nesting
- Replace magic number with named constant
- Remove unused variable
```

## MODE 4: PLAN/DESIGN

### Purpose
Create structured plans without execution. Focus on clarity, feasibility, and risk assessment.

### When to Use
- JIRA ticket creation
- Architecture design
- Task breakdown and estimation
- Feasibility analysis
- System recommendations

### Permissions
- Read-only (advisory only, no execution)
- MUST NOT implement changes
- Can include point estimates when relevant

### Output Format Template

```markdown
## [Plan/Design Topic]

**Summary**: [Brief overview]

**Objectives**:
- [Objective 1]
- [Objective 2]

**Plan Structure**:
1. [Phase 1] ([Point estimate if applicable])
   - **Objective**: [Goal]
   - **Requirements**: [What's needed]
   - **Dependencies**: [What this depends on]
   - **Risks**: [Potential issues]
   - [Subtasks if applicable]

2. [Phase 2] ([Point estimate if applicable])
   - **Same structure]

**Resources Required**:
- [Resource 1]
- [Resource 2]

**Success Criteria**:
- [Criterion 1]
- [Criterion 2]
```

### Requirements
- Objectives clearly stated
- Dependencies identified
- Risks assessed
- Resources listed
- Success criteria defined
- Point estimates OPTIONAL (include only when relevant)
- MUST NOT include implementation details

### Validation
- All phases clearly defined
- Dependencies accurate
- Risks realistic
- Success criteria measurable
- No implementation instructions

### Multi-Mode Combinations
- **+ Analyse**: Analysis feeding into plan
- **+ Write**: Plan followed by implementation
- **+ Review**: Review findings then create plan
- **+ Teach**: Plan with educational rationale

### Examples

#### Example A: JIRA Ticket Breakdown
```markdown
## Implement User Export Feature

**Summary**: Add functionality for users to export their data as CSV

**Objectives**:
- Implement CSV export endpoint
- Add export job queue
- Create download link generation

**Backend Subtasks**:
1. **Add export jobs table** [1 point]
   - **Objective**: Store export job state
   - **Requirements**: Laravel queue system
   - **Dependencies**: Database migration
   - **Risks**: Queue processing failures

2. **Create export trigger endpoint** [1 point]
   - **Objective**: Initiate export process
   - **Requirements**: User authentication
   - **Dependencies**: Export jobs table
   - **Risks**: Rate limiting needed

**Success Criteria**:
- Users can request export
- Export job processes successfully
- Download link accessible for 24 hours
```

#### Example B: Architecture Design
```markdown
## Microservices Migration Strategy

**Summary**: Plan migration from monolith to microservices

**Objectives**:
- Identify service boundaries
- Design inter-service communication
- Plan data migration strategy

**Migration Phases**:

1. **Service Discovery** [2 weeks]
   - **Objective**: Identify bounded contexts
   - **Requirements**: Domain-driven design expertise
   - **Dependencies**: Current system analysis
   - **Risks**: Ambiguous service boundaries

2. **Communication Design** [1 week]
   - **Objective**: Design API contracts
   - **Requirements**: RESTful API design
   - **Dependencies**: Service boundaries identified
   - **Risks**: Version compatibility

3. **Data Migration** [3 weeks]
   - **Objective**: Plan data separation strategy
   - **Requirements**: Database expertise
   - **Dependencies**: Service contracts defined
   - **Risks**: Data consistency during transition

**Resources Required**:
- Backend developers
- DevOps engineers
- Database administrators

**Success Criteria**:
- Service boundaries clearly defined
- API contracts documented
- Data migration strategy validated
- No data loss during migration
```

## MODE 5: TEACH/EXPLAIN

### Purpose
Provide educational content with rationale, examples, and best practices. Focus on conceptual clarity and practical application.

### When to Use
- Explain technical concepts
- Teach design patterns
- Guide through best practices
- Provide rationale for decisions
- Tutorial content

### Permissions
- Read-only
- Educational explanations allowed
- No implementation required

### Output Format Template

```markdown
## [Topic/Concept]

### Purpose
[One-sentence description of what this achieves]

### What It Means
[Explanation of the concept in clear terms]

### When to Use
- [Scenario 1]
- [Scenario 2]
- [Scenario 3]

### Implementation
[code example]

### Benefits
- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

### Related Concepts
See output-format-design.md for related concepts

### Anti-Patterns
❌ **Bad Practice**: [Example of what NOT to do]

✓ **Good Practice**: [Example of correct approach]
```

### Requirements
- Explain WHY (rationale), not just WHAT/HOW
- Provide concrete examples
- Include benefits and trade-offs
- Show anti-patterns (what NOT to do)
- Reference related concepts
- Use multiple examples for clarity

### Validation
- Rationale clearly explained
- Examples practical and runnable
- Benefits clearly stated
- Anti-patterns labeled (❌ BAD, ✓ GOOD)
- Related concepts referenced

### Multi-Mode Combinations
- **+ Analyse**: Teaching with supporting analysis
- **+ Write**: Teaching then implementing
- **+ Review**: Review findings with educational explanations
- **+ Plan**: Teaching then creating plan

### Examples

#### Example A: SOLID Principles - Single Responsibility
```markdown
## Single Responsibility Principle (SRP)

### Purpose
A class should have one, and only one, reason to change.

### What It Means
- Each class should handle a single task/responsibility
- Changes to one requirement should affect only one class
- Avoid "God Objects" that do too much

### When to Use
- When a class has multiple responsibilities
- When tests are hard to write because of many dependencies
- When changing one requirement breaks unrelated functionality

### Implementation
```php
// GOOD: Separate concerns
class UserValidator {
    public function validate(User $user): bool {
        return $user->email !== '';
    }
}

class UserRepository {
    public function save(User $user): void {
        DB::table('users')->insert([...]);
    }
}

// BAD: Combined responsibilities
class UserService {
    public function validateAndSave(User $user): void {
        if ($user->email === '') {
            throw new Exception('Invalid email');
        }
        DB::table('users')->insert([...]);
    }
}
```

### Benefits
- Easier to test
- Easier to maintain
- Changes isolated to specific classes
- Clear separation of concerns

### Related Concepts
See output-format-design.md for related concepts

### Anti-Patterns
❌ **God Object**: A class that handles validation, persistence, notifications, logging, and more

✓ **Separate Classes**: Each class handles one responsibility (validation, persistence, etc.)
```

#### Example B: RESTful API Design - GET vs POST
```markdown
## GET vs POST: When to Use Which

### Purpose
Understand when to use GET vs POST requests in RESTful APIs

### What It Means
- **GET**: Retrieve data, safe, cacheable
- **POST**: Create/modify data, not safe, not cacheable

### When to Use

**GET**:
- Fetching resources
- Filtering, sorting, pagination
- Idempotent operations (same request = same result)

**POST**:
- Creating new resources
- Non-idempotent operations
- Sensitive data (not in URL)

### Implementation
```http
# GET: Fetch users
GET /api/users
GET /api/users?role=admin
GET /api/users?page=2&limit=20

# POST: Create user
POST /api/users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com"
}
```

### Benefits
- **GET**: Cacheable, bookmarkable, no side effects
- **POST**: Secure for sensitive data, creates resources, supports large payloads

### Related Concepts
See output-format-design.md for related concepts

### Anti-Patterns
❌ **BAD**: Use GET to delete resources
```http
GET /api/users/123/delete  # Wrong!
```

✓ **GOOD**: Use POST/DELETE/PUT for modifications
```http
DELETE /api/users/123  # Correct!
```
```

## MULTI-MODE HANDLING

### Principles
- Prompts can activate multiple modes simultaneously
- Design outputs to combine modes coherently
- Maintain clarity when presenting multi-mode outputs
- Order modes logically (e.g., Analyse → Review → Plan → Write)

### Common Multi-Mode Patterns

#### Pattern 1: Analyse → Review → Plan
**Use Case**: Comprehensive analysis with recommendations
```markdown
## Analysis (Analyse Mode)
[Analysis findings...]

## Review (Review Mode)
**Summary**: PARTIAL - Issues found
[Issues with severity...]

## Plan (Plan Mode)
**Recommendation Plan**:
1. Fix Critical Issues [2 days]
2. Address High Priority [1 week]
3. Implement Improvements [2 weeks]
```

#### Pattern 2: Analyse → Write
**Use Case**: Analysis followed by implementation
```markdown
## Analysis (Analyse Mode)
[Current state analysis...]

## Changes (Write Mode)
**Summary**: Implemented fixes based on analysis
[Change details...]
```

#### Pattern 3: Teach → Analyse
**Use Case**: Educational explanation with analysis
```markdown
## Concept Overview (Teach Mode)
[Educational content...]

## Code Analysis (Analyse Mode)
[Code-specific analysis applying concepts...]
```

### Guidelines for Multi-Mode Outputs
- Clearly separate each mode with headers
- Use consistent mode labels in headers
- Ensure transitions between modes are logical
- Avoid redundancy across modes
- Each mode section should stand alone

## DOMAIN-SPECIFIC CONSIDERATIONS

### When Designing Domain-Specific Output Formats

**Rule**: Tailor output formats to domain requirements while maintaining mode structure.

### API Engineering
- **Analyse**: Endpoint documentation, schema definitions
- **Write**: API implementation with request/response examples
- **Review**: Security vulnerabilities, documentation coverage
- **Plan**: API architecture, versioning strategy
- **Teach**: RESTful patterns, authentication methods

### Database Engineering
- **Analyse**: Schema documentation, query analysis
- **Write**: Migration files, model definitions
- **Review**: SQL injection, performance issues, N+1 queries
- **Plan**: Database design, indexing strategy
- **Teach**: Query optimization, normalization, transactions

### Security Engineering
- **Analyse**: Threat models, security posture
- **Write**: Security implementations (auth, encryption)
- **Review**: OWASP vulnerabilities, compliance violations
- **Plan**: Security architecture, incident response
- **Teach**: OWASP Top 10, secure coding practices

### Performance Engineering
- **Analyse**: Profiling results, metrics
- **Write**: Optimized code, caching strategies
- **Review**: Performance bottlenecks, resource leaks
- **Plan**: Performance optimization strategy
- **Teach**: Profiling techniques, caching patterns

## OUTPUT FORMAT VALIDATION CHECKLIST

### Universal Validation (All Modes)
- [ ] Structure matches template
- [ ] No conversational filler
- [ ] STM format applied (keywords + logic)
- [ ] Headers properly formatted
- [ ] Code blocks annotated with language
- [ ] Mode(s) clearly identified
- [ ] Multi-mode sections properly separated

### Mode-Specific Validation

#### Analyse/Read
- [ ] No modification instructions
- [ ] Location references accurate
- [ ] Hierarchical structure present
- [ ] Clear, scannable layout
- [ ] No execution steps

#### Write/Edit
- [ ] All changes documented
- [ ] Before/after comparisons for significant changes
- [ ] User confirmation obtained (if destructive)
- [ ] Line references accurate
- [ ] No unintended modifications

#### Review/Check
- [ ] Severity hierarchy respected (CRITICAL → HIGH → MEDIUM → LOW)
- [ ] All issues include location + description + impact
- [ ] No implementation code provided
- [ ] Recommendations descriptive only
- [ ] Read-only enforced

#### Plan/Design
- [ ] Objectives clearly stated
- [ ] Dependencies identified
- [ ] Risks assessed
- [ ] Resources listed
- [ ] Success criteria defined
- [ ] Point estimates included only when relevant
- [ ] No implementation details

#### Teach/Explain
- [ ] Rationale clearly explained (WHY)
- [ ] Examples practical and runnable
- [ ] Benefits clearly stated
- [ ] Anti-patterns labeled (❌ BAD, ✓ GOOD)
- [ ] Related concepts referenced
- [ ] Educational tone maintained

## COMMON ANTI-PATTERNS TO AVOID

### Universal Anti-Patterns
❌ **Conversational filler**: "Let me tell you about...", "Here's what I'm going to do..."
❌ **Verbose explanations**: Unnecessary repetition, wordy descriptions
❌ **Unstructured output**: No headers, no hierarchy, wall of text
❌ **Missing context**: No file references, no location indicators
❌ **Mode ambiguity**: Unclear which mode(s) are active
❌ **Multi-mode confusion**: Blurred boundaries between mode sections

### Mode-Specific Anti-Patterns

#### Analyse/Read
❌ **Including modification instructions**: "You should change X to Y"
❌ **Missing location references**: No file:line citations
❌ **Flat structure**: No hierarchy, hard to scan
❌ **Implementation details**: Code snippets, specific methods

#### Write/Edit
❌ **Missing change summary**: Just "Done" or "Fixed"
❌ **No before/after comparison**: Doesn't show what changed
❌ **Skipping user confirmation**: Destructive changes without asking
❌ **Unintended modifications**: Changes not documented

#### Review/Check
❌ **Providing implementation code**: Showing "how to fix" instead of "what to fix"
❌ **Missing severity classification**: Just listing issues without priority
❌ **Vague recommendations**: "Fix this" instead of "Use parameterized queries"
❌ **Implementing fixes**: Making changes instead of identifying issues

#### Plan/Design
❌ **Including implementation details**: Code snippets, specific methods
❌ **Missing risk assessment**: No potential issues identified
❌ **Undefined success criteria**: No way to measure completion
❌ **Implementing**: Taking action instead of planning

#### Teach/Explain
❌ **Missing rationale**: Explaining WHAT/HOW but not WHY
❌ **No examples**: Abstract explanations without concrete code
❌ **No anti-patterns**: Just showing good practice, not bad vs good
❌ **Implementation instead of teaching**: Doing instead of explaining

## PROGRESSIVE DISCLOSURE GUIDELINES

### When Output Formats Should Be Loaded

**Rule**: Load output format reference files IMMEDIATELY when mode(s) are detected.

**Detection Logic**:
1. Parse user intent from keywords and context
2. Classify intent into one or more operational modes
3. Load corresponding output format guidelines from `@references/output-format-design.md`
4. Apply domain-specific considerations if applicable
5. Combine formats if multiple modes detected

**Example**:
```markdown
IF user_intent matches "Review and fix security issues":
  -> MODES: [Review/Check, Write/Edit]
  -> LOAD: @references/output-format-design.md
  -> LOCATE: MODE 3 (Review) + MODE 2 (Write)
  -> COMBINE: Review findings section → Write changes section
  -> APPLY: Sequential output with clear mode separation
```

### Domain-Specific Reference Loading

**Rule**: After loading mode guidelines, load domain-specific references if applicable.

**Example**:
```markdown
IF user_intent matches "API security review":
  -> MODES: [Review/Check]
  -> LOAD: @references/output-format-design.md (Review mode template)
  -> LOAD: @secops-engineering/security/OWASP-TOP10.md (domain knowledge)
  -> COMBINE: Apply Review mode structure + OWASP vulnerability patterns
```

## CONCLUSION

These guidelines ensure consistent, structured, and informative output across all skills, agents, and commands in the OpenCode ecosystem.

**Key Principles**:
1. Purpose-driven formats (5 distinct modes)
2. Multi-mode support for complex operations
3. Consistency within domains
4. Informative density (STM format)
5. Mode-specific constraints
6. Progressive disclosure (load on demand)

**When Creating Skills/Agents/Commands**:
1. Identify which modes you need (single or multiple)
2. Load corresponding output format guidelines
3. Adapt templates to your domain
4. Document output format requirements for each mode
5. Implement validation checks
6. Consider multi-mode combinations if relevant
