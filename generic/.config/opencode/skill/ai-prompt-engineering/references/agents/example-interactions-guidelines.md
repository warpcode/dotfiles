# Agent Example Interactions Guidelines

## Overview

Example interactions demonstrate how users engage with agents, providing concrete use cases that guide LLM behavior. Based on analysis of 150+ agents, these guidelines ensure examples are representative, diverse, and cover all major capabilities.

## Interaction Count by Pattern

### Comprehensive Agents
- **Count**: 8-15 examples
- **Purpose**: Cover all capability categories and subcategories
- **Coverage**: Every major area of expertise

### Simplified Agents
- **Count**: None (covered in description)
- **Rationale**: Narrow scope makes examples redundant

### Specialized Agents
- **Count**: 5-10 examples
- **Purpose**: Demonstrate domain-specific workflows
- **Coverage**: Unique operational patterns

## Example Structure

### Format Standard
```markdown
## Example Interactions
- "[User prompt or question]"
- "[Another user prompt or question]"
...
```

### Content Requirements
- **Quoted strings**: All examples in double quotes
- **Natural language**: Sound like real user interactions
- **Specific intent**: Clear what the user wants
- **Representative**: Typical use cases for the agent

## Coverage Strategy

### Capability Mapping
Examples must cover all major capability areas:

**For Comprehensive Agents:**
- 2-3 design/architecture examples
- 2-3 implementation examples
- 2-3 optimization/analysis examples
- 1-2 review/audit examples
- 1-2 migration/transformation examples
- 1-2 troubleshooting examples

### Interaction Type Patterns

| Type | Pattern | Examples |
|------|---------|----------|
| **Design Request** | "Design [architecture/feature] for [use case]" | "Design a RESTful API for e-commerce" |
| **Implementation** | "Implement [feature/pattern] with [constraints]" | "Implement authentication with JWT" |
| **Optimization** | "Optimize [system/code] for [goal]" | "Optimize database queries for performance" |
| **Review/Audit** | "Review [code/system] for [criteria]" | "Review code for security vulnerabilities" |
| **Analysis** | "Analyze [system/architecture] and [action]" | "Analyze architecture and suggest improvements" |
| **Migration** | "Migrate [from] to [to] with [constraints]" | "Migrate from monolith to microservices" |
| **Troubleshooting** | "Debug/Troubleshoot [issue] in [context]" | "Debug memory leak in production service" |
| **Configuration** | "Configure [system/tool] for [environment]" | "Configure CI/CD pipeline for Kubernetes" |
| **Documentation** | "Document [system/feature] with [format]" | "Document API endpoints with OpenAPI" |
| **Testing** | "Test [component/system] for [criteria]" | "Test authentication flow for security" |

## Quality Criteria

### Representativeness
- [ ] Examples reflect real user interactions
- [ ] Cover primary use cases mentioned in description
- [ ] Include various complexity levels
- [ ] Span different capability categories

### Specificity
- [ ] Clear intent in each example
- [ ] Sufficient context provided
- [ ] Avoid vague requests ("help me", "fix this")
- [ ] Include relevant constraints or requirements

### Diversity
- [ ] Different task types (design, implement, analyze, optimize)
- [ ] Various domains within agent's scope
- [ ] Different complexity levels
- [ ] Mix of specific and general requests

### Natural Language
- [ ] Sound like actual user prompts
- [ ] Use conversational but professional tone
- [ ] Include domain-specific terminology appropriately
- [ ] Avoid overly formal or robotic language

## Generation Strategy

### Step 1: Capability Analysis
1. List all capability categories
2. Identify 2-3 subcategories per category
3. Determine interaction types for each subcategory

### Step 2: Interaction Planning
1. Map examples to capability areas
2. Ensure balanced coverage across categories
3. Plan diversity of interaction types
4. Target appropriate count for pattern

### Step 3: Example Creation
1. Write natural user prompts
2. Ensure specificity and clarity
3. Test for representativeness
4. Validate coverage completeness

