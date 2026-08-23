---
name: <capability>-meta
description: >
  Authors/optimizes agent skills from developer conversations. Use when
  creating or refining SKILL.md files.
---

# Meta / self-improving template

Use for skills that author, audit, or optimize other skills.
Check existing coverage first — no duplicates.

### Objective
Convert repeated procedures and developer corrections into reusable skills.

### Improvement Loop

#### Step 1: Ingest
1. Scan the transcript for repeated procedures/corrections/tool issues.
2. Isolate the reusable core pattern from conversation-specific state.

#### Step 2: Scaffold
1. Generate valid frontmatter (folder name == `name`; trigger-rich description).
2. Write the body in third-person imperative using the closest category template.
3. Append Gotchas capturing the exact error/correction that triggered creation
   (the triggering error is the highest-value debugging context).

### What NOT to Do
- No duplicate/overlapping skills — grep repo + `~/.agents/skills/` first.
- No essays; frame everything as executable workflows.

### Validation Gate
- Run the ai-authoring-skills validation workflow on the new skill.
