# pkg.zsh - Staged Package Installer

typeset -gA pkg_recipes pkg_action pkg_exists
typeset -ga pkg_list PKG_MANAGER_PRIORITY=(flatpak mise snap uv npm cargo brew brew_cask apt dnf pacman)

# --- Recipe Definition ---
pkg.define() {
    local rid="${1//-/_}"; shift
    (( ! ${pkg_exists[$rid]:-0} )) && { pkg_list+=($rid); pkg_exists[$rid]=1 }
    local pair k v m
    for pair in "$@"; do
        k="${pair%%=*}" v="${pair#*=}"
        pkg_recipes[$rid:$k]="$v"
        [[ "$k" == managers ]] && for m in ${=v}; do
            (( ${PKG_MANAGER_PRIORITY[(Ie)$m]} )) || PKG_MANAGER_PRIORITY+=($m)
        done
    done
}

pkg.load_recipes() {
    local base; base=$(fs.dotfiles.path "src/zsh/recipes") || return 1
    local f; for f in "$base/"**/*.zsh(N); do source "$f"; done
}

# --- Action Compilation ---
pkg.compile_actions() {
    local rid c=0 total=${#pkg_list}
    pkg_action=()
    for rid in "${pkg_list[@]}"; do
        print -Pn "\r🔍 Compiling: $((++c))/$total ($rid)..." >&2
        pkg_action[$rid]=$(pkg.recipe_action "$rid")
    done
    print -Pn "\r\033[K" >&2
}

# --- Manager Interface ---
pkg.manager_func() {
    local f m func=$1; shift
    for m in "${PKG_MANAGER_PRIORITY[@]}"; do
        f="pkg.managers.$m.$func"
        (( $+functions[$f] )) && { "$f" "$@" || return $? }
    done
}

# --- Helper Logic ---
pkg.is_loaded() { (( ${pkg_exists[${1//-/_}]:-0} )) }
pkg.action_is_enabled() { [[ "$1" == (install*|upgrade*|defer) ]] }
pkg.is_satisfied() { [[ "$(pkg.recipe_action "$1")" == (skip|upgrade:*) ]] }

pkg.installable() {
    local m; for m in "${PKG_MANAGER_PRIORITY[@]}"; do
        (( $+functions[pkg.managers.$m.is_available] )) || continue
        "pkg.managers.$m.is_available" || continue
        (( $+functions[pkg.managers.$m.search] )) && "pkg.managers.$m.search" "$1" && return 0
    done
    return 1
}

# --- Core Action Resolver ---
pkg.recipe_action() {
    local rid="${1//-/_}" m dep any_enabled=0 res
    [[ -n "${pkg_action[$rid]}" ]] && { echo "${pkg_action[$rid]}"; return 0; }
    pkg.is_loaded "$rid" || return 1

    # 1. Resolve Dependencies
    for dep in ${=pkg_recipes[$rid:deps]}; do
        pkg.is_satisfied "$dep" || { res="defer"; break; }
    done

    # 2. Check Managers
    if [[ -z "$res" ]]; then
        local -a managers=( ${=pkg_recipes[$rid:managers]:-"${PKG_MANAGER_PRIORITY[@]}"} )
        local -a valid=()
        for m in "${managers[@]}"; do
            (( $+functions[pkg.managers.$m.enabled] )) || continue
            "pkg.managers.$m.enabled" || continue
            any_enabled=1
            (( $+functions[pkg.managers.$m.is_available] )) || { res="defer"; break; }
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
                        (( $+functions[pkg.managers.$m.search] )) && "pkg.managers.$m.search" "$rid" && { res="install:$m"; break; }
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
pkg.status() {
    local rid="${1//-/_}"
    pkg.is_loaded "$rid" || return 1
    pkg.is_satisfied "$rid"
}

pkg.recipe_managers() {
    local rid="${1//-/_}"
    echo "${pkg_recipes[$rid:managers]:-${PKG_MANAGER_PRIORITY[*]}}"
}

pkg.recipe_packages() {
    local rid="${1//-/_}" pkg
    [[ -n "$2" ]] && pkg="${pkg_recipes[$rid:$2]}"
    echo "${pkg:-${pkg_recipes[$rid:package]}}"
}

pkg.recipes_by_action() {
    local rid target=$1; for rid in "${pkg_list[@]}"; do [[ "${pkg_action[$rid]}" == "$target" ]] && echo "$rid"; done
}

# --- Main Entry Point ---
pkg.install_all() {
    print -P "%F{blue}🔧 Starting staged installation...%f"
    pkg.load_recipes
    local pass=0 max=10
    while (( pass++ < max )); do
        pkg.manager_func setup_repos
        pkg.compile_actions

        local -a pending=()
        for m in "${PKG_MANAGER_PRIORITY[@]}"; do
            local r=$(pkg.recipes_by_action "install:$m")
            [[ -n "$r" ]] && pending+=("install:$m -> $r")
        done

        (( ${#pending} == 0 )) && { print -P "%F{green}✨ Finished in $((pass-1)) passes.%f"; break; }
        echo "🔄 Pass $pass: ${(j:, :)pending}"
        pkg.manager_func install || { print -P "%F{red}❌ Failed.%f"; return 1; }
    done
    pkg.manager_func cleanup
    print -P "%F{green}✨ Complete!%f"
}
