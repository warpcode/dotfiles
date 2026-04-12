pkg.recipe.define ssh \
    package="openssh" \
    managers="apt dnf pacman brew" \
    apt="openssh-client" \
    dnf="openssh-clients" \
    pacman="openssh" \
    brew="openssh"

pkg.recipe.ssh.init() {
    [[ -o interactive ]] || return 0

    zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
    zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
}

pkg.recipe.ssh.configure() {
    (( $+commands[ssh] )) || return 0
    (( $+commands[jq] )) || return 0
    (( $+commands[gomplate] )) || return 0

    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"

    mkdir -p "$ssh_dir" || return $?
    chmod 700 "$ssh_dir"

    config.hydrate "ssh/config.tmpl" --output "$ssh_config"
    find "$ssh_dir" -type f -name 'id_*' -exec chmod 600 {} \;
    find "$ssh_dir" -type f -name 'id_*.pub' -exec chmod 644 {} \;
}