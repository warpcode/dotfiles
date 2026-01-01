# PROTOCOLS: SKILL CREATION

## CORE PHILOSOPHY
- **Goal**: High-fidelity, token-efficient specialized capabilities.
- **Principle**: Progressive Disclosure (Metadata -> Body -> Resources).
- **Limit**: `SKILL.md` < 200 lines (routing only). Detailed content -> `@references/`.

## STRUCTURE
### Directory Layout (Recommended)

#### Minimal Structure
```text
skill-name/
├── SKILL.md (Required - main skill file, <200 lines)
└── references/ (Optional - progressive disclosure)
```

#### Recommended Structure
```text
skill-name/
├── SKILL.md (Required - routing logic only)
├── references/ (Optional - progressive disclosure)
│   ├── modes/        # Mode-specific behavioral extensions
│   ├── intents/      # Intent-specific workflows
│   ├── contexts/     # Context/environment-specific patterns
│   ├── domains/      # Domain expertise (security, database, api, etc.)
│   └── schemas/     # Data schemas, API specs, configuration formats
├── templates/       # Optional - Output templates, prompt templates
├── scripts/         # Optional - Python/Bash scripts for deterministic tasks
└── assets/          # Optional - Logos, icons, file templates, example files
```

### SKILL.md Constraints
- **Purpose**: Routing logic only (IF/THEN blocks for reference loading)
- **Limit**: < 200 lines (routing + glossary)
- **Content**: Frontmatter + Routing Logic + Glossary
- **Prohibited**: Detailed protocols, examples, execution logic (move to references/)

## ROUTING LOGIC PATTERN
```markdown
## ROUTING_PROTOCOL

### Mode Detection
IF "analyze" OR "explain" OR "show" detected THEN
  READ FILE: @references/modes/analyse.md
END

IF "create" OR "write" OR "edit" detected THEN
  READ FILE: @references/modes/write.md
  READ FILE: @references/output/common.md
END

IF "review" OR "check" OR "audit" detected THEN
  READ FILE: @references/modes/review.md
END

### Component-Specific Loading
IF domain-specific keywords detected THEN
  READ FILE: @references/domains/[domain].md
END

### Context-Aware Loading
IF framework/language detected THEN
  READ FILE: @references/contexts/[framework].md
END
```

## RESOURCE MANAGEMENT
- **Scripts**: Deterministic tasks (PDF rotate, Data processing). Path: `@scripts/`.
- **References**: Heavy context (API Docs, Schemas). Path: `@references/`.
- **Rule**: You **MUST** load resources **IMMEDIATELY** when the task requires specialized knowledge. Use the directive: `ACTION -> READ FILE: @references/filename.md`.
- **Constraint**: ALL `@` paths (references, scripts, assets) MUST be relative to the skill's main `SKILL.md` file.
- **Assets**: Output artifacts (Logos, Templates). Path: `@assets/`.

## SECURITY CONSIDERATIONS (MANDATORY)
- **Input Handling**: Always sanitize user inputs in scripts.
- **Path Safety**: Validate file paths, prevent directory traversal.
- **Command Execution**: Never use `eval()`, `subprocess` with unsanitized input.
- **Secrets**: Never log or output credentials/tokens.
- **Permissions**: Scripts run with minimal required privileges.
- **Error Messages**: Sanitized, no sensitive data exposure.

## BEST PRACTICES
- **Tone**: Imperative. "Do X. Check Y."
- **Routing**: Explicitly instruct the LLM to read reference files based on intent (e.g., "IF [Condition] -> READ FILE: @references/[file].md").
- **Context**: Assume LLM intelligence. Don't explain *why*, just *what*.
- **Triggers**: Description must contain specific keywords/filetypes.
- **Validation**:
  - YAML valid?
  - Paths relative (using `@` syntax)?
  - Dependencies listed?
  - Routing logic explicit?

## REFERENCE FILE GUIDELINES
### Size Limits
- **SKILL.md**: < 200 lines (routing only)
- **Reference files**: < 200 lines each (single concern)
- **Templates**: < 300 lines

### Reference Headers
- **Mandatory**: # PURPOSE
- **Recommended**: # TRIGGER_CONDITIONS (when to load)
- **Content**: STM-formatted rules and patterns

### No Circular Dependencies
- Reference A references B
- B references C
- C must NOT reference A
