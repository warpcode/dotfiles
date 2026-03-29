# pkg.zsh - Staged Package Installer
# Usage: source src/zsh/functions/pkg.zsh && pkg.install_all

typeset -gA pkg_recipes pkg_action pkg_exists
typeset -ga pkg_list PKG_MANAGER_PRIORITY=(flatpak mise snap uv npm cargo brew brew_cask apt dnf pacman)

# --- Recipe Definition ---
pkg.define() {
    local rid="${1//-/_}"; shift
    (( ! ${pkg_exists[$rid]:-0} )) && { pkg_list+=($rid); pkg_exists[$rid]=1 }
    for pair in "$@"; do
        local k="${pair%%=*}" v="${pair#*=}"
        pkg_recipes[$rid:$k]="$v"
        [[ "$k" == managers ]] && for m in ${=v}; do
            (( ${PKG_MANAGER_PRIORITY[(Ie)$m]} )) || PKG_MANAGER_PRIORITY+=($m)
        done
    done
}

pkg.load_recipes() {
    local f; for f in "${DOTFILES}/src/zsh/recipes/"**/*.zsh; do [[ -f "$f" ]] && source "$f"; done
}

# --- Action Compilation ---
pkg.compile_actions() {
    local rid c=0 total=${#pkg_list}
    pkg_action=()
    for rid in "${pkg_list[@]}"; do
        printf "\r🔍 Compiling: %d/%d (%s)..." "$((++c))" "$total" "$rid" >&2
        pkg_action[$rid]=$(pkg.recipeAction "$rid")
    done
    printf "\r\033[K" >&2
}

# --- Manager Interface ---
pkg.manager_func() {
    local f m func=$1; shift
    for m in "${PKG_MANAGER_PRIORITY[@]}"; do
        f="pkg.managers.$m.$func"
        (( ${+functions[$f]} )) && { "$f" "$@" || return $? }
    done
}

# --- Helper Logic ---
pkg.isLoaded() { (( ${pkg_exists[${1//-/_}]:-0} )) }
pkg.actionIsEnabled() { [[ "$1" == (install*|upgrade*|defer) ]] }
pkg.isSatisfied() { [[ "$(pkg.recipeAction "$1")" == (skip|upgrade:*) ]] }

pkg.installable() {
    local m; for m in "${PKG_MANAGER_PRIORITY[@]}"; do
        (( ${+functions[pkg.managers.$m.is_available]} )) || continue
        "pkg.managers.$m.is_available" || continue
        (( ${+functions[pkg.managers.$m.search]} )) && "pkg.managers.$m.search" "$1" && return 0
    done
    return 1
}

# --- Core Action Resolver ---
pkg.recipeAction() {
    local rid="${1//-/_}" m dep any_enabled=0 res
    [[ -n "${pkg_action[$rid]}" ]] && { echo "${pkg_action[$rid]}"; return 0; }
    pkg.isLoaded "$rid" || { echo "unavailable"; return 1; }

    # 1. Resolve Dependencies
    for dep in ${=pkg_recipes[$rid:deps]}; do
        pkg.isSatisfied "$dep" || { res="defer"; break; }
    done

    # 2. Check Managers (Priority Order)
    if [[ -z "$res" ]]; then
        local -a managers=( ${=pkg_recipes[$rid:managers]:-"${PKG_MANAGER_PRIORITY[@]}"} )
        local -a valid=()
        for m in "${managers[@]}"; do
            (( ${+functions[pkg.managers.$m.enabled]} )) || continue
            "pkg.managers.$m.enabled" || continue
            any_enabled=1
            (( ${+functions[pkg.managers.$m.is_available]} )) || { res="defer"; break; }
            "pkg.managers.$m.is_available" || { res="defer"; break; }
            valid+=($m)
        done

        if [[ -z "$res" ]]; then
            if (( any_enabled == 0 )); then res="skip"
            else
                for m in "${valid[@]}"; do
                    "pkg.managers.$m.check" "$rid" 2>/dev/null && { res="upgrade:$m"; break; }
                done
                if [[ -z "$res" ]]; then
                    for m in "${valid[@]}"; do
                        (( ${+functions[pkg.managers.$m.search]} )) && "pkg.managers.$m.search" "$rid" && { res="install:$m"; break; }
                    done
                fi
            fi
        fi
    fi

    res="${res:-unavailable}"
    pkg_action[$rid]="$res"
    echo "$res"
}

# --- Utils ---
pkg.recipeManagers() {
    local rid="${1//-/_}"
    echo "${pkg_recipes[$rid:managers]:-${PKG_MANAGER_PRIORITY[*]}}"
}

pkg.recipePackages() {
    local rid="${1//-/_}" pkg
    if [[ -n "$2" ]]; then
        pkg="${pkg_recipes[$rid:$2]}"
    fi
    echo "${pkg:-${pkg_recipes[$rid:package]}}"
}

pkg.recipesByAction() {
    local rid target=$1; for rid in "${pkg_list[@]}"; do [[ "${pkg_action[$rid]}" == "$target" ]] && echo "$rid"; done
}

# --- Main Entry Point ---
pkg.install_all() {
    echo "🔧 Starting staged installation..."
    pkg.load_recipes
    local pass=0 max=10
    while (( pass++ < max )); do
        pkg.manager_func setup_repos
        pkg.compile_actions

        local -a pending=()
        for m in "${PKG_MANAGER_PRIORITY[@]}"; do
            local r=$(pkg.recipesByAction "install:$m")
            [[ -n "$r" ]] && pending+=("install:$m -> $r")
        done

        (( ${#pending} == 0 )) && { echo "✨ Finished in $((pass-1)) passes."; break; }
        echo "🔄 Pass $pass: ${(j:, :)pending}"
        pkg.manager_func install || { echo "❌ Failed."; return 1; }
    done
    pkg.manager_func cleanup
    echo "✨ Complete!"
}
