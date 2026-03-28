# pkg.zsh - Staged Package Installer
#
# Usage: source src/zsh/functions/pkg.zsh && pkg.install_all
#
# Recipe format:
#   pkg.define <name> \
#       package="<name>" \
#       managers="<manager1> <manager2> ..." \
#       <manager>="<override_name>"  # Optional override
#
# Note: Manager modules are auto-loaded by init.zsh

# Global recipe storage: pkg_recipes[recipe_id:key]=value
typeset -gA pkg_recipes

# Package list: all recipe names
typeset -ga pkg_list

# Default manager priority order (used when recipe doesn't specify managers)
typeset -ga PKG_MANAGER_PRIORITY=(flatpak mise snap uv npm cargo brew brew_cask apt dnf pacman)

# Action state: pkg_action[rid]="skip|defer|install|upgrade|unavailable"
typeset -gA pkg_action

# --- Recipe Definition ---

pkg.define() {
    local rid="$1"; shift
    local norm_id="${rid//-/_}"
    local pair key val

    # Store raw recipe data
    for pair in "$@"; do
        key="${pair%%=*}"
        val="${pair#*=}"
        pkg_recipes[${norm_id}:${key}]="$val"

        # If this is the managers field, ensure all listed managers are in priority list
        if [[ "$key" == "managers" ]]; then
            local m
            for m in ${=val}; do
                if [[ ! " ${PKG_MANAGER_PRIORITY[*]} " == *" $m "* ]]; then
                    PKG_MANAGER_PRIORITY+=("$m")
                fi
            done
        fi
    done

    # Add to package list
    pkg_list+=("$norm_id")
}

