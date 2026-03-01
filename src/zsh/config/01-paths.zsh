paths.prepend "/usr/local/bin"
paths.prepend "/usr/local/sbin"
paths.prepend "${HOME}/.local/bin"
paths.prepend "${HOME}/bin"

paths.append "${HOME}/.cargo/bin"

# Add paths from /opt/ and ~/.local/opt/ subdirectories
for base in "${HOME}/.local/opt" /opt; do
  if [[ -d $base ]]; then
    for dir in $base/*/{bin,sbin,usr/bin,usr/sbin,usr/local/bin,usr/local/sbin}(N/); do
      paths.append "$dir"
    done
  fi
done

if [[ -e /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if [[ -n $IS_WORK ]]; then
  paths.prepend "/opt/homebrew/opt/node@18/bin"
  paths.prepend "/opt/homebrew/opt/mysql-client/bin"
fi

