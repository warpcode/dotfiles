from typing import Any
from .utils import format_datetime


def format_sources(data: dict[str, Any]) -> str:
    """Format a list of connected sources as a token-efficient markdown table."""
    sources = data.get("sources", [])
    if not sources:
        return "_No connected repositories found._"

    lines = [
        "| Source ID | Default Branch | Branches |",
        "|---|---|:---:|",
    ]
    for s in sources:
        sid = s.get("id") or s.get("name", "").removeprefix("sources/")
        repo_info = s.get("githubRepo", {})
        default_branch = repo_info.get("defaultBranch", {}).get("displayName", "N/A")
        branch_count = len(repo_info.get("branches", []))
        lines.append(f"| `{sid}` | `{default_branch}` | {branch_count} |")

    next_token = data.get("nextPageToken")
    if next_token:
        lines.append(f"\n_Next Page Token:_ `{next_token}`")

    return "\n".join(lines)


def format_source(data: dict[str, Any]) -> str:
    """Format details of a single source."""
    name = data.get("name", "N/A")
    sid = data.get("id") or name.removeprefix("sources/")
    repo_info = data.get("githubRepo", {})
    owner = repo_info.get("owner", "N/A")
    repo = repo_info.get("repo", "N/A")
    default_branch = repo_info.get("defaultBranch", {}).get("displayName", "N/A")
    branches = [b.get("displayName") for b in repo_info.get("branches", []) if b.get("displayName")]

    lines = [
        f"## Source: `{sid}`",
        f"- **Repository:** `{owner}/{repo}`",
        f"- **Default Branch:** `{default_branch}`",
        f"- **Active Branches ({len(branches)}):**",
    ]
    if branches:
        for b in branches[:15]:
            lines.append(f"  - `{b}`")
        if len(branches) > 15:
            lines.append(f"  - _...and {len(branches) - 15} more branches_")
    else:
        lines.append("  - _No branches reported_")

    return "\n".join(lines)


def format_sessions(data: dict[str, Any]) -> str:
    """Format a list of sessions as a token-efficient markdown table."""
    sessions = data.get("sessions", [])
    if not sessions:
        return "_No sessions found._"

    lines = [
        "| Session ID | State | Repository | Prompt / Title | PR / Output |",
        "|---|---|---|---|---|",
    ]
    for s in sessions:
        sid = s.get("id") or s.get("name", "").removeprefix("sessions/")
        state = s.get("state", "UNKNOWN")
        source_ctx = s.get("sourceContext", {})
        source_name = source_ctx.get("source", "").removeprefix("sources/")
        branch = source_ctx.get("githubRepoContext", {}).get("startingBranch", "")
        repo_display = f"`{source_name}` (`{branch}`)" if branch else f"`{source_name}`"

        title = s.get("title") or s.get("prompt", "")
        if len(title) > 60:
            title = title[:57] + "..."
        title = title.replace("\n", " ").replace("|", "\\|")

        pr_info = ""
        for out in s.get("outputs", []):
            if "pullRequest" in out:
                pr = out["pullRequest"]
                pr_url = pr.get("url")
                pr_info = f"[PR #{pr_url.split('/')[-1]}]({pr_url})" if pr_url else "PR Created"
                break

        lines.append(f"| `{sid}` | **{state}** | {repo_display} | {title} | {pr_info or '-'} |")

    next_token = data.get("nextPageToken")
    if next_token:
        lines.append(f"\n_Next Page Token:_ `{next_token}`")

    return "\n".join(lines)


