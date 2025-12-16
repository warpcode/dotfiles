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


