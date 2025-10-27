A collection of dotfiles for \*nix systems

# Description

This is my personal compilation of dotfiles that I use. It is used to set up a common environment between \*nix systems.

This project makes use of other open source projects which are listed and linked to within this readme.

This project also makes use of `git subtree` so also listed will be the commands to update these subtree's

# Features

- Automatically scans `/opt/` and `~/.local/opt/` for subdirectories containing `bin`, `sbin`, `usr/bin`, `usr/sbin`, `usr/local/bin`, and `usr/local/sbin`, and adds them to PATH, with user-local paths (`~/.local/opt/`) taking precedence over system paths (`/opt/`).

# Installation

Clone the repository and install dependencies:

```bash
git clone <repository-url> ~/.dotfiles
cd ~/.dotfiles
make install-deps  # Installs git, stow, zsh, jq, tmux, fzf, rsync, wget if needed
make install-generic  # Installs generic dotfiles
make install-work  # Installs work dotfiles (optional)
```

Supported OSes: macOS (requires Homebrew), Ubuntu, Debian, Fedora, Arch Linux.

Uninstall with `make uninstall-generic` or `make uninstall-work`.

# External Dependencies

This project uses `git submodule` to manage external dependencies.

To initialize all submodules after cloning:

    git submodule update --init --recursive

To update all submodules:

    make update-submodules

## vendor/ohmyzsh

The Oh My Zsh framework is provided by [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) as a git submodule using the `master` branch.

## src/ohmyzsh/plugins/zsh-autosuggestions

The zsh-autosuggestions plugin is provided as a git submodule in `src/ohmyzsh/plugins/zsh-autosuggestions`.

To initialize submodules after cloning:

    git submodule update --init --recursive

To update zsh-autosuggestions:

    git submodule update --remote src/ohmyzsh/plugins/zsh-autosuggestions

This plugin is loaded via the Oh My Zsh config in `src/zsh/config/50-oh-my-zsh.zsh` using the `$DOTFILES` variable and `$ZSH_CUSTOM` path.

