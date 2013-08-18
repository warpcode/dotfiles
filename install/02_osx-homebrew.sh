
[[ "$OSTYPE" =~ ^darwin ]] || return;

e_header "Setting up OSX config"

if ! require brew; then
    e_process "Homebrew not installed. Installing"
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)" 2>&1 /dev/null
fi

