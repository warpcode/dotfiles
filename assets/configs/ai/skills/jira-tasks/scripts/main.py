#!/usr/bin/env python3
"""
df.jira - Generic Jira REST API wrapper for searches and metadata (Python implementation).

This script provides a command-line interface to the Jira REST API v3,
supporting JQL searches, issue details, and metadata retrieval.
It is a dependency-free replacement for the legacy jira.sh script.
"""

import argparse
import os
import sys

from jira.utils import die
from jira.auth import resolve_secret
from jira.client import JiraClient
from jira.commands.jql import cmd_jql
from jira.commands.issues import cmd_issues
from jira.commands.metadata import (
    cmd_fields, cmd_statuses, cmd_types,
    cmd_priorities, cmd_resolutions, cmd_projects
)
from jira.commands.users import cmd_users
from jira.commands.generic import cmd_call

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="df.jira - Generic Jira REST API wrapper.")
    parser.add_argument("--url", help="Jira workspace URL")
    parser.add_argument("--user", help="Jira user email")
    parser.add_argument("--token", help="Jira API token")
    parser.add_argument("--project", help="Jira project key")
    parser.add_argument("--raw", action="store_true", help="Output raw response from API")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show verbose details")

    subparsers = parser.add_subparsers(dest="subcommand", required=True)

    # JQL
    p_jql = subparsers.add_parser("jql", help="Search for issues")
    p_jql.add_argument("query", help="JQL query string")
    p_jql.add_argument("--max-results", type=int, default=50)
    p_jql.add_argument("--fields", help="Comma-separated list of fields")
    p_jql.add_argument("--expand", default="", help="Comma-separated list of expand options")
    p_jql.add_argument("--full-issue", action="store_true", help="Include original JSON")
    p_jql.add_argument("--param", action="append", help="Extra API params (key=value)")

    # Issues
    p_issues = subparsers.add_parser("issues", help="Fetch specific issue details")
    p_issues.add_argument("ids", nargs="+", help="Issue IDs or keys")
    p_issues.add_argument("--fields", help="Comma-separated list of fields")
    p_issues.add_argument("--expand", default="", help="Comma-separated list of expand options")
    p_issues.add_argument("--full-issue", action="store_true", help="Include original JSON")

    # Fields
    p_fields = subparsers.add_parser("fields", help="List or search Jira fields")
    p_fields.add_argument("filter", nargs="?", help="Optional search pattern")

    # Statuses
    p_statuses = subparsers.add_parser("statuses", help="List Jira statuses")
    p_statuses.add_argument("--category", help="Filter by category")

    # Metadata subcommands (no args needed)
    subparsers.add_parser("types", help="List available issue types")
    subparsers.add_parser("priorities", help="List priority levels")
    subparsers.add_parser("resolutions", help="List resolution types")
    subparsers.add_parser("projects", help="List available projects")

    # Users
    p_users = subparsers.add_parser("users", help="Search for Jira users")
    p_users.add_argument("query", nargs="?", help="Search string")
    p_users.add_argument("--exact", action="store_true", help="Exact match")
    p_users.add_argument("--expand", help="Fields to expand")
    p_users.add_argument("--full", action="store_true", help="Full user object")
    p_users.add_argument("--max-results", type=int, default=50)
    p_users.add_argument("--project", help="Project key")

    # Call
    p_call = subparsers.add_parser("call", help="Direct API call")
    p_call.add_argument("method", choices=["GET", "POST", "PUT", "DELETE"])
    p_call.add_argument("endpoint")
    p_call.add_argument("payload", nargs="?", help="JSON payload string")

    args = parser.parse_args()

    # Resolve credentials
    url = args.url or resolve_secret("JIRA_URL")
    user = args.user or resolve_secret("JIRA_USER")
    token = args.token or resolve_secret("JIRA_API_TOKEN")
    project = args.project or resolve_secret("JIRA_PROJECT")

    if not url: die("Error: Jira URL is required.")
    if not user: die("Error: Jira User is required.")
    if not token: die("Error: Jira API Token is required.")
    if not project: die("Error: Jira Project key is required.")

    if not url.startswith("http"):
        url = f"https://{url}"

    client = JiraClient(url, user, token, verbose=args.verbose)

    # Add project to args if needed for project-specific subcommands
    if hasattr(args, 'project') and not args.project:
        args.project = project
    elif not hasattr(args, 'project'):
        # For statuses subcommand which uses project if available
        setattr(args, 'project', project)

    # Command mapping
    command_map = {
        "jql": cmd_jql,
        "issues": cmd_issues,
        "fields": cmd_fields,
        "statuses": cmd_statuses,
        "types": cmd_types,
        "priorities": cmd_priorities,
        "resolutions": cmd_resolutions,
        "projects": cmd_projects,
        "users": cmd_users,
        "call": cmd_call
    }

    command_map[args.subcommand](client, args)

if __name__ == "__main__":
    main()
