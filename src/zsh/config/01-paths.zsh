path.prepend "/usr/local/bin"
path.prepend "/usr/local/sbin"
path.prepend "${HOME}/.local/bin"
path.prepend "${HOME}/bin"
path.prepend "${DOTFILES}/bin"

path.append "${HOME}/.cargo/bin"

# Add paths from /opt/ and ~/.local/opt/ subdirectories
for base in "${HOME}/.local/opt" /opt; do
  if [[ -d $base ]]; then
    for dir in $base/*/{bin,sbin,usr/bin,usr/sbin,usr/local/bin,usr/local/sbin}(N/); do
      path.append "$dir"
    done
  fi
done

if [[ -e /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


