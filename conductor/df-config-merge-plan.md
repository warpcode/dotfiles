# Plan: Consolidate Dotfiles Config Management

## Objective
Merge the fragmented `df.config.*` scripts into a unified `df.config` multi-call binary. This aligns the config management utilities with the established pattern used by other `df.*` tools (like `df.cache` and `df.secrets`), improving maintainability and standardizing the CLI UX.

## Key Files & Context
- **Target File**: `bin/df.config` (New)
- **Source Files to Remove**:
  - `bin/df.config.block`
  - `bin/df.config.hydrate`
  - `bin/df.config.symlink`
- **Related Dependencies**: These scripts interact with `gomplate`, `jq`, and the `df.secrets` utility.

## Implementation Steps
1. **Create the Base Structure**: Create `bin/df.config` using `zsh`. Ensure strict shell options (`emulate -LR zsh`, `setopt ERR_EXIT PIPE_FAIL NO_UNSET WARN_CREATE_GLOBAL`).
2. **Implement Subcommand Router**: Create a `main()` function that parses the first argument and routes to `cmd_block`, `cmd_hydrate`, or `cmd_symlink`.
3. **Consolidate Helpers**: Extract the duplicated `_resolve_path` and `err` functions from `hydrate` and `symlink` into shared, top-level helper functions in `df.config`.
4. **Migrate Logic**: 
    - Move `df.config.block` logic into `cmd_block()`.
    - Move `df.config.hydrate` logic into `cmd_hydrate()`.
    - Move `df.config.symlink` logic into `cmd_symlink()`.
5. **Update Help/Usage**: Create a unified `_usage` function that lists all three subcommands and their respective flags.
6. **Cleanup**: Delete `df.config.block`, `df.config.hydrate`, and `df.config.symlink`.

## Verification & Testing
- Run `df.config --help` to verify the routing and usage output.
- Test `df.config block` on a temporary file to ensure marker replacement works.
- Test `df.config symlink` with a dummy file to ensure it correctly resolves paths relative to `$DOTFILES` and creates symlinks.
- Test `df.config hydrate` with a template and JSON payload to ensure `gomplate` and `df.secrets` integration remains intact.

## Migration & Rollback
- **Rollback**: A standard `git restore bin/` will recreate the separate files and remove the unified `df.config` script if issues arise.
