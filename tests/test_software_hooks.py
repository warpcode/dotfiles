#!/usr/bin/env python3
"""
Unified End-to-End Test Suite for AI Lifecycle Hooks.
Tests the integration and enforcement of AI Guard hooks across their
corresponding software runtimes:
  - Antigravity CLI (agy) & Antigravity Hook Bridge
  - GitHub Copilot CLI (copilot) & Copilot Rust Hook Engine
  - OpenCode CLI (opencode) & OpenCode TypeScript Plugin Suite
  - Visual Studio Code (code) & VS Code Agent Customization Hooks
"""

import glob
import json
import os
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

# Paths
REPO_ROOT = Path(__file__).resolve().parent.parent
DOT_LOCAL_BIN = REPO_ROOT / "dot_local" / "bin"
AI_GUARD_BIN = DOT_LOCAL_BIN / "executable_df.ai-guard"
AI_GUARD_HOOK = DOT_LOCAL_BIN / "executable_df.ai-guard-hook"
AGY_WRAPPER = REPO_ROOT / "dot_gemini" / "config" / "executable_ai-guard-wrapper.py"
AGY_HOOKS_JSON = REPO_ROOT / "dot_gemini" / "config" / "hooks.json"
COPILOT_HOOKS_JSON = REPO_ROOT / "dot_copilot" / "hooks" / "security.json"
OPENCODE_PLUGIN = REPO_ROOT / "dot_config" / "opencode" / "plugins" / "security-suite.ts"
OPENCODE_TEST_MJS = REPO_ROOT / "tests" / "test_opencode_plugin.mjs"
VSCODE_SETTINGS_TMPL = REPO_ROOT / "dot_config" / "Code" / "User" / "settings.json.tmpl"
VALIDATE_SCRIPT = Path.home() / ".gemini" / "config" / "skills" / "ai-authoring-hooks" / "scripts" / "validate.py"


def resolve_binary(name: str) -> str | None:
    """Find a binary by name, searching standard PATH and user mise/local paths."""
    found = shutil.which(name)
    if found:
        return found
    search_paths = [
        Path.home() / ".local/share/mise/installs/agy/latest/agy",
        Path.home() / ".gemini/bin/agy",
        Path.home() / ".local/share/mise/installs/npm-github-copilot/latest/bin/copilot",
        Path.home() / ".local/share/mise/installs/opencode/latest/opencode",
        Path.home() / ".local/share/mise/installs/node/latest/bin/node",
        Path.home() / ".local/bin" / name,
        Path("/usr/bin") / name,
    ]
    for p in search_paths:
        cand = p / name if p.is_dir() else p
        if cand.name == name and cand.is_file() and os.access(cand, os.X_OK):
            return str(cand)
    return None


def get_base_env() -> dict[str, str]:
    """Get environment dictionary with mise bin paths prepended to PATH."""
    env = os.environ.copy()
    mise_paths = [
        str(Path.home() / ".local/share/mise/installs/agy/latest"),
        str(Path.home() / ".gemini/bin"),
        str(Path.home() / ".local/share/mise/installs/npm-github-copilot/latest/bin"),
        str(Path.home() / ".local/share/mise/installs/opencode/latest"),
        str(Path.home() / ".local/share/mise/installs/node/latest/bin"),
        str(DOT_LOCAL_BIN),
        str(Path.home() / ".local/bin"),
    ]
    current_path = env.get("PATH", "")
    env["PATH"] = ":".join(mise_paths + [current_path])
    return env


def run_ai_guard_hook(args: list[str], stdin_payload: dict | str, env: dict) -> subprocess.CompletedProcess:
    """Run df.ai-guard-hook via bash or direct execution."""
    installed_hook = Path.home() / ".local/bin/df.ai-guard-hook"
    if installed_hook.is_file() and os.access(installed_hook, os.X_OK):
        cmd = [str(installed_hook)] + args
    else:
        cmd = ["bash", str(AI_GUARD_HOOK)] + args

    input_str = json.dumps(stdin_payload) if isinstance(stdin_payload, dict) else str(stdin_payload)
    return subprocess.run(cmd, input=input_str, capture_output=True, text=True, env=env)


# ==============================================================================
# Antigravity Hooks Test Suite (agy)
# ==============================================================================

