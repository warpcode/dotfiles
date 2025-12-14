alias df.cd="cd '$DOTFILES'"
alias df.edit="_dotfiles_tmux_setup"

function df.install() {
    local os=$(_os_detect_os_family)
    _events_trigger "installer_pre_deps" "$os"
    _packages_install_apps $(_packages_get_apps_by_tag dep)
    _packages_add_registered_keys
    _packages_add_registered_repos
    _events_trigger "installer_post_deps" "$os"
    _events_trigger "installer_pre_install" "$os"
    _packages_install_apps $(_packages_get_apps_by_tag default)
    _events_trigger "installer_post_install"
    echo "🎉 Installation complete"
}

function _dotfiles_tmux_setup() {
    df.cd
    _tmux_basic_git "dotfiles"
    cd -
}
