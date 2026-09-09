import sys
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock

# Add scripts directory to sys.path
scripts_dir = Path(__file__).resolve().parent.parent
if str(scripts_dir) not in sys.path:
    sys.path.insert(0, str(scripts_dir))

from jules.utils import die, err, info, format_datetime

class TestJulesUtils(unittest.TestCase):
    def test_format_datetime_valid(self):
        # Test basic valid ISO 8601 string
        self.assertEqual(
            format_datetime("2023-10-25T12:34:56"),
            "2023-10-25 12:34:56 UTC"
        )

        # Test valid ISO 8601 string with 'Z'
        self.assertEqual(
            format_datetime("2023-10-25T12:34:56Z"),
            "2023-10-25 12:34:56 UTC"
        )

    def test_format_datetime_none_or_empty(self):
        # Test None
        self.assertEqual(format_datetime(None), "N/A")

        # Test empty string
        self.assertEqual(format_datetime(""), "N/A")

    def test_format_datetime_invalid(self):
        # Test invalid string, should return the original string
        invalid_str = "not-a-datetime"
        self.assertEqual(format_datetime(invalid_str), invalid_str)

    @patch('sys.exit')
    @patch('sys.stderr.write')
    def test_die(self, mock_stderr_write, mock_exit):
        die("Fatal error occurred", 42)
        mock_stderr_write.assert_called_once_with("Error: Fatal error occurred\n")
        mock_exit.assert_called_once_with(42)

    @patch('sys.exit')
    @patch('sys.stderr.write')
    def test_die_default_exit_code(self, mock_stderr_write, mock_exit):
        die("Another error")
        mock_stderr_write.assert_called_once_with("Error: Another error\n")
        mock_exit.assert_called_once_with(1)

    @patch('sys.stderr.write')
    def test_err(self, mock_stderr_write):
        err("Diagnostic message")
        mock_stderr_write.assert_called_once_with("Diagnostic message\n")

    @patch('sys.stderr.write')
    def test_info_verbose(self, mock_stderr_write):
        info("Verbose information", verbose=True)
        mock_stderr_write.assert_called_once_with("[jules] Verbose information\n")

    @patch('sys.stderr.write')
    def test_info_not_verbose(self, mock_stderr_write):
        info("Quiet information", verbose=False)
        mock_stderr_write.assert_not_called()

if __name__ == "__main__":
    unittest.main()
