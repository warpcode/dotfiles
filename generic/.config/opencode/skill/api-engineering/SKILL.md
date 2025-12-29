---
name: api-engineering
description: >-
  Domain specialist for API design, development, and best practices. Expertise includes RESTful API design, GraphQL, API documentation (OpenAPI/Swagger), versioning, authentication, authorization, rate limiting, CORS, error handling, pagination, filtering, HATEOAS, API testing, and API security. Use when: API design, REST API development, GraphQL implementation, API documentation, API security, API versioning, rate limiting, CORS configuration. Triggers: "API", "REST", "GraphQL", "endpoint", "OpenAPI", "Swagger", "API documentation", "CORS", "rate limiting", "API authentication", "API versioning".
---

# API_ENGINEERING

## DOMAIN EXPERTISE
- **Common Issues**: Missing authentication, no rate limiting, inconsistent error responses, missing CORS headers, no pagination, poor error handling, insecure endpoints, version conflicts, missing documentation, over-fetching/under-fetching
- **Common Mistakes**: Using GET for state-changing operations, inconsistent naming conventions, missing status codes, no error codes, over-complicating API design, breaking changes without versioning, missing input validation, not using HTTPS, exposing internal errors
- **Related Patterns**: RESTful design principles, GraphQL best practices, HATEOAS, API versioning strategies, authentication patterns (JWT, OAuth2), rate limiting algorithms, pagination patterns, error handling standards, API documentation standards
- **Problematic Patterns**: God endpoints (too much functionality), inconsistent API design, versioning in URL path, missing pagination, no rate limiting, no CORS configuration, exposing internal data in errors
- **Security Concerns**: SQL injection in endpoints, XSS in responses, CSRF in state-changing endpoints, broken authentication, missing authorization, CORS misconfiguration, API key leakage, rate limiting bypass, replay attacks
- **Performance Issues**: N+1 queries in endpoints, over-fetching data, under-fetching data requiring multiple requests, no caching, missing compression, large payloads, inefficient database queries
- **API Design**: Resource-oriented design, consistent naming conventions, proper HTTP methods, status codes, content negotiation, pagination, filtering, sorting

## MODE DETECTION
- **WRITE Mode**: Keywords: ["create", "generate", "write", "build", "implement", "add", "new", "design API", "create endpoint", "implement REST", "build GraphQL"]
- **REVIEW Mode**: Keywords: ["review", "analyze", "audit", "check", "find issues", "API review", "security audit", "API design review"]

## LOADING STRATEGY
### Write Mode (Progressive)
Load patterns based on API requirements:
- REST API questions -> Load `@rest/RESTFUL-DESIGN.md`
- GraphQL questions -> Load `@graphql/GRAPHQL-PATTERNS.md`
- Documentation questions -> Load `@documentation/OPENAPI.md`
- Security questions -> Load `@security/API-SECURITY.md`

### Review Mode (Exhaustive)
Load comprehensive checklists:
- IF API review requested -> Load all API patterns
- IF security review requested -> Load `@security/API-SECURITY.md`
- IF design review requested -> Load `@rest/RESTFUL-DESIGN.md`, `@graphql/GRAPHQL-PATTERNS.md`

## CONTENT STRUCTURE
```
api-engineering/
├── rest/
│   └── RESTFUL-DESIGN.md
├── graphql/
│   └── GRAPHQL-PATTERNS.md
├── documentation/
│   └── OPENAPI.md
└── security/
    └── API-SECURITY.md
```

## ROUTING LOGIC
### Progressive Loading (Write Mode)
- **IF** request mentions "REST", "RESTful", "endpoint", "resource" -> READ FILE: `@rest/RESTFUL-DESIGN.md`
- **IF** request mentions "GraphQL", "query", "mutation", "schema" -> READ FILE: `@graphql/GRAPHQL-PATTERNS.md`
- **IF** request mentions "OpenAPI", "Swagger", "documentation" -> READ FILE: `@documentation/OPENAPI.md`
- **IF** request mentions "CORS", "authentication", "authorization", "rate limiting" -> READ FILE: `@security/API-SECURITY.md`

