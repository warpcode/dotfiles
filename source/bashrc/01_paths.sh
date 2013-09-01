if [[ "$OSTYPE" =~ ^darwin ]];
then
    # OSX doesn't have /usr/local/bin or /usr/local/sbin in the path
    _prepend_to_path "/usr/local/bin"
    _prepend_to_path "/usr/local/sbin"
fi

_prepend_to_path "${HOME}/.dotfiles/bin"
_prepend_to_path "${HOME}/bin"