#!/usr/bin/env python3
"""Extract undelivered git patches from completed Jules sessions and prepare branches.

Usage:
    python3 deliver_patch.py <session_id> [--apply]
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def deliver(session_id: str, apply_branch: bool = False) -> int:
    sid = session_id.strip().removeprefix("sessions/")
    script_dir = Path(__file__).resolve().parent
    api_main = script_dir.parent.parent / "google-jules-api" / "scripts" / "main.py"

    cmd = ["python3", str(api_main), "call", "GET", f"sessions/{sid}"]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        sys.stderr.write(f"Error fetching session {sid}: {proc.stderr}\n")
        return 1

    try:
        data = json.loads(proc.stdout)
    except Exception as e:
        sys.stderr.write(f"Error parsing session JSON: {e}\n")
        return 1

    patch = None
    commit_msg = "auto(jules): deliver undelivered patch"
    source = data.get("sourceContext", {}).get("source", "")

    # Look in outputs first, then fall back to activities
    for out in data.get("outputs", []):
        cs = out.get("changeSet") or {}
        if cs.get("gitPatch", {}).get("unidiffPatch"):
            patch = cs["gitPatch"]["unidiffPatch"]
            commit_msg = cs.get("suggestedCommitMessage") or commit_msg
            break

    if not patch:
        sys.stderr.write(f"No git patch found in session {sid} outputs.\n")
        return 1

    patch_path = Path(f"/tmp/jules_{sid}.patch")
    patch_path.write_text(patch)
    print(f"Extracted patch to {patch_path}")
    print(f"Source context: {source}")
    print(f"Suggested commit message:\n{commit_msg}\n")

    if apply_branch:
        branch = f"tidy/jules-{sid}"
        print(f"Creating branch {branch} and applying patch...")
        subprocess.run(["git", "checkout", "-b", branch], check=True)
        subprocess.run(["git", "apply", str(patch_path)], check=True)
        print(f"Successfully applied patch to branch {branch}!")

    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("session_id", help="Jules session ID to extract patch from")
    parser.add_argument("--apply", action="store_true", help="Checkout a new branch and apply the patch")
    args = parser.parse_args()

    sys.exit(deliver(args.session_id, apply_branch=args.apply))


if __name__ == "__main__":
    main()
