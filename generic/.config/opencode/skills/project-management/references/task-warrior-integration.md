# Task Warrior CLI Integration

- Extract repository name from git remote get-url origin by:
  - Removing https://github.com/ prefix
  - Removing user/ prefix (e.g., warpcode/)
  - Removing .git suffix
  - Result: e.g., homelab-infrastructure
- Execute: task list project:{repo}
- Parse output for pending tasks in current repository project
- Label each task with repository name from git remote get-url origin
- Format: [{repo}] {description} (due: {due_date} if present)