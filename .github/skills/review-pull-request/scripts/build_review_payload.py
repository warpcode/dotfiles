#!/usr/bin/env python3
"""Build a REST PR review payload from a compact findings spec.

Spec JSON (list, or object with "findings"):
  [{"path": "...", "line": 12, "severity": "High", "title": "...",
    "description": "...", "impact": "...", "solution": "..."}]

Writes the payload (event REQUEST_CHANGES, neutral one-line body, inline comments
only, side RIGHT, no subject_type) to --out. Submit it with
github-cli/scripts/submit_pull_request_review_payload.sh.
Use verify_review_anchors.sh to check every line against the PR diff first.
"""
import argparse
import json
import sys


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec", help="findings spec JSON file")
    ap.add_argument("--out", required=True, help="payload output path")
    ap.add_argument("--body", default="Review findings are in the inline comments.",
                    help="neutral top-level review body (bot PRs only act on inline comments)")
    ap.add_argument("--event", default="REQUEST_CHANGES", choices=["REQUEST_CHANGES", "COMMENT", "APPROVE"])
    args = ap.parse_args()

    with open(args.spec) as f:
        spec = json.load(f)
    findings = spec["findings"] if isinstance(spec, dict) else spec

    comments = []
    for i, item in enumerate(findings):
        missing = [k for k in ("path", "line", "severity", "title", "description", "impact", "solution") if k not in item]
        if missing:
            print(f"finding {i}: missing {missing}", file=sys.stderr)
            return 1
        body = (f"**{item['severity']} - {item['title']}**\n\n"
                f"**Description:** {item['description']}\n\n"
                f"**Impact:** {item['impact']}\n\n"
                f"**Solution:** {item['solution']}")
        comments.append({"path": item["path"], "line": int(item["line"]), "side": "RIGHT", "body": body})

    with open(args.out, "w") as f:
        json.dump({"event": args.event, "body": args.body, "comments": comments}, f)
    print(f"Wrote {len(comments)} inline comment(s) to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
