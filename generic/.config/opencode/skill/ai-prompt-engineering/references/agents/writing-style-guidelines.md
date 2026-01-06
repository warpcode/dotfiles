# Agent Writing Style Guidelines

## Overview

Agent specifications must maintain consistent, authoritative writing style across all components. Based on analysis of 150+ agent files, these guidelines ensure professional, technical communication that supports reliable LLM behavior.

## Tone and Voice Standards

### Primary Tone: Authoritative
- Expert, confident statements
- Instructional commands and directives
- Professional, technical language
- No slang, colloquialisms, or casual expressions

### Voice by Section

| Section | Voice | Perspective | Example |
|---------|--------|-------------|---------|
| **YAML Frontmatter** | Objective | System description | `model: opus` |
| **Opening Statement** | Authoritative | Identity assignment | `You are a backend architect...` |
| **Purpose** | Descriptive | Expertise definition | `Expert backend architect with...` |
| **Behavioral Traits** | Prescriptive | Behavioral expectations | `Prioritizes user experience...` |
| **Response Approach** | Instructional | Workflow instructions | `Analyze requirements...` |
| **Example Interactions** | Representative | User prompts | `"Design a REST API..."` |

## Tense Consistency Rules

### Section-Specific Tense Requirements

| Section | Primary Tense | Grammar Rules | Examples |
|---------|---------------|---------------|----------|
| **YAML Frontmatter** | Present | Objective facts | `specializing`, `masters` |
| **Opening Statement** | Present | Identity | `You are`, `specializing in` |
| **Purpose** | Present | Expertise | `Masters`, `Specializes in` |
| **Capabilities** | Present Nouns | Technical terms | `API Design`, `Pattern names` |
| **Behavioral Traits** | Present (3rd person) | -s verbs required | `Prioritizes`, `Implements` |
| **Response Approach** | Imperative | Bare verbs | `Analyze`, `Design`, `Implement` |
| **Example Interactions** | Imperative (quoted) | Quoted commands | `"Design..."`, `"Implement..."` |

### Tense Violation Examples

**❌ Incorrect:**
- Behavioral Traits: "Prioritized user experience" (past tense)
- Response Approach: "You should analyze requirements" (conditional)

**✅ Correct:**
- Behavioral Traits: "Prioritizes user experience" (present 3rd person)
- Response Approach: "Analyze requirements" (imperative)

## Sentence Structure Patterns

### Purpose Section (Comprehensive/Specialized)
```
[Expert Role] with comprehensive knowledge of [Domain List].
Masters [Skill List] and [Advanced Capability].
Specializes in [Specialization Focus] that are [Adjective List].
```

**Required:** 2-3 sentences following this exact pattern.

### Behavioral Traits
```
[Verb-s] [Noun Phrase] [Optional Prepositional Phrase]
```

**Examples:**
- "Prioritizes user experience and performance equally"
- "Implements comprehensive error handling and loading states"
- "Follows React and Next.js best practices religiously"

### Response Approach
```
[Number]. **[Phase Name]**: [Action Description with Context]
```

**Examples:**
- "1. **Understand requirements**: Business domain, scale expectations, consistency needs, latency requirements"
- "2. **Define service boundaries**: Domain-driven design, bounded contexts, service decomposition"

## Capitalization Conventions

### Section Headers
- **Rule**: Title Case for all major sections
- **Examples**: `## Capabilities`, `### API Design & Patterns`, `## Behavioral Traits`

### Subcategories (Capabilities)
- **Rule**: Title Case with bold formatting
- **Examples**: `- **RESTful APIs**: ...`, `- **GraphQL APIs**: ...`

### Technology Names
- **Rule**: Proper Case (capitalize first letter of each word)
- **Examples**: `OpenTelemetry`, `PostgreSQL`, `Kubernetes`, `React`, `Next.js`

### Acronyms
- **Rule**: ALL CAPS
- **Examples**: `OWASP`, `JWT`, `RBAC`, `ABAC`, `API`, `HTTP`

### Pattern Names
- **Rule**: Title Case
- **Examples**: `Circuit Breaker`, `Saga Pattern`, `CQRS`, `Observer Pattern`

## Punctuation Standards

### Bullet Lists
```
- **[Bold Item]**: [Description with items, separated, by commas]
```

**Rules:**
- Oxford comma required: `item1, item2, and item3`
- Item separation: `, ` (comma + space)
- Final separator: `, and ` or `, `
- No periods at end unless complete sentences

### Numbered Lists (Response Approach)
```
1. **[Phase]**: [Action]
2. **[Phase]**: [Action]
```

**Rules:**
- Number + period + space
- Bold phase name in brackets
- Colon separator
- Action description follows

### General Punctuation
- **Colons**: Used for definitions, lists, and section introductions
- **Periods**: Used only for complete sentences
- **Commas**: Oxford comma in lists, standard usage elsewhere
- **No semicolons**: Avoid in technical documentation
- **No exclamation points**: Too informal for technical specs

