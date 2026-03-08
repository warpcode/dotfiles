# pkg.zsh - Modular Recipe-Driven Package & Command Manager
#
# This system implements the "Recipe Contract v3", allowing for deep dependency
# chaining, virtual command execution (exec closures), and proxy-based meta-packages.

# Global State (Internal)
typeset -gA _pkg_recipes           # Cached recipe data: [recipe_id:field]=value
typeset -gA _pkg_files             # Maps recipe_id to absolute file path
typeset -gA _pkg_cmds              # Maps binary/command name to recipe_id
typeset -ga _pkg_installers        # Sorted list of installer names by precedence
typeset -gA _pkg_repo_updated      # Maps installer_rid to 1 if updated in session
typeset -gA _pkg_repo_dirty        # Maps installer_rid to 1 if extensions changed system state

# --- Initialization ---

# @description Main entry point. Recursively scan the recipes directory and load all .zsh recipe files.
pkg.init() {
    [[ ${#_pkg_files[@]} -gt 0 ]] && return

    local recipes_dir="${DOTFILES}/src/zsh/recipes"
    local f recipe_id key cmd
    local -A tmp_installers=() # Collect precedence locally (rid -> prec)

    for f in "$recipes_dir"/**/*.zsh(N); do
        recipe_id="${f:t:r}"

        # Reset local recipe array for each file
        unset recipe
        typeset -A recipe
        source "$f"

        # Every recipe must have a name
        [[ -z "${recipe[name]}" ]] && continue

        _pkg_files[$recipe_id]="$f"

        # Cache all fields: [recipe_id:field]=value
        for key in "${(@k)recipe}"; do
            _pkg_recipes["$recipe_id:$key"]="${recipe[$key]}"
        done

        # Map provides/name to recipe ID
        local -a provides=(${=recipe[provides]})
        [[ ${#provides} -eq 0 ]] && provides=("${recipe[name]}")

        for cmd in "${provides[@]}"; do
            _pkg_cmds[$cmd]="$recipe_id"
        done

        # If the recipe provides an installer, register its precedence
        if [[ "${recipe[installer]}" == "true" ]]; then
            tmp_installers[$recipe_id]="${recipe[installer_precedence]:-999}"
        fi
    done

    # Sort installers by precedence (ascending) into the global _pkg_installers array
    local -a sort_helper=()
    local rid
    for rid in "${(@k)tmp_installers}"; do
        sort_helper+=("${(l:3::0:)tmp_installers[$rid]}:$rid")
    done

    _pkg_installers=()
    for item in "${(@on)sort_helper}"; do
        _pkg_installers+=("${item#*:}")
    done
}

# --- Recipe Accessors ---

# @description Find the recipe ID that provides a given binary or command.
# @param $1 string The binary or command name.
pkg.find() {
    local target="$1"
    pkg.init

    if [[ -n "${_pkg_cmds[$target]}" ]]; then
        print -r -- "${_pkg_cmds[$target]}"
        return 0
    else
        # If not found in provides, check if target itself is a recipe ID
        if [[ -n "${_pkg_files[$target]}" ]]; then
            print -r -- "$target"
            return 0
        fi
    fi

    return 1
}

# @description Retrieve a specific field's value from a loaded recipe.
# @param $1 string The recipe ID.
# @param $2 string The field name.
# @param $3 string [Optional] Default value if field is missing.
pkg.field() {
    local rid="$1" field="$2" default="${3:-}"
    local key="${rid}:${field}"
    pkg.init

    if [[ -n "${_pkg_recipes["$key"]}" ]]; then
        print -r -- "${_pkg_recipes["$key"]}"
    else
        print -r -- "$default"
    fi
}

# @description Check if a recipe is installable in the current environment.
# @param $1 string The recipe ID.
# @return 0 if installable, 1 otherwise.
pkg.is_installable() {
    pkg.init
    local rid="$1"

    # 1. If already installed, it's satisfied
    pkg.status "$rid" && return 0

    # 2. Global visibility check
    pkg.hook "$rid" "enabled" || return 1

    # 3. Check if there is an available installer for this recipe
    local installer_rid pkg_name
    for installer_rid in "${_pkg_installers[@]}"; do
        pkg_name=$(pkg.field "$rid" "$installer_rid")
        [[ -z "$pkg_name" ]] && continue

        # Is the installer itself allowed to run here?
        if pkg.hook "$installer_rid" "installer_enabled"; then
            return 0
        fi
    done

    return 1
}
# --- Hook Engine ---

# @description Execute a lifecycle hook, closure, or command string from a recipe.
# @param $1 string The recipe ID.
# @param $2 string The hook field name (e.g., 'exec', 'pre_install').
# @param $@ remaining arguments passed to the hook.
pkg.hook() {
    pkg.init
    local rid="$1" hook_name="$2"; shift 2
    local val=$(pkg.field "$rid" "$hook_name")
    [[ -z "$val" ]] && return 0

    # Ensure recipe file is sourced so local functions are available
    local f="${_pkg_files[$rid]}"
    [[ -f "$f" ]] && source "$f"

    # 1. If it's a defined function, call it directly
    if functions "$val" >/dev/null; then
        "$val" "$@"
        return $?
    fi

    # 2. Treat as a command string/anonymous function.
    # We wrap it in an anonymous function to provide local scope ($1, $2, etc.)
    # and isolate the execution context.
    () {
        local hook_logic="$1"; shift
        eval "$hook_logic"
    } "$val" "$@"
}

# @description Helper to dispatch installer-specific extensions for a recipe.
# @param $1 string Target recipe ID.
# @param $2 string Extension registration field name.
# @param $3 integer [Optional] If 1, handle the 'dirty' repo signal (exit code 2).
pkg.hooks.ext() {
    local rid="$1" hook_field="$2" handle_dirty="${3:-0}"
    local method=$(pkg.detect_installer "$rid")
    [[ -z "$method" ]] && return 0

    local exts=($(pkg.field "$method" "$hook_field"))
    local ext

    for ext in "${exts[@]}"; do
        # Pass only $rid — installer_ext_<name> fetches what it needs from pkg.field
        pkg.hook "$method" "installer_ext_$ext" "$rid"
        [[ "$handle_dirty" -eq 1 ]] && [[ $? -eq 2 ]] && _pkg_repo_dirty["$method"]=1
    done
}

# --- Status & Dependency Resolution ---

# @description Check if a recipe is currently installed or satisfied.
# @param $1 string The recipe ID or binary name.
# @return 0 if satisfied (binary on PATH or provider confirms), 1 otherwise.
pkg.status() {
    pkg.init
    local target="$1"
    local rid=$(pkg.find "$target")
    [[ -z "$rid" ]] && return 1

    # 1. Quick check: provides binary on PATH
    local provides=$(pkg.field "$rid" "provides")
    if [[ -n "$provides" ]]; then
        local cmd
        for cmd in ${=provides}; do
            if command -v "$cmd" >/dev/null 2>&1; then
                return 0
            fi
        done
    fi

    # 2. Proxy check: if proxy=true, it is "installed" if its deps are met.
    if [[ "$(pkg.field "$rid" "proxy")" == "true" ]]; then
        local deps=($(pkg.field "$rid" "depends"))
        local dep satisfied=0
        if [[ ${#deps[@]} -gt 0 ]]; then
            satisfied=1
            for dep in "${deps[@]}"; do
                if ! pkg.status "$dep"; then
                    satisfied=0
                    break
                fi
            done
            [[ $satisfied -eq 1 ]] && return 0
        fi
    fi

    # 3. Exhaustive check: registered installers (in order of precedence)
    local installer_rid pkg_name
    for installer_rid in "${_pkg_installers[@]}"; do
        # Does this recipe have a package defined for this installer?
        pkg_name=$(pkg.field "$rid" "$installer_rid")
        [[ -z "$pkg_name" ]] && continue

        # Is the installer itself available?
        if pkg.status "$installer_rid"; then
            # Verify the installer actually provides a check hook
            [[ -z "$(pkg.field "$installer_rid" "installer_check")" ]] && continue

            # Pass only $rid — installer_check fetches packages internally
            if pkg.hook "$installer_rid" "installer_check" "$rid" >/dev/null 2>&1; then
                return 0
            fi
        fi
    done

    return 1
}

# @description Determine the best (highest precedence) installer available for a recipe.
# @param $1 string The recipe ID.
# @return 0 and echoes installer recipe ID if found, 1 otherwise.
pkg.detect_installer() {
    pkg.init
    local rid="$1"
    local installer_rid pkg_name

    # Iterate through sorted installers
    for installer_rid in "${_pkg_installers[@]}"; do
        # Does this recipe have a package defined for this installer?
        pkg_name=$(pkg.field "$rid" "$installer_rid")
        [[ -z "$pkg_name" ]] && continue

        # Is the installer itself allowed to run here?
        if pkg.is_installable "$installer_rid"; then
            echo -n "$installer_rid"
            return 0
        fi
    done

    return 1
}

# @description Resolve immediate dependencies for a recipe, including explicit deps and the detected installer.
# @param $1 string The recipe ID.
# @return 0 and echoes space-separated dependency IDs.
pkg.deps() {
    pkg.init
    local rid="$1"
    local -a deps=($(pkg.field "$rid" "depends"))

    # 1. Resolve the best installer for this recipe
    local method=$(pkg.detect_installer "$rid")

    # 2. Always add the installer if found and not already in deps
    if [[ -n "$method" ]] && [[ "$rid" != "$method" ]]; then
        # Check if already in the deps array
        if [[ ${deps[(i)$method]} -gt ${#deps} ]]; then
            deps+=("$method")
        fi
    fi

    echo "${deps[@]}"
}

# @description Build a linearized, deduplicated dependency stack for one or more targets.
# @param $@ strings Target binaries or recipe names.
# @return 0 and echoes space-separated recipe IDs.
pkg.stack() {
    pkg.init
    local -a stack=()
    local -A visiting=()
    local -A seen=()

    _resolve() {
        local rid=$(pkg.find "$1")
        [[ -z "$rid" ]] && return 1

        # Skip if already fully resolved
        [[ -n "${seen[$rid]}" ]] && return 0

        # Cycle detection
        if [[ -n "${visiting[$rid]}" ]]; then
            echo "❌ Dependency cycle detected at $rid" >&2
            return 1
        fi

        visiting[$rid]=1

        # Check if the target itself is installable/valid
        if ! pkg.is_installable "$rid"; then
            echo "❌ Recipe '$rid' is not installable in this environment." >&2
            return 1
        fi

        if pkg.status "$rid"; then
            visiting[$rid]=""
            seen[$rid]=1
            return 0
        fi

        # Resolve dependencies (including implicit installer)
        local -a deps=($(pkg.deps "$rid"))
        local dep
        for dep in "${deps[@]}"; do
            _resolve "$dep" || return 1
        done

        visiting[$rid]=""
        seen[$rid]=1
        stack+=("$rid")
    }

    _resolve "$@" || return 1

    echo "${stack[*]}"
}

# --- Installation & Lifecycle ---

# @description Install the specified targets, resolving all dependencies and running hooks.
# @param $@ strings Target binaries or recipe names.
pkg.install() {
    pkg.init

    local -a stacks=()
    local -A seen=()
    local target recipe_id stack_str i layer method

    # 1. Resolve & Deduplicate Dependency Layers
    for target in "$@"; do
        stack_str=($(pkg.stack "$target"))
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
            local name=$(pkg.field "$recipe_id" name)
            local method=$(pkg.detect_installer "$recipe_id")

            if [[ -n "$method" ]]; then
                groups[$method]+=" $recipe_id"
            else
                echo "❌ No installer available for $name" >&2
                return 1
            fi
        done

        # 3. Execute installation for each method group in the layer
        for method in "${(@k)groups}"; do
            local -a rids=(${=groups[$method]})

            pkg.hook "$method" "pre_install"
            for recipe_id in "${rids[@]}"; do
                pkg.hooks.ext "$recipe_id" "installer_pre_install_ext" 1
                pkg.hook "$recipe_id" "pre_install"
                pkg.repo.update "$method"
            done

            for recipe_id in "${rids[@]}"; do
                local name=$(pkg.field "$recipe_id" name)
                echo "📦 Installing $name via $method"
                pkg.hook "$method" "installer_install" "$recipe_id" || {
                    echo "❌ Installation failed for $name via $method" >&2
                    return 1
                }
            done

            # Run post-install hooks for the group
            for recipe_id in "${rids[@]}"; do
                pkg.hook "$recipe_id" "post_install"
                pkg.hooks.ext "$recipe_id" "installer_post_install_ext"
            done
            pkg.hook "$method" "post_install"

            # Final verification
            for recipe_id in "${rids[@]}"; do
                local name=$(pkg.field "$recipe_id" name)
                if pkg.status "$recipe_id"; then
                    echo "✨ $name installed successfully."
                else
                    echo "⚠️  $name install finished but status check failed." >&2
                fi
            done
        done
    done
}

# @description Refresh the package cache for a specific installation method.
# @param $1 string The recipe ID of the provider.
pkg.repo.update() {
    pkg.init
    local rid="$1"

    if [[ "${_pkg_repo_dirty["$method"]}" -eq 1 ]] || [[ -z "${_pkg_repo_updated["$method"]}" ]]; then
        _pkg_repo_updated["$method"]=1
        _pkg_repo_dirty["$method"]=0

        # Only update if the installer itself is functional/satisfied
        if pkg.status "$rid"; then
            pkg.hook "$rid" "installer_repo_update"
        fi

    fi
}

# --- Command Execution ---

# @description Execute a command, checking PATH first, then status, then installer_exec hooks.
# @param $1 string The command/binary to execute.
# @param $@ remaining arguments passed to the command.
pkg.exec() {
    pkg.init
    local cmd="$1"; shift

    # 1. If binary is in PATH, it always takes precedent
    if command -v "$cmd" >/dev/null 2>&1; then
        command "$cmd" "$@"
        return $?
    fi

    # Find the recipe providing this command
    local rid=$(pkg.find "$cmd")
    if [[ -z "$rid" ]]; then
        echo "📦 Command '$cmd' not found." >&2
        return 127
    fi

    # 2. Check if installed; prompt to install if not
    if ! pkg.status "$cmd"; then
        if read -q "?📦 Command '$cmd' not found. Would you like to install it? [y/N] "; then
            echo
            pkg.install "$cmd" || return 1

            paths.reload

            # Re-check PATH post-install
            if command -v "$cmd" >/dev/null 2>&1; then
                command "$cmd" "$@"
                return $?
            fi
        else
            echo
            return 127
        fi
    fi

    # 3. Command is installed but not in PATH — check for installer_exec hook
    local method=$(pkg.detect_installer "$rid")

    if [[ -n "$method" ]]; then
        # Check for {installer_method}_exec hook on recipe OR installer_exec on the installer
        if [[ -n "$(pkg.field "$rid" "${method}_exec")" || -n "$(pkg.field "$method" "installer_exec")" ]]; then
            pkg.hook "$method" "installer_exec" "$rid" "$cmd" "$@"
            return $?
        fi
    fi

    # 4. Fallback to generic exec hook defined on the recipe itself
    local exec_hook=$(pkg.field "$rid" "exec")
    if [[ -n "$exec_hook" ]]; then
        pkg.hook "$rid" "exec" "$cmd" "$@"
        return $?
    fi

    # 5. No hooks available
    echo "❌ Command '$cmd' is installed but cannot be executed (not in PATH and no execution hooks present)." >&2
    return 127
}
