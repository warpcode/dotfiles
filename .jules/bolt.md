## 2026-10-01 - O(1) Work-Seconds Calculation in Jira Metrics
**Learning:** Calculating work durations across large date spans (e.g., Jira cycle/lead time metrics over several months/years) via daily loop iteration incurs linear runtime overhead proportional to the date range size.
**Action:** Replace date iteration loops in calendar/business-hours calculations with O(1) integer division (`divmod(days, 7)`) for full weeks plus modulo remainder indexing for leftover weekdays.

## 2026-10-07 - Avoid Redundant Function Calls in Table Rendering Loops
**Learning:** In table rendering or list rollup loops (e.g., PR state rollups), inner functions often call helper methods that re-evaluate expensive operations already computed by the outer rendering loop.
**Action:** Pass pre-computed intermediate results (such as check rollup outcomes) as optional parameters into inner helper functions to avoid redundant processing iterations.

## 2026-10-08 - Omit Key-Sorting in Hash Generation for Pre-Normalized Dictionaries
**Learning:** `json.dumps(dict, sort_keys=True)` incurs key-sorting overhead across large dictionary lists. When list items are pre-normalized with deterministic key insertion order, `sort_keys=True` is redundant for in-memory hashing.
**Action:** Omit `sort_keys=True` only when every dict in the structure is constructed by the same normalization helper (`_normalize_message`) with a fixed key order, and the hashed value is in-memory only. Keep `sort_keys=True` wherever key ordering is incidental or when hashes are persisted across process boundaries.

## 2026-10-09 - Pre-Compile Dynamic Regexes and Fast Substring Pre-Checks
**Learning:** Evaluating dynamically interpolated regexes (`re.search(rf"...")`) inside inner loops (such as matching tool call arguments against script target names across transcripts) bypasses Python's internal `re` cache and incurs severe regex compilation and evaluation overhead per item.
**Action:** Pre-compile dynamic regex patterns into a dictionary (`script_patterns`) at the top level before iteration, and use a fast string containment check (`if s in cmd_str:`) as a short-circuit guard prior to running `pattern.search(cmd_str)`.

## 2026-10-10 - Module-Level Set Allocation and Type Guard Ordering in AST Parsing
**Learning:** In recursive document format/AST traversals (e.g., Jira ADF parsing), checking the most common container type (`isinstance(node, dict)`) first reduces guard evaluations per node visit. Additionally, allocating string sets (`NEWLINE_BLOCK_TYPES`) at module level avoids per-function-call tuple creation overhead.
**Action:** Order type guards in tree traversal functions according to node type frequency and move literal tuple/set collections to module constants.
## 2026-10-10 - `$( )` Around Pure Zsh Helpers Is a Per-Startup Fork Tax
**Learning:** In zsh, `$(helper)` forks a subshell at ~0.49 ms measured here, even when `helper` only does `printf`/`print`. `dot_zsh/functions/registry.zsh` routed every string-building helper (`_registry.ns_var`, `_registry.norm`) through `print`, so `registry.define` forked 9 times and `registry.get` 4 times. Six `ai.provider.define` calls at shell startup cost ~70 ms in forks alone.
**Action:** Return pure-computation results via `REPLY` (zsh's built-in convention) instead of stdout, so callers do `_registry.norm "$2" || return 1; id="$REPLY"` rather than `id="$(_registry.norm "$2")"`. Two traps worth remembering: (1) `REPLY` is only safe because these helpers are leaf functions with no nested `REPLY` writers — a helper that calls another `REPLY`-returning function must copy `REPLY` to a local *before* the nested call. (2) Always A/B benchmark through an argument (`zsh bench.zsh $REGISTRY_PATH`) — a benchmark that hardcodes the patched file for both arms reports a fake null result.

