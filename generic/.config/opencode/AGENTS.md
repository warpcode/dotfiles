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

### Core Agents

#### `core/feature-lead`

**Description:** This is a master orchestrator agent responsible for the end-to-end development of a new feature. It takes a single feature request or ticket as input and manages the entire workflow: planning the technical tasks, delegating the coding to the backend and frontend developer agents, and coordinating a final code review. This is the primary agent for creating new functionality.

**When to use:** A new feature has been planned and is ready for development.

**Examples:**
- Context: A new feature has been planned and is ready for development.
  user: "Okay, let's build the 'Favorites' feature as described in ticket PM-456."
  assistant: "Understood. I will launch the feature-lead agent to manage the full implementation. It will analyze the ticket, create a technical plan, delegate the coding work to the development agents, and ensure the final code is reviewed. I will report back with a full summary when the feature is complete and ready for your final approval."

#### `core/bug-smasher`

**Description:** This is a master orchestrator agent responsible for the end-to-end resolution of a bug. It takes a bug report as input and manages the entire workflow: using analysis and debugging agents to find the root cause, delegating a code fix to the appropriate developer agent, ensuring a regression test is written, and coordinating a final code review.

**When to use:** A bug has been reported by a user or a monitoring system.

**Examples:**
- Context: A bug has been reported by a user or a monitoring system.
  user: "We have a bug. Users are getting a 500 error when they try to view an order that has no items. Here's the stack trace..."
  assistant: "Understood. A null pointer exception when an order is empty. I will launch the bug-smasher agent to manage the full resolution. It will analyze the stack trace, find the root cause, delegate a fix, ensure a regression test is written, and verify the final code. I will report back when the bug is fixed and ready for review."

#### `core/tech-debt-crusher`

**Description:** This is a proactive master orchestrator agent responsible for identifying and resolving technical debt. It first runs the master `orchestrator` to get a full audit of the codebase. It then identifies a high-impact issue (like a security risk or performance bottleneck), creates a plan to fix it, delegates the work to the appropriate refactoring or development agents, and verifies the fix.

**When to use:** A developer wants to proactively improve the health of the codebase.

**Examples:**
- Context: A developer wants to proactively improve the health of the codebase.
  user: "Let's work on some tech debt. Can you find and fix a significant issue in the project?"
  assistant: "Absolutely. I'm launching the tech-debt-crusher agent. It will begin by performing a full audit of the codebase to identify the highest-impact area for improvement. Once it has a target, it will manage the entire refactoring and review process. I'll report back when it has a fix ready for your review."

### Development Agents

#### `development/backend-developer`

**Description:** This is an action-oriented agent that writes new backend code. It takes a specific, well-defined technical task (e.g., "Create a new API endpoint to fetch products") and implements it by creating and modifying PHP files like controllers, models, and routes. It is designed to use the framework's own command-line tools (`php artisan`).

**When to use:** A technical plan for a new feature has been created by the `task-splitter`.

**Examples:**
- Context: A technical plan for a new feature has been created by the `task-splitter`.
  assistant: "I have the technical plan for the new 'Favorites' feature. I will now launch the backend-developer agent to create the necessary database migration, model, and controller for the API."

#### `development/frontend-developer`

**Description:** This is an action-oriented agent that writes new frontend code. It takes a specific, well-defined technical task (e.g., "Create a new button component and add it to the product page") and implements it by creating and modifying Vue.js files and Pinia stores. It is designed to follow the project's established frontend conventions.

**When to use:** The backend API for a new feature is complete.

**Examples:**
- Context: The backend API for a new feature is complete.
  assistant: "The backend is ready for the new 'Favorites' feature. I will now launch the frontend-developer agent to create the `FavoriteButton.vue` component and integrate it into the product page."

### Documentation Agents

#### `documentation/api-documenter`

**Description:** This is a highly specialized agent that acts as an API design assistant. It generates professional, maintainable OpenAPI 3.0 (Swagger) specifications in YAML or JSON. It has two modes: 1) Designing a new API from a high-level description, and 2) Documenting an existing API by running the codebase analysis suite. Its most important rule is to aggressively use reusable `components` and `$ref`s to keep the specification clean and DRY.

**When to use:** A developer is starting to design a new feature's API or needs to document an existing, undocumented API.

