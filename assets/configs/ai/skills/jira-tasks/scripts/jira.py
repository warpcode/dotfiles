#!/usr/bin/env python3
"""
df.jira - Generic Jira REST API wrapper for searches and metadata (Python implementation).

This script provides a command-line interface to the Jira REST API v3,
supporting JQL searches, issue details, and metadata retrieval.
It is a dependency-free replacement for the legacy jira.sh script.
"""

import argparse
import base64
import json
import os
import shlex
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from urllib.error import HTTPError
from urllib.request import Request, urlopen

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

JIRA_API_VERSION = "3"
WORK_DAY_START = 9  # 9 AM
WORK_DAY_END = 17.5 # 5:30 PM (8.5 hours)
SECONDS_PER_WORK_DAY = int((WORK_DAY_END - WORK_DAY_START) * 3600)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def parse_jira_time(time_str):
    """Parse Jira's ISO 8601 timestamps (e.g. 2026-05-14T09:16:37.070+0100)."""
    if not time_str:
        return None
    
    # Python < 3.11 fromisoformat doesn't like HHMM offsets without a colon.
    # We normalize +HHMM or -HHMM to +HH:MM or -HH:MM.
    if "+" in time_str:
        main, offset = time_str.rsplit("+", 1)
        if len(offset) == 4 and ":" not in offset:
            time_str = f"{main}+{offset[:2]}:{offset[2:]}"
    elif "-" in time_str and "T" in time_str:
        # Only split on '-' if it appears after the 'T' (to avoid splitting the date)
        date_part, time_part = time_str.split("T", 1)
        if "-" in time_part:
            t_main, offset = time_part.rsplit("-", 1)
            if len(offset) == 4 and ":" not in offset:
                time_str = f"{date_part}T{t_main}-{offset[:2]}:{offset[2:]}"
    
    # Handle 'Z' suffix for UTC
    if time_str.endswith("Z"):
        time_str = time_str[:-1] + "+00:00"

    try:
        return datetime.fromisoformat(time_str).astimezone(timezone.utc)
    except ValueError:
        # Fallback for formats that still might fail
        return None

def get_work_seconds(start_dt, end_dt):
    """
    Calculate work seconds between two datetimes, skipping weekends.
    Based on a WORK_DAY_START to WORK_DAY_END schedule.
    """
    if not start_dt or not end_dt or start_dt >= end_dt:
        return 0

    total_seconds = 0
    current = start_dt

    while current.date() <= end_dt.date():
        # Skip weekends (5=Saturday, 6=Sunday)
        if current.weekday() < 5:
            # Define work window for this day
            day_start = current.replace(hour=int(WORK_DAY_START), minute=int((WORK_DAY_START % 1) * 60), second=0, microsecond=0)
            day_end = current.replace(hour=int(WORK_DAY_END), minute=int((WORK_DAY_END % 1) * 60), second=0, microsecond=0)

            # Find intersection of [start_dt, end_dt] and [day_start, day_end]
            overlap_start = max(current if current.date() == start_dt.date() else day_start, day_start)
            overlap_end = min(end_dt if current.date() == end_dt.date() else day_end, day_end)

            if overlap_end > overlap_start:
                total_seconds += (overlap_end - overlap_start).total_seconds()

        current = (current + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)

    return int(total_seconds)

def format_duration(seconds):
    """Convert seconds into a human-readable Xd Yh Zm format based on work day length."""
    if seconds <= 0:
        return "0m"
    
    days = seconds // SECONDS_PER_WORK_DAY
    remaining = seconds % SECONDS_PER_WORK_DAY
    hours = remaining // 3600
    minutes = (remaining % 3600) // 60
    
    parts = []
    if days > 0: parts.append(f"{int(days)}d")
    if hours > 0: parts.append(f"{int(hours)}h")
    if minutes > 0 or not parts: parts.append(f"{int(minutes)}m")
    
    return " ".join(parts)

def err(msg):
    timestamp = datetime.now().strftime('%Y-%m-%dT%H:%M:%S%z')
    sys.stderr.write(f"[{timestamp}] jira.py: {msg}\n")

def die(msg):
    err(msg)
    sys.exit(1)

