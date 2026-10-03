---
name: go
description: Guidance for Go development, testing hygiene, UTF-8 string scanning, and performance conventions.
applyTo: "**/*.go"
---

# Go Coding and Testing Rules

## Code Hygiene & Idioms
- Follow standard Go conventions (`gofmt`, `go vet` clean).
- Errors must be handled explicitly — no `_` discard of errors in production paths.
- Use `fmt.Errorf("context: %w", err)` for error wrapping to preserve the chain.
- Package-level `var` blocks for sentinel errors; never use raw string comparisons.
- Avoid `init()` functions; prefer explicit initialization in constructors.
- Table-driven tests are preferred for unit tests covering multiple input cases.

## String Scanning & UTF-8 Invariants
- **Allocation-Free Stdlib**: `strings.TrimSpace`, `strings.EqualFold`, and `strings.IndexByte` are already allocation-free (they return subslices or perform length-only comparisons). Do not replace them with hand-rolled scanners under the assumption of reducing allocations.
- **EqualFold and Byte Length**: Never guard `strings.EqualFold` with byte length checks (`len(a) == len(b)`). In UTF-8, case folding does not preserve byte length (e.g. Kelvin sign `'K'` [3 bytes] vs `'k'` [1 byte], Angstrom `'Å'` [3 bytes] vs `'Å'` [2 bytes]), leading to subtle false negatives.
- **Whitespace Handling**: Custom trimming loops intended to mimic standard whitespace trimming must strip all standard whitespace characters (`\t`, `\n`, `\r`, `\v`, `\f`, etc., or `unicode.IsSpace`) rather than only ASCII spaces (`' '`), and empty delimiter-separated segments should be handled explicitly.

## Testing Hygiene
- **Safe Redirection**: When capturing stdout or stderr using `os.Pipe()`, check the returned error immediately. Defer closing both writer ends (`wOut.Close()`, `wErr.Close()`) immediately after creation to prevent resource leaks (dangling goroutines/pipes) if the test function panics.
- **Table-Driven Tests**: Keep test cases isolated and ensure each test subcase exercises assertions independently.
