---
description: Use this command to perform comprehensive code review analysis using the code-review-orchestrator agent, which coordinates multiple specialized reviewers for security, correctness, performance, maintainability, and other quality aspects.
---

## Restrictions

- Do not modify files or run commands that change the repository state.
- Only analyze code and provide review feedback.
- Respect file access permissions and avoid reading sensitive files.

## Steps

First, determine the scope of code to review:
- If specific files are provided as arguments, analyze only those files
- If no arguments provided, analyze all changed files in the current git state
- Check for staged changes using `git diff --staged`
- Check for unstaged changes using `git diff`
- If in a git repository, also consider changes since last commit

Initialize the code-review-orchestrator agent with the determined scope.

Provide the orchestrator with:
- List of files to analyze
- Git diff context showing what changed
- Project technology stack (inferred from file extensions and project structure)
- Any specific focus areas mentioned in the command arguments

The orchestrator will:
1. Analyze the scope and select appropriate specialized agents
2. Invoke agents in parallel where possible
3. Collect findings from all agents
4. Synthesize results into a prioritized, comprehensive review report

Present the final review report with:
- Executive summary of overall code quality
- Issues grouped by severity (Critical, High, Medium, Low)
- Specific findings with file locations and line numbers
- Actionable recommendations for each issue
- Code examples showing problems and suggested fixes

If no significant issues found, provide positive feedback on code quality.

---

## Rationale

This command provides comprehensive, automated code review analysis by leveraging multiple specialized AI agents working in coordination. It catches security vulnerabilities, logic bugs, performance issues, maintainability problems, and adherence to best practices across multiple programming languages and frameworks. The orchestrated approach ensures thorough analysis while maintaining efficiency and providing actionable feedback for developers.

## Usage Examples

- **Review staged changes**: Run `code-review` to analyze all staged files for comprehensive quality issues
- **Review specific files**: Run `code-review src/main.py src/utils.js` to focus analysis on particular files
- **Review entire branch**: Run `code-review --branch` to analyze all changes since branching from main/master
- **Security-focused review**: Run `code-review --security` to prioritize security analysis across all files
- **Performance review**: Run `code-review --performance` to focus on performance and efficiency issues

