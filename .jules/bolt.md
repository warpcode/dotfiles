## 2026-10-01 - O(1) Work-Seconds Calculation in Jira Metrics
**Learning:** Calculating work durations across large date spans (e.g., Jira cycle/lead time metrics over several months/years) via daily loop iteration incurs linear runtime overhead proportional to the date range size.
**Action:** Replace date iteration loops in calendar/business-hours calculations with O(1) integer division (`divmod(days, 7)`) for full weeks plus modulo remainder indexing for leftover weekdays.

## 2026-10-07 - Avoid Redundant Function Calls in Table Rendering Loops
**Learning:** In table rendering or list rollup loops (e.g., PR state rollups), inner functions often call helper methods that re-evaluate expensive operations already computed by the outer rendering loop.
**Action:** Pass pre-computed intermediate results (such as check rollup outcomes) as optional parameters into inner helper functions to avoid redundant processing iterations.

## 2026-10-08 - Omit Key-Sorting in Hash Generation for Pre-Normalized Dictionaries
**Learning:** `json.dumps(dict, sort_keys=True)` incurs key-sorting overhead across large dictionary lists. When list items are pre-normalized with deterministic key insertion order, `sort_keys=True` is redundant for in-memory hashing.
**Action:** Omit `sort_keys=True` only when every dict in the structure is constructed by the same normalization helper (`_normalize_message`) with a fixed key order, and the hashed value is in-memory only. Keep `sort_keys=True` wherever key ordering is incidental or when hashes are persisted across process boundaries.
