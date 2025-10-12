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

