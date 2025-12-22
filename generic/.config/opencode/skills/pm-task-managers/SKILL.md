---
name: pm-task-managers
description: Comprehensive guide outlining rules and best practices for using Task Warrior CLI and GitHub Issues (via gh CLI) for effective task management. Use whenever managing tasks via GitHub Issues or Task Warrior.
---

# Task Management Software Guide

## Software Selection and Usage Rules

### When to Use GitHub Issues

Choose GitHub Issues for tasks that benefit from:

- **Team Collaboration**: Tasks requiring discussion, review, or multiple contributors
- **Public Visibility**: Work that stakeholders or the community should track
- **Bug Tracking**: Detailed bug reports with reproduction steps and discussion
- **Feature Requests**: New functionality that needs specification and prioritization
- **Documentation**: Tasks tied to code changes or project milestones
- **Audit Trail**: Work requiring historical record and traceability
- **Integration**: Tasks that benefit from GitHub's ecosystem (pull requests, projects, etc.)

### When to Use Task Warrior CLI

Choose Task Warrior for tasks that are:

- **Personal/Solo**: Individual work not requiring team input
- **Quick Tasks**: Simple todos that can be managed via command line
- **Time-Sensitive**: Tasks with due dates and priority management
- **Recurring**: Routine maintenance or repetitive work
- **Private**: Work not suitable for public/team visibility
- **CLI-Centric**: Workflows that fit command-line interfaces
- **Local Development**: Tasks specific to your development environment

### Decision Framework

Ask these questions to choose the right tool:

1. **Who needs to see this task?**
   - Team/others → GitHub Issues
   - Just me → Task Warrior

2. **Does this require discussion or collaboration?**
   - Yes → GitHub Issues
   - No → Task Warrior

3. **Is this tied to code changes or repository work?**
   - Yes → GitHub Issues
   - No → Task Warrior

4. **How urgent/time-sensitive is this?**
   - Needs due dates/priorities → Task Warrior
   - Milestone-based → GitHub Issues

### Hybrid Usage Rules

- Use both tools for comprehensive task management
- Sync important tasks between systems to avoid gaps
- Reserve GitHub Issues for official project tasks
- Use Task Warrior for personal productivity and reminders
- Review both regularly to maintain alignment

See references/github-integration.md for GitHub details and references/task-warrior-integration.md for Task Warrior details.

## Integration Guidelines

When combining multiple tools for comprehensive task management:

- Maintain clear separation between GitHub issues and Task Warrior tasks
- Use consistent naming conventions across tools
- Regularly sync important tasks between systems to avoid duplication
- Consider integration tools or scripts for cross-tool synchronization when needed

## Reliability Rules

Best practices for handling tool failures and ensuring task management continuity:

- If GitHub API fails, rely on Task Warrior tasks only and note the limitation
- If Task Warrior fails, rely on GitHub issues only and note the limitation  
- If both fail, inform the user and suggest manual tracking or tool maintenance
- Implement fallback procedures for critical task management scenarios

## Task Operations Rules

### Status Updates
Best practice: Update task status immediately when work is completed to maintain accurate project visibility.

- For GitHub issues: Use `gh issue edit --state closed/open` to reflect current status
- For Task Warrior tasks: Use `task <id> done` or `task <id> modify status:pending` for status changes

### Task Creation
Rule: Choose the appropriate software based on task type and team workflow before creating.

When creating new tasks:
- Prompt user to select between GitHub Issue or Task Warrior task based on context
- For GitHub Issue: Reference `.github/ISSUE_TEMPLATE` files for consistency, then use `gh issue create`
- For Task Warrior task: Use `task add` with current repository name as project for organization

## Application Guidelines

High-level guidelines for applying task management rules in different scenarios:

- **Team collaboration tasks**: GitHub Issues for visibility and discussion
- **Personal development tasks**: Task Warrior for quick CLI management
- **Bug tracking**: GitHub Issues with detailed reproduction steps
- **Time-sensitive reminders**: Task Warrior with due dates and priorities
- **Documentation tasks**: GitHub Issues for traceability
- **Maintenance tasks**: Task Warrior for recurring or routine work

See references/github-integration.md and references/task-warrior-integration.md for tool-specific rules and best practices.

## Productivity Rules

General best practices for effective task management:

- **Consistent Naming**: Use clear, descriptive names that follow project conventions
- **Regular Reviews**: Schedule weekly reviews of open tasks to maintain momentum  
- **Avoid Overloading**: Limit active tasks to maintain focus and quality
- **Prioritization**: Focus on high-impact tasks first
- **Documentation**: Keep task descriptions detailed enough for future reference
- **Communication**: Update team members when task status changes affect others

## Common Pitfalls and Solutions

Rules to avoid common task management problems:

- **Task Duplication**: Regularly check both tools to prevent duplicate entries
- **Stale Tasks**: Set reminders to review and update old tasks
- **Poor Visibility**: Use GitHub Issues for team-affecting tasks, not personal todos
- **Inconsistent Status**: Update status immediately when work state changes
- **Missing Context**: Always include sufficient detail in task descriptions
- **Tool Over-reliance**: Have manual backup procedures when tools fail
