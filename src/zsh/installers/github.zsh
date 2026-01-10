# github.zsh - GitHub CLI installation
#
# Registers GitHub CLI package for installation from GitHub releases

_packages_register_app github-cli \
    github:"github-cli:cli/cli@latest" \
    cmd:gh
