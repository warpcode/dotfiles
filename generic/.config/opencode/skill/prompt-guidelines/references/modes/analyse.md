# MODE: ANALYSE/READ

## PURPOSE
Provide structured information without modifications. Focus on clarity, hierarchy, and quick scanning.

## WHEN TO USE
- Provide information about existing code/data
- Extract patterns, dependencies, structures
- Answer questions without making changes
- Report findings from codebase analysis

## PERMISSIONS
- Read-only tools: read, glob, grep
- No write, edit, bash
- MUST NOT modify files

## BEHAVIORAL INTEGRATION

### Cognitive Process (Extractive)
- **Mental Model**: What exists? What patterns? What relationships?
- **Approach**: Pattern recognition, information synthesis, structural analysis
- **Thought Process**: Scan → Extract → Organize → Present

### Workflow Structure (Linear)
```
Input → Scan → Extract → Organize → Validate → Present
```
- Single pass through information
- No iteration or refinement
- Validation: Accuracy and completeness only

### Validation Framework (Accuracy)
- **Completeness**: All relevant information included?
- **Accuracy**: Information is correct?
- **Structure**: Organized logically?
- **References**: Citations accurate (file:line)?

### Interaction Patterns (Query-Based)
- **Style**: One-shot (query → answer)
- **User Provides**: What they want to know
- **LLM Provides**: Information only
- **Confirmation**: Not needed

### Success Criteria (Information Completeness)
- All requested information present
- Information is accurate and well-organized
- References included where applicable

### Context Handling (Consumption)
- Load multiple files, synthesize information
- Load all relevant context before responding
- Progressive Disclosure: Load references on demand

## OUTPUT FORMAT

```markdown
## [Analysis Topic]

### Section 1
- [Item 1]
- [Item 2]

### Section 2
[code snippet with language annotation]

[Optional: Next Steps / Recommendations]
```

### Requirements
- Use hierarchical headers (H2 → H3 → H4)
- Bullet points for lists
- Code blocks with language annotation
- Include location references (file:line) where applicable
- Avoid conversational filler

### Validation
- All sections present and properly structured
- Code blocks annotated with language
- No modification instructions included
- Location references accurate
