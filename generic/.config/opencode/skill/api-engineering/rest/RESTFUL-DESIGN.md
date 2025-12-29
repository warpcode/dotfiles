# RESTful API Design

**Purpose**: Guide for designing RESTful APIs following best practices and conventions

## REST PRINCIPLES

### Resource-Oriented Design
- **Nouns over Verbs**: Use resources (users, posts) not actions (getUsers, createPost)
- **URI Structure**: `/resources/{id}` not `/actions/{resource}`
- **Plural vs Singular**: Use plural for collections (users, posts)

### HATEOAS (Hypermedia as the Engine of Application State)
- **Self-Describing**: API includes links to related resources
- **State Transitions**: Include links for state changes
- **Discoverable**: Start at root, follow links to discover API

### Stateless Communication
- **No Server State**: Each request contains all needed context
- **Sessionless**: Don't rely on server-side sessions
- **Idempotent**: Same request = same result (GET, PUT, DELETE)

### Cacheability
- **GET Requests**: Should be cacheable by default
- **POST/PUT/DELETE**: Invalidate cache
- **Cache Headers**: Use ETag, Last-Modified, Cache-Control

## HTTP METHODS

### GET - Retrieve Resources
```http
GET /api/users                    # List all users
GET /api/users/{id}               # Get specific user
GET /api/users?role=admin       # Filter users
GET /api/users?sort=name&order=asc  # Sort results
GET /api/users?page=2&limit=20  # Pagination
```

### POST - Create Resource
```http
POST /api/users                   # Create new user
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com"
}

Response: 201 Created
Location: /api/users/{new-id}
```

### PUT - Replace Resource
```http
PUT /api/users/{id}               # Full replacement
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com"
}

Response: 200 OK
```

### PATCH - Partial Update
```http
PATCH /api/users/{id}            # Partial update
Content-Type: application/json

{
  "name": "Jane Doe"  // Only update name
}

Response: 200 OK
```

### DELETE - Remove Resource
```http
DELETE /api/users/{id}            # Delete user

Response: 204 No Content
```

## URI DESIGN

### Resource Hierarchy
```
/api/users                       # Users collection
/api/users/{id}                  # Specific user
/api/users/{id}/posts            # User's posts
/api/users/{id}/posts/{id}       # Specific post
/api/users/{id}/comments/{id}  # Comment on post
```

### Query Parameters
```http
# Filtering
GET /api/users?role=admin&status=active

# Sorting
GET /api/users?sort=created_at&order=desc

# Pagination
GET /api/users?page=1&limit=20

# Field Selection
GET /api/users?fields=id,name,email

# Full-text search
GET /api/users?q=search_term
```

### Versioning
```http
# URL path versioning
GET /api/v1/users
GET /api/v2/users

# Header versioning
GET /api/users
Accept: application/vnd.api.v1+json

# Query parameter versioning
GET /api/users?version=1
```

## STATUS CODES

### Success Codes
- **200 OK**: Request succeeded
- **201 Created**: Resource created successfully
- **202 Accepted**: Request accepted for processing
- **204 No Content**: Request succeeded but no content returned (DELETE)

### Redirection Codes
- **301 Moved Permanently**: Resource permanently moved
- **302 Found**: Resource temporarily moved
- **304 Not Modified**: Resource not modified (use ETag/Last-Modified)

### Client Error Codes
- **400 Bad Request**: Malformed request
- **401 Unauthorized**: Authentication required
- **403 Forbidden**: No permission to access resource
- **404 Not Found**: Resource not found
- **405 Method Not Allowed**: HTTP method not supported
- **409 Conflict**: Request conflicts with current state
- **422 Unprocessable Entity**: Well-formed but semantic errors
- **429 Too Many Requests**: Rate limiting exceeded

### Server Error Codes
- **500 Internal Server Error**: Server error
- **502 Bad Gateway**: Invalid response from upstream server
- **503 Service Unavailable**: Service temporarily unavailable
- **504 Gateway Timeout**: Upstream server timeout

## REQUEST/RESPONSE FORMATS

### JSON Request/Response
```json
// Request
{
  "name": "John Doe",
  "email": "john@example.com"
}

// Response
{
  "id": "123",
  "name": "John Doe",
  "email": "john@example.com",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

### Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "email": ["Email is required"]
    }
  }
}
```

### Paginated Response
```json
{
  "data": [
    { "id": "1", "name": "User 1" },
    { "id": "2", "name": "User 2" }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  },
  "links": {
    "self": "/api/users?page=1&limit=20",
    "first": "/api/users?page=1&limit=20",
    "last": "/api/users?page=5&limit=20",
    "next": "/api/users?page=2&limit=20"
  }
}
```

## VALIDATION

### Request Validation
- **Required Fields**: Return 400 with missing fields
- **Type Checking**: Validate data types (string, number, boolean, array, object)
- **Format Validation**: Email format, date format, UUID format
- **Range Validation**: Numeric ranges, date ranges
- **Business Logic**: Unique constraints, business rules

