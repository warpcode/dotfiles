---
name: jules-cli
description: >
  Execute and automate coding workflows using the Google Jules CLI (`@google/jules`).
  Use this skill whenever the user asks to delegate tasks to Jules, create or manage
  Jules remote sessions, check Jules session history or repository listings, pull results or patches from
  Jules sessions, teleport/checkout Jules sessions locally, or script batch automation with Jules. IMPORTANT:
  This skill MUST enforce non-interactive CLI subcommands and NEVER invoke bare `jules` (which launches the TUI dashboard)
user-invocable: false
---

# Jules CLI Automation & Abilities Reference

Use `@google/jules` to manage autonomous AI coding sessions, track remote task execution, pull completed code changes, and teleport session branches directly into your workspace.

## ⛔ CRITICAL RULE: NO TUI DASHBOARD

**NEVER run `jules` without subcommands or flags.**
Running bare `jules` launches an interactive Terminal User Interface (TUI) dashboard. In non-interactive and automated agent environments, TUI sessions freeze execution waiting for terminal input.

- ❌ `jules` (DO NOT USE — launches interactive TUI)
- ✅ `jules new "write unit tests"` (Non-interactive subcommand)
- ✅ `jules remote list --session` (Non-interactive subcommand)
- ✅ `jules teleport 123456` (Non-interactive subcommand)

---

## 📖 Terminology & Core Concepts

- **Repository (`--repo`)**:
  - A connected GitHub or git repository (e.g., `owner/repo` or `.` for the current directory's repo).
  - Jules needs repository authorization so its cloud VM environment can clone and inspect the codebase.

- **Remote Session (`--session` / `session_id`)**:
  - An asynchronous, isolated cloud VM task execution instance.
  - Each session is identified by a unique ID (e.g., `123456`) and runs independently in the cloud to execute your prompt, run tests, and generate code edits.

- **Parallel Sessions (`--parallel <1-5>`)**:
  - Launches 1 to 5 concurrent, isolated VM sessions for the exact same prompt.
  - Useful for comparing multiple solution paths or speeding up execution.

- **Patch / Diff**:
  - The unified git diff file produced by a completed session representing all code changes made by Jules.

- **Teleportation (`teleport <session_id>`)**:
  - One-command workspace synchronization: clones the target repo (if missing), checks out the starting branch, and applies the session patch to your local workspace.

---

## 1. Installation & Execution

### Method 1: On-demand execution with `npx` (Preferred)
Use `npx -y @google/jules` to execute commands directly without requiring a global installation:
```bash
# On-demand execution via npx
npx -y @google/jules remote list --session
npx -y @google/jules new "Add unit tests"
```

### Method 2: Global installation via `npm` (Secondary)
Install the CLI globally if you plan to invoke `jules` frequently:
```bash
# Install globally
npm install -g @google/jules

# Verify installation
jules version
```

---

## 2. Comprehensive List of Jules Abilities

### A. Session Creation & Task Delegation (`new` / `remote new`)
Delegate tasks to Jules cloud VMs. Supports shorthand `jules new` or explicit `jules remote new`.

- **Basic Session Creation**:
  ```bash
  jules new "write unit tests for auth service"
  # Equivalent:
  jules remote new --session "write unit tests for auth service"
  ```
- **Target Specific Repository**:
  ```bash
  jules new --repo owner/repo "add solarized dark theme"
  # Equivalent:
  jules remote new --repo owner/repo --session "add solarized dark theme"
  ```
- **Parallel Multi-Agent Execution** (`--parallel 1-5`): Spawns up to 5 concurrent sessions working on the same task simultaneously to test different approaches or increase execution speed.
  ```bash
  jules new --repo owner/repo --parallel 3 "refactor database queries"
  ```
- **Stdin Task Piping**:
  ```bash
  cat task.md | jules new
  echo "Fix typo in README" | jules remote new --repo owner/repo
  ```

### B. Pulling & Applying Patches (`remote pull`)
Extract generated diffs and apply them to local codebases.

- **Pull Session Output/Diff**:
  ```bash
  jules remote pull --session 123456
  ```
- **Pull and Apply Patch directly to Local Repo**:
  ```bash
  jules remote pull --session 123456 --apply
  ```

### C. Session Teleportation (`teleport`)
One-command environment setup and branch/patch checkout:

- **Teleport to Session**:
  ```bash
  jules teleport 123456
  ```
  - **Outside a repository**: Automatically clones the repository, checks out the session's starting branch, and applies the session patch.
  - **Inside a matching repository**: Applies the session patch directly to the current working tree.

### D. Session & Repository Inspection (`remote list`)
- **List All Remote Sessions**:
  ```bash
  jules remote list --session
  ```
- **List Connected Repositories**:
  ```bash
  jules remote list --repo
  ```

### E. Authentication & Environment Controls
- **Login**: `jules login` (launches browser OAuth flow)
- **Logout**: `jules logout` (clears credentials)
- **Version Check**: `jules version`
- **Shell Autocompletion**:
  ```bash
  jules completion bash    # bash completion script
  jules completion zsh     # zsh completion script
  jules completion fish    # fish completion script
  ```

---

## 3. Scripting & Automation Ecosystem

Combine Jules CLI with standard Linux shell tools (`gh`, `jq`, `gemini`, `cat`) for bulk workflows:

### Example 1: Batch process tasks from a file (`TODO.md`)
```bash
cat TODO.md | while IFS= read -r line; do
  [ -n "$line" ] && jules new "$line"
done
```

### Example 2: Delegate assigned GitHub issue to Jules
```bash
gh issue list --assignee @me --limit 1 --json title \
  | jq -r '.[0].title' \
  | jules new
```

### Example 3: AI-Selected Issue Delegation (Gemini + Jules)
```bash
gemini -p "find the most tedious issue, print it verbatim\n$(gh issue list --assignee @me)" \
  | jules new
```

---

## Command Reference Summary

| Ability / Goal | Shorthand Command | Standard Command | Non-Interactive |
|---|---|---|---|
| New Session | `jules new "<prompt>"` | `jules remote new --session "<prompt>"` | ✅ |
| Target Repository | `jules new --repo <r> "<prompt>"` | `jules remote new --repo <r> --session "<p>"` | ✅ |
| Parallel Sessions | `jules new --parallel N "<prompt>"` | `jules remote new --parallel N --session "<p>"` | ✅ |
| List Sessions | N/A | `jules remote list --session` | ✅ |
| List Repos | N/A | `jules remote list --repo` | ✅ |
| Pull Session Patch | N/A | `jules remote pull --session <id>` | ✅ |
| Pull & Apply Patch | N/A | `jules remote pull --session <id> --apply` | ✅ |
| Teleport to Session | `jules teleport <id>` | N/A | ✅ |
| Authentication | `jules login` / `jules logout` | N/A | ⚠️ Interactive Browser |
| Version Check | `jules version` | N/A | ✅ |
| Shell Autocompletion | `jules completion <shell>` | N/A | ✅ |
| Interactive TUI | `jules` | N/A | ❌ **PROHIBITED** |
