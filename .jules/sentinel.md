## 2026-10-08 - Prevent Command Line Argument Leakage in Exception Stderr Output
**Vulnerability:** When security guard subprocess execution fails with an unhandled exception in `dot_gemini/config/executable_ai-guard-wrapper.py`, printing the full `cmd` list to stderr leaks sensitive raw argument strings and file paths into system logs.
**Learning:** Error handling in security wrappers must never echo raw input/argument lists back to unauthenticated logs or stderr.
**Prevention:** Reference subcommands or static operation identifiers in exception messages instead of serializing dynamic command parameter arrays.

## 2026-11-02 - Avoid Logging Raw Subprocess Outputs in Unauthenticated Bridge Sidecars
**Vulnerability:** `dot_gemini/config/sidecars/openai-bridge/server.py` logged full raw `agentapi` stdout strings (`logging.info(f"agentapi stdout: {stdout}")`), leaking sensitive model responses, user prompt details, and potentially exposed tokens directly into application logs.
**Learning:** Debug-level outputs from wrapped subprocesses easily slip into production/daemon log streams if printed indiscriminately. In sidecars handling LLM dialogues or sensitive CLI tooling, responses can contain private data or redacted keys.
**Prevention:** Never log raw stdout or stderr payloads directly from command handlers. Log only high-level status metadata (such as exit codes and response character counts).

## 2026-10-10 - Unauthenticated sidecars must bind loopback, not `("", port)`
**Vulnerability:** `dot_gemini/config/sidecars/openai-bridge/server.py` bound `("", port)` (0.0.0.0) with `restart_policy: always` and no auth anywhere in the handler. Any LAN host could POST to `/v1/chat/completions` and drive `agentapi` with attacker-controlled prompts, executing with the user's privileges and full environment (including any exported API keys). Also `Content-Length` was unbounded and unvalidated (`int()` raised an unhandled `ValueError`).
**Learning:** `server_address = ("", port)` is the idiomatic Python one-liner and reads as "bind a port", not "expose to the network" — it silently opts every sidecar into LAN exposure. In a dotfiles repo these sidecars are long-lived daemons (`restart_policy: always`), so a binding mistake is permanent rather than session-scoped. The absence of auth in an OpenAI-*shaped* API also feels "normal" (these are conventionally loopback-only), which camouflages the exposure.
**Prevention:** Any `http.server`/`ThreadingHTTPServer`/socket bind in this repo defaults to `127.0.0.1` via a named constant, with the interface overridable only by an explicit env var. Grep for `("", port)` / `("0.0.0.0"` when touching sidecars. Also cap `Content-Length` before `rfile.read()` on every handler.