**Examples:**
- Context: A developer is starting to design a new feature's API.
  user: "I need to design a new API for managing blog posts. It should have endpoints for creating, reading, updating, and deleting posts."
  assistant: "Understood. I will launch the api-documenter agent in 'Design First' mode. It will create a starter `swagger.yaml` file for the Posts API, defining a reusable `Post` schema in the components section and referencing it in the paths."

#### `documentation/readme-writer`

**Description:** This is an action-oriented agent that generates a high-quality, comprehensive `README.md` file for the project. It does this by running the master `orchestrator` agent to get a full picture of the codebase, and then it synthesizes those findings into a well-structured and professional README document.

**When to use:** A project's `README.md` is missing or out of date.

**Examples:**
- Context: A project's `README.md` is missing or out of date.
  assistant: "This project's README is a bit sparse. I'll launch the readme-writer agent. It will first perform a full analysis of the codebase and then use those findings to generate a complete and professional README.md file."

#### `documentation/changelog-generator`

**Description:** This is the final agent in the documentation phase. It's an action-oriented agent that generates a `CHANGELOG.md` file by analyzing the project's git history. It groups conventional commit messages under their corresponding git tags (versions) to create a clear, human-readable log of changes.

**When to use:** A developer is preparing to release a new version of the application.

**Examples:**
- Context: A developer is preparing to release a new version of the application.
  assistant: "Before we tag the new release, let's update the changelog. I'll launch the changelog-generator agent to scan our recent git commits and automatically generate a new `CHANGELOG.md` file."

#### `documentation/docblock-writer`

**Description:** This is an action-oriented agent that improves code quality by automatically adding documentation blocks (DocBlocks) to undocumented code. It scans PHP and JavaScript files, finds public classes and methods that are missing comments, and generates the appropriate PHPDoc or JSDoc for them.

**When to use:** A developer has just finished writing a new feature and wants to ensure it's properly documented.

**Examples:**
- Context: A developer has just finished writing a new feature and wants to ensure it's properly documented.
  assistant: "The code for the new feature is written. I'll now launch the docblock-writer agent to scan the new files and automatically add PHPDoc comments to all the new classes and public methods."

### Git Workflow Agents

#### `git-workflow/branch-name-suggester`

**Description:** This is a simple helper agent that suggests a conventional branch name based on a ticket ID and a brief description. It enforces a consistent branching strategy across the team, making the git history easier to navigate.

**When to use:** A developer is about to start work on a new feature ticket.

**Examples:**
- Context: A developer is about to start work on a new feature ticket.
  user: "I'm starting on ticket PM-456, 'Add user profile avatars'."
  assistant: "Great. Before you start, I'll launch the branch-name-suggester agent to give you a conventional branch name for your work."

#### `git-workflow/commit-message-generator`

**Description:** Use this agent when you need to generate a descriptive and conventional commit message based on the provided context of code changes, such as file modifications, additions, or deletions, without performing the actual git commit. This agent should be launched proactively after identifying changes that require committing, ensuring the message follows best practices like conventional commits (e.g., 'feat:', 'fix:', 'docs:').

**When to use:** When you need to generate a descriptive and conventional commit message based on the provided context of code changes.

**Examples:**
- Context: The user has implemented a new feature and is ready to commit changes.
  user: "I've added a new login function to the app."
  assistant: "I'll use the Task tool to launch the commit-message-generator agent to create an appropriate commit message based on the described changes."

#### `git-workflow/pr-description-writer`

**Description:** This is a high-impact helper agent that automates the creation of a pull request (PR) description. It analyzes the current branch's commits and file changes to generate a comprehensive, well-formatted description that explains the "what," "why," and "how" of the changes, saving developer time and improving the code review process.

**When to use:** A developer has finished a feature, pushed their branch, and is about to create a pull request on GitHub.

**Examples:**
- Context: A developer has finished a feature, pushed their branch, and is about to create a pull request on GitHub.
  user: "I've pushed my `feature/PM-456-user-avatars` branch. Can you write a pull request description for me?"
  assistant: "Absolutely. I'll launch the pr-description-writer agent. It will analyze the commits and changes in your current branch and generate a complete PR description for you to paste into GitHub."

### Personal Productivity Agents

#### `personal-productivity/adhd-task-breaker`

