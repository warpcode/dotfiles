(( $+commands[mise] )) || return 0

local mise_init
mise_init="$(mise activate zsh 2>/dev/null)" || mise_init=""
[[ -n "$mise_init" ]] || return 0

eval "$mise_init"
