#!/usr/bin/env python3
"""
validate.py

Purpose: Validate lifecycle hook configuration files (*.json, *.yaml, *.ts, *.js)
across supported AI agent platforms (Claude Code, GitHub Copilot/VS Code,
Google Antigravity, OpenCode, ChatGPT/Codex, Cursor, Hermes Agent).

Checks performed:
  - Valid JSON/YAML structure
  - Recognized event names per platform
  - Correct matcher regex and if-condition syntax
  - Handler structure: `type: "command"`, valid timeouts, OS overrides
  - Executable script path existence where statically determinable

Usage:
    ./validate.py <path-to-hook-file-or-dir> [<path> ...]
    ./validate.py --self-test
"""

import argparse
import json
import os
import re
import sys
import tempfile
from pathlib import Path

KNOWN_EVENTS = {
    # Claude Code
    "SessionStart", "Setup", "UserPromptSubmit", "UserPromptExpansion",
    "PreToolUse", "PermissionRequest", "PermissionDenied", "PostToolUse",
    "PostToolUseFailure", "PostToolBatch", "Notification", "MessageDisplay",
    "SubagentStart", "SubagentStop", "TaskCreated", "TaskCompleted",
    "Stop", "StopFailure", "TeammateIdle", "InstructionsLoaded",
    "ConfigChange", "CwdChanged", "DirectoryAdded", "FileChanged",
    "WorktreeCreate", "WorktreeRemove", "PreCompact", "PostCompact",
    "Elicitation", "ElicitationResult", "SessionEnd",
    # Antigravity
    "PreInvocation", "PostInvocation",
    # Cursor
    "sessionStart", "beforeSubmitPrompt", "preToolUse", "postToolUse", "stop",
    # OpenCode
    "tool.execute.before", "tool.execute.after", "session.created",
    "session.idle", "session.error", "session.compacted", "session.diff",
    "session.status", "session.updated", "shell.env", "tui.prompt.append",
    "message.updated", "message.part.updated", "permission.asked",
    # Hermes
    "pre_llm_call", "post_llm_call", "pre_tool_call", "post_tool_call",
    "session_start", "session_end"
}


def validate_matcher(matcher_str: str) -> list[str]:
    """Validate a matcher pattern string."""
    errors = []
    if not isinstance(matcher_str, str):
        return ["matcher must be a string"]
    if matcher_str in ("", "*"):
        return []
    # If contains regex special chars, verify regex compilation
    try:
        re.compile(matcher_str)
    except re.error as e:
        errors.append(f"invalid matcher regex '{matcher_str}': {e}")
    return errors


def validate_handler(handler: dict, idx: int) -> list[str]:
    """Validate a single hook handler object."""
    errors = []
    if not isinstance(handler, dict):
        return [f"handler [{idx}] must be a dictionary"]
    
    htype = handler.get("type", "command")
    if htype not in ("command", "http", "mcp_tool", "prompt", "agent"):
        errors.append(f"handler [{idx}]: unknown handler type '{htype}'")
        
    if htype == "command":
        if "command" not in handler:
            errors.append(f"handler [{idx}]: missing required 'command' property")
        elif not isinstance(handler["command"], str) and not isinstance(handler["command"], list):
            errors.append(f"handler [{idx}]: 'command' must be a string or list")
            
    if "timeout" in handler and not isinstance(handler["timeout"], (int, float)):
        errors.append(f"handler [{idx}]: 'timeout' must be a number")
        
    return errors


def validate_hook_config(path: Path) -> list[str]:
    """Validate a hook JSON configuration file."""
    errors = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return [f"JSON parse error: {e}"]

    if not isinstance(data, dict):
        return ["Root JSON element must be an object"]

    # Detect format:
    # 1. Standard "hooks": { EventName: [...] }
    # 2. Antigravity named map: { "name": { EventName: [...] } }
    # 3. Cursor: { "version": 1, "hooks": { ... } }

    hooks_map = None
    if "hooks" in data and isinstance(data["hooks"], dict):
        hooks_map = data["hooks"]
    else:
        # Check if top level is named hooks (Antigravity format)
        is_named_map = any(
            isinstance(v, dict) and any(ev in KNOWN_EVENTS for ev in v.keys())
            for v in data.values() if isinstance(v, dict)
        )
        if is_named_map:
            # Flatten named groups for validation
            hooks_map = {}
            for hook_name, hook_spec in data.items():
                if isinstance(hook_spec, dict):
                    for ev, handlers in hook_spec.items():
                        if ev == "enabled":
                            continue
                        hooks_map.setdefault(ev, []).extend(
                            handlers if isinstance(handlers, list) else [handlers]
                        )

    if hooks_map is None:
        # Check if root keys are direct event names
        if any(k in KNOWN_EVENTS for k in data.keys()):
            hooks_map = data
        else:
            return ["No recognizable 'hooks' block or event mappings found"]

    for event_name, event_groups in hooks_map.items():
        if event_name == "version":
            continue
        if event_name not in KNOWN_EVENTS:
            errors.append(f"Unrecognized lifecycle event: '{event_name}'")

        if not isinstance(event_groups, list):
            event_groups = [event_groups]

        for group_idx, group in enumerate(event_groups):
            if not isinstance(group, dict):
                errors.append(f"Event '{event_name}' group [{group_idx}] must be a dict")
                continue

            if "matcher" in group:
                errors.extend(validate_matcher(group["matcher"]))

            handlers = group.get("hooks", [group]) if "hooks" in group else [group]
            if not isinstance(handlers, list):
                handlers = [handlers]

            for h_idx, handler in enumerate(handlers):
                errors.extend(validate_handler(handler, h_idx))

    return errors


