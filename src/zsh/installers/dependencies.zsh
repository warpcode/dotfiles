# Common dependencies required for repository setup and package installation
#
_packages_register_app ca-certificates \
    apt:ca-certificates \
    dnf:ca-certificates \
    pacman:ca-certificates \
    brew:ca-certificates \
    :dep

_packages_register_app curl \
    apt:curl \
    dnf:curl \
    pacman:curl \
    brew:curl \
    cmd:curl \
    :dep

_packages_register_app dnf-plugins-core \
    dnf:dnf-plugins-core \
    :dep

_packages_register_app gnupg \
    apt:gnupg \
    dnf:gnupg \
    pacman:gnupg \
    brew:gnupg \
    cmd:gpg \
    :dep

_packages_register_app jq \
    apt:jq \
    dnf:jq \
    pacman:jq \
    brew:jq \
    cmd:jq \
    :dep

_packages_register_app unzip \
    apt:unzip \
    dnf:unzip \
    pacman:unzip \
    brew:unzip \
    cmd:unzip \
    :dep
