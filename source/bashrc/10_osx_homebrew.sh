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


# Homebrew autocompletion
if which brew >/dev/null 2>&1; then
  if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
  fi

  if [ -f `brew --prefix`/Library/Contributions/brew_bash_completion.sh ]; then
    . `brew --prefix`/Library/Contributions/brew_bash_completion.sh
  fi
fi