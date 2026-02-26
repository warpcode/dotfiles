
function screen.setup() {
    screen.setup.config
}
events.add dotfiles.setup screen.setup

function screen.setup.config() {
    local destination=~/.screenrc
    config.hydrate "screen/screenrc.tmpl" --output "$destination"
    chmod 600 "$destination"
}
