"""
Unit tests for CloakEnv SecretSource plugin.
"""

import os
import json
import unittest
from unittest.mock import patch, MagicMock
from pathlib import Path

from private_dot_hermes.plugins.cloakenv import (
    CloakEnvSource,
    ErrorKind,
    FetchResult,
    register,
)


class TestCloakEnvSource(unittest.TestCase):

    def setUp(self):
        self.source = CloakEnvSource()
        self.home_path = Path("/home/testuser")

    def test_protected_env_vars(self):
        protected = self.source.protected_env_vars({})
        self.assertIn("CLOAK_TOKEN", protected)
        self.assertIn("CLOAK_SECRET_KEY", protected)

    def test_is_enabled(self):
        self.assertFalse(self.source.is_enabled({}))
        self.assertFalse(self.source.is_enabled({"enabled": False}))
        self.assertTrue(self.source.is_enabled({"enabled": True}))

    def test_teardown(self):
        self.source._cache["test:key"] = (100.0, {"A": "B"})
        self.source.teardown()
        self.assertEqual(len(self.source._cache), 0)

    def test_fetch_missing_token(self):
        with patch.dict(os.environ, {}, clear=True):
            cfg = {"enabled": True, "path": "/services/my-service"}
            res = self.source.fetch(cfg, self.home_path)
            self.assertEqual(res.error_kind, ErrorKind.NOT_CONFIGURED)
            self.assertIn("CLOAK_TOKEN", res.error)

    @patch("private_dot_hermes.plugins.cloakenv.run_secret_cli")
    def test_fetch_success_bulk(self, mock_run_cli):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = json.dumps({"DATABASE_URL": "postgres://user:pass@localhost/db", "API_KEY": "secret123"})
        mock_run_cli.return_value = mock_proc

        cfg = {
            "enabled": True,
            "path": "/services/my-service",
            "namespace": "prod",
            "token": "test-token-123",
            "cache_ttl_seconds": 0,
        }
        res = self.source.fetch(cfg, self.home_path)

        self.assertIsNone(res.error)
        self.assertEqual(res.secrets["DATABASE_URL"], "postgres://user:pass@localhost/db")
        self.assertEqual(res.secrets["API_KEY"], "secret123")
        mock_run_cli.assert_called_once_with(
            ["cloakenv", "export", "--json", "--path", "/services/my-service", "--namespace", "prod"],
            allow_env=["CLOAK_TOKEN", "CLOAK_SECRET_KEY", "PATH", "HOME"],
            timeout=120,
        )

    @patch("private_dot_hermes.plugins.cloakenv.run_secret_cli")
    def test_fetch_success_mapped(self, mock_run_cli):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = json.dumps({"db_pass": "secretpass", "api_token": "token456", "other": "ignored"})
        mock_run_cli.return_value = mock_proc

        cfg = {
            "enabled": True,
            "path": "/services/my-service",
            "token": "test-token",
            "cache_ttl_seconds": 0,
            "mappings": {
                "DB_PASSWORD": "db_pass",
                "MY_API_TOKEN": "api_token",
            },
        }
        res = self.source.fetch(cfg, self.home_path)

        self.assertIsNone(res.error)
        self.assertEqual(res.secrets["DB_PASSWORD"], "secretpass")
        self.assertEqual(res.secrets["MY_API_TOKEN"], "token456")
        self.assertNotIn("other", res.secrets)

    @patch("private_dot_hermes.plugins.cloakenv.run_secret_cli")
    def test_fetch_cli_missing(self, mock_run_cli):
        mock_run_cli.side_effect = RuntimeError("Executable not found: cloakenv")

        cfg = {"enabled": True, "token": "test-token", "cache_ttl_seconds": 0}
        res = self.source.fetch(cfg, self.home_path)

        self.assertEqual(res.error_kind, ErrorKind.BINARY_MISSING)
        self.assertIn("Executable not found", res.error)

    @patch("private_dot_hermes.plugins.cloakenv.run_secret_cli")
    def test_fetch_timeout(self, mock_run_cli):
        mock_run_cli.side_effect = RuntimeError("Command timed out after 30s: cloakenv export")

        cfg = {"enabled": True, "token": "test-token", "cache_ttl_seconds": 0}
        res = self.source.fetch(cfg, self.home_path)

        self.assertEqual(res.error_kind, ErrorKind.TIMEOUT)
        self.assertIn("timed out", res.error)

    @patch("private_dot_hermes.plugins.cloakenv.run_secret_cli")
    def test_fetch_auth_failed(self, mock_run_cli):
        mock_proc = MagicMock()
        mock_proc.returncode = 1
        mock_proc.stderr = "Error: Unauthorized - invalid CLOAK_TOKEN"
        mock_run_cli.return_value = mock_proc

        cfg = {"enabled": True, "token": "invalid-token", "cache_ttl_seconds": 0}
        res = self.source.fetch(cfg, self.home_path)

        self.assertEqual(res.error_kind, ErrorKind.AUTH_FAILED)
        self.assertIn("Unauthorized", res.error)

    @patch("private_dot_hermes.plugins.cloakenv.run_secret_cli")
    def test_caching_behavior(self, mock_run_cli):
        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.stdout = json.dumps({"FOO": "BAR"})
        mock_run_cli.return_value = mock_proc

        cfg = {
            "enabled": True,
            "path": "/cached-path",
            "token": "token",
            "cache_ttl_seconds": 300,
        }

        # First fetch
        res1 = self.source.fetch(cfg, self.home_path)
        self.assertEqual(res1.secrets, {"FOO": "BAR"})

        # Second fetch should hit cache without calling run_secret_cli again
        res2 = self.source.fetch(cfg, self.home_path)
        self.assertEqual(res2.secrets, {"FOO": "BAR"})

        mock_run_cli.assert_called_once()

    def test_register(self):
        ctx = MagicMock()
        register(ctx)
        ctx.register_secret_source.assert_called_once()


if __name__ == "__main__":
    unittest.main()
