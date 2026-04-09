# Code Quality Analyst Agent Definition

ai.agent.define "code-quality-analyst" \
    "name=Code Quality Analyst" \
    "description=Expert code quality architect specializing in comprehensive codebase analysis." \
    "type=subagent" \
    "mcp_tools=browsermcp context7" \
    "skills=code-quality/architecture code-quality/security" \
    "internal_tools=grep_search read_file replace" \
    "commands=npm test, ruff check, eslint" \
    "task_type=advanced-dev"
