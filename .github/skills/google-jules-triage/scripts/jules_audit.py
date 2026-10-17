#!/usr/bin/env python3
"""
jules_audit.py: Audit Google Jules coding sessions for completeness, health state, and stuck runners.

Enumerate non-archived sessions from Google Jules REST API, inspect full activity histories,
detect empty-commit loops, evaluate user feedback responsiveness, and output a structured coverage table.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Any
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

# Add peer skill scripts directory for JulesClient import
scripts_dir = Path(__file__).resolve().parent
skills_dir = scripts_dir.parent.parent
api_scripts_dir = skills_dir / "google-jules-api" / "scripts"
if str(api_scripts_dir) not in sys.path:
    sys.path.insert(0, str(api_scripts_dir))

try:
    from jules.client import JulesClient
except ImportError:
    JulesClient = None  # Fallback client provided below if needed


DEFAULT_BASE_URL = "https://jules.googleapis.com/v1alpha"


class SimpleJulesClient:
    """Minimal Jules REST API client if peer jules package is unavailable."""

    def __init__(self, api_key: str, base_url: str = DEFAULT_BASE_URL, timeout: int = 120) -> None:
        self.api_key = api_key.strip()
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    def call(
        self,
        method: str,
        endpoint: str,
        payload: dict[str, Any] | None = None,
        query_params: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        clean_endpoint = endpoint.lstrip("/")
        url = f"{self.base_url}/{clean_endpoint}"
        if query_params:
            filtered = {k: v for k, v in query_params.items() if v is not None and v != ""}
            if filtered:
                url = f"{url}?{urlencode(filtered)}"

        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        req = Request(url, data=data, method=method.upper())
        req.add_header("X-Goog-Api-Key", self.api_key)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")

        try:
            with urlopen(req, timeout=self.timeout) as resp:
                body = resp.read().decode("utf-8")
                return json.loads(body) if body.strip() else {}
        except HTTPError as e:
            raw = e.read().decode("utf-8") if e.fp else ""
            sys.stderr.write(f"Error: HTTP {e.code} for {url}: {raw}\n")
            sys.exit(1)
        except Exception as e:
            sys.stderr.write(f"Error: Network request failed: {e}\n")
            sys.exit(1)

    def list_sessions(
        self,
        page_size: int = 50,
        page_token: str | None = None,
        filter_expr: str | None = None,
    ) -> dict[str, Any]:
        params: dict[str, Any] = {"pageSize": page_size}
        if page_token:
            params["pageToken"] = page_token
        if filter_expr:
            params["filter"] = filter_expr
        return self.call("GET", "sessions", query_params=params)

    def get_session(self, session_id: str) -> dict[str, Any]:
        sid = session_id.strip().removeprefix("sessions/")
        return self.call("GET", f"sessions/{sid}")

    def list_activities(
        self,
        session_id: str,
        page_size: int = 50,
        page_token: str | None = None,
    ) -> dict[str, Any]:
        sid = session_id.strip().removeprefix("sessions/")
        params: dict[str, Any] = {"pageSize": page_size}
        if page_token:
            params["pageToken"] = page_token
        return self.call("GET", f"sessions/{sid}/activities", query_params=params)

    def get_all_activities(self, session_id: str) -> list[dict[str, Any]]:
        sid = session_id.strip().removeprefix("sessions/")
        activities: list[dict[str, Any]] = []
        page_token: str | None = None
        while True:
            res = self.list_activities(session_id=sid, page_size=50, page_token=page_token)
            batch = res.get("activities", [])
            activities.extend(batch)
            page_token = res.get("nextPageToken")
            if not page_token or not batch:
                break
        return activities


def get_client(api_key: str, timeout: int = 120) -> Any:
    if JulesClient is not None:
        try:
            return JulesClient(api_key=api_key, timeout=timeout)
        except TypeError:
            return JulesClient(api_key=api_key)
    return SimpleJulesClient(api_key=api_key, timeout=timeout)


def parse_dt(dt_str: str | None) -> datetime | None:
    if not dt_str:
        return None
    try:
        clean = dt_str.replace("Z", "+00:00")
        return datetime.fromisoformat(clean)
    except Exception:
        return None


def format_dt(dt_str: str | None) -> str:
    dt = parse_dt(dt_str)
    if not dt:
        return "-"
    return dt.strftime("%Y-%m-%d %H:%M")


_PR_CACHE: dict[str, dict[str, Any]] = {}


def inspect_github_pr(pr_url: str) -> dict[str, Any]:
    """Inspect PR via gh CLI to check mergeability and empty commits."""
    if pr_url in _PR_CACHE:
        return _PR_CACHE[pr_url]
    m = re.search(r"github\.com/([^/]+)/([^/]+)/pull/(\d+)", pr_url)
    if not m:
        return {}
    owner, repo, pr_num = m.groups()
    repo_slug = f"{owner}/{repo}"

    result: dict[str, Any] = {
        "mergeable": "UNKNOWN",
        "empty_commits_count": 0,
        "commits_count": 0,
        "pr_state": "UNKNOWN",
    }
    try:
        proc = subprocess.run(
            [
                "gh",
                "pr",
                "view",
                pr_num,
                "--repo",
                repo_slug,
                "--json",
                "number,mergeable,commits,state",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            pr_data = json.loads(proc.stdout)
            result["mergeable"] = pr_data.get("mergeable", "UNKNOWN")
            result["pr_state"] = pr_data.get("state", "UNKNOWN")
            commits = pr_data.get("commits", [])
            result["commits_count"] = len(commits)

            empty_count = 0
            for c in commits:
                msg = (c.get("messageHeadline", "") + " " + c.get("messageBody", "")).lower()
                if "reject empty commit" in msg or "trigger rebuild" in msg:
                    empty_count += 1

            if empty_count < 2 and len(commits) <= 10:
                for c in commits:
                    sha = c.get("oid") or c.get("sha")
                    if not sha:
                        continue
                    c_proc = subprocess.run(
                        ["gh", "api", f"repos/{repo_slug}/commits/{sha}", "--jq", ".files | length"],
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    if c_proc.returncode == 0 and c_proc.stdout.strip() == "0":
                        empty_count += 1
            result["empty_commits_count"] = empty_count
    except Exception:
        pass
    _PR_CACHE[pr_url] = result
    return result


def _extract_outputs_info(session: dict[str, Any]) -> tuple[str, bool, list[str]]:
    """Extract PR URL, patch availability, and modified file list from session outputs."""
    pr_url = ""
    has_git_patch = False
    patch_files: list[str] = []

    for out in session.get("outputs", []):
        if not pr_url and "pullRequest" in out:
            pr_url = out["pullRequest"].get("url", "")
        cs = out.get("changeSet") or {}
        raw_patch = (cs.get("gitPatch") or {}).get("unidiffPatch") or ""
        if raw_patch or cs.get("suggestedCommitMessage"):
            has_git_patch = True
            if raw_patch:
                patch_files = re.findall(r"^diff --git a/(.*?) b/", raw_patch, re.MULTILINE)

    return pr_url, has_git_patch, patch_files


def _process_activities(
    session: dict[str, Any],
    activities: list[dict[str, Any]] | None,
    has_git_patch: bool,
) -> dict[str, Any]:
    """Parse session activity timeline into structured user/agent state and timestamps."""
    created_time = session.get("createTime", "")
    updated_time = session.get("updateTime", "")
    state = session.get("state", "UNKNOWN")

    user_messages: list[dict[str, Any]] = []
    agent_messages: list[dict[str, Any]] = []
    agent_activities: list[dict[str, Any]] = []

    last_user_time: datetime | None = None
    last_agent_time: datetime | None = None
    last_agent_msg_time: datetime | None = None
    last_user_msg: str = ""
    last_agent_msg: str = ""
    pending_plan_id: str | None = None

    prompt = (session.get("prompt") or "").strip()
    if prompt:
        p_time = parse_dt(created_time)
        user_messages.append({"content": prompt, "time": p_time})
        last_user_msg = prompt
        last_user_time = p_time

    safe_activities = activities or []

    for act in safe_activities:
        act_time_str = act.get("createTime", "")
        act_time = parse_dt(act_time_str)

        if "userMessaged" in act:
            umsg = act["userMessaged"].get("userMessage", "").strip()
            user_messages.append({"content": umsg, "time": act_time})
            last_user_msg = umsg
            last_user_time = act_time
        elif "planApproved" in act:
            pending_plan_id = None
            user_messages.append({"content": "Plan approved", "time": act_time})
            last_user_time = act_time

        if "artifacts" in act:
            for art in act.get("artifacts", []):
                cs = art.get("changeSet") or {}
                if cs.get("gitPatch") or cs.get("suggestedCommitMessage"):
                    has_git_patch = True
                    break

        if "agentMessaged" in act:
            amsg = act["agentMessaged"].get("agentMessage", "").strip()
            agent_messages.append({"content": amsg, "time": act_time})
            agent_activities.append({"type": "Agent Message", "content": amsg, "time": act_time})
            last_agent_msg = amsg
            last_agent_time = act_time
            last_agent_msg_time = act_time
        elif "planGenerated" in act:
            plan = act["planGenerated"].get("plan", {})
            pending_plan_id = plan.get("id") or "plan"
            agent_activities.append({"type": "Plan Generated", "content": f"Plan {pending_plan_id}", "time": act_time})
            last_agent_time = act_time
        elif "progressUpdated" in act:
            pending_plan_id = None
            pu = act["progressUpdated"]
            pu_title = pu.get("title", "")
            agent_activities.append({"type": "Progress Update", "content": pu_title, "time": act_time})
            last_agent_time = act_time
        elif "artifacts" in act:
            agent_activities.append({"type": "Artifacts", "content": "Artifacts produced", "time": act_time})
            last_agent_time = act_time

    last_activity_display: str = ""
    latest_act_time: datetime | None = None

    if safe_activities:
        latest_act = safe_activities[-1]
        lat_time = format_dt(latest_act.get("createTime"))
        type_keys = [
            k for k in latest_act.keys() if k not in ("id", "name", "createTime", "originator")
        ]
        lat_type = type_keys[0] if type_keys else "Activity"
        type_names = {
            "agentMessaged": "Agent Message",
            "userMessaged": "User Message",
            "planGenerated": "Plan Generated",
            "planApproved": "Plan Approved",
            "progressUpdated": "Progress Update",
            "sessionCompleted": "Completed",
            "artifacts": "Artifacts",
        }
        friendly_type = type_names.get(lat_type, lat_type)
        last_activity_display = f"{lat_time} ({friendly_type})"
        latest_act_time = parse_dt(latest_act.get("createTime"))
    else:
        disp_time = updated_time or created_time
        disp_type = "Completed" if state == "COMPLETED" else "Created"
        last_activity_display = f"{format_dt(disp_time)} ({disp_type})"
        latest_act_time = parse_dt(disp_time)

    return {
        "user_messages": user_messages,
        "agent_messages": agent_messages,
        "agent_activities": agent_activities,
        "last_user_time": last_user_time,
        "last_agent_time": last_agent_time,
        "last_agent_msg_time": last_agent_msg_time,
        "last_user_msg": last_user_msg,
        "last_agent_msg": last_agent_msg,
        "pending_plan_id": pending_plan_id,
        "has_git_patch": has_git_patch,
        "last_activity_display": last_activity_display,
        "latest_act_time": latest_act_time,
    }


def _is_junk_session(agent_messages: list[dict[str, Any]]) -> bool:
    """Determine if session consists solely of degenerate / short / CJK / rubber-stamp agent messages."""
    if not agent_messages or len(agent_messages) < 2:
        return False

    for m in agent_messages:
        text = m["content"].strip()
        is_short = len(text) <= 2
        is_cjk = any("\u4e00" <= ch <= "\u9fff" for ch in text)
        is_rubber_stamp = "Code review rating is #Correct#" in text
        if not (is_short or is_cjk or is_rubber_stamp):
            return False

    return True


def _classify_verdict(
    is_junk: bool,
    empty_commit_loop: bool,
    stale_branch: bool,
    pr_url: str,
    pending_plan_id: str | None,
    state: str,
    agent_awaiting_reply: bool,
    has_git_patch: bool,
    patch_files: list[str],
    user_newer_than_agent: bool,
    inactive_mins: float,
    stale_threshold_mins: int,
    max_age_days: int,
    age_days: float,
) -> str:
    """Classify the session's health verdict."""
    if is_junk:
        return "JUNK"
    if empty_commit_loop:
        return "EMPTY_COMMIT_LOOP"
    if stale_branch:
        return "STALE_BRANCH"
    if pr_url:
        return "COMPLETED_WITH_PR"
    if pending_plan_id or state == "AWAITING_PLAN_APPROVAL":
        return "PLAN_GATE"
    if agent_awaiting_reply or state == "AWAITING_USER_FEEDBACK":
        return "FEEDBACK_GATE"
    if state == "COMPLETED":
        if has_git_patch:
            files_summary = (
                f" ({len(patch_files)} files: {', '.join(patch_files[:2])}{'...' if len(patch_files) > 2 else ''})"
                if patch_files
                else ""
            )
            return f"UNDELIVERED_PATCH{files_summary}"
        return "CLOSED_NO_PR"
    if state == "FAILED":
        return "FAILED"
    if user_newer_than_agent:
        return "AWAITING_AGENT"
    if state == "IN_PROGRESS":
        if inactive_mins >= stale_threshold_mins:
            return "STALLED"
        return "ACTIVE"
    if max_age_days and age_days > max_age_days:
        return "INACTIVE"
    return state


