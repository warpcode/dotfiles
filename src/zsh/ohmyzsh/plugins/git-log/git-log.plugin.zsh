# Logs
alias gl1='git log --decorate --oneline --graph --date-order --all'
alias gl2="git log --graph --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(bold white)— %an%C(reset)%C(bold yellow)%d%C(reset)' --abbrev-commit --date=relative"
alias gl3="git log --graph --all --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(bold white)— %an%C(reset)' --abbrev-commit"
alias gl4="git log --graph --all --date=short --pretty=format:'%C(yellow)%h%x20%C(white)%cd%C(green)%d%C(reset)%x20%s%x20%C(bold)(%an)%Creset'"
