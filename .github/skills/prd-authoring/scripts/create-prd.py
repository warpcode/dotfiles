#!/usr/bin/env python3
"""
create-prd.py

Scaffold Product Requirements Documents (PRDs) from structured templates.
Standard library only.
"""

import argparse
import datetime
import os
import re
import sys
from pathlib import Path


def slugify(text: str) -> str:
    """Convert text to URL- and filesystem-safe slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-")


def get_template_path(template_name: str, skill_root: Path) -> Path:
    """Locate template file within the skill templates directory."""
    templates_dir = skill_root / "templates"
    template_file = templates_dir / f"prd-{template_name}.md"
    if not template_file.exists():
        # Fallback to direct name if provided with extension
        direct = templates_dir / template_name
        if direct.exists():
            return direct
        raise FileNotFoundError(f"Template not found: {template_file}")
    return template_file


def render_template(template_content: str, title: str, author: str) -> str:
    """Replace placeholders in template."""
    now = datetime.date.today().isoformat()
    content = template_content
    content = content.replace("[Feature Name]", title)
    content = content.replace("[Date]", now)
    content = content.replace("[Author Name / Team]", author)
    return content


def scaffold_prd(
    title: str,
    template_name: str = "full",
    output_path: str = None,
    author: str = "Product Team",
    skill_root: Path = None,
) -> Path:
    """Generate a new PRD file."""
    if skill_root is None:
        skill_root = Path(__file__).resolve().parent.parent

    tmpl_file = get_template_path(template_name, skill_root)
    template_content = tmpl_file.read_text(encoding="utf-8")
    rendered = render_template(template_content, title, author)

    if output_path:
        out_file = Path(output_path)
    else:
        slug = slugify(title)
        out_file = Path("docs") / "prd" / f"{slug}.md"

    out_file.parent.mkdir(parents=True, exist_ok=True)
    out_file.write_text(rendered, encoding="utf-8")
    return out_file


def run_self_test(skill_root: Path) -> int:
    """Execute unit self-tests."""
    print("Running self-tests for create-prd.py...")
    # Test slugify
    assert slugify("New Feature: Real-Time Sync!") == "new-feature-real-time-sync", "slugify failed"
    assert slugify("   Clean   Slug   ") == "clean-slug", "slugify spacing failed"

    # Test template discovery
    tmpl = get_template_path("full", skill_root)
    assert tmpl.exists(), f"Full template missing at {tmpl}"
    tmpl_light = get_template_path("lightweight", skill_root)
    assert tmpl_light.exists(), f"Lightweight template missing at {tmpl_light}"

    # Test render
    rendered = render_template("# [Feature Name]\nDate: [Date]\nAuthor: [Author Name / Team]", "Test Feature", "Dev")
    assert "Test Feature" in rendered
    assert "Dev" in rendered
    assert datetime.date.today().isoformat() in rendered

    print("All self-tests passed successfully.")
    return 0


def main() -> int:
    skill_root = Path(__file__).resolve().parent.parent

    parser = argparse.ArgumentParser(
        description="Scaffold a new Product Requirements Document (PRD) from templates."
    )
    parser.add_argument(
        "--title",
        "-t",
        type=str,
        help="Title of the feature or product initiative.",
    )
    parser.add_argument(
        "--template",
        "-m",
        choices=["full", "lightweight"],
        default="full",
        help="Template archetype (default: full).",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        help="Target output filepath (default: docs/prd/<slug>.md).",
    )
    parser.add_argument(
        "--author",
        "-a",
        type=str,
        default="Product & Engineering",
        help="Author or owner name (default: Product & Engineering).",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run self-tests and exit.",
    )

    args = parser.parse_args()

    if args.self_test:
        return run_self_test(skill_root)

    if not args.title:
        parser.error("--title / -t is required when not running --self-test.")

    try:
        created = scaffold_prd(
            title=args.title,
            template_name=args.template,
            output_path=args.output,
            author=args.author,
            skill_root=skill_root,
        )
        print(f"Created PRD at: {created}")
        return 0
    except Exception as exc:
        print(f"Error creating PRD: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
