# Stale Branch & Git Sandbox Architecture

Technical reference detailing how Jules handles git operations, why sandbox isolation triggers empty commit loops, and the standard recovery procedure.

---

## 1. Jules Git Architecture

Jules' cloud sandbox has **no git remote credentials**. All commits and branches are managed by the outer orchestration platform directly on GitHub:

```mermaid
sequenceDiagram
    participant Agent as Jules Container (/app)
    participant Platform as Jules Orchestrator (Outer)
    participant GitHub as GitHub (Remote Repo)

    Agent->>Platform: Tool Call (branch_name, message, files)
    Note over Agent: Sandbox has no git push rights
    Platform->>GitHub: Compare /app with base snapshot
    Platform->>GitHub: Create Tree, Commit, and Ref
    GitHub-->>Platform: Commit SHA created
    Platform-->>Agent: Tool Call Result
```

---

## 2. The Empty-Commit Loop Phenomenon

When the base branch in the GitHub repository is updated *after* a Jules session starts:
1. Jules' `/app` workspace is rooted on the older base commit snapshot.
2. If Jules attempts to submit changes, the platform compares Jules' filesystem against the snapshot.
3. If changes overlap or conflicts exist, or if Jules tries to reconcile without access to `git fetch`, the platform may push empty commits or repeatedly reject the diff.
4. Jules may enter an infinite loop attempting to "push" or resolve conflicts it cannot see.

---

## 3. Remediation Procedure

When a session enters an empty-commit loop or reports stale base branch errors:

1. **Halt the Session Runner Immediately**:
   Send the `stale_branch_halt` nudge:
   `"Stop pushing. The remote branch has been updated since your session started. Your local environment is stale. Please stop all further push attempts."`

2. **Archive the Stale Session**:
   Reversibly archive the session so it no longer consumes attention or triggers alarms.

3. **Spawn a Fresh Session**:
   Create a new task session targeting the latest commit on the updated branch, carrying forward any salvageable plan or requirements from the halted session.

4. **Concurrency Invariant**:
   Treat an active Jules task as having an exclusive lock on its target branch. Avoid landing unrelated commits onto a branch while Jules is actively working on it.
