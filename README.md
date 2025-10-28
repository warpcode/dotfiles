# Dotfiles

This is a personal collection of dotfiles for \*nix systems, designed to create a consistent and powerful command-line experience across multiple machines. It uses `stow` for managing symlinks and comes with a `Makefile` for easy installation and dependency management.

## Features

This dotfiles repository comes with a wide range of features to enhance your shell environment:

-   **Modular Zsh Configuration:** The Zsh configuration is organized into `config`, `functions`, `apps`, and `projects` directories, making it easy to extend and manage.
-   **Cross-Platform Support:** An installation script is provided to install dependencies on macOS, Debian/Ubuntu, Fedora, and Arch Linux.
-   **Oh My Zsh Integration:** Includes the popular [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) framework for themes and plugins.
-   **AI Command-Line Tools:** A suite of aliases is provided for interacting with various AI services directly from the command line, including:
    -   `ai.chat`: A wrapper for the `aichat` tool.
    -   `ai.code` / `ai.opencode`: For code generation with OpenCode.
    -   `ai.crush`: To use the crush.dev CLI.
    -   `ai.gemini`: To use the Google Gemini CLI.
-   **Automatic Python Virtualenv:** Automatically activates and deactivates Python virtual environments (`.venv`) as you navigate your filesystem.
-   **Project-Specific Workflows:** The `src/zsh/projects` directory allows you to define aliases and functions to streamline workflows for your individual projects.
-   **FZF Integration:** Integrates [fzf](https://github.com/junegunn/fzf) for powerful fuzzy history search.
-   **Neovim Management:** Includes helper functions for checking for updates and installing specific versions of Neovim.
-   **Automatic PATH management:** Automatically scans `/opt/` and `~/.local/opt/` for subdirectories containing `bin`, `sbin`, `usr/bin`, `usr/sbin`, `usr/local/bin`, and `usr/local/sbin`, and adds them to PATH.

## Installation

1.  Clone the repository:
    ```bash
    git clone <repository-url> ~/.dotfiles
    cd ~/.dotfiles
    ```

2.  Install dependencies:
    ```bash
    make install-deps
    ```
    This will install `git`, `stow`, `zsh`, `jq`, `tmux`, `fzf`, `rsync`, and `wget` if they are not already installed.

3.  Install the dotfiles:
    ```bash
    make install-generic
    ```
    This will create symlinks for the generic configuration files in your home directory.

4.  (Optional) Install work-specific dotfiles:
    ```bash
    make install-work
    ```

To uninstall, you can use `make uninstall-generic` or `make uninstall-work`.

## External Dependencies

This project uses `git submodule` to manage external dependencies.

-   **[ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh):** The Oh My Zsh framework.
-   **[zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions):** A plugin for Zsh that provides command suggestions.

To initialize all submodules after cloning, run:
```bash
git submodule update --init --recursive
```

To update all submodules to their latest versions, run:
```bash
make update-submodules
```

