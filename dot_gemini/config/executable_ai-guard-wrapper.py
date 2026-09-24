#!/usr/bin/env python3
"""
Antigravity/agy Hook Bridge (sits in ~/.gemini/config/ next to hooks.json)
Routes Antigravity lifecycle events to the platform-agnostic df.ai-guard core
and translates results into Antigravity ProtoJSON.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def resolve_ai_guard() -> str:
    script_dir = Path(__file__).resolve().parent
    repo_cand = script_dir.parent.parent / "dot_local" / "bin" / "executable_df.ai-guard"
    if repo_cand.is_file() and os.access(repo_cand, os.X_OK):
        return str(repo_cand)
    home_cand = Path.home() / "src" / "dotfiles" / "dot_local" / "bin" / "executable_df.ai-guard"
    if home_cand.is_file() and os.access(home_cand, os.X_OK):
        return str(home_cand)
    local_bin = Path.home() / ".local" / "bin" / "df.ai-guard"
    if local_bin.is_file() and os.access(local_bin, os.X_OK):
        return str(local_bin)
    p = shutil.which("df.ai-guard")
    if p:
        return p
    return "df.ai-guard"


AI_GUARD_BIN = resolve_ai_guard()


def run_guard(subcmd: str, args: list[str] = None, stdin_str: str = None) -> tuple[int, dict]:
    cmd = [AI_GUARD_BIN, subcmd]
    if args:
        cmd.extend(args)
    try:
        res = subprocess.run(cmd, input=stdin_str, text=True, capture_output=True, check=False)
        out = res.stdout.strip()
        data = {}
        if out:
            try:
                data = json.loads(out)
            except Exception:
                pass
        return res.returncode, data
    except Exception as e:
        sys.stderr.write(f"Error invoking {cmd}: {e}\n")
        return 2, {"decision": "deny", "reason": f"Security guard execution failed: {e}"}


def handle_prompt_route(payload):
    prompt_text = payload.get("prompt") or payload.get("text") or ""
    tp = payload.get("transcriptPath")
    target_line_idx = None
    lines = []

    if not prompt_text and tp and os.path.isfile(tp):
        try:
            with open(tp, "r", encoding="utf-8") as f:
                lines = f.readlines()
            for idx in range(len(lines) - 1, -1, -1):
                try:
                    d = json.loads(lines[idx])
                    if d.get("content") and d.get("type") in ("USER_INPUT", "GENERIC"):
                        prompt_text = d.get("content")
                        target_line_idx = idx
                        break
                except Exception:
                    pass
        except Exception:
            pass

    if not prompt_text:
        print("{}")
        sys.exit(0)

    code, data = run_guard("prompt", stdin_str=json.dumps({"text": prompt_text}))

    if code == 2 or data.get("decision") == "deny":
        reason = data.get("reason", "Content blocked by security guard")
        sys.stderr.write(f"SECURITY GUARD: {reason}\n")
        print(json.dumps({"decision": "deny", "reason": reason}))
        sys.exit(2)

    if data.get("decision") == "replace" and data.get("sanitized"):
        sanitized = data["sanitized"]
    if data.get("decision") == "replace" and data.get("sanitized") != prompt_text:
        reasons = data.get("reasons", [])
        notice = f"Security Notice: Redacted sensitive items ({', '.join(reasons)})" if reasons else "Security Notice: Redacted sensitive items."
        detail = f" ({', '.join(reasons)})" if reasons else ""
        reason = f"Prompt submission blocked: sensitive credentials or secrets detected{detail}. Remove secrets from prompt to prevent leakage."
        sys.stderr.write(f"SECURITY GUARD: {reason}\n")
        print(json.dumps({"decision": "deny", "reason": reason}))
        sys.exit(2)

        # Sanitize transcript step in-place if applicable
        if tp and target_line_idx is not None and lines:
            try:
                step_data = json.loads(lines[target_line_idx])
                step_data["content"] = sanitized
                lines[target_line_idx] = json.dumps(step_data) + "\n"
                with open(tp, "w", encoding="utf-8") as f:
                    f.writelines(lines)
            except Exception:
                pass

        proto_resp = {
            "injectSteps": [
                {"ephemeralMessage": notice}
            ]
        }
        if target_line_idx is not None and lines:
            try:
                stype = json.loads(lines[target_line_idx]).get("type")
                if stype == "USER_INPUT":
                    proto_resp["injectSteps"].append({"userMessage": sanitized})
            except Exception:
                pass

        try:
            with open("/tmp/ai-guard-wrapper.log", "a") as lf:
                lf.write(f"PROMPT SANITIZED: target_type={stype if 'stype' in locals() else 'unknown'} sanitized={sanitized[:100]!r}\n")
        except Exception:
            pass

        print(json.dumps(proto_resp))
        sys.exit(0)

    print("{}")
    sys.exit(0)


def handle_output_route(payload):
    code, data = run_guard("output", stdin_str=json.dumps(payload))
    if code == 2 or data.get("decision") == "deny":
        reason = data.get("reason", "Tool output blocked by security guard")
        sys.stderr.write(f"SECURITY GUARD: {reason}\n")
        print("{}")
        sys.exit(2)

    # In Antigravity, PostToolUse expects an empty JSON object `{}`.
    # PostToolUseResponse in protobuf schema has no fields (no decision, overwrite, etc.).
    print("{}")
    sys.exit(0)


def handle_command_route(payload, tool_args):
    cmd = ""
    for k in ("CommandLine", "commandLine", "command", "cmd"):
        if k in tool_args and isinstance(tool_args[k], str):
            cmd = tool_args[k].strip().strip("'\"")
            break
    if not cmd and isinstance(payload, dict):
        for k in ("CommandLine", "commandLine", "command", "cmd"):
            if k in payload and isinstance(payload[k], str):
                cmd = payload[k].strip().strip("'\"")
                break

    if not cmd:
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)

    # 1. Inspect command line for restricted file targets
    file_code, file_data = run_guard("file", stdin_str=json.dumps(payload))
    if file_code == 2 or file_data.get("decision") == "deny":
        reason = file_data.get("reason", f"Command references restricted file: {cmd}")
        sys.stderr.write(f"SECURITY GUARD: {reason}\n")
        print(json.dumps({"decision": "deny", "reason": reason}))
        sys.exit(2)

    # 2. Evaluate command against command rules
    code, data = run_guard("command", args=[cmd], stdin_str=json.dumps(payload))
    if code == 2 or data.get("decision") == "deny":
        reason = data.get("reason", f"Command is forbidden: {cmd}")
        sys.stderr.write(f"SECURITY GUARD: {reason}\n")
        print(json.dumps({"decision": "deny", "reason": reason}))
        sys.exit(2)

    dec = data.get("decision")
    if dec == "replace":
        modified = data.get("modified") or data.get("command") or cmd
        print(json.dumps({
            "decision": "allow",
            "overwrite": {"CommandLine": modified}
        }))
        sys.exit(0)

    # Safe command: pass through to IDE policy / commands.json
    print(json.dumps({"decision": "allow"}))
    sys.exit(0)


def handle_file_route(payload, tool_name, tool_args):
    if tool_name in ("run_command", "bash", "execute_command", "runTerminalCommand", "terminal"):
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)
    targets = []
    path_keys = (
        "AbsolutePath", "TargetFile", "filePath", "path", "file",
        "target_file", "targetFile", "DirectoryPath", "SearchPath",
        "SearchDirectory", "Uri", "uri", "resourceUri"
    )
    for pk in path_keys:
        if pk in tool_args and isinstance(tool_args[pk], str):
            targets.append(tool_args[pk])
        if pk in payload and isinstance(payload[pk], str):
            targets.append(payload[pk])

    if not targets:
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)

    code, data = run_guard("file", args=targets, stdin_str=json.dumps(payload))
    if code == 2 or data.get("decision") == "deny":
        reason = data.get("reason", f"Access to sensitive file blocked: {', '.join(targets)}")
        sys.stderr.write(f"SECURITY GUARD: {reason}\n")
        print(json.dumps({"decision": "deny", "reason": reason}))
        sys.exit(2)

    dec = data.get("decision")
    if dec == "replace":
        resp = {"decision": "allow"}
        if data.get("replacement"):
            resp["overwrite"] = {pk: data["replacement"] for pk in path_keys if pk in tool_args}
        print(json.dumps(resp))
        sys.exit(0)

    # Unmatched / safe file: proceed to IDE checks
    print(json.dumps({"decision": "allow"}))
    sys.exit(0)


def main():
    route = sys.argv[1] if len(sys.argv) > 1 else ""
    raw_input = sys.stdin.read()
    if os.environ.get("AI_GUARD_DEBUG"):
        try:
            with open("/tmp/ai-guard-wrapper.log", "a") as f:
                f.write(f"HOOK CALLED: argv={sys.argv!r} len={len(raw_input)}\n")
        except Exception:
            pass
    payload = {}
    if raw_input.strip():
        try:
            payload = json.loads(raw_input)
        except Exception:
            payload = {}

    tool_call = payload.get("toolCall", {})
    tool_name = tool_call.get("name", "") if isinstance(tool_call, dict) else ""
    tool_args = tool_call.get("args", {}) if isinstance(tool_call, dict) else {}

    command_tools = (
        "run_command", "bash", "execute_command", "runTerminalCommand",
        "terminal", "sh", "zsh", "shell", "exec"
    )

    if not route:
        if (
            "toolResult" in payload
            or "tool_result" in payload
            or payload.get("hook_event_name") == "PostToolUse"
            or ("result" in payload and "toolCall" not in payload)
            or ("output" in payload and "toolCall" not in payload)
        ):
            route = "output"
        elif "transcriptPath" in payload or "invocationNum" in payload or ("prompt" in payload and not tool_call):
            route = "prompt"
        elif tool_name in command_tools:
            route = "command"
        elif tool_call:
            route = "file"
        else:
            route = "prompt"

    if route == "prompt":
        handle_prompt_route(payload)
    elif route in ("output", "post-tool", "PostToolUse"):
        handle_output_route(payload)
    elif route == "command":
        handle_command_route(payload, tool_args)
    elif route == "file":
        handle_file_route(payload, tool_name, tool_args)
    else:
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)

if __name__ == "__main__":
    main()
