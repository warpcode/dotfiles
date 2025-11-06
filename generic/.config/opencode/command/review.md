---
description: >-
  Use this command to perform comprehensive review analysis of changes using
  multiple specialized agents. Automatically detects the type of changes
  (code, text, documentation) and invokes appropriate reviewers: code-reviewer
  for code quality, spelling-grammar-checker for spelling and grammar in both
  code and text, and fact-checker for factual accuracy in rewrites or large
  text modifications. Provides prioritized issue classification and actionable
  recommendations.
---

## Restrictions

- Do not modify files or run commands that change the repository state.
- Only analyze changes and provide review feedback.
- Respect file access permissions and avoid reading sensitive files.
- Always run spelling-grammar-checker on all content (code and text) for consistency.

## Steps

First, determine the scope of changes to review:

- If specific files are provided as arguments, analyze only those files
- If no arguments provided, analyze all changed files in the current git state
- Check for staged changes using `git diff --staged`
- Check for unstaged changes using `git diff`
- If in a git repository, also consider changes since last commit

Analyze the type of changes to determine which agents to invoke:

- **Code changes**: Invoke code-reviewer agent for security, correctness, performance, maintainability analysis
- **Text/Documentation changes**: Invoke spelling-grammar-checker agent for spelling and grammar issues
- **Large rewrites/refactoring or substantial text edits**: Invoke fact-checker agent for factual accuracy verification
- **All changes**: Always run spelling-grammar-checker on both code (variable names, comments, strings) and text content

Initialize appropriate agents based on detected change types:

For code-reviewer (when code changes detected):

- Provide list of files, git diff context, project technology stack, and focus areas
- Analyze for security vulnerabilities, logic bugs, performance issues, architecture problems, code smells, maintainability concerns, testing gaps, documentation issues, and language-specific best practices
- Classify issues by severity and provide quality gate evaluation

For spelling-grammar-checker (always run):

- Check spelling and grammar in code comments, documentation, variable names, and text content
- Ensure consistent spelling across the codebase

For fact-checker (when large rewrites or text changes detected):

- Verify factual accuracy in documentation, comments, and rewritten content
- Alert user to potential factual inconsistencies or outdated information
- Only provide suggestions for corrections; do not add new information or facts

Present the final review report with:

- Executive summary of overall quality assessment across all review types
- Quality gate evaluation (blocking criteria, warning criteria) for code changes
- Issues grouped by severity (Critical, High, Medium, Low) with risk assessment
- Detailed findings by category (Security, Correctness, Performance, Maintainability, Spelling/Grammar, Factual Accuracy, etc.)
- Specific findings with file locations and line numbers
- Actionable recommendations with priority timelines
- Code/text examples showing problems and suggested fixes
- Files reviewed summary with change context
- Spelling and grammar corrections for both code and text
- Fact-checking alerts for rewritten or modified content

If no significant issues found, provide positive feedback on overall quality.

---

## Rationale

This command provides comprehensive, automated review analysis by intelligently selecting and coordinating multiple specialized AI agents based on the type of changes detected. It ensures quality across code, documentation, and factual content by leveraging code-reviewer for technical analysis, spelling-grammar-checker for language consistency, and fact-checker for accuracy verification.

The multi-agent approach includes:

- **Intelligent Agent Selection**: Automatically detects change types (code vs. text, rewrites vs. minor edits) to invoke appropriate reviewers
- **Comprehensive Coverage**: Catches security vulnerabilities, logic bugs, performance issues, maintainability problems, spelling/grammar errors, and factual inaccuracies
- **Consistent Spelling**: Always checks spelling and grammar in both code (variable names, comments) and text content for consistency
- **Factual Verification**: Alerts users to potential factual issues in rewritten or substantially modified content
- **Prioritized Analysis**: Issues are classified by severity (Critical/High/Medium/Low) with risk assessment
- **Quality Gates**: Blocking criteria ensure critical issues prevent merges, warning criteria flag concerning changes
- **Structured Output**: Clear executive summaries, categorized findings, and actionable recommendations with timelines
- **Efficiency**: Parallel agent execution and intelligent scope detection for fast, thorough analysis

This ensures thorough analysis while maintaining efficiency and providing actionable feedback for developers.

## Usage Examples

Note: These are opencode commands, not shell executables.

- **Review staged changes**: Run `review` to analyze all staged files with automatic agent selection (code-reviewer for code, spelling-grammar-checker always, fact-checker for large changes)
- **Review specific files**: Run `review src/main.py README.md` to focus analysis on particular files with multi-agent review
- **Review entire branch**: Run `review --branch` to analyze all changes since branching from main/master with comprehensive quality assessment
- **Security-focused review**: Run `review --security` to prioritize security analysis across all files with critical vulnerability detection
- **Performance review**: Run `review --performance` to focus on performance and efficiency issues with impact assessment
- **Pre-merge gate**: Run `review --gate` to evaluate quality gates and determine if changes are ready for merge
- **Documentation review**: Run `review --docs` to focus on documentation quality with spelling-grammar-checker and fact-checker agents
- **Code refactoring review**: Run `review --refactor` to analyze code rewrites with code-reviewer, spelling-grammar-checker, and fact-checker for comprehensive assessment
- **Spelling consistency check**: Spelling-grammar-checker runs automatically on all content (code variables, comments, documentation) for consistency
