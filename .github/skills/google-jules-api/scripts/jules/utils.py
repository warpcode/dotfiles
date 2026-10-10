import sys
from datetime import datetime, timezone


def die(message: str, exit_code: int = 1) -> None:
    """Print an error message to stderr and exit."""
    sys.stderr.write(f"Error: {message}\n")
    sys.exit(exit_code)


def err(message: str) -> None:
    """Print a diagnostic message to stderr."""
    sys.stderr.write(f"{message}\n")


def info(message: str, verbose: bool = False) -> None:
    """Print an informational message to stderr if verbose is enabled."""
    if verbose:
        sys.stderr.write(f"[jules] {message}\n")


def parse_iso_datetime(iso_str: str) -> datetime:
    """Parse an ISO 8601 timestamp string into a timezone-aware datetime.

    Python 3.11+ parses a trailing 'Z' natively and is used as a fast path;
    older versions need it rewritten to an explicit offset.

    The result is always tz-aware. Input without an offset is interpreted as
    UTC, which is what every caller requires: they subtract the result from
    datetime.now(timezone.utc), and mixing aware and naive datetimes raises
    TypeError. Previously such input returned a naive datetime, and because
    those call sites swallow exceptions the failure was silent -- inactivity
    and age stayed 0.0 and the max-age filter never excluded anything.
    """
    try:
        dt = datetime.fromisoformat(iso_str)
    except ValueError:
        # Rewrite only a trailing 'Z'; an interior one is part of the value.
        normalised = iso_str[:-1] + "+00:00" if iso_str.endswith("Z") else iso_str
        dt = datetime.fromisoformat(normalised)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def format_datetime(iso_str: str | None) -> str:
    """Format an ISO 8601 timestamp into a readable date-time string."""
    if not iso_str:
        return "N/A"
    try:
        dt = parse_iso_datetime(iso_str)
        return dt.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    except Exception:
        return iso_str
