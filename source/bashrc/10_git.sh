#git shortcuts
alias g="git"
alias gs='git status'
alias gst='gs'

# Adding
function ga() { git add "${@:-.}"; }
alias gap='git add --patch'

# Branches
alias gb='git branch'
alias gba='git branch -a'
function gbc(){
    # Get the current git branch
    git branch 2> /dev/null | grep '*' | sed 's/^* //'
}

# Checkout
function gch() { git checkout "${@:-master}"; }
function gchb() { git checkout -b "${@:-master}"; }

# Clone
alias gcl='git clone'

# Commit
alias gc="git commit"
alias gcm='gc -m'
alias gcma='gc -am'

# Diff
alias gd='git diff'
alias gdc='git diff --cached'

# Pull
alias gu='git pull'
alias gur='gu --rebase'

# Push
alias gp='git push'
alias gpa="gp --all"

# Remote
alias gra='git remote add'
alias grr='git remote rm'

# Git ignore generation
function gi() { curl "http://gitignore.io/api/$@" ;}

# Logs
alias gl='git log'
alias gl1='gl --decorate --oneline --graph --date-order --all'
alias gl2="gl --graph --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold white)— %an%C(reset)%C(bold yellow)%d%C(reset)' --abbrev-commit --date=relative"
alias gl3="gl --graph --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(bold white)— %an%C(reset)' --abbrev-commit"
alias gl4="gl --graph --all --date=short --pretty=format:'%C(yellow)%h%x20%C(white)%cd%C(green)%d%C(reset)%x20%s%x20%C(bold)(%an)%Creset'"


#auto update logs
alias gl1live="while true; do clear; gl1 -40 | cat -; sleep 15; done"
alias gl2live="while true; do clear; gl2 -40 | cat -; sleep 15; done"
alias gl3live="while true; do clear; gl3 -40 | cat -; sleep 15; done"
alias gl3live="while true; do clear; gl4 -40 | cat -; sleep 15; done"