class TestAntigravityHooks(unittest.TestCase):
    """Verifies Antigravity CLI and ProtoJSON hook bridge integration."""

    @classmethod
    def setUpClass(cls):
        cls.agy_bin = resolve_binary("agy")
        cls.env = get_base_env()

    def test_antigravity_binary_available(self):
        """Confirms agy CLI binary is present and executable."""
        self.assertIsNotNone(self.agy_bin, "agy binary must be resolvable on host")
        res = subprocess.run([self.agy_bin, "--help"], capture_output=True, text=True, env=self.env)
        combined = res.stdout + res.stderr
        self.assertEqual(res.returncode, 0)
        self.assertIn("Usage of agy", combined)

    def test_antigravity_hooks_config_valid(self):
        """Confirms hooks.json exists, is valid JSON, and maps events to wrapper."""
        self.assertTrue(AGY_HOOKS_JSON.is_file(), f"{AGY_HOOKS_JSON} must exist")
        with open(AGY_HOOKS_JSON, "r", encoding="utf-8") as f:
            data = json.load(f)
        for key in ("ai-command-gate", "ai-file-guard", "ai-output-scrubber", "ai-prompt-sanitizer"):
            self.assertIn(key, data, f"{key} must be declared in Antigravity hooks")

    def test_antigravity_pre_invocation_sanitization(self):
        """PreInvocation sanitizes prompt and generates injectSteps notice."""
    def test_antigravity_pre_invocation_blocks_secret_token(self):
        """PreInvocation hard blocks prompt containing sensitive API tokens (e.g. ghp_)."""
        payload = {
            "prompt": "Here is my secret token: ghp_111111111111111111111111111111111111 please analyze."
        }
        res = subprocess.run(
            [sys.executable, str(AGY_WRAPPER), "prompt"],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            env=self.env
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD", res.stderr)
        self.assertIn("Prompt submission blocked", res.stderr)

    def test_antigravity_pre_invocation_safe_prompt(self):
        """PreInvocation safely allows prompts without secrets with empty JSON object."""
        payload = {
            "prompt": "Please explain how python unittest works."
        }
        res = subprocess.run(
            [sys.executable, str(AGY_WRAPPER), "prompt"],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            env=self.env
        )
        self.assertEqual(res.returncode, 0)
        out = json.loads(res.stdout)
        self.assertIn("injectSteps", out)
        msg = out["injectSteps"][0].get("ephemeralMessage", "")
        self.assertIn("Security Notice", msg)
        self.assertEqual(out, {})

    def test_antigravity_pre_invocation_blocks_private_key(self):
        """PreInvocation hard blocks prompt containing private key material."""
        payload = {
            "prompt": "-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAAGAAAAMAAAADEAAAAAA=\n-----END OPENSSH PRIVATE KEY-----"
        }
        res = subprocess.run(
            [sys.executable, str(AGY_WRAPPER), "prompt"],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            env=self.env
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD", res.stderr)

    def test_antigravity_pre_tool_use_command_blocking(self):
        """PreToolUse command gate blocks dangerous commands (e.g. rm -rf /, python inline)."""
        dangerous_cmds = [
            "python3 -c 'import os; os.system(\"id\")'",
            "rm -rf /",
            "rm -rf ~",
            "rm -rf $HOME",
        ]
        for cmd in dangerous_cmds:
            with self.subTest(cmd=cmd):
                payload = {
                    "toolCall": {
                        "name": "run_command",
                        "args": {"CommandLine": cmd}
                    }
                }
                res = subprocess.run(
                    [sys.executable, str(AGY_WRAPPER), "command"],
                    input=json.dumps(payload),
                    capture_output=True,
                    text=True,
                    env=self.env
                )
                self.assertEqual(res.returncode, 2, f"Expected {cmd} to be blocked with code 2")
                self.assertIn("SECURITY GUARD", res.stderr)

    def test_antigravity_pre_tool_use_command_allowed(self):
        """PreToolUse command gate allows safe commands."""
        safe_cmds = ["git status", "ls -la", "echo 'Hello World'"]
        for cmd in safe_cmds:
            with self.subTest(cmd=cmd):
                payload = {
                    "toolCall": {
                        "name": "run_command",
                        "args": {"CommandLine": cmd}
                    }
                }
                res = subprocess.run(
                    [sys.executable, str(AGY_WRAPPER), "command"],
                    input=json.dumps(payload),
                    capture_output=True,
                    text=True,
                    env=self.env
                )
                self.assertEqual(res.returncode, 0)
                out = json.loads(res.stdout)
                self.assertEqual(out.get("decision"), "allow")

    def test_antigravity_pre_tool_use_file_blocking(self):
        """PreToolUse file guard blocks reading sensitive keys/configs."""
        payload = {
            "toolCall": {
                "name": "view_file",
                "args": {"AbsolutePath": "/home/jase/.ssh/id_rsa"}
            }
        }
        res = subprocess.run(
            [sys.executable, str(AGY_WRAPPER), "file"],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            env=self.env
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD", res.stderr)

    def test_antigravity_post_tool_use_redaction(self):
        """PostToolUse redacts leaked credentials in tool execution output."""
        payload = {
            "toolResult": "System error: secret token sk-proj-1234567890123456789012345678901234567890 leaked in log."
        }
        res = subprocess.run(
            [sys.executable, str(AGY_WRAPPER), "output"],
            input=json.dumps(payload),
            capture_output=True,
            text=True,
            env=self.env
        )
        self.assertEqual(res.returncode, 0)
        out = json.loads(res.stdout)
        self.assertEqual(out.get("decision"), "allow")
        self.assertNotIn("sk-proj-1234567890123456789012345678901234567890", out.get("toolResult", ""))
        self.assertIn("REDACTED", out.get("toolResult", ""))


# ==============================================================================
# GitHub Copilot Hooks Test Suite (copilot)
# ==============================================================================

class TestCopilotHooks(unittest.TestCase):
    """Verifies GitHub Copilot CLI binary, Rust hook runner, and df.ai-guard-hook."""

    @classmethod
    def setUpClass(cls):
        cls.copilot_bin = resolve_binary("copilot")
        cls.env = get_base_env()

    def test_copilot_binary_available(self):
        """Confirms copilot CLI binary is present and executable."""
        self.assertIsNotNone(self.copilot_bin, "copilot binary must be resolvable on host")
        res = subprocess.run([self.copilot_bin, "-v"], capture_output=True, text=True, env=self.env)
        self.assertEqual(res.returncode, 0)

    def test_copilot_hooks_config_valid(self):
        """Confirms security.json exists, is valid JSON, and points to df.ai-guard-hook."""
        self.assertTrue(COPILOT_HOOKS_JSON.is_file(), f"{COPILOT_HOOKS_JSON} must exist")
        with open(COPILOT_HOOKS_JSON, "r", encoding="utf-8") as f:
            data = json.load(f)
        hooks = data.get("hooks", {})
        self.assertIn("UserPromptSubmit", hooks)
        self.assertIn("PreToolUse", hooks)
        self.assertIn("PostToolUse", hooks)

    def test_copilot_prompt_hook_blocks_private_key(self):
        """df.ai-guard-hook prompt blocks private key submissions with exit code 2."""
        payload = {
            "prompt": "-----BEGIN OPENSSH PRIVATE KEY-----\ndummy content\n-----END OPENSSH PRIVATE KEY-----"
        }
        res = run_ai_guard_hook(["prompt"], payload, self.env)
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD", res.stderr)
        self.assertIn("Private Key material detected and blocked", res.stderr)

    def test_copilot_prompt_hook_redacts_api_tokens(self):
        """df.ai-guard-hook prompt redacts API tokens and returns code 0."""
        payload = {
            "prompt": "Here is token: ghp_123456789012345678901234567890123456"
        }
        res = run_ai_guard_hook(["prompt"], payload, self.env)
        self.assertEqual(res.returncode, 0)
        self.assertNotIn("ghp_123456789012345678901234567890123456", res.stdout)
        self.assertIn("REDACTED", res.stdout)

    def test_copilot_pre_tool_use_command_blocking(self):
        """PreToolUse rejects dangerous shell commands via df.ai-guard-hook."""
        payload = {
            "hook_event_name": "PreToolUse",
            "tool_name": "runTerminalCommand",
            "tool_input": {
                "command": "rm -rf /"
            }
        }
        res = run_ai_guard_hook(["command"], payload, self.env)
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD", res.stderr)

    def test_copilot_pre_tool_use_command_allowed(self):
        """PreToolUse permits safe terminal commands."""
        payload = {
            "hook_event_name": "PreToolUse",
            "tool_name": "runTerminalCommand",
            "tool_input": {
                "command": "git status"
            }
        }
        res = run_ai_guard_hook(["command"], payload, self.env)
        self.assertEqual(res.returncode, 0)

    def test_copilot_pre_tool_use_file_blocking(self):
        """PreToolUse rejects attempts to read sensitive key files."""
        payload = {
            "hook_event_name": "PreToolUse",
            "tool_name": "readFile",
            "tool_input": {
                "path": "/home/jase/.ssh/id_rsa"
            }
        }
        res = run_ai_guard_hook(["file"], payload, self.env)
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD", res.stderr)

    def test_copilot_post_tool_use_redaction(self):
        """PostToolUse redacts leaked credentials from command results."""
        payload = {
            "hook_event_name": "PostToolUse",
            "tool_name": "runTerminalCommand",
            "tool_result": "Error connecting to db: password=supersecret token=ghp_999999999999999999999999999999999999"
        }
        res = run_ai_guard_hook(["output"], payload, self.env)
        self.assertEqual(res.returncode, 0)
        self.assertNotIn("ghp_999999999999999999999999999999999999", res.stdout)
        self.assertIn("REDACTED", res.stdout)


# ==============================================================================
# OpenCode Hooks Test Suite (opencode)
# ==============================================================================

class TestOpenCodeHooks(unittest.TestCase):
    """Verifies OpenCode CLI binary, plugin resolution, and TypeScript plugin suite."""

    @classmethod
    def setUpClass(cls):
        cls.opencode_bin = resolve_binary("opencode")
        cls.node_bin = resolve_binary("node")
        cls.env = get_base_env()

    def test_opencode_binary_available(self):
        """Confirms opencode CLI binary is present and executable."""
        self.assertIsNotNone(self.opencode_bin, "opencode binary must be resolvable on host")
        res = subprocess.run([self.opencode_bin, "--version"], capture_output=True, text=True, env=self.env)
        self.assertEqual(res.returncode, 0)
        self.assertTrue(res.stdout.strip().startswith("1."))

    def test_node_binary_available(self):
        """Confirms node runtime is present for running OpenCode plugin tests."""
        self.assertIsNotNone(self.node_bin, "node binary must be resolvable on host")
        res = subprocess.run([self.node_bin, "--version"], capture_output=True, text=True, env=self.env)
        self.assertEqual(res.returncode, 0)
        self.assertTrue(res.stdout.strip().startswith("v"))

    def test_opencode_config_discovery(self):
        """Executes opencode debug config to verify plugin discovery."""
        res = subprocess.run(
            [self.opencode_bin, "debug", "config"],
            capture_output=True,
            text=True,
            env=self.env,
            timeout=15
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("security-suite.ts", res.stdout)

    def test_opencode_plugin_full_suite(self):
        """Executes node tests/test_opencode_plugin.mjs covering all 30 plugin assertions."""
        self.assertTrue(OPENCODE_TEST_MJS.is_file(), f"{OPENCODE_TEST_MJS} must exist")
        res = subprocess.run(
            [self.node_bin, str(OPENCODE_TEST_MJS)],
            capture_output=True,
            text=True,
            env=self.env,
            timeout=30
        )
        self.assertEqual(res.returncode, 0, f"OpenCode plugin test suite failed: {res.stderr}\n{res.stdout}")
        self.assertIn("30/30 assertions passed!", res.stdout)


# ==============================================================================
# VS Code Hooks Test Suite (code)
# ==============================================================================

class TestVSCodeHooks(unittest.TestCase):
    """Verifies VS Code CLI binary, hook specifications, and agent contracts."""

    @classmethod
    def setUpClass(cls):
        cls.code_bin = resolve_binary("code")
        cls.env = get_base_env()

    def test_vscode_binary_available(self):
        """Confirms code CLI binary is present and executable."""
        self.assertIsNotNone(self.code_bin, "code binary must be resolvable on host")
        res = subprocess.run([self.code_bin, "--version"], capture_output=True, text=True, env=self.env)
        self.assertEqual(res.returncode, 0)
        self.assertTrue("1.136" in res.stdout or "." in res.stdout.splitlines()[0])

    def test_vscode_settings_template_valid(self):
        """Confirms VS Code settings template exists and specifies agent configuration."""
        self.assertTrue(VSCODE_SETTINGS_TMPL.is_file(), f"{VSCODE_SETTINGS_TMPL} must exist")
        with open(VSCODE_SETTINGS_TMPL, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("chat.tools.terminal.enableAutoApprove", content)
        self.assertIn("commands/vscode.tmpl", content)

    def test_vscode_pre_tool_use_command_blocking(self):
        """Tests VS Code agent PreToolUse payload format for command gating."""
        payload = {
            "timestamp": "2026-09-12T12:00:00Z",
            "cwd": "/home/jase/src/dotfiles",
            "session_id": "vscode-agent-session-123",
            "hook_event_name": "PreToolUse",
            "tool_name": "runTerminalCommand",
            "tool_input": {
                "command": "rm -rf /"
            }
        }
        res = run_ai_guard_hook(["command"], payload, self.env)
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD:", res.stderr)
        self.assertIn("forbidden", res.stderr)

    def test_vscode_pre_tool_use_command_allowed(self):
        """Tests VS Code agent PreToolUse payload format for safe commands."""
        payload = {
            "timestamp": "2026-09-12T12:00:00Z",
            "cwd": "/home/jase/src/dotfiles",
            "session_id": "vscode-agent-session-123",
            "hook_event_name": "PreToolUse",
            "tool_name": "runTerminalCommand",
            "tool_input": {
                "command": "git status"
            }
        }
        res = run_ai_guard_hook(["command"], payload, self.env)
        self.assertEqual(res.returncode, 0)

    def test_vscode_pre_tool_use_file_blocking(self):
        """Tests VS Code agent PreToolUse payload format for sensitive file access."""
        payload = {
            "timestamp": "2026-09-12T12:00:00Z",
            "cwd": "/home/jase/src/dotfiles",
            "session_id": "vscode-agent-session-123",
            "hook_event_name": "PreToolUse",
            "tool_name": "readFile",
            "tool_input": {
                "path": "/home/jase/.ssh/id_rsa"
            }
        }
        res = run_ai_guard_hook(["file"], payload, self.env)
        self.assertEqual(res.returncode, 2)
        self.assertIn("SECURITY GUARD: Access to sensitive file", res.stderr)

    def test_vscode_post_tool_use_redaction(self):
        """Tests VS Code agent PostToolUse payload format for secret scrubbing."""
        payload = {
            "timestamp": "2026-09-12T12:00:00Z",
            "cwd": "/home/jase/src/dotfiles",
            "session_id": "vscode-agent-session-123",
            "hook_event_name": "PostToolUse",
            "tool_name": "runTerminalCommand",
            "tool_result": "AWS credentials: AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
        }
        res = run_ai_guard_hook(["output"], payload, self.env)
        self.assertEqual(res.returncode, 0)
        self.assertNotIn("wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY", res.stdout)
        self.assertIn("REDACTED", res.stdout)


# ==============================================================================
# Cross-Platform Schema Validation Test Suite
# ==============================================================================

class TestCrossPlatformHookSchemas(unittest.TestCase):
    """Validates hook definitions against the universal hook schema validator."""

    def test_validate_all_hook_configurations(self):
        """Validates all hook JSON configurations in dotfiles using validate.py."""
        if not VALIDATE_SCRIPT.is_file():
            self.skipTest(f"validate.py not found at {VALIDATE_SCRIPT}")

        hook_files = [
            COPILOT_HOOKS_JSON,
            REPO_ROOT / "dot_codex" / "hooks.json",
            REPO_ROOT / "dot_cursor" / "hooks.json",
            AGY_HOOKS_JSON,
        ]
        for hf in hook_files:
            with self.subTest(file=hf.name):
                self.assertTrue(hf.is_file(), f"{hf} must exist")
                res = subprocess.run(
                    [sys.executable, str(VALIDATE_SCRIPT), str(hf)],
                    capture_output=True,
                    text=True
                )
                self.assertEqual(res.returncode, 0, f"Validation failed for {hf}:\n{res.stdout}\n{res.stderr}")
                self.assertIn(f"PASS: {hf}", res.stdout)


if __name__ == "__main__":
    unittest.main()
