# Task Operations

## Task Status Updates

When the user wants to update task status:
- For GitHub issues: Use gh issue edit --state closed/open
- For Task Warrior tasks: Use task <id> done or task <id> modify status:pending

## Task Creation

When the user wants to create a new task:
- Ask whether they want it as A) GitHub Issue or B) Task Warrior task
- For GitHub Issue: Check for .github/ISSUE_TEMPLATE files as a guide, then use gh issue create
- For Task Warrior task: Use task add with current repository name as the project/group