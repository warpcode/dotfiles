import unittest
from unittest.mock import patch, MagicMock
import json
import sys
import importlib.util
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SERVER_PATH = REPO_ROOT / "dot_gemini" / "config" / "sidecars" / "openai-bridge" / "server.py"
spec = importlib.util.spec_from_file_location("openai_bridge_server", str(SERVER_PATH))
openai_bridge_server = importlib.util.module_from_spec(spec)
spec.loader.exec_module(openai_bridge_server)


class TestOpenAIBridgeServer(unittest.TestCase):

    def setUp(self):
        self.handler = openai_bridge_server.OpenAIBridgeHandler.__new__(openai_bridge_server.OpenAIBridgeHandler)
        self.handler.send_json = MagicMock()
        self.handler.send_error_response = MagicMock()

    def tearDown(self):
        with openai_bridge_server.cache_lock:
            openai_bridge_server.history_to_conv_id.clear()

    def test_allowed_models_frozenset_exactness(self):
        self.assertEqual(openai_bridge_server.ALLOWED_MODELS, frozenset({"flash_lite", "flash", "pro"}))
        with self.assertRaises(AttributeError):
            openai_bridge_server.ALLOWED_MODELS.add("gpt-4")

    def test_parse_agentapi_output_json_response(self):
        raw_output = '{"response": {"content": "Hello from agent", "conversation_id": "conv-123"}}'
        conv_id, content = self.handler.parse_agentapi_output(raw_output)
        self.assertEqual(conv_id, "conv-123")
        self.assertEqual(content, "Hello from agent")

    def test_parse_agentapi_output_raw_text_fallback(self):
        raw_output = "Plain text output without JSON"
        conv_id, content = self.handler.parse_agentapi_output(raw_output)
        self.assertIsNone(conv_id)
        self.assertEqual(content, "Plain text output without JSON")

    @patch("subprocess.run")
    def test_process_completions_model_inputs(self, mock_subprocess_run):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = json.dumps({"response": {"content": "Test response", "conversation_id": "conv-456"}})
        mock_proc.stderr = ""
        mock_subprocess_run.return_value = mock_proc

        messages = [{"role": "user", "content": "Hello"}]

        # Valid model pass-through checks
        for valid_model in ("flash_lite", "flash", "pro"):
            with self.subTest(model=valid_model):
                mock_subprocess_run.reset_mock()
                self.handler.process_completions(messages, model=valid_model, is_chat=True)
                cmd_args = mock_subprocess_run.call_args[0][0]
                self.assertIn(f"--model={valid_model}", cmd_args)

        # Non-string / invalid model fallback checks
        invalid_inputs = [
            ["flash"], {}, None, 123, True, False, "", "FLASH", " flash", "flash ",
            "../../etc/passwd", "flash;rm -rf /", "gpt-4", "A" * 1000
        ]
        for invalid_model in invalid_inputs:
            with self.subTest(model=invalid_model):
                mock_subprocess_run.reset_mock()
                self.handler.process_completions(messages, model=invalid_model, is_chat=True)
                cmd_args = mock_subprocess_run.call_args[0][0]
                self.assertIn("--model=flash_lite", cmd_args)


if __name__ == "__main__":
    unittest.main()
