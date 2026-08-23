---
name: feature-release
description: Multi-phase feature implementation and release workflow with approval gates
argument-hint: "<version-tag> [release-notes-focus]"
capabilities:
  allowed_tools:
    - view_file
    - run_command
    - replace_file_content
  allowed_bash_commands:
    - "git status*"
    - "git diff*"
    - "npm test"
---

# Feature Release Workflow

Execute release preparation for version: **$1**

---

## 📋 Phase 1: Pre-Flight Verification
- [ ] 1. Verify working directory is clean:
  !`git status --porcelain`
- [ ] 2. Run unit and integration tests:
  !`npm test`
- [ ] 3. Inspect recent commit logs since last tag:
  !`git log $(git describe --tags --abbrev=0 2>/dev/null || echo HEAD~10)..HEAD --oneline`

---

## ⚠️ CHECKPOINT 1: Plan & Changelog Approval
- Present updated version diff and changelog draft in `implementation_plan.md`.
- **STOP & PROMPT**: Request explicit user confirmation before modifying release files.

---

## 🛠️ Phase 2: Version Bump & Release Prep
*(Proceed only after Checkpoint 1 approval)*
- [ ] 1. Update version number in `package.json` to `$1`.
- [ ] 2. Prepend release notes to `CHANGELOG.md`.
- [ ] 3. Run final syntax and build check:
  !`npm run build`

---

## 🚀 Phase 3: Final Verification
- Present git diff of release modifications.
- Request user confirmation to create the release commit.
