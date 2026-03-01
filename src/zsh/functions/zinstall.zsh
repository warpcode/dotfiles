# zinstall.zsh - Synchronized Stack-Based Zsh Installer System

# Path to recipes
export ZINSTALL_RECIPES_DIR="${DOTFILES}/src/zsh/recipes"

# Global indexes (populated at runtime)
typeset -A _zinstall_cmds
typeset -A _zinstall_files
typeset -A _zinstall_methods_available  # Maps method name to 1 if available, 0 if not
typeset -A _zinstall_recipes           # Cached recipe data: ['recipe_id:field']=value

# Execution State
typeset -A _zinstall_method_updated_once # method -> 1 if repo updated in current session
typeset -A _zinstall_needs_update        # method -> 1 if repo update requested
typeset -A _zinstall_handled_in_session  # recipe_id -> 1 if already processed

# Command dictionary - maps method to install command template
typeset -A _zinstall_commands=(
    [brew]="brew install"
    [brew-cask]="brew install --cask"
    [flatpak]="flatpak install -y"
    [snap]="sudo snap install"
    [apt]="sudo apt install -y"
    [pkg]="pkg install -y"
    [dnf]="sudo dnf install -y"
    [pacman]="sudo pacman -S --noconfirm"
    [cargo]="cargo install"
)

# Repository update commands
typeset -A _zinstall_update_commands=(
    [apt]="sudo apt update -qq"
    [pkg]="pkg update"
    [dnf]="sudo dnf makecache"
    [pacman]="sudo pacman -Sy"
    [brew]="brew update"
)

# OS-specific method precedence (lower number = higher priority)
typeset -A _zinstall_os_precedence=(
    [brew]=1
    [brew-cask]=2
    [pkg]=3
    [flatpak]=4
    [snap]=5
    [apt]=6
    [dnf]=7
    [pacman]=8
    [cargo]=9
    [github]=10
    [install_cmd]=11
)

# === Initialization ===

