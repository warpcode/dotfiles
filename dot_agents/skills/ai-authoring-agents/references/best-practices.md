# Subagent Authoring Best Practices

Engineering guide for designing, scoping, and tuning custom subagent definitions.

---

## 1. Cognitive Boundaries & Persona Scoping

Subagents are isolated execution sessions spawned to handle specific subtasks without polluting the primary coordinator's context window.

### Good Subagent Boundaries
- **Narrow Responsibility**: Each subagent does one specific type of work (e.g. codebase exploration, security audit, HTL template building, tech debt cleanup).
- **Clear Tool Surface**: Tools are tailored to the role (e.g. read-only tools for reviewers, MCP Figma + edit tools for frontend specialists).
- **Explicit Exit Criteria**: The agent knows when its task is complete and returns a structured verdict or payload to the coordinator.

### Anti-Patterns
- **The "God Subagent"**: A subagent that has all tools, full permissions, and vague instructions ("Help with everything").
- **Chatty Coordinator Loops**: Spawning a subagent for a single trivial 1-line file read instead of doing it inline.
- **Leaked Context Assumptions**: Expecting the subagent to "know what we talked about 5 turns ago" without passing parameters.

---

## 2. Context Isolation & Self-Contained Directives

Subagents operate in their own clean context window. They do **not** inherit previous chat history.

### The Directive Rule
Any task passed to a subagent MUST be context-complete:
- Explicit file paths (absolute or workspace-relative).
- Concrete parameters (e.g., target branch, comparison diff, specific function names).
- Exact output format required (JSON, Markdown table, diff block).

---

## 3. Least Privilege & Security Sandboxing

Always apply least-privilege permissions based on the subagent's role:

| Agent Role | File Read | File Edit | Shell / Terminal | Web / Search | Recommended Permissions |
|---|---|---|---|---|---|
| **Auditor / Reviewer** | Allow | Deny | Deny (or `git diff` only) | Deny | `read: allow, edit: deny, bash: deny` |
| **Researcher / Explorer** | Allow | Deny | Deny | Allow | `read: allow, edit: deny, websearch: allow` |
| **Implementer / Specialist** | Allow | Allow | Allow (safe commands) | Allow | `read: allow, edit: allow, bash: ask/allow` |
| **Janitor / Maintainer** | Allow | Allow | Allow (`test`, `lint`) | Deny | `read: allow, edit: allow, bash: allow` |

---

## 4. Model Routing & Token Economics

Subagents offer huge cost savings when routed to appropriate model tiers:

1. **High-Noise Exploration**:
   - Broad greps, searching file trees, reading large log dumps, documentation fetching.
   - **Model Tier**: Lightweight, fast, cheap models (e.g., `gemini-3.5-flash`, `haiku`, `gpt-4o-mini`).
   - **House Rule**: Exploration subagents must NOT run on master/flagship models.

2. **Complex Implementation & Architecture**:
   - Deep refactoring, multi-file code generation, security-critical audits.
   - **Model Tier**: Flagship models (e.g., `claude-3-5-sonnet`, `gemini-3.5-pro`, `gpt-4o`).

3. **Step Caps (`maxTurns` / `steps`)**:
   - Always cap subagent execution loops (e.g., 10–25 steps) to prevent infinite loops if an error occurs.

---

## 5. Output Contracts & Synthesis Readiness
 
Coordinator agents synthesize subagent findings into final user responses. Make subagent outputs synthesis-friendly:
- Prefer structured JSON or Markdown summaries over raw tool transcripts.
- Include confidence ratings, file locations (`file:///path`), and line numbers (`#L10-L20`).
- Put the verdict / summary first, followed by supporting evidence.
- Use Layer 5 Output Contract specifications from `ai-authoring-prompts` (`[P5.1]` Diff Contract, `[P5.2]` Rubric-as-Judge, `[P5.4]` Rollup / Checklist Log).


---

## 6. No Evals for Pure Subagents

Unlike agent skills (which use test suites and trigger benchmarks in `evals.md`), subagents are **role personas**. 
- Subagents are validated via **schema correctness**, **least-privilege tool enforcement**, **trigger clarity in descriptions**, and **prompt completeness**.
- When testing a new subagent, verify it by spawning it on a targeted, realistic task and verifying that it stays within its sandbox and produces the expected output contract.

---

## 7. Official Documentation & Research References

### Platform Documentation
- **Claude Code**: <https://code.claude.com/docs/en/sub-agents>
- **GitHub Copilot / VS Code**: <https://code.visualstudio.com/docs/agent-customization/custom-agents>
- **OpenCode**: <https://opencode.ai/docs/agents/>
- **Google Antigravity**: <https://antigravity.google/docs/subagents/>
- **ChatGPT / OpenAI Codex**: <https://learn.chatgpt.com/docs/agent-configuration/subagents>
- **Cursor**: <https://cursor.com/docs/agent-customization>
- **Hermes Agent**: <https://hermes-agent.nousresearch.com/docs/developer-guide/creating-agents>

### Structural Archetype References
- [Anthropic Skill-Creator Analyzer Agent](https://github.com/anthropics/skills/blob/main/skills/skill-creator/agents/analyzer.md)
- [Awesome Copilot AEM Front-End Specialist](https://github.com/github/awesome-copilot/blob/main/agents/aem-frontend-specialist.agent.md)
- [Awesome Copilot AWS Cloud Expert](https://github.com/github/awesome-copilot/blob/main/agents/aws-cloud-expert.agent.md)
- [Awesome Copilot GEM Browser Tester](https://github.com/github/awesome-copilot/blob/main/agents/gem-browser-tester.agent.md)
- [Awesome Copilot Universal Janitor](https://github.com/github/awesome-copilot/blob/main/agents/janitor.agent.md)
- [Awesome Claude Agents Python Performance Expert](https://github.com/vijaythecoder/awesome-claude-agents/blob/main/agents/specialized/python/performance-expert.md)
