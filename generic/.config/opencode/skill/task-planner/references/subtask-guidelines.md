# Subtask Guidelines

## Purpose
- Implementation-focused breakdown of main tasks
- Developer notes for technical execution
- Granular technical chunks

## Subtask Format
```
- **[Title]** [X points]
  - [Description of technical work]
```

### Format Requirements
- Title: Concise, action-oriented, clearly states technical work
- Description: Specific technical details (file paths, function names, database schema, API endpoints, etc.)
- Points: Estimated based on complexity + effort + uncertainty (0.1-5 scale)

## Focus Areas

### Database
- Create/modify tables
- Add indexes
- Write migrations
- Seed data

### Backend
- Create API endpoints
- Add business logic
- Implement services
- Add validation
- Error handling
- Authentication/authorization

### Frontend
- Create pages/components
- Add user interactions
- State management
- API integration
- UI/UX implementation

### Testing
- Unit tests
- Integration tests
- E2E tests
- Manual testing scenarios

## Examples

### Database
- **Create user sessions table** [1 point]
  - Add `user_sessions` table with columns: session_id (UUID, PK), user_id (UUID, FK), expires_at (timestamp), created_at (timestamp)
  - Add index on user_id for faster lookups
  - Add index on expires_at for cleanup queries

- **Add last login tracking** [0.5 points]
  - Create migration to add `last_login` column to `users` table (timestamp, nullable)
  - Update user login service to set `last_login` on successful authentication

### Backend
- **Create user API endpoint** [1.5 points]
  - Implement GET /api/users/:id endpoint returning user JSON with fields: id, email, name, created_at, last_login
  - Add authentication middleware (JWT token validation)
  - Add error handling for invalid token and not found (404)

- **Implement user registration service** [1.5 points]
  - Create service in `services/auth/registration.py` with function `register_user(email, password)`
  - Hash password using bcrypt with 12 salt rounds
  - Validate email format and password strength (min 8 chars, 1 uppercase, 1 number)
  - Send welcome email using existing email service

- **Add JWT authentication middleware** [1 point]
  - Create middleware in `middleware/auth.py` with function `jwt_required()`
  - Verify JWT token from Authorization header
  - Extract user_id from token payload
  - Attach user to request object for downstream handlers

- **Create export service** [2 points]
  - Implement service in `services/export.py` with function `export_users_to_csv()`
  - Query users table with batch processing (1000 rows per batch)
  - Generate CSV file with headers: id, email, name, created_at
  - Handle memory constraints using streaming writes

### Frontend
- **Create user list page** [1.5 points]
  - Create component in `components/UserList.tsx` with table displaying users
  - Add pagination controls (prev/next, page numbers)
  - Implement API call to GET /api/users with query params (page, limit)
  - Add loading state and error handling

- **Add login form** [1 point]
  - Create component in `components/LoginForm.tsx` with email and password fields
  - Add client-side validation (email format, password required)
  - Implement API call to POST /api/auth/login
  - Store JWT token in localStorage on success
  - Redirect to dashboard on successful login

- **Implement session state management** [1 point]
  - Create context in `contexts/AuthContext.tsx` for user session
  - Provide session state (user, token, isAuthenticated)
  - Implement login/logout functions
  - Persist session in localStorage

- **Add real-time updates** [1.5 points]
  - Integrate WebSocket client using existing WebSocket service
  - Subscribe to channel: `user:{user_id}`
  - Handle incoming messages and update state
  - Show notification toast on new events

### Testing
- **Write unit tests for user service** [1 point]
  - Test registration with valid email/password
  - Test registration with invalid email format
  - Test registration with weak password
  - Test login with valid credentials
  - Test login with invalid credentials

- **Add integration tests for user API** [1.5 points]
  - Test GET /api/users/:id with valid token returns user data
  - Test GET /api/users/:id with invalid token returns 401
  - Test GET /api/users/:id with non-existent ID returns 404

- **Create E2E test for login flow** [1 point]
  - Navigate to login page
  - Enter email and password
  - Click login button
  - Verify redirect to dashboard
  - Verify user is authenticated

## Constraints
- Target subtasks ≤3 points (rarely 5)
- One clear technical objective per subtask
- Avoid mixing unrelated work
- Include title and description for every subtask
- Include relevant technical details (file paths, function names, database schema, API endpoints, etc.)
