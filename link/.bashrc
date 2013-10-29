#!/usr/bin/env bash

# Exit now if we're not in interactive mode
[ -z "$PS1" ] && return;

# Load in dotfiles scripts
for file in ~/.dotfiles/source/bashrc/*/*; do
  source "$file"
done

# Load in dotfiles scripts
for file in ~/.dotfiles/source/bashrc/*; do
  if [ -f $file ]; then
      source "$file"
  fi
done

# Custom bashrc file
if [ -f ~/.bashrc_custom ]; then
  source ~/.bashrc_custom
fi

# If you just need to add some aliases
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

