# Task Warrior CLI Rules and Best Practices

## Repository Context Integration
- Extract repository name from `git remote get-url origin` for project organization:
  - Remove https://github.com/ prefix
  - Remove user/ prefix (e.g., warpcode/)
  - Remove .git suffix
  - Result: e.g., homelab-infrastructure
- Use repository name as project identifier for task grouping

## Task Listing and Filtering
- Execute `task list project:{repo}` to view pending tasks for current repository
- Parse output to extract task details and due dates
- Label tasks with repository context: [{repo}] {description} (due: {due_date} if present)
- Filter by priority, tags, or due dates as needed: `task list priority:H`

## Task Management Rules
- Use projects to organize tasks by repository or feature area
- Set priorities (H/M/L) appropriately for task urgency
- Include due dates for time-sensitive tasks
- Use tags for additional categorization
- Leverage annotations for detailed notes
- Regularly review and purge completed tasks