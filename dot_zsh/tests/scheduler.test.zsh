#!/usr/bin/env zsh
# Unit tests for scheduler.zsh

set -e

DIR=${0:A:h}
source "${DIR}/../functions/scheduler.zsh" || source "${PWD}/dot_zsh/functions/scheduler.zsh" || exit 1

# Setup isolated temporary test directory
TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

export DOTFILES="$TEST_DIR/dotfiles"
export HOME="$TEST_DIR/home"
mkdir -p "$DOTFILES/assets/configs/scheduler"
mkdir -p "$HOME/.local/state/dotfiles/scheduler"

# Mock TUI output functions
tui.banner() { :; }
tui.info() { :; }
tui.success() { :; }
tui.warn() { :; }
tui.error() { print -u2 -- "$@"; }

# --- Test 1: scheduler.list with no tasks scheduled ---
print -- "--- Test 1: scheduler.list when empty ---"
rm -rf "$DOTFILES/assets/configs/scheduler"
scheduler.list
mkdir -p "$DOTFILES/assets/configs/scheduler"
print -- "PASSED"

# --- Test 2: scheduler.list with tasks ---
print -- "--- Test 2: scheduler.list with configured tasks ---"
cat << 'EOF' > "$DOTFILES/assets/configs/scheduler/sample-task.json"
{
  "name": "sample-task",
  "schedule": "daily",
  "command": "echo hello"
}
EOF

list_out=$(scheduler.list)
if [[ "$list_out" != *"sample-task"* || "$list_out" != *"daily"* || "$list_out" != *"echo hello"* ]]; then
    print -u2 -- "FAILED: scheduler.list output missing expected fields: $list_out"
    exit 1
fi
print -- "PASSED"

# --- Test 3: scheduler.add input validation ---
print -- "--- Test 3: scheduler.add input validation ---"
# Missing args
scheduler.add 2>/dev/null && { print -u2 -- "FAILED: scheduler.add succeeded with missing args"; exit 1; }
scheduler.add "my-task" 2>/dev/null && { print -u2 -- "FAILED: scheduler.add succeeded with partial args"; exit 1; }

# Invalid name (spaces or special symbols)
scheduler.add "bad name!" "daily" "echo 1" 2>/dev/null && { print -u2 -- "FAILED: scheduler.add accepted invalid task name"; exit 1; }

# Invalid schedule
scheduler.add "valid_task" "monthly" "echo 1" 2>/dev/null && { print -u2 -- "FAILED: scheduler.add accepted invalid schedule"; exit 1; }
print -- "PASSED"

# --- Test 4: scheduler.remove input validation ---
print -- "--- Test 4: scheduler.remove input validation ---"
scheduler.remove 2>/dev/null && { print -u2 -- "FAILED: scheduler.remove succeeded without task name"; exit 1; }
scheduler.remove "nonexistent-task" 2>/dev/null && { print -u2 -- "FAILED: scheduler.remove succeeded with nonexistent task"; exit 1; }
print -- "PASSED"

# --- Test 5: scheduler.remove macos flow ---
print -- "--- Test 5: scheduler.remove macOS platform flow ---"
# Setup mock os
df.os() { echo "macos"; }

# Create test plist and log file
mkdir -p "$HOME/Library/LaunchAgents"
test_plist="$HOME/Library/LaunchAgents/com.dotfiles.scheduler.sample-task.plist"
test_log="$HOME/.local/state/dotfiles/scheduler/sample-task.log"
touch "$test_plist" "$test_log"

bootout_called=0
launchctl() {
    if [[ "$1" == "bootout" ]]; then
        bootout_called=1
        return 0
    fi
    return 0
}

scheduler.remove "sample-task"
if (( ! bootout_called )); then
    print -u2 -- "FAILED: launchctl bootout was not called"
    exit 1
fi
if [[ -f "$test_plist" ]]; then
    print -u2 -- "FAILED: plist file was not removed"
    exit 1
fi
if [[ -f "$test_log" ]]; then
    print -u2 -- "FAILED: log file was not removed"
    exit 1
fi
if [[ -f "$DOTFILES/assets/configs/scheduler/sample-task.json" ]]; then
    print -u2 -- "FAILED: task config JSON was not removed"
    exit 1
fi
print -- "PASSED"

# --- Test 6: scheduler.remove systemd flow ---
print -- "--- Test 6: scheduler.remove systemd platform flow ---"
df.os() { echo "linux"; }

# Recreate task config
cat << 'EOF' > "$DOTFILES/assets/configs/scheduler/linux-task.json"
{
  "name": "linux-task",
  "schedule": "hourly",
  "command": "df.check"
}
EOF

mkdir -p "$HOME/.config/systemd/user"
test_service="$HOME/.config/systemd/user/dotfiles-scheduler-linux-task.service"
test_timer="$HOME/.config/systemd/user/dotfiles-scheduler-linux-task.timer"
touch "$test_service" "$test_timer"

systemctl_stop_called=0
systemctl_disable_called=0
systemctl_reload_called=0

systemctl() {
    if [[ "$*" == *"--user stop dotfiles-scheduler-linux-task.timer"* ]]; then
        systemctl_stop_called=1
    elif [[ "$*" == *"--user disable dotfiles-scheduler-linux-task.timer"* ]]; then
        systemctl_disable_called=1
    elif [[ "$*" == *"--user daemon-reload"* ]]; then
        systemctl_reload_called=1
    fi
    return 0
}

scheduler.remove "linux-task"
if (( ! systemctl_stop_called || ! systemctl_disable_called || ! systemctl_reload_called )); then
    print -u2 -- "FAILED: systemctl commands not called properly during scheduler.remove"
    exit 1
fi
if [[ -f "$test_service" || -f "$test_timer" ]]; then
    print -u2 -- "FAILED: systemd service or timer file was not removed"
    exit 1
fi
if [[ -f "$DOTFILES/assets/configs/scheduler/linux-task.json" ]]; then
    print -u2 -- "FAILED: linux task config JSON was not removed"
    exit 1
fi
print -- "PASSED"

# --- Test 7: scheduler.logs validations ---
print -- "--- Test 7: scheduler.logs validations ---"
scheduler.logs 2>/dev/null && { print -u2 -- "FAILED: scheduler.logs succeeded without name"; exit 1; }

df.os() { echo "unknown_os"; }
scheduler.logs "some-task" 2>/dev/null && { print -u2 -- "FAILED: scheduler.logs succeeded with unsupported OS"; exit 1; }

df.os() { echo "macos"; }
scheduler.logs "some-task" 2>/dev/null && { print -u2 -- "FAILED: scheduler.logs succeeded with missing log file"; exit 1; }
print -- "PASSED"

print -- "ALL SCHEDULER TESTS PASSED SUCCESSFULLY!"
