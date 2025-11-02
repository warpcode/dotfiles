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

    # Input validation for security
    if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "❌ Invalid repo name: $repo (only alphanumeric, dots, underscores, slashes, and hyphens allowed)" >&2
        return 1
    fi

    # Try latest release first
    local tag
    if ! tag=$(curl --fail --silent "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null |
        grep '"tag_name":' |
        sed -E 's/.*"([^"]+)".*/\1/'); then
        echo "❌ Failed to fetch latest release for $repo" >&2
        return 1
    fi
    if [[ -n "$tag" ]]; then
        echo "$tag"
        return 0
    fi
    # Fallback to latest overall release (including pre-releases)
    if ! curl --fail --silent "https://api.github.com/repos/$repo/releases" 2>/dev/null |
        jq -r '.[0].tag_name' 2>/dev/null; then
        echo "❌ Failed to fetch releases for $repo" >&2
        return 1
    fi
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

    # Input validation for security
    if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "❌ Invalid repo name: $repo (only alphanumeric, dots, underscores, slashes, and hyphens allowed)" >&2
        return 1
    fi

    local api_url
    if [[ "$version" == "latest" ]]; then
        api_url="https://api.github.com/repos/$repo/releases/latest"
    else
        api_url="https://api.github.com/repos/$repo/releases/tags/$version"
    fi

    local assets
    if ! assets=$(curl --fail --silent "$api_url" 2>/dev/null | jq -r '.assets[].browser_download_url' 2>/dev/null); then
        echo "❌ Failed to fetch assets for $repo $version" >&2
        return 1
    fi

    echo "$assets" | while read -r asset; do
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
# @param version The version tag or "latest"
# @return 0 on success
_gh_install_release() {
    local app=$1
    local repo=$2
    local version=$3

    # Input validation for security
    if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "❌ Invalid repo name: $repo (only alphanumeric, dots, underscores, slashes, and hyphens allowed)" >&2
        return 1
    fi

    local dir="$GITHUB_RELEASES_INSTALL_DIR/$app"

    # Check current version
    local current_version=""
    if [[ -f "$dir/.version" ]]; then
        current_version=$(<"$dir/.version")
    fi

    # Get target version using comparison function
    local target_version=$(_gh_compare_versions "$repo" "$version" "$current_version")
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to resolve version for $repo" >&2
        return 1
    fi

    # If versions match, skip
    if [[ "$target_version" == "$current_version" ]]; then
        echo "🔄 $app is already installed ($current_version)"
        return 0
    fi

    # Install/update
    if [[ -n "$current_version" ]]; then
        echo "📦 $app version mismatch (installed: $current_version, target: $target_version). Installing..."
    else
        echo "📦 Installing $app version $target_version from $repo"
    fi
    echo "⚠️ WARNING: No signature verification performed - manually verify $repo releases for security" >&2

    # Get OS and arch information
    local os=$(_os_detect_os_family)
    local arch=$(_os_detect_arch)

    # Build OS patterns
    local os_patterns=()
    if [[ $os =~ ^(debian|fedora|arch)$ ]]; then
        os_patterns=("linux")
    elif [[ $os == "macos" ]]; then
        os_patterns=("darwin" "macos")
    else
        os_patterns=("$os")
    fi

    # Find compatible asset (.tar.gz and .zip supported)
    local os_regex="($(IFS='|'; echo "${os_patterns[*]}"))"
    local asset_url=$(
        _os_filter_by_arch "$(_gh_get_asset_url "$repo" "$target_version")" |
        grep -i -E "$os_regex" |
        grep -E '\.(tar\.gz|zip)$' |
        head -1
    )

    if [[ -z $asset_url ]]; then
        echo "❌ No compatible .tar.gz asset found for $repo $target_version on $os $arch" >&2
        return 1
    fi

    _gh_extract_asset_to_install_dir "$app" "$asset_url" "$target_version"
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

    # Helper function to flatten directory structure
    _flatten_dir() {
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
    }

    # Download and extract
    if [[ $asset_url =~ \.zip$ ]]; then
        local temp_file=$(mktemp)
        if curl --fail -L "$asset_url" -o "$temp_file" && unzip -d "$dir" "$temp_file"; then
            echo "📦 Downloaded and extracted $asset_url"
            rm "$temp_file"
            _flatten_dir
        else
            echo "❌ Failed to extract $asset_url" >&2
            rm -f "$temp_file"
            return 1
        fi
    elif curl --fail -L "$asset_url" | tar --strip-components=1 -xzf - -C "$dir" 2>/dev/null || curl --fail -L "$asset_url" | tar -xzf - -C "$dir"; then
        echo "📦 Downloaded and extracted $asset_url"
        _flatten_dir
    else
        echo "❌ Failed to extract $asset_url" >&2
        return 1
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
}

# Compare versions and return the target version to use
# @param repo The repository in owner/repo format
# @param expected_version The expected version, or "latest", "main", "master"
# @param current_version The currently installed version
# @return The version to use (expected if different from current, else current)
_gh_compare_versions() {
    local repo="$1"
    local expected_version="$2"
    local current_version="$3"

    if [[ -z "$repo" || -z "$expected_version" ]]; then
        echo "Usage: _gh_compare_versions <owner/repo> <expected_version> [current_version]" >&2
        return 1
    fi

    # Input validation for security
    if [[ ! $repo =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "❌ Invalid repo name: $repo (only alphanumeric, dots, underscores, slashes, and hyphens allowed)" >&2
        return 1
    fi

    # Resolve expected version if it's a special keyword
    if [[ "$expected_version" =~ ^(latest|main|master)$ ]]; then
        expected_version=$(_gh_get_latest_release "$repo")
        if [[ $? -ne 0 ]]; then
            echo "❌ Failed to get latest release for $repo" >&2
            return 1
        fi
    fi

    # Compare versions (normalize by removing leading 'v')
    local expected_normalized="${expected_version#v}"
    local current_normalized="${current_version#v}"

    if [[ "$expected_normalized" != "$current_normalized" ]]; then
        echo "$expected_version"
    else
        echo "$current_version"
    fi
}
