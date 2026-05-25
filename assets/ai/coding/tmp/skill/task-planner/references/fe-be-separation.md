# FE/BE Separation

## Separation Criteria

### Backend Subtasks
Focus on server-side logic, data processing, APIs

#### Database
- Create/modify tables
- Add indexes
- Write migrations
- Seed data
- Database optimization

#### API Endpoints
- REST/GraphQL endpoints
- Request/response handling
- Authentication/authorization
- Rate limiting
- Logging/monitoring

#### Business Logic
- Services layer
- Business rules
- Data processing
- Algorithms
- Workflows

#### Integration
- Third-party API integrations
- External services
- Message queues (Redis, RabbitMQ)
- Email/SMS services
- File storage (S3, etc.)

#### Infrastructure
- Cron jobs
- Background workers
- Caching layer
- Performance monitoring
- Error tracking

### Frontend Subtasks
Focus on user interface, user experience, client-side logic

#### UI Components
- Pages/screens
- Forms
- Lists/tables
- Modals/dialogs
- Navigation

#### User Interaction
- Click handlers
- Form validation
- User feedback
- Notifications/toasts
- Animations/transitions

#### State Management
- Component state
- Global state (Redux, Context, etc.)
- API client state
- Session management
- Local storage

#### API Integration
- API calls
- Data fetching
- Error handling
- Loading states
- Data transformation

#### Styling
- CSS/layout
- Responsive design
- Theme/styling
- Accessibility (a11y)
- Cross-browser compatibility

## Separation Output Format

```markdown
## Backend
- **[Subtask Title]** [X points]
  - [Description of technical work]
- **[Subtask Title]** [X points]
  - [Description of technical work]

## Frontend
- **[Subtask Title]** [X points]
  - [Description of technical work]
- **[Subtask Title]** [X points]
  - [Description of technical work]
```

## Examples

### Example 1: User Registration
```markdown
## Backend
- **Create users DB table** [1 point]
  - Add `users` table with columns: id (UUID, PK), email (unique), password_hash, created_at, last_login
  - Add index on email for faster lookups
  - Create migration file in `migrations/create_users_table.sql`

- **Create registration endpoint** [1.5 points]
  - Implement POST /api/auth/register endpoint in `api/routes/auth.py`
  - Validate email format and password strength (min 8 chars, 1 uppercase, 1 number)
  - Hash password using bcrypt with 12 salt rounds
  - Return 201 with user data (id, email, created_at) on success
  - Return 400 with validation errors on failure

- **Send welcome email** [1 point]
  - Integrate with existing email service in `services/email.py`
  - Send welcome email to new user with account details
  - Add email template in `templates/email/welcome.html`

## Frontend
- **Create registration page component** [1 point]
  - Create `pages/Register.tsx` with registration form
  - Add fields: email, password, confirm password
  - Implement client-side validation (email format, password match)
  - Add submit button with loading state

- **Implement registration API call** [0.5 points]
  - Create function `registerUser(email, password)` in `api/auth.ts`
  - Call POST /api/auth/register with JSON payload
  - Handle success response (store token, redirect)
  - Handle error response (display validation errors)

- **Add user feedback** [0.5 points]
  - Show success toast on successful registration
  - Show error toast on registration failure
  - Display field-specific validation errors
```

### Example 2: Data Export
```markdown
## Backend
- **Create export jobs table** [1 point]
  - Add `export_jobs` table with columns: id (UUID, PK), user_id, status, file_path, created_at, completed_at
  - Add index on user_id and status for queries
  - Create migration file in `migrations/create_export_jobs_table.sql`

- **Create export trigger endpoint** [1 point]
  - Implement POST /api/exports/trigger endpoint in `api/routes/exports.py`
  - Validate user has export permission
  - Create export job record with status "pending"
  - Return 201 with job_id on success

- **Implement export service** [2 points]
  - Create service in `services/export.py` with function `export_user_activity(user_id, date_range)`
  - Query user activities from database with batch processing (1000 rows per batch)
  - Generate CSV file with headers: id, user_id, action, timestamp, details
  - Handle large datasets (>1M rows) efficiently using streaming

- **Add S3 upload service** [1.5 points]
  - Create service in `services/s3.py` with function `upload_to_s3(file_path, bucket, key)`
  - Implement multipart upload for large files (>100MB)
  - Add error handling for upload failures
  - Return S3 URL on successful upload

- **Configure cron job** [0.5 points]
  - Add cron configuration to call export endpoint at 2 AM UTC
  - Create background worker to process export jobs
  - Add error logging and alerting

## Frontend
- **Create export status page** [1 point]
  - Create `pages/ExportStatus.tsx` with export history table
  - Display columns: date, status, file size, download link
  - Add pagination (10 items per page)

- **Add export trigger button** [0.5 points]
  - Add "Export Now" button in export status page
  - Call POST /api/exports/trigger on click
  - Show loading state while triggering export

- **Implement real-time updates** [1 point]
  - Integrate WebSocket client for export status updates
  - Subscribe to channel `export:{user_id}`
  - Update export status in real-time when status changes
  - Show notification toast on export completion
```

## Rules
1. NEVER share subtasks between frontend and backend - always separate
2. Clear labeling in output format
3. Frontend subtasks focus on UI/UX, user interaction
4. Backend subtasks focus on server-side logic, data, APIs
5. Ensure both layers have complete subtask breakdowns
6. If a task spans both layers, split into distinct frontend and backend subtasks
