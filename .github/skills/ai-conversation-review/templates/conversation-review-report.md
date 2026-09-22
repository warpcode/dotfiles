# Conversation Review Report Template

Use this canonical template when generating review findings from a human-AI conversation. Reports must remain lean and strictly issue-focused—documenting problems found, root causes, and concrete fixes/diffs, without congratulatory fluff or summaries of what worked well.

---

```markdown
# AI Conversation Review Report

- **Input Source**: `{{SOURCE_DESCRIPTION}}` (e.g. `inline session`, `transcript.jsonl`, export file)
- **Session Focus**: `{{PRIMARY_TASK_OR_GOAL}}`
- **Scope**: `{{PROJECT_SPECIFIC | GLOBAL}}` (Repo: `{{REPO_NAME}}` / Global Dotfiles)

---

## 1. Skill & Workflow Trigger Issues
*(Audit skills that failed, were misused, or SHOULD have been loaded but were not)*

### Missed Skills (Should have loaded, but didn't)
- **Skill**: `{{SKILL_NAME}}` (`{{SKILL_PATH}}`)
- **Observed Behavior**: {{TASK_THE_AGENT_TRIED_TO_SOLVE_MANUALLY_INSTEAD_OF_USING_SKILL}}
- **Root Cause**: {{WHY_SKILL_DID_NOT_TRIGGER_E_G_FRONTMATTER_DESCRIPTION_MISSING_KEYWORDS_OR_USER_PHRASES}}
- **Proposed Fix (Trigger / Description Update)**:
  ```yaml
  description: >
    {{IMPROVED_FRONTMATTER_DESCRIPTION_WITH_EXPLICIT_TRIGGERS}}
  ```

### Audited Skill Gaps & Workflow Inefficiencies
- **Skill / Workflow**: `{{NAME}}` (`{{FILE_PATH}}`)
- **Issue Found**: {{E_G_MISSING_SUBCOMMAND_UNHANDLED_EDGE_CASE_OR_OVERTRIGGERING}}
- **Proposed Optimization**:
  ```markdown
  {{CONCRETE_FIX_OR_DIFF}}
  ```

---

## 2. Tool & Command Usage Inefficiencies
*(Audit all commands executed: flag complex inline scripts, multi-pipe bash, trial-and-error, and wasted context)*

### Flagged Command Complexity & Anti-Patterns
- **Observed Command**:
  ```bash
  {{OFFENDING_INLINE_PYTHON_OR_COMPLEX_MULTI_PIPE_BASH}}
  ```
- **Complexity Smell**: `{{INLINE_PYTHON | COMPLEX_BASH_PIPELINE | BRITTLE_REGEX | WASTED_CONTEXT_DUMP}}`
- **Problem**: {{WHY_THIS_IS_HARD_TO_REVIEW_FRAGILE_OR_TOKEN_INEFFICIENT}}
- **Enforced Simpler Command or Wrapper**:
  ```bash
  {{SIMPLER_COMMAND_OR_SKILL_SCRIPT_INVOCATION}}
  ```

### Command Pattern & Reusable Skill Script Proposal
*(Consolidating recurring patterns or multi-turn trial-and-error into a deterministic skill script)*

- **Target Skill**: `{{TARGET_SKILL_NAME}}`
- **Script Location**: `{{TARGET_SKILL_DIR}}/scripts/{{SCRIPT_FILENAME}}`
- **Consolidated Pattern**: {{WHAT_MULTI_TURN_OR_COMPLEX_OPERATION_THIS_REPLACES}}
- **Synthesized Script Source**:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  {{COMPLETE_REUSABLE_SCRIPT_SOURCE}}
  ```
- **Documented Usage in `SKILL.md`**:
  ```markdown
  {{CLI_INVOCATION_EXAMPLE_WITH_HELP_AND_FLAGS}}
  ```

---

## 3. Downstream Updates (Scope & Specificity Directed)
*(Mandatory concrete diffs targeting the most specific artifact first)*

### Project-Specific Updates (Repo: `{{REPO_NAME}}`)
- **Target Artifact**: `{{SKILL | WORKFLOW | SUBAGENT | PATH_RULE | REPO_AGENTS_MD}}` - `{{FILE_PATH}}`
- **Issue Resolved**: {{WHAT_INEFFICIENCY_OR_GAP_THIS_FIXES}}
- **Concrete Diff / Content**:
  ```markdown
  {{EXACT_DIFF_OR_CODE_BLOCK}}
  ```

### Global Updates (Dotfiles / Universal Conventions)
*(ONLY if the change is a general global behavior)*
- **Target Artifact**: `{{GLOBAL_SKILL | GLOBAL_AGENT | GLOBAL_INSTRUCTION | GLOBAL_AGENTS_MD}}` - `{{FILE_PATH}}`
- **Rationale for Global Scope**: {{WHY_THIS_APPLIES_ACROSS_ALL_WORKSPACES}}
- **Concrete Diff / Content**:
  ```markdown
  {{EXACT_DIFF_OR_CODE_BLOCK}}
  ```

---

## 4. Compliance & Guardrails Deviations
*(Report strictly on violations, near-misses, or missing negative constraints)*

- **Guardrail / Rule**: `{{RULE_NAME}}`
- **Deviation / Near-Miss**: {{EXACT_OBSERVED_ACTION_IN_TRANSCRIPT}}
- **Root Cause**: {{WHY_THE_AGENT_DEVIATED}}
- **Preventative Rule / Guardrail Fix**:
  ```markdown
  {{EXACT_NEGATIVE_CONSTRAINT_TO_ADD}}
  ```
```
