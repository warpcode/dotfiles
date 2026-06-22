# Acceptance Criteria

## Formats

### Gherkin (Given/When/Then)
Scenario-based, testable conditions in natural language

#### Structure
```
Scenario: [Scenario name]
  Given [initial state]
  When [action]
  Then [expected outcome]
```

#### Guidelines
- Clear, unambiguous steps
- Testable conditions (can be automated)
- Focus on user behavior
- One scenario per happy path/edge case

#### Examples
```
Scenario: User successfully logs in with valid credentials
  Given the user is on the login page
  When the user enters valid email and password
  And clicks the "Login" button
  Then the user is redirected to the dashboard
  And a success message is displayed

Scenario: User cannot log in with invalid credentials
  Given the user is on the login page
  When the user enters invalid email or password
  And clicks the "Login" button
  Then an error message is displayed
  And the user remains on the login page
```

### Checklist
Measurable conditions, true/false format

#### Structure
```
- [Condition 1]
- [Condition 2]
- [Condition 3]
```

#### Guidelines
- Each line is clear, measurable condition
- Testable as true/false
- Use action verbs
- Quantifiable when possible

#### Examples
```
- Export runs daily at 2 AM UTC
- CSV file includes all user actions from previous 24 hours
- File uploaded to S3 with date-based partitioning (YYYY/MM/DD/)
- Email notification sent on completion
- Export handles large datasets (>1M rows) efficiently
- Failed exports trigger alert email
```

## User Choice Workflow

### Step 1: Generate Gherkin Scenarios
- Analyze task requirements
- Generate testable scenarios
- Cover happy paths and edge cases
- Ensure scenarios are actionable

### Step 2: Present to User
- Show generated Gherkin scenarios
- Show checklist alternative
- Ask user to choose format

### Step 3: User Confirmation
Options:
- **Gherkin**: Use the generated scenarios
- **Checklist**: Convert to checklist format
- **Custom**: User provides custom acceptance criteria

## When to Use Gherkin
- Feature work with clear user flows
- Testable user interactions
- QA team uses automated testing
- Multiple scenarios (happy path + edge cases)
- Clear Given/When/Then structure possible

## When to Use Checklist
- Technical implementation details
- Non-functional requirements (performance, security)
- Simple tasks with single outcome
- Complex scenarios difficult to express in Gherkin
- Developer-focused criteria

## Best Practices
- Clear and unambiguous: No vague language
- Testable: Can be verified by QA or automated tests
- Aligned with business goals: Criteria reflect actual requirements
- Complete: Cover all acceptance conditions
- Measurable: Quantifiable when possible
- Actionable: Can be executed/tested

## Examples by Task Type

### Feature Work (Gherkin)
```
Scenario: User creates new account
  Given the user is on the registration page
  When the user enters valid email and password
  And clicks the "Sign Up" button
  Then the account should be created
  And a welcome email should be sent
  And the user should be redirected to the dashboard
```

### Technical Implementation (Checklist)
```
- API endpoint returns JSON with required fields
- Response time < 200ms for single user lookup
- Error handling covers all edge cases (invalid ID, server error)
- Rate limiting applied (100 requests/minute)
- Unit tests cover 100% of code
```

### Bug Fix (Mixed)
```
Scenario: Bug is fixed (Gherkin)
  Given the bug previously occurred
  When the user performs the same action
  Then the bug should no longer occur

Additional criteria (Checklist):
- Fix does not introduce new bugs
- Regression tests added
- Performance impact is minimal
```
