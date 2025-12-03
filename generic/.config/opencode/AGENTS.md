# AGENTS.md

## Rules (MANDATORY)
- **Rule 1 - Agent Priority**: ALWAYS use specialized agents over manual work
- **Rule 2 - Agent Verification**: MUST verify subagent fit before starting
- **Rule 3 - Skill Loading**: MUST load relevant skills/tools BEFORE any task
- **Rule 4 - Git Safety**: NEVER commit/push without explicit user OK
- **Rule 5 - Rule Citation**: MUST cite specific rule when making decisions

## Core Agents
- `core/feature-lead`: Orchestrates full feature dev (plan/code/review). Use for new features.
- `core/bug-smasher`: End-to-end bug fix (root cause/test/review). Use for bugs.
- `core/tech-debt-crusher`: Audits/fixes high-impact issues. Use for improvements.

## Documentation
- `documentation/readme-writer`: Generates README from analysis.
- `documentation/changelog-generator`: CHANGELOG from git.
- `documentation/docblock-writer`: Adds PHPDoc/JSDoc.

## Git Workflow
- `git-workflow/branch-name-suggester`: Conventional branch names from tickets.
- `git-workflow/pr-description-writer`: PR descriptions from branch changes.

## Project Mgmt
- `project-management/task-splitter`: Ticket -> technical checklist.
- `project-management/adhd-task-adapter`: Coding tasks -> ADHD steps.
- `project-management/epic-breakdown`: Large ideas -> epics.
- `project-management/ticket-creator`: Epics -> stories.
- Others: acceptance-criteria-writer, estimation-helper, sprint-planner.

## Quality
- `quality/code-reviewer`: Adaptive code reviews by lang/file.
- `quality/holistic-reviewer`: Full PR multi-review (sec/perf/etc.).

## Refactoring
- `refactoring/code-modernizer`: Updates syntax (e.g., array[]).
- `refactoring/code-organizer`: Sorts use stmts.
- `refactoring/dead-code-remover`: Removes unused privates.
- `refactoring/dependency-updater`: Lists outdated deps.

## Analysis
- `codebase-analysis/orchestrator`: Full audit (arch/sec/perf/test).

## Top-Level
- `adhd-task-breaker`: Non-tech task breakdowns.
- `agent-writer`: Agent config gen/review.
- `code-writer`: Code w/ auto-review.
- `documentation-writer`: Docs/comments ('why' focus).
- `fact-checker`: Validates changes.
- `spelling-grammar-checker`: Text checks.
- `task-manager`: Taskwarrior CLI.

## Rule Enforcement
- **Mandatory rule checks**: Before ANY task, state which rule applies
- **Skill loading requirement**: MUST load relevant skills/tools BEFORE proceeding
- **Agent verification**: MUST verify if specialized agent fits before manual work
- **Explicit compliance**: User can demand "Check rules compliance" at any time

## User Enforcement Commands
- "Check rules before proceeding"
- "Which rule applies here? Cite it"
- "Verify compliance"
- "Reload skills per Rule 3"

## Mandatory Pre-Task Checklist
Before ANY action, state:
1. Which rule(s) apply
2. Which skill(s) will be loaded
3. Which agent(s) will be used (if applicable)
4. How compliance will be verified
 