def resolve_secret(name):
    """Resolve a secret using DF_SECRET_GET_CMD if not already set."""
    # 1. Early return if already set in environment
    val = os.environ.get(name)
    if val:
        return val

    # 2. Special case for token: check JIRA_API_KEY
    if name == "JIRA_API_TOKEN":
        val = os.environ.get("JIRA_API_KEY")
        if val:
            return val

    # 3. Guard: resolver command must be defined
    resolver_cmd = os.environ.get("DF_SECRET_GET_CMD")
    if not resolver_cmd:
        return None

    # 4. Resolve via command
    try:
        cmd_args = shlex.split(resolver_cmd) + [name]
        result = subprocess.run(cmd_args, capture_output=True, text=True, check=True)
        value = result.stdout.strip()
        
        # 5. Fallback for token
        if not value and name == "JIRA_API_TOKEN":
            cmd_args = shlex.split(resolver_cmd) + ["JIRA_API_KEY"]
            result = subprocess.run(cmd_args, capture_output=True, text=True, check=True)
            value = result.stdout.strip()
            
        return value if value else None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

def flatten_adf(node):
    """Recursive function to handle nested ADF (Atlassian Document Format) content."""
    if node is None:
        return ""
    if isinstance(node, list):
        return "".join(flatten_adf(item) for item in node)
    if not isinstance(node, dict):
        return ""
    
    node_type = node.get("type")
    if node_type == "text":
        return node.get("text", "")
    if node_type == "hardBreak":
        return "\n"
    if node_type == "inlineCard":
        return node.get("attrs", {}).get("url", "")
    if node_type == "mention":
        return node.get("attrs", {}).get("text", "")
    if node_type in ("paragraph", "heading", "listItem", "tableCell"):
        content = node.get("content", [])
        return flatten_adf(content) + "\n"
    if "content" in node:
        return flatten_adf(node["content"])
    return ""

