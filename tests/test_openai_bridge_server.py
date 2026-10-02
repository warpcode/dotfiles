import unittest
from unittest.mock import patch, MagicMock
import json
import sys
import importlib.util
from pathlib import Path

# Load server.py module dynamically
REPO_ROOT = Path(__file__).resolve().parent.parent
SERVER_PATH = REPO_ROOT / "dot_gemini" / "config" / "sidecars" / "openai-bridge" / "server.py"
spec = importlib.util.spec_from_file_location("openai_bridge_server", str(SERVER_PATH))
openai_bridge_server = importlib.util.module_from_spec(spec)
sys.modules["openai_bridge_server"] = openai_bridge_server
spec.loader.exec_module(openai_bridge_server)


class TestOpenAIBridgeServer(unittest.TestCase):

    def setUp(self):
        self.handler = openai_bridge_server.OpenAIBridgeHandler.__new__(openai_bridge_server.OpenAIBridgeHandler)
        self.handler.send_json = MagicMock()
        self.handler.send_error_response = MagicMock()

    def test_allowed_models_set(self):
        self.assertIn("flash_lite", openai_bridge_server.ALLOWED_MODELS)
        self.assertIn("flash", openai_bridge_server.ALLOWED_MODELS)
        self.assertIn("pro", openai_bridge_server.ALLOWED_MODELS)
        self.assertNotIn("unknown_model", openai_bridge_server.ALLOWED_MODELS)

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
    def test_process_completions_fallback_model(self, mock_subprocess_run):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = json.dumps({"response": {"content": "Test response", "conversation_id": "conv-456"}})
        mock_proc.stderr = ""
        mock_subprocess_run.return_value = mock_proc

        messages = [{"role": "user", "content": "Hello"}]
        self.handler.process_completions(messages, model="invalid_model", is_chat=True)

        mock_subprocess_run.assert_called_once()
        cmd_args = mock_subprocess_run.call_args[0][0]
        # Should fallback to flash_lite
        self.assertIn("--model=flash_lite", cmd_args)
        self.handler.send_json.assert_called_once()
        status_code, resp_data = self.handler.send_json.call_args[0]
        self.assertEqual(status_code, 200)
        self.assertEqual(resp_data["choices"][0]["message"]["content"], "Test response")


if __name__ == "__main__":
    unittest.main()
