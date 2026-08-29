import os


def resolve_jules_api_key(explicit_token: str | None = None) -> str | None:
    """Resolve the Jules API key.

    Priority:
    1. Explicit token argument (e.g. from CLI flag)
    2. JULES_API_KEY environment variable
    """
    if explicit_token:
        return explicit_token.strip()

    env_token = os.environ.get("JULES_API_KEY")
    if env_token:
        return env_token.strip()

    return None
