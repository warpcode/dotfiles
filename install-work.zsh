#!/usr/bin/env zsh
set -e

source ${0:A:h}/install.zsh

# Use stow to install dotfiles
for dir in work; do
    stow -R --no-folding -t ~/ "$dir"
done;
