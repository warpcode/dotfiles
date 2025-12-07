---
name: task-management
description: Integrate GitHub issues and Task Warrior CLI for unified task management. Search both sources when listing tasks, label Task Warrior tasks with repository name.
---

# Task Management Integration

## Core Functionality

When the user requests to list or view their tasks, automatically search both GitHub issues and Task Warrior CLI.

## GitHub Issues Integration

- Use GitHub CLI: gh issue list
- Requires GitHub CLI authentication
- List open issues for the current repository
- Format: Issue #{number}: {title} ({state})

## Task Warrior CLI Integration

- Extract repository name from git remote get-url origin by:
  - Removing https://github.com/ prefix
  - Removing user/ prefix (e.g., warpcode/)
  - Removing .git suffix
  - Result: e.g., homelab-infrastructure
- Execute: task list project:{repo}
- Parse output for pending tasks in current repository project
- Label each task with repository name from git remote get-url origin
- Format: [{repo}] {description} (due: {due_date} if present)

## Unified Display

Combine both sources in a single list, clearly separating GitHub issues and Task Warrior tasks.

## Error Handling

- If GitHub API fails, show Task Warrior tasks only
- If Task Warrior fails, show GitHub issues only
- If both fail, inform user

## Task Status Updates

When the user wants to update task status:
- For GitHub issues: Use gh issue edit --state closed/open
- For Task Warrior tasks: Use task <id> done or task <id> modify status:pending

## Task Creation

When the user wants to create a new task:
- Ask whether they want it as A) GitHub Issue or B) Task Warrior task
- For GitHub Issue: Check for .github/ISSUE_TEMPLATE files as a guide, then use gh issue create
- For Task Warrior task: Use task add with current repository name as the project/group

## Usage Examples

- "Show me my tasks" → Lists all from both sources
- "What do I need to do?" → Same as above
- "Mark task 123 as done" → Updates Task Warrior task status
- "Close issue #45" → Updates GitHub issue status
- "Create a new task for fixing the bug" → Asks for choice, then creates in selected system