def audit_session(
    session: dict[str, Any],
    activities: list[dict[str, Any]],
    check_pr: bool = False,
    stale_threshold_mins: int = 60,
    max_age_days: int = 30,
) -> dict[str, Any]:
    """Audit a single session, evaluating full activity history and responsiveness."""
    sid = session.get("id") or session.get("name", "").removeprefix("sessions/")
    raw_title = session.get("title") or session.get("prompt", "Untitled Session")
    title = " ".join(raw_title.split())
    state = session.get("state", "UNKNOWN")
    created_time = session.get("createTime", "")
    updated_time = session.get("updateTime", "")

    now = datetime.now(timezone.utc)

    pr_url, initial_patch, patch_files = _extract_outputs_info(session)
    act_data = _process_activities(session, activities, initial_patch)

    has_git_patch = act_data["has_git_patch"]
    latest_act_time = act_data["latest_act_time"]
    last_user_time = act_data["last_user_time"]
    last_agent_time = act_data["last_agent_time"]
    last_agent_msg_time = act_data["last_agent_msg_time"]
    last_user_msg = act_data["last_user_msg"]
    last_agent_msg = act_data["last_agent_msg"]
    pending_plan_id = act_data["pending_plan_id"]

    inactive_mins = 0.0
    if latest_act_time:
        inactive_mins = max(0.0, (now - latest_act_time).total_seconds() / 60.0)

    c_time = parse_dt(created_time or updated_time)
    age_days = (now - c_time).total_seconds() / 86400.0 if c_time else 0.0

    is_junk = _is_junk_session(act_data["agent_messages"])

    agent_awaiting_reply = False
    if last_agent_msg_time and (not last_user_time or last_agent_msg_time > last_user_time):
        if last_agent_msg:
            lower_msg = last_agent_msg.lower()
            if any(
                q in lower_msg
                for q in ["confirm", "approve", "proceed", "look good", "?", "let me know", "feedback"]
            ):
                agent_awaiting_reply = True

    user_newer_than_agent = False
    if last_user_time:
        if not last_agent_time or last_user_time > last_agent_time:
            user_newer_than_agent = True

    empty_commit_loop = False
    stale_branch = False
    pr_details: dict[str, Any] = {}
    if check_pr and pr_url:
        pr_details = inspect_github_pr(pr_url)
        if pr_details.get("empty_commits_count", 0) >= 2:
            empty_commit_loop = True
        if pr_details.get("mergeable") == "CONFLICTING":
            stale_branch = True

    verdict = _classify_verdict(
        is_junk=is_junk,
        empty_commit_loop=empty_commit_loop,
        stale_branch=stale_branch,
        pr_url=pr_url,
        pending_plan_id=pending_plan_id,
        state=state,
        agent_awaiting_reply=agent_awaiting_reply,
        has_git_patch=has_git_patch,
        patch_files=patch_files,
        user_newer_than_agent=user_newer_than_agent,
        inactive_mins=inactive_mins,
        stale_threshold_mins=stale_threshold_mins,
        max_age_days=max_age_days,
        age_days=age_days,
    )

    return {
        "id": sid,
        "title": title,
        "state": state,
        "last_activity": act_data["last_activity_display"],
        "last_user_message": last_user_msg,
        "verdict": verdict,
        "inactive_mins": round(inactive_mins, 1),
        "age_days": round(age_days, 1),
        "pull_request_url": pr_url,
        "pr_details": pr_details,
        "user_newer_than_agent": user_newer_than_agent,
        "has_git_patch": has_git_patch,
    }


