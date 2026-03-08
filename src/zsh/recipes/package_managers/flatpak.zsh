# flatpak.zsh - Recipe for Flatpak package manager

_flatpak_post_install() {
    if command -v flatpak >/dev/null; then
        echo "   Adding flathub remote..."
        # We use --user to avoid sudo requirements for adding the remote if possible
        # though flatpak itself usually needs sudo to install
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    else
        echo "   ❌ Flatpak not found after install?" >&2
    fi
}

typeset -A recipe=(
    [name]="flatpak"
    [provides]="flatpak"
    [installer]=true
    [installer_precedence]=4
    [installer_install]='
        local pkgs=($(pkg.field "$1" flatpak))
        [[ ${#pkgs[@]} -eq 0 ]] && return 1
        flatpak install -y "${pkgs[@]}"
    '
    [installer_check]='
        local pkgs=($(pkg.field "$1" flatpak)) satisfied=1
        for pkg in "${pkgs[@]}"; do
            flatpak info "$pkg" >/dev/null 2>&1 || { satisfied=0; break; }
        done
        return $((1 - satisfied))
    '
    # This recipe itself is installable via other managers:
    [apt]="flatpak"
    [dnf]="flatpak"
    [pacman]="flatpak"
    [post_install]="_flatpak_post_install"
)
