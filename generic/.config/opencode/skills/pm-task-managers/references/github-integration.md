# GitHub Issues Rules and Best Practices

## Authentication and Setup
- Install and authenticate GitHub CLI (`gh auth login`) before use
- Ensure proper repository permissions for issue management
- Use personal access tokens for automated workflows when needed

## Listing and Viewing Issues
- Use `gh issue list` to view open issues for the current repository
- Filter by labels, assignees, or milestones as needed: `gh issue list --label "bug"`
- Format output consistently: Issue #{number}: {title} ({state})
- Review issues regularly to stay updated on project status

## Issue Management Rules
- Use descriptive titles following project conventions
- Include detailed descriptions with steps to reproduce for bugs
- Apply appropriate labels, assignees, and milestones
- Use issue templates when available for consistency
- Close issues promptly when resolved
- Reference related issues and pull requests