def format_session(data: dict[str, Any]) -> str:
    """Format complete details of a single Jules session."""
    sid = data.get("id") or data.get("name", "").removeprefix("sessions/")
    title = data.get("title") or "Untitled Task"
    state = data.get("state", "UNKNOWN")
    created = format_datetime(data.get("createTime"))
    updated = format_datetime(data.get("updateTime"))
    url = data.get("url", "")
    prompt = data.get("prompt", "")

    source_ctx = data.get("sourceContext", {})
    source_name = source_ctx.get("source", "").removeprefix("sources/")
    branch = source_ctx.get("githubRepoContext", {}).get("startingBranch", "main")

    lines = [
        f"# Jules Session: `{sid}`",
        f"- **Title:** {title}",
        f"- **State:** **{state}**",
        f"- **Created:** {created} | **Updated:** {updated}",
    ]
    if url:
        lines.append(f"- **Jules UI URL:** [{url}]({url})")

    lines.extend([
        f"- **Source:** `{source_name}` (base branch: `{branch}`)",
        "",
        "### Task Prompt",
        f"> {prompt}",
    ])

    outputs = data.get("outputs", [])
    if outputs:
        lines.append("\n### Outputs")
        for out in outputs:
            if "pullRequest" in out:
                pr = out["pullRequest"]
                lines.extend([
                    "#### Pull Request",
                    f"- **Title:** {pr.get('title', 'N/A')}",
                    f"- **URL:** [{pr.get('url')}]({pr.get('url')})",
                    f"- **Branch:** `{pr.get('baseRef')}` &larr; `{pr.get('headRef')}`",
                ])
                if pr.get("description"):
                    lines.append(f"- **Description:** {pr.get('description')}")
            elif "changeSet" in out:
                cs = out["changeSet"]
                patch_info = cs.get("gitPatch", {})
                suggested_msg = patch_info.get("suggestedCommitMessage", "")
                base_commit = patch_info.get("baseCommitId", "")
                lines.extend([
                    "#### Change Set",
                    f"- **Base Commit:** `{base_commit}`",
                ])
                if suggested_msg:
                    lines.append(f"- **Suggested Commit Message:**\n```\n{suggested_msg}\n```")

    return "\n".join(lines)


def format_activities(data: dict[str, Any], session_id: str = "") -> str:
    """Format activities and events timeline of a session."""
    activities = data.get("activities", [])
    if not activities:
        return "_No activities recorded for this session._"

    lines = [
        f"## Session Activities ({len(activities)} events)",
        "",
        "| Event ID | Time (UTC) | Originator | Type | Summary |",
        "|---|---|---|---|---|",
    ]

    for a in activities:
        aid = a.get("id") or a.get("name", "").split("/")[-1]
        time_str = format_datetime(a.get("createTime"))
        originator = a.get("originator", "unknown")

        event_type = "Generic"
        summary = "-"

        if "planGenerated" in a:
            event_type = "Plan Generated"
            plan = a["planGenerated"].get("plan", {})
            steps = plan.get("steps", [])
            summary = f"Plan `{plan.get('id', '')[:8]}` ({len(steps)} steps)"
        elif "planApproved" in a:
            event_type = "Plan Approved"
            plan_id = a["planApproved"].get("planId", "")
            summary = f"Approved Plan `{plan_id[:8]}`"
        elif "agentMessaged" in a:
            event_type = "Agent Message"
            msg = a["agentMessaged"].get("agentMessage", "").replace("\n", " ")
            summary = (msg[:60] + "...") if len(msg) > 60 else msg
        elif "userMessaged" in a:
            event_type = "User Message"
            msg = a["userMessaged"].get("userMessage", "").replace("\n", " ")
            summary = (msg[:60] + "...") if len(msg) > 60 else msg
        elif "progressUpdated" in a:
            event_type = "Progress Update"
            p_title = a["progressUpdated"].get("title", "")
            summary = (p_title[:60] + "...") if len(p_title) > 60 else (p_title or "Status updated")
        elif "artifacts" in a:
            event_type = "Artifacts"
            artifacts = a.get("artifacts", [])
            summary = f"{len(artifacts)} patch/artifact(s)"

        summary_clean = summary.replace("|", "\\|")
        lines.append(f"| `{aid[:8]}` | {time_str} | **{originator}** | {event_type} | {summary_clean} |")

    next_token = data.get("nextPageToken")
    if next_token:
        lines.append(f"\n_Next Page Token:_ `{next_token}`")

    return "\n".join(lines)


