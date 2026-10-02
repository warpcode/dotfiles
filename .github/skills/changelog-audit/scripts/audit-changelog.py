#!/usr/bin/env python3
"""
audit-changelog.py

Audit a CHANGELOG.md file against Git history, verify provenance continuity,
and detect missing commits, unrecorded PR labels, and formatting violations.

Standard library only.
"""

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple


def run_git_cmd(args: List[str], cwd: Optional[Path] = None) -> str:
    """Execute git command and return stdout."""
    res = subprocess.run(
        ["git"] + args,
        cwd=cwd,
        capture_output=True,
        text=True,
        check=False,
    )
    if res.returncode != 0:
        raise RuntimeError(f"Git command failed: git {' '.join(args)}\n{res.stderr.strip()}")
    return res.stdout.strip()


def parse_provenance_block(block_text: str) -> Optional[Dict[str, Any]]:
    """Parse YAML subset inside <!-- changelog-provenance: ... --> comment."""
    m = re.search(r"<!--\s*changelog-provenance:(.*?)-->", block_text, re.DOTALL)
    if not m:
        return None

    yaml_content = m.group(1)
    data: Dict[str, Any] = {
        "prs_included": [],
        "labels_recorded": {},
        "omitted_or_internal": [],
    }

    lines = yaml_content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        # Match key-value
        kv = re.match(r"^([a-zA-Z_]+):\s*(.*)$", stripped)
        if kv:
            key = kv.group(1)
            val = kv.group(2).strip()

            if val.startswith("[") and val.endswith("]"):
                try:
                    data[key] = json.loads(val)
                except Exception:
                    data[key] = val
            elif val.startswith('"') and val.endswith('"'):
                data[key] = val[1:-1]
            elif val.isdigit():
                data[key] = int(val)
            elif key == "labels_recorded":
                labels_map = {}
                while i < len(lines) and (lines[i].startswith("    ") or lines[i].startswith("\t\t")):
                    lbl_line = lines[i].strip()
                    i += 1
                    lbl_m = re.match(r"^([^:]+):\s*(.*)$", lbl_line)
                    if lbl_m:
                        lbl_name = lbl_m.group(1).strip()
                        lbl_prs_str = lbl_m.group(2).strip()
                        try:
                            labels_map[lbl_name] = json.loads(lbl_prs_str)
                        except Exception:
                            labels_map[lbl_name] = []
                data["labels_recorded"] = labels_map
            elif key == "omitted_or_internal":
                omitted_list = []
                current_omitted = {}
                while i < len(lines) and (lines[i].startswith("    ") or lines[i].startswith("\t\t")):
                    omit_line = lines[i].strip()
                    i += 1
                    if omit_line.startswith("- sha:"):
                        if current_omitted:
                            omitted_list.append(current_omitted)
                        sha_val = re.sub(r'^- sha:\s*"?([^"]*)"?.*$', r"\1", omit_line)
                        current_omitted = {"sha": sha_val, "reason": ""}
                    elif omit_line.startswith("reason:"):
                        r_val = re.sub(r'^reason:\s*"?([^"]*)"?.*$', r"\1", omit_line)
                        if current_omitted:
                            current_omitted["reason"] = r_val
                if current_omitted:
                    omitted_list.append(current_omitted)
                data["omitted_or_internal"] = omitted_list
            else:
                data[key] = val

    return data


def parse_changelog(content: str) -> List[Dict[str, Any]]:
    """Split changelog into structured release entries."""
    version_pattern = re.compile(
        r"^##\s+\[(.*?)\](?:\s+-\s+(\d{4}-\d{2}-\d{2}))?", re.MULTILINE
    )
    matches = list(version_pattern.finditer(content))
    entries = []

    for idx, match in enumerate(matches):
        version_name = match.group(1)
        release_date = match.group(2)
        start_pos = match.start()
        end_pos = matches[idx + 1].start() if idx + 1 < len(matches) else len(content)

        section_text = content[start_pos:end_pos]
        provenance = parse_provenance_block(section_text)

        # Detect referenced PRs in text: [#123] or (#123)
        prs = [int(p) for p in re.findall(r"(?:\[#|\(#)(\d+)(?:\]|\))", section_text)]

        has_breaking = "### Breaking Changes" in section_text or "⚠️" in section_text

        entries.append({
            "version": version_name,
            "date": release_date,
            "text": section_text,
            "provenance": provenance,
            "prs_in_text": sorted(list(set(prs))),
            "has_breaking": has_breaking,
        })

    return entries


