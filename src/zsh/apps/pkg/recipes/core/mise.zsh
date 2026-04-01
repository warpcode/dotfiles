pkg.define mise \
    package="mise" \
    managers="apt dnf brew pacman" \
    apt_key="https://mise.jdx.dev/gpg-key.pub|mise-archive-keyring.asc" \
    apt_repo="mise-archive-keyring.asc|deb [arch=amd64 signed-by=%KEYRING%] https://mise.jdx.dev/deb stable main" \
    dnf_copr="jdxcode/mise"