def format_activity(data: dict[str, Any]) -> str:
    """Format full details of a single activity event."""
    aid = data.get("id") or data.get("name", "").split("/")[-1]
    originator = data.get("originator", "unknown")
    time_str = format_datetime(data.get("createTime"))

    lines = [
        f"## Activity: `{aid}`",
        f"- **Originator:** `{originator}`",
        f"- **Timestamp:** {time_str}",
    ]

    if "planGenerated" in data:
        plan = data["planGenerated"].get("plan", {})
        lines.extend([
            "",
            f"### Plan Details (`{plan.get('id', 'N/A')}`)",
        ])
        for step in plan.get("steps", []):
            idx = step.get("index", 0) + 1
            lines.extend([
                f"#### Step {idx}: {step.get('title', 'Untitled Step')}",
                step.get("description", "_No description_"),
                "",
            ])

    if "planApproved" in data:
        lines.append(f"- **Approved Plan ID:** `{data['planApproved'].get('planId')}`")

    if "agentMessaged" in data:
        lines.extend([
            "",
            "### Agent Message",
            data["agentMessaged"].get("agentMessage", ""),
        ])

    if "userMessaged" in data:
        lines.extend([
            "",
            "### User Message",
            data["userMessaged"].get("userMessage", ""),
        ])

    if "artifacts" in data:
        lines.extend(["", "### Artifacts / Patches"])
        for art in data.get("artifacts", []):
            cs = art.get("changeSet", {})
            git_patch = cs.get("gitPatch", {})
            unidiff = git_patch.get("unidiffPatch", "")
            if unidiff:
                lines.extend([
                    "```diff",
                    unidiff.strip(),
                    "```",
                ])

    return "\n".join(lines)