**Description:** Use this agent for breaking down complex, NON-TECHNICAL, real-world tasks into a manageable, step-by-step plan. It is designed to reduce overwhelm and improve focus, making it ideal for ADHD task management.

**When to use:** Launch this agent for tasks like planning a project, organizing an event, or tackling a large personal goal.

**Examples:**
- Context: The user wants to plan a large, non-coding project.
  user: "I need to plan and launch a marketing campaign for our new product."
  assistant: "That's a big goal with many moving parts. I'll use the Task tool to launch the adhd-task-breaker agent to create a clear, step-by-step checklist for you."

### Project Management Agents

#### `project-management/task-splitter`

**Description:** Use this agent to break down a single, well-defined software development ticket or feature request into a technical checklist of sub-tasks. This agent analyzes the codebase to identify all the necessary components (backend, frontend, database, tests) that need to be created or modified.

**When to use:** The user has a clear feature request and needs an implementation plan.

**Examples:**
- Context: The user has a clear feature request and needs an implementation plan.
  user: "I need to add a 'favorite' button to our blog posts."
  assistant: "Okay, I'll use the Task tool to launch the task-splitter agent. It will scan the codebase and create a technical checklist of all the necessary backend, frontend, and database changes."

#### `project-management/sprint-planner`

**Description:** This agent helps plan a sprint or work cycle. It takes a prioritized backlog and a team's capacity (in story points) and suggests a realistic scope for the upcoming sprint.

**When to use:** The team is ready to plan their next two-week sprint.

**Examples:**
- Context: The team is ready to plan their next two-week sprint.
  user: "Let's plan our next sprint. We have a capacity of 20 story points."
  assistant: "Great. I'll launch the sprint-planner agent. I will pull the prioritized backlog and select the top tickets that fit within your 20-point capacity."

#### `project-management/acceptance-criteria-writer`

**Description:** A specialist agent that takes a single user story and generates a checklist of clear, testable acceptance criteria in the Gherkin (Given/When/Then) format. This ensures that all stakeholders have a shared understanding of what "done" means before development starts.

**When to use:** A user story has been created by the `ticket-creator` agent.

**Examples:**
- Context: A user story has been created by the `ticket-creator` agent.
  user: "Let's write the acceptance criteria for the 'upload a profile picture' story."
  assistant: "Perfect. I'll launch the acceptance-criteria-writer agent to define the specific success, failure, and edge cases for that feature in a testable format."

#### `project-management/adhd-task-adapter`

**Description:** Use this agent to break down a specific, technical software development task into a sequence of small, concrete, and actionable coding steps. It is designed to be ADHD-friendly by providing hyper-specific starting points and clear completion criteria. This agent MUST be used for tasks that require code changes, as it needs to read the codebase to formulate its plan.

**When to use:** The user needs to implement a technical feature that is not fully specified.

**Examples:**
- Context: The user needs to implement a technical feature that is not fully specified.
  user: "I need to add pagination to the products API endpoint."
  assistant: "Okay, that's a clear goal. To make it easy to start, I'll use the Task tool to launch the adhd-task-adapter agent. It will analyze the current code and give you a step-by-step plan."

#### `project-management/epic-breakdown`

**Description:** Use this agent at the very beginning of a project or for a large, complex feature. It takes a broad concept and breaks it down into distinct, high-level "epics" that can be tackled independently.

**When to use:** The user has a major new product idea.

**Examples:**
- Context: The user has a major new product idea.
  user: "I want to build a new social media platform for pet owners."
  assistant: "That's a huge undertaking! Let's start by using the Task tool to launch the epic-breakdown agent to map out the major feature areas, like 'User Profiles', 'Photo Sharing', and 'Event Planning'."

#### `project-management/ticket-analyser`

**Description:** A crucial agent that acts as a bridge between a user story and the actual coding work. It takes a ticket with defined acceptance criteria and analyzes the live codebase to produce a high-level technical brief, outlining which parts of the system will be affected. Its output is the primary input for the `task-splitter` and `estimation-helper` agents.

**When to use:** A ticket is fully defined with acceptance criteria.

**Examples:**
- Context: A ticket is fully defined with acceptance criteria.
  user: "Can you analyze the 'upload profile picture' ticket to see what technical work is required?"
  assistant: "Yes. I'll launch the ticket-analyzer agent. It will read the codebase to identify the controllers, models, and components that will need to be changed and provide a technical summary."

