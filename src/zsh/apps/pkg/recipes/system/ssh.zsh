pkg.recipe.define ssh \
    package="openssh" \
    managers="apt dnf pacman brew" \
    apt="openssh-client" \
    dnf="openssh-clients" \
    pacman="openssh" \
    brew="openssh"

pkg.recipe.ssh.configure() {
    registry.is_enabled pkg ssh pkg.recipe || return 0

    tui.task "Configuring ssh..."
    tui.indent.push
    {
        (( $+commands[ssh] )) || { tui.warn "ssh command not found, skipping"; return 0; }
        (( $+commands[jq] )) || { tui.warn "jq command not found, skipping"; return 0; }
        (( $+commands[gomplate] )) || { tui.warn "gomplate command not found, skipping"; return 0; }

        local ssh_dir="$HOME/.ssh"
        local ssh_config="$ssh_dir/config"

        tui.step "Ensuring $ssh_dir exists"
        mkdir -p "$ssh_dir" || return $?
        chmod 700 "$ssh_dir"

        tui.step "Hydrating $ssh_config"
        config.hydrate "ssh/config.tmpl" --output "$ssh_config"

        tui.step "Securing keys in $ssh_dir"
        find "$ssh_dir" -type f -name 'id_*' -exec chmod 600 {} \;
        find "$ssh_dir" -type f -name 'id_*.pub' -exec chmod 644 {} \;
        tui.success "ssh configured"
    } always {
        tui.indent.pop
    }
}
