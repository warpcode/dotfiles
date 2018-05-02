# Execute last command
alias r="fc -s"

# Shortcut to view the history
alias h="history"

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Common rsync I use
alias rsyncc="rsync -vhrlptD --progress"

# Reload the bashrc file
alias reload="source ~/.bashrc && echo Bash config reloaded"

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'

# Improved WHOIS lookups
alias whois="whois -h whois-servers.net"

# OSX flush dns cache
[[ "$OSTYPE" =~ ^darwin ]] && alias dnsflush="dscacheutil -flushcache && killall -HUP mDNSResponder"


#######################
# Easier navigation
#######################
s_name=""
s_exec="cd "

for i in {1..10}; do
    # This may be overkill but covers a lot of traversal
    s_name="${s_name}.."
    s_exec="${s_exec}../"
    alias "${s_name}"="${s_exec}"
done

alias ~="cd ~"
alias -- -="cd -"


#######################
# Shortcuts
#######################
alias desktop="cd ~/Desktop"
alias downloads="cd ~/Downloads"
alias home="cd ${HOME}"
alias cddotfiles="cd ~/.dotfiles"

#######################
# MacOS
#######################
if [[ "$OSTYPE" =~ ^darwin ]]
then

    # Start the screensaver
    alias ss="open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"

    if [[ -d "/Applications/Xcode.app" ]]; then
        #iOS Simulator quick launch
        alias iossim="open \"/Applications/Xcode.app/Contents/Applications/iPhone Simulator.app\""
    fi


    # Change working directory to the top-most Finder window location
    function cdfinder() {
    	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
    }
fi
