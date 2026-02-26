# Python Configuration
# Determine the Python command to use, preferring python3 over python

# Python command selection
if (( $+commands[python3] )); then
    export _W_PYTHON_COMMAND="${_W_PYTHON_COMMAND:-python3}"
elif (( $+commands[python] )); then
    export _W_PYTHON_COMMAND="${_W_PYTHON_COMMAND:-python}"
fi

# Return if _W_PYTHON_COMMAND is not set
[[ -z "$_W_PYTHON_COMMAND" ]] && return

alias python.http="mise exec python@latest -- python -m http.server"

# Function to activate a Python virtual environment
# Usage: vrun [venv_path]
function python.vrun() {
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

# Function to automatically load Python venv when changing directories
function python.load-venv {
    local venv_path="$(fs.find.root .venv)"

    if [ -n "$venv_path" ]; then
        python.vrun "$venv_path"
    elif [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating virtual environment: $VIRTUAL_ENV"
        deactivate
    fi
}

# Set up automatic venv loading on directory change
#autoload -U add-zsh-hook
#add-zsh-hook chpwd python.load-venv
#python.load-venv
