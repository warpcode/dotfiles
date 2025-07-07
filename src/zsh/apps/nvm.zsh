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

# Don't try to load nvm if command already available
# Note: nvm is a function so we need to use `which`
which nvm &>/dev/null && return

if [[ -f "$NVM_DIR/nvm.sh" ]]; then
    # Load nvm if it exists in $NVM_DIR
    source "$NVM_DIR/nvm.sh"
else
    return
fi

# Autoload .nvmrc
function load-nvmrc {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [[ -n "$nvmrc_path" ]]; then
        local nvmrc_node_version=$(nvm version $(cat "$nvmrc_path" | tr -dc '[:print:]'))

        if [[ "$nvmrc_node_version" = "N/A" ]]; then
            nvm install
        elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
            nvm use 
        fi
    elif [[ "$node_version" != "$(nvm version default)" ]]; then
        echo "Reverting to nvm default version"
        nvm use default $nvm_silent
    fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Load nvm bash completion
for nvm_completion in "$NVM_DIR/bash_completion" "$NVM_HOMEBREW/etc/bash_completion.d/nvm"; do
    if [[ -f "$nvm_completion" ]]; then
        # Load bashcompinit
        autoload -U +X bashcompinit && bashcompinit
        # Bypass compinit call in nvm bash completion script. See:
        # https://github.com/nvm-sh/nvm/blob/4436638/bash_completion#L86-L93
        ZSH_VERSION= source "$nvm_completion"
        break
    fi
done

unset NVM_HOMEBREW nvm_completion
