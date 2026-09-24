import json
import sys
import unittest
from unittest.mock import patch, MagicMock
from io import StringIO
import importlib.util

# Load the module dynamically due to dashes in name
spec = importlib.util.spec_from_file_location("ai_guard_wrapper", "dot_gemini/config/executable_ai-guard-wrapper.py")
ai_guard_wrapper = importlib.util.module_from_spec(spec)
sys.modules["ai_guard_wrapper"] = ai_guard_wrapper
spec.loader.exec_module(ai_guard_wrapper)


class SystemExitException(Exception):
    pass


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
                with patch('ai_guard_wrapper.handle_prompt_route', side_effect=SystemExitException):
                    with self.assertRaises(SystemExitException):
                        ai_guard_wrapper.main()


    @patch('sys.stdout', new_callable=StringIO)
    def test_malformed_json(self, mock_stdout):
        with patch('sys.argv', ['ai-guard-wrapper.py']):
            with patch('sys.stdin', StringIO('not json')):
                with patch('ai_guard_wrapper.handle_prompt_route', side_effect=SystemExitException):
                    with self.assertRaises(SystemExitException):
                        ai_guard_wrapper.main()


if __name__ == '__main__':
    unittest.main()