def format_table(audits: list[dict[str, Any]]) -> str:
    """Format audit results as a markdown table with mandatory coverage columns."""
    if not audits:
        return "_No sessions found._"

    lines = [
        "| id | title | state | last-activity | last-user-msg | verdict |",
        "|---|---|---|---|---|---|",
    ]
    for a in audits:
        sid = a["id"]
        title = a["title"]
        if len(title) > 50:
            title = title[:47] + "..."
        title = title.replace("|", "\\|")

        state = a["state"]
        last_act = a["last_activity"].replace("|", "\\|")
        last_user = a["last_user_message"]
        if not last_user:
            last_user_display = "-"
        else:
            clean_u = " ".join(last_user.split())
            if len(clean_u) > 50:
                clean_u = clean_u[:47] + "..."
            last_user_display = clean_u.replace("|", "\\|")

        verdict = a["verdict"]
        lines.append(f"| {sid} | {title} | {state} | {last_act} | {last_user_display} | {verdict} |")

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Audit Google Jules coding sessions for completeness, health state, and stuck runners."
    )
    parser.add_argument(
        "--all-pages",
        "--all",
        dest="all_pages",
        action="store_true",
        help="Audit non-archived sessions across all paginated pages (stops once sessions exceed max age).",
    )
    parser.add_argument(
        "--session",
        "-s",
        action="append",
        default=[],
        help="Specific session ID(s) to audit (can be specified multiple times).",
    )
    parser.add_argument(
        "positional_sessions",
        nargs="*",
        default=[],
        help="Optional positional session ID(s) to audit.",
    )
    parser.add_argument(
        "--with-pr",
        action="store_true",
        help="Inspect associated PR branches and commits via gh CLI.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output audit results as JSON instead of Markdown table.",
    )
    parser.add_argument(
        "--classify",
        action="store_true",
        help="Enforce detailed verdict classification.",
    )
    parser.add_argument(
        "--repo",
        help="Filter sessions by repository name or owner/repo.",
    )
    parser.add_argument(
        "--max-age-days",
        "--days",
        dest="max_age_days",
        type=int,
        default=30,
        help="Filter out sessions older than N days (default: 30, 0 for no limit).",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=120,
        help="HTTP / network timeout in seconds (default: 120).",
    )
    parser.add_argument(
        "--include-archived",
        action="store_true",
        help="Include archived sessions in audit (default: skip archived sessions).",
    )
    parser.add_argument(
        "--stale-threshold-mins",
        type=int,
        default=60,
        help="Minutes without activity before in-progress session is STALLED (default: 60).",
    )

    args = parser.parse_args()
    setattr(args, "days", args.max_age_days)
    setattr(args, "all", args.all_pages)

    import socket
    socket.setdefaulttimeout(args.timeout)

    # Secret handling: must come from environment, never invoke secret provider
    api_key = os.environ.get("JULES_API_KEY")
    if not api_key or not api_key.strip():
        sys.stderr.write(
            "Error: JULES_API_KEY environment variable is required.\n"
            "Export JULES_API_KEY or run via 'cloakenv run -- ...'.\n"
        )
        sys.exit(1)

    target_sessions = list(args.session) + list(args.positional_sessions)

    if not args.all_pages and not target_sessions:
        sys.stderr.write(
            "Error: Must specify --all-pages or at least one --session ID.\n"
            "Use --help for usage information.\n"
        )
        sys.exit(1)

    client = get_client(api_key.strip(), timeout=args.timeout)

    session_items: list[dict[str, Any]] = []
    now = datetime.now(timezone.utc)

    if args.all_pages:
        page_token: str | None = None
        page_num = 0
        filter_expr = None if args.include_archived else "archived=false"
        while True:
            page_num += 1
            sys.stderr.write(
                f"Fetching sessions page {page_num}... ({len(session_items)} collected so far)\n"
            )
            sys.stderr.flush()
            res = client.list_sessions(page_size=50, page_token=page_token, filter_expr=filter_expr)
            batch = res.get("sessions", [])
            if not batch:
                break
            reached_max_age = False
            for s in batch:
                if not args.include_archived and s.get("archived") is True:
                    continue
                if args.max_age_days and args.max_age_days > 0:
                    ts = s.get("updateTime") or s.get("createTime")
                    if ts:
                        dt = parse_dt(ts)
                        if dt:
                            age_days = (now - dt).total_seconds() / 86400.0
                            if age_days > args.max_age_days:
                                reached_max_age = True
                                continue
                session_items.append(s)

            if reached_max_age and args.max_age_days and args.max_age_days > 0:
                break

            page_token = res.get("nextPageToken")
            if not page_token:
                break
    else:
        for sid in target_sessions:
            s_data = client.get_session(sid)
            session_items.append(s_data)

    if args.repo:
        clean_repo = args.repo.strip().removeprefix("sources/").removeprefix("github/").lower()
        session_items = [
            s
            for s in session_items
            if clean_repo
            in s.get("sourceContext", {}).get("source", "").removeprefix("sources/").removeprefix("github/").lower()
        ]

    filtered_sessions: list[dict[str, Any]] = []
    for s in session_items:
        if args.max_age_days and args.max_age_days > 0:
            ts = s.get("createTime") or s.get("updateTime")
            if ts:
                dt = parse_dt(ts)
                if dt:
                    age_days = (now - dt).total_seconds() / 86400.0
                    if age_days > args.max_age_days:
                        continue
        filtered_sessions.append(s)

    # Batch pre-populate PR cache if checking PRs
    if getattr(args, "with_pr", False):
        repos_seen = set()
        for s in filtered_sessions:
            src = s.get("sourceContext", {}).get("source", "").removeprefix("sources/").removeprefix("github/")
            if src and "/" in src:
                repos_seen.add(src)
        for repo_slug in repos_seen:
            try:
                proc = subprocess.run(
                    ["gh", "pr", "list", "--repo", repo_slug, "--state", "all", "--limit", "100", "--json", "number,url,mergeable,commits,state"],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                if proc.returncode == 0 and proc.stdout.strip():
                    for item in json.loads(proc.stdout):
                        u = item.get("url")
                        if u:
                            commits = item.get("commits", [])
                            _PR_CACHE[u] = {
                                "mergeable": item.get("mergeable", "UNKNOWN"),
                                "pr_state": item.get("state", "UNKNOWN"),
                                "commits_count": len(commits),
                                "empty_commits_count": 0,
                            }
            except Exception:
                pass

    audits: list[dict[str, Any]] = []
    total = len(filtered_sessions)
    for idx, s in enumerate(filtered_sessions, 1):
        sid = s.get("id") or s.get("name", "").removeprefix("sessions/")
        has_pr = any("pullRequest" in out for out in s.get("outputs", []))
        is_completed = s.get("state") == "COMPLETED"

        sys.stderr.write(f"[{idx}/{total}] Auditing session {sid}...\n")
        sys.stderr.flush()

        # Optimization: bypass N+1 activity fetching for completed sessions that already delivered a PR
        if is_completed and has_pr and not getattr(args, "classify", False):
            activities = []
        else:
            try:
                activities = client.get_all_activities(sid)
            except Exception as e:
                sys.stderr.write(f"Warning: Failed to fetch activities for session {sid}: {e}\n")
                activities = []

        audit_res = audit_session(
            session=s,
            activities=activities,
            check_pr=args.with_pr,
            stale_threshold_mins=args.stale_threshold_mins,
            max_age_days=args.max_age_days,
        )
        audits.append(audit_res)

    if args.json:
        print(json.dumps(audits, indent=2))
    else:
        print(format_table(audits))


if __name__ == "__main__":
    main()
