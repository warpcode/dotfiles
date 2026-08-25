# Antigravity CLI (`agy`) Stream JSON Protocol

The `--output-format stream-json` and `--input-format stream-json` flags enable streaming NDJSON (Newline Delimited JSON) interaction over stdin/stdout for multi-turn automation and real-time event processing.

---

## 1. Output Streaming Format (`--output-format stream-json`)

When running in stream mode:
```bash
agy --output-format stream-json -p "Refactor auth.go to use JWT"
```

Each event is emitted as a single-line JSON object.

### Event Types

#### Step / Progress Event
```json
{
  "type": "step",
  "step_index": 1,
  "action": "Searching codebase",
  "summary": "Grep for auth tokens"
}
```

#### Tool Call Event
```json
{
  "type": "tool_call",
  "tool_name": "view_file",
  "parameters": {
    "AbsolutePath": "/home/user/src/auth.go"
  }
}
```

#### Final Result Event
```json
{
  "type": "result",
  "status": "SUCCESS",
  "response": "Authentication refactored to use JWT successfully.",
  "duration_seconds": 4.12,
  "usage": {
    "input_tokens": 12500,
    "output_tokens": 420,
    "thinking_tokens": 150,
    "total_tokens": 13070
  }
}
```

---

## 2. Multi-Turn Input Streaming (`--input-format stream-json`)

Requires both `--input-format stream-json` and `--output-format stream-json`.

### Input Stream Schema
Send NDJSON messages to stdin. Each line is a turn:
```json
{"prompt": "Analyze main.py for security issues"}
{"prompt": "Apply fix for issue #1"}
```

### Python Streaming Wrapper Pattern
```python
import json
import subprocess

proc = subprocess.Popen(
    [
        "agy",
        "--input-format", "stream-json",
        "--output-format", "stream-json",
        "--dangerously-skip-permissions",
    ],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1,
)

# Turn 1
proc.stdin.write(json.dumps({"prompt": "List files in src/"}) + "\n")
proc.stdin.flush()

for line in proc.stdout:
    event = json.loads(line)
    if event.get("type") == "result":
        print("Turn 1 complete:", event["response"])
        break
```
