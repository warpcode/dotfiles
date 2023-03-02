#!/usr/bin/env zsh

TARGET_DIR="$(dirname ${0:A:h})/bin"

wget https://getcomposer.org/download/latest-stable/composer.phar -O "$TARGET_DIR/composer" -q
chmod +x "$TARGET_DIR/composer"