def process_issue(issue, requested_expands, full_issue=False, status_map=None):
    """Replicates the ISSUE_PROCESSOR_JQ logic for a single issue and adds statistical metrics."""
    fields = issue.get("fields", {})
    now = datetime.now(timezone.utc)
    
    # Extract comments
    comment_data = fields.get("comment", {})
    comments = []
    for c in comment_data.get("comments", []):
        comments.append({
            "author": c.get("author", {}).get("displayName"),
            "created": c.get("created"),
            "updated": c.get("updated"),
            "body": flatten_adf(c.get("body")).rstrip("\n")
        })

    # Extract assignee and parent safely
    assignee_data = fields.get("assignee")
    assignee_name = assignee_data.get("displayName") if assignee_data else "Unassigned"
    
    parent_data = fields.get("parent")
    parent_key = parent_data.get("key") if parent_data else None

    result = {
        "id": issue.get("id"),
        "key": issue.get("key"),
        "parent": parent_key,
        "type": fields.get("issuetype", {}).get("name"),
        "summary": fields.get("summary"),
        "description": flatten_adf(fields.get("description")).rstrip("\n"),
        "comment": {
            "total": comment_data.get("total", 0),
            "comments": comments
        },
        "assignee": assignee_name,
        "status": fields.get("status", {}).get("name"),
        "priority": fields.get("priority", {}).get("name"),
        "labels": fields.get("labels", []),
        "components": [comp.get("name") for comp in fields.get("components", [])],
        "created": fields.get("created"),
        "updated": fields.get("updated")
    }

    # Statistical Metrics (Advanced Reporting)
    if "changelog" in issue:
        val = issue["changelog"]
        histories = sorted(val.get("histories", []), key=lambda x: parse_jira_time(x.get("created")))
        
        # Build timeline of status changes
        initial_status = None
        for h in histories:
            for item in h.get("items", []):
                if item.get("field") == "status":
                    initial_status = item.get("fromString")
                    break
            if initial_status: break
        
        # If we can't find fromString in the first history, assume the first toString was the change from 'New'
        if not initial_status:
            initial_status = "New"

        timeline = [{"status": initial_status, "time": parse_jira_time(fields.get("created"))}]
        transition_count = 0
        
        for h in histories:
            created_dt = parse_jira_time(h.get("created"))
            for item in h.get("items", []):
                if item.get("field") == "status":
                    timeline.append({"status": item.get("toString"), "time": created_dt})
                    transition_count += 1
        
        # Calculate time in each status
        time_in_status = {}
        time_in_category = {"To Do": 0, "In Progress": 0, "Done": 0}
        status_visit_counts = {}
        
        first_in_progress_time = None
        first_done_time = None
        
        for i in range(len(timeline)):
            start = timeline[i]
            s_name = start["status"]
            s_time = start["time"]
            
            # Track visits
            status_visit_counts[s_name] = status_visit_counts.get(s_name, 0) + 1
            
            # Resolve category for this transition
            cat = status_map.get(s_name) if status_map else None
            
            # Track first entry into In Progress and Done categories for Lead/Cycle times
            if cat == "In Progress" and first_in_progress_time is None:
                first_in_progress_time = s_time
            if cat == "Done" and first_done_time is None:
                first_done_time = s_time

            # Calculate duration for this slice
            end_time = timeline[i+1]["time"] if i+1 < len(timeline) else now
            duration = get_work_seconds(s_time, end_time)
            
            time_in_status[s_name] = time_in_status.get(s_name, 0) + duration
            if cat:
                time_in_category[cat] = time_in_category.get(cat, 0) + duration

        # Rework is defined as any visit after the first for a given status
        rework_count = sum(max(0, count - 1) for count in status_visit_counts.values())

        lead_time = get_work_seconds(timeline[0]["time"], first_done_time) if first_done_time else None
        cycle_time = get_work_seconds(first_in_progress_time, first_done_time) if first_in_progress_time and first_done_time else None

        current_status_duration = get_work_seconds(timeline[-1]["time"], now)
        
        result["metrics"] = {
            "transition_count": transition_count,
            "rework_count": rework_count,
            "status_visit_counts": status_visit_counts,
            "current_status_duration_seconds": current_status_duration,
            "current_status_duration_formatted": format_duration(current_status_duration),
            "lead_time_seconds": lead_time,
            "lead_time_formatted": format_duration(lead_time) if lead_time is not None else None,
            "cycle_time_seconds": cycle_time,
            "cycle_time_formatted": format_duration(cycle_time) if cycle_time is not None else None,
            "time_in_status_seconds": time_in_status,
            "time_in_status_formatted": {k: format_duration(v) for k, v in time_in_status.items()},
            "time_in_category_seconds": time_in_category,
            "time_in_category_formatted": {k: format_duration(v) for k, v in time_in_category.items()},
            "work_day_seconds": SECONDS_PER_WORK_DAY
        }

    # Handle requested expands
    for expand_key in requested_expands:
        if expand_key in issue:
            val = issue[expand_key]
            if expand_key == "changelog":
                processed_histories = []
                for h in val.get("histories", []):
                    items = []
                    for item in h.get("items", []):
                        items.append({
                            "field": item.get("field"),
                            "fieldId": item.get("fieldId"),
                            "from": item.get("from"),
                            "fromString": item.get("fromString"),
                            "to": item.get("to"),
                            "toString": item.get("toString")
                        })
                    processed_histories.append({
                        "id": h.get("id"),
                        "author": h.get("author", {}).get("displayName"),
                        "author_id": h.get("author", {}).get("accountId"),
                        "created": h.get("created"),
                        "items": items
                    })
                result["changelog"] = {"histories": processed_histories}
            elif expand_key == "transitions":
                transitions = []
                for t in val:
                    transitions.append({
                        "transitionId": t.get("id"),
                        "transitionname": t.get("name"),
                        "statusId": t.get("to", {}).get("id"),
                        "statusName": t.get("to", {}).get("name"),
                        "hasScreen": t.get("hasScreen"),
                        "isGlobal": t.get("isGlobal"),
                        "isInitial": t.get("isInitial"),
                        "isAvailable": t.get("isAvailable"),
                        "isConditional": t.get("isConditional"),
                        "isLooped": t.get("isLooped")
                    })
                result["transitions"] = transitions
            else:
                result[expand_key] = val

    if full_issue:
        result["original"] = issue
        
    return result

