---
description: >-
  IMMEDIATE COMMAND: Execute these steps right now to commit your current changes. This is not a reference document - it is an active procedure to follow immediately for high-quality, intentional commits.
---

# Commit Command - Execute Immediately

**IMMEDIATE ACTION REQUIRED:** This is a command to execute right now. Do not treat this as documentation - follow these steps immediately to commit your current changes. This ensures high-quality, intentional commits through immediate review, message generation, and approval.

## Key Principles - Execute Immediately

- **IMMEDIATELY** review your changes before committing.
- **RIGHT NOW** use AI assistance for commit message generation when available.
- **DO NOT** commit without explicit approval or verification.
- **FOCUS ONLY** on staged changes unless intentionally committing unstaged ones.
- **RESPECT** repository state and avoid unintended modifications.

## Commit Command Steps - Execute Now

### 1. Determine the Scope of Your Current Changes - Do This Now

**IMMEDIATELY** assess what changes are ready to be committed:

- **RUN NOW:** `git diff --staged` to check for staged changes.
- **IF NEEDED:** Stage the necessary files first using `git add`.
- **REVIEW NOW:** The list of staged files and summarize the types of changes (additions, modifications, deletions).
- **VERIFY NOW:** If committing specific files, ensure they are properly staged.

### 2. Generate an Appropriate Commit Message - Do This Now

**IMMEDIATELY** create a descriptive commit message following project conventions:

- **USE NOW:** The commit-message-writer agent (if available) to generate a commit message based on your staged changes.
- **PROVIDE NOW:** The agent with: the list of staged files, git diff output, project technology stack, and any commit message style guidelines.
- **ENSURE NOW:** The generated message follows conventional commit standards and project-specific conventions.
- **IF NEEDED:** Manually craft a clear, descriptive message if AI generation is not available or suitable.

### 3. Review Changes and Obtain Approval - Do This Now

**IMMEDIATELY** perform a final verification before committing:

- **DISPLAY NOW:** And review the generated or crafted commit message.
- **SUMMARIZE NOW:** Your staged changes, including affected files and change types.
- **OBTAIN NOW:** Explicit approval from yourself or team members before proceeding.
- **CONFIRM NOW:** Approval through the tool's interface if using an AI assistant.
- **IF NOT APPROVED:** Do not commit and consider revising the changes or message.

### 4. Execute the Commit - Do This Now

**ONCE APPROVED** and all checks are complete:

- **RUN NOW:** `git commit -m "your commit message"` with the approved message.
- **FOLLOW NOW:** The AI tool's commit execution process after approval if using one.
- **AVOID** automatic commits; always perform this step manually after verification.

### 5. Handle Special Cases - Be Prepared Now

**IMMEDIATELY** be prepared for edge cases in the current commit process:

- **IF MESSAGE GENERATION FAILS:** Manually create an appropriate message right away.
- **FOR DRY-RUNS:** Preview changes and messages without committing (e.g., using `git diff --staged` and message drafts).
- **FOR SPECIFIC FILES:** Ensure only intended files are staged immediately.
- **RESPECT NOW:** Any project-specific flags or workflows (e.g., pre-commit hooks, CI checks).

## Rationale - Why Execute This Command Now

**EXECUTING THIS COMMAND NOW** ensures you maintain high standards in version control:

- **Quality Assurance**: Thorough review prevents poor commits and maintains repository quality.
- **Intentionality**: Manual steps encourage thoughtful consideration of changes.
- **Consistency**: Standardized message generation promotes uniform commit practices.
- **Safety**: Approval requirements prevent accidental or unintended commits.
- **Collaboration**: Clear processes support team workflows and code reviews.

This approach balances efficiency with careful oversight, leading to better version control hygiene and project maintainability.

## Workflow Examples - Execute These Patterns Now

**EXECUTE THESE EXAMPLES NOW** to apply this procedure:

- **Standard Commit**: Stage changes, review with `git diff --staged`, generate message with AI, approve, then commit.
- **Specific File Commit**: Stage only desired files, verify staging, generate targeted message, review, commit.
- **Dry Run Review**: Check staged changes and draft messages without committing to ensure readiness.
- **Manual Override**: If AI message is inadequate, manually write a clear message following guidelines.
- **Status Check**: Regularly review staged changes to maintain awareness of repository state.