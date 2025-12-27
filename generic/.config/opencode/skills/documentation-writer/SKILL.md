---
name: documentation-writer
description: >
    Create, read, improve, and validate project documentation: docblocks, docstrings, inline comments, README/markdown
    files, API docs (OpenAPI/Swagger), and CHANGELOGs. Use when the user asks to add or improve documentation,
    generate README.md, create OpenAPI specs, add docblocks/docstrings, or produce a CHANGELOG.
    Trigger words: documentation, docs, docblock, docblocks, docstring, README, README.md, API docs, OpenAPI,
    swagger, CHANGELOG, changelog, docblock-writer, readme-writer, api-documenter, changelog-generator,
    add documentation, improve documentation, write docs, edit docs, validate docs.
---

<rules>
## CORE_RULES
- Logic: Explain WHY (rationale), NOT WHAT/HOW (code shows this)
- Constraint: Documentation != Code Logic Modification
- Constraint: Redundant Comments == FALSE (e.g., "# Create user" for `user = User()`)
- Constraint: Secrets in Docs == FALSE
- Constraint: Docs contradicting Code == FALSE
- Rule: Destructive_Edit (bulk/invasive) -> User_Confirm
- Rule: Target_Audience_Ask (beginner/intermediate/expert)
- Rule: Style_Preference_Ask (concise/detailed)

## EXECUTION_PHASES
### Phase_1: Clarification (Ask)
- Logic: Ambiguity > 0 -> Stop && Ask
- Required_Questions:
  - Target_Audience?
  - Preferred_Style?
  - Commit_Changes?

### Phase_2: Planning (Think)
- Logic: Task -> Plan -> Approval
- Output: Plan (Files + Impacts + Steps)
- Constraint: Impact > Low -> User_Confirm

### Phase_3: Execution (Do)
- Logic: Step_1 -> Verify -> Step_2
- Atomic: Execute && Validate EACH step

### Phase_4: Validation (Check)
- Logic: Result -> Checklist -> Done
- Fail: Self_Correct

## SECURITY_FRAMEWORK
- Threat_Model: Input == Malicious
- Validation_Layers:
  1. Input: Type check, sanitize (strip escapes, command injection, path traversal)
  2. Context: Verify permissions, check dependencies
  3. Execution: Confirm intent, check destructiveness
  4. Output: Verify format, redact secrets
- Error_Handling: Define failure modes, never expose secrets
- Destructive_Ops: rm, sudo, push -f, chmod 777 -> User_Confirm

## DOCUMENTATION_STANDARDS
### Inline_Comments
- Use_Case: Business rules, performance, security
- Example: GDPR compliance rationale

### Docblocks/Docstrings
- Schema: Purpose, Parameters, Returns, Raises, Examples, Notes
- Constraint: No redundant descriptions

### Markdown/Wiki
- Schema: Clear headings, consistent formatting, "why" explanations

## VALIDATION_CHECKLIST
- [ ] All public APIs documented (functions/classes/methods)
- [ ] Parameters, returns, exceptions described where applicable
- [ ] Examples added for complex functionality
- [ ] Business rules/constraints explained (why)
- [ ] No redundant/obvious comments added
- [ ] README includes Overview, Installation, Usage, API Reference, Contributing, License
- [ ] OpenAPI uses reusable `components`/`$ref` where appropriate
- [ ] CHANGELOG grouped by version/categorized
- [ ] Documentation matches actual code behavior
- [ ] Legible/concise/informative (active voice, <25 words/sentence, target audience)
- [ ] Accurate—no outdated info, working links
</rules>

<context>
## SCOPE
Create, improve, validate documentation across:
- Inline comments
- Docblocks/docstrings
- README/markdown files
- API documentation (OpenAPI/Swagger)
- CHANGELOGs

## WORKFLOW
1. **Analysis**: Read target files, identify missing/weak documentation
2. **Planning**: Choose format, outline structure
3. **Writing**: Produce rationale-first explanations, consistent formatting
4. **Validation**: Run checklist, verify accuracy

## REFERENCES (Progressive_Disclosure)
- `@references/api-documenter.md` — OpenAPI/Swagger spec generation
- `@references/changelog-generator.md` — CHANGELOG from git history
- `@references/docblock-writer.md` — Docblocks/docstrings + inline comments
- `@references/readme-writer.md` — README synthesis from codebase

Read reference when task maps to domain (e.g., "generate OpenAPI" -> `@references/api-documenter.md`)
</context>

<examples>
### Business_Rule (GDPR Compliance)
```python
# GDPR requires user data deletion within 30 days of account closure.
# Soft deletion maintains audit trails while complying with privacy regulations.
user.deleted_at = datetime.now()
```

### Security_Rationale
```python
# Hash passwords with bcrypt (not MD5) for computational hardness against brute-force attacks.
# MD5 is cryptographically broken and unsafe for password storage.
hashed_password = bcrypt.hash(password)
```

### Performance_Consideration
```python
def process_bulk_orders(orders, options=None):
    """
    Process multiple orders with optimized batch operations.

    Process in batches of 100 to balance memory usage with database performance.
    Individual processing would be too slow; all-at-once causes exhaustion.
    Batch size determined through testing.

    Args:
        orders (list): List of order dictionaries
        options (dict, optional): Processing options

    Returns:
        dict: Processing results with successful/failed counts

    Raises:
        BulkProcessingError: If >10% orders fail
    """
```
</examples>

<execution_protocol>
1. Load `@references/skills.md` for schema compliance
2. Clarify: Ask target audience, style preference, commit intent
3. Plan: Outline files, impacts, steps; get approval if impact > low
4. Execute: Read files, generate documentation, apply changes
5. Validate: Run checklist, self-correct if fails
6. Output: Summary of changes with file paths and line numbers
</execution_protocol>
