"""
CloakEnv Secret Source Plugin for Hermes Agent.

Delegates secret retrieval to @warpcode/cloakenv.
"""

import os
import time
import json
from pathlib import Path
from typing import Dict, Any, Optional, Set, Tuple

try:
    from agent.secret_sources.base import (
        ErrorKind,
        FetchResult,
        SecretSource,
        run_secret_cli,
    )
except ImportError:
    # Fallback / Mock definitions for standalone testing outside full Hermes environment
    from enum import Enum

    class ErrorKind(Enum):
        NOT_CONFIGURED = "NOT_CONFIGURED"
        BINARY_MISSING = "BINARY_MISSING"
        AUTH_FAILED = "AUTH_FAILED"
        AUTH_EXPIRED = "AUTH_EXPIRED"
        REF_INVALID = "REF_INVALID"
        NETWORK = "NETWORK"
        EMPTY_VALUE = "EMPTY_VALUE"
        TIMEOUT = "TIMEOUT"
        INTERNAL = "INTERNAL"

    class FetchResult:
        def __init__(self):
            self.secrets: Dict[str, str] = {}
            self.error: Optional[str] = None
            self.error_kind: Optional[ErrorKind] = None

    class SecretSource:
        name: str = ""
        label: str = ""
        shape: str = "mapped"
        scheme: str = ""
        api_version: int = 1

        def is_enabled(self, cfg: dict) -> bool:
            return cfg.get("enabled", False)

        def override_existing(self, cfg: dict) -> bool:
            return cfg.get("override_existing", False)

        def protected_env_vars(self, cfg: dict):
            return frozenset()

        def fetch_timeout_seconds(self, cfg: dict) -> int:
            return cfg.get("timeout_seconds", 120)

        def config_schema(self) -> dict:
            return {}

        def remediation(self, kind: ErrorKind, cfg: dict) -> str:
            return ""

    def run_secret_cli(cmd: list, allow_env: Optional[list] = None, timeout: int = 30):
        import subprocess
        env = {k: os.environ[k] for k in (allow_env or []) if k in os.environ}
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env,
                stdin=subprocess.DEVNULL,
            )
            return proc
        except FileNotFoundError:
            raise RuntimeError(f"Executable not found: {cmd[0]}")
        except subprocess.TimeoutExpired:
            raise RuntimeError(f"Command timed out after {timeout}s: {' '.join(cmd)}")


