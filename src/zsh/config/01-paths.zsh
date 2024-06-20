path_prepend "/usr/local/bin"
path_prepend "/usr/local/sbin"
path_prepend "${HOME}/.local/bin"
path_prepend "${HOME}/bin"

# Dotfiles bin files should be the least priority
path_append "${DOTFILES}/bin"
path_append "${DOTFILES}/node_modules/.bin"
path_append "${DOTFILES}/php_modules/bin"
