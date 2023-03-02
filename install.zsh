#!/usr/bin/env zsh
set -e

# Ensure dependencies are up to date
git submodule update --init

# Use stow to install dotfiles
stow -R --no-folding -t ~/ stow
