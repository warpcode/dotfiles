#!/usr/bin/env python3
"""
create-changelog.py

Scaffold a standardized CHANGELOG.md file based on project archetypes.
Standard library only.
"""

import argparse
import os
import re
import sys
from pathlib import Path

TEMPLATES = {
    "keepachangelog": "changelog-keepachangelog.md",
    "standard": "changelog-keepachangelog.md",
    "library": "changelog-library-semver.md",
    "sdk": "changelog-library-semver.md",
    "cli": "changelog-cli-tool.md",
    "tooling": "changelog-cli-tool.md",
    "service": "changelog-service-webapp.md",
    "webapp": "changelog-service-webapp.md",
    "monorepo": "changelog-monorepo.md",
}


def detect_repo_slug() -> str:
    """Attempt to detect github owner/repo from git remote."""
    try:
        import subprocess
        res = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True,
            text=True,
            check=False,
        )
        if res.returncode == 0:
            url = res.stdout.strip()
            # Match github.com:owner/repo.git or https://github.com/owner/repo.git
            m = re.search(r"github\.com[:/]([^/]+)/([^/\.]+)(?:\.git)?", url)
            if m:
                return f"{m.group(1)}/{m.group(2)}"
    except Exception:
        pass
    return "owner/repo"


def main():
    parser = argparse.ArgumentParser(
        description="Scaffold a new CHANGELOG.md file based on project archetypes."
    )
    parser.add_argument(
        "--template",
        "-t",
        default="keepachangelog",
        choices=list(TEMPLATES.keys()),
        help="Template archetype (keepachangelog, library, cli, service, monorepo).",
    )
    parser.add_argument(
        "--repo",
        "-r",
        default="",
        help="Repository slug (owner/repo) for markdown compare links.",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="CHANGELOG.md",
        help="Output filepath (default: CHANGELOG.md).",
    )
    parser.add_argument(
        "--force",
        "-f",
        action="store_true",
        help="Overwrite target file if it already exists.",
    )

    args = parser.parse_args()

    out_path = Path(args.output).resolve()
    if out_path.exists() and not args.force:
        print(f"Error: Target file already exists: {out_path}", file=sys.stderr)
        print("Use --force to overwrite.", file=sys.stderr)
        sys.exit(1)

    # Locate template relative to script
    script_dir = Path(__file__).resolve().parent
    templates_dir = script_dir.parent / "templates"
    template_filename = TEMPLATES[args.template]
    template_path = templates_dir / template_filename

    if not template_path.exists():
        print(f"Error: Template file not found: {template_path}", file=sys.stderr)
        sys.exit(1)

    content = template_path.read_text(encoding="utf-8")

    repo_slug = args.repo or detect_repo_slug()
    if repo_slug:
        content = content.replace("owner/repo", repo_slug)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(content, encoding="utf-8")
    print(f"Successfully initialized changelog at: {out_path} (template: {args.template})")


if __name__ == "__main__":
    main()
