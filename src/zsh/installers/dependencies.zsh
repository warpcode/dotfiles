# Common dependencies required for repository setup and package installation

# Debian/Ubuntu prerequisites for adding repositories and installing packages
_installer_dependencies "debian" ca-certificates curl gnupg jq unzip

# Fedora prerequisites for package management
_installer_dependencies "fedora" dnf-plugins-core unzip

# Arch Linux prerequisites
_installer_dependencies "arch" unzip

# macOS prerequisites (via Homebrew)
_installer_dependencies "macos" unzip
