# Dead Code Detection & Emptied-File Reference Audit

Guidelines for locating, confirming, and safely removing dead code, and auditing emptied or refactored files before deletion.

---

## 1. Dead Code Detection Categories

1. **Unreferenced Classes & Methods**:
   - Private or protected methods that are never invoked anywhere in the class hierarchy.
   - Classes never imported, instantiated, or bound in service containers.
2. **Orphaned Routes & Controllers**:
   - Controller classes whose corresponding routes were commented out or deleted from route manifests.
3. **Dead Feature Flags & Unreachable Branches**:
   - Conditionals evaluating flags that have been permanently enabled or disabled in production.
4. **Unused Dependencies**:
   - Packages declared in `composer.json` or `package.json` that are never imported in application code.

---

## 2. Emptied & Refactored File Reference Audit

Non-invasive verification to determine whether a file that has been emptied, significantly reduced, or superseded can be safely deleted.

### Static Reference Discovery
- Search the entire workspace for static occurrences of the filename, relative path, or exported symbols (`rg` / `grep`).

### Dynamic Reference Discovery
Inspect known entrypoints and sourcing logic for dynamic or glob-based references:
- **Zsh**: Check `dot_zsh/init.zsh` and any profile-specific init scripts for glob-based sourcing (e.g., `functions/**/*.zsh`).
- **GitHub Actions**: Check `.github/workflows/` for hardcoded script paths.
- **Standard Tools**: Check `bin/` or `scripts/` for wrappers that might expect the file.
- **Bootstrapping & Packages**: Ensure the file is not required by a package-manager recipe or build script that lacks error handling for missing files.

### Keep vs. Delete Analysis
- **Static Reference**: If the path is hardcoded, verify whether referencing code still functions without it or needs updating first.
- **Dynamic Reference**: If the file is sourced via a glob, it is generally safe to delete once emptied.
- **Dynamic Dispatch**: Check for dynamic dispatch patterns (`call_user_func`, string variable method calls `$this->$method()`, event listeners, or DIC service bindings).

### File Deletion Audit Output
Report a concise verdict per candidate file:
- **Status**: `Keep` | `Delete`
- **Rationale**: Technical explanation of static/dynamic references and runtime impact.
- **Action**: If `Delete`, provide the removal command (e.g., `rm <path>`).

---

## 3. Safe Deletion Verification

1. **Static & Dynamic Check**: Complete the reference discovery above before removing any file or symbol.
2. **Remove & Verify**: Delete the dead code or file and run unit/integration test suites to verify zero broken imports or side effects.
3. **Isolated Commit**: Commit dead-code deletions separately from new feature work with clear commit messages (`refactor: remove unused LegacyBillingService`).
