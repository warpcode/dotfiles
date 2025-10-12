#!/bin/bash

# Script to install dependencies for dotfiles across multiple OSes
# Requires: git, stow, zsh (pre-installed on macOS), jq, tmux, fzf, rsync, wget
# On macOS, assumes Homebrew is installed

set -e

# Common packages to install
packages=(git stow zsh jq tmux fzf rsync wget)

echo "Detecting OS..."

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "macOS detected. Installing with Homebrew (assumes Homebrew is installed)..."
  brew install "${packages[@]}"
elif [[ -f /etc/os-release ]]; then
  . /etc/os-release
  echo "Linux detected: $ID"
  case $ID in
    ubuntu|debian)
      sudo apt update && sudo apt install -y "${packages[@]}"
      ;;
    fedora)
      sudo dnf install -y "${packages[@]}"
      ;;
    arch)
      sudo pacman -Syu --noconfirm "${packages[@]}"
      ;;
    *)
      echo "Unsupported Linux distribution: $ID"
      exit 1
      ;;
  esac
else
  echo "Cannot detect OS. Please install git, stow, zsh manually."
  exit 1
fi

echo "Dependencies installed successfully."