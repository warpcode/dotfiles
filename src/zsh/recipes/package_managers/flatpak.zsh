typeset -A recipe=(
    [name]="flatpak"
    [provides]="flatpak"
    [installer]=true
    [installer_precedence]=4
    [installer_install]='
        local pkgs=($(pkg.field "$1" flatpak))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec flatpak install -y "${pkgs[@]}"
    '
    [installer_check]='
        local pkgs=($(pkg.field "$1" flatpak)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            pkg.exec flatpak info "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    [installer_exec]='
        local pkgs=($(pkg.field "$1" flatpak))
        shift 2
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        pkg.exec flatpak run "${pkgs[@]}" "$@"
    '

    # This recipe itself is installable via other managers:
    [apt]="flatpak"
    [dnf]="flatpak"
    [pacman]="flatpak"
    [post_install]='
        pkg.exec flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '
)
