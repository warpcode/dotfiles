[[ "$OSTYPE" =~ ^darwin ]] || return 1


alias br="brew"
alias brc="br cleanup"
alias brpr="br prune"
alias bri="br install"
alias brrm="br uninstall"
alias brls="br list"
alias brs="br search"
alias brinf="br info"
alias brdr="br doctor"
alias bro="br outdated"

# Cleanup routine
function brcl(){
    brew cleanup && brew prune
}

# Check if a keg is installed
function brex(){
    brew list | grep -q "\b$@\b" || { return 1;}
}


# Link Homebrew casks in `/Applications` rather than `~/Applications`
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
