---
description: >-
  This procedure outlines the immediate steps to follow now before committing your current changes. It ensures high-quality, intentional commits by reviewing staged changes, generating appropriate commit messages, and obtaining approval before proceeding.
---

# Commit Procedure

This procedure outlines the essential steps to perform now before committing your current changes to a git repository. Follow these steps to promote code quality, repository hygiene, and intentional version control practices.

## Key Principles

- Review your changes now before committing.
- Use AI assistance for commit message generation when available.
- Do not commit without explicit approval or verification.
- Focus only on staged changes unless intentionally committing unstaged ones.
- Respect repository state and avoid unintended modifications.

## Commit Procedure Steps

### 1. Determine the Scope of Your Current Changes

Now, assess what changes are ready to be committed:

- Run `git diff --staged` to check for staged changes.
- If no staged changes exist, stage the necessary files first using `git add`.
- Review the list of staged files and summarize the types of changes (additions, modifications, deletions).
- If committing specific files, verify they are properly staged.

### 2. Generate an Appropriate Commit Message

Now, create a descriptive commit message following project conventions:

- Use the commit-message-writer agent (if available) to generate a commit message based on your staged changes.
- Provide the agent with: the list of staged files, git diff output, project technology stack, and any commit message style guidelines.
- Ensure the generated message follows conventional commit standards and project-specific conventions.
- If AI generation is not available or suitable, manually craft a clear, descriptive message.

### 3. Review Changes and Obtain Approval

Now, perform a final verification before committing:

- Display and review the generated or crafted commit message.
- Summarize your staged changes, including affected files and change types.
- Obtain explicit approval from yourself or team members before proceeding.
- If using an AI assistant, confirm approval through the tool's interface.
- If approval is not granted, do not commit and consider revising the changes or message.

### 4. Execute the Commit

Once all checks are complete and approval is obtained:

- Run `git commit -m "your commit message"` with the approved message.
- If using an AI tool, follow its commit execution process after approval.
- Avoid automatic commits; always perform this step manually after verification.

### 5. Handle Special Cases

Be prepared for edge cases in the current commit process:

- If the commit message generation fails or produces unsuitable results, manually create an appropriate message.
- For dry-run scenarios, preview changes and messages without committing (e.g., using `git diff --staged` and message drafts).
- If committing specific files, ensure only intended files are staged.
- Respect any project-specific flags or workflows (e.g., pre-commit hooks, CI checks).

## Rationale

Following this procedure now ensures you maintain high standards in version control:

- **Quality Assurance**: Thorough review prevents poor commits and maintains repository quality.
- **Intentionality**: Manual steps encourage thoughtful consideration of changes.
- **Consistency**: Standardized message generation promotes uniform commit practices.
- **Safety**: Approval requirements prevent accidental or unintended commits.
- **Collaboration**: Clear processes support team workflows and code reviews.

This approach balances efficiency with careful oversight, leading to better version control hygiene and project maintainability.

## Workflow Examples

These examples illustrate how to apply this procedure now:

- **Standard Commit**: Stage changes, review with `git diff --staged`, generate message with AI, approve, then commit.
- **Specific File Commit**: Stage only desired files, verify staging, generate targeted message, review, commit.
- **Dry Run Review**: Check staged changes and draft messages without committing to ensure readiness.
- **Manual Override**: If AI message is inadequate, manually write a clear message following guidelines.
- **Status Check**: Regularly review staged changes to maintain awareness of repository state.