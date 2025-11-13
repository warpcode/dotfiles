# AGENTS.md

## Agent Usage Guidelines

- **ALWAYS Check for Relevant Agents:** Before performing any task, the AI MUST check if a relevant agent or subagent exists that can handle the task more effectively.
- **Prioritize Specialized Agents:** Use specialized agents (code-writer, code-reviewer, commit-message-writer, etc.) for their designated purposes rather than handling tasks manually.
- **Agent Discovery:** When encountering a task, first determine if any available subagents are designed to handle it.
- **Quality Assurance:** Use agents designed for quality control (code-reviewer, spelling-grammar-checker) to ensure high standards.
- **Efficiency:** Leverage agents to perform complex tasks more accurately and efficiently than manual approaches.

## Git Commit Guidelines

- **Authorization Required:** AI must NEVER commit changes without explicit user approval.
- **Permission Protocol:** Always ask permission before committing, propose the commit message first.
- **Approval Mandate:** Do not commit unless user explicitly approves, even for additional changes or follow-ups.
- **No Auto-Commits:** Strict prohibition on automatic commits; user consent is mandatory for every commit action.
- **No Auto-Pushes:** AI must NEVER push git changes to remote repositories unless specifically requested by the user.

## Available Agents

### `adhd-task-breaker`

**Description:** A specialized advisor that decomposes complex, multi-step tasks into smaller, manageable subtasks to improve focus and productivity, especially for individuals with ADHD.

**When to use:** When a user presents a complex, multi-step task that needs to be decomposed into smaller, manageable subtasks to improve focus and productivity, especially for individuals with ADHD.

### `agent-writer`

**Description:** A specialized agent that generates new agent configurations from user requirements or reviews existing agent configurations for completeness, clarity, and adherence to best practices.

**When to use:** When you need to generate new agent configurations from user requirements or when reviewing existing agent configurations for completeness, clarity, and adherence to best practices.

### `code-reviewer`

**Description:** A comprehensive code reviewer that combines all specialized code review aspects including security vulnerabilities, logic bugs, performance issues, architecture problems, code smells, maintainability concerns, testing gaps, documentation issues, and language-specific best practices.

**When to use:** For complete, comprehensive code reviews that need multiple specialized perspectives and thorough analysis of all code quality dimensions.

### `code-writer`

**Description:** A code writer agent that creates new code files and modifies existing code with extremely high attention to detail for code quality, automatically running comprehensive code review orchestration to ensure quality standards are met.

**When to use:** When you need to create new code files from scratch or modify existing code with rigorous quality control and mandatory review processes.

### `commit-message-writer`

**Description:** A specialized agent that generates descriptive and conventional commit messages based on provided context of code changes, following best practices like conventional commits.

**When to use:** When you need to generate a descriptive and conventional commit message based on the provided context of code changes, such as file modifications, additions, or deletions.

### `documentation-writer`

**Description:** A specialized documentation writer that creates, improves, and ensures documentation quality across code comments, docblocks, markdown files, and wiki documentation, focusing on making documentation legible, concise, and informative while emphasizing 'why' explanations over redundant 'what' descriptions.

**When to use:** For creating or enhancing documentation with proper focus on rationale and clarity, such as adding appropriate docblocks and inline comments focusing on 'why' rather than 'what'.

### `fact-checker`

**Description:** A fact-checker agent that meticulously validates changes to code, documentation, or content for factual accuracy, completeness, intent preservation, and context retention, providing systematic analysis and detailed reports on discrepancies without making any modifications.

**When to use:** When you need to verify that changes preserve all critical facts, behaviors, and context from the original. Ideal for reviewing refactors, rewrites, imports, or any modifications where factual integrity is paramount.

### `spelling-grammar-checker`

**Description:** A specialized spelling and grammar checker that identifies spelling errors, grammatical mistakes, and language clarity issues in text, documentation, comments, and user-facing content.

**When to use:** For validating text quality and language correctness, such as reviewing documentation for spelling and grammatical errors.

### `task-manager`

**Description:** A task management agent that helps users organize and track tasks using Taskwarrior CLI, providing comprehensive task management including creation, modification, organization, and reporting with Taskwarrior's rich feature set for projects, tags, priorities, due dates, and recurring tasks.

**When to use:** For organizing and tracking tasks using Taskwarrior CLI, such as adding tasks with project and due date, showing pending tasks, or organizing work tasks.

