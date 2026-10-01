# Sentinel Security Journal

## 2026-03-31 - Safe Associative Array Assignment in Zsh Registries
**Vulnerability:** Use of `eval` in `_registry.aa_set` (`eval "${1}[${2}]=${(q)3}"`) and `registry.define` (`eval "${list_var}+=(\"\${id}\")"`), allowing arbitrary code execution if dynamic keys, values, or namespace list names contained shell command substitutions (e.g. `$(...)`).
**Learning:** In Zsh 5.8+, `eval` is unnecessary for dynamic associative array assignments or array expansion. Instead, `typeset -g "${var}[${key}]"="${val}"` safely assigns associative array elements, and `set -A "$varname" "${(@P)varname}" "$elem"` safely appends array elements without shell evaluation.
**Prevention:** Avoid `eval` for dynamic array manipulation in Zsh. Use native parameter dereferencing (`${(@P)var}`) and `typeset -g` or `set -A`.
