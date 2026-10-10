import sys
from datetime import datetime


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


def format_datetime(iso_str: str | None) -> str:
    """Format an ISO 8601 timestamp into a readable date-time string."""
    if not iso_str:
        return "N/A"
    try:
        clean_str = iso_str.replace("Z", "+00:00")
        dt = datetime.fromisoformat(clean_str)
        return dt.strftime("%Y-%m-%d %H:%M:%S UTC")
    except Exception:
        return iso_str
