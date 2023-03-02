#!/usr/bin/env zsh
set -e

pushd ${0:A:h}

# Ensure dependencies are up to date
git submodule update --init

# Ensure npm is installed and run
if (( $+commands[npm] )); then
    [ -f package-lock.json ] && npm ci || npm i
else
    popd
    echo "npm is not installed"
fi

# Use stow to install dotfiles
echo "Installing dotfile"
stow -R --no-folding -t ~/ stow