### `personal-productivity/adhd-task-breaker`

**Description:** Use this agent for breaking down complex, NON-TECHNICAL, real-world tasks into a manageable, step-by-step plan. It is designed to reduce overwhelm and improve focus, making it ideal for ADHD task management.

**When to use:** Launch this agent for tasks like planning a project, organizing an event, or tackling a large personal goal.

## Future plans

The following is the proposed structure we're aiming for

This final structure reflects all the refinements, consolidations, and additions discussed, resulting in a comprehensive blueprint for an AI-driven development team.

### `opencode/agent/`

#### `core/` — High-Level Strategic Agents

- `architect.md`: Designs high-level system architecture and makes foundational technology choices.
- `tech-lead.md`: Guides development, ensures technical standards, and makes key implementation decisions.
- `project-manager.md`: Oversees the project timeline, resources, and ensures goals are met.

#### `development/` — Code Creation Specialists

- `backend-developer.md`: Writes server-side logic, APIs, and services in PHP.
- `frontend-developer.md`: Builds user interfaces and client-side logic using Vue.js and a custom templating system.
- `database-developer.md`: Designs schemas, writes complex SQL queries, and manages database interactions for MySQL.
- `search-developer.md`: Implements search functionality using Elasticsearch, including queries and indexing.
- `fullstack-developer.md`: Handles tasks that span the entire stack, from the database to the UI.

#### `quality/` — Code and Feature Quality Assurance

- `code-reviewer.md`: Performs a general review of code for logic, style, and correctness, adapting to the language.
- `security-reviewer.md`: Specifically audits code for security vulnerabilities across the entire stack.
- `performance-reviewer.md`: Analyzes code for performance bottlenecks and inefficiencies across the stack.
- `test-writer.md`: Generates unit, integration, or E2E tests for new or existing code.
- `test-coverage-analyst.md`: Measures and reports on the state of test coverage.
- `code-smell-detector.md`: Hunts for signs of poor design or implementation (e.g., long methods, large classes).
- `complexity-analyzer.md`: Calculates cyclomatic complexity to identify overly complex and hard-to-maintain code.
- `dependency-auditor.md`: Scans project dependencies (both Composer and npm) for known vulnerabilities or outdated packages.

#### `debugging/` — Problem Identification and Resolution

- `bug-hunter.md`: Takes a bug report and systematically tries to reproduce and locate the source of the error.
- `log-analyzer.md`: Scans Apache, PHP, or application logs to find patterns or error messages.
- `performance-profiler.md`: Analyzes performance metrics to pinpoint the exact cause of slowness.
- `query-optimizer.md`: Specifically debugs and rewrites inefficient MySQL or Elasticsearch queries.
- `stack-trace-analyzer.md`: Interprets a stack trace (PHP or JS) to explain the sequence of events leading to an error.

#### `devops/` — Infrastructure and Deployment Management

- `docker-specialist.md`: Creates and manages `Dockerfile` configurations for application services.
- `apache-specialist.md`: Configures and troubleshoots Apache virtual hosts and `.htaccess` files.
- `deployment-specialist.md`: Manages the process of deploying code to staging or production environments.
- `environment-manager.md`: Manages `docker-compose.yml` to ensure local environments are consistent.

#### `documentation/` — Knowledge Creation and Management

- `documenter.md`: Generates PHPDoc, JSDoc, or other code-level documentation for functions and classes.
- `readme-writer.md`: Updates the project's main `README.md` file with setup instructions or new features.
- `changelog-generator.md`: Creates `CHANGELOG.md` entries from recent git commit messages.

#### `refactoring/` — Code Improvement and Maintenance

- `code-modernizer.md`: Updates old code to use newer language features or modern best practices.
- `code-organizer.md`: Refactors code by reorganizing files, directories, and namespaces for better clarity.
- `dependency-updater.md`: Manages the process of updating outdated packages (Composer/npm) and resolving conflicts.

#### `project-management/` — Agile and Task Management

