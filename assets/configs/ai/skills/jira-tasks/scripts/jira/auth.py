import os
import shlex
import subprocess

def resolve_secret(name):
    """Resolve a secret using DF_SECRET_GET_CMD if not already set."""
    # 1. Early return if already set in environment
    val = os.environ.get(name)
    if val:
        return val

    # 2. Special case for token: check JIRA_API_KEY
    if name == "JIRA_API_TOKEN":
        val = os.environ.get("JIRA_API_KEY")
        if val:
            return val

    # 3. Guard: resolver command must be defined
    resolver_cmd = os.environ.get("DF_SECRET_GET_CMD")
    if not resolver_cmd:
        return None

    # 4. Resolve via command
    try:
        cmd_args = shlex.split(resolver_cmd) + [name]
        result = subprocess.run(cmd_args, capture_output=True, text=True, check=True)
        value = result.stdout.strip()

        # 5. Fallback for token
        if not value and name == "JIRA_API_TOKEN":
            cmd_args = shlex.split(resolver_cmd) + ["JIRA_API_KEY"]
            result = subprocess.run(cmd_args, capture_output=True, text=True, check=True)
            value = result.stdout.strip()

        return value if value else None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
