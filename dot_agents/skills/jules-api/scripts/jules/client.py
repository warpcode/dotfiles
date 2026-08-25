import json
from typing import Any
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from .utils import die, info

DEFAULT_BASE_URL = "https://jules.googleapis.com/v1alpha"


class JulesClient:
    """REST API client for Google Jules (v1alpha)."""

    def __init__(
        self,
        api_key: str,
        base_url: str = DEFAULT_BASE_URL,
        verbose: bool = False,
    ) -> None:
        if not api_key:
            die("Jules API key is required. Set JULES_API_KEY or provide --token.")
        self.api_key = api_key.strip()
        self.base_url = base_url.rstrip("/")
        self.verbose = verbose

    def call(
        self,
        method: str,
        endpoint: str,
        payload: dict[str, Any] | None = None,
        query_params: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Execute a raw HTTP call to the Jules API."""
        if endpoint.startswith("http://") or endpoint.startswith("https://"):
            url = endpoint
        else:
            clean_endpoint = endpoint.lstrip("/")
            url = f"{self.base_url}/{clean_endpoint}"

        if query_params:
            filtered_params = {
                k: v for k, v in query_params.items() if v is not None and v != ""
            }
            if filtered_params:
                url = f"{url}?{urlencode(filtered_params)}"

        info(f"Request: {method} {url}", self.verbose)
        data = None
        if payload is not None:
            data = json.dumps(payload).encode("utf-8")
            info(f"Payload: {json.dumps(payload)}", self.verbose)

        req = Request(url, data=data, method=method.upper())
        req.add_header("X-Goog-Api-Key", self.api_key)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")

        try:
            with urlopen(req) as response:
                status_code = response.getcode()
                raw_body = response.read().decode("utf-8")
                info(f"HTTP Status: {status_code}", self.verbose)
                if not raw_body.strip():
                    return {}
                return json.loads(raw_body)
        except HTTPError as e:
            status_code = e.code
            raw_body = e.read().decode("utf-8") if e.fp else ""
            info(f"HTTP Error {status_code}: {raw_body}", self.verbose)

            error_msg = ""
            try:
                err_json = json.loads(raw_body)
                if isinstance(err_json, dict) and "error" in err_json:
                    err_obj = err_json["error"]
                    if isinstance(err_obj, dict):
                        error_msg = err_obj.get("message", "")
            except Exception:
                pass

            error_map = {
                400: f"Bad Request (400): {error_msg or 'invalid parameter or payload.'}",
                401: f"Authentication Failed (401): {error_msg or 'invalid or missing API key.'}",
                403: f"Forbidden (403): {error_msg or 'access denied to this resource.'}",
                404: f"Not Found (404): {error_msg or 'the requested resource was not found.'}",
                429: f"Rate Limited (429): {error_msg or 'too many requests.'}",
                500: f"Internal Server Error (500): {error_msg or 'Jules service encountered an error.'}",
                503: f"Service Unavailable (503): {error_msg or 'Jules service temporarily unavailable.'}",
            }
            die(error_map.get(status_code, f"HTTP request failed with status {status_code}: {error_msg or raw_body}"))
        except Exception as e:
            die(f"Network request failed: {str(e)}")

        return {}

    # --- Sources Operations ---

    def list_sources(
        self,
        page_size: int | None = None,
        page_token: str | None = None,
        filter_expr: str | None = None,
    ) -> dict[str, Any]:
        """List connected code repositories / sources."""
        params = {}
        if page_size:
            params["pageSize"] = page_size
        if page_token:
            params["pageToken"] = page_token
        if filter_expr:
            params["filter"] = filter_expr
        return self.call("GET", "sources", query_params=params)

    def get_source(self, source_name_or_id: str) -> dict[str, Any]:
        """Retrieve details for a specific connected repository source."""
        clean_name = source_name_or_id.strip()
        if not clean_name.startswith("sources/"):
            clean_name = f"sources/{clean_name}"
        return self.call("GET", clean_name)

    # --- Sessions Operations ---

    def list_sessions(
        self,
        page_size: int | None = None,
        page_token: str | None = None,
        filter_expr: str | None = None,
    ) -> dict[str, Any]:
        """List Jules task sessions."""
        params = {}
        if page_size:
            params["pageSize"] = page_size
        if page_token:
            params["pageToken"] = page_token
        if filter_expr:
            params["filter"] = filter_expr
        return self.call("GET", "sessions", query_params=params)

    def get_session(self, session_id: str) -> dict[str, Any]:
        """Retrieve full details of a specific Jules session."""
        sid = session_id.strip().removeprefix("sessions/")
        return self.call("GET", f"sessions/{sid}")

    def create_session(
        self,
        prompt: str,
        source: str,
        starting_branch: str = "main",
        title: str | None = None,
        require_plan_approval: bool | None = None,
        env_vars: dict[str, str] | None = None,
    ) -> dict[str, Any]:
        """Create and initiate a new Jules coding task session."""
        clean_source = source.strip()
        if not clean_source.startswith("sources/"):
            clean_source = f"sources/{clean_source}"

        payload: dict[str, Any] = {
            "prompt": prompt,
            "sourceContext": {
                "source": clean_source,
                "githubRepoContext": {
                    "startingBranch": starting_branch,
                },
            },
        }
        if title:
            payload["title"] = title
        if require_plan_approval is not None:
            payload["requirePlanApproval"] = require_plan_approval
        if env_vars:
            payload["environmentVariables"] = env_vars

        return self.call("POST", "sessions", payload=payload)

    def approve_plan(self, session_id: str, plan_id: str) -> dict[str, Any]:
        """Approve a pending plan generated by Jules for a session."""
        sid = session_id.strip().removeprefix("sessions/")
        payload = {"planId": plan_id.strip()}
        return self.call("POST", f"sessions/{sid}:approvePlan", payload=payload)

    def send_message(self, session_id: str, message: str) -> dict[str, Any]:
        """Send a user message or feedback instruction to a session."""
        sid = session_id.strip().removeprefix("sessions/")
        payload = {"message": message.strip()}
        return self.call("POST", f"sessions/{sid}:sendMessage", payload=payload)

    # --- Session Activities Operations ---

    def list_activities(
        self,
        session_id: str,
        page_size: int | None = None,
        page_token: str | None = None,
    ) -> dict[str, Any]:
        """List activities and timeline events for a given session."""
        sid = session_id.strip().removeprefix("sessions/")
        params = {}
        if page_size:
            params["pageSize"] = page_size
        if page_token:
            params["pageToken"] = page_token
        return self.call("GET", f"sessions/{sid}/activities", query_params=params)

    def get_activity(self, session_id: str, activity_id: str) -> dict[str, Any]:
        """Retrieve details for a single activity within a session."""
        sid = session_id.strip().removeprefix("sessions/")
        aid = activity_id.strip().split("/")[-1]
        return self.call("GET", f"sessions/{sid}/activities/{aid}")
