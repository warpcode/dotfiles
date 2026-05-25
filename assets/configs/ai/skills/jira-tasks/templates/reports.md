# Jira Report Templates

## 1. Developer Deep-Dive Report
**Goal**: Detailed view of a developer's focus, handover, and impediments.
**Reference**: Section 4.F in `SKILL.md`.

### Template
# Developer Report: [DEVELOPER_NAME] ([PROJECT_KEY] Project)
**Date:** [CURRENT_DATE]

## Executive Summary
[Brief 2-3 sentence overview of workload, primary focus, and major impediments.]

---

## 2. Active Focus (In Progress)
[Table or List of active tickets in In Progress/QA/UAT]
| Key | Summary | Status | Time in Status | Rework |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [STATUS] | [DURATION] | [REWORK_COUNT] |

**Insights:**
* [Bullet points on specific progress or complexity]

---

## 3. Handover & Verification (Passive In Progress)
[Tickets in states like ready for peer review/QA/UAT]
| Key | Summary | Status | Time in Status |
| :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [STATUS] | [DURATION] |

---

## 4. Impediments & Blockers
[Tickets in 'Blocked', or 'On Hold' statuses]
| Key | Summary | Status | Time in Status | Rework |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [STATUS] | [DURATION] | [REWORK_COUNT] |

**Status Analysis:**
* [Explanation of why it is blocked/parked and what is needed to move forward]

---

## 5. Backlog & Age (To Do)
[Issues in To Do category assigned to the developer]

---

## 6. Delivery Metrics
* **Total Workload:** [COUNT] Issues
* **Active Development:** [COUNT] Issues
* **Handover/Verification:** [COUNT] Issues
* **Impediments:** [COUNT] Issues

---

## 7. Developer Daily Report
**Goal**: Summary of activity for a specific day ("Yesterday").

### Template
# Developer Daily Report: [DEVELOPER_NAME] ([PROJECT_KEY] Project)
**Reporting Date:** [REPORT_DATE]
**Current Date:** [CURRENT_DATE]

## Summary of Activity
[Concise summary of what was achieved on the reporting date.]

---

## 1. Progress & Handovers
### [KEY]: [SUMMARY]
* **Status Change:** [OLD_STATUS] → [NEW_STATUS]
* **Activity Details:**
    * [Details of transitions, comments, or demos conducted]
    * **Handover:** [Who was it handed over to, if anyone]

---

## 2. Key Contributions & Documentation
* [Note any PRs, Wiki updates, or technical documentation authored]

---

## 3. Plan for Today ([CURRENT_DATE])
* [Based on yesterday's progress, what is next?]

---

## Delivery Pulse
* **Issues Resolved/Moved:** [COUNT]
* **Bottlenecks:** [None or description]

---

## 8. Epic Overview Report
**Goal**: High-level status and health of a large initiative (Epic).
**Reference**: Section 4.D in `SKILL.md`.

### Template
# Epic Overview: [EPIC_KEY] - [EPIC_SUMMARY]
**Date:** [CURRENT_DATE]
**Status:** [STATUS]
**Owner/Lead:** [ASSIGNEE]

## Executive Summary
[1-2 sentences summarizing the goal of the Epic and its current health.]

## Health & Progress
* **Overall Completion:** [X]% ([DONE_CHILDREN] / [TOTAL_CHILDREN] issues completed)
* **Estimated Velocity/Lead Time:** [AVERAGE_LEAD_TIME_OF_COMPLETED]

---

## 1. Impediments & Blocked Work
[List of child issues currently blocked or parked]
| Key | Summary | Assignee | Status | Days Blocked |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [ASSIGNEE] | [STATUS] | [DURATION] |

---

## 2. Active Development (In Progress)
[List of child issues currently being worked on]
| Key | Summary | Assignee | Status | Rework |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [ASSIGNEE] | [STATUS] | [REWORK_COUNT] |

---

## 3. Handover & Verification
[List of child issues in QA, Review, or UAT]
| Key | Summary | Assignee | Status | Time in Status |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [ASSIGNEE] | [STATUS] | [DURATION] |

---

## 9. Morning Standup Report
**Goal**: Daily team synchronization, highlighting blockers, recent wins, and active priorities.

### Template
# Team Standup: [PROJECT/TEAM_NAME]
**Date:** [CURRENT_DATE]

## 🚨 Active Blockers (Need Assistance)
[Issues currently in 'Blocked' status or explicitly called out as impeding progress]
* **[KEY]** - [SUMMARY] ([ASSIGNEE]) - *Blocked for [DURATION]*.
  * *Reason:* [Latest comment or reason for block]

---

## ✅ Completed Yesterday
[Issues transitioned to 'Done' in the last 24 hours]
* **[KEY]** - [SUMMARY] ([ASSIGNEE])

---

## 🏃 In Flight (Active Focus)
[Grouped by Assignee, the primary tickets they are working on today]
* **[DEVELOPER_1]:** [KEY] - [SUMMARY] ([STATUS])
* **[DEVELOPER_2]:** [KEY] - [SUMMARY] ([STATUS])

---

## 👀 Verification Needed
[Tickets sitting in Peer Review or QA waiting for eyes]
* **[KEY]** - [SUMMARY] ([STATUS]) - *Waiting for [DURATION]*
