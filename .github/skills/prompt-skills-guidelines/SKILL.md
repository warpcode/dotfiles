---
name: prompt-skills-guidelines
description: Standards and procedures for engineering skills, scripts, and agentic workflows optimized for the Gemini CLI and LLM consumption. Use this skill whenever you are tasked with creating a new skill, optimizing existing tool outputs, or designing agent-to-agent communication protocols. It mandates token-efficient scripting (the --raw pattern) and strictly neutral, non-paraphrasing behavioral standards.
---

# Prompt & Skill Engineering

Design and implement modular capabilities optimized for high-performance, cost-effective agentic interaction.

## 🚀 Token-Efficient Subagent Scripting

When drafting shell scripts or tools intended primarily for AI consumption, prioritize output density to minimize token overhead and latency.

### 1. Default Compression
- **High-Signal Output**: Default to providing a token-efficient Markdown summary. Extract only the essential metadata required for the agent's next logical step to minimize context usage.
- **Example**: PR #123 (Open) - "Fix bug".
- **Large Data Truncation**: Truncate verbose bodies or logs in the default output.

### 2. The `--raw` Pattern
- **Bypass Flag**: Always implement a `--raw` (or `--raw-output`) flag. 
- **AI Constraint**: Agents MUST prioritize the default summary. The `--raw` flag is reserved for debugging, manual inspection, or piping to other tools; it MUST NOT be used by AI agents during standard orchestration phases unless specifically requested.
- **Implementation Standard**:
  ```bash
  # Check for raw flag
  RAW_OUTPUT=false
  for arg in "$@"; do
    [[ "$arg" == "--raw" ]] && RAW_OUTPUT=true
  done

  # Branch output based on flag
  if [[ "$RAW_OUTPUT" == "true" ]]; then
      echo "$RESPONSE"
  else
      # Token-efficient Markdown summary (Default)
      echo "$RESPONSE" | jq -r '...summary logic...'
  fi
  ```

## 🧠 Behavioral Standards

All skills and automated workflows in this workspace must adhere to the following mandates:

### 1. Strictly Neutral Tone
- **Formal Only**: Prohibit all conversational filler, encouraging remarks, or unnecessary affirmations (e.g., "LGTM", "I am happy to help").
- **Direct Feedback**: Focus exclusively on technical findings. Use the mandatory structure for reviews: **Severity**, **Description**, **Impact**, and **Proposed Solution**.

### 2. No Paraphrasing
- **Zero Summary**: Do not paraphrase user tasks or summarize work already visible in the conversation or PR.
- **Focus on Delta**: Address only what is wrong or what needs to change.

### 3. State & Symlink Safety
- **Verification**: Always verify the disk state before and after mutation.
- **Symlink Protection**: Strictly verify target paths before performing bulk deletions (`rm -rf`). Never delete contents through a symlink; only remove the link itself if replacement is required.

## 🛠️ Tooling Consistency

### 1. Template Management
All skills that generate structured written content (e.g., review comments, issue bodies, report summaries) must externalize these structures into templates.
- **Directory**: Store templates in a `templates/` subdirectory within the skill folder.
- **Separation**: Appropriately separate templates by their specific context or target platform (e.g., `templates/github/review_comment.md`, `templates/jira/issue_body.txt`).
- **Discovery**: Ensure scripts and prompts reference these templates directly, allowing for easy updates to the output format without modifying code.

### 2. UI Stability
- **Sequencing**: Never call `update_topic` and `ask_user` in the same conversational turn. Always call `update_topic` first to set the progress context, then issue `ask_user` in a separate turn to ensure the interactive menu renders correctly.
