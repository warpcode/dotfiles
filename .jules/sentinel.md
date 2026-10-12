## 2026-10-08 - Prevent Command Line Argument Leakage in Exception Stderr Output
**Vulnerability:** When security guard subprocess execution fails with an unhandled exception in `dot_gemini/config/executable_ai-guard-wrapper.py`, printing the full `cmd` list to stderr leaks sensitive raw argument strings and file paths into system logs.
**Learning:** Error handling in security wrappers must never echo raw input/argument lists back to unauthenticated logs or stderr.
**Prevention:** Reference subcommands or static operation identifiers in exception messages instead of serializing dynamic command parameter arrays.
