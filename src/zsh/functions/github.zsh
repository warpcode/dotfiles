# Installation directory for GitHub releases (can be overridden by GITHUB_RELEASES_INSTALL_DIR env var)
: ${GITHUB_RELEASES_INSTALL_DIR:="$HOME/.local/opt"}

# Get the latest release version from a GitHub repository
# @param repo The repository in owner/repo format
# @return Latest tag name, or empty on error
_gh_get_latest_release() {
    local repo="$1"
    if [[ -z "$repo" ]]; then
        echo "Usage: _gh_get_latest_release <owner/repo>" >&2
        return 1
    fi
    # Try latest release first
    local tag=$(curl --silent "https://api.github.com/repos/$repo/releases/latest" |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/')
    if [[ -n "$tag" ]]; then
        echo "$tag"
        return 0
    fi
    # Fallback to latest overall release (including pre-releases)
    curl --silent "https://api.github.com/repos/$repo/releases" |
        jq -r '.[0].tag_name' 2>/dev/null
}

# Get GitHub release asset URLs that match all provided patterns
# @param repo The repository in owner/repo format
# @param version The version tag or "latest"
# @param patterns Optional patterns that must all match the asset URL
# @return Matching asset URLs, one per line
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

# Download and install a GitHub release.
# @param app The app name
# @param repo The repo in owner/repo format
# @param version The version tag
# @return 0 on success
_gh_install_release() {
    local app=$1
    local repo=$2
    local version=$3

    local os=$(_os_detect_os_family)
    local arch=$(_os_detect_arch)

    # Resolve latest version
    if [[ $version == "latest" ]]; then
        version=$(_gh_get_latest_release "$repo")
        if [[ -z $version ]]; then
            echo "❌ Failed to get latest release for $repo" >&2
            return 1
        fi
    fi

    # Input validation for security
    if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "❌ Invalid repo name: $repo (only alphanumeric, dots, underscores, slashes, and hyphens allowed)" >&2
        return 1
    fi

    local dir="$GITHUB_RELEASES_INSTALL_DIR/$app"

    # Check current version
    if [[ -f "$dir/.version" ]]; then
        local current=$(<"$dir/.version")
        if [[ $current == "$version" ]]; then
            echo "🔄 $app is already at version $version"
            return 0
        fi
    fi

    echo "📦 Installing $app version $version from $repo"
    echo "⚠️ WARNING: No signature verification performed - manually verify $repo releases for security" >&2

    # Build OS patterns
    local os_patterns=()
    if [[ $os =~ ^(debian|fedora|arch)$ ]]; then
        os_patterns=("linux")
    elif [[ $os == "macos" ]]; then
        os_patterns=("darwin" "macos")
    else
        os_patterns=("$os")
    fi

    # Find compatible asset (only .tar.gz supported initially)
    local os_regex="($(IFS='|'; echo "${os_patterns[*]}"))"
    local asset_url=$(
        _os_filter_by_arch "$(_gh_get_asset_url "$repo" "$version")" |
        grep -E "$os_regex" |
        grep '\.tar\.gz$' |
        head -1
    )

    if [[ -z $asset_url ]]; then
        echo "❌ No compatible .tar.gz asset found for $repo $version on $os $arch" >&2
        return 1
    fi

    _gh_extract_asset_to_install_dir "$app" "$asset_url" "$version"
}

# Extract GitHub asset and setup.
# @param app The app name
# @param asset_url The asset URL
# @param version The version
# @return 0 on success
_gh_extract_asset_to_install_dir() {
    local app=$1
    local asset_url=$2
    local version=$3

    local dir="$GITHUB_RELEASES_INSTALL_DIR/$app"

    # Create directory
    mkdir -p "$dir"

    # Download and extract (with path traversal protection)
    if curl -L "$asset_url" | tar --strip-components=1 --no-overwrite-dir -xzf - -C "$dir"; then
# Flattens top-level dirs for simpler structure
        local subdirs=($(find "$dir" -mindepth 1 -maxdepth 1 -type d))
        if [[ ${#subdirs[@]} -eq 1 ]]; then
            local subdir=${subdirs[1]}
            if [[ -d "$subdir/bin" || -d "$subdir/sbin" || -d "$subdir/usr" || -d "$subdir/lib" ]]; then
                setopt local_options dotglob
                mv "$subdir"/* "$dir"/ 2>/dev/null || true
                unsetopt dotglob
                rmdir "$subdir" 2>/dev/null || true
            fi
        fi

        # Ensure bin/ directory exists and contains symlinks to executables
        if [[ ! -d "$dir/bin" ]]; then
            mkdir -p "$dir/bin"
            # Create symlinks to top-level executables in bin/
            for exe in $(find "$dir" -maxdepth 1 -type f -executable); do
                local basename=$(basename "$exe")
                ln -sf "$exe" "$dir/bin/$basename"
            done
        fi
        echo "$version" > "$dir/.version"
        echo "✅ Successfully installed $app version $version"
    else
        echo "❌ Failed to download or extract $asset_url" >&2
        return 1
    fi
}
