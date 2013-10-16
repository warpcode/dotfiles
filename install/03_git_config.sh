e_header "Setting up Git configs"



if [[ $(git config --global user.name) == '' ]]; then
    while true; do
        echo "Please enter the name to use for git:"
        read username
        if [[ ! $username == "" ]]; then
            git config --global user.name "$username"
            break;
        fi
    done
fi

if [[ $(git config --global user.email) == '' ]]; then
    echo "Please enter the email to use for git:":
    read email
    if [[ ! $email == "" ]]; then
        git config --global user.email "$email"
        break;
    fi
fi

echo ' - Configuring core options'
git config --global core.autocrlf "input"
git config --global core.whitespace "trailing-space"
git config --global --replace-all core.excludesfile "${HOME}/.gitignore_global"
git config --global apply.whitespace "fix"

echo " - Configuring aliases"
git config --global alias.br "branch"
git config --global alias.ci "commit"
git config --global alias.co "checkout"
git config --global alias.df "diff"
git config --global alias.g "grep -I"
git config --global alias.lg "log -p"
git config --global alias.st "status"


echo ' - Configuring master branch default'
git config --global branch.master.remote "origin"
git config --global branch.master.merge "refs/heads/master"

echo ' - Configuring colours'
git config --global color.ui "auto"

git config --global color.branch.current "yellow reverse"
git config --global color.branch.local "yellow"
git config --global color.branch.remote "green"

git config --global color.diff.meta "yellow bold"
git config --global color.diff.frag "green bold"
git config --global color.diff.old "red bold"
git config --global color.diff.new "cyan bold"

git config --global color.status.added "yellow"
git config --global color.status.changed "green"
git config --global color.status.untracked "cyan"



echo " - Completed"
