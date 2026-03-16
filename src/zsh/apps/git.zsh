
alias git.zip="git.cli archive --format=zip HEAD ':!*.gitignore' -o ${PWD##*/}.zip"

# Ensure the defaults are loaded
function _git_clone_and_cd() {
    if [[ -z "$1" ]]; then
        echo "Please provide a valid git url"
        return 1
    fi

    ## check if the second parameter is a directory
    if [[ -z "$2" ]]; then
        local dir_name=$(basename "$1" .git)
    else
        local dir_name="$2"
    fi

    # If the destination dir doesn't exist, clone the repo
    if [[ ! -d "$dir_name" ]]; then
        git clone --depth 1 --recurse-submodules "$1" "$dir_name"
    fi

    # cd to the directory and then open in nvim
    cd "$dir_name" || { echo "Failed to change directory to '$dir_name'"; return 1; }
}

function git.cli() {
    pkg.exec git "$@"
}

function git.setup() {
    pkg.exec git config --global include.path "$(fs.dotfiles.path "assets/configs/git/.gitconfig_default")"
    pkg.exec git config --global core.excludesfile "$(fs.dotfiles.path "assets/configs/git/.gitignore_global")"
}
events.add dotfiles.setup git.setup

