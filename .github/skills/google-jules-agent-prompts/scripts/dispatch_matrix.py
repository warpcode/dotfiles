#!/usr/bin/env python3
"""Batch dispatch Jules agents across repositories.

Dynamically discovers authorized repositories from Jules API and identifies
active repositories (sessions created/updated in the last month) as defaults.

Usage:
    python3 dispatch_matrix.py [--repos REPO ...] [--agents AGENT ...] [--require-approval]
"""
import argparse
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Tuple

SKILL_DIR = Path(__file__).resolve().parent.parent
JULES_API_DIR = SKILL_DIR.parent / "google-jules-api"
JULES_CLI = JULES_API_DIR / "scripts" / "main.py"
BUILD_PROMPTS = SKILL_DIR / "scripts" / "build_prompts.py"

# Add google-jules-api to sys.path for direct client integration
if (JULES_API_DIR / "scripts").exists():
    sys.path.insert(0, str(JULES_API_DIR / "scripts"))

try:
    from jules.auth import resolve_jules_api_key
    from jules.client import JulesClient
    from jules.utils import parse_iso_datetime
except ImportError:
    resolve_jules_api_key = None  # type: ignore
    JulesClient = None  # type: ignore
    parse_iso_datetime = None  # type: ignore

DEFAULT_AGENTS = [
    "bolt",
    "sentinel",
    "test-smith",
    "workflow-warden",
    "docs-auditor",
    "ratchet",
    "flake-hunter",
    "release-scribe",
]


def get_jules_client() -> Any:
    if JulesClient is None or resolve_jules_api_key is None:
        sys.exit("Error: Could not import Jules modules from google-jules-api.")
    api_key = resolve_jules_api_key()
    if not api_key:
        sys.exit("Error: Jules API key not found. Configure JULES_API_KEY in the protected environment.")
    try:
        return JulesClient(api_key=api_key)
    except Exception as e:
        sys.exit(f"Error initializing JulesClient: {e}")


def fetch_connected_sources(client: Any) -> Dict[str, Dict[str, Any]]:
    """Fetch all connected repository sources and map repo_id -> metadata."""
    sources_map: Dict[str, Dict[str, Any]] = {}
    page_token = None
    while True:
        res = client.list_sources(page_size=50, page_token=page_token)
        for s in res.get("sources", []):
            name = s.get("name", "").removeprefix("sources/")
            sid = s.get("id") or name
            repo_info = s.get("githubRepo", {})
            default_branch = repo_info.get("defaultBranch", {}).get("displayName", "main")
            sources_map[sid] = {
                "name": name,
                "id": sid,
                "default_branch": default_branch,
                "is_private": repo_info.get("isPrivate", False),
            }
        page_token = res.get("nextPageToken")
        if not page_token:
            break
    return sources_map


