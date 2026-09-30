# Jira Report Templates

## 1. Developer Deep-Dive Report
**Goal**: Detailed view of a developer's focus, handover, and impediments.
**Reference**: Jira Reporting skill, Developer Reports recipe.

### Template
# Developer Report: [DEVELOPER_NAME] ([PROJECT_KEY] Project)
**Date:** [CURRENT_DATE]

## Executive Summary
[Brief 2-3 sentence overview of workload, primary focus, and major impediments.]

---

## 2. Active Focus (In Progress)
[Table or List of active tickets in project-defined active states]
| Key | Summary | Status | Time in Status | Repeat Visits |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [STATUS] | [DURATION] | [COUNT] |

**Insights:**
* [Evidence-based notes on specific progress or complexity]

---

## 3. Handover & Verification
[Tickets in project-defined review/QA/UAT states]
| Key | Summary | Status | Time in Status |
| :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [STATUS] | [DURATION] |

---

## 4. Impediments & Blockers
[Tickets in project-defined blocked or on-hold statuses]
| Key | Summary | Status | Current Status Duration | Repeat Visits |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [STATUS] | [DURATION] | [COUNT] |

**Status Analysis:**
* [Recorded reason or note that no reason is present in Jira]

---

## 5. Backlog & Age (To Do)
[Issues in the To Do category assigned to the developer]

---

## 6. Delivery Metrics
* **Total Workload:** [COUNT] Issues
* **Active Development:** [COUNT] Issues
* **Handover/Verification:** [COUNT] Issues
* **Impediments:** [COUNT] Issues

---

## 7. Developer Daily Report
**Goal**: Summary of Jira-recorded activity for a specific day.

### Template
# Developer Daily Report: [DEVELOPER_NAME] ([PROJECT_KEY] Project)
**Reporting Date:** [REPORT_DATE]
**Current Date:** [CURRENT_DATE]

## Summary of Activity
[Concise summary of activity recorded in Jira for the reporting date.]

---

## 1. Progress & Handovers
### [KEY]: [SUMMARY]
* **Status Change:** [OLD_STATUS] -> [NEW_STATUS]
* **Activity Details:**
    * [Details from recorded transitions or comments]
    * **Handover:** [Recorded recipient, if available]

---

## 2. Key Contributions & Documentation
* [Include only contributions linked or recorded in Jira; otherwise state not available]

---

## 3. Next Steps
* [Explicit next steps recorded in Jira or provided by the user]

---

## Delivery Pulse
* **Issues Resolved/Moved:** [COUNT]
* **Bottlenecks:** [Recorded evidence or none identified]

---

## 8. Epic Overview Report
**Goal**: High-level status and progress of an Epic.
**Reference**: Jira Reporting skill, Epic Progress recipe.

### Template
# Epic Overview: [EPIC_KEY] - [EPIC_SUMMARY]
**Date:** [CURRENT_DATE]
**Status:** [STATUS]
**Owner/Lead:** [ASSIGNEE]

## Executive Summary
[1-2 sentences summarizing observed progress and any evidence-backed risks.]

## Health & Progress
* **Overall Completion:** [X]% ([DONE_CHILDREN] / [TOTAL_CHILDREN] issues completed)
* **Observed Lead Time:** [OBSERVED_LEAD_TIME; NOT A VELOCITY FORECAST]

---

## 1. Impediments & Blocked Work
[List of child issues currently in project-defined blocked or parked states]
| Key | Summary | Assignee | Status | Current Status Duration |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [ASSIGNEE] | [STATUS] | [DURATION] |

---

## 2. Active Development
[List of child issues currently in project-defined active states]
| Key | Summary | Assignee | Status | Repeat Visits |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [ASSIGNEE] | [STATUS] | [COUNT] |

---

## 3. Handover & Verification
[List of child issues in project-defined QA, review, or UAT states]
| Key | Summary | Assignee | Status | Time in Status |
| :--- | :--- | :--- | :--- | :--- |
| [KEY] | [SUMMARY] | [ASSIGNEE] | [STATUS] | [DURATION] |

---

## 9. Morning Standup Report
**Goal**: Summarize Jira-recorded blockers, recent changes, and active work.

### Template
# Team Standup: [PROJECT/TEAM_NAME]
**Date:** [CURRENT_DATE]

## Active Blockers
[Issues currently in project-defined blocked states or explicitly identified in Jira as impediments]
* **[KEY]** - [SUMMARY] ([ASSIGNEE]) - *In current status for [DURATION]*.
  * *Reason:* [Latest relevant Jira comment or "not recorded"]

---

## Completed Yesterday
[Issues transitioned to a Done-category status in the reporting period]
* **[KEY]** - [SUMMARY] ([ASSIGNEE])

---

## In Flight
[Group active issues by assignee]
* **[DEVELOPER_1]:** [KEY] - [SUMMARY] ([STATUS])
* **[DEVELOPER_2]:** [KEY] - [SUMMARY] ([STATUS])

---

## Verification Needed
[Tickets in project-defined review or QA states]
* **[KEY]** - [SUMMARY] ([STATUS]) - *In current status for [DURATION]*