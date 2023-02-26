#!/usr/bin/env bash
set -e
shopt -s extglob

# Ensure dependencies are up to date

# Use stow to install dotfiles
for file in */.stow; do
    stow -R --no-folding --ignore=.stow -t ~/ "$(dirname $file)"
done;
unset file;
