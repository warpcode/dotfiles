# PROGRESSIVE DISCLOSURE PROTOCOL

## PURPOSE
Define how to intelligently load references based on mode, intent, context, and keywords.

## CORE CONCEPT
**Rule**: Routing decisions are NOT based on a single dimension. Combine mode + Intent + Context + Keywords for intelligent Progressive Disclosure.

## FOUR ROUTING DIMENSIONS

### 1. Mode-Based Routing
- **Purpose**: Determine Behavioral Framework (cognitive, workflow, validation, interaction)
- **Detection**: Mode keywords (analyze, create, review, plan, teach)
- **Routing**: Load mode-specific Behavioral Framework
- **Example**: Detected "review" → Apply review mode Behavioral Framework → Load @references/modes/review.md

### 2. Intent-Based Routing
- **Purpose**: Load domain-specific or task-specific guidance
- **Detection**: User intent keywords (create skill, design agent, audit security)
- **Routing**: Load intent-specific references
- **Example**: Detected "create skill" → Load @references/components/skills.md

### 3. Context-Based Routing
- **Purpose**: Load environment or project-specific patterns
- **Detection**: Project type, existing files, environment variables
- **Routing**: Load context-aware references
- **Example**: Python project detected → Load @references/contexts/python-patterns.md

### 4. Keyword-Based Routing
- **Purpose**: Load specialized knowledge for specific domains
- **Detection**: Domain keywords (SQL injection, SOLID, microservices)
- **Routing**: Load domain expertise references
- **Example**: "SQL injection" detected → Load domain security references

## COMBINING DIMENSIONS

**Pattern**: `Route(mode) AND Route(Intent) AND Route(Context) AND Route(Keywords)`

### Example 1: "Review SQL injection in this Laravel app"
- mode: Review (keyword "review")
- Intent: Security audit (context "injection")
- Context: Laravel framework (detected from files)
- Keywords: "SQL injection"
- Routing: Review mode Behavioral Framework + OWASP Top 10 + Laravel patterns + SQL injection guidance

### Example 2: "Create a skill for PDF rotation"
- mode: Write/Edit (keyword "create")
- Intent: Skill creation (keyword "skill")
- Context: File processing (keyword "PDF rotation")
- Routing: Write mode Behavioral Framework + @references/components/skills.md

## ROUTING PATTERN EXAMPLES

### Simple Mode Routing
```markdown
IF mode == "review" THEN
  Apply review mode Behavioral Framework
  IF intent == "security" THEN
    READ domain security references
  END
END
```

### Multi-Dimensional Routing with ELSE IF
```markdown
IF mode == "create" AND intent == "skill" THEN
  Apply write mode Behavioral Framework
  READ @references/components/skills.md

  IF keyword == "security" THEN
    READ domain security patterns
  ELSE IF keyword == "database" THEN
    READ domain database patterns
  ELSE
    READ generic skill patterns
  END
END
```

### Context-Aware Routing with Nested IF
```markdown
IF framework == "laravel" THEN
  READ Laravel patterns

  IF mode == "review" THEN
    Apply review mode Behavioral Framework with Laravel-specific validation
    IF intent == "security" THEN
      READ Laravel security patterns
    ELSE IF intent == "performance" THEN
      READ Laravel optimization patterns
    END
  END
END
```

## IMPLEMENTATION PATTERN

### Step 1: Detect Mode
```
Input: "Review SQL injection in this Laravel app"
Scan keywords: "review" → Mode: REVIEW
Apply: Review mode Behavioral Framework (cognitive, workflow, validation, interaction)
```

### Step 2: Detect Intent
```
Input: "Review SQL injection in this Laravel app"
Analyze intent: Security audit → INTENT: Security Review
Load: OWASP Top 10 patterns
```

### Step 3: Detect Context
```
Input: "Review SQL injection in this Laravel app"
Scan files: Found Laravel routes, controllers, models
Context: Framework: Laravel → Load: Laravel patterns
```

### Step 4: Detect Keywords
```
Input: "Review SQL injection in this Laravel app"
Extract keywords: "SQL injection" → Domain: Security
Load: SQL injection mitigation patterns
```

### Step 5: Combine and Execute
```
Applied: Review mode Behavioral Framework + OWASP Top 10 + Laravel patterns + SQL injection guidance
Result: Context-aware, mode-compliant, domain-expert response
```
