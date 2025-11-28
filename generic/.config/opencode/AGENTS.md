# AGENTS.md

## Guidelines
- **Prioritize agents**: Use specialized agents (code-writer, code-reviewer) over manual work.
- **Agent check**: Always verify if a subagent fits the task.
- **Git rules**: NEVER commit/push without explicit user OK; propose message first.

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

