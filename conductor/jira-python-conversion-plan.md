# Jira Python Conversion Plan

## Objective
Convert `assets/configs/ai/skills/jira-tasks/scripts/jira.sh` into a pure Python script (`jira.py`) using only standard libraries to eliminate the reliance on `curl` and `jq`, while perfectly replicating 100% of the current functionality.

## Key Files & Context
- **To Create**: `assets/configs/ai/skills/jira-tasks/scripts/jira.py`
- **To Delete**: `assets/configs/ai/skills/jira-tasks/scripts/jira.sh` (after verification)
- **To Update**:
  - `assets/configs/ai/skills/jira-tasks/SKILL.md` (Update references from `jira.sh` to `jira.py` and execution context to Python)
  - `bin/df.jira-reports` (Update the script path and execution context to use `jira.py`)

## Implementation Steps
1.  **Script Foundation**: Initialize `jira.py` using the `argparse` standard library module to replicate the exact CLI interface.
    *   **Global Options**: `--url`, `--user`, `--token`, `--project`, `--raw`, `--verbose`, `--help`.
    *   **Subcommands**: `jql`, `issues`, `fields`, `statuses`, `types`, `priorities`, `resolutions`, `users`, `call`.
2.  **Secret Resolution**: Implement a Python function using `subprocess.run` to call `DF_SECRET_GET_CMD`, seamlessly resolving environment variables (`JIRA_URL`, `JIRA_USER`, `JIRA_API_TOKEN`, `JIRA_PROJECT`) mirroring the bash script's behavior.
3.  **API Client Layer**: Create a robust API client using `urllib.request`. Implement Basic Authentication via `base64` and map the error handling (e.g., 401, 403, 404, 400) to throw descriptive Python exceptions and exit with status `1`.
4.  **ADF Processing Logic**: Write a recursive Python function (`flatten_adf`) to natively extract and format text from nested Atlassian Document Format JSON, fully replacing the legacy `jq` logic for descriptions and comments.
5.  **Subcommand Porting**: Replicate the internal logic for each subcommand. Utilize native dictionary/list comprehensions and filtering to guarantee the output JSON structure identically matches the output produced by the `jq` filters in `jira.sh`. Ensure the `--raw` flag bypasses all formatting.
6.  **Dependency Updates**: Perform surgical replacements in `SKILL.md` and `df.jira-reports` to point to the new `jira.py` script.

## Verification & Testing
1.  Run `python3 jira.py statuses` and verify successful connection and schema structure.
2.  Run `python3 jira.py fields "Story Points"` to test search filtering.
3.  Execute `python3 jira.py jql "assignee = currentUser()" --max-results 1` and compare the output structure byte-for-byte with the legacy bash script.
4.  Run `bin/df.jira-reports` to guarantee system-wide integrations remain stable.
5.  Once verified, remove `jira.sh`.