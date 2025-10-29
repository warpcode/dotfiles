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

# Get GitHub release asset URL that matches pattern array
# Usage: _gh_get_asset_url <owner/repo> <version|latest> [pattern1] [pattern2] [pattern3]...
_gh_get_asset_url() {
    local repo="$1"
    local version="$2"
    shift 2
    local patterns=("$@")

    if [[ -z "$repo" || -z "$version" ]]; then
        echo "Usage: _gh_get_asset_url <owner/repo> <version|latest> [pattern1] [pattern2]..." >&2
        return 1
    fi

    local api_url
    if [[ "$version" == "latest" ]]; then
        api_url="https://api.github.com/repos/$repo/releases/latest"
    else
        api_url="https://api.github.com/repos/$repo/releases/tags/$version"
    fi

    curl --silent "$api_url" | jq -r '.assets[].browser_download_url' | while read -r asset; do
        # If no patterns provided, return all assets
        if [[ ${#patterns[@]} -eq 0 ]]; then
            echo "$asset"
            continue
        fi

        local match=true
        for pattern in "${patterns[@]}"; do
            if [[ ! "$asset" =~ $pattern ]]; then
                match=false
                break
            fi
        done
        if [[ "$match" == true ]]; then
            echo "$asset"
        fi
    done
}
