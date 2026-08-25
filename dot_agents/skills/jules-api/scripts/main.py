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
    print(format_sessions(data))


def cmd_session(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.get_session(args.session_id)
    print(format_session(data))


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
    print(f"Plan `{args.plan_id}` approved successfully for session `{args.session_id}`.")
    if data:
        print(json.dumps(data, indent=2))


def cmd_send_message(client: JulesClient, args: argparse.Namespace) -> None:
    data = client.send_message(args.session_id, args.message)
    print(f"Message sent to session `{args.session_id}`.")
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
    payload = None
    if args.payload:
        try:
            payload = json.loads(args.payload)
        except json.JSONDecodeError as e:
            die(f"Invalid JSON payload: {e}")
    data = client.call(args.method, args.endpoint, payload=payload)
    print(json.dumps(data, indent=2))


def main() -> None:
    # Common flags inherited across root and subparsers with suppress default
    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument(
        "--token",
        "-t",
        default=argparse.SUPPRESS,
        help="Google Jules API key (overrides JULES_API_KEY environment variable)",
    )
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
  Resolves API key from JULES_API_KEY environment variable or --token flag."""

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
        required=True,
        help="Target repository source (e.g. github/owner/repo or sources/github/owner/repo) [REQUIRED]",
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
        help="Plan ID to approve (extracted from 'activities' or 'activity' output)",
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
        description="Direct REST API call escape hatch for querying or mutating any endpoint under https://jules.googleapis.com/v1alpha.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_call.add_argument(
        "method",
        choices=["GET", "POST", "PUT", "DELETE"],
        help="HTTP method to execute",
    )
    p_call.add_argument(
        "endpoint",
        help="API endpoint path relative to /v1alpha (e.g. sources, sessions/4475409647262242777/activities)",
    )
    p_call.add_argument(
        "payload",
        nargs="?",
        help="Optional JSON payload string for POST/PUT requests",
    )

    args = parser.parse_args()

    token_val = getattr(args, "token", None)
    verbose_val = getattr(args, "verbose", False)

    api_key = resolve_jules_api_key(token_val)
    if not api_key:
        die("Jules API key not found. Set JULES_API_KEY environment variable or pass --token.")

    client = JulesClient(api_key=api_key, verbose=verbose_val)

    commands = {
        "sources": cmd_sources,
        "source": cmd_source,
        "sessions": cmd_sessions,
        "session": cmd_session,
        "create-session": cmd_create_session,
        "approve-plan": cmd_approve_plan,
        "send-message": cmd_send_message,
        "activities": cmd_activities,
        "activity": cmd_activity,
        "call": cmd_call,
    }

    commands[args.subcommand](client, args)


if __name__ == "__main__":
    main()
