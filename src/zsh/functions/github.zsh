# Get the latest release version from a GitHub repository
_gh_get_latest_release() {
    local repo="$1"
    if [[ -z "$repo" ]]; then
        echo "Usage: _gh_get_latest_release <owner/repo>" >&2
        return 1
    fi
    curl --silent "https://api.github.com/repos/$repo/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'
}