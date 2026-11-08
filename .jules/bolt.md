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

## 2026-11-01 - Pre-Compile Regexes and Fast Substring Guards in Git Log Processing
**Learning:** In batch git history parsing (e.g. changelog extraction across hundreds or thousands of commits), evaluating uncompiled regex patterns repeatedly inside loops across each commit subject and body incurs unnecessary regex re-compilation and search overhead.
**Action:** Pre-compile static regexes at module level and guard regex invocations with fast substring checks (`"#" in subject`, `":" in s_clean`, `"(#" in clean_msg`) to skip regex engines entirely for non-matching commit messages.

## 2026-11-02 - Fast Substring Guards for PR Regex Evaluation in Changelog Audit
**Learning:** In changelog auditing loops (`audit_version_against_git`), running un-guarded regex searches across every commit subject incurs substantial overhead when most commits do not contain PR references or have already been accounted for.
**Action:** Guard regex pattern calls with `if not is_accounted and "#" in subject:` and fast substring pre-checks (`"(#"` and `"Merge pull request #"`) to bypass regex search calls on non-PR commits.

## 2026-11-03 - Avoid Redundant `while read` Piping Over Native Formatted CLI Outputs
**Learning:** In shell functions that wrap native search utilities (`git grep -n` or `grep -r -n`), piping the command output through `| while IFS=: read -r file line_num content; do print "${file}:${line_num}:${content}"; done` re-formats strings that the binary already emits natively. In Zsh, this while loop forks subshells in pipelines, introduces IPC buffering, and forces line-by-line interpreter loops (~1.63s down to ~0.57s over 50 search runs).
**Action:** Execute CLI commands directly when their native output format matches the expected consumer contract (e.g. `file:line:content`), reserving while-read loops only for paths requiring custom transformation or terminal formatting.

## 2026-11-05 - Batch Multiple Config Files into Single CLI Tool Invocations
**Learning:** Querying metadata fields across multiple JSON files by calling `jq` multiple times inside a loop (e.g. 3 separate `jq` invocations per file in `scheduler.list`) incurs severe process-spawning and subshell overhead (~311 ms vs ~7 ms for 20 tasks).
**Action:** Pass all matching configuration files to a single `jq` command utilizing `[.field1, .field2] | @tsv` and stream into a tab-delimited reader loop, reducing process spawns from 3N to 1.

## 2026-11-06 - In-Process Array Dereferencing Eliminates Subshell Forks in Zsh Dispatch
**Learning:** Extracting array elements across dynamic variable names via command substitution subshells (`ids=($(_registry.arr_get "$var"))`) incurs a ~0.49 ms subshell fork per dispatch call and risks word-splitting on values with spaces. In Zsh, dynamic indirect array dereferencing can be evaluated entirely in-process using native parameter expansion `("${(@P)var}")` with zero forks (~1.41s down to ~0.44s over 1000 dispatches).
**Action:** Use native indirect parameter expansion `("${(@P)var}")` rather than subshell-piped helper functions whenever reading array contents by variable name in Zsh.

## 2026-11-07 - Batch Array Printing with `print -r -l --` Bypasses Element Iteration Overhead
**Learning:** In Zsh, iterating element-by-element over an array in a `for e in "${elems[@]}"; do print -r -- "$e"; done` loop incurs substantial interpreter loop evaluation overhead (~1.12s down to ~0.10s over 2,000 array dumps of 100 elements, an ~11x speedup). In functions like `registry.list` that output line-delimited items from an array name, batch-printing elements with `print -r -l -- "${elems[@]}"` (guarded with `(( ${#elems} ))` to prevent emitting a blank newline on empty arrays) provides a ~3.2x end-to-end speedup.
**Action:** Replace element-by-element print loops in Zsh with direct batch printing `print -r -l -- "${elems[@]}"`, guarded by `(( ${#elems} ))`.

## 2026-11-08 - Consolidate Piped Awk Filters into Direct Positional Extraction
**Learning:** Chaining multiple `awk` invocations across a pipe (e.g., `awk '{$1=""}1' | awk '{$1=$1}1'` in link scraping pipelines) causes multiple process forks, pipes, and redundant field splitting/re-concatenation per line. A single condition-guarded field extract (`awk 'NF >= 2 {print $2}'`) produces identical whitespace-trimmed link outputs while cutting process invocations in half and speeding up stream processing by ~1.33x.
**Action:** Replace multi-stage `awk` strip/trim pipes with a single positional field print guarded by `NF >= 2`.
