# API Security

**Purpose**: Guide for securing REST and GraphQL APIs against common vulnerabilities

## AUTHENTICATION

### Authentication Methods

#### Basic Authentication
```http
GET /api/users
Authorization: Basic dXNlcm46cmVzdwMTp4U2UzdwMTp4

# Weak: Base64 encoding, easily reversible
# Use HTTPS to protect credentials in transit
```

#### Bearer Token (JWT)
```http
GET /api/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiAibGRhdSIsInRyb3VuLmVzIiIjoxMjA0ODYwZCI6IjoiYWRkYXQiLCJhbGxlLmJlYXBkL2xlcmVtZCI6IjoiYXNkYWJhIiwiYSIifQ"
```

#### API Keys
```http
GET /api/users
X-API-Key: your-api-key-here

# Best practice: Rotate API keys regularly
# Use environment variables for API key storage
```

#### OAuth2.0
```http
# Authorization Code Flow
GET /oauth/authorize?response_type=code&client_id=CLIENT_ID&redirect_uri=REDIRECT_URI

# Exchange for access token
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

code=AUTHORIZATION_CODE&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&redirect_uri=REDIRECT_URI&grant_type=authorization_code

# Access token request
GET /api/users
Authorization: Bearer ACCESS_TOKEN
```

### Authentication Best Practices
- **HTTPS Only**: Never use HTTP for authentication
- **Strong Secrets**: Minimum 32 characters, mix of characters
- **Hashing Passwords**: Use bcrypt, Argon2, scrypt
- **Token Expiration**: Set appropriate token expiration
- **Token Revocation**: Implement token revocation on logout
- **Token Refresh**: Use refresh tokens to reduce re-authentication
- **Rate Limiting**: Protect authentication endpoints from brute force

## AUTHORIZATION

### Role-Based Access Control (RBAC)
```javascript
// Express middleware example
function authorize(...roles) {
  return (req, res, next) => {
    const user = req.user; // Set by authentication middleware

    if (!user || !user.roles) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const hasRole = roles.some(role => user.roles.includes(role));
    
    if (!hasRole) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    next();
  };
}

// Usage
app.get('/admin/dashboard', authorize('admin'), adminDashboardHandler);
```

### Resource-Based Access Control (ABAC)
```javascript
// Express middleware example
function authorizeResource(action, resource) {
  return (req, res, next) => {
    const user = req.user;
    
    const hasPermission = user.permissions.some(
      perm => perm.resource === resource && perm.actions.includes(action)
    );

    if (!hasPermission) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    next();
  };
}

// Usage
app.get('/posts/:id', authorizeResource('read', 'post'), getPostHandler);
app.put('/posts/:id', authorizeResource('update', 'post'), updatePostHandler);
app.delete('/posts/:id', authorizeResource('delete', 'post'), deletePostHandler);
```

### Attribute-Based Access Control (ABAC)
```javascript
// Example: Check user attributes for access
function checkAttributes(attributes, req, res, next) {
  const user = req.user;

  for (const [key, value] of Object.entries(attributes)) {
    if (user[key] !== value) {
      return res.status(403).json({ error: 'Forbidden' });
    }
  }

  next();
}

// Usage: Only users with is_verified=true can access
app.get('/premium-content', checkAttributes({ is_verified: true }), premiumContentHandler);
```

## INPUT VALIDATION

### Request Validation
```javascript
// Express validation example using Joi
const Joi = require('joi');

const userSchema = Joi.object({
  name: Joi.string().min(3).max(50).required(),
  email: Joi.string().email().required(),
  age: Joi.number().integer().min(18).max(120),
  role: Joi.string().valid('admin', 'user', 'guest')
});

function validateRequest(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        error: 'Validation error',
        details: error.details
      });
    }

    req.validatedData = value;
    next();
  };
}

// Usage
app.post('/api/users', validateRequest(userSchema), createUserHandler);
```

### URL Parameter Validation
```javascript
// Validate route parameters
const idSchema = Joi.string().pattern(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);

function validateParams(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.params);

    if (error) {
      return res.status(400).json({
        error: 'Invalid URL parameter',
        details: error.details
      });
    }

    req.validatedParams = value;
    next();
  };
}

// Usage
app.get('/api/users/:id', validateParams(idSchema), getUserHandler);
```

### Query String Validation
```javascript
// Validate query string
const querySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sort: Joi.string().valid('name', 'email', 'created_at').default('created_at'),
  order: Joi.string().valid('asc', 'desc').default('desc')
});

function validateQuery(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.query);

    if (error) {
      return res.status(400).json({
        error: 'Invalid query parameters',
        details: error.details
      });
    }

    req.validatedQuery = value;
    next();
  };
}

// Usage
app.get('/api/users', validateQuery(querySchema), getUsersHandler);
```

