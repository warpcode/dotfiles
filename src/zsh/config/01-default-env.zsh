# XDG
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"


# Setup default editor
if [[ -z "$EDITOR" ]]; then
    if (( $+commands[nvim] )); then
        export EDITOR=nvim
    elif (( $+commands[vim] )); then
        export EDITOR=vim
    else
        export EDITOR=nano
    fi
fi

# Execute last command
alias r="fc -s"


# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
