---
name: github-issues
description: >
  Guidelines, procedures, and templates for managing GitHub issues, issue triage, and issue comments.
  Use when authoring, updating, triaging, or commenting on GitHub issues.
user-invocable: false
---

# GitHub Issue Management and Triage

This skill provides guidelines, procedures, and templates for managing GitHub issues and issue comments.

> **Prerequisites:** This skill requires either the GitHub MCP server or the `gh` CLI to be available and authenticated. However, this file contains **ZERO** script or MCP direct references for usage. For execution, refer to the `github-cli` skill.

## 1. Safety and Explicit Consent

- **Explicit Approval Gates**: ALWAYS present the full proposed content (title, body, labels, assignees, or comment text) to the user for explicit approval before creating or modifying an issue, changing issue metadata, or posting/modifying issue comments.
- **Never Assume Context**: Resolve target repository explicitly (current directory, specified `<owner>/<repo>`, or ask the user if ambiguous).
- **Surgical Updates**: When modifying existing issues or comments, make targeted changes strictly to the specified sections; do not overwrite or modify unrelated existing content.

## 2. Context Gathering & Template Detection

- Resolve the target repository (`<owner>/<repo>`).
- Check for existing repository-specific issue templates:
  - `.github/ISSUE_TEMPLATE/*.md`
  - `.github/ISSUE_TEMPLATE.md`
- If repository templates exist, structure the issue body to match the repository template.

## 3. Content Structuring & Fallback Templates

If no repository-specific templates exist, use the standard fallback templates located in `@templates/`:
- **Bug Report**: `@templates/bug_report.md`
- **Feature Request**: `@templates/feature_request.md`
- **Task / Chore**: `@templates/task_chore.md`
- **Question / Discussion**: `@templates/question_discussion.md`
- **Security Vulnerability**: `@templates/security_vulnerability.md`

### Structuring Principles
- Adapt the selected template to the specific task and omit empty/irrelevant sections.
- The user's input and technical facts are the source of truth.
- Ensure clear, reproducible descriptions, expected vs actual behavior, and environment/version details where applicable.

## 4. Issue Comments Guidelines

- **Tone & Style**: Strictly neutral, objective, and concise. Avoid conversational filler, subjective praise, emotional preamble, or informal sign-offs.
- **Technical Content**: Focus on actionable technical updates, minimal reproduction steps, specific error logs, or concrete proposed fixes.
- **Referencing**: Explicitly cross-reference linked pull requests, parent issues, or related tickets (`#number` or `owner/repo#number`).
- **Batching & Updates**: When posting status updates on ongoing tasks, consolidate updates to avoid comment spamming.
