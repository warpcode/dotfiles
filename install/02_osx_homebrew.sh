
[[ "$OSTYPE" =~ ^darwin ]] || return;

e_header "Setting up OSX config"

# Check whether a keg is installed
function _brew_installed(){
    brew list | grep -q "\b$@\b" || { return 1;}
}

# Standard install procedure. Special installs occur manually
function _brew_std_install(){
    if ! _brew_installed "$@" ; then
         e_process "Installing $@"
         if ! brew install "$@" &>/dev/null ; then 
             e_error "Failed to install $@"
             exit 1;  
         fi
    else
        e_process "$@ already installed"
    fi
}

if ! require brew; then
    e_process "Homebrew not installed. Installing"
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)" &>/dev/null
else
    e_process "Updating homebrew install"
    brew update &>/dev/null
fi

e_process "Installing taps"
brew tap homebrew/dupes &>/dev/null
brew tap homebrew/versions &>/dev/null
brew tap phinze/homebrew-cask &>/dev/null



if ! _brew_installed "wget" ; then
     e_process "Installing wget"
     if ! brew install wget --enable-iri &>/dev/null ; then 
         e_error "Failed to install wget"
         exit 1;  
     fi
else
    e_process "wget already installed"
fi


_brew_std_install "findutils"
_brew_std_install "brew-cask"

brew cask install "dropbox" &>/dev/null

brew cleanup &>/dev/null
brew prune &>/dev/null