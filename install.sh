#!/usr/bin/env bash
set -e
shopt -s extglob

# Ensure dependencies are up to date
git submodule update --init

# Use stow to install dotfiles
for dir in home bin; do
    stow -R --no-folding -t ~/ "$dir"
done;
