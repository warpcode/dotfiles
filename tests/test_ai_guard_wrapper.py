import json
import os
import sys
import unittest
from unittest.mock import patch, MagicMock, mock_open
from io import StringIO
import importlib.util
from pathlib import Path

# Load the module dynamically due to dashes in name
REPO_ROOT = Path(__file__).resolve().parent.parent
WRAPPER_PATH = REPO_ROOT / "dot_gemini" / "config" / "executable_ai-guard-wrapper.py"
spec = importlib.util.spec_from_file_location("ai_guard_wrapper", str(WRAPPER_PATH))
ai_guard_wrapper = importlib.util.module_from_spec(spec)
sys.modules["ai_guard_wrapper"] = ai_guard_wrapper
spec.loader.exec_module(ai_guard_wrapper)


class SystemExitException(Exception):
    pass


class TestAiGuardWrapperHelper(unittest.TestCase):
    def test_extract_command_first_hit(self):
        mapping = {"CommandLine": "  echo first  ", "cmd": "ignore"}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo first")

    def test_extract_command_fallthrough_key(self):
        mapping = {"ignore": "this", "cmd": " echo fallback "}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo fallback")

    def test_extract_command_skips_non_string(self):
        # Even if CommandLine is present, if it's not a string, it should fall through to cmd
        mapping = {"CommandLine": {"complex": "object"}, "cmd": " echo real "}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo real")

    def test_extract_command_empty_string_triggers_payload_fallthrough(self):
        # We test the logic in main by calling extract_command.
        # If tool_args has an empty string command, extract_command returns an empty string.
        # This tests that the function behaves correctly for empty string,
        # the fallthrough to payload is tested separately or implicit from main's `if not cmd` logic.
        tool_args = {"CommandLine": "   "}
        cmd = ai_guard_wrapper.extract_command(tool_args)
        self.assertEqual(cmd, "")

        # Test the exact `not cmd` logic as in main
        payload = {"cmd": " payload_cmd "}
        if not cmd and isinstance(payload, dict):
            cmd = ai_guard_wrapper.extract_command(payload)

        self.assertEqual(cmd, "payload_cmd")

    def test_extract_command_falls_through_empty_string(self):
        # If a higher precedence key has an empty/whitespace string, extract_command
        # should fall through to a lower precedence key in the same mapping.
        mapping = {"CommandLine": "   ", "cmd": " echo fallback "}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo fallback")

    def test_extract_command_multi_quote_strip(self):
        # CRITICAL BEHAVIOR: strips all leading and trailing quote characters
        # "\"quoted\"" -> "quoted"
        mapping = {"CommandLine": "'\"\"echo multi\"'\""}
        result = ai_guard_wrapper.extract_command(mapping)
        self.assertEqual(result, "echo multi")

    def test_extract_command_guards_against_non_dict(self):
        # We explicitly test that if mapping is None or not a dict, it returns empty string
        # without crashing
        self.assertEqual(ai_guard_wrapper.extract_command(None), "")
        self.assertEqual(ai_guard_wrapper.extract_command(["list", "of", "items"]), "")
        self.assertEqual(ai_guard_wrapper.extract_command("CommandLine string"), "")


