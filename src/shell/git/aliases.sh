#git shortcuts
alias g="git"
alias gs='git status'
alias gst='gs'
alias gss='git status -s'

# Adding
function ga() { git add "${@:-.}"; }
alias gap='git add --patch'

# Removing
alias grm='git rm'

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

