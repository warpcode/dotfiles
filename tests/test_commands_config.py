"""Tests for unified chezmoi command permissions and templates across IDEs."""

import json
import os
import re
import shutil
import subprocess
import unittest

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COMMANDS_JSON_PATH = os.path.join(REPO_ROOT, ".chezmoidata", "commands.json")
PATHS_JSON_PATH = os.path.join(REPO_ROOT, ".chezmoidata", "paths.json")
CHEZMOI_AVAILABLE = shutil.which("chezmoi") is not None


def parse_jsonc_reference(text):
    """Reference implementation of scanner-based JSONC parser."""
    text = text.strip()
    if not text:
        return {}
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    result = []
    i = 0
    n = len(text)
    in_string = False
    escape = False

    while i < n:
        char = text[i]
        if in_string:
            result.append(char)
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == '"':
                in_string = False
            i += 1
        else:
            if char == '"':
                in_string = True
                result.append(char)
                i += 1
            elif char == "/" and i + 1 < n and text[i + 1] == "/":
                i += 2
                while i < n and text[i] != "\n":
                    i += 1
            elif char == "/" and i + 1 < n and text[i + 1] == "*":
                i += 2
                while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                    i += 1
                i += 2
            else:
                result.append(char)
                i += 1

    cleaned = "".join(result)
    cleaned = re.sub(r",\s*([\]}])", r"\1", cleaned)
    return json.loads(cleaned)


