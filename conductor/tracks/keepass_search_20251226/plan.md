# Plan: KeePass Search Zsh Functions

## Phase 1: Implementation
- [x] Task: Implement `kp.search` in `src/zsh/apps/keepass.zsh` <!-- b54aabd -->
  - [ ] Sub-task: Define `kp.search()` as a Zsh function.
  - [ ] Sub-task: Add argument check: if `$#` is 0, print usage to stderr and return 1.
  - [ ] Sub-task: Call `kp.login`. If it returns non-zero, return that same exit code immediately.
  - [ ] Sub-task: Call `kp search -p "$1"` to get paths from the database, capturing output and exit code.
  - [ ] Sub-task: If `kp` failed, return its exit code.
  - [ ] Sub-task: If `kp` succeeded but output is empty, print "No entries found" to stderr and return 1.
  - [ ] Sub-task: Print output on success.
- [x] Task: Implement `kp.search.first` in `src/zsh/apps/keepass.zsh` <!-- 43bf84b -->
  - [ ] Sub-task: Define `kp.search.first()` as a Zsh function.
  - [ ] Sub-task: Add argument check: if `$#` is 0, print usage to stderr and return 1.
  - [ ] Sub-task: Call `kp.search "$1"` and capture output/exit code.
  - [ ] Sub-task: If `kp.search` failed (including validation, login, or empty result failures), return its exit code immediately.
  - [ ] Sub-task: If `kp.search` succeeded, print the first line of its output.
- [ ] Task: Conductor - User Manual Verification 'Implementation' (Protocol in workflow.md)

## Phase 2: Verification
- [ ] Task: Verify `kp.search` with no arguments (should error).
- [ ] Task: Verify `kp.search` propagates `kp.login` failure (incorrect password).
- [ ] Task: Verify `kp.search` returns paths for a known partial match.
- [ ] Task: Verify `kp.search` returns exit 1 (and error message) for a failed match.
- [ ] Task: Verify `kp.search.first` returns a single string.
- [ ] Task: Verify `kp.search.first` propagates errors from `kp.search` (including argument validation and login failures).
- [ ] Task: Conductor - User Manual Verification 'Verification' (Protocol in workflow.md)
