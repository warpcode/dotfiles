# PROTOCOLS: SKILL CREATION

## CORE PHILOSOPHY
- **Goal**: High-fidelity, token-efficient specialized capabilities.
- **Principle**: Progressive Disclosure (Metadata -> Body -> Resources).
- **Limit**: `SKILL.md` < 500 lines. Else -> Split to `@references/`.

## STRUCTURE
### Directory Layout (Recommended)

#### Minimal Structure
```text
skill-name/
├── SKILL.md (Required - main skill file)
└── references/ (Optional - progressive disclosure)
```

#### Recommended Structure
```text
skill-name/
├── SKILL.md (Required - main skill file)
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

#### Flexible Organization
**Rule**: Reference folder naming is FLEXIBLE. Use structure that fits your skill's needs.

**Alternative**: Flat structure at root level
```text
skill-name/
├── SKILL.md
├── review-mode.md        # Mode-specific at root
├── skill-creation.md    # Intent-specific at root
├── python-patterns.md    # Context-specific at root
└── owasp-top10.md       # Domain-specific at root
```

**Alternative**: All in references/ without subdirectories
```text
skill-name/
├── SKILL.md
└── references/
    ├── review-mode.md
    ├── skill-creation.md
    ├── python-patterns.md
    └── owasp-top10.md
```

### Directory Purposes

#### SKILL.md (Required)
- **Purpose**: Main skill file with frontmatter, instructions, routing logic
- **Constraint**: Must be < 500 lines. Use references/ for detailed content
- **Format**: YAML frontmatter + Markdown body

#### references/ (Optional but Recommended)
- **Purpose**: Progressive disclosure for heavy context, specialized knowledge
- **Use Cases**:
  - API documentation
  - Domain expertise (security, database, patterns)
  - Framework-specific patterns
  - Configuration schemas
- **Routing**: Load based on mode, intent, context, or keywords

#### references/modes/ (Optional)
- **Purpose**: Mode-specific behavioral extensions
- **Use Cases**: Adapt generic mode frameworks for specific domains
- **Example**: references/modes/review.md extends review mode with security-specific validation

#### references/intents/ (Optional)
- **Purpose**: Intent-specific workflow guidance
- **Use Cases**: Step-by-step workflows for specific tasks
- **Example**: references/intents/skill-creation.md provides detailed skill creation process

#### references/contexts/ (Optional)
- **Purpose**: Context or environment-specific patterns
- **Use Cases**: Language-specific, framework-specific, platform-specific patterns
- **Example**: references/contexts/python.md provides Python coding patterns

#### references/domains/ (Optional)
- **Purpose**: Domain expertise and specialized knowledge
- **Use Cases**: Security, database, API, performance, testing domains
- **Example**: references/domains/security.md contains OWASP patterns

#### references/schemas/ (Optional)
- **Purpose**: Data schemas, API specifications, configuration formats
- **Use Cases**: JSON schemas, OpenAPI specs, database schemas
- **Example**: references/schemas/api-response.json defines response format

#### templates/ (Optional)
- **Purpose**: Reusable templates for outputs, prompts, files
- **Use Cases**: Code templates, response templates, prompt templates
- **Example**: templates/python-class.md for Python class generation

#### scripts/ (Optional)
- **Purpose**: Deterministic tasks that require external execution
- **Use Cases**: File processing, data transformation, API calls
- **Languages**: Python, Bash, or any executable
- **Example**: scripts/rotate_pdf.py for PDF rotation

#### assets/ (Optional)
- **Purpose**: Static assets, templates, examples
- **Use Cases**: Logos, icons, file templates, example files
- **Example**: assets/logo.png or assets/example-config.yaml

### SKILL.md Format
- **Frontmatter**:
  - `name`: [a-z0-9-] (Max 64 chars).
  - `description`: Purpose + Scope + Excludes (domain) + Triggers. (Max 1024 chars).
  - `allowed-tools`: [List] (Optional).
- **Body**: STM Instructions + Examples + Requirements.

## CREATION PROCESS
1. **Plan**: Task -> Reusable_Resources(Scripts/Docs).
2. **Init**: `scripts/init_skill.py`.
3. **Edit**: Implement logic using STM.
4. **Pkg**: `scripts/package_skill.py`.

## RESOURCE MANAGEMENT
- **Scripts**: Deterministic tasks (PDF rotate, Data processing). Path: `@scripts/`.
- **References**: Heavy context (API Docs, Schemas). Path: `@references/`.
- **Rule**: You **MUST** load resources **IMMEDIATELY** when the task requires specialized knowledge. Use the directive: `ACTION -> READ FILE: @references/filename.md`.
- **Constraint**: ALL `@` paths (references, scripts, assets) MUST be relative to the skill's main `SKILL.md` file.
- **Assets**: Output artifacts (Logos, Templates). Path: `@assets/`.
- **Syntax**: `Ref == @path/to/file`. No MD links.

## BEST PRACTICES
- **Tone**: Imperative. "Do X. Check Y."
- **Routing**: Explicitly instruct the LLM to read reference files based on intent (e.g., "IF [Condition] -> READ FILE: @references/[file].md").
- **Context**: Assume LLM intelligence. Don't explain *why*, just *what*.
- **Triggers**: Description must contain specific keywords/filetypes.
- **Validation**:
  - YAML valid?
  - Paths relative (using `@` syntax)?
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
description: >-
  [One-line purpose]
  Scope: [key capabilities]
  Excludes: [exclusions - domain skills only]
  Triggers: [keywords for routing]
---

# [Skill Name]

## PURPOSE
[One-sentence description of skill's goal]

## EXECUTION PROTOCOL [MANDATORY]

### Phase 1: Clarification
IF requirements != complete -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning
Propose plan -> IF impact > Low -> Wait(User_Confirm)

### Phase 3: Execution
Execute atomic steps. Validate result after EACH step.

### Phase 4: Validation
Final_Checklist: [Check items]. IF Fail -> Self_Correct.

## VALIDATION CHECKLIST [MANDATORY]
- [ ] [Check 1]
- [ ] [Check 2]

## EXAMPLES [RECOMMENDED]
```markdown
User: [Trigger]
Agent: [Response]
```
```