## Vocabulary Guidelines

### High-Frequency Action Verbs (Top 10)
1. **Design** (architectural planning)
2. **Implement** (code execution)
3. **Optimize** (performance improvement)
4. **Create** (artifact generation)
5. **Analyze** (problem assessment)
6. **Build** (system construction)
7. **Develop** (iterative creation)
8. **Plan** (strategy development)
9. **Configure** (system setup)
10. **Deploy** (production release)

### High-Frequency Nouns (Top 10)
1. **Architecture** (system design)
2. **Design** (planning artifacts)
3. **Performance** (efficiency metrics)
4. **Security** (protection measures)
5. **Patterns** (reusable solutions)
6. **Services** (system components)
7. **Data** (information assets)
8. **Systems** (integrated components)
9. **Testing** (quality assurance)
10. **Infrastructure** (underlying systems)

### Domain-Specific Terminology

#### Backend Architecture
- Service boundaries, microservices, event-driven, resilience patterns
- Circuit breaker, saga, CQRS, event sourcing, API Gateway, BFF

#### Database Design
- Normalization, denormalization, indexing, sharding
- ACID, BASE, CAP theorem, consistency models, migration

#### Security
- OWASP Top 10, JWT, OAuth2, SAML, RBAC, ABAC
- Zero-trust, defense-in-depth, least privilege

#### DevOps/Cloud
- Infrastructure as Code, GitOps, CI/CD, containers
- Kubernetes, auto-scaling, high availability
- Observability, distributed tracing, APM

### Prohibited Language

#### Slang/Colloquialisms
- ❌ "Awesome", "cool", "super"
- ❌ "Easy", "simple" (too subjective)
- ❌ "Just", "simply" (diminishing)
- ❌ "Stuff", "things" (vague)

#### Overly Casual
- ❌ "We should", "you might want to"
- ❌ "It would be good to"
- ❌ "Let's try to"

#### Vague Terms
- ❌ "Best practices" (specify which)
- ❌ "Modern approaches" (be specific)
- ❌ "Industry standards" (cite specific standards)

## Formatting Consistency

### Markdown Standards
- **Headers**: Use `#` for main, `##` for sections, `###` for subsections
- **Bold**: Use `**text**` for emphasis
- **Code**: Use backticks for `inline code`
- **Lists**: Consistent indentation (2 spaces)
- **Line breaks**: Single blank lines between sections

### Code Block Usage
- **Rare**: Only for pseudo-code or templates
- **Syntax highlighting**: Use appropriate language markers
- **Annotation**: Comments explain logic flow

### List Formatting
- **Bullets**: `- ` (dash + space)
- **Numbers**: `1. ` (number + period + space)
- **Indentation**: 2 spaces for sub-items
- **Consistency**: Same format throughout document

## Quality Checklist

### Tone Validation
- [ ] Authoritative tone maintained throughout
- [ ] No slang or colloquial expressions
- [ ] Professional technical language
- [ ] Consistent voice per section type

### Tense Validation
- [ ] Purpose uses present tense
- [ ] Behavioral traits use third-person present (-s verbs)
- [ ] Response approach uses imperative mood
- [ ] No tense mixing within sections

### Capitalization Validation
- [ ] Section headers in Title Case
- [ ] Technology names in Proper Case
- [ ] Acronyms in ALL CAPS
- [ ] Pattern names in Title Case

### Punctuation Validation
- [ ] Oxford comma used in lists
- [ ] Consistent list formatting
- [ ] Proper colon usage
- [ ] No unnecessary punctuation

### Vocabulary Validation
- [ ] Domain-specific terms used correctly
- [ ] Action verbs are specific and technical
- [ ] No vague or subjective language
- [ ] No prohibited casual expressions

### Formatting Validation
- [ ] Markdown syntax correct
- [ ] Consistent indentation
- [ ] Proper bold formatting
- [ ] Clean line breaks

## Common Style Violations

### Tense Errors
- **Problem**: Mixed tenses in behavioral traits
- **Fix**: Ensure all use third-person present
- **Prevention**: Check each trait ends with -s verb

### Capitalization Inconsistency
- **Problem**: `kubernetes` instead of `Kubernetes`
- **Fix**: Apply proper case to technology names
- **Prevention**: Reference capitalization rules

### Punctuation Issues
- **Problem**: Missing Oxford comma in lists
- **Fix**: Add comma before "and" in lists
- **Prevention**: Always include Oxford comma

### Vocabulary Problems
- **Problem**: "Awesome security features" (subjective)
- **Fix**: "OWASP-compliant security features"
- **Prevention**: Use specific, technical terms

## Success Criteria

Style is successful when:
- Tone is consistently authoritative and instructional
- Tense rules are followed strictly per section
- Capitalization conventions are applied uniformly
- Punctuation follows established patterns
- Vocabulary is domain-appropriate and precise
- Formatting is clean and consistent
- No style violations present
- Document reads as professional technical specification
