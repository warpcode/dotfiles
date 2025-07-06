(( $+commands[git] )) || return

# Ensure the defaults are loaded
git config --global include.path "~/.gitconfig_default"
