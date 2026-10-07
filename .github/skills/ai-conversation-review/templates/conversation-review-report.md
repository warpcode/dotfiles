# Conversation Review Report Template

Use this canonical template when generating review findings from a human-AI conversation. Reports must remain compact and strictly focused on actionable metrics, script candidates, guideline violations, suggestions/advice, and concrete improvement diffs.

---

```markdown
# AI Conversation Review

## 1. Metrics
- **Reviewed session:** {{TOOL_CALLS}} tool invocations; {{FAILED_CALLS}} failures.
- **Offload analysis:** {{OFFLOADABLE_SHARE}}% offloadable; projected {{PROJECTED_CALLS}} calls after scripting. Mechanical chains: {{CHAINS}} ({{CALLS_IN_CHAINS}} calls); repeated sequences: {{REPEATED_SEQS}}; retry loops: {{RETRIES}}.
- **Review data-gathering budget:** {{GATHERING_CALLS_USED}} tool calls used (budget: <= 3).
- **History baseline:** {{HISTORY_DELTA_SUMMARY}}

## 2. Script Candidates
| Sequence | Occurrences | Calls Saved | Class | Suggested Script | Target Skill / Repo |
| --- | ---: | ---: | --- | --- | --- |
| `{{TOOL_SEQUENCE}}` | {{COUNT}} | {{SAVED}} | **{{CLASS}}** | `{{SCRIPT_NAME}}` | `{{TARGET_SKILL}}` |

## 3. Guideline Violations
- **{{RULE_OR_SAFETY_CONSTRAINT}}**: {{VIOLATION_DESCRIPTION}}. **Evidence:** Turn {{TURN_NUM}} (Event #{{EVENT_NUM}}). **Diagnosis:** {{ROOT_CAUSE_DIAGNOSIS}}.

## 4. Suggestions / Advice
- **{{[High|Medium|Low]}}**: {{SUGGESTION_OR_ADVICE_STATEMENT}}. **Evidence:** Turn {{TURN_NUM}}.

## 5. Improvements
### `{{TARGET_FILE_PATH}}`
```diff
{{DIFF_BLOCK}}
```
```
