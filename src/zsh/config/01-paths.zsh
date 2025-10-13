_paths_prepend "/usr/local/bin"
_paths_prepend "/usr/local/sbin"
_paths_prepend "${HOME}/.local/bin"
_paths_prepend "${HOME}/bin"

# Add paths from /opt/ and ~/.local/opt/ subdirectories
for base in "${HOME}/.local/opt" /opt; do
  if [[ -d $base ]]; then
    for dir in $base/*/{bin,sbin,usr/bin,usr/sbin,usr/local/bin,usr/local/sbin}(N/); do
      _paths_append "$dir"
    done
  fi
done

if [[ -e /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if [[ -n $IS_WORK ]]; then
  _paths_prepend "/opt/homebrew/opt/node@18/bin"
  _paths_prepend "/opt/homebrew/opt/mysql-client/bin"
fi

