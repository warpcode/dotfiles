# Specification: KeePass Search Zsh Functions

## 1. Overview
This track defines the requirements for adding new Zsh functions (`kp.search` and `kp.search.first`) to the dotfiles environment. These functions will provide programmatic search capabilities for KeePass databases. A critical technical constraint is that the `kp` function caches the password in a shell variable (`KP_PASSWORD`). To avoid repeated password prompts or failures, the new functions must ensure authentication occurs in the *current* shell scope before invoking `kp` in a subshell.

## 2. Goals
- Define a new Zsh function `kp.search` that returns full entry paths/UUIDs for matching queries.
- Define a new Zsh function `kp.search.first` that returns only the first matching entry path.
- **Authentication:** Explicitly ensure `kp.login` succeeds in the current shell *before* running any `$(kp ...)` commands.
- **Error Handling:** Ensure rigorous error propagation and argument validation. If arguments are missing, or if any step in the chain fails (`kp.login`, `kp search`, or empty results), the functions must return a non-zero exit code and appropriate error messages.

## 3. User Stories
- **US-001:** As a user, I want to run `kp.search "my query"` and get a list of all matching entry paths.
- **US-002:** As a developer, I want `kp.search.first "my query"` to return exactly one path so I can quickly retrieve a specific password.
- **US-003:** As a user, I want to be prompted for my password only once per session, even when using these search functions.
- **US-004:** As a user, I want clear error messages if I forget to provide a search term, if login fails, or if no entries are found.

## 4. Functional Requirements
- **FR-001:** `kp.search` MUST require at least one argument (the search term). If missing, it MUST print a usage message to stderr and return exit code 1.
- **FR-002:** `kp.search` MUST call `kp.login` and capture its return code. If `kp.login` fails, `kp.search` MUST return the same failure code immediately.
- **FR-003:** `kp.search` MUST invoke `kp search <term>` and filter the results for a case-insensitive exact match (matching the entry name or the full path suffix provided).
- **FR-004:** `kp.search` MUST handle empty results by printing an error to stderr and returning exit code 1.
- **FR-005:** `kp.search` MUST capture the exit code of the underlying `kp` command and return it immediately if non-zero.
- **FR-006:** `kp.search.first` MUST require at least one argument. If missing, it MUST print a usage message and return exit code 1.
- **FR-007:** `kp.search.first` MUST call `kp.search` and return only the first line of output.
- **FR-008:** `kp.search.first` MUST capture the exit code of `kp.search` and return it immediately if non-zero.
- **FR-009:** Both functions MUST be standalone Zsh functions defined in `src/zsh/apps/keepass.zsh`.
- **FR-010:** The existing `kp` function MUST NOT be modified.

## 5. Non-Functional Requirements
- **NFR-001:** Functions must follow the `kp.` prefix naming convention for helpers.
- **NFR-002:** Output should be minimal (raw paths) to facilitate programmatic use.

## 6. Acceptance Criteria
- [ ] `kp.search` returns exit code 1 if no arguments are provided.
- [ ] `kp.search` returns a non-zero exit code if `kp.login` fails.
- [ ] `kp.search "query"` outputs all matching entry paths.
- [ ] `kp.search "missing"` outputs an error to stderr and returns status 1.
- [ ] `kp.search.first "query"` outputs exactly the first matching path.
- [ ] `kp.search.first` returns a non-zero exit code if `kp.search` (or `kp.login`) fails.
- [ ] `kp` function remains exactly as it was.
