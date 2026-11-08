import unittest
from unittest.mock import patch
import sys
import importlib.util

spec = importlib.util.spec_from_file_location("extract_git_history", ".github/skills/changelog-authoring/scripts/extract-git-history.py")
extract_git_history = importlib.util.module_from_spec(spec)
sys.modules["extract_git_history"] = extract_git_history
spec.loader.exec_module(extract_git_history)

class TestExtractGitHistory(unittest.TestCase):
    @patch("extract_git_history.run_git_cmd")
    def test_get_first_commit_empty_repo(self, mock_run):
        mock_run.return_value = ""
        # The splitlines()[0] will raise IndexError if repo is empty (no commits)
        with self.assertRaises(IndexError):
            extract_git_history.get_first_commit()

if __name__ == "__main__":
    unittest.main()
