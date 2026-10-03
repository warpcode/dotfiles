import sys
from datetime import datetime, timezone, timedelta

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

WORK_DAY_START = 9  # 9 AM
WORK_DAY_END = 17.5 # 5:30 PM (8.5 hours)

# Calculate SECONDS_PER_WORK_DAY using the exact minute-truncated day window
# to guarantee full intermediate days always agree with partial day calculations.
_probe_dt = datetime(2020, 1, 1)
_day_start_probe = _probe_dt.replace(
    hour=int(WORK_DAY_START),
    minute=int((WORK_DAY_START % 1) * 60),
    second=0,
    microsecond=0,
)
_day_end_probe = _probe_dt.replace(
    hour=int(WORK_DAY_END),
    minute=int((WORK_DAY_END % 1) * 60),
    second=0,
    microsecond=0,
)
SECONDS_PER_WORK_DAY = int((_day_end_probe - _day_start_probe).total_seconds())

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

    Optimized O(1) time complexity by calculating full intermediate weeks
    via integer arithmetic instead of iterating day-by-day in a loop.
    """
    if not start_dt or not end_dt or start_dt >= end_dt:
        return 0

    start_date = start_dt.date()
    end_date = end_dt.date()

    # Helper to calculate work overlap for a single day
    def _day_work_seconds(dt, is_start_day, is_end_day):
        if dt.weekday() >= 5:  # Weekend
            return 0
        day_start = dt.replace(
            hour=int(WORK_DAY_START),
            minute=int((WORK_DAY_START % 1) * 60),
            second=0,
            microsecond=0,
        )
        day_end = dt.replace(
            hour=int(WORK_DAY_END),
            minute=int((WORK_DAY_END % 1) * 60),
            second=0,
            microsecond=0,
        )
        s = dt if is_start_day else day_start
        e = end_dt if is_end_day else day_end
        s = max(s, day_start)
        e = min(e, day_end)
        if e > s:
            return (e - s).total_seconds()
        return 0

    # Same day case
    if start_date == end_date:
        return int(_day_work_seconds(start_dt, True, True))

    # Calculate first partial/full day and last partial/full day
    first_day_sec = _day_work_seconds(start_dt, True, False)
    last_day_sec = _day_work_seconds(end_dt, False, True)

    # Calculate full intermediate days in O(1)
    d1 = start_date + timedelta(days=1)
    d2 = end_date - timedelta(days=1)

    if d1 <= d2:
        num_days = (d2 - d1).days + 1
        full_weeks, rem_days = divmod(num_days, 7)
        start_w = d1.weekday()
        rem_weekdays = sum(1 for i in range(rem_days) if (start_w + i) % 7 < 5)
        work_days = full_weeks * 5 + rem_weekdays
        middle_sec = work_days * SECONDS_PER_WORK_DAY
    else:
        middle_sec = 0

    return int(first_day_sec + last_day_sec + middle_sec)

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