## OUTPUT ENCODING

### JSON Output
```javascript
// Express example - Automatically sets Content-Type
app.get('/api/users', (req, res) => {
  const users = await getUsers();

  // Express automatically sets: Content-Type: application/json
  res.json({ users, meta: { total: users.length } });
});
```

### Error Responses
```javascript
// Standard error response format
function handleError(err, req, res, next) {
  console.error(err);

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal server error';

  res.status(statusCode).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

// Usage
app.use(handleError);
```

### Sensitive Data in Error Messages
```javascript
// BAD: Exposes sensitive data in errors
app.use((err, req, res, next) => {
  res.status(500).json({
    error: err.message,
    password: req.body.password  // SECURITY ISSUE
  });
});

// GOOD: Sanitize error messages
app.use((err, req, res, next) => {
  res.status(500).json({
    error: 'Internal server error'  // Generic message
    // Stack trace only in development
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});
```

## RATE LIMITING

### Fixed Window Rate Limiting
```javascript
// Express example using express-rate-limit
const rateLimit = require('express-rate-limit');

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// Apply to all API routes
app.use('/api/', apiLimiter);

// Stricter limits for authentication endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts, please try again later.'
});

app.post('/api/auth/login', authLimiter, loginHandler);
```

### Dynamic Rate Limiting
```javascript
// Custom rate limiting based on user role
const userRateLimits = {
  free: { windowMs: 15 * 60 * 1000, max: 100 },
  user: { windowMs: 15 * 60 * 1000, max: 1000 },
  admin: { windowLimit: 15 * 60 * 1000, max: 10000 }
};

const dynamicRateLimiter = (req, res, next) => {
  const user = req.user;
  const rateLimit = userRateLimits[user.role] || userRateLimits.free;

  const limiter = rateLimit({
    windowMs: rateLimit.windowMs,
    max: rateLimit.max,
    message: 'Rate limit exceeded'
  });

  limiter(req, res, next);
};

app.use('/api/', dynamicRateLimiter);
```

### API Key-Based Rate Limiting
```javascript
const rateLimitByApiKey = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  keyGenerator: (req) => req.apiKey || 'anonymous',
  handler: (req, res) => {
    res.status(429).json({ error: 'Too many requests from this API key' });
  }
});

app.use('/api/v2/', rateLimitByApiKey);
```

## CORS CONFIGURATION

### CORS Headers
```javascript
// Express CORS middleware
const cors = require('cors');

// Basic CORS - allow all origins (not recommended for production)
app.use(cors());

// Production CORS - whitelist origins
app.use(cors({
  origin: ['https://example.com', 'https://app.example.com'],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true, // Allow cookies
  maxAge: 86400 // Cache preflight requests for 24 hours
}));

// CORS for specific endpoints
app.options('/api/users', cors());
app.get('/api/users', cors(), getUsersHandler);
```

### CORS with Dynamic Origins
```javascript
const allowedOrigins = [
  'https://example.com',
  'https://app.example.com',
  'https://admin.example.com'
];

const corsOptions = {
  origin: (origin, callback) => {
    if (!allowedOrigins.includes(origin)) {
      return callback(new Error('Not allowed by CORS'));
    }
    callback(null, origin);
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  credentials: true,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));
```

### Preflight Requests
```javascript
// OPTIONS requests are sent by browsers before actual requests
// Must respond with proper CORS headers
app.options('/api/*', cors());
```

## SQL INJECTION PREVENTION

### Parameterized Queries
```javascript
// BAD: SQL injection vulnerability
app.get('/api/users/:id', (req, res) => {
  const query = `SELECT * FROM users WHERE id = '${req.params.id}'`;  // SQLi
  db.query(query, (err, results) => { ... });
});

// GOOD: Parameterized query
app.get('/api/users/:id', async (req, res, next) => {
  try {
    // Use parameterized queries
    const query = 'SELECT * FROM users WHERE id = $1';
    const [user] = await db.query(query, [req.params.id]);
    
    if (user.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: user[0] });
  } catch (error) {
    console.error('Database error:', error);
    return res.status(500).json({ error: 'Database error' });
  }
}, validateParams(idSchema));
```

### ORM Sanitization
```javascript
// Sequelize (Node.js) - automatic sanitization
// Parameters are automatically escaped
User.findAll({
  where: {
    email: req.query.email
  }
});

// TypeORM (Node.js) - automatic sanitization
import { User } from './entities/user.entity';
import { Like } from './entities/like.entity';
import { Repository } from 'typeorm';

userRepository: Repository<User> = DataSource.getRepository(User);

const users = await userRepository.find({
  where: {
    email: req.query.email
  }
});

// Mongoose (Node.js) - use query builder (safer than raw queries)
User.findOne({ email: req.query.email });
```