### Comprehensive Loading (Review Mode)
- **IF** request mentions "review", "audit", "analyze" -> READ FILES: All API patterns
- **IF** request mentions "API security" -> Load `@security/API-SECURITY.md`, REST security patterns
- **IF** request mentions "API design" -> Load REST/GraphQL design patterns

## CONTEXT DETECTION
### API Style Detection
- **REST API**: RESTful endpoints, HTTP methods (GET, POST, PUT, DELETE), resource URLs
- **GraphQL**: GraphQL schema, queries, mutations, subscriptions, GraphiQL
- **gRPC**: Protocol Buffers, gRPC service definitions, .proto files
- **SOAP**: WSDL files, SOAP envelope, XML payloads
- **WebSocket**: WebSocket connections, Socket.IO, real-time APIs

### Framework Detection
#### REST Frameworks
- **Express**: package.json with "express", app.get(), app.post(), router
- **NestJS**: package.json with "@nestjs/*", @Controller, @Get decorators
- **Django REST**: drf (Django Rest Framework), rest_framework in requirements.txt
- **Laravel API**: Laravel, API routes, Laravel Sanctum/Passport
- **Spring Boot**: @RestController, @RequestMapping, Spring Web MVC

#### GraphQL Frameworks
- **Apollo**: package.json with "@apollo/*", Apollo Server/Client
- **Express-GraphQL**: package.json with "express-graphql", graphqlHTTP
- **GraphQL Yoga**: package.json with "graphql-yoga", GraphQL Yoga Server
- **Absinthe (Ruby)**: Absinthe gem in Gemfile
- **Graphene (Python)**: graphene in requirements.txt

### Protocol Detection
- **HTTP/1.1**: Standard HTTP requests, no HTTP/2 push
- **HTTP/2**: Binary protocol, multiplexing, header compression
- **HTTP/3**: QUIC transport, UDP-based, improved performance
- **WebSocket**: ws://, wss:// protocols, real-time communication
- **gRPC**: HTTP/2, Protocol Buffers, .proto definitions

### API Version Detection
- **URL Path Versioning**: `/api/v1/users` (common, but not recommended)
- **Header Versioning**: `Accept: application/vnd.api.v1+json` (recommended)
- **Query Parameter Versioning**: `/api/users?version=1` (not recommended)
- **Content Negotiation**: Version in media type (recommended)

## WHEN TO USE THIS SKILL
✅ Use when:
- Designing RESTful APIs
- Implementing GraphQL schemas
- Creating API documentation (OpenAPI/Swagger)
- Implementing API authentication (JWT, OAuth2, API keys)
- Adding CORS support
- Implementing rate limiting
- Handling API errors and status codes
- API versioning strategies
- Pagination, filtering, sorting
- API testing and validation

❌ Do NOT use when:
- Backend business logic (use software-engineering)
- Database design (use database-engineering)
- Frontend API consumption (use frontend-engineering)
- Infrastructure (use devops-engineering)
- Security operations beyond API (use secops-engineering)

## EXECUTION PROTOCOL

### Phase 1: Analysis
1. **Detect Mode**: WRITE vs REVIEW based on keywords
2. **Detect Context**: API style (REST/GraphQL), framework, protocol
3. **Load Patterns**: Progressive (write) or Exhaustive (review)
4. **Detect Multi-Domain**: Check if additional skills needed (database, security, performance)

### Phase 2: Execution (Write Mode)
1. Load relevant API pattern references
2. Design API according to REST/GraphQL best practices
3. Implement authentication/authorization
4. Add CORS, rate limiting as needed
5. Implement proper error handling
6. Provide OpenAPI/Swagger documentation
7. Follow framework conventions (Express, NestJS, Django REST, Laravel)

### Phase 3: Execution (Review Mode)
1. Load all API checklist references
2. Systematically check each category:
   - REST/GraphQL design issues
   - Security vulnerabilities (authentication, authorization, injection)
   - CORS configuration
   - Error handling
   - Rate limiting
   - Documentation completeness
   - Performance issues (N+1 queries, over-fetching)
3. Provide prioritized issues with severity levels

### Phase 4: Validation
- Verify API follows design principles
- Check security (HTTPS, authentication, rate limiting)
- Ensure proper status codes and error responses
- Validate documentation completeness
- Check for cross-references (MUST be within skill only)

