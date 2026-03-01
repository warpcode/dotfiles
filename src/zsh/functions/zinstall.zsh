# zinstall.zsh - Simplified Zsh Installer System

# Path to recipes
export ZINSTALL_RECIPES_DIR="${DOTFILES}/src/zsh/recipes"

# Global indexes (populated at runtime)
typeset -A _zinstall_cmds
typeset -A _zinstall_files
typeset -a _zinstall_stack
typeset -A _zinstall_methods_available  # Maps method name to 1 if available, 0 if not
typeset -A _zinstall_recipes  # Cached recipe data: ['recipe_id:field']=value

# Command dictionary - maps method to install command template
typeset -A _zinstall_commands=(
    [brew]="brew install"
    [brew-cask]="brew install --cask"
    [flatpak]="flatpak install -y"
    [snap]="sudo snap install"
    [apt]="sudo apt install -y"
    [dnf]="sudo dnf install -y"
    [pacman]="sudo pacman -S --noconfirm"
    [cargo]="cargo install"
)

# OS-specific method precedence (lower number = higher priority)
# Flat structure: [method]=priority
typeset -A _zinstall_os_precedence=(
    [brew]=1
    [brew-cask]=2
    [flatpak]=3
    [snap]=4
    [apt]=5
    [dnf]=6
    [pacman]=7
    [cargo]=8
    [github]=9
    [custom]=10
)

# === Core ===