class TestAIGuardWrapper(unittest.TestCase):

    def setUp(self):
        # Override sys.exit to actually stop execution so subsequent code in the functions doesn't run
        self.exit_patcher = patch('sys.exit', side_effect=SystemExitException)
        self.mock_exit = self.exit_patcher.start()

    def tearDown(self):
        self.exit_patcher.stop()

    @patch('sys.stdout', new_callable=StringIO)
    def test_main_default_to_allow_when_unknown_route(self, mock_stdout):
        # Setting no route and unknown payload payload
        with patch('sys.argv', ['ai-guard-wrapper.py', 'unknown-route']):
            with patch('sys.stdin', StringIO('{"some": "data"}')):
                with self.assertRaises(SystemExitException):
                    ai_guard_wrapper.main()

        self.assertEqual(json.loads(mock_stdout.getvalue()), {"decision": "allow"})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.handle_prompt_route')
    def test_main_dispatch_prompt_route(self, mock_handle_prompt):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('{"prompt": "hello"}')):
                ai_guard_wrapper.main()

        mock_handle_prompt.assert_called_once()
        args, kwargs = mock_handle_prompt.call_args
        self.assertEqual(args[0]['prompt'], "hello")

    @patch('ai_guard_wrapper.handle_output_route')
    def test_main_dispatch_output_route(self, mock_handle_output):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('{"toolResult": "success"}')):
                ai_guard_wrapper.main()

        mock_handle_output.assert_called_once()
        args, kwargs = mock_handle_output.call_args
        self.assertEqual(args[0]['toolResult'], "success")

    @patch('ai_guard_wrapper.handle_command_route')
    def test_main_dispatch_command_route(self, mock_handle_command):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('{"toolCall": {"name": "run_command", "args": {"cmd": "ls"}}}')):
                ai_guard_wrapper.main()

        mock_handle_command.assert_called_once()
        args, kwargs = mock_handle_command.call_args
        self.assertEqual(args[0]['toolCall']['name'], "run_command")

    @patch('ai_guard_wrapper.handle_file_route')
    def test_main_dispatch_file_route(self, mock_handle_file):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('{"toolCall": {"name": "read_file", "args": {"path": "test.txt"}}}')):
                ai_guard_wrapper.main()

        mock_handle_file.assert_called_once()
        args, kwargs = mock_handle_file.call_args
        self.assertEqual(args[0]['toolCall']['name'], "read_file")

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_command_route_allow(self, mock_stdout, mock_run_guard):
        mock_run_guard.side_effect = [(0, {"decision": "allow"}), (0, {"decision": "allow"})]

        payload = {"toolCall": {"name": "run_command", "args": {"cmd": "ls"}}}
        tool_args = payload["toolCall"]["args"]

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_command_route(payload, tool_args)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {"decision": "allow"})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_command_route_deny(self, mock_stderr, mock_stdout, mock_run_guard):
        mock_run_guard.side_effect = [(0, {"decision": "allow"}), (2, {"decision": "deny", "reason": "No way"})]

        payload = {"toolCall": {"name": "run_command", "args": {"cmd": "ls"}}}
        tool_args = payload["toolCall"]["args"]

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_command_route(payload, tool_args)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {"decision": "deny", "reason": "No way"})
        self.mock_exit.assert_called_with(2)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_file_route_allow(self, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "allow"})

        payload = {"toolCall": {"name": "read_file", "args": {"path": "test.txt"}}}
        tool_args = payload["toolCall"]["args"]

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_file_route(payload, "read_file", tool_args)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {"decision": "allow"})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_output_route_allow(self, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "allow"})

        payload = {"toolResult": "success"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_output_route(payload)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {})
        self.mock_exit.assert_called_with(0)

    @patch('sys.stdout', new_callable=StringIO)
    def test_empty_payload(self, mock_stdout):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('')):
                with patch('ai_guard_wrapper.handle_prompt_route', side_effect=SystemExitException) as mock_handle_prompt:
                    with self.assertRaises(SystemExitException):
                        ai_guard_wrapper.main()
                    mock_handle_prompt.assert_called_once_with({})

    @patch('sys.stdout', new_callable=StringIO)
    def test_malformed_json(self, mock_stdout):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('not json')):
                with patch('ai_guard_wrapper.handle_prompt_route', side_effect=SystemExitException) as mock_handle_prompt:
                    with self.assertRaises(SystemExitException):
                        ai_guard_wrapper.main()
                    mock_handle_prompt.assert_called_once_with({})

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_prompt_route_transcript_extracts_last_valid_prompt(self, mock_stdout, mock_run_guard):
        import tempfile
        mock_run_guard.return_value = (0, {"decision": "allow"})

        with tempfile.TemporaryDirectory() as tmpdir:
            transcript_file = os.path.join(tmpdir, "transcript.jsonl")
            lines = [
                "corrupt json line\n",
                json.dumps({"type": "USER_INPUT", "content": "first user input"}) + "\n",
                json.dumps({"type": "SYSTEM", "content": "system message"}) + "\n",
                json.dumps({"type": "GENERIC", "content": "last generic prompt"}) + "\n",
                json.dumps({"type": "USER_INPUT"}) + "\n"  # missing content
            ]
            with open(transcript_file, "w", encoding="utf-8") as f:
                f.writelines(lines)

            payload = {"transcriptPath": transcript_file}

            with self.assertRaises(SystemExitException):
                ai_guard_wrapper.handle_prompt_route(payload)

            mock_run_guard.assert_called_once_with("prompt", stdin_str=json.dumps({"text": "last generic prompt"}))
            self.assertEqual(json.loads(mock_stdout.getvalue()), {})
            self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_prompt_route_transcript_missing_file_or_invalid_json(self, mock_stdout, mock_run_guard):
        import tempfile
        # Scenario 1: Non-existent file
        payload1 = {"transcriptPath": "/nonexistent/path/transcript.jsonl"}
        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload1)
        self.assertEqual(json.loads(mock_stdout.getvalue()), {})
        self.mock_exit.assert_called_with(0)
        mock_run_guard.assert_not_called()

        # Scenario 2: File with no matching prompt lines
        with tempfile.TemporaryDirectory() as tmpdir:
            transcript_file = os.path.join(tmpdir, "transcript.jsonl")
            with open(transcript_file, "w", encoding="utf-8") as f:
                f.write('{"type": "SYSTEM", "content": "hello"}\ncorrupt json\n')

            payload2 = {"transcriptPath": transcript_file}
            mock_stdout.seek(0)
            mock_stdout.truncate(0)
            with self.assertRaises(SystemExitException):
                ai_guard_wrapper.handle_prompt_route(payload2)

            self.assertEqual(json.loads(mock_stdout.getvalue()), {})
            self.mock_exit.assert_called_with(0)
            mock_run_guard.assert_not_called()

    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_prompt_route_empty_no_transcript(self, mock_stdout):
        payload = {}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_prompt_route_allow(self, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "allow"})
        payload = {"prompt": "What is the capital of France?"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_deny(self, mock_stderr, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (2, {"decision": "deny", "reason": "No way"})
        payload = {"prompt": "Tell me a secret"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {"decision": "deny", "reason": "No way"})
        self.mock_exit.assert_called_with(2)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_replace_sanitized(self, mock_stderr, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "replace", "sanitized": "safe prompt"})
        payload = {"prompt": "my secret is XYZ"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        # The logic expects a proto_resp printed before exit(0)
        self.assertTrue("injectSteps" in json.loads(mock_stdout.getvalue()))
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_transcript_rewrites_file_and_injects_user_message(self, mock_stderr, mock_stdout, mock_run_guard):
        import tempfile
        mock_run_guard.return_value = (
            0,
            {
                "decision": "replace",
                "sanitized": "safe prompt [REDACTED]",
                "reasons": ["API Key Leak"]
            }
        )

        with tempfile.TemporaryDirectory() as tmpdir:
            transcript_file = os.path.join(tmpdir, "transcript.jsonl")
            lines = [
                json.dumps({"type": "SYSTEM", "content": "system prompt"}) + "\n",
                json.dumps({"type": "USER_INPUT", "content": "my secret is secret123"}) + "\n",
            ]
            with open(transcript_file, "w", encoding="utf-8") as f:
                f.writelines(lines)

            payload = {"transcriptPath": transcript_file}

            with self.assertRaises(SystemExitException):
                ai_guard_wrapper.handle_prompt_route(payload)

            self.mock_exit.assert_called_with(0)

            # Check rewritten transcript file content
            with open(transcript_file, "r", encoding="utf-8") as f:
                updated_lines = f.readlines()

            updated_data = json.loads(updated_lines[1])
            self.assertEqual(updated_data["content"], "safe prompt [REDACTED]")
            self.assertEqual(updated_data["type"], "USER_INPUT")

            # Check printed JSON response
            resp = json.loads(mock_stdout.getvalue())
            self.assertIn("injectSteps", resp)
            self.assertEqual(len(resp["injectSteps"]), 2)
            self.assertIn("Security Notice: Redacted sensitive items (API Key Leak)", resp["injectSteps"][0]["ephemeralMessage"])
            self.assertEqual(resp["injectSteps"][1], {"userMessage": "safe prompt [REDACTED]"})

    @patch('builtins.open', side_effect=[
        mock_open(read_data='{"type": "USER_INPUT", "content": "my secret is secret123"}\n')(),
        IOError("Write failed")
    ])
    @patch('os.path.isfile', return_value=True)
    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_transcript_rewrite_write_error_handled(
        self, mock_stderr, mock_stdout, mock_run_guard, mock_isfile, mock_open_file
    ):
        mock_run_guard.return_value = (
            0,
            {
                "decision": "replace",
                "sanitized": "safe prompt",
                "reasons": []
            }
        )
        payload = {"transcriptPath": "/fake/transcript.jsonl"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        self.mock_exit.assert_called_with(0)
        resp = json.loads(mock_stdout.getvalue())
        self.assertIn("injectSteps", resp)

    @patch('subprocess.run')
    def test_run_guard_success_with_json_output(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = '{"decision": "allow"}'
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/file.txt"])
        self.assertEqual(code, 0)
        self.assertEqual(data, {"decision": "allow"})

    @patch('subprocess.run')
    def test_run_guard_success_with_empty_output(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = ''
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/file.txt"])
        self.assertEqual(code, 0)
        self.assertEqual(data, {})

    @patch('subprocess.run')
    def test_run_guard_nonzero_returncode_with_json_output(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 2
        mock_proc.stdout = '{"decision": "deny", "reason": "blocked"}'
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("prompt", args=["--check"])
        self.assertEqual(code, 2)
        self.assertEqual(data, {"decision": "deny", "reason": "blocked"})

    @patch('subprocess.run')
    def test_run_guard_nonzero_returncode_with_non_json_output(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 1
        mock_proc.stdout = 'Fatal error: guard failed'
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("prompt")
        self.assertEqual(code, 1)
        self.assertEqual(data, {})

    @patch('subprocess.run')
    def test_run_guard_whitespace_padded_json(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = '  \n\t {"decision": "allow"} \n\n '
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("command", args=["ls"])
        self.assertEqual(code, 0)
        self.assertEqual(data, {"decision": "allow"})

    @patch('subprocess.run')
    def test_run_guard_arguments_and_stdin_passing(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = '{"decision": "allow"}'
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("prompt", args=["arg1", "arg2"], stdin_str='{"text": "test"}')
        self.assertEqual(code, 0)
        self.assertEqual(data, {"decision": "allow"})
        mock_subprocess.assert_called_once_with(
            [ai_guard_wrapper.AI_GUARD_BIN, "prompt", "arg1", "arg2"],
            input='{"text": "test"}',
            text=True,
            capture_output=True,
            check=False
        )

    @patch('subprocess.run')
    def test_run_guard_truncated_json_output(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = '{"decision": "allow"'
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("file", args=["/test.txt"])
        self.assertEqual(code, 0)
        self.assertEqual(data, {})

    @patch('subprocess.run')
    def test_run_guard_success_with_invalid_json_output(self, mock_subprocess):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = 'not json format'
        mock_subprocess.return_value = mock_proc

        code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/file.txt"])
        self.assertEqual(code, 0)
        self.assertEqual(data, {})

    @patch('subprocess.run', side_effect=Exception("Execution mock failure with /path/to/secret.key sensitive_arg"))
    @patch('sys.stderr', new_callable=StringIO)
    def test_run_guard_exception_does_not_leak_cmd_args(self, mock_stderr, mock_subprocess):
        code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/secret.key", "sensitive_arg"])
        self.assertEqual(code, 2)
        self.assertEqual(data.get("decision"), "deny")
        self.assertEqual(data.get("reason"), "Security guard execution failed (file)")
        stderr_output = mock_stderr.getvalue()
        reason_output = data.get("reason", "")
        self.assertIn("Error invoking security guard (file)", stderr_output)
        self.assertNotIn("/path/to/secret.key", stderr_output)
        self.assertNotIn("sensitive_arg", stderr_output)
        self.assertNotIn("/path/to/secret.key", reason_output)
        self.assertNotIn("sensitive_arg", reason_output)

    @patch('builtins.open', new_callable=mock_open)
    @patch('subprocess.run', side_effect=Exception("Execution mock failure with sensitive detail"))
    @patch('sys.stderr', new_callable=StringIO)
    def test_run_guard_debug_logging_exception_handling(self, mock_stderr, mock_subprocess, m_open):
        m_open.side_effect = Exception("Failed to open debug log")
        with patch.dict(os.environ, {"AI_GUARD_DEBUG": "1"}, clear=True):
            code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/secret.key"])
            self.assertEqual(code, 2)
            self.assertEqual(data.get("decision"), "deny")

    @patch('builtins.open', new_callable=mock_open)
    @patch('subprocess.run', side_effect=Exception("Execution mock failure with sensitive detail"))
    @patch('sys.stderr', new_callable=StringIO)
    def test_run_guard_debug_logging_prevented_when_unset(self, mock_stderr, mock_subprocess, m_open):
        with patch.dict(os.environ, {}, clear=True):
            code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/secret.key"])
            self.assertEqual(code, 2)
            m_open.assert_not_called()

    @patch('builtins.open', new_callable=mock_open)
    @patch('subprocess.run', side_effect=Exception("Execution mock failure with sensitive detail"))
    @patch('sys.stderr', new_callable=StringIO)
    def test_run_guard_debug_logging_when_enabled(self, mock_stderr, mock_subprocess, m_open):
        with patch.dict(os.environ, {"AI_GUARD_DEBUG": "1"}, clear=True):
            code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/secret.key"])
            self.assertEqual(code, 2)
            m_open.assert_called_once_with(os.path.expanduser("~/.local/state/ai-guard-wrapper.log"), "a")
            handle = m_open()
            written = "".join(call.args[0] for call in handle.write.call_args_list)
            self.assertIn("GUARD FAILURE subcmd=file", written)
            self.assertIn("Execution mock failure with sensitive detail", written)

    @patch('builtins.open', new_callable=mock_open)
    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_debug_logging_prevented_when_unset(self, mock_stderr, mock_stdout, mock_run_guard, m_open):
        mock_run_guard.return_value = (0, {"decision": "replace", "sanitized": "sensitive_data_12345"})
        payload = {"prompt": "my secret is sensitive_data_12345"}

        with patch.dict(os.environ, {}, clear=True):
            with self.assertRaises(SystemExitException):
                ai_guard_wrapper.handle_prompt_route(payload)

        m_open.assert_not_called()

    @patch('builtins.open', new_callable=mock_open)
    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_debug_logging_when_enabled(self, mock_stderr, mock_stdout, mock_run_guard, m_open):
        mock_run_guard.return_value = (0, {"decision": "replace", "sanitized": "sensitive_data_12345"})
        payload = {"prompt": "my secret is sensitive_data_12345"}

        with patch.dict(os.environ, {"AI_GUARD_DEBUG": "1"}, clear=True):
            with self.assertRaises(SystemExitException):
                ai_guard_wrapper.handle_prompt_route(payload)

        m_open.assert_called_once_with(os.path.expanduser("~/.local/state/ai-guard-wrapper.log"), "a")
        handle = m_open()
        written_content = "".join(call.args[0] for call in handle.write.call_args_list)
        self.assertIn("PROMPT SANITIZED", written_content)
        self.assertNotIn("sensitive_data_12345", written_content)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_prompt_route_uses_text_field(self, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "allow"})
        payload = {"text": "prompt via text key"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        mock_run_guard.assert_called_once_with("prompt", stdin_str=json.dumps({"text": "prompt via text key"}))
        self.assertEqual(json.loads(mock_stdout.getvalue()), {})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_deny_default_reason(self, mock_stderr, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "deny"})
        payload = {"prompt": "blocked prompt"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        self.assertEqual(
            json.loads(mock_stdout.getvalue()),
            {"decision": "deny", "reason": "Content blocked by security guard"}
        )
        self.assertIn("SECURITY GUARD: Content blocked by security guard", mock_stderr.getvalue())
        self.mock_exit.assert_called_with(2)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    def test_handle_prompt_route_replace_identical_sanitized_does_not_inject(self, mock_stdout, mock_run_guard):
        mock_run_guard.return_value = (0, {"decision": "replace", "sanitized": "identical text"})
        payload = {"prompt": "identical text"}

        with self.assertRaises(SystemExitException):
            ai_guard_wrapper.handle_prompt_route(payload)

        self.assertEqual(json.loads(mock_stdout.getvalue()), {})
        self.mock_exit.assert_called_with(0)

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_transcript_generic_type_omits_user_message(self, mock_stderr, mock_stdout, mock_run_guard):
        import tempfile
        mock_run_guard.return_value = (
            0,
            {
                "decision": "replace",
                "sanitized": "generic prompt sanitized",
                "reasons": ["Secret Leak"]
            }
        )

        with tempfile.TemporaryDirectory() as tmpdir:
            transcript_file = os.path.join(tmpdir, "transcript.jsonl")
            lines = [
                json.dumps({"type": "GENERIC", "content": "generic prompt secret"}) + "\n"
            ]
            with open(transcript_file, "w", encoding="utf-8") as f:
                f.writelines(lines)

            payload = {"transcriptPath": transcript_file}

            with self.assertRaises(SystemExitException):
                ai_guard_wrapper.handle_prompt_route(payload)

            self.mock_exit.assert_called_with(0)
            resp = json.loads(mock_stdout.getvalue())
            self.assertIn("injectSteps", resp)
            self.assertEqual(len(resp["injectSteps"]), 1)
            self.assertIn("Security Notice: Redacted sensitive items (Secret Leak)", resp["injectSteps"][0]["ephemeralMessage"])

    @patch('ai_guard_wrapper.run_guard')
    @patch('sys.stdout', new_callable=StringIO)
    @patch('sys.stderr', new_callable=StringIO)
    def test_handle_prompt_route_transcript_corrupted_line_during_stype_check(self, mock_stderr, mock_stdout, mock_run_guard):
        import tempfile
        mock_run_guard.return_value = (
            0,
            {
                "decision": "replace",
                "sanitized": "safe content",
                "reasons": []
            }
        )

        with tempfile.TemporaryDirectory() as tmpdir:
            transcript_file = os.path.join(tmpdir, "transcript.jsonl")
            lines = [
                json.dumps({"type": "USER_INPUT", "content": "user secret"}) + "\n"
            ]
            with open(transcript_file, "w", encoding="utf-8") as f:
                f.writelines(lines)

            payload = {"transcriptPath": transcript_file}

            # Mock builtins.open so readlines works, but subsequent read in stype check receives corrupt line
            original_open = open
            def custom_open(path, mode='r', *args, **kwargs):
                if mode == 'w':
                    # Corrupt line in place when written
                    f = original_open(path, mode, *args, **kwargs)
                    f.write("corrupt json line\n")
                    f.close()
                    return original_open(os.devnull, 'w')
                return original_open(path, mode, *args, **kwargs)

            with patch('builtins.open', side_effect=custom_open):
                with self.assertRaises(SystemExitException):
                    ai_guard_wrapper.handle_prompt_route(payload)

            self.mock_exit.assert_called_with(0)
            resp = json.loads(mock_stdout.getvalue())
            self.assertIn("injectSteps", resp)


if __name__ == '__main__':
    unittest.main()
