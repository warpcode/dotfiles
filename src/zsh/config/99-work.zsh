export IS_WORK=$([ -f ~/.is_work ] && echo 1)

[ ! -n "$IS_WORK" ] && return

# Work specific config here
