# zinstall.zsh - Simplified Zsh Installer System

# Path to recipes
export ZINSTALL_RECIPES_DIR="${DOTFILES}/src/zsh/recipes"

# Global indexes (populated at runtime)
typeset -A _zinstall_cmds
typeset -A _zinstall_files
typeset -a _zinstall_stack

# === Core ===

# Initialize and scan recipes dynamically
_zinstall_init() {
    # If already initialized, skip
    [[ ${#_zinstall_cmds[@]} -gt 0 ]] && return

    # Clear existing arrays
    _zinstall_cmds=()
    _zinstall_files=()

    # Helper function to load a single recipe in a local scope
    # This prevents 'recipe' variable from leaking or being overwritten globally
    _zinstall_load_recipe_metadata() {
        local f="$1"
        local recipe_id="${f:t:r}"
        
        # Define recipe assoc array locally. 
        # When we source the file, it populates this local variable.
        typeset -A recipe
        source "$f"
        
        # Write to global indexes
        _zinstall_files[$recipe_id]="$f"
        
        if [[ -n ${recipe[provides]} ]]; then
            local cmd
            for cmd in ${=recipe[provides]}; do
                _zinstall_cmds[$cmd]="$recipe_id"
            done
        else
            _zinstall_cmds[${recipe[name]}]="$recipe_id"
        fi
    }

    # Iterate over all recipe files
    for f in "$ZINSTALL_RECIPES_DIR"/*.zsh(N); do
        _zinstall_load_recipe_metadata "$f"
    done
    
# Cleanup helper
    unfunction _zinstall_load_recipe_metadata
}

# Resolve a command or ID to a recipe ID
# Usage: zinstall.recipe <target>
zinstall.recipe() {
    local target="$1"
    _zinstall_init
    
    if [[ -n ${_zinstall_cmds[$target]} ]]; then
        echo "${_zinstall_cmds[$target]}"
        return 0
    elif [[ -n ${_zinstall_files[$target]} ]]; then
        echo "$target"
        return 0
    fi
    
    return 1
}

# Internal helper to resolve the installation method based on precedence
_zinstall_resolve_method() {
    # Validation: Ensure recipe is available
    if [[ ${(t)recipe} != association* ]]; then
        echo "❌ Internal Error: _zinstall_resolve_method called without valid recipe" >&2
        return 1
    fi

    local resolved=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ -n ${recipe[brew]} ]] && command -v brew >/dev/null; then
            resolved="brew"
        elif [[ -n ${recipe[brew-cask]} ]] && command -v brew >/dev/null; then
            resolved="brew-cask"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Precedence: Flatpak > Snap > OS Package Manager (Apt/Dnf/Pacman)
        if [[ -n ${recipe[flatpak]} ]] && command -v flatpak >/dev/null; then
            resolved="flatpak"
        elif [[ -n ${recipe[snap]} ]] && command -v snap >/dev/null; then
            resolved="snap"
        elif [[ -f /etc/debian_version && -n ${recipe[apt]} ]]; then
            resolved="apt"
        elif [[ -f /etc/fedora-release && -n ${recipe[dnf]} ]]; then
            resolved="dnf"
        elif [[ -x $(command -v pacman) && -n ${recipe[pacman]} ]]; then
            resolved="pacman"
        fi
    fi

    # cargo fallback
    if [[ -z "$resolved" && -n ${recipe[cargo]} ]]; then
        resolved="cargo"
    fi

    # GitHub release fallback
    if [[ -z "$resolved" && -n ${recipe[github]} ]]; then
        resolved="github"
    fi

    # Fallback to custom command if no system method found
    if [[ -z "$resolved" && -n ${recipe[install_cmd]} ]]; then
        resolved="custom"
    fi

    echo "$resolved"
}

# Internal helper to configure repositories/sources
_zinstall_setup_repo() {
    # Validation: Ensure we are called within a context where 'recipe' and 'method' are defined
    if [[ ${(t)recipe} != association* ]]; then
        echo "❌ Internal Error: _zinstall_setup_repo called without valid recipe" >&2
        return 1
    elif [[ -z $method ]]; then
        echo "❌ Internal Error: _zinstall_setup_repo called without valid method" >&2
        return 1
    fi

    case "$method" in
        brew|brew-cask)
            if [[ -n ${recipe[brew_tap]} ]]; then
                local tap
                for tap in ${=recipe[brew_tap]}; do
                    if ! brew tap | grep -q "^$tap$"; then
                        echo "   Tapping $tap..."
                        brew tap "$tap"
                    fi
                done
            fi
            ;;
        apt)
            if [[ -n ${recipe[apt_repo]} ]]; then
                local repo_config="${recipe[apt_repo]}"
                local parts=("${(@s:|:)repo_config}")
                local key_url="${parts[1]}"
                local keyring_name="${parts[2]}"
                local repo_line="${parts[3]}"
                local list_file="/etc/apt/sources.list.d/${recipe[name]}.list"

                # 1. Handle Keyring
                local keyring_path=""
                if [[ -n "$keyring_name" && "$keyring_name" != "null" ]]; then
                    keyring_path="/usr/share/keyrings/$keyring_name"
                    if [[ ! -f "$keyring_path" && -n "$key_url" && "$key_url" != "null" ]]; then
                         echo "   Downloading GPG key..."
                         curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring_path" --yes
                    fi
                fi

                # 2. Token Replacement
                local codename=$(lsb_release -cs 2>/dev/null || echo "stable")
                local arch=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
                local distro=$(lsb_release -is 2>/dev/null | tr "[:upper:]" "[:lower:]" || echo "debian")
                
                # Use quoted patterns for robust replacement
                repo_line="${repo_line//"%CODENAME%"/"$codename"}"
                repo_line="${repo_line//"%ARCH%"/"$arch"}"
                repo_line="${repo_line//"%DISTRO%"/"$distro"}"
                key_url="${key_url//"%DISTRO%"/"$distro"}"
                
                if [[ -n "$keyring_path" ]]; then
                    repo_line="${repo_line//"%KEYRING%"/"$keyring_path"}"
                    # Ensure [signed-by=...] is present if a keyring is used
                    # Look for [signed-by= or signed-by=
                    if [[ $repo_line != *"signed-by="* ]]; then
                         # Inject after 'deb ' or 'deb-src '
                         repo_line="${repo_line/deb /deb [signed-by=$keyring_path] }"
                    fi
                fi

                # 3. Idempotent Write & Update
                if [[ ! -f "$list_file" ]] || [[ "$(cat "$list_file")" != "$repo_line" ]]; then
                    echo "   Configuring apt source..."
                    echo "$repo_line" | sudo tee "$list_file" >/dev/null
                    sudo apt update -qq
                fi
            fi
            ;;
        dnf)
            if [[ -n ${recipe[dnf_repo]} ]]; then
                 local repo_url="${recipe[dnf_repo]}"
                 local repo_filename="${repo_url:t}"
                 if [[ ! -f "/etc/yum.repos.d/$repo_filename" ]]; then
                      echo "   Adding dnf repo..."
                      sudo dnf config-manager --add-repo "$repo_url"
                 fi
            fi
            ;;
    esac
}

# Internal helper to execute the installation command
_zinstall_run_installer() {
    # Validation: Ensure method and recipe are available via scope
    if [[ ${(t)recipe} != association* ]]; then
        echo "❌ Internal Error: _zinstall_run_installer called without valid recipe" >&2
        return 1
    elif [[ -z $method ]]; then
        echo "❌ Internal Error: _zinstall_run_installer called without valid method" >&2
        return 1
    fi

    local pkgs="${recipe[$method]}"
    [[ "$method" == "custom" ]] && pkgs="${recipe[install_cmd]}"

    case "$method" in
        brew)      brew install ${=pkgs} ;;
        brew-cask) brew install --cask ${=pkgs} ;;
        flatpak)   flatpak install -y ${=pkgs} ;;
        snap)      sudo snap install ${=pkgs} ;;
        apt)       sudo apt install -y ${=pkgs} ;;
        dnf)       sudo dnf install -y ${=pkgs} ;;
        pacman)    sudo pacman -S --noconfirm ${=pkgs} ;;
        custom)
            if functions ${pkgs} >/dev/null; then
                ${pkgs}
            else
                eval "${pkgs}"
            fi
            ;;
        cargo)     cargo install ${=pkgs} ;;
        github)
            local app=${pkgs%%:*}
            local rest=${pkgs#*:}
            local repo=${rest%%@*}
            local version=${rest#*@}
            _gh_install_release "$app" "$repo" "$version"
            ;;
        *)
            echo "❌ No suitable installation method found or no packages defined." >&2
            return 1
            ;;
    esac
}

# Install a package (from recipe)
# Usage: zinstall.install <package_name_or_binary>
zinstall.install() {
    local target="$1"
    _zinstall_init
    local recipe_id=$(zinstall.recipe "$target")
    
    if [[ -z "$recipe_id" ]]; then
        echo "❌ Unknown package or command: $target" >&2
        return 1
    fi

    local recipe_file="${_zinstall_files[$recipe_id]}"
    if [[ ! -f "$recipe_file" ]]; then
        echo "❌ Recipe file missing: $recipe_file" >&2
        return 1
    fi
    
    echo "📦 Loading recipe: $recipe_id"
    
    # 1. Cycle Detection
    if [[ ${_zinstall_stack[(i)$recipe_id]} -le ${#_zinstall_stack} ]]; then
        echo "❌ Circular dependency detected: ${_zinstall_stack[*]} -> $recipe_id" >&2
        return 1
    fi
    _zinstall_stack+=("$recipe_id")

    # Source the recipe in a subshell/block to execute logic
    (
        typeset -A recipe
        source "$recipe_file"
        
        # 2. Idempotency Check (Assume if one command exists, the package is installed)
        local cmd
        for cmd in ${=recipe[provides]:-${recipe[name]}}; do
            if command -v "$cmd" >/dev/null 2>&1; then
                echo "✅ ${recipe[name]} is already installed (found '$cmd')."
                return 0
            fi
        done

        echo "   Installing ${recipe[name]}..."
        
        # 3. Handle Dependencies
        if [[ -n ${recipe[depends]} ]]; then
            echo "   Installing dependencies for ${recipe[name]}: ${recipe[depends]}..."
            zinstall.ensure ${=recipe[depends]} || return 1
        fi
        
        # 4. Pre-install
        if [[ -n ${recipe[pre_install]} ]]; then
            echo "   Running pre-install..."
            if functions ${recipe[pre_install]} >/dev/null; then
                ${recipe[pre_install]}
            else
                eval "${recipe[pre_install]}"
            fi
        fi
        
        # 5. Determine Installation Method (Precedence)
        local method=$(_zinstall_resolve_method)
        if [[ -z "$method" ]]; then
            echo "   Not applicable: no matching installer found for current OS ($(uname -s)). Skipping."
            return 0
        fi

        # 6. Repo/Environment Setup
        _zinstall_setup_repo

        # 7. Perform Installation via helper
        if _zinstall_run_installer; then
            # 8. Post Install
            if [[ -n ${recipe[post_install]} ]]; then
                echo "   Running post-install..."
                if functions ${recipe[post_install]} >/dev/null; then
                    ${recipe[post_install]}
                else
                    eval "${recipe[post_install]}"
                fi
            fi
            echo "✅ Installed ${recipe[name]}!"
        else
            return 1
        fi
    )
    local ret=$?
    
    # Pop from stack
    _zinstall_stack=(${_zinstall_stack[1,-2]})
    
    return $ret
}

# Ensure packages are installed
# Usage: zinstall.ensure <package> [package...]
zinstall.ensure() {
    local pkg
    for pkg in "$@"; do
        zinstall.install "$pkg" || return 1
    done
}
