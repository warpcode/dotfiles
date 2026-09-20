## Jules Sessions Health & Status Audit

| Session ID | State | Assessment | Inactive | Title / Latest Activity | PR / Output |
|---|---|---|---|---|---|
| `SESSION_ID` | **STATE** | BADGE | XXm | **Task Title**<br>_Latest activity summary_ | [PR #XXX](PR_URL) |

### Actionable Items

#### Plans Awaiting Approval
- **Session `SESSION_ID`** (Task Title)
  - Plan ID: `PLAN_ID`
  - To approve: `python3 <skill-dir>/scripts/main.py approve-plan SESSION_ID PLAN_ID`

#### Sessions Awaiting User Guidance
- **Session `SESSION_ID`** (Task Title)
  - Latest: Inquiry text...
  - To respond: `python3 <skill-dir>/scripts/main.py send-message SESSION_ID "<feedback>"`

#### Stalled / Silent Sessions
- **Session `SESSION_ID`** (Task Title) — Inactive for XXm
  - Last event: `type`: detail...
  - To nudge: `python3 <skill-dir>/scripts/main.py send-message SESSION_ID "What is your progress?"`
