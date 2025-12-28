# Point Estimation Rubric

## Point Scale
- 0.1 = 1 hour (quick task)
- 0.5 = 4 hours (half day)
- 1 = 1 day (8 hours)
- 2 = 2 days
- 3 = 3 days
- 4 = 4 days
- 5 = 5 days (rare, should be split)

## Factors

### 1. Complexity
- **Low**: Straightforward implementation, existing patterns, clear requirements
- **Medium**: Some complexity, minor unknowns, requires integration
- **High**: Complex logic, multiple integrations, significant unknowns

### 2. Effort
- **Low**: Small code change, minimal files, simple configuration
- **Medium**: Moderate code change, multiple files, some configuration
- **High**: Large code change, many files, complex configuration

### 3. Uncertainty
- **Low**: Well-defined requirements, familiar tech stack, no unknowns
- **Medium**: Some requirements clarity, familiar tech, minor unknowns
- **High**: Vague requirements, unfamiliar tech, many unknowns

## Estimation Matrix

### 0.1 Points (1 Hour)
- Complexity: Low, Effort: Low, Uncertainty: Low
- Examples:
  - Add simple validation rule
  - Fix minor bug
  - Add simple UI component
  - Update configuration

### 0.5 Points (Half Day / 4 Hours)
- Complexity: Low, Effort: Medium, Uncertainty: Low
- OR Complexity: Medium, Effort: Low, Uncertainty: Low
- Examples:
  - Create simple API endpoint
  - Add DB table with migration
  - Create page component with styling
  - Write unit tests for single function

### 1 Point (1 Day / 8 Hours)
- Complexity: Medium, Effort: Medium, Uncertainty: Low
- OR Complexity: Low, Effort: High, Uncertainty: Low
- Examples:
  - Create API endpoint with validation
  - Implement authentication flow
  - Create full page with state management
  - Write integration tests for feature

### 2 Points (2 Days)
- Complexity: Medium, Effort: Medium, Uncertainty: Medium
- OR Complexity: High, Effort: Medium, Uncertainty: Low
- Examples:
  - Implement complex business logic
  - Create full feature (API + frontend)
  - Migrate to new library/framework
  - Implement real-time updates

### 3 Points (3 Days)
- Complexity: High, Effort: Medium, Uncertainty: Medium
- OR Complexity: Medium, Effort: High, Uncertainty: Medium
- Examples:
  - Implement complex multi-step workflow
  - Integrate third-party service
  - Performance optimization
  - Implement caching layer

### 4 Points (4 Days)
- Complexity: High, Effort: High, Uncertainty: Medium
- Examples:
  - Implement complex feature with multiple integrations
  - Major refactoring
  - Implement distributed system component

### 5 Points (5 Days - Rare, Should Split)
- Complexity: High, Effort: High, Uncertainty: High
- **ACTION**: Break down into smaller subtasks

## Estimation Process

1. Review subtask description and technical details
2. Assess Complexity (Low/Medium/High)
3. Assess Effort (Low/Medium/High)
4. Assess Uncertainty (Low/Medium/High)
5. Consult matrix to determine point estimate
6. Provide justification: Complexity + Effort + Uncertainty = X points

## Guidelines
- Be conservative: Better to overestimate than underestimate
- Consider dependencies and coordination
- Account for testing and code review
- Factor in familiar vs unfamiliar tech stack
- Include buffer for unexpected issues
- Validate against consolidation rules (≤3 points target)
