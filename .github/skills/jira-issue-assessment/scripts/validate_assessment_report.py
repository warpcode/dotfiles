#!/usr/bin/env python3
"""Validate that a Jira assessment report meets the skill's structural coverage gate."""

import argparse
import re
import sys
from pathlib import Path
from typing import List, Tuple


REQUIRED_HEADINGS = [
    "Project Progress",
    "Remaining Issues",
    "Requirement Assessment",
    "Findings",
    "Open Questions And Evidence Gaps",
    "Pull Requests And Validation",
    "Conclusion",
]

REQUIRED_REQUIREMENT_SUBHEADINGS = [
    "Completed / Met in Source",
    "Partially Met",
    "Incomplete / Unverified",
]

REQUIRED_REQUIREMENT_COLUMNS = [
    "Issue",
    "Requirement or acceptance criterion",
    "Code visibility",
    "Implementation status",
    "Verification status",
    "Evidence type",
    "Owner / implementing PR",
    "Evidence",
    "Release gate",
    "Remaining action",
]


def section_bounds(lines: List[str], heading: str) -> Tuple[int, int]:
    start = next((index for index, line in enumerate(lines) if line == f"## {heading}"), -1)
    if start < 0:
        return -1, -1
    end = next(
        (index for index in range(start + 1, len(lines)) if lines[index].startswith("## ")),
        len(lines),
    )
    return start, end


def subsection_bounds(
    lines: List[str], parent_start: int, parent_end: int, heading: str
) -> Tuple[int, int]:
    start = next(
        (
            index
            for index in range(parent_start + 1, parent_end)
            if lines[index] == f"### {heading}"
        ),
        -1,
    )
    if start < 0:
        return -1, -1
    end = next(
        (
            index
            for index in range(start + 1, parent_end)
            if lines[index].startswith("### ")
        ),
        parent_end,
    )
    return start, end


def table_rows(lines: List[str], header_prefix: str | None = None) -> List[str]:
    rows = []
    for line in lines:
        if not line.startswith("|") or re.fullmatch(r"\|[ -:|]+\|", line):
            continue
        if header_prefix is not None and line.startswith(header_prefix):
            continue
        rows.append(line)
    return rows


def table_header(lines: List[str], header_prefix: str) -> str | None:
    return next((line for line in lines if line.startswith(header_prefix)), None)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate the structure and criterion coverage of a Jira assessment report."
    )
    parser.add_argument("report", type=Path, help="Markdown report produced by jira-issue-assessment")
    parser.add_argument(
        "--expected-issue",
        action="append",
        default=[],
        metavar="KEY",
        help="Issue key that must appear in Requirement Assessment; repeat for every in-scope issue",
    )
    parser.add_argument(
        "--criterion-count",
        type=int,
        default=None,
        help="Exact number of criterion rows extracted into the pre-report matrix",
    )
    parser.add_argument(
        "--require-figma-evidence",
        action="store_true",
        help="Require Figma and MCP evidence in the report",
    )
    args = parser.parse_args()

    if not args.report.is_file():
        parser.error(f"Report not found: {args.report}")

    lines = args.report.read_text(encoding="utf-8").splitlines()
    errors = []
    heading_indexes = []
    for heading in REQUIRED_HEADINGS:
        start, _ = section_bounds(lines, heading)
        if start < 0:
            errors.append(f"Missing required heading: ## {heading}")
        else:
            heading_indexes.append(start)
    if heading_indexes != sorted(heading_indexes):
        errors.append("Required headings are not in template order")

    requirement_start, requirement_end = section_bounds(lines, "Requirement Assessment")
    requirement_rows = []
    if requirement_start >= 0:
        subsection_indexes = []
        for subsection in REQUIRED_REQUIREMENT_SUBHEADINGS:
            start, end = subsection_bounds(lines, requirement_start, requirement_end, subsection)
            if start < 0:
                errors.append(f"Missing required subsection: ### {subsection}")
            else:
                subsection_indexes.append(start)
                header = table_header(
                    lines[start + 1:end],
                    "| Issue | Requirement or acceptance criterion | Code visibility |",
                )
                if header is None:
                    errors.append(f"Missing requirement table header in ### {subsection}")
                else:
                    missing_columns = [column for column in REQUIRED_REQUIREMENT_COLUMNS if column not in header]
                    if missing_columns:
                        errors.append(
                            f"Missing requirement columns in ### {subsection}: {', '.join(missing_columns)}"
                        )
                requirement_rows.extend(
                    table_rows(
                        lines[start + 1:end],
                        header_prefix="| Issue | Requirement or acceptance criterion | Code visibility |",
                    )
                )
        if subsection_indexes != sorted(subsection_indexes):
            errors.append("Requirement Assessment subsections are not in template order")
        for issue_key in args.expected_issue:
            if not any(issue_key in row for row in requirement_rows):
                errors.append(f"Missing Requirement Assessment subsection row for {issue_key}")
        if args.criterion_count is not None and len(requirement_rows) != args.criterion_count:
            errors.append(
                f"Requirement row count is {len(requirement_rows)}; expected {args.criterion_count}"
            )
        if any("Child/subtasks" in row for row in requirement_rows):
            errors.append("Requirement Assessment collapses issue keys into Child/subtasks")

    remaining_start, remaining_end = section_bounds(lines, "Remaining Issues")
    if remaining_start >= 0 and any(
        "Child/subtasks" in row for row in table_rows(lines[remaining_start + 1:remaining_end])
    ):
        errors.append("Remaining Issues collapses issue keys into Child/subtasks")

    if args.require_figma_evidence:
        report_text = "\n".join(lines).lower()
        if "figma" not in report_text or "mcp" not in report_text:
            errors.append("Missing Figma MCP evidence")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)

    print("Assessment report coverage: PASS")
    print(f"- Requirement rows: {len(requirement_rows)}")
    print(f"- In-scope issue keys checked: {len(args.expected_issue)}")
    print(f"- Figma MCP evidence required: {'yes' if args.require_figma_evidence else 'no'}")


if __name__ == "__main__":
    main()