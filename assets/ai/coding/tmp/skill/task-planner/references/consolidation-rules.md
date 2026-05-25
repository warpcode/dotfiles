# Consolidation Rules

## When to Consolidate

### Merge Related Work
- IF subtasks share same codebase area → Combine
- IF subtasks are part of same feature/component → Combine
- IF subtasks are small (≤0.5 points) and related → Combine

### Examples
- "Create API endpoint" + "Add validation to endpoint" → "Create API endpoint with validation"
  - **Create user API endpoint** [1.5 points] + **Add validation to user endpoint** [0.3 points]
  - → **Create user API endpoint with validation** [1.8 points]

- "Add DB table" + "Add indexes to table" → "Create DB table with indexes"
  - **Add users table** [0.5 points] + **Add indexes to users table** [0.2 points]
  - → **Create users DB table with indexes** [0.7 points]

- "Create page component" + "Add styling to page" → "Create and style page component"
  - **Create user list component** [0.5 points] + **Add styling to user list** [0.3 points]
  - → **Create and style user list component** [0.8 points]

### Don't Merge IF
- Subtasks span different layers (e.g., DB + Frontend)
- Subtasks have different objectives (e.g., create + delete)
- Subtasks have different points (e.g., 0.1 + 2.5)
- Subtasks have different dependencies/risks

## When to Split

### Split Large Subtasks
- IF subtask >3 points → Break down further
- IF subtask has multiple objectives → Break down further
- IF subtask spans multiple layers → Break down further

### Examples
- "Create full authentication system (login, register, password reset)" → Split into:
  - **Implement login API** [1.5 points] - POST /api/auth/login endpoint with JWT token generation
  - **Implement login frontend** [0.5 points] - Login form with email/password fields and validation
  - **Implement registration API** [1.5 points] - POST /api/auth/register endpoint with password hashing
  - **Implement registration frontend** [0.5 points] - Registration form with email/password fields
  - **Implement password reset API** [2 points] - Password reset flow with email token and password update
  - **Implement password reset frontend** [1 point] - Password reset form and email input

- "Create user management dashboard" → Split into:
  - **Create user list page** [2 points] - User list component with table and pagination
  - **Add user filtering** [1 point] - Filter by email, name, status with API query params
  - **Create user detail page** [2 points] - User detail component with edit form
  - **Implement user update** [1.5 points] - PUT /api/users/:id endpoint with validation
  - **Add bulk delete** [1 point] - Delete multiple users with API endpoint
  - **Add bulk export** [1 point] - Export selected users to CSV file

### Don't Split IF
- Subtask is already small (≤1 point)
- Subtask is atomic operation
- Splitting creates excessive granularity (e.g., 0.1 point tasks)

## Validation Workflow

### After Point Estimation
1. Review all subtasks and their point estimates
2. Identify subtasks >3 points → Mark for splitting
3. Identify subtasks ≤0.5 points that are related → Mark for consolidation
4. Apply consolidation/splitting rules
5. Re-estimate points for modified subtasks
6. Verify final subtasks meet ≤3 point target

### Example
Initial subtasks:
- **Add DB table for users** [0.5 points]
- **Add indexes to users table** [0.2 points]
- **Create user API endpoint** [2 points]
- **Add validation to user endpoint** [0.3 points]

After consolidation:
- **Create users DB table with indexes** [0.7 points]
  - Add `users` table with columns: id, email, password_hash, created_at, last_login
  - Add index on email for faster lookups
  - Add index on last_login for cleanup queries

- **Create user API endpoint with validation** [2.3 points]
  - Implement GET /api/users/:id endpoint returning user JSON
  - Add email format validation in request handler
  - Add error handling for invalid token and not found (404)

## Target
- Subtasks ≤3 points (rarely 5)
- Avoid excessive granularity (≤0.1 points)
- Balance between granularity and consolidation
- Each subtask should be completable in focused work session