def format_session_check(audits: list[dict[str, Any]], show_history: bool = False, flag_unmerged: bool = False) -> str:
    """Format session audit results into an actionable markdown report with conversation history."""
    if not audits:
        return "_No sessions to audit._"

    lines = [
        "## Jules Sessions Health & Status Audit",
        "",
        "| Session ID | State | Assessment | Inactive | Dialogue | Title / Latest Activity | PR / Output |",
        "|---|---|---|---|:---:|---|---|",
    ]

    actionable_plans = []
    stalled_sessions = []
    feedback_sessions = []

    for a in audits:
        sid = a["id"]
        state = a["state"]
        assessment = a["assessment"]
        inactive_mins = a.get("inactive_mins", 0.0)
        if inactive_mins >= 1440:
            inactive = f"{round(inactive_mins / 1440.0, 1)}d"
        elif inactive_mins >= 60:
            inactive = f"{round(inactive_mins / 60.0, 1)}h"
        elif inactive_mins > 0:
            inactive = f"{round(inactive_mins, 1)}m"
        else:
            inactive = "<1m"

        title = a["title"]
        if len(title) > 36:
            title = title[:33] + "..."
        detail = a["latest_detail"]
        if detail and len(detail) > 40:
            detail = detail[:37] + "..."
        summary_cell = f"**{title}**<br>_{detail}_" if detail else f"**{title}**"

        # Dialogue column
        u_count = a.get("user_message_count", 0)
        a_count = a.get("agent_message_count", 0)
        unanswered = a.get("unanswered_user_messages", 0)
        diag_str = f"{u_count}U / {a_count}A"
        if unanswered > 0:
            diag_str += f"<br>⚠️ {unanswered} unreplied"
        elif a.get("agent_awaiting_reply"):
            diag_str += "<br>❓ agent asked"

        pr_info = "-"
        if a["pull_request_url"]:
            pr_num = a["pull_request_url"].split("/")[-1]
            pr_info = f"[PR #{pr_num}]({a['pull_request_url']})"

        # Status badge
        badge = assessment
        if assessment == "INACTIVE" or a.get("is_inactive"):
            badge = "💤 **INACTIVE**"
        elif assessment == "AWAITING_PLAN_APPROVAL":
            badge = "⚠️ **PLAN_GATE**"
            actionable_plans.append(a)
        elif assessment == "AWAITING_USER_FEEDBACK":
            badge = "💬 **FEEDBACK_GATE**"
            feedback_sessions.append(a)
        elif assessment == "STALLED":
            badge = "🚨 **STALLED**"
            stalled_sessions.append(a)
        elif assessment == "COMPLETED_WITH_PR":
            badge = "✅ **COMPLETED**"
        elif assessment == "COMPLETED_NO_OUTPUT":
            badge = "⚪ **CLOSED_NO_PR**"
        elif assessment == "ACTIVE":
            badge = "🔵 **ACTIVE**"

        lines.append(f"| `{sid}` | {state} | {badge} | {inactive} | {diag_str} | {summary_cell} | {pr_info} |")

    # Actionable items with conversation history context
    if actionable_plans or feedback_sessions or stalled_sessions:
        lines.extend(["", "### Actionable Items", ""])

    if actionable_plans:
        lines.append("#### Plans Awaiting Approval")
        for a in actionable_plans:
            lines.append(f"- **Session `{a['id']}`** ({a['title']})")
            if a["pending_plan_id"]:
                lines.append(f"  - Plan ID: `{a['pending_plan_id']}`")
                lines.append(f"  - To approve: `python3 <skill-dir>/scripts/main.py approve-plan {a['id']} {a['pending_plan_id']}`")
            _render_recent_history(lines, a)

    if feedback_sessions:
        lines.append("#### Sessions Awaiting User Guidance")
        for a in feedback_sessions:
            lines.append(f"- **Session `{a['id']}`** ({a['title']})")
            lines.append(f"  - Last agent message: {a.get('last_agent_message', a['latest_detail'])}")
            lines.append(f"  - To respond: `python3 <skill-dir>/scripts/main.py send-message {a['id']} \"<feedback>\"`")
            _render_recent_history(lines, a)

    if stalled_sessions:
        lines.append("#### Stalled / Silent Sessions")
        for a in stalled_sessions:
            lines.append(f"- **Session `{a['id']}`** ({a['title']}) — Inactive for {a['inactive_mins']}m")
            lines.append(f"  - Last event: `{a['latest_type']}`: {a['latest_detail']}")
            lines.append(f"  - To nudge: `python3 <skill-dir>/scripts/main.py send-message {a['id']} \"What is your progress?\"`")
            _render_recent_history(lines, a)

    # CLOSED_NO_PR sessions with deliverables (unmerged work)
    if flag_unmerged:
        closed_no_pr = [a for a in audits if a.get("assessment") == "COMPLETED_NO_OUTPUT"]
        unmerged = []
        for a in closed_no_pr:
            history = a.get("conversation_history", [])
            has_deliverables = any(
                h.get("content", "").find("Completed pre-commit steps") >= 0
                or h.get("content", "").find("Code review: Code reviewed") >= 0
                or h.get("content", "").find("Code review: Completed") >= 0
                or h.get("content", "").find("Completed") >= 0
                for h in history
                if h.get("role") == "agent"
            )
            if has_deliverables:
                unmerged.append(a)

        if unmerged:
            lines.extend(["", "### ⚠️ CLOSED_NO_PR Sessions with Deliverables (Unmerged Work)", ""])
            for a in unmerged:
                lines.append(f"- **Session `{a['id']}`** ({a['title']}) — Completed work but no PR created")
                lines.append(f"  - To request PR: `python3 <skill-dir>/scripts/main.py nudge {a['id']} pr_reminder`")
                lines.append(f"  - To review: `python3 <skill-dir>/scripts/main.py check-sessions {a['id']} --history`")
                _render_recent_history(lines, a)
        else:
            lines.extend(["", "### CLOSED_NO_PR Sessions with Deliverables", ""])
            lines.append("_No CLOSED_NO_PR sessions with detected deliverables found._")

    # Full conversation history if requested (or single-session audit)
    if show_history:
        lines.extend(["", "### Detailed Conversation Histories", ""])
        for a in audits:
            lines.append(f"#### Session `{a['id']}`: {a['title']}")
            history = a.get("conversation_history", [])
            if not history:
                lines.append("  _No conversation messages recorded._\n")
                continue
            for h in history:
                role_icon = "👤 **User**" if h["role"] == "user" else ("🤖 **Agent**" if h["role"] == "agent" else "⚙️ **System**")
                time_str = format_datetime(h.get("time"))
                msg_type = h.get("type", "message")
                content = h.get("content", "").replace("\n", "\n    > ")
                lines.append(f"- `[{time_str}]` {role_icon} ({msg_type}):\n    > {content}")
            lines.append("")

    return "\n".join(lines)


def _render_recent_history(lines: list[str], audit: dict[str, Any], max_items: int = 4) -> None:
    """Helper to append recent conversation turns to an audit section."""
    history = audit.get("conversation_history", [])
    if not history:
        return
    lines.append("  - **Recent Conversation History:**")
    recent = history[-max_items:]
    for h in recent:
        role_label = "User" if h["role"] == "user" else ("Agent" if h["role"] == "agent" else "System")
        time_str = format_datetime(h.get("time"))
        short_content = h.get("content", "").strip()
        if len(short_content) > 100:
            short_content = short_content[:97] + "..."
        short_content = short_content.replace("\n", " ")
        lines.append(f"    - `[{time_str}]` **{role_label}**: {short_content}")