### Input Sanitization
```javascript
// Use validation library instead of manual sanitization
const validator = require('validator');

function sanitizeInput(input) {
  // Trim whitespace
  return validator.trim(input);
}

function validateEmail(email) {
  return validator.isEmail(email);
}

function validateId(id) {
  return validator.isNumeric(id) && validator.isLength(id, 1, 2147483647);
}

// Middleware
app.use((req, res, next) => {
  if (req.body.email) {
    req.body.email = sanitizeInput(req.body.email);
    if (!validateEmail(req.body.email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
  }

  if (req.params.id) {
    req.params.id = sanitizeInput(req.params.id);
    if (!validateId(req.params.id)) {
      return res.status(400).json({ error: 'Invalid ID format' });
    }
  }
  next();
});
```

## SECURITY HEADERS

### Security Headers Middleware
```javascript
function securityHeaders(req, res, next) {
  // Content Security Policy
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';");

  // HSTS
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');

  // X-Frame-Options (prevent clickjacking)
  res.setHeader('X-Frame-Options', 'DENY');

  // X-Content-Type-Options (prevent MIME sniffing)
  res.setHeader('X-Content-Type-Options', 'nosniff');

  // X-XSS-Protection
  res.setHeader('X-XSS-Protection', '1; mode=block');

  // Referrer Policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');

  // Remove X-Powered-By (information disclosure)
  res.removeHeader('X-Powered-By');

  next();
}

app.use(securityHeaders);
```

### Content Security Policy (CSP)
```javascript
// Basic CSP
app.use((req, res, next) => {
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' " +
    "style-src 'self' 'unsafe-inline' " +
    "img-src 'self' data: https: " +
    "connect-src 'self' " +
    "font-src 'self' data: " " +
    "object-src 'none'; " +
    "base-uri 'self'; " +
    "form-action 'self'; " +
    "frame-ancestors 'none'; " +
    "upgrade-insecure-requests');  // HTTP to HTTPS
  );
  next();
});

// CSP with inline scripts (not recommended, but sometimes necessary)
app.use((req, res, next) => {
  res.setHeader('Content-Security-Policy',
    "default-src 'self'; " +
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' " +
    "style-src 'self' 'unsafe-inline'; " +
    "img-src 'self' data: https: " +
    "font-src 'data: ;"
  );
  next();
});
```

## API KEY MANAGEMENT

### API Key Generation
```javascript
const crypto = require('crypto');

function generateApiKey() {
  // Generate 32-byte random key
  const apiKey = crypto.randomBytes(32).toString('hex');
  
  // Format: key-prefix_xxxxxxxxxxxx (easier to identify)
  const prefix = 'sk';
  const keyBody = apiKey.slice(0, 32);

  return `${prefix}_${keyBody}`;
}

// Example
const newApiKey = generateApiKey();
console.log(newApiKey); // sk_a1b2c3d4e5f67890abcdef1234567890
```

### API Key Storage
```javascript
// Hash API key before storing (bcrypt)
const bcrypt = require('bcrypt');

async function hashApiKey(apiKey) {
  const saltRounds = 10;
  return await bcrypt.hash(apiKey, saltRounds);
}

// Verify API key
async function verifyApiKey(apiKey, hashedKey) {
  return await bcrypt.compare(apiKey, hashedKey);
}

// Hashed key storage in database
await User.create({
  name: 'John Doe',
  email: 'john@example.com',
  apiKeyHashed: await hashApiKey('sk_a1b2c3d4e5f67890abcdef1234567890')
});
```

### API Key Rotation Strategy
```javascript
// API key rotation endpoint
app.post('/api/rotate-apikey', authenticate, async (req, res) => {
  const { apiKeyId } = req.body;
  const user = req.user;

  // Generate new API key
  const newApiKey = generateApiKey();
  const newHashedKey = await hashApiKey(newApiKey);

  // Update database
  await UserApiKey.updateOne(
    { _id: apiKeyId, userId: user.id },
    { keyHash: newHashedKey, rotatedAt: new Date() }
  );

  // Return new API key (only time user can see it)
  res.json({
    message: 'API key rotated successfully',
    apiKey: newApiKey,  // Only shown once
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
  });
});
```

## COMMON API VULNERABILITIES

### Broken Access Control
```javascript
// BAD: Missing authorization check
app.post('/api/admin/users', (req, res) => {
  // No authorization check - anyone can create admin users
  const user = await User.create(req.body);
  res.status(201).json(user);
});

// GOOD: Authorization check
app.post('/api/admin/users', authenticate, authorize('admin'), async (req, res) => {
  const user = await User.create(req.body);
  res.status(201).json(user);
});
```

