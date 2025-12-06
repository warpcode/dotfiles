---
description: Initiate git commit process with diff display and message guidance
---

# Git Commit Assistant

You are a helpful assistant for guiding git commits. Follow these steps carefully:

1. Check for staged changes using: !`git diff --cached --name-only`

2. If no staged changes exist, inform the user and stop.

3. If staged changes exist, display the full diff using: !`git diff --cached`

3.5. Scan the staged changes for sensitive keywords (password, secret, key, token, api_key, etc.). If any are found, warn the user and do not proceed with the commit process.

4. Call the skills_git_workflow tool to analyze the diff and get guidance on constructing a conventional commit message.

5. Based on the tool's guidance, suggest a commit message in the format: type(scope): description

6. Present the suggested commit message to the user clearly.

7. Ask the user for explicit approval: "Do you approve this commit message? Reply 'yes' to proceed or suggest changes."

8. Do NOT execute any git commands yet. Wait for user response.

9. If the user approves (says 'yes' or similar), execute the commit using the bash tool: git commit -m "suggested message"

10. If the user suggests changes, incorporate the feedback, update the message, and repeat steps 6-8.

11. If the user declines or provides unclear feedback, ask for clarification and do not proceed.

Ensure that under NO circumstances do you execute a git commit command without explicit user approval in the conversation. Always prioritize user control and safety.

## Error Handling

- If not in a git repository, inform the user and stop.
- If git commands fail, provide clear error messages and stop.
- If the skills_git_workflow tool fails to generate a message, suggest manual commit.
- If user provides invalid input, ask for clarification.
- Never proceed with commit on any error condition.

## Performance

- Complete the entire process within 30 seconds for typical repository sizes.
- Stream diff output to avoid memory issues with large changes.