### Validation Examples
```json
// Bad request
{
  "email": "invalid-email",  // Invalid email format
  "age": -5               // Negative age (should be >= 0)
}

// Validation response
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "email": ["Email must be valid"],
      "age": ["Age must be >= 0"]
    }
  }
}
```

## AUTHENTICATION

### Basic Authentication
```http
GET /api/users
Authorization: Basic dXNlcm46cmVzdwMTp4U2VzYWJkZXJvd2VyZGly
```

### Bearer Token (JWT)
```http
GET /api/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJodGUiLCJleHAiOiJleHAifQ
```

### API Key
```http
GET /api/users
X-API-Key: your-api-key-here
```

## PAGINATION STRATEGIES

### Offset/Limit Pagination
```http
GET /api/users?page=2&limit=20

// Response
{
  "data": [...],
  "meta": {
    "page": 2,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

### Cursor-Based Pagination
```http
GET /api/users?cursor=abc123&limit=20

// Response
{
  "data": [...],
  "meta": {
    "next_cursor": "xyz789",
    "has_more": true
  }
}
```

### Keyset Pagination
```http
GET /api/users?last_id=50&limit=20

// Response
{
  "data": [...],
  "meta": {
    "last_id": 100,
    "has_more": true
  }
}
```

## FILTERING AND SORTING

### Filtering
```http
# Equality
GET /api/users?role=admin

# Multiple filters
GET /api/users?role=admin&status=active

# Range filtering
GET /api/users?age_gte=18&age_lte=65

# Partial match
GET /api/users?name=John

# Array filtering
GET /api/users?tags[]=technology&tags[]=programming
```

### Sorting
```http
# Single field sort
GET /api/users?sort=created_at

# Multiple field sort
GET /api/users?sort=created_at,name&order=asc

# Reverse sort
GET /api/users?sort=created_at&order=desc
```

## RATE LIMITING

### Rate Limiting Headers
```http
GET /api/users
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1722585600
```

### Rate Limiting Strategies
- **Fixed Window**: Reset every time period (e.g., per minute)
- **Sliding Window**: Count requests in rolling time window
- **Token Bucket**: Tokens replenish at fixed rate
- **Leaky Bucket**: Tokens leak at constant rate

## CORS CONFIGURATION

### CORS Headers
```http
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Expose-Headers: X-Request-Id
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 86400
```

### Preflight Request
```http
OPTIONS /api/users
Origin: https://example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization

Response: 204 No Content
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: POST
Access-Control-Allow-Headers: Content-Type, Authorization
```

## HATEOAS EXAMPLE

### Self-Describing Response
```json
{
  "id": "123",
  "name": "John Doe",
  "email": "john@example.com",
  "posts": "/api/users/123/posts",
  "self": "/api/users/123"
}
```

### State Transitions
```json
{
  "id": "123",
  "status": "pending",
  "self": "/api/orders/123",
  "approve": "/api/orders/123/approve",
  "cancel": "/api/orders/123/cancel",
  "refund": "/api/orders/123/refund"
}
```

## BEST PRACTICES

### Consistent Naming
- **Kebab-case** for paths: `/api/user-profiles`
- **snake_case** for JSON fields: `created_at`, `updated_at`
- **PascalCase** for class names in code (not JSON)

### Versioning Strategy
- **URL Path**: `/api/v1/users` (recommended)
- **Header**: `Accept: application/vnd.api.v1+json`
- **Never Breaking Changes**: Add new versions, don't modify existing

### Error Handling
- **Consistent Error Format**: Always use same error structure
- **Use Appropriate Status Codes**: Choose correct HTTP status code
- **Provide Error Details**: Include validation errors, debugging info
- **Log Errors**: Log all errors server-side for debugging

### Security
- **HTTPS Only**: Never use HTTP for production APIs
- **Authentication**: Implement proper authentication (JWT, OAuth2, API keys)
- **Authorization**: Implement proper authorization (role-based, resource-based)
- **Rate Limiting**: Protect against abuse and DDoS
- **Input Validation**: Always validate and sanitize input
- **CORS**: Configure CORS properly for frontend
- **Security Headers**: Add security headers (CSP, HSTS, etc.)

### Performance
- **Pagination**: Always paginate large datasets
- **Compression**: Use gzip compression
- **Caching**: Cache GET responses with appropriate headers
- **Database Optimization**: Use efficient queries (N+1 prevention)
- **Indexing**: Add database indexes for filtered/sorted fields

### Documentation
- **OpenAPI/Swagger**: Document API with OpenAPI/Swagger
- **Examples**: Provide request/response examples
- **Error Codes**: Document all error codes
- **Changelog**: Track API changes
- **Deprecation**: Document deprecated endpoints with timeline
