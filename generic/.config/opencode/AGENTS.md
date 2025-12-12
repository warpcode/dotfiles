# AGENTS.md

## Rules (MANDATORY)
- **Rule 1 - Agent Priority**: ALWAYS use specialized agents over manual work
- **Rule 2 - Agent Verification**: MUST verify subagent fit before starting
- **Rule 3 - Skill Loading**: MUST search for and load relevant skills/tools BEFORE any task
- **Rule 4 - Git Safety**: NEVER commit/push without explicit user OK
- **Rule 5 - Rule Citation**: MUST cite specific rule when making decisions
- **Rule 6 - Skill Prompt Fidelity**: If a skill/tool is loaded and it returns a prompt or instruction, the agent MUST read and fully understand that prompt before acting. If the skill recommends another file for more information, the agent MUST load and read that file using the Read tool before proceeding.
- **Rule 7 - Reference Verification**: MUST explicitly load and read any referenced skill/docs (using the Read tool) before acting on that skill's guidance; log the exact file paths read and cite them when making decisions.
- **Rule 8 - Concise Responses**: ALWAYS reply concisely; avoid unnecessary repetition, filler words, and verbose explanations unless the user explicitly asks for more detail.

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
- **Reference audit**: When a skill is used, list the reference files read and the Read tool outputs used to verify them.

## User Enforcement Commands
- "Check rules before proceeding"
- "Which rule applies here? Cite it"
- "Verify compliance"
- "Reload skills per Rule 3"
- "Show refs read"

## Mandatory Pre-Task Checklist
Before ANY action, state concisely:
1. Which rule(s) apply
2. Which skill(s) will be loaded
3. Which agent(s) will be used (if applicable)
4. How compliance will be verified
5. Which skill reference files will be read (paths) and a short note on what was learned; use the Read tool to read those files and cite them.


