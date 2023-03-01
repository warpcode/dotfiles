#!/usr/bin/env zsh
set -e
shopt -s extglob

# Use stow to install dotfiles
for dir in work; do
    stow -R --no-folding -t ~/ "$dir"
done;
