# Standardized Nudge Catalog & Communication Policy

Standardized steering message templates for prompting, waking, and guiding Google Jules cloud sessions.

---

## 1. Nudge Principles

1. **Be Concise and Direct**: Cloud agent runners process concise, directive instructions more reliably than conversational ambiguity.
2. **Contextual Clarity**: State the current state and what specific next step the agent should perform.
3. **Avoid Repeating the Entire Prompt**: Reference the approved plan or existing task rather than restating full requirements.

---

## 2. Standardized Templates

| Template Key | When to Use | Message Text |
|---|---|---|
| `plan_stalled` | Plan was approved, but runner has been silent or idle with no edits visible. | `"The plan was approved but no implementation progress is visible. Please proceed with implementation per the approved plan."` |
| `progress_check` | Runner is `IN_PROGRESS` or idle with no activity updates for $\ge 60$ minutes. | `"What is your progress? Please provide a status update on this task."` |
| `pr_reminder` | Work completed and verification passed, but runner stopped before opening a PR (`CLOSED_NO_PR`). | `"This session appears to have completed work. Please create a pull request with the changes or provide a status update."` |
| `stale_branch_halt` | Runner is stuck pushing empty commits or base branch moved out from under it. | `"Stop pushing. The remote branch has been updated since your session started. Your local environment is stale. Please stop all further push attempts."` |
| `custom` | Specific steering or addressing agent's technical questions. | Craft targeted message addressing the agent's explicit inquiry. |

---

## 3. Automated Nudging Guardrails

- **Maximum Nudge Frequency**: Do not send repeated nudges within a 15-minute window. Allow the cloud container sufficient time to cycle and respond.
- **Max Retries**: If a session remains stalled after 2 consecutive nudges spaced 30 minutes apart, mark the session as unrecoverable and alert the user.

