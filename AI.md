# AI Assistant Guidelines for this Repository

This document provides guidance for an AI assistant interacting with this repository. It outlines the project's purpose, key technologies, and how the AI should approach suggestions and code modifications.

## Project Overview

This repository serves as a personal collection of dotfiles and utility scripts, primarily focused on enhancing a developer's command-line and development environment on Unix-like systems. It's structured to be managed with `GNU Stow` (implied by `.stow-local-ignore`), allowing for symbolic linking of configuration files into the home directory.

The core components include:
*   **Zsh Configuration:** A highly customized Zsh setup, leveraging `Oh My Zsh` and a modular structure (`src/zsh/`). The loading mechanism is defined in `src/zsh/init.zsh` and follows a specific order, allowing for user overrides. Key concepts to be aware of include:
    *   **`~/.env` file:** For loading sensitive or machine-specific environment variables.
    *   **Core Modules:** The main configuration is sourced from `src/zsh/{functions,config,apps,projects}/*.zsh`.
    *   **User Overrides:** The system supports user-specific configurations in `~/.zshrc.before.d/`, `~/.zshrc.d/`, and `~/.zshrc.{functions,config,apps,projects}/`. New functionality should respect this override system.
*   **Utility Scripts:** A collection of shell scripts (`bin/`, `bin-old/`) for various tasks, including media processing (ffmpeg), image optimization, Git utilities, Docker management, web scraping, and general system administration.
*   **Editor Configuration:** Neovim configuration.
*   **Terminal Multiplexer:** Tmux configuration.
*   **Fonts:** Nerd Fonts for enhanced terminal aesthetics.
*   **Work-specific Overrides:** Separate configurations for a work environment, allowing for easy switching or layering of settings.

The goal is to maintain a consistent, efficient, and personalized development environment across different machines.

## Key Technologies and Concepts

The repository heavily relies on the following technologies and concepts:

*   **Shell:** Zsh (primary shell), Bash (for some utility scripts).
*   **Configuration Management:** GNU Stow (for dotfile management).
*   **Version Control:** Git.
*   **Terminal Multiplexer:** Tmux.
*   **Text Editor:** Neovim.
*   **Shell Framework:** Oh My Zsh.
*   **Command-line Tools:** FZF (fuzzy finder), Rsync, Sudo, SSH.
*   **Programming Languages/Runtimes:** Python, Node.js (via NVM).
*   **Media Processing:** FFmpeg (used extensively in `bin/` scripts).
*   **Image Processing:** Tools for image optimization.
*   **Docker:** Scripts for Docker user management.
*   **Nerd Fonts:** For rich terminal display.

## AI Interaction Guidelines

When providing suggestions or generating code, please adhere to the following principles:

1.  **Contextual Awareness:** Understand that this is a dotfiles repository. Solutions should generally be command-line oriented, shell-script based, or configuration file modifications.
2.  **Prioritize Zsh:** For shell-related tasks, assume Zsh as the primary shell unless explicitly stated otherwise. Leverage Zsh-specific features where appropriate (e.g., `src/zsh/functions/`, `src/zsh/apps/`).
3.  **Modularity:** When adding new Zsh configurations or functions, place them in the appropriate subdirectory within `src/zsh/` (`apps`, `config`, `functions`, etc.). Be mindful of the loading order defined in `src/zsh/init.zsh` and the user override directories (`~/.zshrc.d/`, etc.).
4.  **Stow Compatibility:** If suggesting new dotfiles, consider how they would integrate with a `stow`-managed setup (e.g., placing them in appropriate top-level directories like `generic/` or `work/`).
5.  **Scripting Focus:** Many tasks are handled by custom scripts in `bin/` and `bin-old/`. When suggesting new functionality, consider if it fits within an existing script or warrants a new one in `bin/`.
6.  **Read-Only Files:** Remember the list of files provided as "read-only." Do not propose changes to these files without explicit instruction to "add them to the chat" first.
7.  **Clarity and Conciseness:** Provide clear, actionable suggestions and code.
8.  **Security:** Be mindful of security implications, especially when dealing with `sudo`, SSH, or network configurations.
9.  **Cross-Platform (Implicit):** While primarily Unix-focused, consider general shell best practices that might allow for broader compatibility where reasonable, though Zsh-specific solutions are preferred for core dotfiles.
10. **Explain Rationale:** Always explain *why* a change is being suggested and how it aligns with the project's goals or existing structure.
11. **Avoid Running README Commands:** Do not suggest executing commands found in the `README.md` directly. These commands often contain placeholders (e.g., `<repository-url>`) or assume a specific directory structure (e.g., `~/dotfiles`) that may not match the user's actual environment. Treat them as illustrative examples, not as literal commands to be run.
