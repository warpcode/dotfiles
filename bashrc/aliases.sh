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

    #Create aliases for mamp
    for f in /Applications/MAMP/bin/php/*; do
        f=`basename "$f"`

        if [[ -f /Applications/MAMP/bin/php/${f}/bin/php ]]; then
            alias "mamp_${f}"="/Applications/MAMP/bin/php/${f}/bin/php"
        fi
    done;
fi

#######################
# Misc
#######################
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
