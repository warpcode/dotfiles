# AGENTS.md

## Agent Usage Guidelines
- **ALWAYS Check for Relevant Agents:** Before performing any task, the AI MUST check if a relevant agent or subagent exists that can handle the task more effectively.
- **Prioritize Specialized Agents:** Use specialized agents (code-writer, code-reviewer, commit-message-writer, etc.) for their designated purposes rather than handling tasks manually.
- **Agent Discovery:** When encountering a task, first determine if any available subagents are designed to handle it.
- **Quality Assurance:** Use agents designed for quality control (code-reviewer, spelling-grammar-checker) to ensure high standards.
- **Efficiency:** Leverage agents to perform complex tasks more accurately and efficiently than manual approaches.

## Git Commit Guidelines
- **Authorization Required:** AI must NEVER commit changes without explicit user approval.
- **Permission Protocol:** Always ask permission before committing, propose the commit message first.
- **Approval Mandate:** Do not commit unless user explicitly approves, even for additional changes or follow-ups.
- **No Auto-Commits:** Strict prohibition on automatic commits; user consent is mandatory for every commit action.
- **No Auto-Pushes:** AI must NEVER push git changes to remote repositories unless specifically requested by the user.