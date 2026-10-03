# Bolt's Journal

## 2025-10-03 - Pre-compiling Regex Patterns in Security Guard Rules
**Learning:** Re-compiling regex strings repeatedly inside rule matching loops (`match_str`, `match_file`, `redact_text_and_report`) introduces significant overhead (~8x slowdown in `find_rule`). Pre-compiling regex patterns into rule objects during normalization (`normalize_rules`) slashes matching time drastically.
**Action:** Always pre-compile regex patterns when loading or normalizing configuration rules that are repeatedly evaluated against multiple candidates or text segments.
