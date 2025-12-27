# Technology Stack

## Core Languages
- **Zsh:** The primary shell and configuration language.
- **Bash:** Used for auxiliary scripts and broader compatibility.
- **Python:** Supported for AI tools and managed via automatic virtual environment activation (`uv`).
- **Make:** Used for installation, dependency management, and high-level project tasks.

## Frameworks and Tools
- **Oh My Zsh:** Provides the foundation for themes and plugin management.
- **GNU Stow:** Manages symlinks for dotfiles in a clean and reversible manner.
- **Git:** Version control and submodule management for external dependencies.

## Key Dependencies
- **fzf:** Fuzzy finder for history search and file navigation.
- **jq:** JSON processor for configuration and API responses.
- **curl / wget:** Used by the installer for downloading assets and interacting with web services.
- **uv:** Fast Python package installer and resolver.
- **tmux:** Terminal multiplexer for persistent sessions.

## Architecture
- **Modular Zsh Configuration:** Organized into `config/`, `functions/`, `apps/`, and `projects/`.
- **Custom Application Installer:** A robust system for installing system packages and GitHub releases with version tracking.
- **AI/Agentic Tooling:** Custom wrappers and aliases for integrating various AI CLIs (OpenCode, Gemini, etc.).
