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