#!/usr/bin/env python3
"""
df.jules.api - Google Jules REST API client & CLI utility.

Interact with Google Jules v1alpha REST API to inspect sources, query sessions,
track activity timelines, approve plans, send messages, and fetch git diff patches.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# Ensure scripts directory is on sys.path for local module resolution
scripts_dir = Path(__file__).resolve().parent
if str(scripts_dir) not in sys.path:
    sys.path.insert(0, str(scripts_dir))

from jules.auth import resolve_jules_api_key
from jules.client import AuditSessionsOptions, JulesClient
from jules.formatters import (
    format_activities,
    format_activity,
    format_session,
    format_sessions,
    format_session_check,
    format_source,
    format_sources,
)
from jules.utils import die


def cmd_sources(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.list_sources(
        page_size=getattr(args, "page_size", None),
        page_token=getattr(args, "page_token", None),
        filter_expr=getattr(args, "filter", None),
    )
    print(format_sources(data))


def cmd_source(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.get_source(args.source_id)
    print(format_source(data))


def cmd_sessions(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.list_sessions(
        page_size=getattr(args, "page_size", None),
        page_token=getattr(args, "page_token", None),
        filter_expr=getattr(args, "filter", None),
    )
    repo = getattr(args, "repo", None)
    if repo and "sessions" in data:
        clean_repo = repo.strip().removeprefix("sources/").removeprefix("github/").lower()
        data["sessions"] = [
            s
            for s in data["sessions"]
            if clean_repo in s.get("sourceContext", {}).get("source", "").removeprefix("sources/").removeprefix("github/").lower()
        ]
    print(format_sessions(data))


def cmd_session(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.get_session(args.session_id)
    print(format_session(data))


def cmd_check_sessions(client: JulesClient, args: argparse.Namespace) -> None:
    stale_threshold = getattr(args, "stale_threshold_mins", 60)
    max_age_days = getattr(args, "max_age_days", 30)
    if max_age_days == 0:
        max_age_days = None
    session_id = getattr(args, "session_id", None)
    flag_unmerged = getattr(args, "flag_unmerged", False)

    if session_id:
        sess = client.get_session(session_id)
        audits = [
            client.audit_session(
                sess, stale_threshold_mins=stale_threshold, max_age_days=max_age_days
            )
        ]
    else:
        opts = AuditSessionsOptions(
            page_size=getattr(args, "page_size", 10),
            stale_threshold_mins=stale_threshold,
            filter_expr=getattr(args, "filter", None),
            max_age_days=max_age_days,
            repo=getattr(args, "repo", None),
        )
        audits = client.audit_sessions(opts)


    show_history = getattr(args, "history", False) or bool(session_id)
    print(
        format_session_check(
            audits, show_history=show_history, flag_unmerged=flag_unmerged
        )
    )

    if getattr(args, "nudge", False):
        nudge_targets = [
            a
            for a in audits
            if a["assessment"] in ("STALLED", "AWAITING_USER_FEEDBACK")
        ]
        if nudge_targets:
            print("\n### Auto-Nudge Progress Updates")
            for a in nudge_targets:
                sid = a["id"]
                msg = "What is your progress? Please provide a status update on this task."
                client.send_message(sid, msg)
                print(f"- Sent status check message to `{sid}` ({a['title']})")
        else:
            print("\n_No stalled sessions found to nudge._")


def cmd_create_session(client: JulesClient, args: argparse.Namespace) -> None:
    prompt = args.prompt
    if prompt == "-" or not prompt:
        prompt = sys.stdin.read().strip()
    if not prompt:
        die("Task prompt is required. Provide prompt argument or pipe via stdin.")

    automation_mode = getattr(args, "automation_mode", "AUTO_CREATE_PR")

    data = client.create_session(
        prompt=prompt,
        source=args.source,
        starting_branch=args.branch,
        title=args.title,
        require_plan_approval=args.require_approval,
        automation_mode=automation_mode,
    )
    print(format_session(data))


def cmd_approve_plan(client: JulesClient, args: argparse.Namespace) -> None:
    session_ids = args.session_ids
    plan_id = args.plan_id
    for sid in session_ids:
        try:
            data = client.approve_plan(sid, plan_id if len(session_ids) == 1 else None)
            if plan_id and len(session_ids) == 1:
                print(f"Plan `{plan_id}` approved successfully for session `{sid}`.")
            else:
                print(f"Plan approved successfully for session `{sid}`.")
            if data and len(session_ids) == 1:
                print(json.dumps(data, indent=2))
        except Exception as e:
            print(f"Error approving plan for session `{sid}`: {e}", file=sys.stderr)


def cmd_send_message(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.send_message(args.session_id, args.message)
    print(f"Message sent to session `{args.session_id}`.")
    if data:
        print(json.dumps(data, indent=2))


NUDGE_TEMPLATES = {
    "plan_stalled": (
        "The plan was approved but no implementation progress is visible. "
        "Please proceed with implementation per the approved plan."
    ),
    "progress_check": (
        "What is your progress? Please provide a status update on this task."
    ),
    "pr_reminder": (
        "This session appears to have completed work. "
        "Please create a pull request with the changes or provide a status update."
    ),
}


def cmd_nudge(client: JulesClient, args: argparse.Namespace) -> None:
    session_ids = [sid.strip().removeprefix("sessions/") for sid in args.session_ids]
    template = getattr(args, "template", None)
    # Support positional syntax: nudge <id1> [id2 ...] <template>
    if not template and session_ids and session_ids[-1] in NUDGE_TEMPLATES:
        template = session_ids.pop()
    if not template:
        template = "progress_check"

    if template not in NUDGE_TEMPLATES:
        die(
            f"Unknown nudge template: {template}. Available: {', '.join(NUDGE_TEMPLATES.keys())}"
        )

    if not session_ids:
        die("Provide at least one session ID to nudge.")

    message = NUDGE_TEMPLATES[template]
    for sid in session_ids:
        try:
            data = client.send_message(sid, message)
            print(f"Nudge `{template}` sent to session `{sid}`.")
            if data and len(session_ids) == 1:
                print(json.dumps(data, indent=2))
        except Exception as e:
            print(f"Error nudging session `{sid}`: {e}", file=sys.stderr)


def cmd_activities(client: JulesClient, args: argparse.Namespace) -> None:
    if getattr(args, "all", False) or getattr(args, "tail", None):
        acts = client.get_all_activities(session_id=args.session_id)
        if getattr(args, "tail", None):
            acts = acts[-args.tail:]
        data = {"activities": acts}
    else:
        data = client.list_activities(
            session_id=args.session_id,
            page_size=getattr(args, "page_size", None),
            page_token=getattr(args, "page_token", None),
        )
    print(format_activities(data, session_id=args.session_id))


def cmd_activity(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.get_activity(args.session_id, args.activity_id)
    print(format_activity(data))


def cmd_call(client: JulesClient, args: argparse.Namespace) -> None:
    if args.method.upper() != "GET":
        die(
            f"Refusing to issue {args.method.upper()} via the read-only 'call' command. "
            "Use the dedicated Jules command for this operation after explicit user approval."
        )
    if args.endpoint.startswith(("http://", "https://")):
        die("API endpoint must be relative to the configured Jules URL.")
    data = client.call("GET", args.endpoint)
    print(json.dumps(data, indent=2))


def cmd_delete_session(client: JulesClient, args: argparse.Namespace) -> None:
    if args.list_archived_candidates:
        _print_archive_candidates(client, args)
        return

    if not args.session_id:
        die("Provide a session_id, or use --list-archived-candidates.")

    data = client.delete_session(args.session_id, confirm=args.confirm)
    sid = args.session_id.strip().removeprefix("sessions/")
    print(f"Permanently deleted session {sid}. This is irreversible and cannot be recovered.")
    if data:
        print(json.dumps(data, indent=2))


def _archive_candidates(client: JulesClient, args: argparse.Namespace) -> list[dict]:
    is_batch = getattr(args, "all_candidates", False) or getattr(args, "list_candidates", False) or getattr(args, "list_archived_candidates", False)
    all_pages = getattr(args, "page_size", None) is None and is_batch
    page_size = getattr(args, "page_size", None) or (50 if is_batch else 20)
    max_age = getattr(args, "max_age_days", None)
    if max_age == 0:
        max_age = None
    older_than = getattr(args, "older_than_days", None)
    if older_than:
        max_age = None
        all_pages = True
    opts = AuditSessionsOptions(
        page_size=page_size,
        max_age_days=max_age,
        older_than_days=older_than,
        repo=getattr(args, "repo", None),
        all_pages=all_pages,
    )
    audits = client.audit_sessions(opts)
    if older_than:
        return [a for a in audits if not a.get("pull_request_url") or a.get("assessment") in ("CLOSED_NO_PR", "STALLED", "COMPLETED_NO_OUTPUT", "AWAITING_PLAN_APPROVAL", "AWAITING_USER_FEEDBACK", "COMPLETED")]
    return [
        a
        for a in audits
        if not a.get("pull_request_url")
        and not a.get("is_inactive")
        and a.get("assessment")
        in (
            "AWAITING_PLAN_APPROVAL",
            "AWAITING_USER_FEEDBACK",
            "STALLED",
            "COMPLETED_NO_OUTPUT",
        )
    ]


def _print_archive_candidates(client: JulesClient, args: argparse.Namespace) -> None:
    candidates = _archive_candidates(client, args)
    if not candidates:
        print("No gated/stalled sessions without a PR. Nothing to archive.")
        return
    print("## Archive Candidates (dry run - nothing was mutated)\n")
    print("| Session ID | Assessment | State | Title |")
    print("|---|---|---|---|")
    for a in candidates:
        title = " ".join(str(a.get("title") or "").split())[:70]
        print(
            f"| `{a.get('id')}` | {a.get('assessment')} | "
            f"{a.get('state')} | {title} |"
        )
    print(
        "\nArchiving is REVERSIBLE. Apply with: "
        "`archive-session <id> [<id> ...]` or `archive-session --all-candidates`"
    )


def cmd_archive_session(client: JulesClient, args: argparse.Namespace) -> None:
    if args.list_candidates:
        _print_archive_candidates(client, args)
        return

    target_ids = list(args.session_ids or [])
    if getattr(args, "all_candidates", False):
        candidates = _archive_candidates(client, args)
        target_ids.extend([c["id"] for c in candidates if c.get("id")])
        if not target_ids:
            print("No candidate sessions found to archive.")
            return

    if not target_ids:
        die("Provide one or more session IDs, or use --list-candidates / --all-candidates.")

    verb = "Unarchived" if args.unarchive else "Archived"
    for sid in target_ids:
        if args.unarchive:
            client.unarchive_session(sid)
        else:
            client.archive_session(sid)
        clean = sid.strip().removeprefix("sessions/")
        suffix = " (restored to active listing)" if args.unarchive else " (reversible)"
        print(f"{verb} session {clean}{suffix}")


def build_repo_pr_cache(repos: set[str]) -> dict[str, str]:
    """Fetch PR statuses in batch per repository using gh pr list: O(repos) instead of O(PRs)."""
    cache: dict[str, str] = {}
    for repo in repos:
        try:
            proc = subprocess.run(
                [
                    "gh", "pr", "list", "--repo", repo, "--state", "all",
                    "--limit", "300", "--json", "number,state"
                ],
                capture_output=True,
                text=True,
                check=False,
                timeout=20,
            )
            if proc.returncode == 0 and proc.stdout.strip():
                for pr in json.loads(proc.stdout):
                    cache[f"{repo}#{pr['number']}"] = pr.get("state", "").upper()
        except Exception as e:
            sys.stderr.write(f"Warning: Failed to bulk fetch PRs for {repo}: {e}\n")
    return cache


def cmd_archive_closed_prs(client: JulesClient, args: argparse.Namespace) -> None:
    """Batch archive all sessions whose remote GitHub PRs are MERGED or CLOSED."""
    max_age = getattr(args, "max_age_days", 30)
    if max_age == 0:
        max_age = None

    print("Auditing non-archived sessions for PR deliverables...")
    opts = AuditSessionsOptions(
        page_size=50,
        max_age_days=max_age,
        repo=getattr(args, "repo", None),
        all_pages=True,
    )
    sessions = client.audit_sessions(opts)

    repo_pr_map: list[tuple[str, str, int, str]] = []
    unique_repos: set[str] = set()
    for s in sessions:
        pr_url = s.get("pull_request_url")
        if not pr_url:
            continue
        m = re.search(r"github\.com/([^/]+/[^/]+)/pull/(\d+)", pr_url)
        if m:
            repo_slug = m.group(1)
            pr_num = int(m.group(2))
            sid = s.get("id", "")
            title = s.get("title", "")
            repo_pr_map.append((sid, repo_slug, pr_num, title))
            unique_repos.add(repo_slug)

    print(f"Found {len(repo_pr_map)} sessions with PRs across {len(unique_repos)} repos.")
    print("Bulk resolving remote PR states...")
    pr_cache = build_repo_pr_cache(unique_repos)

    to_archive: list[tuple[str, str, str]] = []
    for sid, repo_slug, pr_num, title in repo_pr_map:
        key = f"{repo_slug}#{pr_num}"
        state = pr_cache.get(key)
        if state in ("MERGED", "CLOSED"):
            to_archive.append((sid, state, title))

    if not to_archive:
        print("No sessions found with merged or closed PRs to archive.")
        return

    print(f"\nFound {len(to_archive)} sessions eligible for archival:")
    for sid, st, tit in to_archive[:10]:
        print(f"- `{sid}` [{st}]: {tit}")
    if len(to_archive) > 10:
        print(f"... and {len(to_archive) - 10} more.")

    if not getattr(args, "apply", False):
        print(f"\n[DRY RUN] Pass --apply to archive these {len(to_archive)} sessions.")
        return

    from concurrent.futures import ThreadPoolExecutor
    print(f"\nArchiving {len(to_archive)} sessions concurrently...")
    with ThreadPoolExecutor(max_workers=8) as pool:
        list(pool.map(lambda item: client.archive_session(item[0]), to_archive))
    print(f"Successfully archived {len(to_archive)} sessions.")



def setup_parser() -> argparse.ArgumentParser:
    # Common flags inherited across root and subparsers with suppress default
    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        default=argparse.SUPPRESS,
        help="Enable verbose HTTP request/response logging to stderr",
    )
    common_parser.add_argument(
        "--page-size",
        "-n",
        type=int,
        default=argparse.SUPPRESS,
        help="Maximum number of items to return in a single page",
    )
    common_parser.add_argument(
        "--page-token",
        "-p",
        default=argparse.SUPPRESS,
        help="Pagination token for retrieving the next page of results",
    )

    main_description = """Google Jules REST API Client & CLI Utility (v1alpha)

