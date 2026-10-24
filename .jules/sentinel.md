## 2026-10-08 - Prevent Command Line Argument Leakage in Exception Stderr Output
**Vulnerability:** When security guard subprocess execution fails with an unhandled exception in `dot_gemini/config/executable_ai-guard-wrapper.py`, printing the full `cmd` list to stderr leaks sensitive raw argument strings and file paths into system logs.
**Learning:** Error handling in security wrappers must never echo raw input/argument lists back to unauthenticated logs or stderr.
**Prevention:** Reference subcommands or static operation identifiers in exception messages instead of serializing dynamic command parameter arrays.

## 2026-10-10 - Unauthenticated sidecars must bind loopback, not `("", port)`
**Vulnerability:** `dot_gemini/config/sidecars/openai-bridge/server.py` bound `("", port)` (0.0.0.0) with `restart_policy: always` and no auth anywhere in the handler. Any LAN host could POST to `/v1/chat/completions` and drive `agentapi` with attacker-controlled prompts, executing with the user's privileges and full environment (including any exported API keys). Also `Content-Length` was unbounded and unvalidated (`int()` raised an unhandled `ValueError`).
**Learning:** `server_address = ("", port)` is the idiomatic Python one-liner and reads as "bind a port", not "expose to the network" — it silently opts every sidecar into LAN exposure. In a dotfiles repo these sidecars are long-lived daemons (`restart_policy: always`), so a binding mistake is permanent rather than session-scoped. The absence of auth in an OpenAI-*shaped* API also feels "normal" (these are conventionally loopback-only), which camouflages the exposure.
**Prevention:** Any `http.server`/`ThreadingHTTPServer`/socket bind in this repo defaults to `127.0.0.1` via a named constant, with the interface overridable only by an explicit env var. Grep for `("", port)` / `("0.0.0.0"` when touching sidecars. Also cap `Content-Length` before `rfile.read()` on every handler.

## 2026-10-23 - Secure execution of remote bootstrap scripts
**Vulnerability:** In `install.sh`, downloading installation scripts via `curl` and piping directly to shell (`/bin/bash -c "$(curl ...)"` or `curl ... | sh`) without verifying download completion or saving to temporary files leaves the process vulnerable to partial execution upon network interruption or MITM stream manipulation.
**Learning:** Bootstrap scripts downloading remote installers should always save the script to a secure temporary file using `mktemp -t`, verify that the download succeeded (`curl -fsSL` exit code check), execute from the file, and ensure cleanup afterwards.
**Prevention:** Avoid piping `curl` outputs directly into `sh` or `bash`. Ensure `tests/test_install_script.py` validates that `install.sh` does not contain unverified `curl | sh` pipes.
