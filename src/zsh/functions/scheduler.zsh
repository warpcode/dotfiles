# scheduler.zsh - User-space scheduled task framework

# List all scheduled tasks
scheduler.list() {
    local config_dir="$DOTFILES/assets/configs/scheduler"
    local cfg
    local name schedule command

    if [[ ! -d "$config_dir" ]]; then
        tui.info "No tasks scheduled."
        return 0
    fi

    tui.banner "Scheduled Tasks" "-" 40
    for cfg in "$config_dir"/*.json(N); do
        name=$(jq -r '.name' "$cfg")
        schedule=$(jq -r '.schedule' "$cfg")
        command=$(jq -r '.command' "$cfg")
        print -f "%-20s | %-10s | %s\n" "$name" "$schedule" "$command"
    done
}

# Remove a scheduled task
scheduler.remove() {
    local name="$1"
    [[ -z "$name" ]] && { tui.error "Usage: scheduler.remove <name>"; return 1; }

    local config_file="$DOTFILES/assets/configs/scheduler/$name.json"
    [[ ! -f "$config_file" ]] && { tui.error "Task not found: $name"; return 1; }

    local os_family=$("$DOTFILES/bin/df.os" family)

    case "$os_family" in
        macos)
            local plist="$HOME/Library/LaunchAgents/com.dotfiles.scheduler.$name.plist"
            if [[ -f "$plist" ]]; then
                launchctl unload "$plist" 2>/dev/null || true
                rm -f "$plist"
            fi
            ;;
        debian|fedora|arch|linux)
            local service_file="$HOME/.config/systemd/user/dotfiles-scheduler-$name.service"
            local timer_file="$HOME/.config/systemd/user/dotfiles-scheduler-$name.timer"
            if [[ -f "$timer_file" ]]; then
                systemctl --user stop "dotfiles-scheduler-$name.timer" 2>/dev/null || true
                systemctl --user disable "dotfiles-scheduler-$name.timer" 2>/dev/null || true
                rm -f "$service_file" "$timer_file"
                systemctl --user daemon-reload
            fi
            ;;
    esac

    rm -f "$config_file"
    tui.success "Task removed: $name"
}

# Apply a scheduled task configuration (internal)
scheduler.apply() {
    local name="$1"
    local os_family=$("$DOTFILES/bin/df.os" family)
    local config_file="scheduler/$name.json"

    case "$os_family" in
        macos)
            local plist="$HOME/Library/LaunchAgents/com.dotfiles.scheduler.$name.plist"
            config.hydrate "scheduler/launchd.plist.tmpl" \
                --config-file "$config_file" \
                --output "$plist"
            launchctl unload "$plist" 2>/dev/null || true
            launchctl load "$plist"
            ;;
        debian|fedora|arch|linux)
            local service_file="$HOME/.config/systemd/user/dotfiles-scheduler-$name.service"
            local timer_file="$HOME/.config/systemd/user/dotfiles-scheduler-$name.timer"

            config.hydrate "scheduler/systemd.service.tmpl" \
                --config-file "$config_file" \
                --output "$service_file"
            config.hydrate "scheduler/systemd.timer.tmpl" \
                --config-file "$config_file" \
                --output "$timer_file"

            systemctl --user daemon-reload
            systemctl --user enable "dotfiles-scheduler-$name.timer"
            systemctl --user restart "dotfiles-scheduler-$name.timer"
            ;;
        *)
            tui.error "Unsupported OS family for scheduler: $os_family"
            return 1
            ;;
    esac
}

# Add a new scheduled task
scheduler.add() {
    local name="$1" schedule="$2" command="$3"
    [[ -z "$name" || -z "$schedule" || -z "$command" ]] && {
        tui.error "Usage: scheduler.add <name> <schedule> <command>"
        return 1
    }

    case "$schedule" in
        hourly|daily|weekly) ;;
        *)
            tui.error "Unsupported schedule: $schedule (valid: hourly, daily, weekly)"
            return 1
            ;;
    esac

    local config_dir="$DOTFILES/assets/configs/scheduler"
    mkdir -p "$config_dir"
    local config_file="$config_dir/$name.json"

    # Save configuration
    jq -n \
        --arg name "$name" \
        --arg schedule "$schedule" \
        --arg command "$command" \
        '{name: $name, schedule: $schedule, command: $command}' \
        > "$config_file"

    scheduler.apply "$name"
    tui.success "Task added/updated: $name"
}
