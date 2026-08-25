#!/usr/bin/env python3
"""List configured Antigravity MCP servers as a structured JSON array.

Usage:
  list-mcp-servers.py [--enabled-only] [--disabled-only]
  list-mcp-servers.py -h | --help

Options:
  --enabled-only    Filter output to include only enabled MCP servers.
  --disabled-only   Filter output to include only disabled MCP servers.
  -h, --help        Show this help message.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="List Antigravity MCP servers as structured JSON."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--enabled-only",
        action="store_true",
        help="Include only enabled servers",
    )
    group.add_argument(
        "--disabled-only",
        action="store_true",
        help="Include only disabled servers",
    )
    return parser.parse_args()


def get_mcp_servers() -> list[dict[str, str]]:
    try:
        res = subprocess.run(
            ["agy", "mcp", "list"],
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(f"Error running 'agy mcp list': {exc.stderr}\n")
        sys.exit(exc.returncode)
    except FileNotFoundError:
        sys.stderr.write("Error: 'agy' command not found in PATH.\n")
        sys.exit(1)

    lines = [line.rstrip() for line in res.stdout.strip().splitlines() if line.strip()]
    if not lines or len(lines) <= 1:
        return []

    # First line is header: NAME TYPE STATUS COMMAND/URL
    header = lines[0]
    col_names = ["NAME", "TYPE", "STATUS", "COMMAND/URL"]
    indices: list[int] = []
    for name in col_names:
        idx = header.find(name)
        indices.append(idx)

    servers: list[dict[str, str]] = []
    for line in lines[1:]:
        if not line.strip():
            continue
        # Extract fields based on header positions
        name_val = line[indices[0]:indices[1]].strip() if len(line) > indices[0] else ""
        type_val = line[indices[1]:indices[2]].strip() if len(line) > indices[1] else ""
        status_val = line[indices[2]:indices[3]].strip() if len(line) > indices[2] else ""
        cmd_val = line[indices[3]:].strip() if len(line) > indices[3] else ""

        servers.append({
            "name": name_val,
            "type": type_val,
            "status": status_val,
            "command_or_url": cmd_val,
        })
    return servers


def main() -> None:
    args = parse_args()
    servers = get_mcp_servers()

    if args.enabled_only:
        servers = [s for s in servers if s.get("status") == "enabled"]
    elif args.disabled_only:
        servers = [s for s in servers if s.get("status") == "disabled"]

    print(json.dumps(servers, indent=2))


if __name__ == "__main__":
    main()
