
[[ "$OSTYPE" =~ ^darwin ]] || return;

e_header "Setting up OSX Homebrew"



if ! require brew ; then
    echo " - Homebrew not installed. Installing"
    ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)" &>/dev/null
else
    echo " - Updating homebrew install"
    brew update &>/dev/null
fi

echo " - Installing taps"
brew tap homebrew/dupes &>/dev/null
brew tap homebrew/versions &>/dev/null
brew tap phinze/homebrew-cask &>/dev/null




echo " - Installing wget"
brew install wget --enable-iri

echo " - Installing findutils"
brew install findutils

echo " - Installing brew-cask"
brew install brew-cask

echo " - Installing git"
brew install git

echo " - Installing tree"
brew install tree
#brew cask install "dropbox" &>/dev/null

brew cleanup &>/dev/null
brew prune &>/dev/null