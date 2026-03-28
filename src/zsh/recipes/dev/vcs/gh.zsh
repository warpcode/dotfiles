pkg.define gh \
    package="gh" \
    managers="brew apt" \
    apt_key="https://cli.github.com/packages/githubcli-archive-keyring.gpg|githubcli-archive-keyring.gpg" \
    apt_repo="githubcli-archive-keyring.gpg|deb [arch=%ARCH% signed-by=%KEYRING%] https://cli.github.com/packages stable main"
