# Benchmark Baseline & Performance Claim Verification

Guidelines for verifying cited benchmarks and performance claims before accepting reported speedups or allocation reductions.

---

## 1. Committed Artifact Check

Confirm that named benchmarks or tests cited in a change description (e.g., `BenchmarkFilterResultsByExpression`) are committed to the target head blob rather than remaining local to the author's environment.

---

## 2. Head vs. Base Reproduction

Re-run the cited benchmark on **both** head and base in isolated worktrees with multiple iterations (e.g., `go test -bench=... -benchmem -count=6`) and report the measured comparison table:
- A committed benchmark can still carry fabricated or stale numbers.
- Challenge headline claims in the finding whenever measured numbers fail to reproduce, even if the underlying code change is functionally valid.

---

## 3. Baseline Fidelity Check

Verify the benchmark baseline compares against the **real pre-change implementation**, not a hand-rewritten strawman:
- Diff the benchmark's baseline function against the base branch (`git show <base-ref>:<path> | diff - <base-path>`).
- Flag benchmarks whose baseline omits existing optimizations (such as an already-present accumulator) or alters control flow relative to base.

---

## 4. Path Coverage & Mechanism Plausibility

- **Exercises Changed Path**: Confirm the benchmark inputs actually reach the modified branches rather than executing a fast-path or no-op branch.
- **Plausible Mechanism**: Verify the code change can explain the claimed delta (e.g., an allocation removed in source that the compiler/runtime already eliminated on the base branch will measure allocation-neutral).
