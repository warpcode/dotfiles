---
name: skill-template
description: >
  [One-line purpose]
  Scope: [key capabilities]
  Excludes: [exclusions - domain skills only]
  Triggers: [keywords for routing]
---

# SKILL_NAME

## PURPOSE
[One-sentence description of skill's goal]

## DOMAIN EXPERTISE [OPTIONAL - Domain Skills Only]
- **Common Issues**: [List]
- **Common Mistakes**: [List]
- **Related Patterns**: [List]
- **Problematic Patterns**: [List]
- **Security Concerns**: [List]
- **Performance Issues**: [List]

## MODE DETECTION [OPTIONAL - Multi-Mode Only]
- **WRITE Mode**: Keywords: ["keyword1", "keyword2"]
- **REVIEW Mode**: Keywords: ["keyword1", "keyword2"]

## LOADING STRATEGY [OPTIONAL - Has Internal References]
### Write Mode (Progressive)
Load patterns based on requirements:
- Topic 1 -> Load `@reference/file1.md`
- Topic 2 -> Load `@reference/file2.md`

### Review Mode (Exhaustive)
Load comprehensive checklists:
- IF review requested -> Load all pattern references

## ROUTING LOGIC [OPTIONAL - Progressive Disclosure]
### Progressive Loading (Write Mode)
- **IF** request mentions "topic1" -> READ FILE: `@reference/file1.md`
- **IF** request mentions "topic2" -> READ FILE: `@reference/file2.md`

### Comprehensive Loading (Review Mode)
- **IF** request mentions "review" -> READ FILES: `@reference/file1.md`, `@reference/file2.md`

## CONTEXT DETECTION [OPTIONAL]
[Detection rules for frameworks, languages, platforms]

## EXECUTION PROTOCOL [MANDATORY]

### Phase 1: Clarification
[Clarification logic]
IF requirements != complete -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning
[Planning logic]
Propose plan -> IF impact > Low -> Wait(User_Confirm)

### Phase 3: Execution
[Execution logic]
Execute atomic steps. Validate result after EACH step.

### Phase 4: Validation
[Validation logic]
Final_Checklist: [Check items]. IF Fail -> Self_Correct.

## OUTPUT FORMAT [OPTIONAL - Complex Output Requirements]
### Write Mode Output
```markdown
[Write mode output template]
```

### Review Mode Output
```markdown
[Review mode output template]
```

## SECURITY FRAMEWORK [OPTIONAL - Security-Sensitive]
- **Threat Model**: [Description]
- **Validation Layers**: [Layers 1-4]
- **Threat Controls**: [Control rules]
- **Error Handling**: [Error handling logic]

## DEPENDENCIES [OPTIONAL - External Tools]
- tool1: [version/purpose]
- tool2: [version/purpose]

## ENVIRONMENT AWARENESS [OPTIONAL - Context-Dependent]
Action(Create|Edit) -> scan(~/.config/opencode/) -> Verify(Dependencies)
Assumption == FALSE. Reference ONLY existing components.

## VALIDATION CHECKLIST [MANDATORY]
- [ ] [Check 1]
- [ ] [Check 2]
- [ ] [Check 3]

## EXAMPLES [RECOMMENDED]

### Example 1: [Description]
[Example details]

### Example 2: [Description]
[Example details]

## GLOSSARY [RECOMMENDED when abbreviations exist]

**TERM1**: [Definition]
**TERM2**: [Definition]
