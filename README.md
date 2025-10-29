# Dotfiles

This is a personal collection of dotfiles for \*nix systems, designed to create a consistent and powerful command-line experience across multiple machines. It uses `stow` for managing symlinks and comes with a `Makefile` for easy installation and dependency management.

## Requirements

The following dependencies are required and will be installed automatically by the installer:

- **git** - Version control
- **stow** - Symlink management
- **zsh** - Shell (pre-installed on macOS)
- **jq** - JSON processor
- **wget** - HTTP downloader
- **curl** - HTTP client

Additional tools like `fzf`, `uv`, `tmux`, and `rsync` can be installed using the dotfiles installer.

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
-   **Neovim Support:** Includes Neovim in the automatic package installation system.
-   **Automatic PATH management:** Automatically scans `/opt/` and `~/.local/opt/` for subdirectories containing `bin`, `sbin`, `usr/bin`, `usr/sbin`, `usr/local/bin`, and `usr/local/sbin`, and adds them to PATH.
-   **GitHub Release Installer:** Automatically downloads and installs applications directly from GitHub releases. Supports OS and architecture detection, version management, and creates executable symlinks in a `bin/` directory. Configurable installation directory via `INSTALLER_OPT_DIR` environment variable (defaults to `~/.local/opt`).

## Installation

1.  Clone the repository:
    ```bash
    git clone <repository-url> ~/.dotfiles
    cd ~/.dotfiles
    ```

2.  Install the dotfiles:
    ```bash
    make install-generic
    ```
    This will create symlinks for the generic configuration files in your home directory. Required dependencies will be installed automatically when you start a new Zsh session.

3.  (Optional) Install work-specific dotfiles:
    ```bash
    make install-work
    ```

To uninstall, you can use `make uninstall-generic` or `make uninstall-work`.

### Installing Applications from GitHub Releases

The installer supports downloading applications directly from GitHub releases with automatic OS and architecture detection:

1. Register a GitHub release in your app configuration:
   ```zsh
   _installer_package "github" "fzf" "junegunn/fzf@v0.66.1"
   _installer_package "github" "uv" "astral-sh/uv@latest"
   ```

2. Install all registered packages:
   ```zsh
   _installer_install
   ```

This will:
- Download the appropriate `.tar.gz` asset for your OS and architecture
- Extract it to `~/.local/opt/appname/` (configurable via `INSTALLER_OPT_DIR`)
- Automatically flatten top-level directories containing `bin/`, `sbin/`, `usr/`, or `lib/`
- Create symlinks to all executable files in `bin/` for PATH access
- Track versions in `.version` files to avoid unnecessary re-downloads

Supported formats: Currently `.tar.gz` archives. The system detects Linux/macOS and x86_64/aarch64 architectures, with fallback patterns for common naming variations.

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

## Troubleshooting

### Dependencies not installing?
- Ensure your OS is supported (macOS, Debian/Ubuntu, Fedora, Arch Linux)
- Check that you have `sudo` access for system package installation
- For GitHub releases, ensure `curl` and `tar` are available

### Conflicts with existing configuration?
- The dotfiles use `stow` to manage symlinks, which won't overwrite existing files
- Check for conflicts in `~/.zshrc`, `~/.gitconfig`, etc.
- User overrides can be added to `~/.zshrc.d/` or `~/.zshrc.{functions,config,apps,projects}/`

### Customizing the setup
- Add personal aliases/functions to `~/.zshrc.d/`
- Override app configurations in `~/.zshrc.apps/`
- Add project-specific settings to `~/.zshrc.projects/`
- Modify `INSTALLER_OPT_DIR` to change where GitHub releases are installed

## Customization

### Adding new applications
Create a new file in `src/zsh/apps/yourapp.zsh`:
```zsh
# Register packages
_installer_package "default" yourapp

# Add app-specific configuration
alias youralias="yourapp --option"
```

### Project-specific configurations
Add files to `src/zsh/projects/yourproject.zsh` for project-specific aliases and functions.

### Overriding settings
Any file in `~/.zshrc.d/` will be sourced after the main configuration, allowing you to override or add settings.

