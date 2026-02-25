
function screen.setup() {
    screen.setup.config
}
events.add dotfiles.setup screen.setup

function screen.setup.config() {
    config.hydrate "screen/screenrc.tmpl" --output ~/.screenrc
}