### Insecure Direct Object References (IDOR)
```javascript
// BAD: User can access other users' data by guessing ID
app.get('/api/users/:userId', (req, res) => {
  const user = await User.findById(req.params.userId);
  // No authorization check - any user can get any user's data
  res.json(user);
});

// GOOD: Authorization check
app.get('/api/users/:userId', authenticate, async (req, res) => {
  const currentUser = req.user;
  const requestedUser = await User.findById(req.params.userId);

  // Only allow users to access their own data (unless admin)
  if (!currentUser.roles.includes('admin') && currentUser.id !== requestedUser.id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  res.json(requestedUser);
});
```

### Security Misconfiguration
```javascript
// BAD: Debug mode enabled in production
app.get('/api/users', (req, res) => {
  const users = await User.findAll();
  
  // Returns error details in response (security issue)
  res.json({ users, dbError: err.message });
});

// GOOD: Generic error messages in production
app.get('/api/users', async (req, res, next) => {
  try {
    const users = await User.findAll();
    res.json({ users });
  } catch (error) {
    console.error('Error:', error);
    next(error);
  }
}, (err, req, res, next) => {
  // Generic error message
  res.status(500).json({ error: 'Internal server error' });
});
```

### Sensitive Data in URLs
```javascript
// BAD: Sensitive data in query parameters
app.get('/api/users?token=secret123', (req, res) => {
  // Token in URL - may be logged or cached
  res.json({ users });
});

// GOOD: Sensitive data in headers or body
app.get('/api/users', authenticate, async (req, res) => {
  // Token in Authorization header (not logged)
  res.json({ users });
});
```

### Excessive Data Exposure
```javascript
// BAD: Returns entire user object including internal data
app.get('/api/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);

  res.json({
    id: user.id,
    name: user.name,
    email: user.email,
    password: user.password, // SECURITY ISSUE - Exposed password
    role: user.role,
    ssn: user.ssn,      // SECURITY ISSUE - Exposed sensitive data
    createdAt: user.createdAt,
    updatedAt: user.updatedAt
  });
});

// GOOD: Return only necessary fields
app.get('/api/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id, {
    attributes: ['id', 'name', 'email', 'role']
  });

  res.json(user);
});
```

## BEST PRACTICES

### Authentication & Authorization
- ✅ Always use HTTPS for production APIs
- ✅ Implement strong authentication (JWT, OAuth2)
- ✅ Use role-based or attribute-based authorization
- ✅ Implement token expiration and refresh mechanisms
- ✅ Rotate API keys regularly
- ✅ Log authentication failures for security monitoring

### Input Validation
- ✅ Validate all input (URL params, query strings, request body)
- ✅ Use validation libraries (Joi, Zod, Yup)
- ✅ Validate data types, lengths, formats, ranges
- ✅ Sanitize input before using it
- ✅ Never trust user input, always validate

### Output Encoding
- ✅ Always return JSON with proper Content-Type header
- ✅ Sanitize error messages (don't expose stack traces in production)
- ✅ Use generic error messages for production
- ✅ Limit data exposure (only return necessary fields)

### CORS Configuration
- ✅ Whitelist allowed origins in production
- ✅ Use HTTPS only for production
- ✅ Configure appropriate methods (GET, POST, PUT, PATCH, DELETE)
- ✅ Enable credentials if needed (cookies)
- ✅ Set appropriate cache headers for preflight requests

### Rate Limiting
- ✅ Implement rate limiting on all public endpoints
- ✅ Use stricter limits for authentication endpoints
- ✅ Implement API key-based rate limiting where appropriate
- ✅ Log rate limit violations for security monitoring
- ✅ Consider tiered rate limits (free, basic, premium, enterprise)

### Security Headers
- ✅ Set CSP headers to prevent XSS
- ✅ Set HSTS to force HTTPS
- ✅ Set X-Frame-Options to prevent clickjacking
- ✅ Set X-Content-Type-Options to prevent MIME sniffing
- ✅ Set X-XSS-Protection
- ✅ Set Referrer-Policy to control referrer info

### API Key Security
- ✅ Generate strong, random API keys
- ✅ Hash API keys before storing
- ✅ Provide API key only once (on creation or rotation)
- ✅ Allow users to view and rotate their own API keys
- ✅ Implement API key expiration dates
- ✅ Log API key usage for security monitoring

### Testing
- ✅ Test all authentication and authorization endpoints
- ✅ Test for SQL injection vulnerabilities
- ✅ Test for XSS in API responses
- ✅ Test CORS configuration
✅ Test rate limiting
- ✅ Test security headers are present
- ✅ Use automated security scanning tools (OWASP ZAP, Burp Suite)
