#!/usr/bin/env python3
"""parse_conversation.py

Universal multi-format conversation parser for AI transcripts and logs.
Parses transcripts across platforms (Antigravity/Gemini JSONL, Claude Code JSON/JSONL,
OpenCode JSON, OpenAI/ChatGPT exports, Copilot chat exports, and plain Markdown/text)
and produces a token-efficient Markdown summary for AI agent analysis.

Usage:
    parse_conversation.py <input_path_or_url> [options]
    parse_conversation.py --stdin [options]

Options:
    -h, --help            Show this help message and exit
    --max-turns N         Limit summary to the last N conversation turns (default: all)
    --tools-only          Extract only tool calls, arguments, and execution statuses
    --errors-only         Extract only errors, failed tool calls, and user corrections
    --user-only           Extract only user prompts and directives
"""

import argparse
import json
import os
import re
import sys
from typing import Any, Dict, List, Optional, Tuple


def parse_antigravity_gemini_jsonl(lines: List[str]) -> List[Dict[str, Any]]:
    """Parses Antigravity / Gemini CLI transcript.jsonl format."""
    events = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue

        step_type = obj.get("type", "")
        source = obj.get("source", "")
        content = obj.get("content", "")
        tool_calls = obj.get("tool_calls", [])
        status = obj.get("status", "")

        if step_type == "USER_INPUT" or source == "USER_EXPLICIT":
            events.append({
                "role": "user",
                "content": content,
                "tool_calls": [],
                "error": None
            })
        elif step_type in ("PLANNER_RESPONSE", "MODEL") or source == "MODEL":
            extracted_tools = []
            if isinstance(tool_calls, list):
                for tc in tool_calls:
                    tool_name = tc.get("name") or tc.get("ToolName") or tc.get("toolAction", "tool_call")
                    args = tc.get("args") or tc.get("Arguments") or {}
                    extracted_tools.append({
                        "name": tool_name,
                        "args": args
                    })
            
            error = None
            if status == "ERROR" or "Error" in str(content):
                error = str(content)[:300]

            events.append({
                "role": "assistant",
                "content": content,
                "tool_calls": extracted_tools,
                "error": error
            })
    return events


def parse_claude_code_session(data: Any) -> List[Dict[str, Any]]:
    """Parses Claude Code JSON / JSONL transcripts."""
    events = []
    records = data if isinstance(data, list) else [data]
    for rec in records:
        if not isinstance(rec, dict):
            continue
        # Claude Code event formats
        role = rec.get("role") or rec.get("type")
        content = rec.get("content") or rec.get("message", "")
        tool_calls = []
        
        # Check tool invocations
        if "tools" in rec or "tool_use" in rec:
            raw_tools = rec.get("tools") or rec.get("tool_use") or []
            if isinstance(raw_tools, list):
                for t in raw_tools:
                    tool_calls.append({
                        "name": t.get("name", "unknown_tool"),
                        "args": t.get("input", {})
                    })
        
        if role in ("user", "human"):
            events.append({"role": "user", "content": content, "tool_calls": [], "error": None})
        elif role in ("assistant", "agent"):
            err = None
            if rec.get("is_error") or "error" in rec:
                err = str(rec.get("error", "Execution error"))[:300]
            events.append({"role": "assistant", "content": content, "tool_calls": tool_calls, "error": err})
    return events


def parse_openai_chatgpt_json(data: Any) -> List[Dict[str, Any]]:
    """Parses OpenAI / ChatGPT message exports."""
    events = []
    # Could be mapping or messages array
    messages = []
    if isinstance(data, dict):
        if "mapping" in data:
            for node_id, node in data["mapping"].items():
                msg = node.get("message")
                if msg:
                    messages.append(msg)
        elif "messages" in data:
            messages = data["messages"]
    elif isinstance(data, list):
        messages = data

    for msg in messages:
        if not isinstance(msg, dict):
            continue
        author = msg.get("author", {})
        role = author.get("role") if isinstance(author, dict) else msg.get("role")
        content_obj = msg.get("content", {})
        parts = []
        if isinstance(content_obj, dict):
            parts = content_obj.get("parts", [])
        elif isinstance(content_obj, str):
            parts = [content_obj]
        
        text = " ".join(str(p) for p in parts if p)
        if role in ("user", "human"):
            events.append({"role": "user", "content": text, "tool_calls": [], "error": None})
        elif role in ("assistant", "system"):
            events.append({"role": role, "content": text, "tool_calls": [], "error": None})
    return events


def parse_markdown_plain_text(text: str) -> List[Dict[str, Any]]:
    """Parses plain Markdown / Text conversation transcripts."""
    events = []
    pattern = re.compile(r'^(#{1,4}\s*(?:User|Human|Assistant|AI|System)|(?:\*{0,2}(?:User|Human|Assistant|AI|System)\*{0,2}\s*:))', re.IGNORECASE | re.MULTILINE)
    
    splits = pattern.split(text)
    if len(splits) <= 1:
        # Single block fallback
        return [{"role": "user", "content": text.strip(), "tool_calls": [], "error": None}]
    
    current_role = "user"
    for part in splits:
        part_clean = part.strip()
        if not part_clean:
            continue
        
        header_match = pattern.match(part_clean)
        if header_match:
            header_lower = part_clean.lower()
            if "user" in header_lower or "human" in header_lower:
                current_role = "user"
            elif "assistant" in header_lower or "ai" in header_lower:
                current_role = "assistant"
            elif "system" in header_lower:
                current_role = "system"
        else:
            events.append({
                "role": current_role,
                "content": part_clean,
                "tool_calls": [],
                "error": None
            })
    return events