class CloakEnvSource(SecretSource):
    """
    Hermes SecretSource plugin integrating @warpcode/cloakenv.
    """
    name = "cloakenv"
    label = "CloakEnv"
    shape = "mapped"
    scheme = "cloakenv"

    def __init__(self):
        super().__init__()
        self._cache: Dict[str, Tuple[float, Dict[str, str]]] = {}

    def protected_env_vars(self, cfg: dict) -> frozenset:
        """
        Bootstrap tokens for CloakEnv that must never be overwritten.
        """
        return frozenset({"CLOAK_TOKEN", "CLOAK_SECRET_KEY"})

    def is_enabled(self, cfg: dict) -> bool:
        return cfg.get("enabled", False)

    def config_schema(self) -> dict:
        return {
            "type": "object",
            "properties": {
                "enabled": {"type": "boolean", "default": False},
                "path": {"type": "string", "description": "Vault or secret path in CloakEnv"},
                "namespace": {"type": "string", "description": "CloakEnv environment namespace"},
                "token": {"type": "string", "description": "CloakEnv auth token (or set CLOAK_TOKEN env var)"},
                "cache_ttl_seconds": {"type": "integer", "default": 300},
                "cli_path": {"type": "string", "default": "cloakenv"},
                "mappings": {
                    "type": "object",
                    "additionalProperties": {"type": "string"},
                    "description": "Map of ENV_VAR -> cloakenv secret key or reference"
                }
            }
        }

    def remediation(self, kind: ErrorKind, cfg: dict) -> str:
        if kind == ErrorKind.NOT_CONFIGURED:
            return "Set secrets.cloakenv.path and ensure CLOAK_TOKEN (or secrets.cloakenv.token) is configured."
        elif kind == ErrorKind.BINARY_MISSING:
            return "Install cloakenv CLI and ensure it is in PATH or specify secrets.cloakenv.cli_path."
        elif kind in (ErrorKind.AUTH_FAILED, ErrorKind.AUTH_EXPIRED):
            return "Check your CLOAK_TOKEN or CloakEnv authentication credentials."
        return ""

    def fetch(self, cfg: dict, home_path: Path) -> FetchResult:
        """
        Fetch secrets from CloakEnv. MUST NOT raise. MUST NOT prompt.
        """
        result = FetchResult()

        try:
            path = cfg.get("path", "").strip()
            namespace = cfg.get("namespace", "").strip()
            token = cfg.get("token", "").strip() or os.environ.get("CLOAK_TOKEN", "").strip()
            cli_path = cfg.get("cli_path", "cloakenv").strip()
            cache_ttl = int(cfg.get("cache_ttl_seconds", 300))
            mappings = cfg.get("mappings", {})

            if not token:
                result.error = "secrets.cloakenv.enabled is true but CLOAK_TOKEN / secrets.cloakenv.token is not set."
                result.error_kind = ErrorKind.NOT_CONFIGURED
                return result

            # Cache key check
            cache_key = f"{path}:{namespace}"
            now = time.time()
            if cache_key in self._cache and cache_ttl > 0:
                cached_time, cached_secrets = self._cache[cache_key]
                if now - cached_time < cache_ttl:
                    result.secrets = cached_secrets
                    return result

            # Construct command
            # cloakenv export --json --path <path> [--namespace <namespace>]
            cmd = [cli_path, "export", "--json"]
            if path:
                cmd.extend(["--path", path])
            if namespace:
                cmd.extend(["--namespace", namespace])

            # Use run_secret_cli helper to run securely
            timeout = self.fetch_timeout_seconds(cfg)
            try:
                proc = run_secret_cli(
                    cmd,
                    allow_env=["CLOAK_TOKEN", "CLOAK_SECRET_KEY", "PATH", "HOME"],
                    timeout=timeout,
                )
            except RuntimeError as exc:
                err_str = str(exc)
                if "timed out" in err_str.lower():
                    result.error = f"CloakEnv fetch timed out: {err_str}"
                    result.error_kind = ErrorKind.TIMEOUT
                else:
                    result.error = f"CloakEnv CLI execution failed: {err_str}"
                    result.error_kind = ErrorKind.BINARY_MISSING
                return result

            if proc.returncode != 0:
                stderr_snippet = proc.stderr[:200] if proc.stderr else ""
                if "auth" in stderr_snippet.lower() or "unauthorized" in stderr_snippet.lower() or proc.returncode in (1, 401, 403):
                    result.error = f"CloakEnv CLI auth failed (exit {proc.returncode}): {stderr_snippet}"
                    result.error_kind = ErrorKind.AUTH_FAILED
                else:
                    result.error = f"CloakEnv CLI exited with {proc.returncode}: {stderr_snippet}"
                    result.error_kind = ErrorKind.INTERNAL
                return result

            try:
                raw_data = json.loads(proc.stdout)
            except Exception as json_err:
                result.error = f"Failed to parse CloakEnv JSON output: {json_err}"
                result.error_kind = ErrorKind.INTERNAL
                return result

            if not isinstance(raw_data, dict):
                result.error = f"CloakEnv output expected dict/object, got {type(raw_data).__name__}"
                result.error_kind = ErrorKind.INTERNAL
                return result

            # Process secrets
            fetched_secrets: Dict[str, str] = {}
            if mappings and isinstance(mappings, dict):
                # Explicit VAR -> reference mapping
                for env_var, ref_key in mappings.items():
                    if ref_key in raw_data:
                        val = str(raw_data[ref_key])
                        if val:
                            fetched_secrets[env_var] = val
            else:
                # Bulk export mapping
                for k, v in raw_data.items():
                    if isinstance(k, str) and v is not None:
                        val = str(v)
                        if val:
                            fetched_secrets[k] = val

            if not fetched_secrets and raw_data:
                result.error = "CloakEnv returned data, but no non-empty matching secret values were found."
                result.error_kind = ErrorKind.EMPTY_VALUE
                return result

            if cache_ttl > 0:
                self._cache[cache_key] = (now, fetched_secrets)

            result.secrets = fetched_secrets
            return result

        except Exception as unhandled_exc:
            result.error = f"Unexpected error in CloakEnv secret source: {unhandled_exc}"
            result.error_kind = ErrorKind.INTERNAL
            return result


def register(ctx):
    """
    Register CloakEnv secret source plugin with Hermes plugin context.
    """
    if hasattr(ctx, "register_secret_source"):
        ctx.register_secret_source(CloakEnvSource())
