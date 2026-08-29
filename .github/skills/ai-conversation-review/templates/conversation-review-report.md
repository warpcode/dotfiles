# Conversation Review Report Template

Use this canonical template when generating review findings from a human-AI conversation.

---

```markdown
# AI Conversation Review Report

- **Input Source**: `{{SOURCE_DESCRIPTION}}` (e.g. `inline session`, `transcript.jsonl`, or export file)
- **Session Focus**: `{{PRIMARY_TASK_OR_GOAL}}`
- **Reviewed Artifacts**: `{{LIST_OF_SKILLS_PROMPTS_OR_INSTRUCTION_FILES_REVIEWED}}`

---

## 1. Durable Memory Updates (`~/.agents/AGENTS.md`)

### Additions
- **[{{CATEGORY}}]** {{FACT_DESCRIPTION}}
  - *Rationale / Evidence*: {{REASON_OR_EVIDENCE_FROM_CONVERSATION}}

### Updates & Enrichments
- **[{{CATEGORY}}]** {{ENRICHED_FACT_DESCRIPTION}}
  - *Replaces*: "{{EXACT_TEXT_OF_PREVIOUS_ENTRY}}"
  - *Rationale*: {{WHY_THIS_UPDATE_IS_NEEDED}}

### Stale Removals
- "{{EXACT_TEXT_OF_STALE_OR_INVALIDATED_ENTRY}}"
  - *Reason*: {{WHY_THIS_ENTRY_IS_NO_LONGER_APPLICABLE}}

---

## 2. Workspace & Global Instruction Alignment

### Files Audited
- Located: `{{LIST_OF_FOUND_FILES}}`
- Missing / Absent: `{{LIST_OF_MISSING_FILES}}`

### Instruction Gaps & Corrections

#### [{{ACTION: UPDATE | CREATE_RULE}}] - `{{TARGET_FILE_PATH}}`
- **Section / Target Area**: `{{TARGET_SECTION}}`
- **Identified Gap / Ambiguity**: `{{EXPLANATION_OF_WHAT_FAILED_OR_WAS_AMBIGUOUS}}`
- **Proposed Content / Diff**:
  ```markdown
  {{EXACT_MARKDOWN_BLOCK_OR_DIFF_TO_APPLY}}
  ```

---

## 3. Skill & Prompt Optimizations

### Audited Skills & Prompt Workflows

#### [{{SKILL_OR_PROMPT_NAME}}] (`{{ACTION: REFACTOR | MERGE | BREAK_UP | REFINE_TRIGGER | NEW_SKILL}}`)
- **Location**: `{{FILE_PATH}}`
- **Evaluation Finding**: {{SUMMARY_OF_ISSUE_E_G_UNDERTRIGGERING_PROMPT_MICROMANAGEMENT_OR_BLOAT}}
- **Proposed Fix / Optimization**:
  ```markdown
  {{UPDATED_FRONTMATTER_OR_REFACTORED_PROMPT_BODY}}
  ```

---

## 4. Terminal Command Consolidation & Scripts

### Candidate Shell Sequences Identified

#### [{{SCRIPT_NAME}}] (`{{TARGET_PATH}}`)
- **Observed Command Pattern**: `{{ONE_LINER_OR_FLAKY_SEQUENCE_USED_IN_SESSION}}`
- **Problem with Ad-Hoc Execution**: {{WHY_THE_LLM_STRUGGLED_OR_GUESSED}}
- **Synthesized Script Content**:
  ```bash
  {{COMPLETE_REUSABLE_SCRIPT_SOURCE_CODE}}
  ```
- **Usage for AI Agent in `SKILL.md`**:
  ```bash
  {{INVOCATION_EXAMPLE}}
  ```

---

## 5. Compliance & Guardrails Audit

### Guardrails Checked
- **{{GUARDRAIL_OR_RULE_NAME}}**: {{STATUS: FULLY_ADHERED | PARTIALLY_ADHERED | VIOLATED}}
  - *Observation*: {{FACTUAL_EVIDENCE_FROM_TRANSCRIPT}}
  - *Root Cause Analysis*: {{IF_VIOLATED_WHY_DID_THE_AGENT_DEVIATE}}
  - *Preventative Fix*: {{RULE_OR_HOOK_PROPOSED_TO_PREVENT_RECURRENCE}}
```
