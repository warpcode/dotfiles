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

function brcl(){
    br cleanup
    br prune
}


#function install_homebrew(){

#}


#function uninstall_homebrew(){

#}