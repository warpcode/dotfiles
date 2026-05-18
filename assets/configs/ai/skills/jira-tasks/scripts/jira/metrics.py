from datetime import datetime, timezone
from .utils import parse_jira_time, get_work_seconds, format_duration, SECONDS_PER_WORK_DAY

def calculate_metrics(issue, status_map=None, now=None):
    """Calculate statistical metrics for an issue based on its changelog."""
    if "changelog" not in issue:
        return None

    if now is None:
        now = datetime.now(timezone.utc)

    fields = issue.get("fields", {})
    val = issue["changelog"]
    histories = sorted(val.get("histories", []), key=lambda x: parse_jira_time(x.get("created")))

    # Build timeline of status changes
    initial_status = None
    for h in histories:
        for item in h.get("items", []):
            if item.get("field") == "status":
                initial_status = item.get("fromString")
                break
        if initial_status:
            break

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

    return {
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
