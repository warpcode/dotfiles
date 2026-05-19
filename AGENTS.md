# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-21 17:31:30
**Commit:** a1d2a0f5
**Branch:** master

## OVERVIEW
Modular *nix dotfiles ecosystem using GNU Stow for symlink management and a highly granular Zsh configuration. Integrates custom AI tooling (OpenCode, Gemini) and a multi-platform package installer.

## STRUCTURE
```
.
├── generic/       # Stow targets (generic configuration files)
│   ├── .config/   # App-specific configs (OpenCode, Gemini, etc.)
│   └── .zshrc     # Bootstrap loader for src/zsh/init.zsh
├── src/zsh/       # Core modular Zsh configuration
│   ├── apps/      # Application-specific Zsh modules
│   ├── config/    # Numbered Zsh config files (01-99)
│   ├── functions/ # Core Zsh utilities and installer
│   ├── projects/  # Project-specific aliases/workflows
│   └── recipes/   # Cross-platform package recipes
├── .opencode/     # OpenCode command definitions (NPM-based)
├── .specify/      # Skill management and refactoring system
├── bin/           # Custom utility scripts (video, git, etc.)
├── work/          # Work-specific stow targets
└── Makefile       # Installation entry point
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add new alias | `src/zsh/config/` | Use existing numbered files or add new |
| Configure app | `src/zsh/apps/` | Create `{app}.zsh` |
| Add package | `src/zsh/recipes/` | Add recipe for `zinstall` |
| Edit AI skills | `generic/.config/opencode/skill/` | STM format preferred |
| Add package | `src/zsh/recipes/` | Add recipe for `pkg.install` |

## CONVENTIONS
- **Stow Categories**: Files live in `generic/` or `work/` to be stowed to `$HOME`.
- **Bootstrap Pattern**: `~/.zshrc` is a minimal loader; logic lives in `src/zsh/init.zsh`.
- **Load Order**: Zsh configs in `src/zsh/config/` use `XX-name.zsh` for explicit ordering.
- **Package Management**: Use `pkg.install` (defined in `src/zsh/functions/pkg.zsh`) for cross-platform dependencies.
- **AI Tooling**: Distinguish between `.opencode/` (commands) and `generic/.config/opencode/` (runtime skills/agents).

## ANTI-PATTERNS (THIS PROJECT)
- **Direct Home Edit**: NEVER edit stowed files in `$HOME`; edit them in `generic/` or `work/`.
- **Manual Apt/Brew**: Avoid direct `apt install` or `brew install` in scripts; use `pkg.install`.
- **Hardcoded Paths**: Use `$DOTFILES` variable to refer to the repository root.
- **Non-Modular Zsh**: Do not add large blocks of config directly to `init.zsh`.

## UNIQUE STYLES
- **Telegraphic Markdown**: AI skills and documentation use Structured Telegraphic Markdown (STM) for token efficiency.
- **Lazy Loading**: Environment variables and heavy configs are lazy-loaded to keep shell startup fast.

## COMMANDS
```bash
make install-generic   # Install generic dotfiles
make install-work      # Install work + generic dotfiles
pkg.install <package>     # Install a package via modular recipes
```

## NOTES
- The project is undergoing a skill refactoring in `.specify/` to reduce AI token usage.
- `vendor/ohmyzsh` is a git submodule; ensure it's initialized.
