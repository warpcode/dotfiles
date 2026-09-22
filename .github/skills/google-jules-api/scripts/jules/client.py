import json
from datetime import datetime, timezone
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

    def approve_plan(self, session_id: str, plan_id: str | None = None) -> dict[str, Any]:
        """Approve a pending plan generated by Jules for a session."""
        sid = session_id.strip().removeprefix("sessions/")
        payload: dict[str, Any] = {}
        return self.call("POST", f"sessions/{sid}:approvePlan", payload=payload)

    def send_message(self, session_id: str, message: str) -> dict[str, Any]:
        """Send a user message or feedback instruction to a session."""
        sid = session_id.strip().removeprefix("sessions/")
        payload = {"prompt": message.strip()}
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
        if len(aid) < 32:
            all_acts = self.get_all_activities(sid)
            matches = [
                a for a in all_acts
                if (a.get("id") or a.get("name", "").split("/")[-1]).startswith(aid)
            ]
            if len(matches) == 1:
                return matches[0]
            elif len(matches) > 1:
                from jules.utils import die
                die(f"Ambiguous activity ID prefix '{aid}' matches {len(matches)} activities.")
        return self.call("GET", f"sessions/{sid}/activities/{aid}")

    def get_all_activities(self, session_id: str) -> list[dict[str, Any]]:
        """Retrieve all activities for a session across all paginated pages in chronological order."""
        sid = session_id.strip().removeprefix("sessions/")
        activities: list[dict[str, Any]] = []
        page_token = None
        while True:
            res = self.list_activities(session_id=sid, page_size=50, page_token=page_token)
            acts = res.get("activities", [])
            activities.extend(acts)
            page_token = res.get("nextPageToken")
            if not page_token or not acts:
                break
        return activities

    def audit_session(
        self,
        session_data: dict[str, Any],
        stale_threshold_mins: int = 60,
        max_age_days: int | None = 30,
    ) -> dict[str, Any]:
        """Audit the status, timeline events, and health of a single session."""
        sid = session_data.get("id") or session_data.get("name", "").removeprefix("sessions/")
        title = session_data.get("title") or session_data.get("prompt", "")[:60].replace("\n", " ")
        state = session_data.get("state", "UNKNOWN")
        source_ctx = session_data.get("sourceContext", {})
        source_name = source_ctx.get("source", "").removeprefix("sources/")
        branch = source_ctx.get("githubRepoContext", {}).get("startingBranch", "")

        created_time = session_data.get("createTime", "")
        updated_time = session_data.get("updateTime", "")

        pr_url = ""
        for out in session_data.get("outputs", []):
            if "pullRequest" in out:
                pr_url = out["pullRequest"].get("url", "")
                break

        activities = self.get_all_activities(sid)
        now = datetime.now(timezone.utc)

        conversation_history: list[dict[str, Any]] = []
        code_reviews: list[dict[str, Any]] = []
        plans: list[dict[str, Any]] = []
        pending_plan_id = ""
        user_message_count = 0
        agent_message_count = 0
        unanswered_user_messages = 0
        last_user_message = ""
        last_user_time = ""
        last_agent_message = ""
        last_agent_time = ""

        # Analyze initial task prompt as turn 0 if present
        prompt = session_data.get("prompt", "").strip()
        if prompt:
            conversation_history.append({
                "role": "user",
                "type": "prompt",
                "time": created_time,
                "id": "initial-prompt",
                "content": prompt,
            })
            user_message_count += 1
            unanswered_user_messages += 1
            last_user_message = prompt
            last_user_time = created_time

        # Traverse complete chronological timeline
        for a in activities:
            t = a.get("createTime", "")
            orig = a.get("originator", "")
            aid = a.get("id", "")

            if "planGenerated" in a:
                p = a["planGenerated"].get("plan", {})
                pid = p.get("id", "")
                steps = [s.get("title", "") for s in p.get("steps", [])]
                plans.append({
                    "id": pid,
                    "time": t,
                    "steps": steps,
                })
                pending_plan_id = pid
                conversation_history.append({
                    "role": "agent",
                    "type": "plan_generated",
                    "time": t,
                    "id": aid,
                    "content": f"Generated plan '{pid}' with {len(steps)} steps.",
                    "plan": p,
                })

            if "planApproved" in a:
                pid = a["planApproved"].get("planId", "")
                conversation_history.append({
                    "role": "user",
                    "type": "plan_approved",
                    "time": t,
                    "id": aid,
                    "content": f"Plan '{pid}' approved.",
                })

            if "progressUpdated" in a:
                pu = a["progressUpdated"]
                pu_title = pu.get("title", "")
                pu_desc = pu.get("description", "")
                if "reviewed" in pu_title.lower() or "review" in pu_desc.lower():
                    code_reviews.append({
                        "time": t,
                        "title": pu_title,
                        "description": pu_desc,
                    })
                    conversation_history.append({
                        "role": "agent",
                        "type": "code_review",
                        "time": t,
                        "id": aid,
                        "content": f"Code review: {pu_title}",
                        "review": pu,
                    })

            if "userMessaged" in a:
                user_msg = a["userMessaged"].get("userMessage", "").strip()
                user_message_count += 1
                unanswered_user_messages += 1
                last_user_message = user_msg
                last_user_time = t
                conversation_history.append({
                    "role": "user",
                    "type": "message",
                    "time": t,
                    "id": aid,
                    "content": user_msg,
                })

            if "agentMessaged" in a:
                agent_msg = a["agentMessaged"].get("agentMessage", "").strip()
                agent_message_count += 1
                unanswered_user_messages = 0
                last_agent_message = agent_msg
                last_agent_time = t
                conversation_history.append({
                    "role": "agent",
                    "type": "message",
                    "time": t,
                    "id": aid,
                    "content": agent_msg,
                })

            if "sessionCompleted" in a:
                conversation_history.append({
                    "role": "system",
                    "type": "session_completed",
                    "time": t,
                    "id": aid,
                    "content": "Session completed.",
                })

        # Conversation context assessment
        last_speaker = conversation_history[-1]["role"] if conversation_history else "none"
        agent_awaiting_reply = False
        if last_speaker == "agent" and last_agent_message:
            lower_msg = last_agent_message.lower()
            if any(q in lower_msg for q in ["confirm", "approve", "proceed", "look good", "?", "let me know", "feedback"]):
                agent_awaiting_reply = True

        latest_activity_time = updated_time
        latest_type = "none"
        latest_detail = ""

        if activities:
            latest = activities[-1]
            latest_activity_time = latest.get("createTime", updated_time)
            orig = latest.get("originator", "agent")
            type_keys = [k for k in latest.keys() if k not in ("id", "name", "createTime", "originator")]
            latest_type = type_keys[0] if type_keys else "unknown"

            if "agentMessaged" in latest:
                latest_detail = latest["agentMessaged"].get("agentMessage", "")[:120].strip()
            elif "userMessaged" in latest:
                latest_detail = f"User: {latest['userMessaged'].get('userMessage', '')[:100].strip()}"
            elif "planGenerated" in latest:
                plan = latest["planGenerated"].get("plan", {})
                latest_detail = f"Plan: {len(plan.get('steps', []))} steps"
            elif "progressUpdated" in latest:
                latest_detail = latest["progressUpdated"].get("title", "")
            elif "sessionCompleted" in latest:
                latest_detail = "Session completed"

        inactive_mins = 0.0
        if latest_activity_time:
            try:
                clean_time = latest_activity_time.replace("Z", "+00:00")
                act_dt = datetime.fromisoformat(clean_time)
                inactive_mins = max(0.0, (now - act_dt).total_seconds() / 60.0)
            except Exception:
                pass

        # Calculate session age and inactive status
        created_str = created_time or updated_time
        age_days = 0.0
        if created_str:
            try:
                clean_created = created_str.replace("Z", "+00:00")
                c_dt = datetime.fromisoformat(clean_created)
                age_days = max(0.0, (now - c_dt).total_seconds() / 86400.0)
            except Exception:
                pass

        is_inactive = bool(max_age_days is not None and max_age_days > 0 and age_days > max_age_days)

        # Determine assessment using state, age, and conversation history
        if is_inactive:
            assessment = "INACTIVE"
        elif state == "AWAITING_PLAN_APPROVAL" or (pending_plan_id and agent_awaiting_reply and state not in ("COMPLETED", "FAILED")):
            assessment = "AWAITING_PLAN_APPROVAL"
        elif state == "AWAITING_USER_FEEDBACK" or (agent_awaiting_reply and state not in ("COMPLETED", "FAILED")):
            assessment = "AWAITING_USER_FEEDBACK"
        elif state == "IN_PROGRESS":
            if unanswered_user_messages > 0 and inactive_mins >= 15:
                assessment = "STALLED"
            elif inactive_mins >= stale_threshold_mins:
                assessment = "STALLED"
            else:
                assessment = "ACTIVE"
        elif state == "COMPLETED":
            if pr_url:
                assessment = "COMPLETED_WITH_PR"
            else:
                assessment = "COMPLETED_NO_OUTPUT"
        else:
            assessment = state

        return {
            "id": sid,
            "title": title,
            "state": state,
            "assessment": assessment,
            "source": source_name,
            "branch": branch,
            "created_time": created_time,
            "updated_time": updated_time,
            "latest_activity_time": latest_activity_time,
            "inactive_mins": round(inactive_mins, 1),
            "age_days": round(age_days, 1),
            "is_inactive": is_inactive,
            "activity_count": len(activities),
            "latest_type": latest_type,
            "latest_detail": latest_detail,
            "pending_plan_id": pending_plan_id,
            "pull_request_url": pr_url,
            "conversation_history": conversation_history,
            "user_message_count": user_message_count,
            "agent_message_count": agent_message_count,
            "unanswered_user_messages": unanswered_user_messages,
            "agent_awaiting_reply": agent_awaiting_reply,
            "last_speaker": last_speaker,
            "last_user_message": last_user_message,
            "last_user_time": last_user_time,
            "last_agent_message": last_agent_message,
            "last_agent_time": last_agent_time,
            "code_reviews": code_reviews,
            "plans": plans,
        }

    def audit_sessions(
        self,
        page_size: int = 10,
        stale_threshold_mins: int = 60,
        filter_expr: str | None = None,
        max_age_days: int | None = 30,
    ) -> list[dict[str, Any]]:
        """List and audit recent sessions, ignoring inactive sessions over max_age_days old."""
        res = self.list_sessions(page_size=page_size, filter_expr=filter_expr)
        sessions = res.get("sessions", [])
        now = datetime.now(timezone.utc)
        audits = []
        for s in sessions:
            if max_age_days is not None and max_age_days > 0:
                ts = s.get("createTime") or s.get("updateTime")
                if ts:
                    try:
                        clean_time = ts.replace("Z", "+00:00")
                        s_dt = datetime.fromisoformat(clean_time)
                        age_days = (now - s_dt).total_seconds() / 86400.0
                        if age_days > max_age_days:
                            continue
                    except Exception:
                        pass
            audits.append(self.audit_session(s, stale_threshold_mins=stale_threshold_mins, max_age_days=max_age_days))
        return audits

