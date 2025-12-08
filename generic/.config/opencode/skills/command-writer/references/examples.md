# Command-Writer Examples

This file contains extended examples of command generation using the command-writer skill.

## Basic Examples

### Code Review Command

**Request**: Create a command called 'code-review' that performs code review on specified files.

**Generated Command** (`~/.config/opencode/command/code-review.md`):

```markdown
---
description: Perform comprehensive code review on specified files using quality agents
agent: quality/code-reviewer
---

1. Analyze the provided files: `$ARGUMENTS`
2. Run quality checks using the code-reviewer agent
3. Generate review report with findings and recommendations
4. Suggest fixes for identified issues
```

**Usage**: `/code-review src/main.js src/utils.js`

### Git Commit Command

**Request**: Create a command called 'smart-commit' that handles git commits with conventional messages.

**Generated Command** (`~/.config/opencode/command/smart-commit.md`):

```markdown
---
description: Create conventional git commits using git-workflow skill
---

1. Stage changes: `git add $ARGUMENTS`
2. Generate commit message using git-workflow skill
3. Commit with generated message
4. Push if requested
```

**Usage**: `/smart-commit .` or `/smart-commit specific-file.js`

## Complex Workflow Examples

### Feature Deployment Command

**Request**: Create a 'feature-deploy' command that handles the full deployment workflow.

**Generated Command** (`~/.config/opencode/command/feature-deploy.md`):

```markdown
---
description: Complete feature deployment workflow with quality checks and git operations
---

1. Run quality checks using @quality/holistic-reviewer on $ARGUMENTS
2. If checks pass, create feature branch using skills_git_workflow
3. Merge to main branch after approval
4. Deploy and monitor
```

**Usage**: `/feature-deploy feature-branch-name`

### API Documentation Command

**Request**: Create a command called 'api-docs' that generates API documentation.

**Generated Command** (`~/.config/opencode/command/api-docs.md`):

```markdown
---
description: Generate comprehensive API documentation from code
agent: documentation/api-documenter
---

1. Scan codebase for API endpoints using grep
2. Use context7 tool to fetch relevant documentation
3. Generate OpenAPI spec with api-documenter agent
4. Create documentation files
```

**Usage**: `/api-docs routes/ controllers/`

## Error Handling Examples

### Command with Validation

**Request**: Create a command that validates inputs before proceeding.

**Generated Command** (`~/.config/opencode/command/validated-deploy.md`):

```markdown
---
description: Deployment with input validation and error handling
---

1. Validate $ARGUMENTS are provided
2. Check if files exist using read tool
3. If validation fails, exit with error message
4. Proceed with deployment if valid
```

**Usage**: `/validated-deploy app.js config.json`

### Command with Fallbacks

**Request**: Create a command that handles missing dependencies gracefully.

**Generated Command** (`~/.config/opencode/command/safe-build.md`):

```markdown
---
description: Safe build process with dependency checks
---

1. Check if required tools are available
2. If missing, suggest installation commands
3. If available, proceed with build using $ARGUMENTS
4. Handle build failures with rollback options
```

**Usage**: `/safe-build production`

## Integration Examples

### Multi-Agent Command

**Request**: Create a command that coordinates multiple agents.

**Generated Command** (`~/.config/opencode/command/full-review.md`):

```markdown
---
description: Complete code review using multiple specialized agents
---

1. Run security analysis with @security/vulnerability-scanner
2. Perform code quality review with @quality/code-reviewer
3. Check performance with @performance/analyzer
4. Generate consolidated report
```

**Usage**: `/full-review src/`

### Skill Integration Command

**Request**: Create a command that leverages specific skills.

**Generated Command** (`~/.config/opencode/command/git-workflow-deploy.md`):

```markdown
---
description: Deployment using git-workflow skill for version control
---

1. Use skills_git_workflow to create release branch
2. Run tests and quality checks
3. Merge and tag release using git-workflow conventions
4. Deploy to production
```

**Usage**: `/git-workflow-deploy v1.2.3`

## Advanced Template Patterns

### Dynamic Argument Processing

```markdown
---
description: Process multiple files with dynamic arguments
---

1. Parse $ARGUMENTS into file list
2. For each file in list:
   - Validate file exists
   - Process file with appropriate tool
   - Generate output
3. Combine results into final report
```

### Conditional Logic in Templates

```markdown
---
description: Conditional processing based on input type
---

1. Determine input type from $ARGUMENTS
2. If type is 'code': use code-reviewer agent
3. If type is 'config': use validation tools
4. If type is 'docs': use documentation tools
5. Apply appropriate processing
```

### Error Recovery Patterns

```markdown
---
description: Command with comprehensive error handling
---

1. Backup current state
2. Attempt operation on $ARGUMENTS
3. If operation fails:
   - Log error details
   - Attempt recovery procedures
   - Notify user of issues
4. Restore state if recovery fails
5. Provide success/failure summary
```

These examples demonstrate the flexibility and power of command templates in encapsulating complex workflows while maintaining safety and reliability.