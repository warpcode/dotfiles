## 2026-10-02 - In-Process `py_compile` for Script Syntax Validation
**Learning:** Spawning external `python3 -m py_compile <file>` subprocesses during file validation introduces ~60ms per-file process creation and Python runtime startup overhead. Using Python's built-in `py_compile.compile(str(p), doraise=True)` in-process accomplishes the exact same syntax verification ~28x faster (3.13s -> 0.11s for 48 files).
**Action:** When performing Python syntax or compilation checks in Python scripts, use `py_compile.compile(file, doraise=True)` directly in-process instead of spawning sub-processes.
