
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


echo " - Installing brew-cask"
brew install brew-cask

##

##

#install some core utilities
echo " - Installing wget"
brew install wget --enable-iri

echo " - Installing coreutils"
brew install coreutils

echo " - Installing findutils"
brew install findutils

echo " - Installing git"
brew install git

echo " - Installing tree"
brew install tree

echo " - Installing tmux"
brew install tmux

echo " - Installing ack"
brew install ack

echo " - Installing lynx"
brew install lynx

echo " - Installing nmap"
brew install nmap

echo " - Installing htop (htop-osx)"
brew install htop-osx

echo " - Installing man2html"
brew install man2html


# Install the lua interpreter
echo " - Installing lua"
brew install lua

# JS interpreters
echo " - Installing ringojs"
brew install ringojs

echo " - Installing narwhal"
brew install narwhal

echo " - Installing rhino"
brew install rhino

echo " - Installing node"
brew install node

# Screenshot a website
echo " - Installing webkit2png"
brew install webkit2png


# Compression
echo " - Installing p7zip"
brew install p7zip

echo " - Installing zopfli"
brew install zopfli

echo " - Installing cabextract"
brew install cabextract

#brew cask install "dropbox" &>/dev/null

brew cleanup &>/dev/null
brew prune &>/dev/null