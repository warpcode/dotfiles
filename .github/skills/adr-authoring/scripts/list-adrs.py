#!/usr/bin/env python3
"""
list-adrs.py

List and summarize Architecture Decision Records (ADRs) in a directory.
Standard library only.
"""

import argparse
import json
import re
import sys
from pathlib import Path


def parse_adr_file(filepath: Path) -> dict:
    """Extract metadata from an ADR markdown file."""
    content = filepath.read_text(encoding="utf-8")
    title = filepath.stem
    status = "Unknown"
    date = "Unknown"
    deciders = "Unknown"
    supersedes = None
    superseded_by = None

    # Title extraction from first # header
    m_title = re.search(r"^#\s+(?:ADR-)?(?:\d+:)?\s*(.+)$", content, re.MULTILINE)
    if m_title:
        title = m_title.group(1).strip()

    # Status extraction from metadata table or text
    m_status = re.search(r"\*\*Status\*\*\s*\|\s*([^\n|]+)", content, re.IGNORECASE)
    if not m_status:
        m_status = re.search(r"^Status:\s*([^\n]+)", content, re.MULTILINE | re.IGNORECASE)
    if m_status:
        status = m_status.group(1).strip()

    # Date extraction
    m_date = re.search(r"\*\*Date\*\*\s*\|\s*([^\n|]+)", content, re.IGNORECASE)
    if not m_date:
        m_date = re.search(r"^Date:\s*([^\n]+)", content, re.MULTILINE | re.IGNORECASE)
    if m_date:
        date = m_date.group(1).strip()

    # Deciders extraction
    m_deciders = re.search(r"\*\*Deciders\*\*\s*\|\s*([^\n|]+)", content, re.IGNORECASE)
    if m_deciders:
        deciders = m_deciders.group(1).strip()

    # Supersedes extraction
    m_sup = re.search(r"Supersedes\s+ADR-(\d+)", content, re.IGNORECASE)
    if m_sup:
        supersedes = m_sup.group(1).strip()

    m_sup_by = re.search(r"Superseded by\s+ADR-(\d+)", content, re.IGNORECASE)
    if m_sup_by:
        superseded_by = m_sup_by.group(1).strip()

    # ADR Number from filename
    num_match = re.match(r"^(\d{4})", filepath.stem)
    number = num_match.group(1) if num_match else "0000"

    return {
        "number": number,
        "filename": filepath.name,
        "path": str(filepath),
        "title": title,
        "status": status,
        "date": date,
        "deciders": deciders,
        "supersedes": supersedes,
        "superseded_by": superseded_by,
    }


def find_adrs(adr_dir: Path) -> list:
    """Find and parse all ADR markdown files sorted by number."""
    if not adr_dir.exists():
        return []

    records = []
    for entry in sorted(adr_dir.iterdir()):
        if entry.is_file() and entry.suffix == ".md" and not entry.name.startswith("README"):
            try:
                records.append(parse_adr_file(entry))
            except Exception:
                continue
    return records


def format_table(records: list) -> str:
    """Render plain text table."""
    if not records:
        return "No ADRs found."

    lines = []
    lines.append(f"{'#':<6} {'Status':<12} {'Date':<12} {'Title':<45} {'Supersedes'}")
    lines.append("-" * 85)
    for r in records:
        sup_info = ""
        if r["supersedes"]:
            sup_info = f"-> {r['supersedes']}"
        elif r["superseded_by"]:
            sup_info = f"by {r['superseded_by']}"

        lines.append(
            f"{r['number']:<6} {r['status']:<12} {r['date']:<12} {r['title'][:44]:<45} {sup_info}"
        )
    return "\n".join(lines)


def run_self_test() -> int:
    """Execute unit self-tests."""
    print("Running self-tests for list-adrs.py...")
    import tempfile

    with tempfile.TemporaryDirectory() as tmpdir:
        td = Path(tmpdir)
        adr1 = td / "0001-record-architecture-decisions.md"
        adr1.write_text(
            "# ADR-0001: Record Architecture Decisions\n\n"
            "| **Status** | Accepted |\n"
            "| **Date** | 2026-10-02 |\n"
            "| **Deciders** | Architecture Council |\n",
            encoding="utf-8",
        )

        res = find_adrs(td)
        assert len(res) == 1, "Expected 1 ADR"
        assert res[0]["number"] == "0001"
        assert res[0]["title"] == "Record Architecture Decisions"
        assert res[0]["status"] == "Accepted"
        assert res[0]["date"] == "2026-10-02"

        tbl = format_table(res)
        assert "0001" in tbl
        assert "Accepted" in tbl

    print("All self-tests passed successfully.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="List and summarize Architecture Decision Records (ADRs)."
    )
    parser.add_argument(
        "--dir",
        "-d",
        type=str,
        default="docs/adr",
        help="Target ADR directory (default: docs/adr).",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output as JSON.",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="Run self-tests and exit.",
    )

    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    adr_dir = Path(args.dir)
    records = find_adrs(adr_dir)

    if args.json:
        print(json.dumps(records, indent=2))
    else:
        print(format_table(records))

    return 0


if __name__ == "__main__":
    sys.exit(main())