class TestCommandsCatalog(unittest.TestCase):
    """Validate .chezmoidata/commands.json schema and completeness."""

    def test_commands_json_exists_and_valid(self):
        assert os.path.isfile(COMMANDS_JSON_PATH)
        with open(COMMANDS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        assert "commands" in data
        cmds = data["commands"]
        assert "allow" in cmds and isinstance(cmds["allow"], list)
        assert "ask" in cmds and isinstance(cmds["ask"], list)
        assert "deny" in cmds and isinstance(cmds["deny"], list)
        assert len(cmds["allow"]) >= 50
        assert len(cmds["ask"]) >= 8
        assert len(cmds["deny"]) >= 8

    def test_command_entries_are_valid_strings(self):
        with open(COMMANDS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        for group in ["allow", "ask", "deny"]:
            for item in data["commands"][group]:
                self.assertIsInstance(item, str, f"Entry must be string: {item}")
                self.assertTrue(item.strip(), f"Entry must not be empty: {item}")

    def test_commands_json_glob_syntax(self):
        """Assert that commands in .chezmoidata/commands.json define valid glob patterns."""
        with open(COMMANDS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        has_wildcard = False
        for group in ["allow", "ask", "deny"]:
            for item in data["commands"][group]:
                self.assertIsInstance(item, str)
                self.assertTrue(item.strip())
                if "*" in item:
                    has_wildcard = True
        self.assertTrue(has_wildcard, "Expected glob patterns with wildcards in commands.json")

    def test_all_commands_convert_to_valid_regex(self):
        """Assert that every command in commands.json compiles to a valid regular expression."""
        def glob_to_vscode_regex(raw: str) -> str:
            raw = raw.strip()
            for ch in ['\\', '.', '+', '?', '^', '$', '(', ')', '[', ']', '{', '}']:
                raw = raw.replace(ch, '\\' + ch)
            raw = raw.replace('*', '.*')
            return f"/^{raw}$/"

        with open(COMMANDS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        for group in ["allow", "ask", "deny"]:
            for item in data["commands"][group]:
                reg_wrapper = glob_to_vscode_regex(item)
                self.assertTrue(reg_wrapper.startswith("/^") and reg_wrapper.endswith("$/"))
                raw_regex = reg_wrapper[1:-1]
                try:
                    compiled = re.compile(raw_regex)
                except re.error as e:
                    self.fail(f"Invalid regex for command '{item}': {raw_regex} (error: {e})")

                if "*" in item:
                    sample = item.replace("*", "test_arg")
                    self.assertIsNotNone(compiled.match(sample), f"Regex {raw_regex} did not match {sample}")
                else:
                    self.assertIsNotNone(compiled.match(item), f"Regex {raw_regex} did not match {item}")

    def test_paths_json_exists_and_valid(self):
        """Assert that .chezmoidata/paths.json exists and defines valid read/write/deny lists."""
        assert os.path.isfile(PATHS_JSON_PATH)
        with open(PATHS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)

        assert "paths" in data
        paths = data["paths"]
        assert "read" in paths and isinstance(paths["read"], list)
        assert "write" in paths and isinstance(paths["write"], list)
        assert "deny" in paths and isinstance(paths["deny"], list)
        assert any("skills" in p for p in paths["read"])
        assert any(".ssh" in p for p in paths["deny"])



class TestJsoncParsing(unittest.TestCase):
    """Test scanner-based parse_jsonc handles strings with comments/URLs."""

    def test_pure_json(self):
        assert parse_jsonc_reference('{"a": 1, "b": "hello"}') == {"a": 1, "b": "hello"}

    def test_single_line_comments(self):
        raw = """{
            // First comment
            "a": 1, // inline comment
            "b": 2
        }"""
        assert parse_jsonc_reference(raw) == {"a": 1, "b": 2}

    def test_multi_line_comments(self):
        raw = """{
            /* block comment */
            "a": 1,
            /* multiline
               comment */
            "b": 2
        }"""
        assert parse_jsonc_reference(raw) == {"a": 1, "b": 2}

    def test_urls_with_double_slashes_preserved(self):
        raw = """{
            "homepage": "https://example.com/api/v1", // comment
            "proxy": "http://localhost:8080",
            "escaped": "test \\"quote\\" string"
        }"""
        res = parse_jsonc_reference(raw)
        assert res["homepage"] == "https://example.com/api/v1"
        assert res["proxy"] == "http://localhost:8080"
        assert res["escaped"] == 'test "quote" string'

    def test_trailing_commas(self):
        raw = """{
            "list": [1, 2, 3, ],
            "map": {"a": 1, },
        }"""
        assert parse_jsonc_reference(raw) == {"list": [1, 2, 3], "map": {"a": 1}}


def chezmoi_cat(target):
    """Run chezmoi cat using an isolated persistent state file to avoid lock contention."""
    return subprocess.check_output(
        ["chezmoi", "--persistent-state", "/tmp/chezmoitest.boltdb", "cat", target],
        cwd=REPO_ROOT,
        text=True,
    )


@unittest.skipUnless(CHEZMOI_AVAILABLE, "chezmoi executable not found on PATH")
class TestRenderedOutputs(unittest.TestCase):
    """Test chezmoi rendering of all target files."""

    def test_antigravity_cli_settings(self):
        gemini_config = os.path.expanduser("~/.gemini/config/config.json")
        out = chezmoi_cat(gemini_config)
        data = json.loads(out)
        assert "userSettings" in data
        assert "globalPermissionGrants" in data["userSettings"]
        perms = data["userSettings"]["globalPermissionGrants"]
        assert "allow" in perms
        assert "command(git status *)" in perms["allow"]
        assert "unsandboxed(git status *)" in perms["allow"]
        assert "command(git diff *)" in perms["allow"]
        assert "unsandboxed(git diff *)" in perms["allow"]
        assert "command(ls *)" in perms["allow"]
        assert "unsandboxed(ls *)" in perms["allow"]
        assert "command(git push origin HEAD *)" in perms["allow"]
        assert "unsandboxed(git push origin HEAD *)" in perms["allow"]
        assert "command(chezmoi status *)" in perms["allow"]
        assert "unsandboxed(chezmoi status *)" in perms["allow"]
        assert "command(chezmoi diff *)" in perms["allow"]
        assert "unsandboxed(chezmoi diff *)" in perms["allow"]
        assert "command(chezmoi apply *)" not in perms["allow"]
        assert "unsandboxed(chezmoi apply *)" not in perms["allow"]
        assert any("read_file(" in p and "skills" in p for p in perms["allow"])
        assert "ask" in perms
        assert "command(chezmoi apply *)" in perms["ask"]
        assert "unsandboxed(chezmoi apply *)" in perms["ask"]
        assert "deny" in perms
        assert "command(git push --force*)" in perms["deny"]
        assert "unsandboxed(git push --force*)" in perms["deny"]
        for item in perms["allow"] + perms.get("ask", []) + perms.get("deny", []):
            self.assertNotIn("internal/*", item)
            self.assertNotIn("/home/", item, f"Found /home/ in permission item: {item}")
        assert "remoteControlEnabled" in data["userSettings"]
        self.assertTrue(data["userSettings"]["remoteControlEnabled"])


    def test_opencode_json(self):
        out = chezmoi_cat(os.path.expanduser("~/.config/opencode/opencode.json"))
        data = json.loads(out)
        assert "permission" in data
        bash = data["permission"]["bash"]
        assert bash["*"] == "ask"
        assert bash["git status *"] == "allow"
        assert bash["ls *"] == "allow"
        assert bash["git checkout *"] == "allow"
        assert bash["chezmoi status *"] == "allow"
        assert bash["chezmoi diff *"] == "allow"
        assert bash["chezmoi apply *"] == "ask"
        assert bash["rm *"] == "ask"
        assert bash["sudo *"] == "ask"
        assert bash["git push *"] == "ask"
        assert bash["dd *"] == "deny"
        assert bash["rm -rf $HOME*"] == "deny"
        assert bash["git push --force*"] == "deny"
        self.assertNotIn("git checkout * -- internal/*", bash)
        self.assertNotIn("git push *--force*", bash)
        for key in bash:
            self.assertNotIn("/home/", key, f"Found /home/ in opencode bash key: {key}")

        # Path permissions: read, edit, write, external_directory
        perm = data["permission"]
        self.assertIn("read", perm)
        self.assertIsInstance(perm["read"], dict)
        self.assertEqual(perm["read"]["*"], "allow")
        self.assertEqual(perm["read"]["~/.ssh/**"], "deny")
        self.assertEqual(perm["read"]["*.env*"], "deny")
        self.assertEqual(perm["read"]["~/.agents"], "allow")

        self.assertIn("edit", perm)
        self.assertIsInstance(perm["edit"], dict)
        self.assertEqual(perm["edit"]["~/.ssh/**"], "deny")
        self.assertEqual(perm["edit"]["~/src/**"], "allow")

        self.assertIn("external_directory", perm)
        self.assertIsInstance(perm["external_directory"], dict)
        self.assertEqual(perm["external_directory"]["*"], "ask")
        self.assertEqual(perm["external_directory"]["~/.agents"], "allow")
        self.assertEqual(perm["external_directory"]["~/.ssh/**"], "deny")

    def test_claude_settings(self):
        out = chezmoi_cat(os.path.expanduser("~/.claude/settings.json"))
        data = json.loads(out)
        assert "permissions" in data
        perms = data["permissions"]
        assert "Bash(git status *)" in perms["allow"]
        assert "Bash(git diff *)" in perms["allow"]
        assert "Bash(git checkout *)" in perms["allow"]
        assert "Bash(chezmoi status *)" in perms["allow"]
        assert "Bash(chezmoi diff *)" in perms["allow"]
        assert "Bash(chezmoi apply *)" in perms["ask"]
        assert "Bash(sudo *)" in perms["ask"]
        assert "Bash(rm *)" in perms["ask"]
        assert "Bash(git push *)" in perms["ask"]
        assert "Bash(dd *)" in perms["deny"]
        assert "Bash(rm -rf $HOME*)" in perms["deny"]
        assert "Bash(git push --force*)" in perms["deny"]
        assert any("Read(" in p and "skills" in p for p in perms["allow"])
        assert "Read(~/.ssh/**)" in perms["deny"]
        self.assertNotIn("Bash(git checkout * -- internal/*)", perms["allow"])
        self.assertNotIn("Bash(git push *--force*)", perms["ask"])
        for item in perms["allow"] + perms.get("ask", []) + perms.get("deny", []):
            self.assertNotIn("/home/", item, f"Found /home/ in claude permission item: {item}")

    def test_copilot_settings(self):
        out = chezmoi_cat(os.path.expanduser("~/.copilot/settings.json"))
        data = json.loads(out)
        assert "permissions" in data
        perms = data["permissions"]
        assert "Shell(git status *)" in perms["allow"]
        assert "Shell(chezmoi status *)" in perms["allow"]
        assert "Shell(chezmoi diff *)" in perms["allow"]
        assert any("Read(" in p and "skills" in p for p in perms["allow"])
        assert "Shell(chezmoi apply *)" in perms["ask"]
        assert "Shell(git push --force*)" in perms["deny"]
        assert "Read(~/.ssh/**)" in perms["deny"]
        for item in perms["allow"] + perms.get("ask", []) + perms.get("deny", []):
            self.assertNotIn("/home/", item, f"Found /home/ in copilot permission item: {item}")




@unittest.skipUnless(CHEZMOI_AVAILABLE, "chezmoi executable not found on PATH")
class TestPartialAndPatternOnlyRendering(unittest.TestCase):
    """Test templates render cleanly when entries have strings or legacy dicts."""

    def test_templates_support_string_entries(self):
        tmpl = '{{ template "commands/%s" (dict "commands" (dict "allow" (list "echo *" "ls" "git checkout * -- foo/*") "deny" (list "rm -rf *") "ask" (list "sudo"))) }}'
        for name in [
            "antigravity.tmpl",
            "claude.tmpl",
            "copilot.tmpl",
            "opencode.tmpl",
            "vscode.tmpl",
        ]:
            out = subprocess.check_output(
                ["chezmoi", "execute-template", tmpl % name],
                cwd=REPO_ROOT,
                text=True,
            )
            self.assertTrue(len(out.strip()) > 0, f"{name} rendered empty output")

    def test_conflict_precedence_deny_overrides_allow(self):
        """Verify deny/ask precedence across engines via dictionary overwrites, priority levels, or runtime policy."""
        ctx = '(dict "commands" (dict "allow" (list "git push" "rm") "deny" (list "rm") "ask" (list "git push")))'
        
        # VS Code: dictionary overwrite ensures rm and git push regex keys are false
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/vscode.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        parsed = json.loads("{" + out + "}")["chat.tools.terminal.autoApprove"]
        rm_keys = [k for k in parsed if "rm" in k]
        self.assertTrue(len(rm_keys) > 0)
        for k in rm_keys:
            self.assertFalse(parsed[k])
        push_keys = [k for k in parsed if "push" in k]
        self.assertTrue(len(push_keys) > 0)
        for k in push_keys:
            self.assertFalse(parsed[k])

        # OpenCode: dictionary overwrite ensures rm is deny and git push is ask
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/opencode.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        parsed = json.loads("{" + out + "}")["permission"]["bash"]
        self.assertEqual(parsed["rm"], "deny")
        self.assertEqual(parsed["git push"], "ask")

        # Claude: rm is in deny; git push is in ask (runtime precedence: deny > ask > allow)
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/claude.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        perms = json.loads("{" + out + "}")["permissions"]
        self.assertIn("Bash(rm)", perms["deny"])
        self.assertIn("Bash(git push)", perms["ask"])

        # Copilot: rm is in deny; git push is in ask (runtime precedence: deny > ask > allow)
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/copilot.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        perms = json.loads("{" + out + "}")["permissions"]
        self.assertIn("Shell(rm)", perms["deny"])
        self.assertIn("Shell(git push)", perms["ask"])

        # Antigravity CLI: rm is in deny; git push is in ask
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/antigravity.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        cli_perms = json.loads("{" + out + "}")["globalPermissionGrants"]
        self.assertIn("command(rm)", cli_perms["deny"])
        self.assertIn("unsandboxed(rm)", cli_perms["deny"])
        self.assertIn("command(git push)", cli_perms["ask"])
        self.assertIn("unsandboxed(git push)", cli_perms["ask"])

    def test_whitespace_handling(self):
        """Verify leading and trailing whitespace are sanitized."""
        ctx = '(dict "commands" (dict "allow" (list "  echo  " "  git status  ") "deny" (list "rm -rf $HOME") "ask" (list)))'
        
        # Prefix engine (Antigravity CLI): "  echo  " -> "echo", "  git status  " -> "git status"
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/antigravity.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        cli_perms = json.loads("{" + out + "}")["globalPermissionGrants"]["allow"]
        self.assertIn("command(echo)", cli_perms)
        self.assertIn("command(git status)", cli_perms)
        self.assertNotIn("command(  git status  )", cli_perms)


        # Glob engine (Claude Code): rm -rf $HOME present
        out = subprocess.check_output(
            ["chezmoi", "execute-template", f'{{{{ template "commands/claude.tmpl" {ctx} }}}}'],
            cwd=REPO_ROOT,
            text=True,
        )
        perms = json.loads("{" + out + "}")["permissions"]
        self.assertIn("Bash(rm -rf $HOME)", perms["deny"])
        self.assertIn("Bash(git status)", perms["allow"])
        self.assertNotIn("Bash(  git status  )", perms["allow"])


@unittest.skipUnless(CHEZMOI_AVAILABLE, "chezmoi executable not found on PATH")
class TestCanonicalCommandsGenerator(unittest.TestCase):
    """Test unified canonical template and provider dynamic parity."""

    def test_canonical_template_direct_rendering(self):
        """Verify canonical.tmpl outputs valid JSON containing only canonical commands and paths."""
        out = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ includeTemplate "commands/canonical.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        data = json.loads(out)
        self.assertEqual(set(data.keys()), {"commands", "paths"})
        self.assertIn("allow", data["commands"])
        self.assertIn("ask", data["commands"])
        self.assertIn("deny", data["commands"])
        self.assertIn("read", data["paths"])
        self.assertIn("write", data["paths"])
        self.assertIn("deny", data["paths"])

    def test_dynamic_skills_parity_across_all_assistants(self):
        """Verify dynamic skill scripts in canonical data are correctly formatted by each assistant template."""
        sample_script = "~/src/dotfiles/.github/skills/github-cli/scripts/list_issue_types.sh"
        sample_variant = "~/.agents/skills/github-cli/scripts/list_issue_types.sh"

        # 1. Canonical data compiler
        out_canon = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ includeTemplate "commands/canonical.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        canon_data = json.loads(out_canon)
        self.assertIn(sample_script, canon_data["commands"]["allow"])
        self.assertIn(sample_variant, canon_data["commands"]["allow"])

        # 2. Antigravity CLI provider template
        out_agy = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ template "commands/antigravity.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        agy_allow = json.loads("{" + out_agy + "}")["globalPermissionGrants"]["allow"]
        self.assertIn(f"command({sample_script})", agy_allow)
        self.assertIn(f"unsandboxed({sample_script})", agy_allow)
        self.assertIn(f"command({sample_variant})", agy_allow)


        # 3. Claude Code provider template
        out_claude = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ template "commands/claude.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        claude_allow = json.loads("{" + out_claude + "}")["permissions"]["allow"]
        self.assertIn(f"Bash({sample_script})", claude_allow)
        self.assertIn(f"Bash({sample_variant})", claude_allow)

        # 4. GitHub Copilot provider template
        out_copilot = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ template "commands/copilot.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        copilot_allow = json.loads("{" + out_copilot + "}")["permissions"]["allow"]
        self.assertIn(f"Shell({sample_script})", copilot_allow)
        self.assertIn(f"Shell({sample_variant})", copilot_allow)

        # 5. OpenCode provider template
        out_opencode = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ template "commands/opencode.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        opencode_bash = json.loads("{" + out_opencode + "}")["permission"]["bash"]
        self.assertEqual(opencode_bash.get(sample_script), "allow")
        self.assertEqual(opencode_bash.get(sample_variant), "allow")

        # 6. VS Code provider template
        out_vscode = subprocess.check_output(
            ["chezmoi", "execute-template", '{{ template "commands/vscode.tmpl" . }}'],
            cwd=REPO_ROOT,
            text=True,
        )
        vscode_data = json.loads("{" + out_vscode + "}")
        vscode_term = vscode_data["chat.tools.terminal.autoApprove"]
        vscode_edits = vscode_data["chat.tools.edits.autoApprove"]
        matching_keys = [k for k in vscode_term if "list_issue_types" in k]
        self.assertTrue(len(matching_keys) > 0)
        for k in matching_keys:
            self.assertTrue(vscode_term[k])
        self.assertTrue(vscode_edits.get("~/src/**"))
        self.assertFalse(vscode_edits.get("~/.ssh/**"))


if __name__ == "__main__":
    unittest.main()


