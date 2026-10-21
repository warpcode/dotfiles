import os
import sys
import unittest
from unittest.mock import patch, MagicMock

# Setting flag to load the mock class
os.environ["TESTING_CLOAKENV"] = "1"

# Importing the plugin class from the module
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, parent_dir)

from plugin import CloakEnvSecretSource, FetchStatus

class TestCloakEnvSecretSource(unittest.TestCase):
    def setUp(self):
        self.config_base = {
            "path": "path/to/secret",
            "namespace": "my-ns",
            "token": "secret_token_value",
        }

    def test_cache_key_uniqueness_different_mappings(self):
        plugin1 = CloakEnvSecretSource({**self.config_base, "mappings": {"A": "B"}})
        plugin2 = CloakEnvSecretSource({**self.config_base, "mappings": {"B": "A"}})
        self.assertNotEqual(plugin1.get_cache_key(), plugin2.get_cache_key())

    def test_cache_key_uniqueness_different_tokens(self):
        plugin1 = CloakEnvSecretSource({**self.config_base, "token": "token1"})
        plugin2 = CloakEnvSecretSource({**self.config_base, "token": "token2"})
        self.assertNotEqual(plugin1.get_cache_key(), plugin2.get_cache_key())

    def test_cache_key_same_mappings_same_tokens(self):
        plugin1 = CloakEnvSecretSource({**self.config_base, "mappings": {"A": "B"}})
        plugin2 = CloakEnvSecretSource({**self.config_base, "mappings": {"A": "B"}})
        self.assertEqual(plugin1.get_cache_key(), plugin2.get_cache_key())

    @patch("plugin.subprocess.run")
    def test_empty_vault_handling_empty_stdout(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout="")
        plugin = CloakEnvSecretSource(self.config_base)
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.EMPTY_VALUE)
        self.assertEqual(result.error, "Vault is empty")

    @patch("plugin.subprocess.run")
    def test_empty_vault_handling_empty_json(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout="{}")
        plugin = CloakEnvSecretSource(self.config_base)
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.EMPTY_VALUE)
        self.assertEqual(result.error, "Vault is empty")

    @patch("plugin.subprocess.run")
    def test_empty_vault_handling_no_match(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout='{"C": "D"}')
        plugin = CloakEnvSecretSource({**self.config_base, "mappings": {"A": "B"}})
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.SUCCESS)
        self.assertEqual(result.secrets, {})


    @patch("plugin.subprocess.run")
    def test_error_classification_auth_error_message(self, mock_run):
        mock_run.return_value = MagicMock(returncode=1, stderr="Some authentication failed unauthorized error")
        plugin = CloakEnvSecretSource(self.config_base)
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.AUTH_ERROR)
        self.assertEqual(result.error, "Some authentication failed unauthorized error")

    @patch("plugin.subprocess.run")
    def test_error_classification_general_error(self, mock_run):
        mock_run.return_value = MagicMock(returncode=1, stderr="General Error")
        plugin = CloakEnvSecretSource(self.config_base)
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.ERROR)
        self.assertEqual(result.error, "General Error")

    @patch("plugin.subprocess.run")
    def test_success(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout='{"A": "B", "C": "D"}')
        plugin = CloakEnvSecretSource({**self.config_base, "mappings": {"X": "A"}})
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.SUCCESS)
        self.assertEqual(result.secrets, {"X": "B"})

    @patch("plugin.subprocess.run")
    def test_execution_error_handling(self, mock_run):
        mock_run.side_effect = FileNotFoundError("Executable not found")
        plugin = CloakEnvSecretSource(self.config_base)
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.ERROR)
        self.assertIn("Failed to execute cloakenv: Executable not found", result.error)

    @patch("plugin.subprocess.run")
    def test_non_dict_json_handling(self, mock_run):
        mock_run.return_value = MagicMock(returncode=0, stdout='["A", "B"]')
        plugin = CloakEnvSecretSource(self.config_base)
        result = plugin.fetch()
        self.assertEqual(result.status, FetchStatus.ERROR)
        self.assertEqual(result.error, "Expected JSON object from cloakenv")

if __name__ == '__main__':
    unittest.main()
