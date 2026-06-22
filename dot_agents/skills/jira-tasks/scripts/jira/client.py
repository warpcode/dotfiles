import base64
import json
from urllib.error import HTTPError
from urllib.request import Request, urlopen
from .utils import err, die

JIRA_API_VERSION = "3"

class JiraClient:
    def __init__(self, url, user, token, verbose=False):
        self.url = url.rstrip("/")
        self.user = user
        self.token = token
        self.verbose = verbose
        auth_str = f"{user}:{token}"
        self.auth_header = f"Basic {base64.b64encode(auth_str.encode()).decode()}"

    def call(self, method, endpoint, payload=None, query_params=None):
        if endpoint.startswith("http"):
            url = endpoint
        else:
            url = f"{self.url}/{endpoint.lstrip('/')}"

        if query_params:
            from urllib.parse import urlencode
            url = f"{url}?{urlencode(query_params)}"

        if self.verbose:
            err(f"Request: {method} {url}")
            if payload:
                err(f"Payload: {json.dumps(payload)}")

        data = json.dumps(payload).encode() if payload else None
        req = Request(url, data=data, method=method)
        req.add_header("Authorization", self.auth_header)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")

        try:
            with urlopen(req) as response:
                status_code = response.getcode()
                body = response.read().decode()
                if self.verbose:
                    err(f"HTTP Status: {status_code}")
                return json.loads(body) if body else {}
        except HTTPError as e:
            status_code = e.code
            body = e.read().decode()
            if self.verbose:
                err(f"HTTP Status: {status_code}")
                err(f"Response: {body}")

            error_map = {
                401: "Authentication failed (401).",
                403: "Forbidden (403).",
                404: "Not Found (404).",
                400: "Bad Request (400)."
            }
            die(error_map.get(status_code, f"Request failed with HTTP {status_code}."))
        except Exception as e:
            die(f"Request failed: {str(e)}")

def get_status_map(client, project_key=None):
    """Fetch all statuses and their categories to build a mapping."""
    if project_key:
        endpoint = f"rest/api/{JIRA_API_VERSION}/project/{project_key}/statuses"
        try:
            response = client.call("GET", endpoint)
            # Flatten statuses from all issue types
            mapping = {}
            for itype in response:
                for status in itype.get("statuses", []):
                    mapping[status["name"]] = status.get("statusCategory", {}).get("name")
            return mapping
        except:
            pass

    # Fallback to global status list
    endpoint = f"rest/api/{JIRA_API_VERSION}/status"
    try:
        response = client.call("GET", endpoint)
        return {item["name"]: item.get("statusCategory", {}).get("name") for item in response}
    except:
        return {}