def get_status_map(client, project_key=None):
    """Fetch all statuses and their categories to build a mapping."""
    if project_key:
        endpoint = f"rest/api/{JIRA_API_VERSION}/project/{project_key}/statuses"
        try:
            response = client.call("GET", endpoint)
            # Flatten statuses from all issue types
            mapping = {}
            for itype in response:
                for status in itype.get("statuses", []):
                    mapping[status["name"]] = status.get("statusCategory", {}).get("name")
            return mapping
        except:
            pass
            
    # Fallback to global status list
    endpoint = f"rest/api/{JIRA_API_VERSION}/status"
    try:
        response = client.call("GET", endpoint)
        return {item["name"]: item.get("statusCategory", {}).get("name") for item in response}
    except:
        return {}

class JiraClient:
    def __init__(self, url, user, token, verbose=False):
        self.url = url.rstrip("/")
        self.user = user
        self.token = token
        self.verbose = verbose
        auth_str = f"{user}:{token}"
        self.auth_header = f"Basic {base64.b64encode(auth_str.encode()).decode()}"

    def call(self, method, endpoint, payload=None, query_params=None):
        if endpoint.startswith("http"):
            url = endpoint
        else:
            url = f"{self.url}/{endpoint.lstrip('/')}"
            
        if query_params:
            from urllib.parse import urlencode
            url = f"{url}?{urlencode(query_params)}"

        if self.verbose:
            err(f"Request: {method} {url}")
            if payload:
                err(f"Payload: {json.dumps(payload)}")

        data = json.dumps(payload).encode() if payload else None
        req = Request(url, data=data, method=method)
        req.add_header("Authorization", self.auth_header)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")

        try:
            with urlopen(req) as response:
                status_code = response.getcode()
                body = response.read().decode()
                if self.verbose:
                    err(f"HTTP Status: {status_code}")
                return json.loads(body) if body else {}
        except HTTPError as e:
            status_code = e.code
            body = e.read().decode()
            if self.verbose:
                err(f"HTTP Status: {status_code}")
                err(f"Response: {body}")
            
            error_map = {
                401: "Authentication failed (401).",
                403: "Forbidden (403).",
                404: "Not Found (404).",
                400: "Bad Request (400)."
            }
            die(error_map.get(status_code, f"Request failed with HTTP {status_code}."))
        except Exception as e:
            die(f"Request failed: {str(e)}")

# ---------------------------------------------------------------------------
# Subcommands
# ---------------------------------------------------------------------------

def cmd_jql(client, args):
    mandatory_fields = ["parent", "summary", "description", "status", "assignee", "issuetype", "comment", "created", "updated", "priority", "labels", "components"]
    fields_list = mandatory_fields
    if args.fields:
        fields_list = list(set(mandatory_fields + [f.strip() for f in args.fields.split(",") if f.strip()]))

    payload = {
        "jql": args.query,
        "maxResults": args.max_results,
        "fields": fields_list
    }
    
    requested_expands = [e.strip() for e in args.expand.split(",") if e.strip()]
    if requested_expands:
        payload["expand"] = ",".join(requested_expands)

    if args.param:
        for p in args.param:
            if '=' not in p:
                die(f"Error: --param requires key=value format (got: {p})")
            k, v = p.split('=', 1)
            # Try to convert to number if possible to match JQ behavior
            if v.isdigit():
                v = int(v)
            payload[k] = v

    endpoint = f"rest/api/{JIRA_API_VERSION}/search/jql"
    response = client.call("POST", endpoint, payload)

    if args.raw:
        print(json.dumps(response))
        return

    status_map = None
    if "changelog" in requested_expands:
        status_map = get_status_map(client, args.project)

    processed_issues = [process_issue(issue, requested_expands, args.full_issue, status_map) for issue in response.get("issues", [])]
    output = {
        "isLast": response.get("isLast", True),
        "resultsOnPage": len(processed_issues),
        "nextPageToken": response.get("nextPageToken"),
        "issues": processed_issues
    }
    # Include any top-level expands present in source
    for expand_key in requested_expands:
        if expand_key in response:
            output[expand_key] = response[expand_key]

    print(json.dumps(output))

