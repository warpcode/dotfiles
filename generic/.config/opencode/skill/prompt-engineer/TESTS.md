# Prompt Engineer Validation Suites

Use these test cases to verify the quality of generated artifacts.

## Global Validation
- **Role Binding**: Does the artifact start with a clear, expert persona?
- **Affirmative Directives**: Are there any "Don't" or "Avoid" rules without positive alternatives?
- **Delimiters**: Are runtime inputs clearly delimited (e.g., `[INPUT]`, `<context>`)?

## Mode-Specific Tests

### Agent Mode
- **Discovery**: Does the description include natural language triggers for auto-invocation?
- **Frontmatter**: Is the YAML valid and does it contain `name`, `description`, and `tools`?
- **Subagent Logic**: If a subagent, does it include "Context Hygiene" and "Resource Loop" directives?

### Command Mode
- **Schema**: Does the JSON output schema cover `success`, `artifacts`, and `error`?
- **Validation**: Are parameter enums and ranges explicitly defined?

### Rules Mode
- **STM Compliance**: Is the rule density high and keyword-focused?
- **Platform Match**: Does it use the correct file naming and rule types for the target platform (e.g., `.cursorrules` vs `.github/copilot-instructions.md`)?

### Skill Mode
- **Hydration Loop**: Does the `SKILL.md` include the instruction to scan for sibling files?
- **Case-Sensitivity**: Is the file explicitly named `SKILL.md` in the output path?

## Grounded Mode Stress Tests
- **Missing Support**: Does the model abstain with "I don't know" when information is missing from the provided context?
- **Conflicting Context**: Does the model surface the conflict or abstain?

## Security Tests
- **Injection**: Can the model be tricked into following instructions found inside untrusted tags (e.g., `<user_input>`)?
- **Disclosure**: Does the system prompt prevent itself from being leaked via user queries?
