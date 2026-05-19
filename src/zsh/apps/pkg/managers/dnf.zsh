# dnf.zsh - DNF manager implementation

pkg.manager.define "dnf" \
    "name=DNF" \
    "url=https://dnf.readthedocs.io/"

pkg.managers.dnf.is_available() {
    (( $+commands[dnf] ))
}

pkg.managers.dnf.enabled() {
    pkg.managers.dnf.is_available
}

pkg.managers.dnf.check() {
    pkg.managers.dnf.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" dnf):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        rpm -q "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.dnf.update() {
    pkg.managers.dnf.is_available || return 0
    _pkg.sudo dnf makecache
}

pkg.managers.dnf.cleanup() {
    pkg.managers.dnf.is_available || return 0
    _pkg.sudo dnf autoremove -y && _pkg.sudo dnf clean all
}

pkg.managers.dnf.search() {
    pkg.managers.dnf.is_available || return 1
    local rid="$1"
    local -a pkgs=( ${=$(pkg.recipe.get "$rid" dnf):-$(pkg.recipe.get "$rid" package)} )
    (( $#pkgs == 0 )) && return 1

    local pkg
    for pkg in "${pkgs[@]}"; do
        dnf list available "$pkg" >/dev/null 2>&1 || return 1
    done
    return 0
}

pkg.managers.dnf.install() {
    pkg.managers.dnf.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "install:dnf") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "dnf")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    _pkg.sudo dnf install -y ${=pkgs}
}

pkg.managers.dnf.upgrade() {
    pkg.managers.dnf.is_available || return 0
    local rid pkgs=""
    local -a rids=( "$@" )
    (( ${#rids} == 0 )) && rids=( $(pkg.recipe.by_action "upgrade:dnf") )
    for rid in "${rids[@]}"; do
        local p=$(pkg.recipe.packages "$rid" "dnf")
        [[ -n "$p" ]] && pkgs+="${pkgs:+ }$p"
    done
    [[ -z "$pkgs" ]] && return 0
    _pkg.sudo dnf upgrade -y ${=pkgs}
}

pkg.managers.dnf.setup_repos() {
    pkg.managers.dnf.is_available || return 0
    local changed=0 rid val repo_filename

    local codename=$(lsb_release -cs 2>/dev/null)
    if [[ -z "$codename" && -f /etc/os-release ]]; then
        codename=$(grep "VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    codename="${codename:-stable}"

    local arch=$(uname -m 2>/dev/null || echo x86_64)
    local distro=$(lsb_release -is 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if [[ -z "$distro" && -f /etc/os-release ]]; then
        distro=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    distro="${distro:-fedora}"

    typeset -A seen_repos
    for rid in $(registry.list pkg); do
        val="$(pkg.recipe.get "$rid" "dnf_repo")"
        [[ -z "$val" ]] && continue
        [[ -n "${seen_repos[$val]}" ]] && continue
        seen_repos[$val]=1

        val="${val//\%CODENAME\%/$codename}"
        val="${val//\%ARCH\%/$arch}"
        val="${val//\%DISTRO\%/$distro}"

        repo_filename="${val:t}"
        if [[ ! -f "/etc/yum.repos.d/$repo_filename" ]]; then
            echo "   Adding dnf repo: $repo_filename"
            if dnf --version | grep -q "dnf5"; then
                _pkg.sudo dnf config-manager addrepo --from-repofile="$val" && changed=1
            else
                _pkg.sudo dnf config-manager --add-repo "$val" && changed=1
            fi
        fi
    done

    typeset -A seen_coprs
    for rid in $(registry.list pkg); do
        val="$(pkg.recipe.get "$rid" "dnf_copr")"
        [[ -z "$val" ]] && continue
        [[ -n "${seen_coprs[$val]}" ]] && continue
        seen_coprs[$val]=1

        val="${val//\%CODENAME\%/$codename}"
        val="${val//\%ARCH\%/$arch}"
        val="${val//\%DISTRO\%/$distro}"

        echo "   Enabling copr repo: $val"
        _pkg.sudo dnf copr enable -y "$val" && changed=1
    done
    [[ $changed -eq 1 ]] && _pkg.sudo dnf makecache
}