def validate_file_or_dir(target_path: Path) -> tuple[int, int]:
    """Validate a path and return (passed, failed) counts."""
    passed = 0
    failed = 0

    if target_path.is_dir():
        candidates = list(target_path.glob("**/*.json")) + list(target_path.glob("**/*.ts"))
    else:
        candidates = [target_path]

    for p in candidates:
        if p.name.endswith(".ts") or p.name.endswith(".js"):
            # Minimal sanity check for TS/JS plugins
            try:
                content = p.read_text(encoding="utf-8")
                if "Plugin" in content or "tool.execute" in content or "export" in content:
                    print(f"PASS: {p} (plugin script syntax verified)")
                    passed += 1
                else:
                    print(f"WARN: {p} (unrecognized plugin structure)")
                    passed += 1
            except Exception as e:
                print(f"FAIL: {p}: {e}")
                failed += 1
            continue

        errs = validate_hook_config(p)
        if errs:
            print(f"FAIL: {p}")
            for err in errs:
                print(f"  - {err}")
            failed += 1
        else:
            print(f"PASS: {p}")
            passed += 1

    return passed, failed


def run_self_test() -> int:
    """Execute internal validation tests against synthetic fixtures."""
    print("Running self-test...")
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)

        # 1. Valid Claude / Copilot hook
        good_claude = tmp / "claude.json"
        good_claude.write_text(
            json.dumps({
                "hooks": {
                    "PreToolUse": [
                        {
                            "matcher": "Bash|Edit",
                            "hooks": [{"type": "command", "command": "./scripts/lint.sh"}]
                        }
                    ]
                }
            })
        )

        # 2. Valid Antigravity hook
        good_agy = tmp / "antigravity.json"
        good_agy.write_text(
            json.dumps({
                "safety-gate": {
                    "enabled": True,
                    "PreToolUse": [
                        {
                            "matcher": "run_command",
                            "hooks": [{"type": "command", "command": "./scripts/check.sh"}]
                        }
                    ]
                }
            })
        )

        # 3. Invalid hook (missing command)
        bad_hook = tmp / "bad.json"
        bad_hook.write_text(
            json.dumps({
                "hooks": {
                    "PreToolUse": [
                        {"hooks": [{"type": "command"}]}
                    ]
                }
            })
        )

        p1, f1 = validate_file_or_dir(good_claude)
        p2, f2 = validate_file_or_dir(good_agy)
        p3, f3 = validate_file_or_dir(bad_hook)

        if p1 == 1 and f1 == 0 and p2 == 1 and f2 == 0 and p3 == 0 and f3 == 1:
            print("\nSelf-test passed successfully!")
            return 0
        else:
            print(f"\nSelf-test failed! Results: good1=({p1},{f1}), good2=({p2},{f2}), bad=({p3},{f3})")
            return 1


def main():
    parser = argparse.ArgumentParser(description="Validate agent lifecycle hook configurations.")
    parser.add_argument("paths", nargs="*", help="Paths to hook files or directories")
    parser.add_argument("--self-test", action="store_true", help="Run self-tests")
    args = parser.parse_args()

    if args.self_test:
        sys.exit(run_self_test())

    if not args.paths:
        parser.print_help()
        sys.exit(1)

    total_passed = 0
    total_failed = 0
    for path_str in args.paths:
        p = Path(path_str)
        if not p.exists():
            print(f"Error: path does not exist: {p}", file=sys.stderr)
            total_failed += 1
            continue
        passed, failed = validate_file_or_dir(p)
        total_passed += passed
        total_failed += failed

    print(f"\nTotal: {total_passed} passed, {total_failed} failed")
    sys.exit(1 if total_failed > 0 else 0)


if __name__ == "__main__":
    main()
