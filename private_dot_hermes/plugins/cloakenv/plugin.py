import os
import sys
import json
import hashlib
import subprocess

try:
    from hermes.plugins.secrets import SecretSource, FetchResult, FetchStatus
except ImportError:
    if "PYTEST_CURRENT_TEST" in os.environ or "TESTING_CLOAKENV" in os.environ:
        class FetchStatus:
            SUCCESS = "SUCCESS"
            AUTH_ERROR = "AUTH_ERROR"
            ERROR = "ERROR"
            EMPTY_VALUE = "EMPTY_VALUE"

        class FetchResult:
            def __init__(self, status, secrets=None, error=None):
                self.status = status
                self.secrets = secrets or {}
                self.error = error

        class SecretSource:
            def __init__(self, config=None):
                self.config = config or {}
    else:
        print("Warning: could not import hermes dependencies. This module must be run within Hermes.", file=sys.stderr)
        raise

class CloakEnvSecretSource(SecretSource):
    def __init__(self, config=None):
        super().__init__(config)
        self.path = self.config.get("path", "")
        self.namespace = self.config.get("namespace", "default")
        self.token = self.config.get("token", "")
        self.mappings = self.config.get("mappings", {})

    def get_cache_key(self):
        sorted_mappings = sorted(self.mappings.items())
        token_hash = hashlib.sha256(self.token.encode()).hexdigest()[:8]
        return f"{self.path}:{self.namespace}:{sorted_mappings}:{token_hash}"

    def fetch(self):
        if not self.path or not self.token:
            return FetchResult(status=FetchStatus.ERROR, error="Missing path or token")

        env = {**os.environ, "CLOAK_TOKEN": self.token}
        try:
            cmd = ["cloakenv", "read", "--namespace", self.namespace, self.path, "--format", "json"]
            result = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=30)

            if result.returncode != 0:
                stderr_lower = result.stderr.lower()
                is_auth_error = (
                    "unauthorized" in stderr_lower or
                    "auth" in stderr_lower
                )
                if is_auth_error:
                    return FetchResult(status=FetchStatus.AUTH_ERROR, error=result.stderr)
                return FetchResult(status=FetchStatus.ERROR, error=result.stderr)

            raw_data = result.stdout.strip()
            if not raw_data:
                return FetchResult(status=FetchStatus.EMPTY_VALUE, error="Vault is empty")

            try:
                parsed_data = json.loads(raw_data)
            except json.JSONDecodeError as e:
                return FetchResult(status=FetchStatus.ERROR, error=f"Invalid JSON: {e}")

            if not isinstance(parsed_data, dict):
                return FetchResult(status=FetchStatus.ERROR, error="Expected JSON object from cloakenv")

            if not parsed_data:
                return FetchResult(status=FetchStatus.EMPTY_VALUE, error="Vault is empty")

            fetched_secrets = {}
            if self.mappings:
                for target_key, source_key in self.mappings.items():
                    if source_key in parsed_data:
                        fetched_secrets[target_key] = parsed_data[source_key]
                if not fetched_secrets:
                    return FetchResult(status=FetchStatus.SUCCESS, secrets={})
            else:
                fetched_secrets = parsed_data

            return FetchResult(status=FetchStatus.SUCCESS, secrets=fetched_secrets)
        except (FileNotFoundError, OSError, subprocess.TimeoutExpired) as e:
            return FetchResult(status=FetchStatus.ERROR, error=f"Failed to execute cloakenv: {e}")
