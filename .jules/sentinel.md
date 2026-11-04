## 2026-10-08 - Prevent Command Line Argument Leakage in Exception Stderr Output
**Vulnerability:** When security guard subprocess execution fails with an unhandled exception in `dot_gemini/config/executable_ai-guard-wrapper.py`, printing the full `cmd` list to stderr leaks sensitive raw argument strings and file paths into system logs.
**Learning:** Error handling in security wrappers must never echo raw input/argument lists back to unauthenticated logs or stderr.
**Prevention:** Reference subcommands or static operation identifiers in exception messages instead of serializing dynamic command parameter arrays.

## 2026-10-10 - Unauthenticated sidecars must bind loopback, not `("", port)`
**Vulnerability:** `dot_gemini/config/sidecars/openai-bridge/server.py` bound `("", port)` (0.0.0.0) with `restart_policy: always` and no auth anywhere in the handler. Any LAN host could POST to `/v1/chat/completions` and drive `agentapi` with attacker-controlled prompts, executing with the user's privileges and full environment (including any exported API keys). Also `Content-Length` was unbounded and unvalidated (`int()` raised an unhandled `ValueError`).
**Learning:** `server_address = ("", port)` is the idiomatic Python one-liner and reads as "bind a port", not "expose to the network" — it silently opts every sidecar into LAN exposure. In a dotfiles repo these sidecars are long-lived daemons (`restart_policy: always`), so a binding mistake is permanent rather than session-scoped. The absence of auth in an OpenAI-*shaped* API also feels "normal" (these are conventionally loopback-only), which camouflages the exposure.
**Prevention:** Any `http.server`/`ThreadingHTTPServer`/socket bind in this repo defaults to `127.0.0.1` via a named constant, with the interface overridable only by an explicit env var. Grep for `("", port)` / `("0.0.0.0"` when touching sidecars. Also cap `Content-Length` before `rfile.read()` on every handler.

## 2026-11-01 - Prevent Agent Output and Error Leakage in Sidecar Server Logs
**Vulnerability:** `dot_gemini/config/sidecars/openai-bridge/server.py` logged raw `stdout` and `stderr` from the `agentapi` subprocess directly to system logs via `logging.info(f"agentapi stdout: {stdout}")` and `logging.warning(f"agentapi stderr: {stderr}")`. LLM responses or error diagnostics containing credentials, tokens, or confidential content were exposed in persistent server logs.
**Learning:** Just as input prompts and CLI arguments must not be logged, model completion outputs and raw stderr streams frequently contain generated secrets or sensitive diagnostics and must never be serialized into unauthenticated logs.
**Prevention:** In sidecars and daemon wrappers, log only metadata (e.g. exit status, byte length, completion status) rather than the raw output or error content of subprocesses.

## 2026-11-03 - Secure CLI Invocation and URL Decoding in Shell Download Utilities
**Vulnerability:** In `dot_local/bin/executable_dl`, URLs were passed directly to `wget` without `--` delimiter, permitting option injection (e.g., `--post-file` or `--output-document`), and default filenames were derived using bash `echo -e` string substitution which evaluated escape sequences and null bytes.
**Learning:** Naive shell-based percent-decoding using `echo -e "${_//%/\\x}"` introduces interpretation vulnerabilities for non-hex sequences and escape codes. Moreover, passing external inputs directly to commands without a `--` options delimiter allows flag injection.
**Prevention:** Always delimit positional CLI arguments with `--` when executing tools like `wget`, `curl`, or `basename`, and use standard parsing libraries like Python's `urllib.parse.unquote` to sanitize and decode URL strings.

## 2026-11-04 - Delimit Positional Arguments in CLI Web Scrapers
**Vulnerability:** In `dot_local/bin/executable_link-scraper`, URLs were passed directly to `lynx` without argument validation or `--` delimiter, allowing CLI option injection (e.g., `-auth=`, `-post_data`, `-restrictions`).
**Learning:** CLI utilities wrapping external commands like `lynx` must validate user inputs and separate option flags from positional targets using the `--` option terminator to prevent unexpected parameter injection.
**Prevention:** Always enforce argument presence validation and insert `--` before positional target arguments passed to external binaries like `lynx` or `curl`.
