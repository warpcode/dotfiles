export IS_WORK=$([ -f ~/.is_work ] && echo 1)

[ ! -n "$IS_WORK" ] && return

# Work specific config here
eval "$(/opt/homebrew/bin/brew shellenv)"
path_prepend "/opt/homebrew/opt/node@16/bin"
path_append "${DOTFILES}/bin-work"