## MULTI-DOMAIN LOADING
### When to Load Additional Skills

**Context Detection Triggers**:
- **Database Operations**: If database queries or ORM usage in endpoints -> LOAD: `@database-engineering/SKILL.md`
- **Security Concerns**: If authentication, authorization, or security mentioned -> LOAD: `@secops-engineering/SKILL.md`
- **Performance Issues**: If slow endpoints, N+1 queries, or performance mentioned -> LOAD: `@performance-engineering/SKILL.md`
- **Code Architecture**: If refactoring or code quality mentioned -> LOAD: `@software-engineering/SKILL.md`

**Detection Rules**:
1. **Analyze Request**: Scan for keywords and file types
2. **Determine Context**: Identify primary domain (API) and secondary domains
3. **Load Primary Skill**: This skill (api-engineering) with appropriate patterns
4. **Load Secondary Skills**: If secondary domain detected, load relevant skill from that skill's SKILL.md

**Example Scenario**:
```
User: "Review this REST API endpoint for SQL injection and performance issues"

Analysis:
- Primary: api (REST API)
- Secondary 1: database (SQL injection)
- Secondary 2: performance (performance issues)

Load:
1. api-engineering/SKILL.md (RESTFUL-DESIGN.md, API-SECURITY.md)
2. database-engineering/SKILL.md (SQL-INJECTION.md, INDEXING.md)
3. performance-engineering/SKILL.md (QUERY-OPTIMIZATION.md, PROFILING.md)
```

## OUTPUT FORMAT

### Write Mode Output
```markdown
## API Design: [Endpoint/Resource]

### API Style
[REST / GraphQL / gRPC]

### Framework
[Express / NestJS / Django REST / Laravel]

### Implementation
```http/JavaScript/TypeScript/Python/PHP
[API endpoint implementation]
```

### Authentication
- [Authentication method: JWT, OAuth2, API Key]
- [Authorization implementation]

### Security
- [CORS configuration]
- [Rate limiting strategy]
- [Input validation]

### HTTP Design
- [HTTP methods]
- [Status codes]
- [Error responses]

### Related Patterns
@rest/[specific-pattern].md
```

### Review Mode Output
```markdown
## API Review Report

### Critical Issues
1. **[Issue Name]**: [Endpoint/File:line]
   - Severity: CRITICAL
   - Category: [Security/Design/Performance/Documentation]
   - Description: [Issue details]
   - Impact: [Security vulnerability / Poor UX / Performance degradation]
   - Fix: [Recommended remediation]
   - Reference: @rest/[specific-pattern].md or @security/[specific-pattern].md

### High Priority Issues
[Same format]

### Medium Priority Issues
[Same format]

### Low Priority Issues
[Same format]

### Design Assessment
- **REST Principles**: [Compliant / Issues found]
- **Naming Conventions**: [Consistent / Inconsistent]
- **HTTP Methods**: [Correct usage / Issues found]
- **Status Codes**: [Appropriate / Incorrect]

### Security Assessment
- **Authentication**: [Implemented / Missing / Weak]
- **Authorization**: [Implemented / Missing / Weak]
- **CORS**: [Properly configured / Misconfigured]
- **Rate Limiting**: [Implemented / Missing / Weak]
- **Input Validation**: [Implemented / Missing / Weak]

### Performance Assessment
- **N+1 Queries**: [Found / Not found]
- **Over-fetching**: [Found / Not found]
- **Under-fetching**: [Found / Not found]
- **Caching**: [Implemented / Missing]
- **Compression**: [Enabled / Disabled]

### Documentation Assessment
- **OpenAPI/Swagger**: [Complete / Incomplete]
- **Examples**: [Provided / Missing]
- **Error Documentation**: [Provided / Missing]

### Recommendations
1. [API design improvement]
2. [Security improvement]
3. [Performance optimization]
4. [Documentation improvement]

### Related Skills
- @database-engineering/SKILL.md (for SQLi, N+1, query optimization)
- @secops-engineering/SKILL.md (for OWASP Top 10, security best practices)
- @software-engineering/SKILL.md (for code quality issues)
- @performance-engineering/SKILL.md (for performance profiling, optimization)
```
