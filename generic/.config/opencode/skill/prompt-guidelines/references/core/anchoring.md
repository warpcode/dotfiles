# ANCHORING PATTERNS

## PURPOSE
Establish patterns for reference binding and cross-referencing.

## REFERENCE SYNTAX
- **Syntax**: `Ref == @path/to/file`
- **Constraint**: Markdown Links `[text](path)` == FORBIDDEN
- **Rule**: All `@` paths MUST be relative to skill's main SKILL.md file

## SKILL LOADING SYNTAX
### In Skill Reference Files
- Use `@` syntax for internal references
- Example: `@references/commit-message.md` within git-workflow skill

### In Commands
- Use `skill(skill_id)` to load and execute
- Load: `skill(git-workflow)` -> Load instructions and execute
- Example: `skill(git-workflow)` (not `@skills/git-workflow`)

### Constraint
- Never use `@skills/name` in commands - always use skill() function

## REFERENCE LOADING RULES
- **Immediate**: Load references IMMEDIATELY when task requires specialized knowledge
- **Directive**: `ACTION -> READ FILE: @references/filename.md`
- **Validation**: Verify file exists before loading
- **Path Safety**: All paths relative to SKILL.md

## PROGRESSIVE DISCLOSURE
- **Load on Demand**: Load references based on mode, intent, context
- **Avoid Overload**: Don't load all references upfront
- **Explicit Routing**: Use IF/THEN blocks for conditional loading
