# Common dependencies required for repository setup and package installation

# Debian/Ubuntu prerequisites for adding repositories and installing packages
_installer_dependencies "debian" ca-certificates curl gnupg jq

# Fedora prerequisites for package management
_installer_dependencies "fedora" dnf-plugins-core
