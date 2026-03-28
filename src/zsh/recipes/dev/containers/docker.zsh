pkg.define docker \
    package="docker" \
    managers="brew apt" \
    brew="docker" \
    apt="docker-ce docker-compose-plugin" \
    apt_key="https://download.docker.com/linux/ubuntu/gpg|docker.asc" \
    apt_repo="docker.asc|deb [arch=%ARCH% signed-by=%KEYRING%] https://download.docker.com/linux/ubuntu %CODENAME% stable"