# Load all recipe files from disk
pkg.load_recipes() {
    local recipe_file
    for recipe_file in "${DOTFILES}/src/zsh/recipes/"**/*.zsh; do
        [[ -f "$recipe_file" ]] || continue
        source "$recipe_file"
    done
}

# Compile actions for all recipes based on current system state
pkg.compile_actions() {
    local rid total count
    total=${#pkg_list[@]}
    count=0

    # Clear current actions to force recalculation if this is a new pass
    # Actually, pkg.install_all should do this or we can do it here.
    # We'll do it here to be safe.
    pkg_action=()

    for rid in "${pkg_list[@]}"; do
        ((count++))
        printf "\r🔍 Compiling actions: %d/%d (%s)..." "$count" "$total" "$rid" >&2
        pkg_action[$rid]=$(pkg.recipeAction "$rid")
    done
    printf "\r\033[K" >&2  # Clear progress line
}

# Run package manager func
pkg.manager_func() {
    local func=$1; shift;
    local m
    for m in "${PKG_MANAGER_PRIORITY[@]}"; do
        local setup_func="pkg.managers.${m}.${func}"
        if typeset -f "$setup_func" >/dev/null 2>&1; then
            "$setup_func" "$@" || return $?
        fi
    done
}

# Check if a recipe is installable via any available manager
pkg.installable() {
    local rid="$1"
    local m

    for m in "${PKG_MANAGER_PRIORITY[@]}"; do
        pkg.managers.${m}.is_available || continue
        typeset -f "pkg.managers.${m}.search" >/dev/null 2>&1 || continue

        if pkg.managers.${m}.search "$rid"; then
            return 0
        fi
    done
    return 1
}

# Check if a recipe is loaded
pkg.isLoaded() {
    local rid="$1"
    local norm_id="${rid//-/_}"
    local r
    for r in "${pkg_list[@]}"; do
        [[ "$r" == "$norm_id" ]] && return 0
    done
    return 1
}

# Check if an action means the manager is enabled (install/upgrade/defer)
pkg.actionIsEnabled() {
    local action="$1"
    [[ "$action" == "install"* || "$action" == "upgrade"* || "$action" == "defer" ]]
}

# Get all recipes with a specific action value (e.g., "install", "defer", "skip")
pkg.recipesByAction() {
    local target="$1"
    local rid
    for rid in "${pkg_list[@]}"; do
        [[ "${pkg_action[$rid]}" == "$target" ]] && echo "$rid"
    done
}

# Get package name for a recipe
# Usage: pkg.recipePackages <rid> [manager]
pkg.recipePackages() {
    local rid="$1"
    local norm_id="${rid//-/_}"
    local manager="$2"

    if [[ -n "$manager" ]]; then
        # Check if manager is valid for this recipe
        local managers=(${=$(pkg.recipeManagers "$rid")})
        local m
        for m in "${managers[@]}"; do
            [[ "$m" == "$manager" ]] && break
        done
        # If manager is valid, return manager-specific package
        if [[ "$m" == "$manager" ]]; then
            local pkg="${pkg_recipes[${norm_id}:${manager}]}"
            echo "${pkg:-${pkg_recipes[${norm_id}:package]}}"
            return
        fi
    fi
    # Fall back to generic package
    echo "${pkg_recipes[${norm_id}:package]}"
}

# Check if a recipe is already satisfied (skip or upgrade:*)
pkg.isSatisfied() {
    local rid="$1"
    local action=$(pkg.recipeAction "$rid")
    [[ "$action" == "skip" || "$action" == "upgrade"* ]]
}
# Determine action for a recipe: skip|defer|install|upgrade|unavailable
pkg.recipeAction() {
    local rid="$1" norm_id="${1//-/_}" m dep
    local -a valid_managers=()
    local any_enabled=0

    # Check if recipe is loaded
    ! pkg.isLoaded "$rid" && { echo "unavailable"; return 1; }

    # Return cached action if already processed in this pass
    [[ -n "${pkg_action[$rid]}" ]] && { echo "${pkg_action[$rid]}"; return 0; }

    # Check dependencies (circular dependency prevention not included for brevity)
    for dep in ${=pkg_recipes[${norm_id}:deps]}; do
        ! pkg.isSatisfied "$dep" && { echo "defer"; return 0; }
    done

    # Phase 1: Filter enabled managers and check availability
    for m in ${=$(pkg.recipeManagers "$rid")}; do
        typeset -f "pkg.managers.${m}.enabled" >/dev/null 2>&1 || continue
        pkg.managers.${m}.enabled || continue

        any_enabled=1
        pkg.managers.${m}.is_available || { echo "defer"; return 0; }
        valid_managers+=("$m")
    done

    # Decision: Skip if none enabled
    [[ $any_enabled -eq 0 ]] && { echo "skip"; return 0; }

    # Phase 2: Check if already installed via ANY valid manager
    # This prevents duplicate installs across different managers
    for m in "${valid_managers[@]}"; do
        pkg.managers.${m}.check "$rid" 2>/dev/null && { echo "upgrade:$m"; return 0; }
    done

    # Phase 3: Find best valid manager with package in repo
    for m in "${valid_managers[@]}"; do
        if typeset -f "pkg.managers.${m}.search" >/dev/null 2>&1; then
            pkg.managers.${m}.search "$rid" && { echo "install:$m"; return 0; }
        fi
    done

    echo "unavailable"
}

# Get ordered list of managers for a recipe
pkg.recipeManagers() {
    local rid="$1"
    local norm_id="${rid//-/_}"
    local managers_field="${pkg_recipes[${norm_id}:managers]}"
    echo "${managers_field:-${PKG_MANAGER_PRIORITY[*]}}"
}

# --- Installation ---


pkg.install_all() {
    echo "🔧 Starting package installation..."

    # Phase 1: Load all recipes to populate metadata (keys, repos, etc)
    pkg.load_recipes

    local pass=0
    local max_passes=10

    while [[ $pass -lt $max_passes ]]; do
        ((pass++))

        # Phase 2: Setup repositories for all managers idempotently
        # This is inside the loop so newly installed managers get setup
        pkg.manager_func setup_repos

        # Phase 3: Recalculate actions based on current system state
        pkg.compile_actions

        # Check for any pending installs
        local pending_installs=()
        local m
        for m in "${PKG_MANAGER_PRIORITY[@]}"; do
            local recipes=$(pkg.recipesByAction "install:$m")
            [[ -n "$recipes" ]] && pending_installs+=("install:$m -> $recipes")
        done

        if [[ ${#pending_installs[@]} -eq 0 ]]; then
            echo "✨ No pending installations. Finished after Pass $((pass-1))."
            break
        fi

        echo "🔄 Pass $pass..."
        local p
        for p in "${pending_installs[@]}"; do
            echo "   $p"
        done

        # Phase 4: Run installation for all managers
        pkg.manager_func install || { echo "❌ Critical: Installation failed. Terminating."; return 1; }
    done

    # Final cleanup for all managers
    echo "🧹 Running cleanup..."
    pkg.manager_func cleanup

    echo "=============================================="
    echo "✨ Installation complete!"
}
