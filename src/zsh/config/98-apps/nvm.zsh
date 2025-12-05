if [[ -z "$NVM_DIR" ]]; then
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
    elif [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/nvm" ]]; then
        export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    elif (( $+commands[brew] )); then
        NVM_HOMEBREW="${NVM_HOMEBREW:-${HOMEBREW_PREFIX:-$(brew --prefix)}/opt/nvm}"
        if [[ -d "$NVM_HOMEBREW" ]]; then
            export NVM_DIR="$NVM_HOMEBREW"
        fi
    fi
fi