- `epic-breakdown.md`: Takes a large feature concept and breaks it down into smaller, manageable epics.
- `ticket-creator.md`: Formats a task description into a well-defined ticket for a system like Jira or GitHub Issues.
- `task-splitter.md`: Breaks a single, complex ticket into a checklist of smaller, actionable sub-tasks.
- `adhd-task-adapter.md`: Rephrases tasks to have a clear, single objective and starting point to make them more approachable.
- `ticket-analyzer.md`: Reads a ticket and analyzes the codebase to determine the required technical implementation plan.
- `estimation-helper.md`: Provides story point or time-based estimates for a given task based on its technical scope.
- `acceptance-criteria-writer.md`: Generates clear, testable acceptance criteria for a user story.
- `ticket-prioritizer.md`: Helps prioritize a backlog of tickets based on factors like value and effort.
- `sprint-planner.md`: Assists in planning a sprint by selecting a realistic set of tickets from the backlog.

#### `personal-productivity/` — Personal Productivity and Task Management

- `adhd-task-breaker.md`: Use this agent for breaking down complex, NON-TECHNICAL, real-world tasks into a manageable, step-by-step plan. It is designed to reduce overwhelm and improve focus, making it ideal for ADHD task management.

#### `codebase-analysis/` — Automated Codebase Discovery and Mapping

- `orchestrator.md`: A master agent that runs other analysis agents in sequence to build a comprehensive project report.
- **`discovery/`**
  - `project-detector.md`: Identifies the project type and primary languages used in the repository.
  - `directory-structure-mapper.md`: Creates a map of the key directories and their purposes.
  - `entrypoint-finder.md`: Locates the initial execution points of the application (e.g., `index.php`).
  - `config-file-finder.md`: Finds and catalogs all configuration files.
- **`dependency-analysis/`**
  - `package-manager-detector.md`: Identifies all package managers being used (Composer, npm, etc.).
  - `dependency-tree-analyzer.md`: Builds a complete tree of all project dependencies and their versions.
  - `multi-frontend-detector.md`: Checks if the project contains multiple, separate frontend applications.
  - `vendor-analyzer.md`: Specifically analyzes the contents of the `vendor/` and `node_modules/` directories.
- **`build-system-analysis/`**
  - `build-tool-detector.md`: Detects the asset build tool being used (e.g., webpack).
  - `build-config-analyzer.md`: Parses the webpack config to understand the build process.
  - `asset-pipeline-mapper.md`: Maps how assets (JS, CSS) are processed from source to output.
  - `script-analyzer.md`: Analyzes scripts defined in `package.json` and `composer.json`.
