#!/usr/bin/env python3
"""Summarize VS Code Copilot session tool usage without emitting raw prompts."""

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List


INLINE_PYTHON = re.compile(r"\bpython(?:3)?\s+(?:-c|<<)")
CORRECTION_PATTERN = re.compile(
    r"\b(?:wrong|missed|instead|follow the template|not what|correct(?:ion|ed)?|"
    r"should have|must)\b",
    re.IGNORECASE,
)


def load_records(path: Path) -> List[Dict[str, Any]]:
    records = []
    with path.open(encoding="utf-8", errors="replace") as transcript:
        for line in transcript:
            try:
                record = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(record, dict):
                records.append(record)
    return records


def tool_arguments(arguments: Any) -> Dict[str, Any]:
    if isinstance(arguments, dict):
        return arguments
    if isinstance(arguments, str):
        try:
            decoded = json.loads(arguments)
        except json.JSONDecodeError:
            return {}
        return decoded if isinstance(decoded, dict) else {}
    return {}


def shell_pipe_count(command: str) -> int:
    """Count shell pipe operators outside quoted arguments and excluding `||`."""
    quote = None
    escaped = False
    count = 0
    for index, character in enumerate(command):
        if escaped:
            escaped = False
            continue
        if character == "\\":
            escaped = True
            continue
        if quote:
            if character == quote:
                quote = None
            continue
        if character in ("'", '"'):
            quote = character
            continue
        if character == "|":
            previous = command[index - 1] if index else ""
            following = command[index + 1] if index + 1 < len(command) else ""
            if previous != "|" and following != "|":
                count += 1
    return count


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Audit a VS Code Copilot JSONL transcript with concise Markdown output."
    )
    parser.add_argument("transcript", type=Path, help="Path to a VS Code Copilot transcript JSONL file")
    parser.add_argument(
        "--max-tools",
        type=int,
        default=12,
        help="Maximum tool names to show in the frequency table (default: 12)",
    )
    parser.add_argument(
        "--details",
        action="store_true",
        help="Show bounded command examples and failed file paths (may reveal command arguments)",
    )
    parser.add_argument(
        "--max-details",
        type=int,
        default=5,
        help="Maximum examples per category with --details (default: 5)",
    )
    args = parser.parse_args()

    if not args.transcript.is_file():
        parser.error(f"Transcript not found: {args.transcript}")

    records = load_records(args.transcript)
    starts = []
    completions = {}
    subagents = []
    terminal_commands = []
    corrections = 0

    for record in records:
        record_type = record.get("type")
        data = record.get("data", {})
        if record_type == "tool.execution_complete" and data.get("toolCallId"):
            completions[data["toolCallId"]] = data
        elif record_type == "tool.execution_start":
            starts.append(data)
            arguments = tool_arguments(data.get("arguments"))
            if data.get("toolName") == "runSubagent":
                subagents.append(arguments.get("agentName", "unspecified"))
            if data.get("toolName") == "run_in_terminal":
                command = arguments.get("command")
                if isinstance(command, str):
                    terminal_commands.append(command)
        elif record_type == "user.message":
            content = data.get("content", "")
            if isinstance(content, str) and CORRECTION_PATTERN.search(content):
                corrections += 1

    tool_counts = Counter(start.get("toolName", "unknown") for start in starts)
    failed = [
        start for start in starts
        if completions.get(start.get("toolCallId"), {}).get("success") is False
    ]
    inline_python = sum(bool(INLINE_PYTHON.search(command)) for command in terminal_commands)
    complex_pipelines = sum(shell_pipe_count(command) > 2 for command in terminal_commands)
    repeated_commands = sum(
        count - 1 for count in Counter(terminal_commands).values() if count > 1
    )

    print("# VS Code Copilot Session Audit")
    print()
    print(f"- **Parsed records:** {len(records)}")
    print(f"- **Tool executions:** {len(starts)}")
    print(f"- **Failed executions:** {len(failed)}")
    print(f"- **Subagent launches:** {len(subagents)} ({len(set(subagents))} distinct agents)")
    print(f"- **Potential user-correction messages:** {corrections}")
    print()
    print("## Tool Frequency")
    print()
    print("| Tool | Calls |")
    print("| --- | ---: |")
    for tool_name, count in tool_counts.most_common(args.max_tools):
        print(f"| `{tool_name}` | {count} |")
    print()
    print("## Command Smells")
    print()
    print(f"- **Terminal executions:** {len(terminal_commands)}")
    print(f"- **Inline Python or heredocs:** {inline_python}")
    print(f"- **Pipelines with more than two pipes:** {complex_pipelines}")
    print(f"- **Exact repeated terminal commands:** {repeated_commands}")
    print()
    print("## Failed Tool Frequency")
    print()
    if failed:
        failed_counts = Counter(start.get("toolName", "unknown") for start in failed)
        for tool_name, count in failed_counts.most_common():
            print(f"- `{tool_name}`: {count}")
    else:
        print("- None")

    if args.details:
        command_counts = Counter(terminal_commands)
        categories = {
            "Long pipelines": [command for command in terminal_commands if shell_pipe_count(command) > 2],
            "Repeated commands": [command for command, count in command_counts.items() if count > 1],
        }
        for title, commands in categories.items():
            print(f"\n## {title} ({len(commands)})\n")
            for command in commands[:args.max_details]:
                count = f" ({command_counts[command]} runs)" if title == "Repeated commands" else ""
                print(f"- {json.dumps(command[:240])}{count}")
            if len(commands) > args.max_details:
                print(f"- ... {len(commands) - args.max_details} more")

        print(f"\n## Failed calls ({len(failed)})\n")
        for start in failed[:args.max_details]:
            arguments = tool_arguments(start.get("arguments"))
            path = arguments.get("filePath", "")
            print(f"- {start.get('toolName', 'unknown')}: {Path(path).name if path else '(no file path)'}")
        if len(failed) > args.max_details:
            print(f"- ... {len(failed) - args.max_details} more")


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