# Initialize and scan recipes dynamically
zinstall.init.recipes() {
    # If already initialized, skip
    [[ ${#_zinstall_cmds[@]} -gt 0 ]] && return

    # Clear existing arrays
    _zinstall_cmds=()
    _zinstall_files=()
    _zinstall_recipes=()

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

        # Cache all recipe fields as 'recipe_id:field' in global associative array
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

    # Iterate over all recipe files
    for f in "$ZINSTALL_RECIPES_DIR"/*.zsh(N); do
        _zinstall_load_recipe_metadata "$f"
    done

    # Cleanup helper
    unfunction _zinstall_load_recipe_metadata
}

# Detect and populate available installation methods
zinstall.init.install_methods() {
    # If already initialized, skip
    [[ ${#_zinstall_methods_available[@]} -gt 0 ]] && return

    # Clear existing
    _zinstall_methods_available=()

    # Initialize all methods as unavailable
    local method
    for method in "${(@k)_zinstall_commands[@]}"; do
        _zinstall_methods_available[$method]=0
    done

    # Platform-specific checks
    case "$OSTYPE" in
        darwin*)
            _os_has_package_manager brew && _zinstall_methods_available[brew]=1
            ;;
        linux-gnu*)
            _os_has_package_manager flatpak && _zinstall_methods_available[flatpak]=1
            _os_has_package_manager snap && _zinstall_methods_available[snap]=1
            _os_is_debian_based && _zinstall_methods_available[apt]=1
            _os_is_fedora_based && _zinstall_methods_available[dnf]=1
            _os_has_package_manager pacman && _zinstall_methods_available[pacman]=1
            ;;
    esac

    # Universal methods (available everywhere with required tools)
    _os_has_package_manager cargo && _zinstall_methods_available[cargo]=1
    # github and custom don't require external tools
    _zinstall_methods_available[github]=1
    _zinstall_methods_available[custom]=1
}

# Master init - calls all sub-inits
zinstall.init() {
    zinstall.init.recipes
    zinstall.init.install_methods
}

# Resolve a binary/command name to its recipe ID
# Usage: zinstall.recipe.find_by_binary <binary_name>
zinstall.recipe.find_by_binary() {
    local target="$1"
    zinstall.init

    if [[ -n ${_zinstall_cmds[$target]} ]]; then
        echo "${_zinstall_cmds[$target]}"
        return 0
    elif [[ -n ${_zinstall_files[$target]} ]]; then
        echo "$target"
        return 0
    fi

    return 1
}

# Check if a recipe would install on the current system
# Usage: zinstall.recipe.installable <recipe_name>
# Returns 0 if installable, 1 if not
zinstall.recipe.installable() {
    local recipe_name="$1"
    local method=$(zinstall.recipe.install_method "$recipe_name")
    [[ -n "$method" ]]
}

# Get the preferred install method for a recipe
# Usage: zinstall.recipe.install_method <recipe_name>
# Echoes the method name, or returns 1 if none found
zinstall.recipe.install_method() {
    emulate -L zsh
    local recipe_name="$1"
    zinstall.init

    # Check if recipe exists via cache
    if [[ -z ${_zinstall_files[$recipe_name]} ]]; then
        return 1
    fi

    # Single pass: find highest priority valid method using cached fields
    local method best_prec=999 method_value prec
    for method in "${(@k)_zinstall_os_precedence[@]}"; do
        prec=${_zinstall_os_precedence[$method]}

        # Skip if we already found a better match
        [[ $prec -lt $best_prec ]] || continue

        # Check: method available on OS AND method defined in recipe (via cache)
        method_value=$(zinstall.recipe.field "$recipe_name" "$method")
        if [[ ${_zinstall_methods_available[$method]} -eq 1 ]] && [[ -n "$method_value" ]]; then
            best_prec=$prec
            echo "$method"
            return 0
        fi
    done

    return 1
}

# Get a specific field from a recipe
# Usage: zinstall.recipe.field <recipe_name> <field> [default]
# Echoes the field value, or default if not set, or nothing if no default given
zinstall.recipe.field() {
    local recipe_name="$1"
    local field="$2"
    local default="${3:-}"

    zinstall.init

    # Check cache first - use unquoted variable for key with special chars
    local cache_key="${recipe_name}:${field}"
    if [[ -n ${_zinstall_recipes[$cache_key]} ]]; then
        echo "${_zinstall_recipes[$cache_key]}"
        return 0
    elif [[ -n "$default" ]]; then
        echo "$default"
        return 0
    fi

    return 1
}

# Get packages for a recipe using the specified method
# Usage: zinstall.recipe.install_packages <recipe_name> [method]
# If method is empty, uses zinstall.recipe.install_method to determine it
# Echoes the packages to install, or returns error if none found
zinstall.recipe.install_packages() {
    local recipe_name="$1"
    local method="${2:-}"

    zinstall.init

    local recipe_file="${_zinstall_files[$recipe_name]}"
    if [[ -z "$recipe_file" ]]; then
        echo "❌ Recipe not found: $recipe_name" >&2
        return 1
    fi

    # Resolve method if not provided
    if [[ -z "$method" ]]; then
        method=$(zinstall.recipe.install_method "$recipe_name")
        if [[ -z "$method" ]]; then
            echo "❌ No install method found for $recipe_name" >&2
            return 1
        fi
    fi

    # Get packages for method
    local packages=$(zinstall.recipe.field "$recipe_name" "$method")
    [[ "$method" == "custom" ]] && packages=$(zinstall.recipe.field "$recipe_name" "install_cmd")

    if [[ -z "$packages" ]]; then
        echo "❌ No packages defined for method '$method' in recipe '$recipe_name'" >&2
        return 1
    fi

    echo "$packages"
}

# Get dependencies for a recipe
# Usage: zinstall.recipe.dependencies <recipe_name>
# Echoes the dependencies (space-separated), or nothing if none defined
zinstall.recipe.dependencies() {
    local recipe_name="$1"

    zinstall.init

    local recipe_file="${_zinstall_files[$recipe_name]}"
    if [[ -z "$recipe_file" ]]; then
        echo "❌ Recipe not found: $recipe_name" >&2
        return 1
    fi

    # Get dependencies field
    zinstall.recipe.field "$recipe_name" "depends"
}

# === Repository Setup Dispatcher ===
# Dispatches to method-specific handlers based on recipe[method_repo]
zinstall.repo.setup() {
    local repo_type="${method}_repo"
    [[ -n ${recipe[$repo_type]} ]] || return 0
    _zinstall.repo.${method}.setup "${recipe[$repo_type]}"
}

# === Brew Repo Handler ===
zinstall.repo.brew.setup() {
    local tap
    for tap in ${=recipe[brew_tap]}; do
        brew tap | grep -q "^$tap$" && continue
        echo "   Tapping $tap..."
        brew tap "$tap"
    done
}

# === APT Repo Handler ===
# Format: key_url|keyring_name|repo_line
zinstall.repo.apt.setup() {
    local config="$1"
    local parts=("${(@s:|:)config}")
    local key_url="${parts[1]}"
    local keyring_name="${parts[2]}"
    local repo_line="${parts[3]}"

    local keyring_path=$(zinstall.repo.apt.keyring.setup "$key_url" "$keyring_name")
    repo_line=$(zinstall.repo.apt.template.render "$repo_line" "$keyring_path")

    # Inject signed-by if keyring present but not in template
    if [[ -n "$keyring_path" && $repo_line != *"signed-by="* ]]; then
        repo_line="${repo_line/deb /deb [signed-by=$keyring_path] }"
    fi

    local list_file="/etc/apt/sources.list.d/${recipe[name]}.list"
    [[ "$(cat "$list_file" 2>/dev/null)" != "$repo_line" ]] && {
        echo "   Configuring apt source..."
        echo "$repo_line" | sudo tee "$list_file" >/dev/null
        sudo apt update -qq
    }
}

# === DNF Repo Handler ===
zinstall.repo.dnf.setup() {
    local repo_url="$1"
    local repo_filename="${repo_url:t}"
    [[ -f "/etc/yum.repos.d/$repo_filename" ]] && return
    echo "   Adding dnf repo..."
    sudo dnf config-manager --add-repo "$repo_url"
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

    # Handle github specially (parses app:repo@version)
    if [[ "$method" == "github" ]]; then
        local app=${pkgs%%:*}
        local rest=${pkgs#*:}
        local repo=${rest%%@*}
        local version=${rest#*@}
        _gh_install_release "$app" "$repo" "$version"
    # Handle custom specially (function or eval)
    elif [[ "$method" == "custom" ]]; then
        if functions ${pkgs} >/dev/null; then
            ${pkgs}
        else
            eval "${pkgs}"
        fi
    # Standard methods via dictionary lookup
    elif [[ -n ${_zinstall_commands[$method]} ]]; then
        ${=_zinstall_commands[$method]} ${=pkgs}
    else
        echo "❌ No suitable installation method found or no packages defined." >&2
        return 1
    fi
}

# === Hook Execution Helper ===
# Executes pre/post install hooks from recipe
# Usage: zinstall.recipe.hooks.run <recipe_name> <hook_name>
# Hooks can be function names or shell code strings
zinstall.recipe.hooks.run() {
    local recipe_name="$1"
    local hook_name="$2"

    # Ensure recipes are loaded
    zinstall.init

    # Load recipe file and run hook in subshell
    local recipe_file="${_zinstall_files[$recipe_name]}"
    [[ -n "$recipe_file" ]] || return 0

    (
        typeset -A recipe
        source "$recipe_file"

        local hook_value="${recipe[$hook_name]:-}"
        [[ -n "$hook_value" ]] || return 0

        echo "   Running ${hook_name}..."
        functions ${hook_value} >/dev/null && ${hook_value} || eval "${hook_value}"
    )
}

# === Template Renderer ===
# Renders template tokens: %CODENAME%, %ARCH%, %DISTRO%, %KEYRING%
zinstall.repo.apt.template.render() {
    local template="$1"
    local keyring_path="${2:-}"

    local -A vars=(
        [CODENAME]=$(lsb_release -cs 2>/dev/null || echo "stable")
        [ARCH]=$(dpkg --print-architecture 2>/dev/null || echo "amd64")
        [DISTRO]=$(lsb_release -is 2>/dev/null | tr "[:upper:]" "[:lower:]" || echo "debian")
        [KEYRING]=$keyring_path
    )

    for token in "${(@k)vars}"; do
        template="${template//%${token}%/${vars[$token]}}"
    done
    echo "$template"
}

# === Keyring Handler ===
# Downloads and configures GPG keyring for apt repos
zinstall.repo.apt.keyring.setup() {
    local key_url="$1"
    local keyring_name="$2"

    # Skip if null
    [[ -n "$keyring_name" && "$keyring_name" != "null" ]] || return 0

    local keyring_path="/usr/share/keyrings/$keyring_name"
    [[ -f "$keyring_path" ]] || {
        echo "   Downloading GPG key..."
        curl -fsSL "$key_url" | sudo gpg --dearmor -o "$keyring_path" --yes
    }
    echo "$keyring_path"
}

# Install a package (from recipe)
# Usage: zinstall.install <package_name_or_binary>
zinstall.install() {
    local target="$1"
    zinstall.init
    local recipe_id=$(zinstall.recipe.find_by_binary "$target")

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

    # 1.5. Idempotency Check (using cached data)
    # Only check if 'provides' is set. Dependencies that don't provide a binary
    # (e.g. libraries, meta-packages) should always proceed to the installer,
    # which should itself be idempotent.
    local provides name
    provides=$(zinstall.recipe.field "$recipe_id" "provides")
    name=$(zinstall.recipe.field "$recipe_id" "name")
    if [[ -n "$provides" ]]; then
        local cmd
        for cmd in ${=provides}; do
            if command -v "$cmd" >/dev/null 2>&1; then
                echo "✅ ${name} is already installed (found '$cmd')."
                _zinstall_stack=(${_zinstall_stack[1,-2]})
                return 0
            fi
        done
    fi

    # Source the recipe in a subshell/block to execute logic
    (
        typeset -A recipe
        source "$recipe_file"

        echo "   Installing ${recipe[name]}..."

        # 2. Handle Dependencies using helper
        local deps
        deps=$(zinstall.recipe.dependencies "$recipe_id")
        if [[ -n "$deps" ]]; then
            echo "   Installing dependencies for ${recipe[name]}: $deps..."
            zinstall.ensure ${=deps} || return 1
        fi

        # 3. Pre-install
        zinstall.recipe.hooks.run "$recipe_id" pre_install

        # 4. Determine Installation Method (Precedence)
        local method=$(zinstall.recipe.install_method "$recipe_id")
        if [[ -z "$method" ]]; then
            echo "   Not applicable: no matching installer found for current OS ($(uname -s)). Skipping."
            return 0
        fi

        # 5. Repo/Environment Setup
        zinstall.repo.setup

        # 6. Perform Installation via helper
        if _zinstall_run_installer; then
            # 7. Post Install
            zinstall.recipe.hooks.run "$recipe_id" post_install
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

# Execute a command, installing it if not found in PATH
# Usage: zinstall.exec <command> [args...]
zinstall.exec() {
    local cmd="$1"
    shift  # Remove cmd from "$@", leaving only the arguments

    # Check if command exists in PATH
    if command -v "$cmd" >/dev/null 2>&1; then
        "$cmd" "$@"
        return $?
    fi

    # Command not found - attempt to install it
    echo "🔍 Command '$cmd' not found. Attempting to install..." >&2

    if ! zinstall.install "$cmd"; then
        echo "❌ Failed to install '$cmd'" >&2
        return 1
    fi

    # Retry execution after installation
    if command -v "$cmd" >/dev/null 2>&1; then
        "$cmd" "$@"
        return $?
    fi

    echo "❌ Command '$cmd' still not found after installation" >&2
    return 1
}
