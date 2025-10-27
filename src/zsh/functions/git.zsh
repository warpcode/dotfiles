# Git utility functions

# Ensure a git repository is cloned to a directory
# Usage: _g_ensure_cloned <repo_url> <directory>
_git_ensure_cloned() {
  local repo="$1"
  local dir="$2"

  if [[ -z "$repo" || -z "$dir" ]]; then
    echo "Usage: _g_ensure_cloned <repo_url> <directory>" >&2
    return 1
  fi

  if [[ ! -d "$dir/.git" ]]; then
    git clone "$repo" "$dir"
  fi
}