def cmd_issues(client, args):
    fields_list = None
    if args.fields:
        fields_list = [f.strip() for f in args.fields.split(",") if f.strip()]
    
    requested_expands = [e.strip() for e in args.expand.split(",") if e.strip()]
    
    payload = {"issueIdsOrKeys": args.ids}
    if fields_list:
        payload["fields"] = fields_list
    if requested_expands:
        payload["expand"] = requested_expands

    endpoint = f"rest/api/{JIRA_API_VERSION}/issue/bulkfetch"
    response = client.call("POST", endpoint, payload)

    if args.raw:
        print(json.dumps(response))
        return

    status_map = None
    if "changelog" in requested_expands:
        status_map = get_status_map(client, args.project)

    processed_issues = [process_issue(issue, requested_expands, args.full_issue, status_map) for issue in response.get("issues", [])]
    output = {
        "isLast": response.get("isLast", True),
        "resultsOnPage": len(processed_issues),
        "nextPageToken": response.get("nextPageToken"),
        "issues": processed_issues
    }
    # Include any top-level expands present in source
    for expand_key in requested_expands:
        if expand_key in response:
            output[expand_key] = response[expand_key]

    print(json.dumps(output))

def cmd_fields(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/field"
    response = client.call("GET", endpoint)
    
    if args.raw:
        print(json.dumps(response))
        return

    if args.filter:
        f = args.filter.lower()
        response = [item for item in response if f in item.get("name", "").lower()]

    result = {item["id"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_statuses(client, args):
    if args.project:
        endpoint = f"rest/api/{JIRA_API_VERSION}/project/{args.project}/statuses"
        response = client.call("GET", endpoint)
        # Flatten statuses from all issue types
        all_statuses = []
        seen_ids = set()
        for itype in response:
            for status in itype.get("statuses", []):
                sid = status["id"]
                if sid not in seen_ids:
                    all_statuses.append(status)
                    seen_ids.add(sid)
        response = all_statuses
    else:
        endpoint = f"rest/api/{JIRA_API_VERSION}/status"
        response = client.call("GET", endpoint)

    if args.raw:
        print(json.dumps(response))
        return

    result = {
        item["id"]: {
            "name": item["name"],
            "category": item.get("statusCategory", {}).get("name")
        }
        for item in response
    }
    
    if args.category:
        cat = args.category.lower().replace(" ", "-")
        result = {k: v for k, v in result.items() if v["category"].lower().replace(" ", "-") == cat}

    print(json.dumps(result))

def cmd_types(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/issuetype"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["id"]: {"name": item["name"], "subtask": item.get("subtask")} for item in response}
    print(json.dumps(result))

def cmd_priorities(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/priority"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["id"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_resolutions(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/resolution"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["id"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_projects(client, args):
    endpoint = f"rest/api/{JIRA_API_VERSION}/project"
    response = client.call("GET", endpoint)
    if args.raw:
        print(json.dumps(response))
        return
    result = {item["key"]: item["name"] for item in response}
    print(json.dumps(result))

def cmd_users(client, args):
    endpoint = "rest/api/3/user/search"
    if args.project:
        endpoint = "rest/api/3/user/assignable/search"
    
    query_params = {"maxResults": args.max_results}
    if args.query:
        query_params["query"] = args.query
    if args.project:
        query_params["project"] = args.project
    if args.expand:
        query_params["expand"] = args.expand

    response = client.call("GET", endpoint, query_params=query_params)
    
    if args.raw:
        print(json.dumps(response))
        return

    if args.exact and args.query:
        q = args.query.lower()
        response = [u for u in response if u.get("displayName", "").lower() == q or u.get("emailAddress", "").lower() == q]

    if args.full:
        print(json.dumps(response))
    else:
        result = {u["accountId"]: u["displayName"] for u in response}
        print(json.dumps(result))

def cmd_call(client, args):
    response = client.call(args.method, args.endpoint, payload=json.loads(args.payload) if args.payload else None)
    print(json.dumps(response))

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

    globals()[f"cmd_{args.subcommand}"](client, args)

if __name__ == "__main__":
    main()
