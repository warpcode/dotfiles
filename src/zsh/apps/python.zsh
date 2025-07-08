if (( $+commands[python3] )); then
    export _W_PYTHON_COMMAND=python3
elif (( $+commands[python] )); then
    export _W_PYTHON_COMMAND=python
else
    return
fi

# Run proper IPython regarding current virtualenv (if any)
alias ipython="$_W_PYTHON_COMMAND -c 'import IPython; IPython.terminal.ipapp.launch_new_instance()'"

# Share local directory as a HTTP server
alias pyserver="$_W_PYTHON_COMMAND -m http.server"

# Activate a venv
function vrun() {
    local venvpath="${1:-.venv}"
    local name="$(basename "${1}")"

    if [ -n "$VIRTUAL_ENV" ]; then
        if [[ "$VIRTUAL_ENV" != "$venvpath" ]]; then
            echo "Deactivating virtual environment: $VIRTUAL_ENV"
            deactivate
        else
            return 0
        fi
    fi

    if [[ ! -d "$venvpath" ]]; then
        return 1
    fi

    if [[ ! -f "${venvpath}/bin/activate" ]]; then
        echo >&2 "Error: '${name}' is not a proper virtual environment"
        return 1
    fi

    . "${venvpath}/bin/activate" || return $?
    echo "Activated virtual environment ${VIRTUAL_ENV}"
}

# Autoload python venv
function load-venv {
    # Find the nearest parent directory where the .venv exists
    local venv_path="$(find_parent_path .venv)"

    if [ -n "$venv_path" ]; then
        vrun "$venv_path"
    elif [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating virtual environment: $VIRTUAL_ENV"
        deactivate
    fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd load-venv
