import unittest
import sys
import os
import io
import json
from unittest.mock import MagicMock, patch

# Add parent directory to sys.path to find the jira package
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from jira.commands.generic import cmd_call

class DummyArgs:
    def __init__(self, method, endpoint, payload=None):
        self.method = method
        self.endpoint = endpoint
        self.payload = payload

class TestGenericCommand(unittest.TestCase):
    def setUp(self):
        self.client = MagicMock()

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_call_get_without_payload(self, mock_stdout):
        mock_response = {"id": "10000", "key": "TEST-1"}
        self.client.call.return_value = mock_response

        args = DummyArgs(method="GET", endpoint="rest/api/3/issue/TEST-1", payload=None)
        cmd_call(self.client, args)

        self.client.call.assert_called_once_with("GET", "rest/api/3/issue/TEST-1", payload=None)
        output = json.loads(mock_stdout.getvalue().strip())
        self.assertEqual(output, mock_response)

    @patch('sys.stdout', new_callable=io.StringIO)
    def test_cmd_call_post_with_payload(self, mock_stdout):
        mock_response = {"id": "10001", "key": "TEST-2"}
        self.client.call.return_value = mock_response

        payload_str = '{"fields": {"summary": "New Issue"}}'
        args = DummyArgs(method="POST", endpoint="rest/api/3/issue", payload=payload_str)
        cmd_call(self.client, args)

        self.client.call.assert_called_once_with(
            "POST", "rest/api/3/issue", payload={"fields": {"summary": "New Issue"}}
        )
        output = json.loads(mock_stdout.getvalue().strip())
        self.assertEqual(output, mock_response)

    def test_cmd_call_invalid_json_payload(self):
        args = DummyArgs(method="POST", endpoint="rest/api/3/issue", payload="{invalid json}")
        with self.assertRaises(json.JSONDecodeError):
            cmd_call(self.client, args)
        self.client.call.assert_not_called()

if __name__ == "__main__":
    unittest.main()
