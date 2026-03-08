# cargo.zsh - Recipe for Cargo (Rust) package manager

_cargo_post_install() {
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
}

typeset -A recipe=(
    [name]="cargo"
    [provides]="cargo"
    [installer]=true
    [installer_precedence]=9
    [installer_install]='
        local pkgs=($(pkg.field "$1" cargo))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec cargo install "${pkgs[@]}"
    '
    [installer_upgrade]='
        local pkgs=($(pkg.field "$1" cargo))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec cargo install "${pkgs[@]}" # cargo install re-installs/upgrades
    '
    [installer_check]='
        local pkgs=($(pkg.field "$1" cargo)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg.exec cargo install --list | grep -q "^$pkg " || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    [apt]="cargo"
    [dnf]="cargo"
    [pacman]="cargo"
    [brew]="rustup-init"
    # [custom_install]="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    [post_install]="_cargo_post_install"
)
