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
| `stale_branch_halt` | Runner is stuck pushing empty commits or base branch moved out from under it — **only if not already wedged**. | `"Stop pushing. The remote branch has been updated since your session started. Your local environment is stale. Please stop all further push attempts."` |
| `custom` | Specific steering or addressing agent's technical questions. | Craft targeted message addressing the agent's explicit inquiry. |

---

## 3. Automated Nudging Guardrails

- **Maximum Nudge Frequency**: Do not send repeated nudges within a 15-minute window. Allow the cloud container sufficient time to cycle and respond.
- **Max Retries**: If a session remains stalled after 2 consecutive nudges spaced 30 minutes apart, mark the session as unrecoverable and alert the user.

---

## 3.1 Anti-Pattern: Nudging a Wedged Session

**Count the empty commits before sending any nudge.** If two or more commits above the merge base
introduce no file changes, the session is wedged and is in **Workflow 6** territory, not nudge
territory.

Observed on warpcode/cloakenv#210: session `7376406477938977770` had already pushed one empty commit.
A halt nudge was sent; the runner responded by pushing another empty commit. This repeated four
times. None of the six open review findings were ever addressed, and the branch became permanently
unmergeable because the `Reject empty commit` gate cannot be satisfied by appending commits.

**Rule:** nudges are for a *stalled but potentially healthy* session — one that is silent,
blocked, or awaiting guidance. They are actively harmful for a session in an empty-commit loop,
because the nudge resets the runner's work timer and triggers another push attempt. Escalate to
Workflow 6 instead.