- **`infrastructure-analysis/`**
  - `docker-environment-analyzer.md`: Parses `Dockerfile` and `docker-compose.yml` to understand the dev environment.
  - `container-relationship-mapper.md`: Maps how different Docker containers network and depend on each other.
  - `volume-mount-analyzer.md`: Identifies which local directories are mounted into containers.
  - `network-topology-mapper.md`: Diagrams the network ports and connections between services.
  - `server-config-analyzer.md`: Analyzes server configuration files (e.g., Apache's `.conf` files).
- **`framework-analysis/`**
  - `framework-detector.md`: Identifies the primary backend and frontend frameworks.
  - `framework-version-checker.md`: Determines the specific versions of the detected frameworks.
  - `bespoke-framework-analyzer.md`: Attempts to understand the conventions of a custom or non-standard framework.
  - `framework-convention-mapper.md`: Maps out the project's adherence to standard framework conventions.
  - `framework-extension-finder.md`: Finds custom plugins, modules, or extensions being used.
- **`routing-analysis/`**
  - `route-discovery-agent.md`: Scans the code to find all defined API and web routes.
  - `route-type-classifier.md`: Classifies routes as GET, POST, etc., and determines if they are web or API.
  - `route-handler-mapper.md`: Maps each route to the specific controller method that handles it.
  - `middleware-analyzer.md`: Identifies any middleware applied to routes or route groups.
  - `route-parameter-analyzer.md`: Catalogs the parameters expected by each route (e.g., `{id}`).
  - `url-pattern-documentor.md`: Generates a human-readable list of all available URL patterns.
- **`database-analysis/`**
  - `database-connection-finder.md`: Locates the code responsible for establishing the database connection.
  - `orm-detector.md`: Detects if an ORM (Object-Relational Mapper) is being used.
  - `model-discovery-agent.md`: Scans for and catalogs all database models.
  - `migration-analyzer.md`: Reads database migration files to understand the schema's history.
  - `database-layer-mapper.md`: Maps the flow of data from controllers to models to the database.
  - `query-pattern-analyzer.md`: Analyzes the types of database queries being made (raw SQL vs. ORM).
  - `relationship-mapper.md`: Discovers and diagrams relationships between database models.
- **`search-analysis/`**
  - `elasticsearch-detector.md`: Confirms the use of Elasticsearch in the project.
  - `search-client-analyzer.md`: Analyzes the client library used to communicate with Elasticsearch.
  - `index-mapper.md`: Discovers the Elasticsearch indexes and their mappings.
  - `search-query-cataloger.md`: Finds and lists all the different search queries used in the codebase.
  - `search-integration-analyzer.md`: Maps where and how Elasticsearch is integrated into the application logic.
- **`frontend-analysis/`**
  - `template-system-detector.md`: Identifies which templating systems are in use (Vue and custom).
  - `multi-template-mapper.md`: Maps which parts of the application use which templating system.
  - `component-discovery-agent.md`: Finds and catalogs all Vue.js components.
  - `asset-usage-analyzer.md`: Tracks how and where frontend assets like images and fonts are used.
  - `state-management-detector.md`: Detects the state management library being used (e.g., Pinia, Vuex).
  - `api-client-analyzer.md`: Analyzes how the frontend makes API calls to the backend.
- **`architecture-analysis/`**
  - `layer-identifier.md`: Identifies the distinct layers of the application (e.g., presentation, business, data).
  - `pattern-detector.md`: Detects the use of common software design patterns (e.g., MVC, Repository).
  - `coupling-analyzer.md`: Measures the degree of coupling between different modules.
  - `abstraction-mapper.md`: Identifies the key abstractions and interfaces in the codebase.
  - `design-pattern-cataloger.md`: Creates a catalog of all identified design patterns and their locations.
- **`security-analysis/`**
  - `vulnerability-scanner.md`: Performs a broad scan for known security vulnerabilities (OWASP Top 10).
  - `authentication-analyzer.md`: Audits the authentication implementation (e.g., login, password hashing).
  - `authorization-analyzer.md`: Checks the authorization logic (e.g., roles, permissions).
  - `input-validation-checker.md`: Scans for places where user input is used without proper validation.
  - `sql-injection-detector.md`: Specifically looks for code patterns vulnerable to SQL injection.
  - `xss-vulnerability-scanner.md`: Searches for potential Cross-Site Scripting (XSS) vulnerabilities.
  - `csrf-protection-checker.md`: Verifies that forms and endpoints are protected against CSRF attacks.
  - `secret-leak-detector.md`: Scans the repository for accidentally committed secrets or API keys.
  - `file-upload-security-analyzer.md`: Checks the security of file upload handling logic.
  - `session-security-analyzer.md`: Audits how user sessions are created, managed, and destroyed.
  - `api-security-auditor.md`: Audits API endpoints for common security issues like rate limiting.
  - `dependency-vulnerability-scanner.md`: Checks dependencies for known security issues (CVEs).
  - `cors-configuration-analyzer.md`: Analyzes the Cross-Origin Resource Sharing (CORS) setup.
  - `encryption-usage-checker.md`: Verifies that sensitive data is being encrypted correctly.
  - `security-header-analyzer.md`: Checks for the presence and correctness of security-related HTTP headers.
- **`performance-analysis/`**
  - `bottleneck-identifier.md`: Conducts a high-level search for potential performance bottlenecks.
  - `n-plus-one-detector.md`: Specifically detects N+1 query problems in loops.
  - `slow-query-identifier.md`: Finds database queries that are likely to be slow without proper indexing.
  - `memory-usage-analyzer.md`: Identifies code patterns that could lead to high memory consumption.
  - `caching-opportunity-finder.md`: Looks for frequently accessed, expensive operations that could be cached.
  - `database-index-analyzer.md`: Analyzes queries and schema to suggest missing database indexes.
  - `api-response-time-analyzer.md`: Identifies API endpoints that may have slow response times.
  - `asset-size-analyzer.md`: Checks the size of compiled JS and CSS bundles.
  - `image-optimization-checker.md`: Finds large, unoptimized images in the frontend assets.
  - `lazy-loading-opportunity-finder.md`: Identifies components or routes that could be lazy-loaded.
  - `algorithm-complexity-analyzer.md`: Checks for algorithms with high time or space complexity (O(n²)).
  - `database-connection-analyzer.md`: Reviews how database connections are pooled and managed.
  - `elasticsearch-performance-analyzer.md`: Audits Elasticsearch queries for potential performance issues.
  - `frontend-render-analyzer.md`: Analyzes Vue components for common causes of slow rendering.
  - `resource-leak-detector.md`: Looks for unclosed file handles or other potential resource leaks.
- **`testing-analysis/`**
  - `test-suite-mapper.md`: Catalogs all test files and organizes them by type (unit, integration, E2E).
  - `test-coverage-calculator.md`: Provides a detailed breakdown of test coverage by module or directory.
  - `untested-code-identifier.md`: Generates a report of public methods and components that lack test coverage.
  - `test-pattern-analyzer.md`: Identifies the common patterns and conventions used in the test suite.
  - `test-framework-detector.md`: Detects the specific testing frameworks being used (e.g., PHPUnit, Vitest).
  - `mock-usage-analyzer.md`: Analyzes how mocking and stubbing are used in tests.
  - `integration-test-mapper.md`: Specifically maps out tests that involve multiple system components.
  - `e2e-test-mapper.md`: Maps out end-to-end tests and the user flows they cover.
  - `test-quality-analyzer.md`: Assesses the quality of tests, looking for non-deterministic tests or poor assertions.
  - `flaky-test-detector.md`: Identifies tests that sometimes pass and sometimes fail without code changes.
  - `test-data-analyzer.md`: Analyzes how test data and fixtures are managed.
  - `assertion-pattern-analyzer.md`: Reviews the types of assertions being used for effectiveness.
  - `test-isolation-checker.md`: Checks if tests are properly isolated from one another.
  - `critical-path-coverage-checker.md`: Verifies that the most critical user paths are covered by tests.
  - `test-documentation-analyzer.md`: Reviews tests for clarity and descriptive naming.
- **`reporting/`**
  - `tech-stack-reporter.md`: Generates a summary of the entire technology stack.
  - `architecture-diagram-generator.md`: Creates text-based diagrams of the system architecture.
  - `onboarding-doc-generator.md`: Creates a "getting started" guide for a new developer based on analysis.
  - `tech-debt-identifier.md`: Scans for and creates a report on areas of technical debt.
  - `security-report-generator.md`: Consolidates findings from all security-analysis agents into a single report.
  - `performance-report-generator.md`: Consolidates findings from all performance-analysis agents.
  - `test-coverage-report-generator.md`: Generates a summary of test coverage findings.
  - `knowledge-base-builder.md`: Synthesizes all analysis into a searchable knowledge base about the project.

#### `context/` — Situational Awareness and Impact Analysis

- `codebase-mapper.md`: Provides a high-level overview of the codebase to other agents.
- `database-schema-reader.md`: Reads the database schema from migrations or a dump and provides it as context.
- `api-endpoint-cataloger.md`: Maintains a list of all available API endpoints and their functions.
- `dependency-graph-builder.md`: Visualizes the relationships between different modules or packages.
- `feature-impact-analyzer.md`: Predicts which files and components will be affected by a new feature request.
- `tech-debt-cataloger.md`: Identifies and catalogs specific instances of technical debt.

#### `git-workflow/` — Version Control Assistance

- `commit-message-generator.md`: Writes conventional commit messages based on staged changes.
- `branch-name-suggester.md`: Suggests a conventional branch name based on the ticket number or task.
- `pr-description-writer.md`: Writes a detailed pull request description from the branch's changes and commits.
- `changelog-entry-generator.md`: A focused agent that creates a changelog entry for a single pull request.
- `git-workflow-enforcer.md`: Provides guidance to ensure adherence to the team's branching strategy.

#### `tools/` — Integration with External Systems

- `git-helper.md`: A general-purpose agent for performing common Git operations.
- `github-pr-helper.md`: Interacts with the GitHub CLI/API to review or comment on pull requests.
- `jira-helper.md`: Interacts with the Jira API to update tickets or create work logs.
- `dependency-manager.md`: A wrapper agent for safely managing Composer and npm dependencies.
- `database-helper.md`: An agent for running migrations or interacting with the database CLI.

#### `specialized/` — Stack-Specific Expert Agents

- `elasticsearch-query-optimizer.md`: A highly specialized agent for rewriting and optimizing complex ES queries.
- `mysql-schema-designer.md`: An expert in MySQL schema design, focusing on normalization and indexing.
- `vue-component-architect.md`: Designs the structure of complex, multi-part Vue components and their props.
- `webpack-optimizer.md`: A specialist for diagnosing and fixing slow webpack build times.

