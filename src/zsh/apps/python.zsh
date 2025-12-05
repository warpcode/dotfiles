# Python Configuration
# Determine the Python command to use, preferring python3 over python

# Return if _W_PYTHON_COMMAND is not set
[[ -z "$_W_PYTHON_COMMAND" ]] && return

# Aliases using the detected Python command
alias ipython="$_W_PYTHON_COMMAND -c 'import IPython; IPython.terminal.ipapp.launch_new_instance()'"
alias pyserver="$_W_PYTHON_COMMAND -m http.server"

# Function to activate a Python virtual environment
# Usage: vrun [venv_path]
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

# Function to automatically load Python venv when changing directories
function load-venv {
    local venv_path="$(_fs_find_parent_path .venv)"

    if [ -n "$venv_path" ]; then
        vrun "$venv_path"
    elif [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating virtual environment: $VIRTUAL_ENV"
        deactivate
    fi
}

# Set up automatic venv loading on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd load-venv
load-venv
