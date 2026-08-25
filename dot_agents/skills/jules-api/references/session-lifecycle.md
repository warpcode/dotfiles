# Jules Session Lifecycle & Execution Model

Understanding the lifecycle stages of an asynchronous task delegated to Google Jules.

```mermaid
stateDiagram-v2
    [*] --> QUEUED: POST /sessions
    QUEUED --> PLANNING: VM Provisioned & Repo Cloned
    PLANNING --> PLAN_GENERATED: Plan Artifact Emitted

    state Plan_Gate <<choice>>
    PLAN_GENERATED --> Plan_Gate: requirePlanApproval?

    Plan_Gate --> AWAITING_APPROVAL: true
    Plan_Gate --> EXECUTING: false (Auto-Approved)

    AWAITING_APPROVAL --> EXECUTING: POST /sessions/{id}:approvePlan
    AWAITING_APPROVAL --> PLANNING: POST /sessions/{id}:sendMessage (Feedback)

    EXECUTING --> RUNNING_TESTS: Code Edits & Test Execution
    RUNNING_TESTS --> ARTIFACT_GENERATED: Unidiff Patch Produced
    ARTIFACT_GENERATED --> PR_CREATED: GitHub PR Opened
    PR_CREATED --> COMPLETED: Final Output Attached
    COMPLETED --> [*]

    EXECUTING --> FAILED: Test Failure / Error
    PLANNING --> FAILED: Unresolvable Prompt
    FAILED --> [*]
```

---

## Lifecycle Stages

### 1. Initiation & VM Provisioning
- Session is created via `POST /sessions` with `prompt` and `sourceContext`.
- Jules provisions an isolated cloud virtual machine with a fresh container environment.
- The target git repository and `startingBranch` are cloned securely.

### 2. Planning Phase
- Jules analyzes repository files, dependencies, and git log.
- Jules produces a structured `planGenerated` activity containing step-by-step tasks with IDs, titles, and descriptions.
- If `requirePlanApproval` was set to `true`, execution halts until the user approves via `approvePlan` or sends clarifying feedback via `sendMessage`.

### 3. Execution & Test Verification
- Jules executes commands in a bash session on the VM.
- Code modifications are made and verified by running project test suites (e.g. `go test`, `pytest`, `npm test`).
- Progress events are emitted as `progressUpdated` activities.

### 4. Patch Generation & Pull Request Automation
- Completed changes are recorded in an `artifacts` activity containing a unified git diff (`unidiffPatch`).
- Jules creates a dedicated git branch and opens a GitHub Pull Request with a structured description and suggested commit message.
- The session state transitions to `COMPLETED`.
