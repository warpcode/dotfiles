# Jules Python Programmatic Client Reference

Use `jules.client.JulesClient` for programmatic automation pipelines, custom triage bots, or integrating Jules with other orchestration frameworks.

---

## Authentication & Initialization

The client automatically resolves the API key via `resolve_jules_api_key()` from the `JULES_API_KEY` environment variable, or accepts an explicit key.

```python
from jules.client import JulesClient
from jules.auth import resolve_jules_api_key

# Auto-resolve from environment (JULES_API_KEY)
api_key = resolve_jules_api_key()
client = JulesClient(api_key=api_key)

# Or pass explicitly:
# client = JulesClient(api_key="your-api-key")
```

---

## Core Operations

### 1. Sources (Connected Repositories)

```python
# List connected sources
sources_resp = client.list_sources(page_size=10)
for src in sources_resp.get("sources", []):
    print(src["name"], src.get("githubRepoContext", {}).get("defaultBranch"))

# Get specific repository source
source = client.get_source("sources/github/warpcode/cloakenv")
```

### 2. Task Sessions

```python
# List sessions
sessions_resp = client.list_sessions(page_size=5)
for s in sessions_resp.get("sessions", []):
    print(s["id"], s.get("state"), s.get("title"))

# Create session with connected repo
session = client.create_session(
    prompt="Refactor sensitive memory buffers to use ZeroBytes",
    source="github/warpcode/cloakenv",
    starting_branch="main",
    title="Memory Scrubbing Refactor",
    require_plan_approval=True,
)
session_id = session["id"]

# Create sourceless session (exploratory, no repository)
sourceless = client.create_session(
    prompt="Explain architectural trade-offs between zero-copy buffers and memory wiping",
    title="Architecture Discussion",
)

# Inspect session details
details = client.get_session(session_id)
print(details.get("outputs"))
```

### 3. Human-in-the-Loop Interaction

```python
# Approve plan
client.approve_plan(session_id, plan_id="optional-plan-id")

# Send feedback or steering message
client.send_message(session_id, "Please ensure unit tests verify boundary allocations.")
```

### 4. Activities & Timelines

```python
# Fetch paginated activities (oldest first by API convention)
activities_resp = client.list_activities(session_id, page_size=20)

# Fetch all activities automatically following nextPageToken
all_activities = client.get_all_activities(session_id)

# Fetch single activity (e.g. plan steps or patch diff)
activity = client.get_activity(session_id, activity_id="abc123")
```
