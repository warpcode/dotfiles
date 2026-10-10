#!/usr/bin/env python3
"""Apply one source mutation described by a JSON object, for mutation_check.sh.

Reads a mutation spec on stdin or from a path, applies it to the target file,
and reports what happened. Kept as a file (rather than an inline
`python3 -c` / heredoc) so it is reviewable in a diff, unit-testable, and
reused verbatim by mutation_check.sh for every mutation in a run.

Spec (one JSON object):
  {
    "path": "internal/engine/autoload.go",   # required, relative to --root
    "old":  "if gStart < 0 ||",             # required, must occur in the file
    "new":  "if true ||",                   # required, "" means delete
    "count": 1                              # optional, max replacements (default 1)
  }

Exit codes:
  0  mutation applied
  1  `old` not found (or found fewer times than `count` requires)
  2  bad usage / unreadable spec / unreadable file
  3  write failed
"""
import argparse
import json
import sys


def fail(msg: str, code: int) -> "int":
    print(f"apply_mutation: {msg}", file=sys.stderr)
    return code


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec", nargs="?", default="-",
                    help="mutation JSON file, or - for stdin (default: -)")
    ap.add_argument("--root", default=".",
                    help="directory the mutation path is relative to (default: .)")
    ap.add_argument("--check", action="store_true",
                    help="report whether old is present, then exit without writing")
    args = ap.parse_args()

    raw = sys.stdin.read() if args.spec == "-" else open(args.spec, encoding="utf-8").read()
    try:
        mut = json.loads(raw)
    except json.JSONDecodeError as exc:
        return fail(f"spec is not valid JSON: {exc}", 2)

    for key in ("path", "old", "new"):
        if key not in mut:
            return fail(f"spec is missing '{key}'", 2)

    import os
    root_abs = os.path.abspath(args.root)
    target = os.path.abspath(os.path.join(root_abs, mut["path"]))
    try:
        rel = os.path.relpath(target, root_abs)
        if rel.startswith("..") or os.path.isabs(rel):
            return fail(f"target path is outside root directory: {mut['path']!r}", 2)
    except ValueError:
        return fail(f"target path is outside root directory: {mut['path']!r}", 2)
    try:
        with open(target, encoding="utf-8") as fh:
            src = fh.read()
    except OSError as exc:
        return fail(f"cannot read {target}: {exc}", 2)

    old, new = mut["old"], mut["new"]
    count = int(mut.get("count", 1))
    if count < 1:
        return fail(f"count must be >= 1, got {count}", 2)

    occurrences = src.count(old)
    if occurrences == 0:
        return fail(f"pattern not found in {mut['path']}: {old!r}", 1)
    if occurrences < count:
        return fail(
            f"pattern occurs {occurrences}x in {mut['path']}, need {count}: {old!r}", 1)

    if args.check:
        print(f"FOUND {occurrences}x in {mut['path']}")
        return 0

    # Replace the LAST `count` occurrence(s) from the front in a single pass so
    # overlapping patterns cannot shift the offsets mid-replacement.
    out, pos, done = [], 0, 0
    while done < count:
        idx = src.index(old, pos)
        out.append(src[pos:idx])
        out.append(new)
        pos = idx + len(old)
        done += 1
    out.append(src[pos:])
    mutated = "".join(out)

    try:
        with open(target, "w", encoding="utf-8") as fh:
            fh.write(mutated)
    except OSError as exc:
        return fail(f"cannot write {target}: {exc}", 3)

    print(f"APPLIED {mut['path']} (replaced {count}x)")
    return 0


if __name__ == "__main__":
    sys.exit(main())