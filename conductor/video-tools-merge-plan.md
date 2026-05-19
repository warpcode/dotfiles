# Plan: Merge Video Processing Suite

## Objective
Consolidate the fragmented `video-*` processing scripts into a single, unified multi-call binary (e.g., `bin/video`). This will reduce `$PATH` pollution, centralize shared logic (like hardware detection and temporary file management), and provide a more discoverable CLI experience via subcommands.

## Key Files & Context
- **Target File**: `bin/video` (New)
- **Source Files to Remove**: 
  - `bin/video-detect-crop`
  - `bin/video-detect-gpu`
  - `bin/video-detect-scale`
  - `bin/video-detect-valid`
  - `bin/video-encode`
  - `bin/video-encode-dir`
  - `bin/video-filter-streams`
  - `bin/video-find-all`
  - `bin/video-list-to-chapters`
  - `bin/video-list-to-input`

## Implementation Steps
1. **Create the Base Structure**: Create `bin/video` using bash. Implement a subcommand routing mechanism (e.g., a `case` statement mapping `$1` to internal functions like `cmd_encode`).
2. **Migrate Shared Logic**: Extract common environment checks, hardware detection (`video-detect-gpu`), and validation routines into top-level helper functions within `bin/video`.
3. **Migrate Subcommands**: Port the core logic of each `video-*` script into its corresponding `cmd_<subcommand>` function.
    - `encode` -> `cmd_encode`
    - `encode-dir` -> `cmd_encode_dir`
    - `detect-crop` -> `cmd_detect_crop`
    - `detect-scale` -> `cmd_detect_scale`
    - etc.
4. **Refactor Inter-dependencies**: Currently, scripts like `video-encode` call other scripts like `${0%/*}/video-detect-gpu`. Update these to call the new internal helper functions directly instead of spawning subshells for external scripts.
5. **Update Help/Usage**: Create a comprehensive `_usage` function documenting all available subcommands and their options.
6. **Cleanup**: Delete the old `video-*` scripts from the `bin/` directory.

## Verification & Testing
- Run `video --help` to ensure the router functions correctly.
- Test hardware detection: `video detect-gpu`
- Test validation: `video detect-valid <test_file>`
- Perform a test encode using `video encode` and `video encode-dir` to ensure the complex ffmpeg argument building and inter-script dependencies were ported successfully.

## Migration & Rollback
- **Rollback**: If issues are found, the `git checkout` command can restore the original `video-*` scripts and remove the new `bin/video` file.
