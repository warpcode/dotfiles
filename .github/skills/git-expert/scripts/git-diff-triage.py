#!/usr/bin/env python3
"""
git_diff_triage.py

Purpose: feed a git diff to an LLM without bloating context.

Strategy: for each changed file, show the FULL diff if it's small
(<= --threshold changed lines), otherwise show only the structural
header lines (file header, mode/rename/copy/similarity lines, ---/+++,
@@ hunk markers, "Binary files ... differ") plus a one-line note
saying how many lines were omitted.

By default this also applies a set of git diff flags chosen for LLM
context efficiency (see DEFAULT_DIFF_FLAGS below) -- most notably -D,
which drops the old content of deletions entirely, and -B combined
with -D, which does the same for a file that's rewritten so heavily
in place that it falls below the rename-similarity threshold.

Design notes:
- Splitting the diff per-file and re-running `git diff -- <path>`
  breaks rename/copy detection, because pathspec-restricted diffs
  can't see the old name. This script instead runs `git diff` ONCE
  and splits the single output into per-file chunks on lines matching
  '^diff --git '. That keeps rename/copy/similarity headers intact.
- Sizing decisions are made by counting the +/- lines actually present
  in each chunk's own output, NOT by calling `git diff --numstat`.
  This matters because flags like -D and -w change what's shown in
  the diff body without changing numstat's counts (verified: -D
  suppresses a deletion's content but numstat still reports the full
  original line count; -w hides whitespace-only changes but numstat
  still counts them). Counting the actual rendered lines means the
  truncation logic reacts to what's really in the output, and won't
  add a misleading "body omitted" note to something already-suppressed
  by -D/-B.
- Binary files are detected directly from the chunk text (a line
  matching "^Binary files .* differ$"), not from a numstat marker.

Usage:
    ./git_diff_triage.py [--threshold N] [--raw] [-- <git diff args...>]

Any args after `--` are appended to the default flag set below, so you
can add a revision range / pathspec, or override a default (e.g. pass
-M0 to change the rename similarity threshold).

Examples:
    ./git_diff_triage.py
    ./git_diff_triage.py --raw
    ./git_diff_triage.py --threshold 80
    ./git_diff_triage.py --threshold 60 -- --staged
    ./git_diff_triage.py -- HEAD~3 HEAD
"""

import argparse
import re
import subprocess
import sys

HEADER_PATTERN = re.compile(
    r"^(diff --git|index [0-9a-f]|(deleted|new) file mode|old mode|"
    r"new mode|rename (from|to)|copy (from|to)|similarity index|"
    r"dissimilarity index|--- |\+\+\+ |@@|Binary files)"
)

BINARY_PATTERN = re.compile(r"^Binary files .* differ$", re.MULTILINE)

# Chosen for LLM token efficiency:
#   -U0                       zero context lines around each hunk
#   --diff-algorithm=minimal  diff-quality choice; not guaranteed to
#                             reduce size, but doesn't hurt
#   -B                        break complete rewrites into delete+create,
#                             so -D can suppress the "delete" half's old
#                             content on a heavily-rewritten file
#   -M                        rename detection (default in modern git,
#                             kept explicit for reproducibility)
#   -C --find-copies-harder   copy detection; --find-copies-harder is a
#                             no-op without -C, and is expensive (scans
#                             unmodified files too) -- included per your
#                             call that the extra processing time is
#                             worth the token savings
#   -D                        omit preimage (old content) for deletes
#   -w                        ignore all whitespace changes
#   --ignore-blank-lines      hide hunks that are blank-line-only changes
#   --no-color                redundant when piped (git already suppresses
#                             color for non-tty output), kept per request
#                             in case color.ui=always is set globally
DEFAULT_DIFF_FLAGS = [
    "-U0",
    "--diff-algorithm=minimal",
    "-B",
    "-M",
    "-C",
    "--find-copies-harder",
    "-D",
    "-w",
    "--ignore-blank-lines",
    "--no-color",
]


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--threshold", type=int, default=40,
                         help="max changed lines (added+removed) to show in full")
    parser.add_argument("--raw", "--raw-output", action="store_true", dest="raw",
                         help="output full git diff without hunk truncation or body omission")
    parser.add_argument("diff_args", nargs=argparse.REMAINDER,
                         help="args appended to the default git diff flags (put after --)")
    args = parser.parse_args(argv)
    # argparse REMAINDER keeps a leading "--" if present; strip it.
    if args.diff_args and args.diff_args[0] == "--":
        args.diff_args = args.diff_args[1:]
    return args


def run_git_diff(extra_args):
    try:
        result = subprocess.run(
            ["git", "diff"] + DEFAULT_DIFF_FLAGS + extra_args,
            capture_output=True, text=True, check=True,
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        if e.stderr:
            sys.stderr.write(e.stderr)
        else:
            sys.stderr.write(f"git diff failed with exit code {e.returncode}\n")
        sys.exit(1)


def split_diff_into_chunks(raw: str):
    """Split full `git diff` output into per-file chunks, each starting
    with a line matching '^diff --git '. Returns a list of chunk strings
    (each chunk includes its own trailing newline, order preserved)."""
    lines = raw.splitlines(keepends=True)
    chunks = []
    current = []
    for line in lines:
        if line.startswith("diff --git ") and current:
            chunks.append("".join(current))
            current = [line]
        else:
            current.append(line)
    if current:
        chunks.append("".join(current))
    return chunks


def count_body_lines(chunk: str):
    """Count actual +/- content lines present in a chunk's own output
    (excluding the --- / +++ file-header lines). Reflects what's really
    rendered, so it stays correct regardless of which diff flags (-D,
    -w, -B, --ignore-blank-lines, etc.) already reduced the body."""
    added = removed = 0
    for line in chunk.splitlines():
        if line.startswith("+++ ") or line.startswith("--- "):
            continue
        if line.startswith("+"):
            added += 1
        elif line.startswith("-"):
            removed += 1
    return added, removed


def header_only(chunk: str) -> str:
    kept = [line for line in chunk.splitlines(keepends=True) if HEADER_PATTERN.match(line)]
    return "".join(kept)


def main():
    args = parse_args(sys.argv[1:])

    full_raw = run_git_diff(args.diff_args)
    if args.raw:
        sys.stdout.write(full_raw)
        return

    chunks = split_diff_into_chunks(full_raw)

    out = []
    for chunk in chunks:
        if BINARY_PATTERN.search(chunk):
            # Binary file: git diff already keeps this compact
            # ("Binary files a/x and b/x differ"), just pass it through.
            out.append(chunk)
            out.append("\n")
            continue

        added, removed = count_body_lines(chunk)
        total = added + removed

        if total == 0:
            # Nothing to truncate: already fully suppressed (e.g. a
            # deletion under -D, or a pure rename with identical
            # content) -- pass through as-is, no note needed.
            out.append(chunk)
        elif total <= args.threshold:
            out.append(chunk)
        else:
            out.append(header_only(chunk))
            out.append(
                f"# [diff-triage] body omitted: +{added}/-{removed} lines "
                f"(threshold {args.threshold})\n"
            )
        out.append("\n")

    sys.stdout.write("".join(out))


if __name__ == "__main__":
    main()