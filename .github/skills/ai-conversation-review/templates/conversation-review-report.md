# Conversation Review Report Template

Use this canonical template when generating review findings from a human-AI conversation. Reports must remain compact and strictly focused on actionable suggestions, advice, and improvements.

---

```markdown
# AI Conversation Review

## 1. Suggestions
*(Workflow and tooling recommendations, such as automating common procedures and command chains into scripts to eliminate tool sprawl and save tokens, batching, simpler commands, or alternative tools)*
- **{{TOPIC}}**: {{CONCISE_SUGGESTION}}

## 2. Advice
*(Actionable behavioral guidance, habits, or procedural adjustments)*
- **{{TOPIC}}**: {{CONCISE_ADVICE}}

## 3. Improvements
*(Concrete diffs or changes for skills, rules, or instructions)*

### `{{TARGET_FILE_OR_SKILL}}`
```diff
{{DIFF_OR_CODE_BLOCK}}
```
```
