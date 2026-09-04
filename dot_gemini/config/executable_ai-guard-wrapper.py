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
    local_bin = Path.home() / ".local" / "bin" / "df.ai-guard"
    if local_bin.is_file() and os.access(local_bin, os.X_OK):
        return str(local_bin)
    p = shutil.which("df.ai-guard")
    if p:
        return p
    repo_cand = Path.home() / "src" / "dotfiles" / "dot_local" / "bin" / "executable_df.ai-guard"
    if repo_cand.is_file():
        return str(repo_cand)
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
        return 0, {}


def main():
    route = sys.argv[1] if len(sys.argv) > 1 else ""
    raw_input = sys.stdin.read()
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

    if not route:
        if "transcriptPath" in payload or "invocationNum" in payload or "prompt" in payload:
            route = "prompt"
        elif tool_name in ("run_command", "bash", "execute_command", "runTerminalCommand", "terminal"):
            route = "command"
        else:
            route = "file"

    # =========================================================================
    # ROUTE: PROMPT (PreInvocation)
    # =========================================================================
    if route == "prompt":
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
            print(json.dumps({}))
            sys.exit(0)

        code, data = run_guard("prompt", stdin_str=json.dumps({"text": prompt_text}))

        if code == 2 or data.get("decision") == "deny":
            reason = data.get("reason", "Content blocked by security guard")
            sys.stderr.write(f"SECURITY GUARD: {reason}\n")
            print(json.dumps({"decision": "deny", "reason": reason}))
            sys.exit(2)

        if data.get("decision") == "replace" and data.get("sanitized"):
            sanitized = data["sanitized"]
            reasons = data.get("reasons", [])
            notice = f"Security Notice: Redacted sensitive items ({', '.join(reasons)})" if reasons else "Security Notice: Redacted sensitive items."

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

        print(json.dumps({}))
        sys.exit(0)

    # =========================================================================
    # ROUTE: COMMAND (PreToolUse on command execution)
    # =========================================================================
    if route == "command":
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
        code, data = run_guard("command", args=[cmd])
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

        if dec == "allow":
            resp = {
                "decision": "allow"
            }
            if cmd != tool_args.get("CommandLine"):
                resp["overwrite"] = {"CommandLine": cmd}
            try:
                with open("/tmp/ai-guard-wrapper.log", "a") as lf:
                    lf.write(f"ALLOW: cmd={cmd!r} data={data!r} resp={resp!r}\n")
            except Exception:
                pass
            print(json.dumps(resp))
            sys.exit(0)

        if dec == "ask":
            resp = {"decision": "ask"}
            if data.get("reason"):
                resp["reason"] = data["reason"]
            try:
                with open("/tmp/ai-guard-wrapper.log", "a") as lf:
                    lf.write(f"ASK: cmd={cmd!r} data={data!r} resp={resp!r}\n")
            except Exception:
                pass
            print(json.dumps(resp))
            sys.exit(0)

        # Unmatched command: default to ask
        try:
            with open("/tmp/ai-guard-wrapper.log", "a") as lf:
                lf.write(f"UNMATCHED (ASK): cmd={cmd!r} data={data!r}\n")
        except Exception:
            pass
        print(json.dumps({"decision": "ask"}))
        sys.exit(0)

    # =========================================================================
    # ROUTE: FILE (PreToolUse on file tools)
    # =========================================================================
    if route == "file":
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

        code, data = run_guard("file", args=targets)
        if code == 2 or data.get("decision") == "deny":
            reason = data.get("reason", f"Access to sensitive file blocked: {', '.join(targets)}")
            sys.stderr.write(f"SECURITY GUARD: {reason}\n")
            print(json.dumps({"decision": "deny", "reason": reason}))
            sys.exit(2)

        dec = data.get("decision")
        if dec in ("allow", "ask"):
            resp = {"decision": dec}
            if data.get("reason"):
                resp["reason"] = data["reason"]
            print(json.dumps(resp))
            sys.exit(0)

        # Unmatched file: proceed to IDE checks
        print(json.dumps({"decision": "allow"}))
        sys.exit(0)

    print(json.dumps({"decision": "allow"}))
    sys.exit(0)


if __name__ == "__main__":
    main()