# pkg.zsh - Staged Package Installer

typeset -gA pkg_action
typeset -ga PKG_MANAGER_PRIORITY=(flatpak mise snap uv npm cargo brew brew_cask apt dnf pacman)

# --- Manager Definition ---
pkg.manager.define() {
    local mid="${1//-/_}"; shift
    registry.define "pkg_manager" "$mid" "$@"
    (( ${PKG_MANAGER_PRIORITY[(Ie)$mid]} )) || PKG_MANAGER_PRIORITY+=($mid)
}

# --- Recipe Definition ---
pkg.recipe.define() {
    local rid="${1//-/_}"; shift
    registry.define "pkg" "$rid" "$@"
    local pair k v m
    for pair in "$@"; do
        [[ "$pair" == *=* ]] || continue
        k="${pair%%=*}" v="${pair#*=}"
        [[ "$k" == managers ]] && for m in ${=v}; do
            (( ${PKG_MANAGER_PRIORITY[(Ie)$m]} )) || PKG_MANAGER_PRIORITY+=($m)
        done
    done
}

# --- Registry Accessors ---
pkg.recipe.get() { registry.get "pkg" "$1" "$2"; }
pkg.recipe.exists() { registry.exists "pkg" "$1"; }

# --- Action Compilation ---
pkg.compile_actions() {
    local rid c=0 total=$(registry.list pkg 2>/dev/null | wc -l)
    pkg_action=()
    local id
    for id in $(registry.list pkg); do
        tui.progress "Compiling: $((++c))/$total ($id)..."
        pkg_action[$id]=$(pkg.recipe.action "$id")
    done
    tui.progress.clear
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
pkg.recipe.action_is_enabled() { [[ "$1" == (install*|upgrade*|defer) ]] }
pkg.recipe.is_satisfied() { [[ "$(pkg.recipe.action "$1")" == (skip|upgrade:*) ]] }

# --- Core Action Resolver ---
pkg.recipe.action() {
    local rid="${1//-/_}" m dep any_enabled=0 res
    [[ -n "${pkg_action[$rid]}" ]] && { echo "${pkg_action[$rid]}"; return 0; }
    pkg.recipe.exists "$rid" || return 1

    # 1. Resolve Dependencies
    for dep in ${=$(pkg.recipe.get "$rid" deps)}; do
        pkg.recipe.is_satisfied "$dep" || { res="defer"; break; }
    done

    # 2. Check Managers
    if [[ -z "$res" ]]; then
        local -a managers=( ${=$(pkg.recipe.get "$rid" managers):-${PKG_MANAGER_PRIORITY[@]}} )
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
pkg.recipe.packages() {
    local rid="${1//-/_}" pkg
    [[ -n "$2" ]] && pkg=$(pkg.recipe.get "$rid" "$2")
    echo "${pkg:-$(pkg.recipe.get "$rid" package)}"
}

pkg.recipe.by_action() {
    local rid target=$1
    for rid in ${(k)pkg_action[@]}; do
        [[ "${pkg_action[$rid]}" == "$target" ]] && echo "$rid"
    done
}

# --- Main Entry Point ---
pkg.install_all() {
    tui.banner "Installing packages in stages..." "=" 46
    local pass=0 max=10
    while (( pass++ < max )); do
        pkg.manager_func setup_repos
        pkg.compile_actions

        local -a pending=()
        for m in "${PKG_MANAGER_PRIORITY[@]}"; do
            local r=$(pkg.recipe.by_action "install:$m")
            [[ -n "$r" ]] && pending+=("install:$m -> $r")
        done

        (( ${#pending} == 0 )) && { tui.done "Finished in $((pass-1)) passes."; break; }
        tui.info "Pass $pass: ${(j:, :)pending}"
        pkg.manager_func install || { tui.fatal "Failed."; return 1; }
    done
    pkg.manager_func cleanup
    tui.done "Complete!"
}

# --- Recipe Lifecycle Hooks ---
pkg.recipe.configure_all() {
    local id rid func
    for id in $(registry.list pkg 2>/dev/null); do
        rid="${id//-/_}"
        func="pkg.recipe.${rid}.configure"
        (( $+functions[$func] )) || continue
        "$func" "$id" || tui.error "$func failed for $id"
    done
}

pkg.recipe.init_all() {
    local id rid func
    for id in $(registry.list pkg 2>/dev/null); do
        rid="${id//-/_}"
        func="pkg.recipe.${rid}.init"
        (( $+functions[$func] )) || continue
        "$func" "$id" || tui.error "$func failed for $id"
    done
}