def ingest_transcript(raw_text: str) -> List[Dict[str, Any]]:
    """Auto-detects format and normalizes into standard event sequence."""
    raw_text = raw_text.strip()
    if not raw_text:
        return []

    # 1. Try JSONL (Antigravity or Claude Code lines)
    if "\n" in raw_text and ("{" in raw_text):
        lines = [ln for ln in raw_text.splitlines() if ln.strip().startswith("{")]
        if lines:
            try:
                first_obj = json.loads(lines[0])
                if "step_index" in first_obj or "source" in first_obj or "tool_calls" in first_obj:
                    return parse_antigravity_gemini_jsonl(lines)
            except Exception:
                pass

    # 2. Try JSON (Object or Array)
    if raw_text.startswith("{") or raw_text.startswith("["):
        try:
            data = json.loads(raw_text)
            if isinstance(data, dict) and "mapping" in data:
                return parse_openai_chatgpt_json(data)
            elif isinstance(data, list) or (isinstance(data, dict) and "messages" in data):
                return parse_claude_code_session(data)
        except Exception:
            pass

    # 3. Fallback to Markdown / Plain Text
    return parse_markdown_plain_text(raw_text)


def generate_markdown_summary(events: List[Dict[str, Any]], max_turns: Optional[int] = None,
                              tools_only: bool = False, errors_only: bool = False,
                              user_only: bool = False) -> str:
    """Formats events into a clean, token-efficient Markdown summary."""
    if not events:
        return "No conversation events found in transcript."

    if max_turns and max_turns > 0:
        events = events[-max_turns:]

    output = []
    output.append("# Ingested Conversation Summary")
    output.append(f"**Total Events Extracted:** {len(events)}\n")

    user_count = sum(1 for e in events if e.get("role") == "user")
    assistant_count = sum(1 for e in events if e.get("role") == "assistant")
    tool_count = sum(len(e.get("tool_calls", [])) for e in events)

    output.append(f"- **User Turns:** {user_count}")
    output.append(f"- **Assistant Turns:** {assistant_count}")
    output.append(f"- **Tool Invocations:** {tool_count}\n")
    output.append("---")

    for i, ev in enumerate(events, 1):
        role = ev.get("role", "unknown").capitalize()
        content = ev.get("content", "").strip()
        tool_calls = ev.get("tool_calls", [])
        error = ev.get("error")

        if user_only and role.lower() != "user":
            continue
        if tools_only and not tool_calls:
            continue
        if errors_only and not error and not ("error" in content.lower() or "fail" in content.lower()):
            continue

        output.append(f"\n### Turn {i} [{role}]")
        
        if content and not tools_only:
            # Truncate very long blocks for token efficiency
            if len(content) > 1200 and not errors_only:
                snippet = content[:800] + "\n\n... [Truncated for token efficiency] ...\n\n" + content[-300:]
                output.append(snippet)
            else:
                output.append(content)

        if tool_calls:
            output.append("\n**Tools Executed:**")
            for tc in tool_calls:
                tname = tc.get("name", "tool")
                targs = tc.get("args", {})
                args_str = json.dumps(targs, separators=(',', ':')) if isinstance(targs, (dict, list)) else str(targs)
                if len(args_str) > 200:
                    args_str = args_str[:180] + "...}"
                output.append(f"- `{tname}`: `{args_str}`")

        if error:
            output.append(f"\n> [!WARNING]\n> **Execution Error:** {error}")

    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(
        description="Universal multi-format conversation parser for AI transcripts and logs."
    )
    parser.add_argument("input_path", nargs="?", default=None, help="Path to transcript file (.json, .jsonl, .md, .txt)")
    parser.add_argument("--stdin", action="store_true", help="Read transcript from standard input")
    parser.add_argument("--max-turns", type=int, default=None, help="Limit summary to the last N turns")
    parser.add_argument("--tools-only", action="store_true", help="Extract only tool calls and statuses")
    parser.add_argument("--errors-only", action="store_true", help="Extract only errors and corrections")
    parser.add_argument("--user-only", action="store_true", help="Extract only user prompts")

    args = parser.parse_args()

    raw_text = ""
    if args.stdin or (args.input_path == "-" or (not args.input_path and not sys.stdin.isatty())):
        raw_text = sys.stdin.read()
    elif args.input_path:
        if not os.path.exists(args.input_path):
            sys.stderr.write(f"Error: File not found at '{args.input_path}'\n")
            sys.exit(1)
        with open(args.input_path, "r", encoding="utf-8", errors="replace") as f:
            raw_text = f.read()
    else:
        parser.print_help()
        sys.exit(1)

    events = ingest_transcript(raw_text)
    summary_md = generate_markdown_summary(
        events,
        max_turns=args.max_turns,
        tools_only=args.tools_only,
        errors_only=args.errors_only,
        user_only=args.user_only
    )
    print(summary_md)


if __name__ == "__main__":
    main()
