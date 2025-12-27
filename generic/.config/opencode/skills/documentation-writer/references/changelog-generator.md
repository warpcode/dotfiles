<rules>
## CORE_RULES
- Expertise: Communication + Process (Release Manager)
- Format: Conventional Commits parsing (feat:, fix:, refactor:)
- Ignore: `chore:`, `docs:` (simple commits)
- Grouping: By version, then by category (Features, Bug Fixes, Refactors)
- Security: Validate git commands, sanitize input
</rules>

<context>
## PROCESS
1. Acknowledge Goal: Generate `CHANGELOG.md` from git history
2. Fetch Git History:
   - Command: `git log --pretty=format:"%H|%d|%s"`
   - Output: Commit hash, tags, subject line
3. Process Commit Log:
   - Line-by-line parsing
   - Tag found (e.g., `v1.1.0`) -> New version section
   - Parse by Conventional Commit specification
4. Group + Format Changes:
   - Group under version number
   - Categorize: "🚀 Features", "🐛 Bug Fixes", "🧹 Refactors"
   - Ignore: `chore:`, `docs:`
5. Generate `CHANGELOG.md`:
   - Construct full Markdown document
   - Write with `write` tool to project root
</context>

<examples>
### CHANGELOG_Format
```markdown
# Changelog

All notable changes to this project will be documented in this file.

---

## [v1.1.0] - 2025-11-12

### 🚀 Features

- (auth): Add password reset functionality
- (products): Implement product search and filtering

### 🐛 Bug Fixes

- (billing): Correctly calculate tax for international orders
- (api): Prevent N+1 query in the orders endpoint

### 🧹 Refactors

- (auth): Modernize array syntax in legacy controller

---

## [v1.0.0] - 2025-10-28

### ✨ Initial Release

- Initial release of the application.

---
```
</examples>

<execution_protocol>
1. Announce: "Generating CHANGELOG.md from git history"
2. Execute: `git log --pretty=format:"%H|%d|%s"`
3. Parse: Process log, identify tags, categorize commits
4. Construct: Build Markdown with version sections + categories
5. Validate: All meaningful commits included, formatting consistent
6. Output: Confirmation + preview of `CHANGELOG.md`
7. Security: Sanitize git output, validate paths before write
</execution_protocol>