#### `project-management/estimation-helper`

**Description:** A specialist agent that provides a size estimate (in Story Points) for a given task. It bases its estimate on a technical plan from `ticket-analyzer` or `task-splitter`, analyzing complexity, effort, and uncertainty. It does not estimate time directly.

**When to use:** The user has a technical analysis and needs to understand the size of the task for planning.

**Examples:**
- Context: The user has a technical analysis and needs to understand the size of the task for planning.
  user: "Can you estimate the work for the 'upload profile picture' ticket based on the analysis from ticket-analyzer?"
  assistant: "Certainly. I'll launch the estimation-helper agent to provide a story point estimate and a breakdown of the complexity, effort, and uncertainty involved."

#### `project-management/ticket-creator`

**Description:** Use this agent to take a single epic or a well-defined feature idea and break it down into formal user stories or tickets. It focuses on capturing the "who, what, and why" of a feature.

**When to use:** The user has a clear epic from the `epic-breakdown` agent.

**Examples:**
- Context: The user has a clear epic from the `epic-breakdown` agent.
  user: "Let's break down the 'User Profiles' epic."
  assistant: "Great choice. I'll use the Task tool to launch the ticket-creator agent to generate the specific user stories for that epic, like 'As a user, I want to be able to upload a profile picture...'"

### Quality Agents

#### `quality/code-reviewer`

**Description:** This is the primary, consolidated agent for performing code reviews. It is language-agnostic and adaptive. When given a file, it first inspects the file extension (`.php`, `.vue`, `.js`) and then applies a specific set of rules and best practices relevant to that language. It serves as the main entry point for all general code quality checks.

**When to use:** A developer wants a review of a new PHP file they just wrote or a pull request contains both frontend and backend changes.

**Examples:**
- Context: A developer wants a review of a new PHP file they just wrote.
  user: "Can you please review `app/Services/BillingService.php`?"
  assistant: "Certainly. I'm launching the code-reviewer agent. It has detected a `.php` file, so it will apply our standard PSR-12 checks and look for common PHP-specific issues."

#### `quality/holistic-reviewer`

**Description:** This is a master orchestrator for code quality. It takes a set of changed files (like in a pull request) and coordinates a multi-dimensional review by delegating tasks to the entire suite of specialist agents (security, performance, code smell, testing). It then synthesizes all their findings into a single, prioritized, and actionable review report.

**When to use:** A developer has submitted a pull request and needs a full, in-depth review.

**Examples:**
- Context: A developer has submitted a pull request and needs a full, in-depth review.
  user: "Please perform a comprehensive review of my pull request."
  assistant: "Understood. I'm launching the holistic-reviewer agent. This is a deep analysis that will coordinate our security, performance, quality, and testing specialists to perform a full 360-degree audit of the changes. I will provide a single, unified report when it's complete."

### Refactoring Agents

#### `refactoring/code-modernizer`

**Description:** This is the first agent in the refactoring phase. It's an action-oriented agent that scans the codebase for outdated language syntax and automatically updates it to modern conventions. Its initial focus is on converting PHP's old `array()` syntax to the short `[]` syntax.

**When to use:** A developer wants to clean up some old parts of the codebase.

**Examples:**
- Context: A developer wants to clean up some old parts of the codebase.
  assistant: "I can help with that. I'll launch the code-modernizer agent to perform a safe and automatic cleanup. It will start by converting all the old `array()` syntax to the modern short array syntax `[]`."

#### `refactoring/code-organizer`

**Description:** This agent runs after the `dead-code-remover`. It is an action-oriented agent that focuses on improving the organization and readability of code files. Its primary task is to find all PHP files and alphabetize their `use` statements, which is a common and recommended coding standard.

**When to use:** A developer wants to improve the consistency of the codebase.

**Examples:**
- Context: A developer wants to improve the consistency of the codebase.
  assistant: "Now that we've removed the dead code, let's clean up the remaining files. I'll launch the code-organizer agent to automatically sort all of the `use` statements in every PHP file alphabetically. This will make the files cleaner and easier to read."

#### `refactoring/dead-code-remover`

**Description:** This agent runs after the `code-modernizer`. It's an action-oriented agent that scans the codebase to find and remove "dead" code—code that is provably unused. Its primary and safest target is unused private methods within a class.

