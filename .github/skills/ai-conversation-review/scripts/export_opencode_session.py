#!/usr/bin/env python3
"""Export an OpenCode session from its SQLite store to parser-compatible JSONL.

OpenCode persists sessions in `~/.local/share/opencode/opencode.db` (tables
`session` and `part`). This script converts one session into the JSONL shape
consumed by `parse_conversation.py`, so ad-hoc `python3 -c` SQLite queries are
never needed.

Usage:
    python3 export_opencode_session.py --latest
    python3 export_opencode_session.py <session-id>
    python3 export_opencode_session.py --latest --list

The resulting JSONL is written to stdout; redirect it to a file:

    python3 export_opencode_session.py --latest > /tmp/session.jsonl
    python3 parse_conversation.py /tmp/session.jsonl --tools-only
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from pathlib import Path
from typing import Any

DEFAULT_DB = Path.home() / ".local" / "share" / "opencode" / "opencode.db"


def die(msg: str) -> None:
    print(f"Error: {msg}", file=sys.stderr)
    sys.exit(1)


def resolve_db(path: str | None) -> Path:
    db = Path(path) if path else DEFAULT_DB
    if not db.exists():
        die(f"OpenCode database not found at {db}. Pass --db to override.")
    return db


def connect(db: Path) -> sqlite3.Connection:
    return sqlite3.connect(f"file:{db}?mode=ro", uri=True)


def list_sessions(conn: sqlite3.Connection, limit: int) -> list[tuple[str, str, int]]:
    rows = conn.execute(
        "SELECT id, COALESCE(title, ''), time_created FROM session "
        "ORDER BY time_created DESC LIMIT ?",
        (limit,),
    ).fetchall()
    return [(r[0], r[1], r[2]) for r in rows]


def resolve_session_id(conn: sqlite3.Connection, session_id: str | None, latest: bool) -> str:
    if session_id:
        return session_id
    if not latest:
        die("Provide a session ID or pass --latest.")
    sessions = list_sessions(conn, 1)
    if not sessions:
        die("No sessions found in the database.")
    return sessions[0][0]


def part_to_event(part: dict[str, Any], role: str) -> dict[str, Any] | None:
    """Convert one `part` row into a normalized conversation event.

    `role` comes from the parent `message` row -- OpenCode parts carry no role.
    """
    ptype = part.get("type")
    text = part.get("text") or ""

    if ptype == "text":
        if not text.strip():
            return None
        return {
            "role": "user" if role == "user" else "assistant",
            "content": text,
            "tool_calls": [],
            "error": None,
        }

    if ptype == "tool":
        state = part.get("state") or {}
        status = state.get("status")
        args = state.get("input") or {}
        return {
            "role": "assistant",
            "content": "",
            "tool_calls": [{
                "name": part.get("tool", "unknown"),
                "status": status,
                "error": (state.get("error") or None) if status == "error" else None,
                "arguments": args if isinstance(args, dict) else {},
            }],
            "error": None,
        }

    return None


def export(conn: sqlite3.Connection, session_id: str) -> int:
    rows = conn.execute(
        "SELECT p.data, m.data "
        "FROM part p LEFT JOIN message m ON m.id = p.message_id "
        "WHERE p.session_id = ? ORDER BY p.id",
        (session_id,),
    ).fetchall()

    count = 0
    for raw_part, raw_message in rows:
        try:
            part = json.loads(raw_part)
        except json.JSONDecodeError:
            continue
        role = "assistant"
        if raw_message:
            try:
                role = json.loads(raw_message).get("role") or "assistant"
            except json.JSONDecodeError:
                pass
        event = part_to_event(part, role)
        if event is None:
            continue
        print(json.dumps(event))
        count += 1

    print(
        f"# Exported {count} events from session {session_id}",
        file=sys.stderr,
    )
    return count


def main() -> None:
    ap = argparse.ArgumentParser(
        prog="export_opencode_session.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("session_id", nargs="?", help="OpenCode session ID (ses_...) to export")
    ap.add_argument("--latest", action="store_true", help="Export the most recent session")
    ap.add_argument("--list", action="store_true", help="List recent sessions and exit")
    ap.add_argument("--db", help=f"Path to opencode.db (default: {DEFAULT_DB})")
    ap.add_argument("--limit", type=int, default=10, help="Sessions to show with --list (default: 10)")
    args = ap.parse_args()

    conn = connect(resolve_db(args.db))

    if args.list:
        for sid, title, created in list_sessions(conn, args.limit):
            print(f"{sid}\t{title[:70] or '(untitled)'}\t{created}")
        return

    if args.session_id and args.latest:
        die("Provide either a session ID or --latest, not both.")

    sid = resolve_session_id(conn, args.session_id, args.latest)
    if not export(conn, sid):
        die(f"No exportable parts found for session {sid}.")


if __name__ == "__main__":
    main()