def discover_active_repos(client: Any, sources_map: Dict[str, Dict[str, Any]], days_active: int = 30) -> List[Tuple[str, str]]:
    """Query recent Jules sessions to identify repos active in the last `days_active` days."""
    now = datetime.now(timezone.utc)
    active_repo_ids: set[str] = set()

    page_token = None
    max_pages = 5  # Scan up to 250 recent sessions for activity in the past month
    for _ in range(max_pages):
        res = client.list_sessions(page_size=50, page_token=page_token, filter_expr="archived=false")
        sessions = res.get("sessions", [])
        if not sessions:
            break

        reached_cutoff = False
        for s in sessions:
            source_ctx = s.get("sourceContext", {})
            source_name = source_ctx.get("source", "").removeprefix("sources/")
            if not source_name:
                continue

            created_str = s.get("createTime") or s.get("updateTime")
            if created_str:
                try:
                    dt = parse_iso_datetime(created_str)
                    age_days = (now - dt).total_seconds() / 86400.0
                    if age_days <= days_active:
                        active_repo_ids.add(source_name)
                    else:
                        reached_cutoff = True
                except Exception:
                    pass

        page_token = res.get("nextPageToken")
        if not page_token or reached_cutoff:
            break

    # Resolve active repos with their default branches
    active_sources: List[Tuple[str, str]] = []
    for sid in sorted(active_repo_ids):
        # Match against known connected sources
        matched_source = sources_map.get(sid)
        if not matched_source:
            # Fallback search by normalized name
            for k, v in sources_map.items():
                if k.lower() == sid.lower() or v["name"].lower() == sid.lower():
                    matched_source = v
                    break

        branch = matched_source["default_branch"] if matched_source else "main"
        active_sources.append((sid, branch))

    return active_sources


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Batch dispatch Jules maintenance agents across repositories.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--repos",
        nargs="+",
        default=None,
        help="Target repositories to dispatch agents against (default: auto-detected repos active in the last 30 days)",
    )
    parser.add_argument(
        "--agents",
        nargs="+",
        default=DEFAULT_AGENTS,
        help="Agents to dispatch (bolt, sentinel, test-smith, etc.)",
    )
    parser.add_argument(
        "--days-active",
        type=int,
        default=30,
        help="Window in days to determine default active repositories from Jules history",
    )
    parser.add_argument(
        "--list-active",
        action="store_true",
        help="Print active repos detected from Jules and exit without dispatching",
    )
    parser.add_argument(
        "--require-approval",
        action="store_true",
        default=True,
        help="Require human plan approval for generated sessions",
    )
    parser.add_argument(
        "--no-approval",
        dest="require_approval",
        action="store_false",
        help="Do not require plan approval",
    )

    args = parser.parse_args()

    if not JULES_CLI.exists():
        sys.exit(f"Error: Jules CLI not found at {JULES_CLI}")

    client = get_jules_client()
    sources_map = fetch_connected_sources(client)

    if not sources_map:
        sys.exit("Error: No connected repository sources found in Jules.")

    target_repos: List[Tuple[str, str]] = []

    if args.repos:
        for r in args.repos:
            clean_r = r.removeprefix("sources/")
            source_info = sources_map.get(clean_r)
            if not source_info:
                # Case-insensitive or substring match fallback
                for k, v in sources_map.items():
                    if k.lower() == clean_r.lower() or v["name"].lower() == clean_r.lower():
                        source_info = v
                        break
            branch = source_info["default_branch"] if source_info else "main"
            target_repos.append((clean_r, branch))
    else:
        # Dynamically discover active repos in the last month
        target_repos = discover_active_repos(client, sources_map, days_active=args.days_active)
        if not target_repos:
            print(f"No repositories active in the last {args.days_active} days detected in Jules. Falling back to all connected sources.")
            target_repos = [(s["id"], s["default_branch"]) for s in sources_map.values()]

    if args.list_active:
        print(f"Discovered active repositories in Jules (past {args.days_active} days):")
        for repo_id, branch in target_repos:
            print(f"  - {repo_id} (branch: {branch})")
        return

    print(f"Target repositories for dispatch ({len(target_repos)}):")
    for repo_id, branch in target_repos:
        print(f"  - {repo_id} (branch: {branch})")
    print()

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp_path = Path(tmp_dir)
        # Build prompt files
        build_cmd = [sys.executable, str(BUILD_PROMPTS), str(tmp_path)] + args.agents
        res = subprocess.run(build_cmd, capture_output=True, text=True)
        if res.returncode != 0:
            sys.exit(f"Failed to build prompts: {res.stderr.strip()}")

        for repo, branch in target_repos:
            repo_slug = repo.split("/")[-1]
            print(f"=== Dispatching to {repo} ({branch}) ===")
            for agent in args.agents:
                prompt_file = tmp_path / f"{agent}.txt"
                if not prompt_file.exists():
                    print(f"Skipping {agent}: prompt not found", file=sys.stderr)
                    continue

                title = f"[{repo_slug}] {agent.replace('-', ' ').title()} Agent"
                cmd = [
                    sys.executable,
                    str(JULES_CLI),
                    "create-session",
                    "--source",
                    repo,
                    "--branch",
                    branch,
                    "--title",
                    title,
                ]
                if args.require_approval:
                    cmd.append("--require-approval")

                print(f"Launching {agent} on {repo}...")
                with open(prompt_file, "r") as pf:
                    proc = subprocess.run(cmd, stdin=pf, capture_output=True, text=True)

                if proc.returncode != 0:
                    print(f"Error launching {agent} on {repo}: {proc.stderr.strip()}", file=sys.stderr)
                else:
                    lines = proc.stdout.strip().splitlines()
                    first_line = lines[0] if lines else "Session dispatched"
                    print(f"✓ {first_line}")


if __name__ == "__main__":
    main()