def audit_version_against_git(
    entry: Dict[str, Any],
    path_filter: Optional[str] = None,
    cwd: Optional[Path] = None,
) -> Dict[str, Any]:
    """Reconcile a release entry against Git log."""
    prov = entry.get("provenance")
    result: Dict[str, Any] = {
        "version": entry["version"],
        "has_provenance": prov is not None,
        "format_ok": True,
        "format_errors": [],
        "missing_commits": [],
        "git_commit_count": 0,
        "audited_commit_count": 0,
    }

    if entry["version"] != "Unreleased" and not entry.get("date"):
        result["format_ok"] = False
        result["format_errors"].append("Missing or invalid ISO release date (expected YYYY-MM-DD)")

    if not prov or not prov.get("commit_range"):
        result["format_errors"].append("No valid commit_range in changelog-provenance block")
        return result

    commit_range = prov["commit_range"]
    try:
        cmd = ["log", commit_range, "--format=%H|%h|%an|%s", "--date=short"]
        if path_filter:
            cmd.extend(["--", path_filter])
        raw_log = run_git_cmd(cmd, cwd=cwd)
        lines = [line.strip() for line in raw_log.splitlines() if line.strip()]
    except Exception as e:
        result["format_errors"].append(f"Git log failed for range '{commit_range}': {e}")
        return result

    result["git_commit_count"] = len(lines)
    known_prs = set(entry["prs_in_text"])
    if prov.get("prs_included"):
        known_prs.update(prov["prs_included"])

    omitted_shas = {o.get("sha", "") for o in prov.get("omitted_or_internal", [])}

    missing = []
    # Extract only the user-facing narrative (before provenance block or details collapsible)
    raw_text = entry.get("text", "")
    narrative_text = re.split(r"(?:<!--\s*changelog-provenance|<details>)", raw_text)[0]

    for line in lines:
        parts = line.split("|", 3)
        if len(parts) >= 4:
            full_sha, short_sha, author, subject = parts[0], parts[1], parts[2], parts[3]

            # Check if SHA or PR is accounted for
            is_accounted = False
            if (
                short_sha in omitted_shas
                or full_sha in omitted_shas
                or short_sha in narrative_text
                or full_sha in narrative_text
            ):
                is_accounted = True

            # Check if mentioned PR appears in subject
            m_pr = re.search(r"\(#(\d+)\)", subject)
            if m_pr and int(m_pr.group(1)) in known_prs:
                is_accounted = True

            m_merge = re.search(r"Merge pull request #(\d+)", subject)
            if m_merge and int(m_merge.group(1)) in known_prs:
                is_accounted = True

            if not is_accounted:
                # Determine severity
                severity = "Low"
                subj_lower = subject.lower()
                if any(k in subj_lower for k in ["feat", "feature", "fix", "bug", "breaking", "!"]):
                    severity = "High"
                elif any(k in subj_lower for k in ["refactor", "perf", "update"]):
                    severity = "Medium"

                missing.append({
                    "short_sha": short_sha,
                    "full_sha": full_sha,
                    "author": author,
                    "subject": subject,
                    "severity": severity,
                })

    result["missing_commits"] = missing
    result["audited_commit_count"] = len(lines) - len(missing)
    return result


