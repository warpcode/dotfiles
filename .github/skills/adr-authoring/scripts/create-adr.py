#!/usr/bin/env python3
"""
create-adr.py

Scaffold Architecture Decision Records (ADRs) with sequential numbering.
Standard library only.
"""

import argparse
import datetime
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass
class ADRContext:
    """Encapsulates context/metadata for an ADR."""

    title: str
    number: int = 0
    status: str = "Proposed"
    author: str = "Engineering Team"
    supersedes: Optional[str] = None


def slugify(text: str) -> str:
    """Convert text to URL- and filesystem-safe slug."""
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-")


def get_next_adr_number(adr_dir: Path) -> int:
    """Detect next available sequential ADR number."""
    if not adr_dir.exists():
        return 1

    max_num = 0
    pattern = re.compile(r"^(\d{4})[-_].*\.md$", re.IGNORECASE)
    for entry in adr_dir.iterdir():
        if entry.is_file():
            m = pattern.match(entry.name)
            if m:
                num = int(m.group(1))
                if num > max_num:
                    max_num = num

    return max_num + 1


def get_template_path(template_name: str, skill_root: Path) -> Path:
    """Locate template file within the skill templates directory."""
    templates_dir = skill_root / "templates"
    template_file = templates_dir / f"adr-{template_name}.md"
    if not template_file.exists():
        direct = templates_dir / template_name
        if direct.exists():
            return direct
        raise FileNotFoundError(f"Template not found: {template_file}")
    return template_file


def render_template(
    template_content: str,
    context: ADRContext,
) -> str:
    """Replace placeholders in template."""
    num_str = f"{context.number:04d}"
    now = datetime.date.today().isoformat()
    content = template_content
    content = content.replace("[NUMBER]", num_str)
    content = content.replace("[Title]", context.title)
    content = content.replace("[Status]", context.status)
    content = content.replace("[Date]", now)
    content = content.replace("[Author / Deciders]", context.author)

    if context.supersedes:
        content = content.replace(
            "[Superseded By / Supersedes]", f"Supersedes ADR-{context.supersedes}"
        )
    else:
        content = content.replace(
            "[Superseded By / Supersedes]", "None"
        )
    return content


def scaffold_adr(
    context: ADRContext,
    template_name: str = "madr",
    adr_dir_path: str = "docs/adr",
    skill_root: Optional[Path] = None,
) -> Path:
    """Generate a new ADR file."""
    if skill_root is None:
        skill_root = Path(__file__).resolve().parent.parent

    adr_dir = Path(adr_dir_path)
    if not context.number:
        context.number = get_next_adr_number(adr_dir)

    num_str = f"{context.number:04d}"
    slug = slugify(context.title)
    filename = f"{num_str}-{slug}.md"
    out_file = adr_dir / filename

    tmpl_file = get_template_path(template_name, skill_root)
    template_content = tmpl_file.read_text(encoding="utf-8")
    rendered = render_template(template_content, context)

    adr_dir.mkdir(parents=True, exist_ok=True)
    out_file.write_text(rendered, encoding="utf-8")
    return out_file


def run_self_test(skill_root: Path) -> int:
    """Execute unit self-tests."""
    print("Running self-tests for create-adr.py...")
    # Test slugify
    assert slugify("Use PostgreSQL for Event Store") == "use-postgresql-for-event-store"

    # Test templates exist
    tmpl_madr = get_template_path("madr", skill_root)
    assert tmpl_madr.exists(), f"MADR template missing at {tmpl_madr}"
    tmpl_nygard = get_template_path("nygard", skill_root)
    assert tmpl_nygard.exists(), f"Nygard template missing at {tmpl_nygard}"

    # Test render
    sample = "# ADR-[NUMBER]: [Title]\nStatus: [Status]\nDate: [Date]"
    ctx = ADRContext(title="Cache Layer", number=42, status="Accepted")
    rendered = render_template(sample, ctx)
    assert "ADR-0042: Cache Layer" in rendered
    assert "Status: Accepted" in rendered

    import tempfile
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp_path = Path(tmpdir)
        assert get_next_adr_number(tmp_path) == 1
        (tmp_path / "0001-init.md").write_text("dummy", encoding="utf-8")
        assert get_next_adr_number(tmp_path) == 2
        (tmp_path / "0005-other.md").write_text("dummy", encoding="utf-8")
        assert get_next_adr_number(tmp_path) == 6

    print("All self-tests passed successfully.")
    return 0


def main() -> int:
    skill_root = Path(__file__).resolve().parent.parent

    parser = argparse.ArgumentParser(
        description="Scaffold a new Architecture Decision Record (ADR) with sequential numbering."
    )
    parser.add_argument(
        "--title",
        "-t",
        type=str,
        help="Title of the architectural decision.",
    )
    parser.add_argument(
        "--template",
        "-m",
        choices=["madr", "nygard"],
        default="madr",
        help="Template archetype (default: madr).",
    )
    parser.add_argument(
        "--dir",
        "-d",
        type=str,
        default="docs/adr",
        help="Target ADR directory (default: docs/adr).",
    )
    parser.add_argument(
        "--status",
        "-s",
        choices=["Proposed", "Accepted", "Rejected", "Deprecated", "Superseded"],
        default="Proposed",
        help="Initial decision status (default: Proposed).",
    )
    parser.add_argument(
        "--author",
        "-a",
        type=str,
        default="Engineering Team",
        help="Deciders / authors (default: Engineering Team).",
    )
    parser.add_argument(
        "--supersedes",
        type=str,
        help="ADR number that this decision supersedes (e.g. 0003).",
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
        ctx = ADRContext(
            title=args.title,
            status=args.status,
            author=args.author,
            supersedes=args.supersedes,
        )
        created = scaffold_adr(
            context=ctx,
            template_name=args.template,
            adr_dir_path=args.dir,
            skill_root=skill_root,
        )
        print(f"Created ADR at: {created}")
        return 0
    except Exception as exc:
        print(f"Error creating ADR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
