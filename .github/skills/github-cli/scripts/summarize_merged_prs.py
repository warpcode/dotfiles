#!/usr/bin/env python3
"""
summarize_merged_prs.py

Summarize pull requests merged on a specific date (default: today) into
business-friendly bullet points with emojis.

Usage:
    python3 summarize_merged_prs.py [--date YYYY-MM-DD] [--owner OWNER] [--repo REPO]
    python3 summarize_merged_prs.py --help

This script uses the GitHub GraphQL API via `gh` CLI to fetch merged PRs
and formats them for human consumption.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


# Emoji mapping for common PR types
EMOJI_MAP = {
    "feat": "✨",
    "feature": "✨",
    "fix": "🐛",
    "bug": "🐛",
    "hotfix": "🚑",
    "security": "🔒",
    "perf": "⚡",
    "performance": "⚡",
    "refactor": "♻️",
    "style": "🎨",
    "docs": "📝",
    "doc": "📝",
    "test": "✅",
    "tests": "✅",
    "chore": "🔧",
    "build": "📦",
    "ci": "🔄",
    "deploy": "🚀",
    "release": "🏷️",
    "revert": "⏪",
    "wip": "🚧",
    "config": "⚙️",
    "dependency": "📦",
    "deps": "📦",
}


def detect_pr_type(title: str) -> str:
    """Detect PR type from conventional commit prefix or keywords."""
    title_lower = title.lower()
    
    # Check conventional commit format: type(scope): summary
    match = re.match(r"^(\w+)(?:\([^)]+\))?:\s", title_lower)
    if match:
        prefix = match.group(1)
        if prefix in EMOJI_MAP:
            return prefix
    
    # Check for keywords in title
    for keyword, emoji in EMOJI_MAP.items():
        if keyword in title_lower:
            return keyword
    
    return "default"


def get_emoji_for_pr(title: str) -> str:
    """Get appropriate emoji for a PR title."""
    pr_type = detect_pr_type(title)
    return EMOJI_MAP.get(pr_type, "📋")


def sanitize_for_business(title: str, body: str = "") -> str:
    """Convert technical PR title/body into business-friendly language."""
    # Remove conventional commit prefix
    clean = re.sub(r"^\w+(?:\([^)]+\))?:\s*", "", title)
    
    # Common technical-to-business translations
    replacements = [
        (r"\brefactor\b", "improve"),
        (r"\boptimize\b", "speed up"),
        (r"\bmigrate\b", "move"),
        (r"\bdeprecate\b", "phase out"),
        (r"\bendpoint\b", "API endpoint"),
        (r"\bmiddleware\b", "middleware layer"),
        (r"\bauthentication\b", "login/security"),
        (r"\bauthorization\b", "permissions"),
        (r"\blatency\b", "response time"),
        (r"\bthroughput\b", "capacity"),
        (r"\bcrash\b", "stability issue"),
        (r"\berror\b", "issue"),
        (r"\bexception\b", "error"),
        (r"\bnull pointer\b", "crash"),
        (r"\bmemory leak\b", "memory issue"),
        (r"\bdeadlock\b", "freeze"),
        (r"\brace condition\b", "timing issue"),
    ]
    
    for pattern, replacement in replacements:
        clean = re.sub(pattern, replacement, clean, flags=re.IGNORECASE)
    
    # Capitalize first letter
    if clean:
        clean = clean[0].upper() + clean[1:]
    
    return clean


def fetch_merged_prs(owner: str, repo: str, date_str: str) -> list:
    """Fetch merged PRs for a specific date using GitHub GraphQL API."""
    # GraphQL query for merged PRs on a specific date
    query = """
    query($owner: String!, $repo: String!, $date: DateTime!, $limit: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequests(
          states: [MERGED]
          first: $limit
          orderBy: {field: UPDATED_AT, direction: DESC}
        ) {
          nodes {
            number
            title
            body
            url
            mergedAt
            author {
              login
            }
            baseRefName
            headRefName
            labels(first: 10) {
              nodes {
                name
              }
            }
          }
        }
      }
    }
    """
    
    # Build the date range for the query
    # We'll fetch a larger set and filter client-side for the specific date
    # since GraphQL doesn't easily support "merged on date X"
    
    cmd = [
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"owner={owner}",
        "-f", f"repo={repo}",
        "-F", "limit=100",
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        data = json.loads(result.stdout)
        
        prs = data.get("data", {}).get("repository", {}).get("pullRequests", {}).get("nodes", [])
        
        # Filter by merged date
        target_date = datetime.strptime(date_str, "%Y-%m-%d").date()
        filtered = []
        
        for pr in prs:
            merged_at = pr.get("mergedAt")
            if merged_at:
                merged_date = datetime.fromisoformat(merged_at.replace("Z", "+00:00")).date()
                if merged_date == target_date:
                    filtered.append(pr)
        
        return filtered
    
    except subprocess.CalledProcessError as e:
        print(f"Error fetching PRs: {e.stderr}", file=sys.stderr)
        return []
    except json.JSONDecodeError as e:
        print(f"Error parsing response: {e}", file=sys.stderr)
        return []


def format_pr_summary(pr: dict) -> str:
    """Format a single PR as a business-friendly bullet point."""
    title = pr.get("title", "")
    body = pr.get("body", "") or ""
    url = pr.get("url", "")
    author = pr.get("author", {}).get("login", "unknown")
    number = pr.get("number", 0)
    
    emoji = get_emoji_for_pr(title)
    business_title = sanitize_for_business(title, body)
    
    # Extract key info from body if available
    extra_info = ""
    if body:
        # Look for key phrases in body
        body_lower = body.lower()
        if "breaking" in body_lower or "breaking change" in body_lower:
            extra_info = " ⚠️ *Breaking change*"
        elif "migration" in body_lower:
            extra_info = " 🔄 *Includes migration*"
        elif "security" in body_lower or "vulnerability" in body_lower:
            extra_info = " 🔒 *Security fix*"
    
    return f"- {emoji} **#{number}**: {business_title} ([PR]({url})){extra_info}"


def main():
    parser = argparse.ArgumentParser(
        description="Summarize merged PRs for a given date",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 summarize_merged_prs.py                    # Today's merged PRs
  python3 summarize_merged_prs.py --date 2025-12-27  # Specific date
  python3 summarize_merged_prs.py --owner org --repo name  # Explicit repo
        """
    )
    parser.add_argument(
        "--date",
        default=datetime.now().strftime("%Y-%m-%d"),
        help="Date to summarize (YYYY-MM-DD), default: today"
    )
    parser.add_argument(
        "--owner",
        help="Repository owner (default: auto-detected from gh)"
    )
    parser.add_argument(
        "--repo",
        help="Repository name (default: auto-detected from gh)"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output raw JSON instead of formatted summary"
    )
    
    args = parser.parse_args()
    
    # Auto-detect owner/repo if not provided
    if not args.owner or not args.repo:
        try:
            repo_view = subprocess.run(
                ["gh", "repo", "view", "--json", "owner,name"],
                capture_output=True, text=True, check=True
            )
            repo_data = json.loads(repo_view.stdout)
            args.owner = args.owner or repo_data["owner"]["login"]
            args.repo = args.repo or repo_data["name"]
        except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError) as e:
            print("Error: Could not auto-detect repository. Use --owner and --repo.", file=sys.stderr)
            sys.exit(1)
    
    print(f"Fetching PRs merged on {args.date} from {args.owner}/{args.repo}...")
    
    prs = fetch_merged_prs(args.owner, args.repo, args.date)
    
    if args.json:
        print(json.dumps(prs, indent=2))
        return
    
    if not prs:
        print(f"No merged PRs found for {args.date}")
        return
    
    print(f"\n## Merged PRs for {args.date} ({len(prs)} total)\n")
    
    for pr in prs:
        print(format_pr_summary(pr))
    
    print()


if __name__ == "__main__":
    main()