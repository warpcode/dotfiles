# Common dependencies required for repository setup and package installation
#
_packages_register_app ca-certificates apt:ca-certificates :dep
_packages_register_app curl apt:curl :dep
_packages_register_app dnf-plugins-core dnf:dnf-plugins-core :dep
_packages_register_app gnupg apt:gnupg :dep
_packages_register_app jq apt:jq :dep
_packages_register_app unzip \
    apt:unzip \
    dnf:unzip \
    pacman:unzip \
    brew:unzip \
    :dep
