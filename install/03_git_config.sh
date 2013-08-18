e_header "Setting up Git configs"

git config --global --replace-all core.excludesfile "${HOME}/.gitignore_global"

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

e_success "Completed"