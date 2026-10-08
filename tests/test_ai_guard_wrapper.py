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

    @patch('subprocess.run', side_effect=Exception("Execution mock failure"))
    @patch('sys.stderr', new_callable=StringIO)
    def test_run_guard_exception_does_not_leak_cmd_args(self, mock_stderr, mock_subprocess):
        code, data = ai_guard_wrapper.run_guard("file", args=["/path/to/secret.key", "sensitive_arg"])
        self.assertEqual(code, 2)
        self.assertEqual(data.get("decision"), "deny")
        stderr_output = mock_stderr.getvalue()
        self.assertIn("Error invoking security guard (file)", stderr_output)
        self.assertNotIn("/path/to/secret.key", stderr_output)
        self.assertNotIn("sensitive_arg", stderr_output)

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

        m_open.assert_called_once_with("/tmp/ai-guard-wrapper.log", "a")
        handle = m_open()
        written_content = "".join(call.args[0] for call in handle.write.call_args_list)
        self.assertIn("PROMPT SANITIZED", written_content)
        self.assertNotIn("sensitive_data_12345", written_content)


if __name__ == '__main__':
    unittest.main()
