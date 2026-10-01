## 2025-02-18 - Parameter Indirection Injection via Subscripts in Zsh
**Vulnerability:** In Zsh, resolving associative array values via parameter indirection `${(P)ref}` where `ref="varname[${key}]"` re-evaluates expressions (such as `$(...)`) in `${key}` even when `eval` is not explicitly used.
**Learning:** `typeset -g` or direct assignment prevents injection during assignment, but reading via `${(P)ref}` where `ref` contains subscript syntax still executes command substitutions embedded in keys or indices.
**Prevention:** Always strictly validate and sanitize associative array keys and variable identifiers (e.g., restricted to `^[A-Za-z0-9_]+$`) prior to referencing them in dynamic parameter indirection expressions in Zsh.
