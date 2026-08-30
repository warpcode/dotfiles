import sys
from datetime import datetime, timezone, timedelta

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

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
