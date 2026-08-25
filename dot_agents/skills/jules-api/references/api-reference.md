# Google Jules REST API Reference (v1alpha)

Comprehensive specification of endpoints, query parameters, request structures, and response schemas for Google Jules API.

- **Base Service Endpoint:** `https://jules.googleapis.com/v1alpha`
- **Authentication Header:** `X-Goog-Api-Key: <JULES_API_KEY>`

---

## 1. Sources (`/sources`)

Sources represent connected GitHub repositories authorized for task delegation.

### List Sources
- **HTTP Method:** `GET /v1alpha/sources`
- **Query Parameters:**
  - `pageSize` (integer, optional): Maximum number of sources to return.
  - `pageToken` (string, optional): Page token for pagination.
  - `filter` (string, optional): Filter expression (e.g., `name=sources/github/owner/repo`).
- **Response Body:**
  ```json
  {
    "sources": [
      {
        "name": "sources/github/owner/repo",
        "id": "github/owner/repo",
        "githubRepo": {
          "owner": "owner",
          "repo": "repo",
          "defaultBranch": {
            "displayName": "main"
          },
          "branches": [
            { "displayName": "main" },
            { "displayName": "feature-1" }
          ]
        }
      }
    ],
    "nextPageToken": "string"
  }
  ```

### Get Source
- **HTTP Method:** `GET /v1alpha/sources/{sourceId}` or `GET /v1alpha/{name=sources/**}`
- **Response Body:** Single source object.

---

## 2. Sessions (`/sessions`)

A session represents an asynchronous coding task executed by an isolated cloud VM.

### List Sessions
- **HTTP Method:** `GET /v1alpha/sessions`
- **Query Parameters:**
  - `pageSize` (integer, optional): Maximum number of sessions to return.
  - `pageToken` (string, optional): Pagination token.
  - `filter` (string, optional): Filter expression.
- **Response Body:**
  ```json
  {
    "sessions": [
      {
        "name": "sessions/4475409647262242777",
        "id": "4475409647262242777",
        "title": "Task title",
        "state": "COMPLETED",
        "prompt": "Task instructions...",
        "sourceContext": {
          "source": "sources/github/owner/repo",
          "githubRepoContext": {
            "startingBranch": "main"
          },
          "environmentVariablesEnabled": true
        },
        "outputs": [
          {
            "pullRequest": {
              "url": "https://github.com/owner/repo/pull/123",
              "title": "PR Title",
              "description": "PR body",
              "baseRef": "main",
              "headRef": "branch-name"
            }
          }
        ],
        "createTime": "2026-08-22T08:46:34Z",
        "updateTime": "2026-08-22T11:29:17Z",
        "url": "https://jules.google.com/session/4475409647262242777"
      }
    ],
    "nextPageToken": "string"
  }
  ```

### Get Session
- **HTTP Method:** `GET /v1alpha/sessions/{sessionId}`
- **Response Body:** Single session object.

### Create Session
- **HTTP Method:** `POST /v1alpha/sessions`
- **Request Body:**
  ```json
  {
    "prompt": "Refactor auth handler to scrub memory buffers",
    "sourceContext": {
      "source": "sources/github/owner/repo",
      "githubRepoContext": {
        "startingBranch": "main"
      }
    },
    "title": "Refactor sensitive memory",
    "requirePlanApproval": false
  }
  ```
- **Response Body:** Created session object.

### Approve Plan
- **HTTP Method:** `POST /v1alpha/sessions/{sessionId}:approvePlan`
- **Request Body:**
  ```json
  {
    "planId": "1b5bcc461e9140ba990f4601ec3b4734"
  }
  ```
- **Response Body:** `{}` (empty object on success).

### Send Message
- **HTTP Method:** `POST /v1alpha/sessions/{sessionId}:sendMessage`
- **Request Body:**
  ```json
  {
    "message": "Please also add unit tests for error cases."
  }
  ```
- **Response Body:** `{}` (empty object on success).

---

## 3. Session Activities (`/sessions/{sessionId}/activities`)

### List Activities
- **HTTP Method:** `GET /v1alpha/sessions/{sessionId}/activities`
- **Query Parameters:**
  - `pageSize` (integer, optional)
  - `pageToken` (string, optional)
- **Response Body:**
  ```json
  {
    "activities": [
      {
        "name": "sessions/{sessionId}/activities/{activityId}",
        "id": "{activityId}",
        "createTime": "2026-08-22T08:50:25Z",
        "originator": "agent",
        "planGenerated": {
          "plan": {
            "id": "plan-id",
            "steps": [
              {
                "id": "step-id",
                "title": "Step title",
                "description": "Step description",
                "index": 0
              }
            ]
          }
        }
      }
    ],
    "nextPageToken": "string"
  }
  ```

### Get Activity
- **HTTP Method:** `GET /v1alpha/sessions/{sessionId}/activities/{activityId}`
- **Response Body:** Single activity event object.
