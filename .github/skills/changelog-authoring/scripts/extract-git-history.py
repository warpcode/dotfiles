#!/usr/bin/env python3
"""
extract-git-history.py

Extract git commit history, parse PR numbers, resolve associated labels,
group changes according to Keep a Changelog standards, and generate
provenance metadata records for full auditability.

Standard library only. Optional integration with `gh` CLI for PR labels.
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
    """Execute a git command and return stripped stdout."""
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


def detect_repo_slug(cwd: Optional[Path] = None) -> str:
    """Extract owner/repo slug from git remote."""
    try:
        url = run_git_cmd(["remote", "get-url", "origin"], cwd=cwd)
        m = re.search(r"github\.com[:/]([^/]+)/([^/\.]+)(?:\.git)?", url)
        if m:
            return f"{m.group(1)}/{m.group(2)}"
    except Exception:
        pass
    return "owner/repo"


def get_latest_tag(cwd: Optional[Path] = None) -> Optional[str]:
    """Find the most recent git tag."""
    try:
        tag = run_git_cmd(["describe", "--tags", "--abbrev=0"], cwd=cwd)
        if tag:
            return tag
    except Exception:
        pass

    try:
        tags = run_git_cmd(["tag", "--sort=-version:refname"], cwd=cwd).splitlines()
        if tags and tags[0].strip():
            return tags[0].strip()
    except Exception:
        pass

    return None


def get_first_commit(cwd: Optional[Path] = None) -> str:
    """Get the initial root commit in git history."""
    return run_git_cmd(["rev-list", "--max-parents=0", "HEAD"], cwd=cwd).splitlines()[0]


def get_commit_sha(ref: str, cwd: Optional[Path] = None) -> str:
    """Resolve a git ref to a full 40-character SHA."""
    return run_git_cmd(["rev-parse", ref], cwd=cwd)


def extract_pr_number(subject: str, body: str) -> Optional[int]:
    """Detect PR number from subject or merge message."""
    # Pattern 1: Squash merge trailing (#123)
    m = re.search(r"\(#(\d+)\)\s*$", subject)
    if m:
        return int(m.group(1))

    # Pattern 2: Merge pull request #123 from ...
    m = re.search(r"Merge pull request #(\d+)", subject)
    if m:
        return int(m.group(1))

    # Pattern 3: Merge PR #123
    m = re.search(r"Merge PR #(\d+)", subject, re.IGNORECASE)
    if m:
        return int(m.group(1))

    # Pattern 4: Embedded in body: PR: #123 or Closes #123
    m = re.search(r"(?:PR|Pull Request|Closes|Fixes)\s*#(\d+)", body, re.IGNORECASE)
    if m:
        return int(m.group(1))

    return None


def fetch_gh_labels_for_pr(pr_num: int, repo_slug: str, cache: Dict[int, List[str]]) -> List[str]:
    """Fetch GitHub labels using gh CLI if available."""
    if pr_num in cache:
        return cache[pr_num]

    try:
        cmd = ["gh", "pr", "view", str(pr_num), "--json", "labels"]
        if repo_slug and repo_slug != "owner/repo":
            cmd.extend(["--repo", repo_slug])

        res = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if res.returncode == 0:
            data = json.loads(res.stdout)
            labels = [lbl.get("name", "") for lbl in data.get("labels", []) if lbl.get("name")]
            cache[pr_num] = labels
            return labels
    except Exception:
        pass

    cache[pr_num] = []
    return []


def parse_conventional_commit(subject: str) -> Tuple[Optional[str], Optional[str], bool, str]:
    """
    Parse conventional commit message into (type, scope, is_breaking, clean_message).
    Example: 'feat(parser)!: add json streaming' -> ('feat', 'parser', True, 'add json streaming')
    """
    pattern = r"^([a-zA-Z0-9_-]+)(?:\(([^\)]+)\))?(!)?:\s*(.*)$"
    m = re.match(pattern, subject.strip())
    if m:
        c_type = m.group(1).lower()
        scope = m.group(2)
        breaking = bool(m.group(3))
        message = m.group(4).strip()
        return c_type, scope, breaking, message

    return None, None, False, subject.strip()


def classify_commit(
    subject: str,
    body: str,
    labels: List[str],
) -> Tuple[str, bool, str, Optional[str]]:
    """
    Classify commit into category and determine whether it is user-facing or internal.
    Returns: (category, is_breaking, clean_desc, scope)
    Categories: 'Breaking Changes', 'Added', 'Changed', 'Deprecated', 'Removed', 'Fixed', 'Security', 'Internal'
    """
    lower_labels = [lbl.lower() for lbl in labels]
    is_breaking = False
    if "breaking" in lower_labels or "breaking-change" in lower_labels:
        is_breaking = True

    if "BREAKING CHANGE:" in body or "BREAKING-CHANGE:" in body:
        is_breaking = True

    c_type, scope, c_breaking, clean_msg = parse_conventional_commit(subject)
    if c_breaking:
        is_breaking = True

    # Strip PR suffix from description if present: 'Add feature (#123)' -> 'Add feature'
    clean_msg = re.sub(r"\s*\(#\d+\)\s*$", "", clean_msg).strip()

    # Determine category
    if is_breaking:
        return "Breaking Changes", True, clean_msg, scope

    if "security" in lower_labels or (c_type and c_type in ["sec", "security"]):
        return "Security", False, clean_msg, scope

    if "bug" in lower_labels or "fix" in lower_labels or (c_type and c_type in ["fix", "bug"]):
        return "Fixed", False, clean_msg, scope

    if "feature" in lower_labels or "enhancement" in lower_labels or (c_type and c_type in ["feat", "feature"]):
        return "Added", False, clean_msg, scope

    if "deprecation" in lower_labels or (c_type and c_type in ["deprecate", "deprecated"]):
        return "Deprecated", False, clean_msg, scope

    if "removal" in lower_labels or (c_type and c_type in ["remove", "removed", "drop"]):
        return "Removed", False, clean_msg, scope

    if c_type in ["perf", "refactor"]:
        return "Changed", False, clean_msg, scope

    if c_type in ["chore", "ci", "test", "build", "style", "docs"]:
        return "Internal", False, clean_msg, scope

    # Fallback heuristic based on commit subject prefix words
    subj_lower = clean_msg.lower()
    if subj_lower.startswith(("fix", "resolve", "patch", "prevent")):
        return "Fixed", False, clean_msg, scope
    if subj_lower.startswith(("add", "introduce", "implement", "support", "new")):
        return "Added", False, clean_msg, scope
    if subj_lower.startswith(("update", "improve", "refactor", "optimize", "perf")):
        return "Changed", False, clean_msg, scope
    if subj_lower.startswith(("deprecate")):
        return "Deprecated", False, clean_msg, scope
    if subj_lower.startswith(("remove", "delete", "drop")):
        return "Removed", False, clean_msg, scope
    if subj_lower.startswith(("chore", "ci", "test", "lint")):
        return "Internal", False, clean_msg, scope

    # Default unclassified user-facing to Changed
    return "Changed", False, clean_msg, scope


def fetch_git_commits(
    from_ref: Optional[str],
    to_ref: str,
    path_filter: Optional[str] = None,
    cwd: Optional[Path] = None,
) -> List[Dict[str, Any]]:
    """Retrieve commits between from_ref and to_ref."""
    if not from_ref:
        base_tag = get_latest_tag(cwd)
        from_ref = base_tag if base_tag else get_first_commit(cwd)

    rev_range = f"{from_ref}..{to_ref}"
    delimiter = "---RECORD_SPLIT---"
    field_delim = "---FIELD_SPLIT---"
    git_format = f"%H{field_delim}%h{field_delim}%an{field_delim}%ad{field_delim}%s{field_delim}%b{delimiter}"

    cmd = ["log", rev_range, f"--format={git_format}", "--date=short"]
    if path_filter:
        cmd.extend(["--", path_filter])

    raw_output = run_git_cmd(cmd, cwd=cwd)
    if not raw_output:
        return []

    records = raw_output.split(delimiter)
    commits = []
    for rec in records:
        rec = rec.strip()
        if not rec:
            continue
        parts = rec.split(field_delim)
        if len(parts) >= 5:
            full_sha = parts[0].strip()
            short_sha = parts[1].strip()
            author = parts[2].strip()
            date = parts[3].strip()
            subject = parts[4].strip()
            body = parts[5].strip() if len(parts) > 5 else ""
            commits.append({
                "full_sha": full_sha,
                "short_sha": short_sha,
                "author": author,
                "date": date,
                "subject": subject,
                "body": body,
            })

    return commits


def build_provenance_and_changelog(
    commits: List[Dict[str, Any]],
    from_ref: str,
    to_ref: str,
    repo_slug: str,
    version_label: str,
    fetch_gh_labels: bool = True,
    cwd: Optional[Path] = None,
) -> Tuple[str, Dict[str, Any]]:
    """Build changelog markdown draft and provenance dictionary."""
    base_sha = get_commit_sha(from_ref, cwd=cwd)
    head_sha = get_commit_sha(to_ref, cwd=cwd)
    today_str = datetime.date.today().isoformat()

    categories: Dict[str, List[Dict[str, Any]]] = {
        "Breaking Changes": [],
        "Added": [],
        "Changed": [],
        "Deprecated": [],
        "Removed": [],
        "Fixed": [],
        "Security": [],
    }
    omitted_list: List[Dict[str, str]] = []
    prs_included: Set[int] = set()
    labels_recorded: Dict[str, List[int]] = {}

    label_cache: Dict[int, List[str]] = {}

    for c in commits:
        pr_num = extract_pr_number(c["subject"], c["body"])
        pr_labels: List[str] = []
        if pr_num:
            if fetch_gh_labels:
                pr_labels = fetch_gh_labels_for_pr(pr_num, repo_slug, label_cache)
            if not pr_labels:
                # Infer label from conventional commit prefix
                c_type, scope, _, _ = parse_conventional_commit(c["subject"])
                if c_type:
                    pr_labels.append(c_type)
                if scope:
                    pr_labels.append(scope)

        cat, is_breaking, clean_desc, scope = classify_commit(c["subject"], c["body"], pr_labels)

        entry = {
            "short_sha": c["short_sha"],
            "full_sha": c["full_sha"],
            "desc": clean_desc,
            "pr_num": pr_num,
            "author": c["author"],
            "scope": scope,
        }

        if cat == "Internal":
            omitted_list.append({
                "sha": c["short_sha"],
                "reason": c["subject"],
            })
        else:
            categories[cat].append(entry)
            if pr_num:
                prs_included.add(pr_num)
                for lbl in pr_labels:
                    labels_recorded.setdefault(lbl, [])
                    if pr_num not in labels_recorded[lbl]:
                        labels_recorded[lbl].append(pr_num)

    compare_url = f"https://github.com/{repo_slug}/compare/{from_ref}...{to_ref}"

    provenance_data = {
        "version": version_label,
        "date": today_str if version_label != "Unreleased" else None,
        "commit_range": f"{from_ref}..{to_ref}",
        "base_commit": base_sha,
        "head_commit": head_sha,
        "compare_url": compare_url,
        "commit_count": len(commits),
        "prs_included": sorted(list(prs_included)),
        "labels_recorded": {k: sorted(v) for k, v in sorted(labels_recorded.items())},
        "omitted_or_internal": omitted_list,
    }

    # Format Markdown
    md_lines = []
    if version_label == "Unreleased":
        md_lines.append("## [Unreleased]")
    else:
        md_lines.append(f"## [{version_label}] - {today_str}")

    md_lines.append("")

    for cat_name, entries in categories.items():
        if not entries:
            continue
        if cat_name == "Breaking Changes":
            md_lines.append("### Breaking Changes ⚠️")
        else:
            md_lines.append(f"### {cat_name}")

        for e in entries:
            scope_prefix = f"**{e['scope']}**: " if e["scope"] else ""
            ref_suffix = ""
            if e["pr_num"]:
                ref_suffix = f" ([#{e['pr_num']}](https://github.com/{repo_slug}/pull/{e['pr_num']}))"
            else:
                ref_suffix = f" ([`{e['short_sha']}`](https://github.com/{repo_slug}/commit/{e['full_sha']}))"
            md_lines.append(f"- {scope_prefix}{e['desc']}{ref_suffix}")
        md_lines.append("")

    # Provenance YAML block inside HTML comment
    yaml_lines = [
        "<!--",
        "changelog-provenance:",
        f"  version: \"{provenance_data['version']}\"",
    ]
    if provenance_data["date"]:
        yaml_lines.append(f"  date: \"{provenance_data['date']}\"")
    yaml_lines.extend([
        f"  commit_range: \"{provenance_data['commit_range']}\"",
        f"  base_commit: \"{provenance_data['base_commit']}\"",
        f"  head_commit: \"{provenance_data['head_commit']}\"",
        f"  compare_url: \"{provenance_data['compare_url']}\"",
        f"  commit_count: {provenance_data['commit_count']}",
        f"  prs_included: {json.dumps(provenance_data['prs_included'])}",
        "  labels_recorded:",
    ])
    for lbl, prs in provenance_data["labels_recorded"].items():
        yaml_lines.append(f"    {lbl}: {json.dumps(prs)}")

    yaml_lines.append("  omitted_or_internal:")
    for omitted in provenance_data["omitted_or_internal"]:
        safe_reason = omitted['reason'].replace('"', '\\"')
        yaml_lines.append(f"    - sha: \"{omitted['sha']}\"")
        yaml_lines.append(f"      reason: \"{safe_reason}\"")
    yaml_lines.append("-->")

    md_lines.extend(yaml_lines)
    md_lines.append("")

    # Collapsible human-readable audit section
    md_lines.extend([
        "<details>",
        f"<summary><b>Release Provenance & Audit Trail</b> (commit range: <code>{from_ref}..{to_ref}</code>, {len(commits)} commits)</summary>",
        "",
        f"- **Commit Range**: [`{commits[-1]['short_sha'] if commits else 'base'}...{commits[0]['short_sha'] if commits else 'head'}`]({compare_url}) ({len(commits)} total commits)",
        "- **PRs & Labels**:",
    ])
    if prs_included:
        for pr_id in sorted(prs_included):
            pr_lbls = [k for k, v in provenance_data["labels_recorded"].items() if pr_id in v]
            lbl_str = f" `[{', '.join(pr_lbls)}]`" if pr_lbls else ""
            md_lines.append(f"  - #{pr_id}{lbl_str}")
    else:
        md_lines.append("  - (No pull requests detected in range)")

    md_lines.append(f"- **Internal / Filtered Commits** ({len(omitted_list)} total):")
    for o in omitted_list[:10]:
        md_lines.append(f"  - `{o['sha']}` {o['reason']}")
    if len(omitted_list) > 10:
        md_lines.append(f"  - *(... and {len(omitted_list) - 10} more audited internal commits)*")

    md_lines.extend([
        "</details>",
        "",
    ])

    return "\n".join(md_lines), provenance_data


def main():
    parser = argparse.ArgumentParser(
        description="Extract git commit history and generate Keep a Changelog drafts with provenance records."
    )
    parser.add_argument(
        "--from-ref",
        help="Base git reference/tag (default: latest tag).",
    )
    parser.add_argument(
        "--to-ref",
        default="HEAD",
        help="Target git reference (default: HEAD).",
    )
    parser.add_argument(
        "--version",
        default="Unreleased",
        help="Target release version name (default: Unreleased).",
    )
    parser.add_argument(
        "--repo",
        help="GitHub repo slug (owner/repo). Auto-detected if omitted.",
    )
    parser.add_argument(
        "--path",
        help="Path filter for commit history (useful for monorepos).",
    )
    parser.add_argument(
        "--no-gh",
        action="store_true",
        help="Skip querying gh CLI for PR labels.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw structured JSON provenance instead of Markdown.",
    )
    parser.add_argument(
        "--output",
        "-o",
        help="Write output to filepath instead of stdout.",
    )

    args = parser.parse_args()

    repo_slug = args.repo or detect_repo_slug()
    base_ref = args.from_ref or get_latest_tag()
    if not base_ref:
        base_ref = get_first_commit()

    commits = fetch_git_commits(
        from_ref=base_ref,
        to_ref=args.to_ref,
        path_filter=args.path,
    )

    md_output, prov_data = build_provenance_and_changelog(
        commits=commits,
        from_ref=base_ref,
        to_ref=args.to_ref,
        repo_slug=repo_slug,
        version_label=args.version,
        fetch_gh_labels=not args.no_gh,
    )

    out_content = json.dumps(prov_data, indent=2) if args.json else md_output

    if args.output:
        p = Path(args.output).resolve()
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(out_content + "\n", encoding="utf-8")
        print(f"Generated changelog draft at: {p} ({len(commits)} commits, range: {base_ref}..{args.to_ref})")
    else:
        print(out_content)


if __name__ == "__main__":
    main()
