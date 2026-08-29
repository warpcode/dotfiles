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
            summary = "Status updated"
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
