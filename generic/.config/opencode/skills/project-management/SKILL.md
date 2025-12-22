---
name: project-management
description: Comprehensive project management skill that integrates GitHub issues and Task Warrior CLI for unified task tracking and management, provides ADHD-friendly task planning strategies, and offers detailed breakdowns for both technical and non-technical tasks to reduce overwhelm and improve productivity.
---

# Task Management Integration

## Core Functionality

When the user requests to list or view their tasks, automatically search both GitHub issues and Task Warrior CLI.

See references/github-integration.md for GitHub details and references/task-warrior-integration.md for Task Warrior details.

## Unified Display

Combine both sources in a single list, clearly separating GitHub issues and Task Warrior tasks.

## Error Handling

- If GitHub API fails, show Task Warrior tasks only
- If Task Warrior fails, show GitHub issues only
- If both fail, inform user

See references/task-operations.md for task updates and creation.

## Usage Examples

- "Show me my tasks" → Lists all from both sources
- "What do I need to do?" → Same as above
- "Mark task 123 as done" → Updates Task Warrior task status
- "Close issue #45" → Updates GitHub issue status
- "Create a new task for fixing the bug" → Asks for choice, then creates in selected system

## ADHD Task Breakdowns

For ADHD-friendly task planning, reference these files as needed: references/adhd-task-strategies.md for universal strategies (e.g., Pomodoro, time estimates); references/adhd-technical-task-breakdowns.md for code-related tasks; references/adhd-real-world-task-breakdowns.md for non-technical tasks. Load only when breaking down complex tasks to reduce overwhelm.
