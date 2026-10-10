## 2026-10-01 - O(1) Work-Seconds Calculation in Jira Metrics
**Learning:** Calculating work durations across large date spans (e.g., Jira cycle/lead time metrics over several months/years) via daily loop iteration incurs linear runtime overhead proportional to the date range size.
**Action:** Replace date iteration loops in calendar/business-hours calculations with O(1) integer division (`divmod(days, 7)`) for full weeks plus modulo remainder indexing for leftover weekdays.

## 2026-10-07 - Avoid Redundant Function Calls in Table Rendering Loops
**Learning:** In table rendering or list rollup loops (e.g., PR state rollups), inner functions often call helper methods that re-evaluate expensive operations already computed by the outer rendering loop.
**Action:** Pass pre-computed intermediate results (such as check rollup outcomes) as optional parameters into inner helper functions to avoid redundant processing iterations.