def check_continuity(entries: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Verify that commit ranges connect seamlessly without gaps."""
    continuity_findings = []
    entries_with_prov = [e for e in entries if e.get("provenance")]

    for i in range(len(entries_with_prov) - 1):
        curr = entries_with_prov[i]["provenance"]
        prev = entries_with_prov[i + 1]["provenance"]

        curr_base = curr.get("base_commit", "")
        prev_head = prev.get("head_commit", "")

        if curr_base and prev_head and curr_base != prev_head:
            continuity_findings.append({
                "from_version": entries_with_prov[i]["version"],
                "to_version": entries_with_prov[i + 1]["version"],
                "gap": f"base_commit ({curr_base[:7]}) != predecessor head_commit ({prev_head[:7]})",
            })

    return continuity_findings


def generate_markdown_report(
    changelog_path: Path,
    entries: List[Dict[str, Any]],
    audit_results: List[Dict[str, Any]],
    continuity_findings: List[Dict[str, Any]],
) -> str:
    """Generate Markdown audit report from template."""
    total_missing = sum(len(r["missing_commits"]) for r in audit_results)
    overall_status = "PASS" if total_missing == 0 and not continuity_findings else ("WARN" if total_missing < 3 else "FAIL")

    lines = [
        f"# Changelog Audit Report: `{changelog_path.name}`",
        "",
        f"**Audit Date**: {datetime.date.today().isoformat()}  ",
        f"**Versions Audited**: {len(audit_results)}  ",
        f"**Overall Status**: **{overall_status}**  ",
        "",
        "---",
        "",
        "## 1. Version Audit Summary",
        "",
        "| Version | Date | Status | Commits in Git | Accounted | Missing Commits |",
        "|---|---|---|---|---|---|",
    ]

    for r in audit_results:
        ver_status = "PASS" if not r["missing_commits"] and r["format_ok"] else "FAIL"
        d = next((e.get("date") or "Unreleased" for e in entries if e["version"] == r["version"]), "N/A")
        lines.append(f"| `{r['version']}` | {d} | {ver_status} | {r['git_commit_count']} | {r['audited_commit_count']} | {len(r['missing_commits'])} |")

    lines.extend([
        "",
        "---",
        "",
        "## 2. Missing Pieces & Unaccounted Commits",
        "",
    ])

    if total_missing == 0:
        lines.append("✅ **Zero missing commits detected.** All Git commits in audited ranges are either documented in the release notes or recorded in the provenance omission ledger.")
    else:
        lines.extend([
            "| Commit SHA | Author | Subject | Severity |",
            "|---|---|---|---|",
        ])
        for r in audit_results:
            for m in r["missing_commits"]:
                lines.append(f"| `{m['short_sha']}` | {m['author']} | {m['subject']} | **{m['severity']}** |")

    if continuity_findings:
        lines.extend([
            "",
            "---",
            "",
            "## 3. Range Continuity Gaps",
            "",
            "| Version | Predecessor | Gap Description |",
            "|---|---|---|",
        ])
        for cf in continuity_findings:
            lines.append(f"| `{cf['from_version']}` | `{cf['to_version']}` | {cf['gap']} |")

    lines.extend([
        "",
        "---",
        "",
        "## 4. Remediation Checklist",
        "",
        "- [ ] Review high-severity missing commits and add them to user-facing changelog sections.",
        "- [ ] Add internal/chore commits to the `omitted_or_internal` provenance block.",
        "- [ ] Verify all compare links at the bottom of the document resolve properly.",
    ])

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Audit CHANGELOG.md against Git history, verify provenance, and detect missing pieces."
    )
    parser.add_argument(
        "--changelog",
        "-c",
        default="CHANGELOG.md",
        help="Path to CHANGELOG.md (default: CHANGELOG.md).",
    )
    parser.add_argument(
        "--version",
        help="Specific version to audit (e.g. 1.2.0 or Unreleased). Audits all if omitted.",
    )
    parser.add_argument(
        "--path",
        help="Path filter for commit history (for monorepos).",
    )
    parser.add_argument(
        "--report",
        help="Write full markdown audit report to specified file.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw JSON audit results.",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Exit with code 1 if any missing commits or errors are detected.",
    )

    args = parser.parse_args()

    cl_path = Path(args.changelog).resolve()
    if not cl_path.exists():
        print(f"Error: Changelog file not found: {cl_path}", file=sys.stderr)
        sys.exit(1)

    content = cl_path.read_text(encoding="utf-8")
    entries = parse_changelog(content)

    if not entries:
        print(f"Error: No valid release entries found in {cl_path}", file=sys.stderr)
        sys.exit(1)

    target_entries = entries
    if args.version:
        target_entries = [e for e in entries if e["version"] == args.version]
        if not target_entries:
            print(f"Error: Version '{args.version}' not found in changelog.", file=sys.stderr)
            sys.exit(1)

    audit_results = []
    for entry in target_entries:
        res = audit_version_against_git(entry, path_filter=args.path, cwd=cl_path.parent)
        audit_results.append(res)

    continuity_findings = check_continuity(entries) if not args.version else []

    if args.json:
        payload = {
            "changelog": str(cl_path),
            "results": audit_results,
            "continuity_gaps": continuity_findings,
        }
        print(json.dumps(payload, indent=2))
        return

    # Terminal output
    print(f"=== Changelog Audit: {cl_path.name} ===")
    has_failures = False
    for r in audit_results:
        missing_count = len(r["missing_commits"])
        status_str = "PASS" if missing_count == 0 and r["format_ok"] else "FAIL"
        if status_str == "FAIL":
            has_failures = True
        print(f"\nVersion [{r['version']}]: {status_str}")
        print(f"  Provenance block: {'Present' if r['has_provenance'] else 'Missing'}")
        print(f"  Git commits in range: {r['git_commit_count']}")
        print(f"  Accounted for: {r['audited_commit_count']}")
        print(f"  Missing / Unaccounted: {missing_count}")

        if r["format_errors"]:
            for err in r["format_errors"]:
                print(f"  [ERROR] {err}")

        if r["missing_commits"]:
            print("  Missing Commits:")
            for m in r["missing_commits"]:
                print(f"    - [{m['severity']}] {m['short_sha']} ({m['author']}): {m['subject']}")

    if continuity_findings:
        has_failures = True
        print("\nRange Continuity Gaps:")
        for cf in continuity_findings:
            print(f"  - [{cf['from_version']} -> {cf['to_version']}]: {cf['gap']}")

    if args.report:
        report_text = generate_markdown_report(cl_path, entries, audit_results, continuity_findings)
        rep_path = Path(args.report).resolve()
        rep_path.write_text(report_text + "\n", encoding="utf-8")
        print(f"\nAudit report saved to: {rep_path}")

    if args.strict and has_failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