zinstall.init.recipes() {
    [[ ${#_zinstall_cmds[@]} -gt 0 ]] && return
    _zinstall_cmds=()
    _zinstall_files=()
    _zinstall_recipes=()

    _zinstall_load_recipe_metadata() {
        local f="$1"
        local recipe_id="${f:t:r}"
        typeset -A recipe
        source "$f"

        _zinstall_files[$recipe_id]="$f"
        local field
        for field in "${(@k)recipe[@]}"; do
            _zinstall_recipes[${recipe_id}:${field}]="${recipe[$field]}"
        done

        if [[ -n ${recipe[provides]} ]]; then
            local cmd
            for cmd in ${=recipe[provides]}; do
                _zinstall_cmds[$cmd]="$recipe_id"
            done
        else
            _zinstall_cmds[${recipe[name]}]="$recipe_id"
        fi
    }

    for f in "$ZINSTALL_RECIPES_DIR"/*.zsh(N); do
        _zinstall_load_recipe_metadata "$f"
    done
    unfunction _zinstall_load_recipe_metadata
}

zinstall.init.install_methods() {
    [[ ${#_zinstall_methods_available[@]} -gt 0 ]] && return
    _zinstall_methods_available=()

    local method
    for method in "${(@k)_zinstall_commands[@]}"; do
        _zinstall_methods_available[$method]=0
    done

    case "$OSTYPE" in
        darwin*)
            _os_has_package_manager brew && _zinstall_methods_available[brew]=1
            ;;
        linux-gnu*)
            if _os_is_termux; then
                _os_has_package_manager pkg && _zinstall_methods_available[pkg]=1
            else
                _os_has_package_manager flatpak && _zinstall_methods_available[flatpak]=1
                _os_has_package_manager snap && _zinstall_methods_available[snap]=1
                _os_is_debian_based && _zinstall_methods_available[apt]=1
                _os_is_fedora_based && _zinstall_methods_available[dnf]=1
                _os_has_package_manager pacman && _zinstall_methods_available[pacman]=1
            fi
            ;;
    esac

    _os_has_package_manager cargo && _zinstall_methods_available[cargo]=1
    _zinstall_methods_available[github]=1
    _zinstall_methods_available[install_cmd]=1
}

zinstall.init() {
    zinstall.init.recipes
    zinstall.init.install_methods
}

# === Recipe Utilities ===

zinstall.recipe.find_by_binary() {
    local target="$1"
    zinstall.init
    if [[ -n ${_zinstall_cmds[$target]} ]]; then
        echo "${_zinstall_cmds[$target]}"
    elif [[ -n ${_zinstall_files[$target]} ]]; then
        echo "$target"
    else
        return 1
    fi
}

zinstall.recipe.is_installed() {
    local recipe_id="$1"
    local provides=$(zinstall.recipe.field "$recipe_id" "provides")
    [[ -z "$provides" ]] && return 1 # Assume re-install if provides is missing

    local cmd
    for cmd in ${=provides}; do
        command -v "$cmd" >/dev/null 2>&1 && return 0
    done
    return 1
}

zinstall.recipe.field() {
    local recipe_id="$1" field="$2" default="${3:-}"
    zinstall.init
    local key="${recipe_id}:${field}"
    if (( ${+_zinstall_recipes[$key]} )); then
        echo "${_zinstall_recipes[$key]}"
    elif [[ -n "$default" ]]; then
        echo "$default"
    else
        return 1
    fi
}

zinstall.recipe.install_method() {
    local recipe_id="$1"
    zinstall.init
    [[ -z ${_zinstall_files[$recipe_id]} ]] && return 1

    local method best_prec=999 prec val best_method=""
    for method in "${(@k)_zinstall_os_precedence[@]}"; do
        prec=${_zinstall_os_precedence[$method]}
        [[ $prec -lt $best_prec ]] || continue
        val=$(zinstall.recipe.field "$recipe_id" "$method")
        if [[ ${_zinstall_methods_available[$method]} -eq 1 ]] && [[ -n "$val" ]]; then
            best_prec=$prec
            best_method="$method"
        fi
    done

    if [[ -n "$best_method" ]]; then
        echo "$best_method"
        return 0
    fi
    return 1
}

zinstall.recipe.dependencies() {
    zinstall.recipe.field "$1" "depends"
}

# === Dependency Stack Generator ===

# Returns a space-separated string of the entire dependency stack for a target
zinstall.recipe.stack() {
    local target="$1"
    local -a stack=()
    local -A visiting=()

    _resolve() {
        local rid=$(zinstall.recipe.find_by_binary "$1")
        [[ -n "$rid" ]] || return 1

        # If already in stack, skip
        [[ ${stack[(i)$rid]} -le ${#stack} ]] && return 0

        # Cycle detection
        if [[ ${visiting[$rid]} -eq 1 ]]; then
            echo "❌ Loop detected at $rid" >&2
            return 1
        fi

        visiting[$rid]=1
        local deps=($(zinstall.recipe.dependencies "$rid"))
        for dep in $deps; do _resolve "$dep" || return 1; done
        visiting[$rid]=0

        stack+=("$rid")
    }

    _resolve "$target" || return 1
    echo "${stack[*]}"
}

zinstall.repo.update() {
    local method="$1"
    local force="${2:-0}"
    local cmd="${_zinstall_update_commands[$method]}"
    [[ -z "$cmd" ]] && return 0

    if [[ "$force" -eq 1 ]] || [[ ${_zinstall_method_updated_once[$method]} -ne 1 ]] || [[ ${_zinstall_needs_update[$method]} -eq 1 ]]; then
        echo "🔄 Updating repositories for $method..."
        ${=cmd}
        _zinstall_method_updated_once[$method]=1
    fi
    _zinstall_needs_update[$method]=0
}

zinstall.repo.setup() {
    local rid="$1" method="$2"
    local repo_field="${method}_repo"
    local config=$(zinstall.recipe.field "$rid" "$repo_field")
    [[ -n "$config" ]] || return 0

    case "$method" in
        brew)
            local tap=$(zinstall.recipe.field "$rid" "brew_tap")
            for t in ${=tap}; do
                brew tap | grep -q "^$t$" || { echo "   Tapping $t..."; brew tap "$t"; _zinstall_needs_update[brew]=1; }
            done
            ;;
        apt)
            _zinstall_repo_apt_setup "$rid" "$config"
            ;;
        dnf)
            local repo_filename="${config:t}"
            [[ -f "/etc/yum.repos.d/$repo_filename" ]] || {
                echo "   Adding dnf repo..."
                sudo dnf config-manager --add-repo "$config"
                _zinstall_needs_update[dnf]=1
            }
            ;;
    esac
}

_zinstall_repo_apt_setup() {
    local rid="$1" config="$2"
    local parts=("${(@s:|:)config}")
    local key_url="${parts[1]}" keyring_name="${parts[2]}" repo_line="${parts[3]}"
    local keyring_path=""
    if [[ -n "$keyring_name" && "$keyring_name" != "null" ]]; then
        keyring_path="/usr/share/keyrings/$keyring_name"
        [[ -f "$keyring_path" ]] || {
            echo "   Downloading GPG key..."
            curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring_path" --yes
        }
    fi
    local -A vars=(
        [CODENAME]=$(lsb_release -cs 2>/dev/null || echo "stable")
        [ARCH]=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
        [DISTRO]=$(lsb_release -is 2>/dev/null | tr "[:upper:]" "[:lower:]" || echo "debian")
        [KEYRING]=$keyring_path
    )
    for token in "${(@k)vars}"; do repo_line="${repo_line//%${token}%/${vars[$token]}}"; done
    if [[ -n "$keyring_path" && $repo_line != *"signed-by="* ]]; then
        repo_line="${repo_line/deb /deb [signed-by=$keyring_path] }"
    fi
    local list_file="/etc/apt/sources.list.d/${rid}.list"
    [[ "$(cat "$list_file" 2>/dev/null)" != "$repo_line" ]] && {
        echo "   Configuring apt source for $rid..."
        echo "$repo_line" | sudo tee "$list_file" >/dev/null
        _zinstall_needs_update[apt]=1
    }
}

zinstall.recipe.hooks.run() {
    local rid="$1" hook="$2"
    local val=$(zinstall.recipe.field "$rid" "$hook")
    [[ -n "$val" ]] || return 0
    local recipe_file="${_zinstall_files[$rid]}"
    (
        source "$recipe_file"
        echo "   Running ${hook} for $rid..."
        functions ${val} >/dev/null && ${val} || eval "${val}"
    )
}

# === Public API ===

zinstall.install() {
    zinstall.init
    local -a stacks=()
    local -A seen=()
    local target recipe_id stack_str i layer method

    # 1. Resolve & Deduplicate Dependency Layers
    for target in "$@"; do
        stack_str=($(zinstall.recipe.stack "$target"))
        for (( i=1; i <= ${#stack_str}; i++ )); do
            recipe_id="${stack_str[i]}"
            if [[ -z ${seen[$recipe_id]} ]]; then
                stacks[i]+=" $recipe_id"
                seen[$recipe_id]=1
            fi
        done
    done

    # 2. Process each layer (deepest dependencies first)
    for layer in "${stacks[@]}"; do
        [[ -z "$layer" ]] && continue
        local -A groups=()

        # Group by method and run pre-install setup
        for recipe_id in ${=layer}; do
            local name=$(zinstall.recipe.field "$recipe_id" name)

            if zinstall.recipe.is_installed "$recipe_id"; then
                echo "✅ Already installed: $name"
                continue
            fi

            if method=$(zinstall.recipe.install_method "$recipe_id"); then
                groups[$method]+=" $recipe_id"
                zinstall.recipe.hooks.run "$recipe_id" pre_install
                zinstall.repo.setup "$recipe_id" "$method"
            fi
        done

        # 3. Execute installation for each method group in the layer
        for method in "${(@k)groups}"; do
            zinstall.repo.update "$method"
            local -a rids=(${=groups[$method]})

            if [[ -n ${_zinstall_commands[$method]} ]]; then
                # Batch installation (apt, pkg, brew, etc.)
                local -a pkgs=()
                for recipe_id in "${rids[@]}"; do pkgs+=($(zinstall.recipe.field "$recipe_id" "$method")); done
                echo "📦 Batch installing ($method): $pkgs"
                ${=_zinstall_commands[$method]} ${=pkgs} || {
                    echo "❌ Batch installation failed for $method ($pkgs)" >&2
                    return 1
                }
            else
                # Individual installation (github, install_cmd)
                for recipe_id in "${rids[@]}"; do
                    local val=$(zinstall.recipe.field "$recipe_id" "$method")
                    local name=$(zinstall.recipe.field "$recipe_id" name)
                    echo "📦 Installing $name via $method..."

                    if [[ "$method" == "github" ]]; then
                        local app=${val%%:*} rest=${val#*:} repo=${rest%%@*} ver=${rest#*@}
                        _gh_install_release "$app" "$repo" "$ver" || {
                            echo "❌ Installation failed for $name (github: $repo)" >&2
                            return 1
                        }
                    elif [[ "$method" == "install_cmd" ]]; then
                        functions "$val" >/dev/null && "$val" || eval "$val" || {
                            echo "❌ Installation command failed for $name" >&2
                            return 1
                        }
                    fi
                done
            fi

            # Run post-install hooks for the group
            for recipe_id in "${rids[@]}"; do
                zinstall.recipe.hooks.run "$recipe_id" post_install
                echo "✅ Successfully installed $recipe_id!"
            done
        done
    done
}

zinstall.exec() {
    local cmd="$1"; shift
    command -v "$cmd" >/dev/null 2>&1 && { "$cmd" "$@"; return $?; }
    zinstall.install "$cmd" || return 1
    command -v "$cmd" >/dev/null 2>&1 && { "$cmd" "$@"; return $?; }
    return 1
}
