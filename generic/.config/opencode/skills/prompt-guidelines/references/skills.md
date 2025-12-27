# PROTOCOLS: SKILL CREATION

## CORE PHILOSOPHY
- **Goal**: High-fidelity, token-efficient specialized capabilities.
- **Principle**: Progressive Disclosure (Metadata -> Body -> Resources).
- **Limit**: `SKILL.md` < 500 lines. Else -> Split to `@references/`.

## STRUCTURE
### Directory Layout
```text
skill-name/
├── SKILL.md (Required)
├── scripts/ (Optional: Python/Bash)
├── references/ (Optional: Docs/Schemas)
└── assets/ (Optional: Templates)
```

### SKILL.md Format
- **Frontmatter**:
  - `name`: [a-z0-9-] (Max 64 chars).
  - `description`: [What] + [When] + [Triggers]. (Max 1024 chars).
  - `allowed-tools`: [List] (Optional).
- **Body**: STM Instructions + Examples + Requirements.

## CREATION PROCESS
1. **Plan**: Task -> Reusable_Resources(Scripts/Docs).
2. **Init**: `scripts/init_skill.py`.
3. **Edit**: Implement logic using STM.
4. **Pkg**: `scripts/package_skill.py`.

## RESOURCE MANAGEMENT
- **Scripts**: Deterministic tasks (PDF rotate, Data processing).
- **References**: Heavy context (API Docs, Schemas). Load on demand.
- **Assets**: Output artifacts (Logos, Templates).
- **Rule**: `Ref == @references/filename.md`. No MD links.

## BEST PRACTICES
- **Tone**: Imperative. "Do X. Check Y."
- **Context**: Assume LLM intelligence. Don't explain *why*, just *what*.
- **Triggers**: Description must contain specific keywords/filetypes.
- **Validation**:
  - YAML valid?
  - Paths relative?
  - Dependencies listed?

## SECURITY CONSIDERATIONS (MANDATORY)
- **Input Handling**: Always sanitize user inputs in scripts.
- **Path Safety**: Validate file paths, prevent directory traversal.
- **Command Execution**: Never use `eval()`, `subprocess` with unsanitized input.
- **Secrets**: Never log or output credentials/tokens.
- **Permissions**: Scripts run with minimal required privileges.
- **Error Messages**: Sanitized, no sensitive data exposure.

## TEMPLATE
```yaml
---
name: skill-name
description: [Action] on [Target]. Use when [Trigger].
---

# [Skill Name]

## QUICK START
- Example: `[Command]`

## INSTRUCTIONS
1. Step_1: Input -> Process.
2. Step_2: Use `@references/guide.md` if complex.
3. Step_3: Output format.

## EXAMPLES
<example>
User: [Trigger]
Agent: [Response]
</example>
```
