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
    exit 1
fi

# Ensure php is installed and run
if (( $+commands[php] )); then
    ./bin/composer install
else
    popd
    echo "php is not installed"
    exit 1
fi

# Use stow to install dotfiles
echo "Installing dotfiles"
stow -R --no-folding -t ~/ stow


echo "Install complete"
echo "Please open a new terminal"
