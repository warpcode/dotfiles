---
description: Use this command to perform comprehensive code review analysis using the code-review-orchestrator agent, which coordinates multiple specialized reviewers for security, correctness, performance, maintainability, and other quality aspects. Includes prioritized issue classification, quality gate evaluation, and structured recommendations with merge readiness assessment.
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
2. Invoke agents in parallel where possible (including code-review-prioritization for severity classification)
3. Collect findings from all agents
4. Apply quality gates and risk assessment
5. Synthesize results into a prioritized, comprehensive review report with merge readiness evaluation

Present the final review report with:
- Executive summary of overall code quality and merge readiness assessment
- Quality gate evaluation (blocking criteria, warning criteria)
- Issues grouped by severity (Critical, High, Medium, Low) with risk assessment
- Detailed findings by category (Security, Correctness, Performance, Maintainability, etc.)
- Specific findings with file locations and line numbers
- Actionable recommendations with priority timelines
- Code examples showing problems and suggested fixes
- Files reviewed summary with change context

If no significant issues found, provide positive feedback on code quality.

---

## Rationale

This command provides comprehensive, automated code review analysis by leveraging multiple specialized AI agents working in coordination. It catches security vulnerabilities, logic bugs, performance issues, maintainability problems, and adherence to best practices across multiple programming languages and frameworks.

The orchestrated approach includes:
- **Prioritized Analysis**: Issues are classified by severity (Critical/High/Medium/Low) with risk assessment
- **Quality Gates**: Blocking criteria ensure critical issues prevent merges, warning criteria flag concerning changes
- **Specialized Reviewers**: Dedicated agents for security, correctness, anti-patterns, performance, maintainability, architecture, testing, and documentation
- **Structured Output**: Clear executive summaries, categorized findings, and actionable recommendations with timelines
- **Efficiency**: Parallel agent execution and intelligent scope detection for fast, thorough analysis

This ensures thorough analysis while maintaining efficiency and providing actionable feedback for developers.

## Usage Examples

- **Review staged changes**: Run `code-review` to analyze all staged files for comprehensive quality issues with quality gate evaluation
- **Review specific files**: Run `code-review src/main.py src/utils.js` to focus analysis on particular files with prioritized findings
- **Review entire branch**: Run `code-review --branch` to analyze all changes since branching from main/master with merge readiness assessment
- **Security-focused review**: Run `code-review --security` to prioritize security analysis across all files with critical vulnerability detection
- **Performance review**: Run `code-review --performance` to focus on performance and efficiency issues with impact assessment
- **Pre-merge gate**: Run `code-review --gate` to evaluate quality gates and determine if changes are ready for merge

