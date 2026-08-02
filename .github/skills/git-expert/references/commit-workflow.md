# Commit Message Standards

Reference for the *process* of performing a commit — collecting context and presenting the commit command to the user. The actual format rules (subjects, bodies, type tables, hard constraints on message shape) live in `${SKILL_DIR}/references/commit-message-format.md`. **Execute** this workflow whenever the user asks to commit or to review staged changes with intent to commit — run the provided scripts, don't just read them.

## Workflow

### 1. Collect Context

**Execute** the preflight script first (do not read it — run it to get live repo context):

```bash
bash ${SKILL_DIR}/scripts/preflight.sh
```

Then check for staged files:

- **If staged files exist** → proceed to filename checks.
- **If no staged files** → check if there are any changed files at all:
  - **If changed files exist** → proceed to filename checks.
  - **If no changed files at all** → halt the procedure and inform the user there are no changes to generate a diff.

### 2. Filename Checks

Analyse the filenames for review and raise any issues or concerns to the user. If there are already project rules in place for filenaming, now would be the perfect time to check and halt if there are any issues/concerns. If the filename checks pass, move onto file diffs.

### 3. File Diffs

**Execute** the git-diff-triage script to efficiently triage the diff (run it, don't read it):

```bash
python3 ${SKILL_DIR}/scripts/git-diff-triage.py --threshold=40 -- --staged
```

This script shows the full diff for files with ≤ 40 changed lines, and for larger files shows only structural headers (file header, @@ hunk markers, etc.) with a note on how many lines were omitted. If the diff size is over the threshold, the body content is omitted and the LLM then gets it efficiently in chunks.

Then, decide, based on the size of the diffs, to batch analyse files/chunks.

### 4. Assess Complexity

Determine whether the commit message should be single-line or multiline. See `${SKILL_DIR}/references/commit-message-format.md` for complexity assessment rules.

### 5. Draft Message

Apply the format rules from `${SKILL_DIR}/references/commit-message-format.md` to draft the commit message.

### 6. Write to File

Write the commit message to a temporary file in the system tmp directory using `mktemp`. You MUST use the native edit file tool available to write the draft commit message (never use bash/shell/scripts to write the file content). This avoids breaking the shell syntax.

### 7. Present to User

By default, always show the draft commit message to the user for approval. When approved, run the `git commit -F /tmp/*******` command and remove the temp file.


## Operational Hard Constraints

These constraints govern *how* a commit is constructed and delivered — not the
format of the message itself (those rules are in `${SKILL_DIR}/references/commit-message-format.md`).

| Rule | Requirement |
|------|-------------|
| Auto-commit | MUST NOT run `git commit` without user instruction |
| Staged only | MUST generate from `git diff --staged`, never from working tree |
| Commit file | MUST write message to a file via the agent's file-writing tool (never shell redirection) |
| Confirmation | MUST present the full commit command and wait for explicit user approval |
| Message source | MUST pull subject/body content from the staged diff and format rules — never invent details |
