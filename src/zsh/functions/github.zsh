# github.zsh - GitHub Release Management Utilities

export GITHUB_RELEASES_INSTALL_DIR="${GITHUB_RELEASES_INSTALL_DIR:-$HOME/.local/opt}"

# --- Internal Helpers ---

_github_err() { echo "❌ $1" >&2; return 1; }

_github_api() {
    curl --fail --silent -L "https://api.github.com/repos/$1"
}

_github_validate_repo() {
    [[ "$1" =~ ^[a-zA-Z0-9._/-]+$ ]] || _github_err "Invalid repo name: $1"
}

# --- Public API ---

# Get the latest release version
github.get_latest_release() {
    local repo="$1"; [[ -z "$repo" ]] && return 1
    _github_validate_repo "$repo" || return 1

    local tag
    tag=$(_github_api "$repo/releases/latest" | jq -r '.tag_name // empty' 2>/dev/null)
    [[ -z "$tag" ]] && tag=$(_github_api "$repo/releases" | jq -r '.[0].tag_name // empty' 2>/dev/null)

    [[ -n "$tag" ]] && echo "$tag" || _github_err "Failed to fetch version for $repo"
}

# Get release asset URLs
github.get_asset_url() {
    local repo="$1" version="$2"; shift 2
    [[ -z "$repo" || -z "$version" ]] && return 1
    
    local ep=$([[ "$version" == "latest" ]] && echo "latest" || echo "tags/$version")
    local raw=$(_github_api "$repo/releases/$ep" | jq -r '.assets[].browser_download_url' 2>/dev/null)
    [[ -z "$raw" ]] && _github_err "No assets for $repo $version" && return 1

    local -a assets=( ${(f)raw} )
    local p
    setopt LOCAL_OPTIONS NO_CASE_MATCH EXTENDED_GLOB
    for p in "$@"; do
        assets=( ${(M)assets:#(#i)*$~p*} )
    done
    print -l "${assets[@]}"
}

# Download and install a GitHub release
github.install_release() {
    local app="$1" repo="$2" version="$3"
    [[ -z "$app" || -z "$repo" || -z "$version" ]] && return 1
    
    local dir="$GITHUB_RELEASES_INSTALL_DIR/$app"
    local current=$(<"$dir/.version" 2>/dev/null)
    local target=$(_github_compare_versions "$repo" "$version" "$current") || return 1

    if [[ "$target" == "$current" ]]; then
        echo "    🔄 $app is up-to-date ($current)"
        return 0
    fi

    echo "    📦 ${current:+Updating $app: $current -> $target}${current:-Installing $app $target}"

    local -a assets=( ${(f)"$(github.get_asset_url "$repo" "$target")"} )
    
    local arch=$(os.arch)
    local os_fam=$(os.family)
    local -A os_map=( debian linux fedora linux arch linux macos "darwin|macos" )
    local os_p="${os_map[$os_fam]:-$os_fam}"
    
    local arch_p
    case "$arch" in
        amd64) arch_p="(amd64|x86_64|x64)" ;;
        arm64) arch_p="(arm64|aarch64)" ;;
        *)     arch_p="$arch" ;;
    esac

    setopt LOCAL_OPTIONS NO_CASE_MATCH EXTENDED_GLOB
    assets=( ${(M)assets:#(#i)*$~arch_p*} )
    assets=( ${(M)assets:#(#i)*($~os_p)*} )
    assets=( ${(M)assets:#*.(tar.gz|zip|tgz)} )

    local url="${assets[1]}"
    [[ -z "$url" ]] && _github_err "No compatible asset for $repo $target" && return 1

    _github_extract_asset "$app" "$url" "$target"
}

_github_extract_asset() {
    local app="$1" url="$2" version="$3"
    local dir="$GITHUB_RELEASES_INSTALL_DIR/$app"
    local tmp=$(mktemp)
    trap "rm -f '$tmp'" EXIT

    curl --fail -SL "$url" -o "$tmp" || { _github_err "Download failed: $url"; return 1; }

    mkdir -p "$dir"
    (
        cd "$dir" || exit 1
        case "$url" in
            *.zip) unzip -qo "$tmp" ;;
            *)     tar -xzf "$tmp" --strip-components=1 2>/dev/null || tar -xzf "$tmp" ;;
        esac

        local -a sub=(*(/N))
        if (( ${#sub} == 1 )) && [[ -d "$sub[1]/bin" || -d "$sub[1]/lib" ]]; then
            mv "$sub[1]"/*(N) . && rmdir "$sub[1]"
        fi
        
        if [[ ! -d "bin" || -z "$(ls -A bin 2>/dev/null)" ]]; then
            mkdir -p bin
            local exe; for exe in *(x.N); do
                [[ "$exe" == "bin" ]] && continue
                ln -sf "../$exe" "bin/${exe:t}"
            done
        fi
        echo "$version" > .version
    )
    echo "    ✅ Installed $app $version"
}

_github_compare_versions() {
    local repo="$1" expected="$2" current="$3"
    if [[ "$expected" =~ ^(latest|main|master)$ ]]; then
        expected=$(github.get_latest_release "$repo") || return 1
    fi
    [[ "${expected#v}" != "${current#v}" ]] && echo "$expected" || echo "$current"
}
