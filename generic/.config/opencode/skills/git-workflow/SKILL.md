---
name: git-workflow
description: >
    MANDATORY: This tool MUST be used for EVERY SINGLE git operation, including basic checks like status, diff, log, and any git-related queries.
    NEVER use bash or other tools for git commands.
    Always load appropriate reference files BEFORE responding or executing any git commands.
    Provides git expertise for ALL git operations, including information retrieval, commit message generation, branch management,
    conflict resolution, code review workflows, status checks, diffs, logs, and any other git-related tasks.
---

# Git Workflow Expert

This skill helps with git operations by routing you to the appropriate resources.

## Task Detection and Routing

**When the user mentions retrieving information about changes, or providing a github url:**

1. READ @references/changes-info.md for workflow patterns
2. Provide the information requested

**When the user mentions commit messages or wants to commit:**

1. READ @references/commit-message.md for guidelines
2. Generate commit message following the loaded guidelines

## Rules

- Use this skill for ALL git operations and queries
- This tool must ALWAYS be used when running ANY git operation, including basic checks like status, diff, and log
- Always load the appropriate reference file BEFORE responding or executing any git commands
- Run analysis scripts when objective data is needed
- Only load what's needed for the current task
- Provide actionable guidance, not just documentation

**When the user mentions conflicts or merge issues:**

1. READ `references/merge-conflicts.md` for resolution patterns
2. Provide resolution guidance

**When the user mentions branching strategy:**

1. READ `references/branch-strategies.md` for workflow patterns
2. Provide recommendations based on their context

**When the user asks about rebasing:**

1. READ `references/rebase-guidelines.md` for best practices
2. Guide them through the appropriate rebase workflow

**When the user wants code review of changes:**

1. RUN `scripts/analyze_diff.py` to get change statistics
2. READ `references/commit-messages.md` for quality standards
3. Review the changes and provide feedback

**For any other git operation (status, diff, log, etc.):**

1. Use appropriate git commands to retrieve information
2. Provide clear, formatted output