Interact with Google Jules to manage connected repositories, list sessions,
track activity timelines, approve plans, send messages, and fetch diff patches.

Authentication:
    Resolves API key from the JULES_API_KEY environment variable."""

    parser = argparse.ArgumentParser(
        prog="main.py",
        description=main_description,
        parents=[common_parser],
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(
        dest="subcommand",
        required=True,
        title="Available Subcommands",
        description="Choose a subcommand to execute:",
    )

    # sources
    p_sources = subparsers.add_parser(
        "sources",
        parents=[common_parser],
        help="List connected repositories / sources",
        description="List all connected GitHub repositories authorized for task delegation in Google Jules (GET /v1alpha/sources).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_sources.add_argument(
        "--filter",
        help="Filter expression to narrow results (e.g. name=sources/github/owner/repo)",
    )

    # source
    p_source = subparsers.add_parser(
        "source",
        parents=[common_parser],
        help="Get details for a specific repository source",
        description="Retrieve metadata, default branch, and active branches for a specific repository source (GET /v1alpha/sources/{sourceId}).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_source.add_argument(
        "source_id",
        help="Source identifier in the format 'github/owner/repo' or 'sources/github/owner/repo'",
    )

    # sessions
    p_sessions = subparsers.add_parser(
        "sessions",
        parents=[common_parser],
        help="List task sessions",
        description="List asynchronous task sessions (GET /v1alpha/sessions). Outputs a Markdown table containing Session IDs, States, Repositories, Prompt Titles, and PR Links.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_sessions.add_argument(
        "--filter",
        help="Filter expression to filter sessions",
    )
    p_sessions.add_argument(
        "--repo",
        help="Filter sessions by repository (e.g. warpcode/cloakenv or cloakenv)",
    )

    # session
    p_session = subparsers.add_parser(
        "session",
        parents=[common_parser],
        help="Get details for a specific session",
        description="Retrieve full details, task prompt, state, source context, change set, base commit, and pull request info for a single session (GET /v1alpha/sessions/{sessionId}).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_session.add_argument(
        "session_id",
        help="Unique Jules session ID (e.g. 4475409647262242777)",
    )

    # check-sessions
    p_check = subparsers.add_parser(
        "check-sessions",
        parents=[common_parser],
        help="Audit health, timeline activity, and plan status for sessions",
        description="Audit recent sessions or a specific session. Analyzes timeline activity across all pages, detects stalled/silent runs (>threshold mins), identifies plans awaiting approval, and reports actionable steps.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_check.add_argument(
        "session_id",
        nargs="?",
        default=None,
        help="Optional specific session ID to audit (if omitted, audits recent sessions)",
    )
    p_check.add_argument(
        "--repo",
        help="Filter audited sessions by repository (e.g. warpcode/cloakenv or cloakenv)",
    )
    p_check.add_argument(
        "--stale-threshold-mins",
        type=int,
        default=60,
        help="Inactivity threshold in minutes before flagging an in-progress session as STALLED (default: 60)",
    )
    p_check.add_argument(
        "--max-age-days",
        type=int,
        default=30,
        help="Ignore sessions older than this threshold in days (default: 30; set 0 to disable)",
    )
    p_check.add_argument(
        "--nudge",
        action="store_true",
        help="Automatically send a progress inquiry message to any session detected as STALLED or AWAITING_USER_FEEDBACK",
    )
    p_check.add_argument(
        "--history",
        "-H",
        action="store_true",
        help="Include full chronological conversation history thread for audited sessions",
    )
    p_check.add_argument(
        "--filter",
        help="Filter expression to narrow sessions",
    )
    p_check.add_argument(
        "--flag-unmerged",
        action="store_true",
        help="Scan CLOSED_NO_PR sessions for completion markers (e.g., 'Completed pre-commit steps', 'Code review: Code reviewed') and flag sessions with deliverables but no PR",
    )

    # create-session
    p_create = subparsers.add_parser(
        "create-session",
        parents=[common_parser],
        help="Create a new task session",
        description="Create and dispatch a new asynchronous coding task to an isolated Jules cloud VM (POST /v1alpha/sessions).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_create.add_argument(
        "prompt",
        nargs="?",
        default="",
        help="Task prompt / instructions for the AI coding agent (omit or use '-' to read from stdin)",
    )
    p_create.add_argument(
        "--source",
        "-s",
        help="Target repository source (e.g. github/owner/repo or sources/github/owner/repo) [Optional: omit for sourceless session]",
    )
    p_create.add_argument(
        "--branch",
        "-b",
        default="main",
        help="Starting base branch in the repository (default: main)",
    )
    p_create.add_argument(
        "--title",
        help="Optional short human-readable session title",
    )
    p_create.add_argument(
        "--require-approval",
        action="store_true",
        help="Halt execution after plan generation to require human approval via 'approve-plan'",
    )
    p_create.add_argument(
        "--automation-mode",
        default="AUTO_CREATE_PR",
        help="Automation mode for session execution (default: AUTO_CREATE_PR)",
    )

    # approve-plan
    p_approve = subparsers.add_parser(
        "approve-plan",
        parents=[common_parser],
        help="Approve generated plans for one or more sessions",
        description="Approve pending implementation plans generated by Jules for sessions configured with requirePlanApproval (POST /v1alpha/sessions/{sessionId}:approvePlan). Accepts one or more session IDs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_approve.add_argument(
        "session_ids",
        nargs="+",
        help="One or more Jules session IDs containing pending plans",
    )
    p_approve.add_argument(
        "--plan-id",
        dest="plan_id",
        default=None,
        help="Optional plan ID to confirm (only applied when approving a single session)",
    )

    # send-message
    p_msg = subparsers.add_parser(
        "send-message",
        parents=[common_parser],
        help="Send a user message/instruction to a session",
        description="Send a steering message, guidance, or clarifying instruction to a running Jules task session (POST /v1alpha/sessions/{sessionId}:sendMessage).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_msg.add_argument(
        "session_id",
        help="Target Jules session ID",
    )
    p_msg.add_argument(
        "message",
        help="Feedback, guidance, or instruction message text",
    )

    # activities
    p_acts = subparsers.add_parser(
        "activities",
        parents=[common_parser],
        help="List activities/events for a session",
        description="List chronological timeline events, agent thoughts, plan emissions, and progress updates for a session (GET /v1alpha/sessions/{sessionId}/activities).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_acts.add_argument(
        "session_id",
        help="Jules session ID to query activities for",
    )
    p_acts.add_argument(
        "--all",
        action="store_true",
        help="Fetch all activities across all pages",
    )
    p_acts.add_argument(
        "--tail",
        type=int,
        metavar="N",
        default=None,
        help="Return only the last N activities (fetches across pages if needed)",
    )

    # activity
    p_act = subparsers.add_parser(
        "activity",
        parents=[common_parser],
        help="Get details of a single activity in a session",
        description="Retrieve full details for a single activity event, such as full plan steps or unified git diff patches (GET /v1alpha/sessions/{sessionId}/activities/{activityId}).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_act.add_argument(
        "session_id",
        help="Jules session ID",
    )
    p_act.add_argument(
        "activity_id",
        help="Activity event ID (e.g. ea05126655df43eab990cce1d8a32a0f)",
    )

    # call (escape hatch)
    p_call = subparsers.add_parser(
        "call",
        parents=[common_parser],
        help="Direct API call escape hatch",
        description="Read-only REST API call for a relative endpoint under https://jules.googleapis.com/v1alpha.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_call.add_argument(
        "method",
        choices=["GET"],
        help="Only GET is allowed; use dedicated commands for approved writes.",
    )
    p_call.add_argument(
        "endpoint",
        help="API endpoint path relative to /v1alpha (e.g. sources, sessions/4475409647262242777/activities)",
    )
    # delete-session (destructive, irreversible)
    p_del = subparsers.add_parser(
        "delete-session",
        parents=[common_parser],
        help="Permanently delete a Jules session (IRREVERSIBLE)",
        description=(
            "Permanently delete a Jules session, bypassing archiving. This cannot be undone. "
            "To archive, close out, hide, or tidy a session, use the reversible "
            "'archive-session' command instead. Requires --confirm."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_del.add_argument(
        "session_id",
        nargs="?",
        help="Jules session ID to permanently delete (omit when using --list-archived-candidates)",
    )
    p_del.add_argument(
        "--confirm",
        action="store_true",
        help="Required. Confirms permanent, irreversible deletion of the session.",
    )
    p_del.add_argument(
        "--list-archived-candidates",
        action="store_true",
        help="Dry-run: list sessions that are gated/stalled with no PR. Mutates nothing.",
    )

    # archive-session (reversible)
    p_arch = subparsers.add_parser(
        "archive-session",
        parents=[common_parser],
        help="Archive a Jules session (reversible) - use for 'archive'/'close out'/'tidy'",
        description=(
            "Archive one or more Jules sessions. Archiving sets the session's 'archived' "
            "flag and removes it from default listings. This is REVERSIBLE: restore with "
            "'archive-session --unarchive'. Use 'delete-session' only for permanent removal."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_arch.add_argument(
        "session_ids",
        nargs="*",
        help="One or more Jules session IDs to archive (omit when using --list-candidates or --all-candidates)",
    )
    p_arch.add_argument(
        "--unarchive",
        action="store_true",
        help="Restore the given sessions to the active listing instead of archiving them.",
    )
    p_arch.add_argument(
        "--list-candidates",
        action="store_true",
        help="Dry-run: list gated/stalled sessions without a PR that are safe to archive.",
    )
    p_arch.add_argument(
        "--all-candidates",
        action="store_true",
        help="Archive all candidate gated/stalled sessions without a PR in a single command.",
    )
    p_arch.add_argument(
        "--repo",
        help="Filter candidate sessions by repository (e.g. warpcode/cloakenv or cloakenv)",
    )
    p_arch.add_argument(
        "--max-age-days",
        type=int,
        default=30,
        help="Ignore sessions older than this threshold in days (default: 30; set 0 to disable)",
    )
    p_arch.add_argument(
        "--older-than-days",
        type=int,
        help="Archive sessions older than N days across all pages (overrides --max-age-days)",
    )

    # nudge
    p_nudge = subparsers.add_parser(
        "nudge",
        parents=[common_parser],
        help="Send a standardized nudge message to a session",
        description="Send a pre-defined nudge template to a Jules session. Templates: plan_stalled, progress_check, pr_reminder.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_nudge.add_argument(
        "session_ids",
        nargs="+",
        help="One or more target Jules session IDs (optionally followed by template name)",
    )
    p_nudge.add_argument(
        "--template",
        "-t",
        choices=["plan_stalled", "progress_check", "pr_reminder"],
        default=None,
        help="Nudge template to use (default: progress_check)",
    )

    # archive-closed-prs
    p_arch_prs = subparsers.add_parser(
        "archive-closed-prs",
        parents=[common_parser],
        help="Batch archive sessions whose pull requests are MERGED or CLOSED on GitHub",
        description="Audit sessions with PR deliverables, batch-check remote GitHub PR lifecycle states, and archive completed sessions.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_arch_prs.add_argument(
        "--apply",
        action="store_true",
        help="Actually apply the archival mutation (default is dry-run)",
    )
    p_arch_prs.add_argument(
        "--repo",
        help="Filter candidate sessions by repository (e.g. warpcode/cloakenv or cloakenv)",
    )
    p_arch_prs.add_argument(
        "--max-age-days",
        type=int,
        default=30,
        help="Ignore sessions older than this threshold in days (default: 30; set 0 to disable)",
    )

    return parser


def main() -> None:
    parser = setup_parser()
    args = parser.parse_args()

    verbose_val = getattr(args, "verbose", False)

    api_key = resolve_jules_api_key()
    if not api_key:
        die("Jules API key not found. Configure JULES_API_KEY in the protected environment.")

    client = JulesClient(api_key=api_key, verbose=verbose_val)

    commands = {
        "sources": cmd_sources,
        "source": cmd_source,
        "sessions": cmd_sessions,
        "session": cmd_session,
        "check-sessions": cmd_check_sessions,
        "create-session": cmd_create_session,
        "approve-plan": cmd_approve_plan,
        "send-message": cmd_send_message,
        "nudge": cmd_nudge,
        "activities": cmd_activities,
        "activity": cmd_activity,
        "call": cmd_call,
        "delete-session": cmd_delete_session,
        "archive-session": cmd_archive_session,
        "archive-closed-prs": cmd_archive_closed_prs,
    }

    commands[args.subcommand](client, args)


if __name__ == "__main__":
    main()