**When to use:** A developer wants to clean up the codebase after a lot of refactoring.

**Examples:**
- Context: A developer wants to clean up the codebase after a lot of refactoring.
  assistant: "A great next step is to remove any code that's no longer being used. I'll launch the dead-code-remover agent to perform a safe scan and identify any unused private methods we can clean up."

#### `refactoring/dependency-updater`

**Description:** This is the final agent in the initial refactoring phase. It's an action-oriented agent that checks for outdated third-party dependencies using the package managers' built-in commands. It then presents a clear list of available updates to the user.

**When to use:** A developer wants to ensure the project's dependencies are current.

**Examples:**
- Context: A developer wants to ensure the project's dependencies are current.
  assistant: "Let's make sure our third-party libraries are up-to-date. I'll launch the dependency-updater agent to run `composer outdated` and `npm outdated`. It will give us a clear list of all the packages that have new versions available."

### Codebase Analysis Agents

#### `codebase-analysis/orchestrator`

**Description:** This is the master agent for conducting a full codebase audit. It acts as a project manager, running the entire suite of specialist analysis agents in the correct sequence. It covers descriptive analysis (architecture), and evaluative analysis (security, performance, testing), compiling all findings into a final, comprehensive 'State of the Codebase' report.

**When to use:** A developer needs a complete, holistic audit of a project.

**Examples:**
- Context: A developer needs a complete, holistic audit of a project.
  user: "I need a full 360-degree report on this codebase: architecture, security, performance, and test coverage."
  assistant: "Understood. I will launch the main orchestrator agent. This is the most comprehensive analysis possible, coordinating with all specialist agents. The final output will be a complete audit report with architectural diagrams, a prioritized list of security and performance issues, and a full assessment of the test suite."

### Top-Level Agents

#### `adhd-task-breaker`

**Description:** A specialized advisor that decomposes complex, multi-step tasks into smaller, manageable subtasks to improve focus and productivity, especially for individuals with ADHD.

**When to use:** When a user presents a complex, multi-step task that needs to be decomposed into smaller, manageable subtasks to improve focus and productivity, especially for individuals with ADHD.

#### `agent-writer`

**Description:** A specialized agent that generates new agent configurations from user requirements or reviews existing agent configurations for completeness, clarity, and adherence to best practices.

**When to use:** When you need to generate new agent configurations from user requirements or when reviewing existing agent configurations for completeness, clarity, and adherence to best practices.

#### `code-writer`

**Description:** A code writer agent that creates new code files and modifies existing code with extremely high attention to detail for code quality, automatically running comprehensive code review orchestration to ensure quality standards are met.

**When to use:** When you need to create new code files from scratch or modify existing code with rigorous quality control and mandatory review processes.

#### `documentation-writer`

**Description:** A specialized documentation writer that creates, improves, and ensures documentation quality across code comments, docblocks, markdown files, and wiki documentation, focusing on making documentation legible, concise, and informative while emphasizing 'why' explanations over redundant 'what' descriptions.

**When to use:** For creating or enhancing documentation with proper focus on rationale and clarity, such as adding appropriate docblocks and inline comments focusing on 'why' rather than 'what'.

#### `fact-checker`

**Description:** A fact-checker agent that meticulously validates changes to code, documentation, or content for factual accuracy, completeness, intent preservation, and context retention, providing systematic analysis and detailed reports on discrepancies without making any modifications.

**When to use:** When you need to verify that changes preserve all critical facts, behaviors, and context from the original. Ideal for reviewing refactors, rewrites, imports, or any modifications where factual integrity is paramount.

#### `spelling-grammar-checker`

**Description:** A specialized spelling and grammar checker that identifies spelling errors, grammatical mistakes, and language clarity issues in text, documentation, comments, and user-facing content.

**When to use:** For validating text quality and language correctness, such as reviewing documentation for spelling and grammatical errors.

#### `task-manager`

**Description:** A task management agent that helps users organize and track tasks using Taskwarrior CLI, providing comprehensive task management including creation, modification, organization, and reporting with Taskwarrior's rich feature set for projects, tags, priorities, due dates, and recurring tasks.

**When to use:** For organizing and tracking tasks using Taskwarrior CLI, such as adding tasks with project and due date, showing pending tasks, or organizing work tasks.

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

