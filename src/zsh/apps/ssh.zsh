
# Better SSH/Rsync/SCP Autocomplete
zstyle ':completion:*:(scp|rsync):*' tag-order ' hosts:-ipaddr:ip\ address hosts:-host:host files'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

function ssh.setup() {
    ssh.setup.config
    ssh.setup.perms
}
events.add dotfiles.setup ssh.setup

function ssh.setup.config() {
    local destination=~/.ssh/config
    config.hydrate "ssh/config.tmpl" --output "$destination"
    chmod 600 "$destination"
}

function ssh.setup.perms() {
    local ssh_dir="$HOME/.ssh"
    if [[ -d "$ssh_dir" ]]; then
        chmod 700 "$ssh_dir"
        find "$ssh_dir" -type f -name 'id_*' -exec chmod 600 {} \;
        find "$ssh_dir" -type f -name 'id_*.pub' -exec chmod 644 {} \;
    fi
}