### Step 4: Validation
1. Check count requirements
2. Verify capability coverage
3. Ensure diversity
4. Test natural language quality

## Domain-Specific Example Patterns

### Architecture Agents
```
"Design a microservices architecture for a high-traffic e-commerce platform"
"Create an event-driven architecture for real-time order processing"
"Design API gateway patterns for multi-tenant SaaS application"
"Implement circuit breaker patterns for external service dependencies"
"Design database sharding strategy for 1M+ users"
```

### Development Agents
```
"Implement user authentication with OAuth2 and JWT"
"Create a REST API with proper error handling and validation"
"Build a responsive dashboard with real-time data updates"
"Implement caching strategy for high-performance web application"
"Create unit tests for complex business logic"
```

### Security Agents
```
"Audit this authentication system for OWASP top 10 vulnerabilities"
"Design role-based access control for multi-tenant application"
"Implement secure API key management and rotation"
"Review code for potential SQL injection vulnerabilities"
"Design secure session management for web application"
```

### DevOps Agents
```
"Set up CI/CD pipeline with automated testing and deployment"
"Configure Kubernetes cluster for production microservices"
"Implement monitoring and alerting for cloud infrastructure"
"Design blue-green deployment strategy for zero-downtime releases"
"Set up log aggregation and analysis for distributed system"
```

## Specialized Agent Examples

### Incident Response
```
"Our production API is returning 500 errors for all requests"
"Database connection pool exhausted, causing application timeouts"
"Memory usage spiking to 95% on application servers"
"External payment service timing out during checkout"
"SSL certificate expired causing site-wide HTTPS failures"
```

### Documentation
```
"Create API documentation for user management endpoints"
"Write architecture decision record for microservices migration"
"Document deployment process for production releases"
"Create troubleshooting guide for common user issues"
"Write technical specifications for new feature implementation"
```

### Content Creation
```
"Write SEO-optimized blog post about React performance optimization"
"Create product description for new SaaS feature"
"Write technical tutorial on implementing GraphQL subscriptions"
"Create case study about successful system migration"
"Write whitepaper on cloud-native architecture patterns"
```

## Validation Checklist

### Content Validation
- [ ] Correct count for agent pattern
- [ ] All examples are quoted strings
- [ ] Examples cover major capability areas
- [ ] Diversity of interaction types
- [ ] Natural, conversational language
- [ ] Specific intent in each example

### Quality Validation
- [ ] No vague or generic prompts
- [ ] Appropriate technical detail
- [ ] Representative of real use cases
- [ ] Balanced complexity distribution
- [ ] Domain-appropriate terminology

### Coverage Validation
- [ ] All capability categories represented
- [ ] Various task types included
- [ ] Different complexity levels
- [ ] Primary use cases from description

## Common Mistakes

### Insufficient Coverage
- **Problem**: Examples only cover 2-3 capability areas
- **Fix**: Map examples to all major categories
- **Prevention**: Plan coverage before writing examples

### Vague Prompts
- **Problem**: "Help me with this" or "Fix the code"
- **Fix**: Make prompts specific and contextual
- **Prevention**: Include relevant details and constraints

### Lack of Diversity
- **Problem**: All examples are similar design requests
- **Fix**: Include different interaction types
- **Prevention**: Plan variety in interaction types

### Unnatural Language
- **Problem**: Robotic or overly formal prompts
- **Fix**: Use conversational professional language
- **Prevention**: Think about how real users would ask

### Wrong Count
- **Problem**: Too few examples for comprehensive agents
- **Fix**: Add examples to meet pattern requirements
- **Prevention**: Check pattern requirements early

## Success Criteria

Example interactions are successful when:
- Count matches pattern requirements
- All major capability areas covered
- Examples are specific and actionable
- Language is natural and representative
- Diversity across interaction types
- Appropriate technical detail level
- Clear user intent in each example
- Comprehensive coverage of agent capabilities
