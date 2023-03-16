if ! (( $+commands[brew] )); then
    return
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
