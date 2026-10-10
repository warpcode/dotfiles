#!/usr/bin/env python3
"""
df.jules.api - Google Jules REST API client & CLI utility.

Interact with Google Jules v1alpha REST API to inspect sources, query sessions,
track activity timelines, approve plans, send messages, and fetch git diff patches.
"""

import argparse
import json
import sys
from pathlib import Path

# Ensure scripts directory is on sys.path for local module resolution
scripts_dir = Path(__file__).resolve().parent
if str(scripts_dir) not in sys.path:
    sys.path.insert(0, str(scripts_dir))

from jules.auth import resolve_jules_api_key
from jules.client import JulesClient
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
        audits = client.audit_sessions(
            page_size=getattr(args, "page_size", 10),
            stale_threshold_mins=stale_threshold,
            filter_expr=getattr(args, "filter", None),
            max_age_days=max_age_days,
            repo=getattr(args, "repo", None),
        )


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

    data = client.create_session(
        prompt=prompt,
        source=args.source,
        starting_branch=args.branch,
        title=args.title,
        require_plan_approval=args.require_approval,
    )
    print(format_session(data))


def cmd_approve_plan(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.approve_plan(args.session_id, args.plan_id)
    if args.plan_id:
        print(
            f"Plan `{args.plan_id}` approved successfully for session `{args.session_id}`."
        )
    else:
        print(f"Plan approved successfully for session `{args.session_id}`.")
    if data:
        print(json.dumps(data, indent=2))


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
    template = args.template
    if template not in NUDGE_TEMPLATES:
        die(
            f"Unknown nudge template: {template}. Available: {', '.join(NUDGE_TEMPLATES.keys())}"
        )

    message = NUDGE_TEMPLATES[template]
    data = client.send_message(args.session_id, message)
    print(f"Nudge `{template}` sent to session `{args.session_id}`.")
    if data:
        print(json.dumps(data, indent=2))


def cmd_activities(client: JulesClient, args: argparse.Namespace) -> None:
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
    audits = client.audit_sessions(
        page_size=getattr(args, "page_size", None) or 20,
        max_age_days=getattr(args, "max_age_days", None),
        repo=getattr(args, "repo", None),
    )
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

    # approve-plan
    p_approve = subparsers.add_parser(
        "approve-plan",
        parents=[common_parser],
        help="Approve a generated plan in a session",
        description="Approve a pending implementation plan generated by Jules for a session configured with requirePlanApproval (POST /v1alpha/sessions/{sessionId}:approvePlan).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_approve.add_argument(
        "session_id",
        help="Jules session ID containing the pending plan",
    )
    p_approve.add_argument(
        "plan_id",
        nargs="?",
        default=None,
        help="Optional plan ID to approve (extracted from 'activities' or 'activity' output)",
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

    # nudge
    p_nudge = subparsers.add_parser(
        "nudge",
        parents=[common_parser],
        help="Send a standardized nudge message to a session",
        description="Send a pre-defined nudge template to a Jules session. Templates: plan_stalled, progress_check, pr_reminder.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_nudge.add_argument(
        "session_id",
        help="Target Jules session ID",
    )
    p_nudge.add_argument(
        "template",
        choices=["plan_stalled", "progress_check", "pr_reminder"],
        help="Nudge template to use",
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
    }

    commands[args.subcommand](client, args)


if __name__ == "__main__":
    main()
